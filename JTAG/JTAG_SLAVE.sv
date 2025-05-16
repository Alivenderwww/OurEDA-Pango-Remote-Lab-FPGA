module JTAG_SLAVE #(
    parameter OFFSET_ADDR = 32'h1000_0000
)(
    input wire clk,
    input wire rstn,

    output wire tck,
    output wire tdi,
    output wire tms,
    input  wire tdo,

    output logic             JTAG_SLAVE_CLK          ,
    output logic             JTAG_SLAVE_RSTN         ,
    input  logic [4-1:0]     JTAG_SLAVE_WR_ADDR_ID   ,
    input  logic [31:0]      JTAG_SLAVE_WR_ADDR      ,
    input  logic [ 7:0]      JTAG_SLAVE_WR_ADDR_LEN  ,
    input  logic [ 1:0]      JTAG_SLAVE_WR_ADDR_BURST,
    input  logic             JTAG_SLAVE_WR_ADDR_VALID,
    output logic             JTAG_SLAVE_WR_ADDR_READY,
    input  logic [31:0]      JTAG_SLAVE_WR_DATA      ,
    input  logic [ 3:0]      JTAG_SLAVE_WR_STRB      ,
    input  logic             JTAG_SLAVE_WR_DATA_LAST ,
    input  logic             JTAG_SLAVE_WR_DATA_VALID,
    output logic             JTAG_SLAVE_WR_DATA_READY,
    output logic [4-1:0]     JTAG_SLAVE_WR_BACK_ID   ,
    output logic [ 1:0]      JTAG_SLAVE_WR_BACK_RESP ,
    output logic             JTAG_SLAVE_WR_BACK_VALID,
    input  logic             JTAG_SLAVE_WR_BACK_READY,
    input  logic [4-1:0]     JTAG_SLAVE_RD_ADDR_ID   ,
    input  logic [31:0]      JTAG_SLAVE_RD_ADDR      ,
    input  logic [ 7:0]      JTAG_SLAVE_RD_ADDR_LEN  ,
    input  logic [ 1:0]      JTAG_SLAVE_RD_ADDR_BURST,
    input  logic             JTAG_SLAVE_RD_ADDR_VALID,
    output logic             JTAG_SLAVE_RD_ADDR_READY,
    output logic [4-1:0]     JTAG_SLAVE_RD_BACK_ID   ,
    output logic [31:0]      JTAG_SLAVE_RD_DATA      ,
    output logic [ 1:0]      JTAG_SLAVE_RD_DATA_RESP ,
    output logic             JTAG_SLAVE_RD_DATA_LAST ,
    output logic             JTAG_SLAVE_RD_DATA_VALID,
    input  logic             JTAG_SLAVE_RD_DATA_READY
);

/*
将JTAG控制器做成AXI-SLAVE:
有一个地址是fifo_shift_data写入口，只写，一次进32bit数据。
有一个地址是fifo_shift_cmd写入口，只写，一次进32bit数据，格式为{CMD,CMD_CYCLE_LEN}
因此需要在AXI信号中加入AWBURST和ARBURST，做出修改如下：
AXBURST = 1'b0 固定突发，仅对ADDR当前地址做LEN突发长度的读写。适合对FIFO的读写。
AXBURST = 1'b1 增量突发，突发长度+1，ADDR也+1。适合对存储器的读写。
接下来设定32位的标志位地址，标志JTAG运行逻辑。
其中有一位是CMD_DONE，即JTAG空闲标志
其中有一位是CMD_FIFO_DATA_RESET，若其置1则强制fifo_shift_data清空，清空后自动置0。
其中有一位是CMD_FIFO_CMD_RESET，若其置1则强制fifo_shift_cmd清空，清空后自动置0。
其他的可以先空出来备用。
shift_out_data怎么办？鉴于移出的数据与TAP内部寄存器一一对应，因此完全可以做一个寄存器映射
，存储着Lab_FPGA的移位寄存器。
因此需要设置一个IDCODE寄存器地址
因此需要设置3个UID寄存器地址(UID是96位)
需要设置n个（n根据芯片类型固定）边界扫描寄存器地址
*/
wire jtag_rstn_sync;
rstn_sync rstn_sync_jtag(clk, rstn, jtag_rstn_sync);
assign JTAG_SLAVE_CLK  = clk;
assign JTAG_SLAVE_RSTN = jtag_rstn_sync;

wire [3:0] cmd;
wire [27:0] cycle_num;
wire shift_out;
wire cmd_ready;
wire cmd_done;
wire shift_in_rd;
wire shift_out_wr;

/*
JTAG从机地址规定
0   JTAG状态标识位，可读可写
1   移位数据fifo读入口，只读
2   移位数据fifo写入口，只写
3   移位命令fifo写入口，只写
其余的都是未定义，
若出现以下任何一种情况，返回RESP = 2'b10：
1. 对只写地址读操作
2. 对只读地址写操作
3. 对未定义地址读写操作
4. 增量突发超出了JTAG从机边界
*/
localparam JTAG_STATE_ADDR     = 32'h0;
localparam JTAG_SHIFT_OUT_ADDR = 32'h1;
localparam JTAG_SHIFT_IN_ADDR  = 32'h2;
localparam JTAG_SHIFT_CMD_ADDR = 32'h3;

reg  [31:0] JTAG_STATE_REG_WR;
reg  [31:0] JTAG_STATE_REG_READ;
wire jtag_wr_en, jtag_rd_en;
wire [15:0] tap_state;
/*
[0]    移位数据读fifo清空，1为有效，清空后自动置0                     
[1]    移位数据fifo读入口-空标识，只读，对JTAG_STATE_REG的写不改变其值
[2]    移位数据fifo读入口-满标识，只读，对JTAG_STATE_REG的写不改变其值
[7:3]  保留

[8]    移位数据写fifo清空，1为有效，清空后自动置0
[9]    移位数据fifo写入口-空标识，只读，对JTAG_STATE_REG的写不改变其值
[10]   移位数据fifo写入口-满标识，只读，对JTAG_STATE_REG的写不改变其值
[15:11]保留

[16]   移位命令写fifo清空，1为有效，清空后自动置0
[17]   移位命令fifo写入口-空标识，只读，对JTAG_STATE_REG的写不改变其值
[18]   移位命令fifo写入口-满标识，只读，对JTAG_STATE_REG的写不改变其值
[23:19]保留

[24]   CMD执行完毕标识，只读，对JTAG_STATE_REG的写不改变其值
*/

//_________________写___通___道_________________//
reg [ 3:0] wr_addr_id;
reg [31:0] wr_addr;
reg [ 3:0] wr_addr_burst;
reg        wr_transcript_error, wr_transcript_error_reg;
//JTAG作为SLAVE不接收WR_ADDR_LEN，其DATA线的结束以WR_DATA_LAST为参考。
reg [ 1:0] cu_wrchannel_st, nt_wrchannel_st;
localparam ST_WR_IDLE = 2'b00, //写通道空闲
           ST_WR_DATA = 2'b01, //地址线握手成功，数据线通道开启
           ST_WR_RESP = 2'b10; //写响应

//_________________读___通___道_________________//
reg [ 3:0] rd_addr_id;
reg [31:0] rd_addr;
reg [ 7:0] rd_addr_len;
reg [ 3:0] rd_addr_burst;
reg [ 7:0] rd_data_trans_num;
reg        rd_transcript_error, rd_transcript_error_reg;
reg [ 1:0] cu_rdchannel_st, nt_rdchannel_st;
localparam ST_RD_IDLE = 2'b00, //发送完LAST和RESP，读通道空闲
           ST_RD_DATA = 2'b01; //地址线握手成功，数据线通道开启

wire        fifo_shift_data_wr_en       ;
wire [31:0] fifo_shift_data_wr_data     ;
wire        fifo_shift_data_rd_en       ;
wire        fifo_shift_data_rd_data     ;
wire        fifo_shift_data_full        ;
wire        fifo_shift_data_almost_full ;
wire        fifo_shift_data_empty       ;
reg         fifo_shift_data_out_valid   ;
wire        fifo_shift_data_in_last     ;
wire        fifo_shift_cmd_wr_en        ;
wire [31:0] fifo_shift_cmd_wr_data      ;
wire        fifo_shift_cmd_rd_en        ;
wire        fifo_shift_cmd_full         ;
wire        fifo_shift_cmd_almost_full  ;
wire        fifo_shift_cmd_empty        ;
reg         fifo_shift_cmd_out_valid    ;
wire        fifo_shift_out_wr_en        ;
wire        fifo_shift_out_wr_data      ;
wire [31:0] fifo_shift_out_rd_data      ;
wire        fifo_shift_out_rd_en        ;
wire        fifo_shift_out_full         ;
wire        fifo_shift_out_almost_full  ;
wire        fifo_shift_out_empty        ;
reg         fifo_shift_out_out_valid    ;
wire        fifo_shift_data_out_last    ;
wire        jtag_fifo_shift_out_rst     ;
wire        jtag_fifo_shift_data_rst    ;
wire        jtag_fifo_shift_cmd_rst     ;

//_______________________________________________________________________________//
always @(*) begin
    case (cu_wrchannel_st)
        ST_WR_IDLE: nt_wrchannel_st <= (JTAG_SLAVE_WR_ADDR_VALID && JTAG_SLAVE_WR_ADDR_READY)?(ST_WR_DATA):(ST_WR_IDLE);
        ST_WR_DATA: nt_wrchannel_st <= (JTAG_SLAVE_WR_DATA_VALID && JTAG_SLAVE_WR_DATA_READY && JTAG_SLAVE_WR_DATA_LAST)?(ST_WR_RESP):(ST_WR_DATA);
        ST_WR_RESP: nt_wrchannel_st <= (JTAG_SLAVE_WR_BACK_VALID && JTAG_SLAVE_WR_BACK_READY)?(ST_WR_IDLE):(ST_WR_RESP);
        default   : nt_wrchannel_st <= ST_WR_IDLE;
    endcase
end
always @(posedge clk or negedge jtag_rstn_sync) begin
    if(~jtag_rstn_sync) cu_wrchannel_st <= ST_WR_IDLE;
    else cu_wrchannel_st <= nt_wrchannel_st;
end
assign JTAG_SLAVE_WR_ADDR_READY = (jtag_rstn_sync) && (cu_wrchannel_st == ST_WR_IDLE);
assign JTAG_SLAVE_WR_BACK_VALID = (jtag_rstn_sync) && (cu_wrchannel_st == ST_WR_RESP);
assign JTAG_SLAVE_WR_BACK_RESP  = ((jtag_rstn_sync) && ((~wr_transcript_error) && (~wr_transcript_error_reg)))?(2'b00):(2'b10);
assign JTAG_SLAVE_WR_BACK_ID    = wr_addr_id;
always @(posedge clk or negedge jtag_rstn_sync) begin
    if(~jtag_rstn_sync) begin
        wr_addr_id    <= 0;
        wr_addr_burst <= 0;
    end else if(JTAG_SLAVE_WR_ADDR_VALID && JTAG_SLAVE_WR_ADDR_READY) begin
        wr_addr_id    <= JTAG_SLAVE_WR_ADDR_ID;
        wr_addr_burst <= JTAG_SLAVE_WR_ADDR_BURST;
    end else begin
        wr_addr_id    <= wr_addr_id;
        wr_addr_burst <= wr_addr_burst;
    end
end
always @(posedge clk or negedge jtag_rstn_sync) begin
    if(~jtag_rstn_sync) wr_addr <= 0;
    else if(JTAG_SLAVE_WR_ADDR_VALID && JTAG_SLAVE_WR_ADDR_READY) wr_addr <= JTAG_SLAVE_WR_ADDR - OFFSET_ADDR;
    else if((wr_addr_burst == 2'b01) && JTAG_SLAVE_WR_DATA_VALID && JTAG_SLAVE_WR_DATA_READY) wr_addr <= wr_addr + 1;
    else wr_addr <= wr_addr;
end
always @(*) begin
    if((~jtag_rstn_sync) || (cu_wrchannel_st == ST_WR_IDLE) || (cu_wrchannel_st == ST_WR_RESP)) wr_transcript_error <= 0;
    else if((wr_addr_burst == 2'b10) || (wr_addr_burst == 2'b11)) wr_transcript_error <= 1;
    else if((wr_addr < JTAG_STATE_ADDR) || (wr_addr > JTAG_SHIFT_CMD_ADDR)) wr_transcript_error <= 1;
    else if(wr_addr == JTAG_SHIFT_OUT_ADDR) wr_transcript_error <= 1;
    else wr_transcript_error <= 0;
end
always @(posedge clk or negedge jtag_rstn_sync) begin
    if((~jtag_rstn_sync) || (cu_wrchannel_st == ST_WR_IDLE)) wr_transcript_error_reg <= 0;
    else wr_transcript_error_reg <= (wr_transcript_error)?(1):(wr_transcript_error_reg);
end



//_______________________________________________________________________________//
always @(*) begin
    case (cu_rdchannel_st)
        ST_RD_IDLE: nt_rdchannel_st <= (JTAG_SLAVE_RD_ADDR_VALID && JTAG_SLAVE_RD_ADDR_READY)?(ST_RD_DATA):(ST_RD_IDLE);
        ST_RD_DATA: nt_rdchannel_st <= (JTAG_SLAVE_RD_DATA_VALID && JTAG_SLAVE_RD_DATA_READY && JTAG_SLAVE_RD_DATA_LAST)?(ST_RD_IDLE):(ST_RD_DATA);
        default   : nt_rdchannel_st <= ST_RD_IDLE;
    endcase
end
always @(posedge clk or negedge jtag_rstn_sync)begin
    if(~jtag_rstn_sync) cu_rdchannel_st <= ST_RD_IDLE;
    else cu_rdchannel_st <= nt_rdchannel_st;
end
assign JTAG_SLAVE_RD_ADDR_READY = (jtag_rstn_sync) && (cu_rdchannel_st == ST_RD_IDLE);
always @(posedge clk or negedge jtag_rstn_sync) begin
    if(~jtag_rstn_sync) begin
        rd_addr_id    <= 0;
        rd_addr_burst <= 0;
        rd_addr_len   <= 0;
    end else if(JTAG_SLAVE_RD_ADDR_VALID && JTAG_SLAVE_RD_ADDR_READY) begin
        rd_addr_id    <= JTAG_SLAVE_RD_ADDR_ID;
        rd_addr_burst <= JTAG_SLAVE_RD_ADDR_BURST;
        rd_addr_len   <= JTAG_SLAVE_RD_ADDR_LEN;
    end else begin
        rd_addr_id    <= rd_addr_id;
        rd_addr_burst <= rd_addr_burst;
        rd_addr_len   <= rd_addr_len;
    end
end
always @(posedge clk or negedge jtag_rstn_sync) begin
    if(~jtag_rstn_sync) rd_addr <= 0;
    else if(JTAG_SLAVE_RD_ADDR_VALID && JTAG_SLAVE_RD_ADDR_READY) rd_addr <= JTAG_SLAVE_RD_ADDR - OFFSET_ADDR;
    else if(JTAG_SLAVE_RD_DATA_VALID && JTAG_SLAVE_RD_DATA_READY) rd_addr <= rd_addr + 1;
    else rd_addr <= rd_addr;
end
always @(posedge clk or negedge jtag_rstn_sync) begin
    if(~jtag_rstn_sync || (cu_rdchannel_st == ST_RD_IDLE)) rd_data_trans_num <= 0;
    else if(JTAG_SLAVE_RD_DATA_VALID && JTAG_SLAVE_RD_DATA_READY) rd_data_trans_num <= rd_data_trans_num + 1;
    else rd_data_trans_num <= rd_data_trans_num;
end
assign JTAG_SLAVE_RD_DATA_LAST = (jtag_rstn_sync) && (cu_rdchannel_st == ST_RD_DATA) && (JTAG_SLAVE_RD_DATA_VALID) && (rd_data_trans_num == rd_addr_len);
assign JTAG_SLAVE_RD_BACK_ID = rd_addr_id;
assign JTAG_SLAVE_RD_DATA_RESP  = ((jtag_rstn_sync) && (cu_rdchannel_st == ST_RD_DATA) && ((~rd_transcript_error) && (~rd_transcript_error_reg)))?(2'b00):(2'b10);

always @(*) begin
    //写数据READY选通
    if(~jtag_rstn_sync) JTAG_SLAVE_WR_DATA_READY <= 0;
    else if(cu_wrchannel_st == ST_WR_DATA) begin
             if(wr_addr == JTAG_STATE_ADDR    ) JTAG_SLAVE_WR_DATA_READY <= 1; //状态寄存器可立即写
        else if(wr_addr == JTAG_SHIFT_IN_ADDR ) JTAG_SLAVE_WR_DATA_READY <= (~fifo_shift_data_almost_full); //写FIFO未满可写
        else if(wr_addr == JTAG_SHIFT_CMD_ADDR) JTAG_SLAVE_WR_DATA_READY <= (~fifo_shift_cmd_almost_full); //写FIFO未满可写
        else JTAG_SLAVE_WR_DATA_READY <= 1; //ERROR，直接跳过不写
    end else JTAG_SLAVE_WR_DATA_READY <= 0;
    //读数据VALID选通
    if(~jtag_rstn_sync) JTAG_SLAVE_RD_DATA_VALID <= 0;
    else if(cu_rdchannel_st == ST_RD_DATA) begin
             if(rd_addr == JTAG_STATE_ADDR    ) JTAG_SLAVE_RD_DATA_VALID <= 1; //状态寄存器可立即读   
        else if(rd_addr == JTAG_SHIFT_OUT_ADDR) JTAG_SLAVE_RD_DATA_VALID <= (fifo_shift_out_out_valid); //读FIFO数据有效可读
        else JTAG_SLAVE_RD_DATA_VALID <= 1; //ERROR，直接跳过默认为全1
    end else JTAG_SLAVE_RD_DATA_VALID <= 0;
    //读数据DATA选通
    if(~jtag_rstn_sync) JTAG_SLAVE_RD_DATA <= 0;
    else if(cu_rdchannel_st == ST_RD_DATA) begin
             if(rd_addr == JTAG_STATE_ADDR    ) JTAG_SLAVE_RD_DATA <= JTAG_STATE_REG_READ; //状态寄存器可立即读  
        else if(rd_addr == JTAG_SHIFT_OUT_ADDR) JTAG_SLAVE_RD_DATA <= fifo_shift_out_rd_data; //读FIFO数据有效可读
        else JTAG_SLAVE_RD_DATA <= 32'hFFFFFFFF;
    end else JTAG_SLAVE_RD_DATA <= 0;
end

always @(*) begin
    if((~jtag_rstn_sync) || (cu_rdchannel_st == ST_RD_IDLE)) rd_transcript_error <= 0;
    else if((rd_addr_burst == 2'b10) || (rd_addr_burst == 2'b11)) rd_transcript_error <= 1;
    else if((rd_addr < JTAG_STATE_ADDR) || (rd_addr > JTAG_SHIFT_OUT_ADDR)) rd_transcript_error <= 1;
    else rd_transcript_error <= 0;
end
always @(posedge clk or negedge jtag_rstn_sync) begin
    if((~jtag_rstn_sync) || (cu_rdchannel_st == ST_RD_IDLE)) rd_transcript_error_reg <= 0;
    else rd_transcript_error_reg <= (rd_transcript_error)?(1):(rd_transcript_error_reg);
end

//_______32'h10000000_______//
always @(*) begin
    JTAG_STATE_REG_READ[0]    = JTAG_STATE_REG_WR[0];
    JTAG_STATE_REG_READ[1]    = fifo_shift_out_empty;
    JTAG_STATE_REG_READ[2]    = fifo_shift_out_full;
    JTAG_STATE_REG_READ[7:3]  = 0;

    JTAG_STATE_REG_READ[8]    = JTAG_STATE_REG_WR[8];
    JTAG_STATE_REG_READ[9]    = fifo_shift_data_empty;
    JTAG_STATE_REG_READ[10]   = fifo_shift_data_full;
    JTAG_STATE_REG_READ[15:11]= 0;

    JTAG_STATE_REG_READ[16]   = JTAG_STATE_REG_WR[16];
    JTAG_STATE_REG_READ[17]   = fifo_shift_cmd_empty;
    JTAG_STATE_REG_READ[18]   = fifo_shift_cmd_full;
    JTAG_STATE_REG_READ[23:19]= 0;
    JTAG_STATE_REG_READ[24]   = cmd_done;
    JTAG_STATE_REG_READ[31:25]= 0;
end
always @(posedge clk or negedge jtag_rstn_sync) begin
    if(~jtag_rstn_sync) JTAG_STATE_REG_WR <= 0;
    else if(JTAG_SLAVE_WR_DATA_VALID && JTAG_SLAVE_WR_DATA_READY && (wr_addr == JTAG_STATE_ADDR))begin
        JTAG_STATE_REG_WR[07:00] <= (JTAG_SLAVE_WR_STRB[0])?(JTAG_SLAVE_WR_DATA[07:00]):(JTAG_STATE_REG_WR[07:00]);
        JTAG_STATE_REG_WR[15:08] <= (JTAG_SLAVE_WR_STRB[1])?(JTAG_SLAVE_WR_DATA[15:08]):(JTAG_STATE_REG_WR[15:08]);
        JTAG_STATE_REG_WR[23:16] <= (JTAG_SLAVE_WR_STRB[2])?(JTAG_SLAVE_WR_DATA[23:16]):(JTAG_STATE_REG_WR[23:16]);
        JTAG_STATE_REG_WR[31:24] <= (JTAG_SLAVE_WR_STRB[3])?(JTAG_SLAVE_WR_DATA[31:24]):(JTAG_STATE_REG_WR[31:24]);
    end else begin
        JTAG_STATE_REG_WR[0]  <= 0; //自动置0
        JTAG_STATE_REG_WR[8]  <= 0; //自动置0
        JTAG_STATE_REG_WR[16] <= 0; //自动置0
    end
end

//_______32'h10000001_______//
always @(posedge clk or negedge jtag_rstn_sync) begin
    if(~jtag_rstn_sync) 
         fifo_shift_out_out_valid <= 0;
    else if(JTAG_STATE_REG_WR[0]) 
         fifo_shift_out_out_valid <= 0;
    else if(fifo_shift_out_empty && fifo_shift_out_rd_en && fifo_shift_out_out_valid)//在fifo为空的情况下有效数据被读了
         fifo_shift_out_out_valid <= 0;
    else if((~fifo_shift_out_out_valid) && (~fifo_shift_out_empty) && (fifo_shift_out_rd_en))//fifo不空的情况下非有效数据被读了
         fifo_shift_out_out_valid <= 1;
    else fifo_shift_out_out_valid <= fifo_shift_out_out_valid;
end
assign fifo_shift_out_rd_en = ((~fifo_shift_out_empty) && (~fifo_shift_out_out_valid)) || (JTAG_SLAVE_RD_DATA_READY && JTAG_SLAVE_RD_DATA_VALID && (rd_addr == JTAG_SHIFT_OUT_ADDR));
assign fifo_shift_out_wr_en = (~fifo_shift_out_full) && ((shift_out_wr && jtag_rd_en));
assign fifo_shift_out_wr_data = (shift_out);
assign fifo_shift_data_out_last = fifo_shift_out_almost_full;
assign jtag_fifo_shift_out_rst = (~jtag_rstn_sync) || (JTAG_STATE_REG_WR[0]);

jtag_fifo_shift_out jtag_fifo_shift_out_inst(
    .clk        (clk                    ),
    .rst        (jtag_fifo_shift_out_rst),
    .wr_en      (fifo_shift_out_wr_en   ),
    .wr_data    (fifo_shift_out_wr_data ),
    .rd_en      (fifo_shift_out_rd_en   ),
    .rd_data    (fifo_shift_out_rd_data ),
    .wr_full    (fifo_shift_out_full    ),
    .almost_full(fifo_shift_out_almost_full),
    .rd_empty   (fifo_shift_out_empty   )
);


//_______32'h10000002_______//
always @(posedge clk or negedge jtag_rstn_sync) begin
    if(~jtag_rstn_sync) 
         fifo_shift_data_out_valid <= 0;
    else if(JTAG_STATE_REG_WR[8]) 
         fifo_shift_data_out_valid <= 0;
    else if(fifo_shift_data_empty && (fifo_shift_data_out_valid && shift_in_rd && jtag_rd_en))//在fifo为空的情况下有效数据被读了
         fifo_shift_data_out_valid <= 0;
    else if((~fifo_shift_data_out_valid) && (~fifo_shift_data_empty) && (fifo_shift_data_rd_en))//fifo不空的情况下非有效数据被读了
         fifo_shift_data_out_valid <= 1;
    else fifo_shift_data_out_valid <= fifo_shift_data_out_valid;
end
assign fifo_shift_data_rd_en = (~fifo_shift_data_empty) && ((~fifo_shift_data_out_valid) || (shift_in_rd)) && (jtag_rd_en);
assign fifo_shift_data_in_last = (fifo_shift_data_empty);
assign fifo_shift_data_wr_en = (JTAG_SLAVE_WR_DATA_VALID && JTAG_SLAVE_WR_DATA_READY && (wr_addr == JTAG_SHIFT_IN_ADDR));
assign fifo_shift_data_wr_data = JTAG_SLAVE_WR_DATA;
assign jtag_fifo_shift_data_rst = (~jtag_rstn_sync) || (JTAG_STATE_REG_WR[8]);
jtag_fifo_shift_data jtag_fifo_shift_data_inst(
    .clk        (clk                        ),
    .rst        (jtag_fifo_shift_data_rst   ),
    .wr_en      (fifo_shift_data_wr_en      ),
    .wr_data    (fifo_shift_data_wr_data    ),
    .rd_en      (fifo_shift_data_rd_en      ),
    .rd_data    (fifo_shift_data_rd_data    ),
    .wr_full    (fifo_shift_data_full       ),
    .almost_full(fifo_shift_data_almost_full),
    .rd_empty   (fifo_shift_data_empty      )
);

//_______32'h10000003_______//
always @(posedge clk or negedge jtag_rstn_sync) begin
    if(~jtag_rstn_sync) 
         fifo_shift_cmd_out_valid <= 0;
    else if(JTAG_STATE_REG_WR[16]) 
         fifo_shift_cmd_out_valid <= 0;
    else if(fifo_shift_cmd_empty && (fifo_shift_cmd_out_valid && cmd_ready) && jtag_rd_en)//在fifo为空的情况下有效数据被读了
         fifo_shift_cmd_out_valid <= 0;
    else if((~fifo_shift_cmd_out_valid) && (~fifo_shift_cmd_empty) && (fifo_shift_cmd_rd_en))//fifo不空的情况下非有效数据被读了
         fifo_shift_cmd_out_valid <= 1;
    else fifo_shift_cmd_out_valid <= fifo_shift_cmd_out_valid;
end
assign fifo_shift_cmd_rd_en = (~fifo_shift_cmd_empty) && ((~fifo_shift_cmd_out_valid) || (cmd_ready)) && (jtag_rd_en);
assign fifo_shift_cmd_wr_en = (JTAG_SLAVE_WR_DATA_VALID && JTAG_SLAVE_WR_DATA_READY && (wr_addr == JTAG_SHIFT_CMD_ADDR));
assign fifo_shift_cmd_wr_data = JTAG_SLAVE_WR_DATA;
assign jtag_fifo_shift_cmd_rst = (~jtag_rstn_sync) || (JTAG_STATE_REG_WR[16]);
jtag_fifo_shift_cmd jtag_fifo_shift_cmd_inst(
    .clk        (clk                    ),
    .rst        (jtag_fifo_shift_cmd_rst),
    .wr_en      (fifo_shift_cmd_wr_en   ),
    .wr_data    (fifo_shift_cmd_wr_data ),
    .rd_en      (fifo_shift_cmd_rd_en   ),
    .rd_data    ({cmd,cycle_num}        ),
    .wr_full    (fifo_shift_cmd_full    ),
    .almost_full(fifo_shift_cmd_almost_full),
    .rd_empty   (fifo_shift_cmd_empty   )
);

//TAP FSM implementation
tap_FSM #(
    .CMD_STORE(3),  //2^n
    .CMD_LEN  (4),
    .CYCLE_LEN(28)
)tap_FSM_inst(
.clk          (clk                     ),
.rstn         (jtag_rstn_sync          ),

.jtag_rd_en   (jtag_rd_en              ),
.jtag_wr_en   (jtag_wr_en              ),
.tms          (tms                     ), //TMS在TCK上升沿被芯片读取，需要在下降沿改变值
.tdi          (tdi                     ), //TDI在TCK上升沿被芯片读取，需要在下降沿改变值
.tdo          (tdo                     ), //TDO在TCK下降沿被芯片改变值，需要在上升沿读取

.cmd           (cmd                      ), //自定义CMD命令
.cycle_num     (cycle_num                ), //循环次数
.shift_in      (fifo_shift_data_rd_data  ), //移位比特流，低位先入
.shift_in_rd   (shift_in_rd              ), //移位入使能
.shift_in_last (fifo_shift_data_in_last  ), //拉高表示shift_in是上级fifo中最后一个bit. 会使JTAG进入PAUSE态
.shift_out     (shift_out                ), //从TDO读出的移位比特流
.shift_out_wr  (shift_out_wr             ), //移位出使能
.shift_out_last(fifo_shift_data_out_last ), //拉高表示当前shift_out再存就会满. 会使JTAG进入PAUSE态

.cmd_valid    (fifo_shift_cmd_out_valid), //cmd, cycle_num有效信号
.cmd_ready    (cmd_ready               ), //准备信号
.tap_state    (tap_state              ), //TAP当前状态
.cmd_done     (cmd_done                )  //暂存列全空标志位
);

jtag_tck_gen #(
    .TCK_HIGH_PERIOD (1),
    .TCK_LOW_PERIOD (1)
)jtag_tck_gen_inst(
    .ref_clk    (clk),
    .rstn       (jtag_rstn_sync),
    .tck        (tck),
    .jtag_rd_en (jtag_rd_en),
    .jtag_wr_en (jtag_wr_en)
);
endmodule