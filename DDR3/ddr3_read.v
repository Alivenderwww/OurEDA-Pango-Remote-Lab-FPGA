module ddr3_read(
    input wire          clk            ,
    input wire          rstn           ,

    //转换后的总线
    input  wire [ 3:0] SLAVE_RD_ADDR_ID   , //读地址通道-ID
    input  wire [27:0] SLAVE_RD_ADDR      , //读地址通道-地址
    input  wire [ 7:0] SLAVE_RD_ADDR_LEN  , //读地址通道-突发长度。最小为0（1突发），最大为255（256突发）
    input  wire [ 1:0] SLAVE_RD_ADDR_BURST, //读地址通道-突发类型。（DDR不支持除增量传输外的其他突发类型，因此不接入逻辑）
    input  wire        SLAVE_RD_ADDR_VALID, //读地址通道-握手信号-有效
    output wire        SLAVE_RD_ADDR_READY, //读地址通道-握手信号-准备

    output wire [ 3:0] SLAVE_RD_BACK_ID   , //读数据通道-ID
    output wire [31:0] SLAVE_RD_DATA      , //读数据通道-数据
    output wire [ 1:0] SLAVE_RD_DATA_RESP , //读数据通道-响应
    output wire        SLAVE_RD_DATA_LAST , //读数据通道-last信号
    output wire        SLAVE_RD_DATA_VALID, //读数据通道-握手信号-有效
    input  wire        SLAVE_RD_DATA_READY, //读数据通道-握手信号-准备

    //转换前的总线
    output wire [ 27:0] READ_ADDR      ,
    output wire [  3:0] READ_LEN       ,
    output wire [  3:0] READ_ID        ,
    output wire         READ_ADDR_VALID,
    input  wire         READ_ADDR_READY,

    input wire  [255:0] READ_DATA      ,
    input wire  [  3:0] READ_BACK_ID   ,
    input wire          READ_DATA_LAST ,
    input wire          READ_DATA_VALID
);
wire ddr_rstn_sync;
rstn_sync rstn_sync_ddr(clk, rstn, ddr_rstn_sync);

/*
DDR3所支持的READ_LEN位宽为4，最大16突发长度
256*16 = 4096 bits
因此DDR3支持最大突发长度的FIFO存储量设定为4096bits
因为PDS的FIFO IP的读地址位宽最小为6
最大支持存储 2**6 = 64个256bit
考虑到流水，设定为一次最多读32个256bit，这比DDR3 IP所支持的最大16突发长度还要大
因此READ FIFO IP的读地址位宽设定为6够用了
所以READ FIFO IP的写地址位宽设定为9
对于上级模块，一次最多可以写32个256bit，即256个32bit，因此最大突发长度为256，即RD_LEN位宽为8
almost_empty最理想设定为FIFO总量 - DDR3所支持的最大突发长度，不过实际上设置为多少都能运行。
*/

/*
读流程：
读的状态相比写的要简单。
处于IDLE状态时RD_ADDR_READY为高电平
当其与RD_ADDR_VALID均为高电平时，与上级模块地址线握手成功，记录地址线，进入WAIT状态
同时计算出开头有多少无用数据，转换后的LEN。
当处于非IDLE状态时，当FIFO未空时，先冲刷掉开头的无用数据。
处理掉开头的无用数据后，只要FIFO未空，就可以一直向上级模块发送DATA_VALID信号。
当数据FIFO内数据量低于固定值时，进入TRANS_ADDR状态，向DDR3发送地址线握手，握手成功后进入TRANS_DATA状态。
接收DDR3发来的数据，接收数据存入FIFO中，当接收到LAST信号后回到WAIT状态。
与写模块不同，读模块不用考虑最后一波地址或者最后一波数据的问题，因为即使是最后一波数据量比较小，FIFO早晚也会被读到半空。
由于本模块需要生成向上级模块输出的RD_DATA_LAST信号，因此内部需要做一个计数器trans_num计数需要向上级模块传输的剩余数据量。
当计数器为1时RD_DATA_LAST信号拉高，同时检测到RD_DATA_LAST拉高并且与上级数据线握手成功后，进入RESET状态。
RESET状态下，FIFO被强制置位，处理掉剩余的无用数据。随后回到IDLE状态。
*/

wire         fifo_rst;
wire         fifo_wr_en;
wire [255:0] fifo_wr_data;
wire         fifo_rd_en;
wire [ 31:0] fifo_rd_data;
wire         empty;
wire         almost_empty;

reg [2:0] cu_rd_st, nt_rd_st;
localparam READ_ST_IDLE       = 3'b000,
           READ_ST_WAIT       = 3'b001,
           READ_ST_TRANS_ADDR = 3'b010,
           READ_ST_TRANS_DATA = 3'b011,
           READ_ST_RESET      = 3'b100;

reg [2:0] start_giveup_num;
reg [7:0] trans_num;
reg [27:0] rd_addr_load;
reg [ 7:0] rd_len_load;
reg [3:0] rd_id_load;
wire [27:0] rd_addr_end = SLAVE_RD_ADDR + SLAVE_RD_ADDR_LEN;
wire flag_last_trans = (rd_len_load <= 15);
wire flag_unuse_rd_need = (cu_rd_st != READ_ST_IDLE) && (start_giveup_num != 0);
reg flag_trans_addr_over;
reg fifo_rd_first_need;

always @(*) begin
    case (cu_rd_st)
        READ_ST_IDLE      : nt_rd_st <= (SLAVE_RD_ADDR_READY && SLAVE_RD_ADDR_VALID)?(READ_ST_WAIT):(READ_ST_IDLE);
        READ_ST_WAIT      : begin
            if(SLAVE_RD_DATA_LAST && SLAVE_RD_DATA_READY && SLAVE_RD_DATA_VALID) nt_rd_st <= READ_ST_RESET;
            else if(almost_empty && (~flag_trans_addr_over)) nt_rd_st <= READ_ST_TRANS_ADDR;
            else nt_rd_st <= READ_ST_WAIT;
        end
        READ_ST_TRANS_ADDR : nt_rd_st <= (READ_ADDR_READY && READ_ADDR_VALID)?(READ_ST_TRANS_DATA):(READ_ST_TRANS_ADDR);
        READ_ST_TRANS_DATA : nt_rd_st <= (READ_DATA_VALID && READ_DATA_LAST)?(READ_ST_WAIT):(READ_ST_TRANS_DATA);
        READ_ST_RESET      : nt_rd_st <= READ_ST_IDLE;
        default            : nt_rd_st <= READ_ST_IDLE;
    endcase
end
always @(posedge clk or negedge ddr_rstn_sync) begin
    if(~ddr_rstn_sync) cu_rd_st <= READ_ST_IDLE;
    else cu_rd_st <= nt_rd_st;
end

always @(posedge clk or negedge ddr_rstn_sync) begin
    if(~ddr_rstn_sync) flag_trans_addr_over <= 0;
    else if(cu_rd_st == READ_ST_IDLE) flag_trans_addr_over <= 0;
    else if(READ_ADDR_VALID && READ_ADDR_READY && flag_last_trans) flag_trans_addr_over <= 1;
    else flag_trans_addr_over <= flag_trans_addr_over;
end

always @(posedge clk or negedge ddr_rstn_sync) begin
    if(~ddr_rstn_sync) begin
        rd_addr_load     <= 0;
        rd_len_load      <= 0;
        rd_id_load       <= 0;
    end else if(SLAVE_RD_ADDR_VALID && SLAVE_RD_ADDR_READY) begin
        rd_addr_load     <= {SLAVE_RD_ADDR[27:3],3'b000};
        rd_len_load      <= rd_addr_end[27:3] - SLAVE_RD_ADDR[27:3];
        rd_id_load       <= SLAVE_RD_ADDR_ID;
    end else if(READ_ADDR_VALID && READ_ADDR_READY) begin
        if(flag_last_trans) begin
            rd_addr_load <= rd_addr_load;
            rd_len_load  <= rd_len_load;
            rd_id_load   <= rd_id_load;
        end else begin
            rd_addr_load <= rd_addr_load + READ_LEN * 8 + 8;
            rd_len_load  <= rd_len_load - READ_LEN - 1;
            rd_id_load   <= rd_id_load;
        end
    end else begin
        rd_addr_load <= rd_addr_load;
        rd_len_load  <= rd_len_load;
        rd_id_load   <= rd_id_load;
    end
end

always @(posedge clk or negedge ddr_rstn_sync) begin
    if(~ddr_rstn_sync) start_giveup_num <= 0;
    else if(SLAVE_RD_ADDR_VALID && SLAVE_RD_ADDR_READY) start_giveup_num <= SLAVE_RD_ADDR[2:0];
    else if(fifo_rd_en && (~fifo_rd_first_need) && flag_unuse_rd_need) start_giveup_num <= start_giveup_num - 1;
    else start_giveup_num <= start_giveup_num;
end

always @(posedge clk or negedge ddr_rstn_sync) begin
    if(~ddr_rstn_sync) trans_num <= 0;
    else if(SLAVE_RD_ADDR_VALID && SLAVE_RD_ADDR_READY) trans_num <= SLAVE_RD_ADDR_LEN;
    else if(fifo_rd_en && (~flag_unuse_rd_need) && (~fifo_rd_first_need) && (trans_num != 0)) trans_num <= trans_num - 1;
    else trans_num <= trans_num;
end

always @(posedge clk or negedge ddr_rstn_sync) begin
    if(~ddr_rstn_sync) fifo_rd_first_need <= 1;
    else if(cu_rd_st == READ_ST_RESET) fifo_rd_first_need <= 1;
    else if(empty && ((SLAVE_RD_DATA_READY) && (SLAVE_RD_DATA_VALID))) fifo_rd_first_need <= 1;
    else if(fifo_rd_en && fifo_rd_first_need) fifo_rd_first_need <= 0;
    else fifo_rd_first_need <= fifo_rd_first_need;
end

assign SLAVE_RD_ADDR_READY   = (ddr_rstn_sync) && (cu_rd_st == READ_ST_IDLE);
assign SLAVE_RD_DATA         = fifo_rd_data;
assign SLAVE_RD_BACK_ID      = rd_id_load;//DDR不支持乱序执行，因此直接连线就OK。
assign SLAVE_RD_DATA_LAST    = (ddr_rstn_sync) && (cu_rd_st != READ_ST_IDLE && cu_rd_st != READ_ST_RESET) && (trans_num == 0);
assign SLAVE_RD_DATA_VALID   = (ddr_rstn_sync) && ((cu_rd_st != READ_ST_IDLE && cu_rd_st != READ_ST_RESET) && (~fifo_rd_first_need) && (~flag_unuse_rd_need));
assign SLAVE_RD_DATA_RESP    = 2'b00;
assign READ_ADDR             = rd_addr_load;
assign READ_LEN              = (rd_len_load >= 15)?(4'b1111):(rd_len_load);
assign READ_ID               = rd_id_load;
assign READ_ADDR_VALID       = (ddr_rstn_sync) && (cu_rd_st == READ_ST_TRANS_ADDR);

assign fifo_rst     = (~ddr_rstn_sync) || (cu_rd_st == READ_ST_RESET);
assign fifo_wr_en   = (READ_DATA_VALID);
assign fifo_wr_data = (READ_DATA);
assign fifo_rd_en   = (~empty) && ((flag_unuse_rd_need) || (fifo_rd_first_need) || ((SLAVE_RD_DATA_READY) && (SLAVE_RD_DATA_VALID))); //dont care或读出无用数据或与上级模块数据线握手成功

//fifo的读端口特性：fifo_rd_data是上一个fifo_rd_en采集到的数据。
//因此rd_data_valid实际上是相对于fifo_rd_en延迟一个周期，还要考虑到empty信号，当前fifo empty并不代表当前的fifo_rd_data是无用的。
//fifo_rd_en为1的逻辑整体上不变，就是(~empty) && ((flag_unuse_rd_need) || (fifo_rd_first_need) || ((SLAVE_RD_DATA_READY) && (SLAVE_RD_DATA_VALID)))
//但是RD_DATA_VALID为1的逻辑要大改，是((cu_rd_st != READ_ST_IDLE && cu_rd_st != READ_ST_RESET) && (~fifo_rd_first_need) && (~flag_unuse_rd_need));
//fifo_rd_first_need是当前的fifo_rd_data是不是所谓DON'T CARE的标志，如果在empty==1的情况下fifo_rd_data被读走，或者fifo初始化，就会触发它为高电平。

fifo_ddr3_read fifo_ddr3_read(
    .clk    (clk),
    .rst    (fifo_rst),

    .wr_en  (fifo_wr_en),
    .wr_data(fifo_wr_data),

    .rd_en  (fifo_rd_en),
    .rd_data(fifo_rd_data),

    .rd_empty  (empty),
    .almost_empty (almost_empty)
);

endmodule