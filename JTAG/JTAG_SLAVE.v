module JTAG_SLAVE #(
    parameter OFFSET_ADDR = 32'h1000_0000
)(
    input wire clk,
    input wire rstn,

    output wire tck,
    output wire tdi,
    output wire tms,
    input  wire tdo,

    output wire        JTAG_SLAVE_CLK          ,
    output wire        JTAG_SLAVE_RSTN         ,

    input  wire [ 3:0] JTAG_SLAVE_WR_ADDR_ID   , //写地址通道-ID
    input  wire [31:0] JTAG_SLAVE_WR_ADDR      , //写地址通道-地址
    input  wire [ 7:0] JTAG_SLAVE_WR_ADDR_LEN  , //写地址通道-突发长度-最小为0（1突发），最大为255（256突发）
    input  wire [ 1:0] JTAG_SLAVE_WR_ADDR_BURST, //写地址通道-突发类型。00为固定突发，01为增量突发
    input  wire        JTAG_SLAVE_WR_ADDR_VALID, //写地址通道-握手信号-有效
    output wire        JTAG_SLAVE_WR_ADDR_READY, //写地址通道-握手信号-准备

    input  wire [31:0] JTAG_SLAVE_WR_DATA      , //写数据通道-数据
    input  wire [ 3:0] JTAG_SLAVE_WR_STRB      , //写数据通道-选通
    input  wire        JTAG_SLAVE_WR_DATA_LAST , //写数据通道-last信号
    input  wire        JTAG_SLAVE_WR_DATA_VALID, //写数据通道-握手信号-有效
    output  reg        JTAG_SLAVE_WR_DATA_READY, //写数据通道-握手信号-准备

    output wire [ 3:0] JTAG_SLAVE_WR_BACK_ID   , //写响应通道-ID
    output wire [ 1:0] JTAG_SLAVE_WR_BACK_RESP , //写响应通道-响应 //SLAVE_WR_DATA_LAST拉高的同时或者之后 00 01正常 10写错误 11地址有问题找不到从机
    output wire        JTAG_SLAVE_WR_BACK_VALID, //写响应通道-握手信号-有效
    input  wire        JTAG_SLAVE_WR_BACK_READY, //写响应通道-握手信号-准备

    input  wire [ 3:0] JTAG_SLAVE_RD_ADDR_ID   , //读地址通道-ID
    input  wire [31:0] JTAG_SLAVE_RD_ADDR      , //读地址通道-地址
    input  wire [ 7:0] JTAG_SLAVE_RD_ADDR_LEN  , //读地址通道-突发长度。最小为0（1突发），最大为255（256突发）
    input  wire [ 1:0] JTAG_SLAVE_RD_ADDR_BURST, //读地址通道-突发类型。
    input  wire        JTAG_SLAVE_RD_ADDR_VALID, //读地址通道-握手信号-有效
    output wire        JTAG_SLAVE_RD_ADDR_READY, //读地址通道-握手信号-准备

    output wire [ 3:0] JTAG_SLAVE_RD_BACK_ID   , //读数据通道-ID
    output  reg [31:0] JTAG_SLAVE_RD_DATA      , //读数据通道-数据
    output wire [ 1:0] JTAG_SLAVE_RD_DATA_RESP , //读数据通道-响应
    output wire        JTAG_SLAVE_RD_DATA_LAST , //读数据通道-last信号
    output  reg        JTAG_SLAVE_RD_DATA_VALID, //读数据通道-握手信号-有效
    input  wire        JTAG_SLAVE_RD_DATA_READY  //读数据通道-握手信号-准备
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
assign JTAG_SLAVE_CLK  = clk;
assign JTAG_SLAVE_RSTN = rstn;

wire [3:0] cmd;
wire [27:0] cycle_num;
wire shift_out;
wire cmd_ready;
wire cmd_done;
wire shift_in_rd;
wire shift_out_wr;

/*
JTAG从机地址规定
OFFSET_ADDR + 0为JTAG状态标识位，可读可写
OFFSET_ADDR + 1为移位数据fifo读入口，只读
OFFSET_ADDR + 2为移位数据fifo写入口，只写
OFFSET_ADDR + 3为移位命令fifo写入口，只写
其余的都是未定义，
若出现以下任何一种情况，返回RESP = 2'b10：
1. 对只写地址读操作
2. 对只读地址写操作
3. 对未定义地址读写操作
4. 增量突发超出了JTAG从机边界
*/
localparam REAL_JTAG_STATE_ADDR     = OFFSET_ADDR + 32'h0;
localparam REAL_JTAG_SHIFT_OUT_ADDR = OFFSET_ADDR + 32'h1;
localparam REAL_JTAG_SHIFT_IN_ADDR  = OFFSET_ADDR + 32'h2;
localparam REAL_JTAG_SHIFT_CMD_ADDR = OFFSET_ADDR + 32'h3;

reg  [31:0] JTAG_STATE_REG_WR;
reg  [31:0] JTAG_STATE_REG_READ;
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

wire        fifo_shift_data_wr_en    ;
wire [31:0] fifo_shift_data_wr_data  ;
wire        fifo_shift_data_rd_en    ;
wire        fifo_shift_data_rd_data  ;
wire        fifo_shift_data_full     ;
wire        fifo_shift_data_empty    ;
reg         fifo_shift_data_out_valid;
wire        fifo_shift_data_in_last  ;
wire        fifo_shift_cmd_wr_en     ;
wire [31:0] fifo_shift_cmd_wr_data   ;
wire        fifo_shift_cmd_rd_en     ;
wire        fifo_shift_cmd_full      ;
wire        fifo_shift_cmd_empty     ;
reg         fifo_shift_cmd_out_valid ;
wire        fifo_shift_out_wr_en     ;
wire        fifo_shift_out_wr_data   ;
wire [31:0] fifo_shift_out_rd_data   ;
wire        fifo_shift_out_rd_en     ;
wire        fifo_shift_out_full      ;
wire        fifo_shift_out_empty     ;
reg         fifo_shift_out_out_valid ;
wire        fifo_shift_data_out_last ;
reg         fifo_out_full_data_temp  ;
reg         fifo_out_full_data_valid ;
wire        jtag_fifo_shift_out_rst  ;
wire        jtag_fifo_shift_data_rst ;
wire        jtag_fifo_shift_cmd_rst  ;

//_______________________________________________________________________________//
always @(*) begin
    if(~rstn) nt_wrchannel_st <= ST_WR_IDLE;
    case (cu_wrchannel_st)
        ST_WR_IDLE: nt_wrchannel_st <= (JTAG_SLAVE_WR_ADDR_VALID && JTAG_SLAVE_WR_ADDR_READY)?(ST_WR_DATA):(ST_WR_IDLE);
        ST_WR_DATA: nt_wrchannel_st <= (JTAG_SLAVE_WR_DATA_VALID && JTAG_SLAVE_WR_DATA_READY && JTAG_SLAVE_WR_DATA_LAST)?(ST_WR_RESP):(ST_WR_DATA);
        ST_WR_RESP: nt_wrchannel_st <= (JTAG_SLAVE_WR_BACK_VALID && JTAG_SLAVE_WR_BACK_READY)?(ST_WR_IDLE):(ST_WR_RESP);
        default   : nt_wrchannel_st <= ST_WR_IDLE;
    endcase
end
always @(posedge clk) cu_wrchannel_st <= nt_wrchannel_st;
assign JTAG_SLAVE_WR_ADDR_READY = (rstn) && (cu_wrchannel_st == ST_WR_IDLE);
assign JTAG_SLAVE_WR_BACK_VALID = (rstn) && (cu_wrchannel_st == ST_WR_RESP);
assign JTAG_SLAVE_WR_BACK_RESP  = ((rstn) && ((~wr_transcript_error) && (~wr_transcript_error_reg)))?(2'b00):(2'b10);
assign JTAG_SLAVE_WR_BACK_ID    = wr_addr_id;
always @(posedge clk) begin
    if(~rstn) begin
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
always @(posedge clk) begin
    if(~rstn) wr_addr <= 0;
    else if(JTAG_SLAVE_WR_ADDR_VALID && JTAG_SLAVE_WR_ADDR_READY) wr_addr <= JTAG_SLAVE_WR_ADDR;
    else if((wr_addr_burst == 2'b01) && JTAG_SLAVE_WR_DATA_VALID && JTAG_SLAVE_WR_DATA_READY) wr_addr <= wr_addr + 1;
    else wr_addr <= wr_addr;
end
always @(*) begin
    if((~rstn) || (cu_wrchannel_st == ST_WR_IDLE) || (cu_wrchannel_st == ST_WR_RESP)) wr_transcript_error <= 0;
    else if((wr_addr_burst == 2'b10) || (wr_addr_burst == 2'b11)) wr_transcript_error <= 1;
    else if((wr_addr < REAL_JTAG_STATE_ADDR) || (wr_addr > REAL_JTAG_SHIFT_CMD_ADDR)) wr_transcript_error <= 1;
    else if(wr_addr == REAL_JTAG_SHIFT_OUT_ADDR) wr_transcript_error <= 1;
    else wr_transcript_error <= 0;
end
always @(posedge clk) begin
    if((~rstn) || (cu_wrchannel_st == ST_WR_IDLE)) wr_transcript_error_reg <= 0;
    else wr_transcript_error_reg <= (wr_transcript_error)?(1):(wr_transcript_error_reg);
end



//_______________________________________________________________________________//
always @(*) begin
    if(~rstn) nt_rdchannel_st <= ST_RD_IDLE;
    case (cu_rdchannel_st)
        ST_RD_IDLE: nt_rdchannel_st <= (JTAG_SLAVE_RD_ADDR_VALID && JTAG_SLAVE_RD_ADDR_READY)?(ST_RD_DATA):(ST_RD_IDLE);
        ST_RD_DATA: nt_rdchannel_st <= (JTAG_SLAVE_RD_DATA_VALID && JTAG_SLAVE_RD_DATA_READY && JTAG_SLAVE_RD_DATA_LAST)?(ST_RD_IDLE):(ST_RD_DATA);
        default   : nt_rdchannel_st <= ST_RD_IDLE;
    endcase
end
always @(posedge clk) cu_rdchannel_st <= nt_rdchannel_st;
assign JTAG_SLAVE_RD_ADDR_READY = (rstn) && (cu_rdchannel_st == ST_RD_IDLE);
always @(posedge clk) begin
    if(~rstn) begin
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
always @(posedge clk) begin
    if(~rstn) rd_addr <= 0;
    else if(JTAG_SLAVE_RD_ADDR_VALID && JTAG_SLAVE_RD_ADDR_READY) rd_addr <= JTAG_SLAVE_RD_ADDR;
    else if(JTAG_SLAVE_RD_DATA_VALID && JTAG_SLAVE_RD_DATA_READY) rd_addr <= rd_addr + 1;
    else rd_addr <= rd_addr;
end
always @(posedge clk) begin
    if(~rstn || (cu_rdchannel_st == ST_RD_IDLE)) rd_data_trans_num <= 0;
    else if(JTAG_SLAVE_RD_DATA_VALID && JTAG_SLAVE_RD_DATA_READY) rd_data_trans_num <= rd_data_trans_num + 1;
    else rd_data_trans_num <= rd_data_trans_num;
end
assign JTAG_SLAVE_RD_DATA_LAST = (JTAG_SLAVE_RD_DATA_VALID) && (rd_data_trans_num == rd_addr_len);
assign JTAG_SLAVE_RD_BACK_ID = rd_addr_id;
assign JTAG_SLAVE_RD_DATA_RESP  = ((rstn) && ((~rd_transcript_error) && (~rd_transcript_error_reg)))?(2'b00):(2'b10);

always @(*) begin
    //写数据READY选通
    if(~rstn) JTAG_SLAVE_WR_DATA_READY <= 0;
    else if(cu_wrchannel_st == ST_WR_DATA) begin
             if(wr_addr == REAL_JTAG_STATE_ADDR    ) JTAG_SLAVE_WR_DATA_READY <= 1; //状态寄存器可立即写
        else if(wr_addr == REAL_JTAG_SHIFT_IN_ADDR ) JTAG_SLAVE_WR_DATA_READY <= (~fifo_shift_data_full); //写FIFO未满可写
        else if(wr_addr == REAL_JTAG_SHIFT_CMD_ADDR) JTAG_SLAVE_WR_DATA_READY <= (~fifo_shift_cmd_full); //写FIFO未满可写
        else JTAG_SLAVE_WR_DATA_READY <= 1; //ERROR，直接跳过不写
    end else JTAG_SLAVE_WR_DATA_READY <= 0;
    //读数据VALID选通
    if(~rstn) JTAG_SLAVE_RD_DATA_VALID <= 0;
    else if(cu_rdchannel_st == ST_RD_DATA) begin
             if(rd_addr == REAL_JTAG_STATE_ADDR    ) JTAG_SLAVE_RD_DATA_VALID <= 1; //状态寄存器可立即读   
        else if(rd_addr == REAL_JTAG_SHIFT_OUT_ADDR) JTAG_SLAVE_RD_DATA_VALID <= (fifo_shift_out_out_valid); //读FIFO数据有效可读
        else JTAG_SLAVE_RD_DATA_VALID <= 1; //ERROR，直接跳过默认为全1
    end else JTAG_SLAVE_RD_DATA_VALID <= 0;
    //读数据DATA选通
    if(~rstn) JTAG_SLAVE_RD_DATA <= 0;
    else if(cu_rdchannel_st == ST_RD_DATA) begin
             if(rd_addr == REAL_JTAG_STATE_ADDR    ) JTAG_SLAVE_RD_DATA <= JTAG_STATE_REG_READ; //状态寄存器可立即读  
        else if(rd_addr == REAL_JTAG_SHIFT_OUT_ADDR) JTAG_SLAVE_RD_DATA <= fifo_shift_out_rd_data; //读FIFO数据有效可读
        else JTAG_SLAVE_RD_DATA <= 32'hFFFFFFFF;
    end else JTAG_SLAVE_RD_DATA <= 0;
end

always @(*) begin
    if((~rstn) || (cu_rdchannel_st == ST_RD_IDLE)) rd_transcript_error <= 0;
    else if((rd_addr_burst == 2'b10) || (rd_addr_burst == 2'b11)) rd_transcript_error <= 1;
    else if((rd_addr < REAL_JTAG_STATE_ADDR) || (rd_addr > REAL_JTAG_SHIFT_OUT_ADDR)) rd_transcript_error <= 1;
    else rd_transcript_error <= 0;
end
always @(posedge clk) begin
    if((~rstn) || (cu_rdchannel_st == ST_RD_IDLE)) rd_transcript_error_reg <= 0;
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
always @(posedge clk) begin
    if(~rstn) JTAG_STATE_REG_WR <= 0;
    else if(JTAG_SLAVE_WR_DATA_VALID && JTAG_SLAVE_WR_DATA_READY && (wr_addr == REAL_JTAG_STATE_ADDR))begin
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
always @(posedge clk) begin
    if(jtag_fifo_shift_out_rst) 
         fifo_shift_out_out_valid <= 0;
    else if(fifo_shift_out_empty && fifo_shift_out_rd_en && fifo_shift_out_out_valid)//在fifo为空的情况下有效数据被读了
         fifo_shift_out_out_valid <= 0;
    else if((~fifo_shift_out_out_valid) && (~fifo_shift_out_empty) && (fifo_shift_out_rd_en))//fifo不空的情况下非有效数据被读了
         fifo_shift_out_out_valid <= 1;
    else fifo_shift_out_out_valid <= fifo_shift_out_out_valid;
end
always @(posedge clk) begin
    if(~rstn) fifo_out_full_data_valid <= 0;
    else if(fifo_shift_out_full && shift_out_wr) fifo_out_full_data_valid <= 1;
    else if((~fifo_shift_out_full) && (fifo_out_full_data_valid) && (fifo_shift_out_wr_en)) fifo_out_full_data_valid <= 0;
    else fifo_out_full_data_valid <= fifo_out_full_data_valid;
end
always @(posedge clk) begin
    if(~rstn) fifo_out_full_data_temp <= 0;
    else if(fifo_shift_out_full && shift_out_wr) fifo_out_full_data_temp <= shift_out;
    else fifo_out_full_data_temp <= fifo_out_full_data_temp;
end
assign fifo_shift_out_rd_en = ((~fifo_shift_out_empty) && (~fifo_shift_out_out_valid)) || (JTAG_SLAVE_RD_DATA_READY && JTAG_SLAVE_RD_DATA_VALID && (rd_addr == REAL_JTAG_SHIFT_OUT_ADDR));
assign fifo_shift_out_wr_en = (~fifo_shift_out_full) && ((fifo_out_full_data_valid) || (shift_out_wr));
assign fifo_shift_out_wr_data = (fifo_out_full_data_valid)?(fifo_out_full_data_temp):(shift_out);
assign fifo_shift_data_out_last = fifo_shift_out_full;
assign jtag_fifo_shift_out_rst = (~rstn) && (~JTAG_STATE_REG_WR[0]);

jtag_fifo_shift_out jtag_fifo_shift_out_inst(
    .clk        (clk                    ),
    .rst        (jtag_fifo_shift_out_rst),
    .wr_en      (fifo_shift_out_wr_en   ),
    .wr_data    (fifo_shift_out_wr_data ),
    .rd_en      (fifo_shift_out_rd_en   ),
    .rd_data    (fifo_shift_out_rd_data ),
    .wr_full    (fifo_shift_out_full    ),
    .rd_empty   (fifo_shift_out_empty   )
);


//_______32'h10000002_______//
always @(posedge clk) begin
    if(jtag_fifo_shift_data_rst) 
         fifo_shift_data_out_valid <= 0;
    else if(fifo_shift_data_empty && (fifo_shift_data_out_valid && shift_in_rd))//在fifo为空的情况下有效数据被读了
         fifo_shift_data_out_valid <= 0;
    else if((~fifo_shift_data_out_valid) && (~fifo_shift_data_empty) && (fifo_shift_data_rd_en))//fifo不空的情况下非有效数据被读了
         fifo_shift_data_out_valid <= 1;
    else fifo_shift_data_out_valid <= fifo_shift_data_out_valid;
end
assign fifo_shift_data_rd_en = (~fifo_shift_data_empty) && ((~fifo_shift_data_out_valid) || (shift_in_rd));
assign fifo_shift_data_in_last = (fifo_shift_data_empty);
assign fifo_shift_data_wr_en = (JTAG_SLAVE_WR_DATA_VALID && JTAG_SLAVE_WR_DATA_READY && (wr_addr == REAL_JTAG_SHIFT_IN_ADDR));
assign fifo_shift_data_wr_data = JTAG_SLAVE_WR_DATA;
assign jtag_fifo_shift_data_rst = (~rstn) && (~JTAG_STATE_REG_WR[8]);
jtag_fifo_shift_data jtag_fifo_shift_data_inst(
    .clk        (clk                     ),
    .rst        (jtag_fifo_shift_data_rst),
    .wr_en      (fifo_shift_data_wr_en   ),
    .wr_data    (fifo_shift_data_wr_data ),
    .rd_en      (fifo_shift_data_rd_en   ),
    .rd_data    (fifo_shift_data_rd_data ),
    .wr_full    (fifo_shift_data_full    ),
    .rd_empty   (fifo_shift_data_empty   )
);

//_______32'h10000003_______//
always @(posedge clk) begin
    if(jtag_fifo_shift_cmd_rst) 
         fifo_shift_cmd_out_valid <= 0;
    else if(fifo_shift_cmd_empty && (fifo_shift_cmd_out_valid && cmd_ready))//在fifo为空的情况下有效数据被读了
         fifo_shift_cmd_out_valid <= 0;
    else if((~fifo_shift_cmd_out_valid) && (~fifo_shift_cmd_empty) && (fifo_shift_cmd_rd_en))//fifo不空的情况下非有效数据被读了
         fifo_shift_cmd_out_valid <= 1;
    else fifo_shift_cmd_out_valid <= fifo_shift_cmd_out_valid;
end
assign fifo_shift_cmd_rd_en = (~fifo_shift_cmd_empty) && ((~fifo_shift_cmd_out_valid) || (cmd_ready));
assign fifo_shift_cmd_wr_en = (JTAG_SLAVE_WR_DATA_VALID && JTAG_SLAVE_WR_DATA_READY && (wr_addr == REAL_JTAG_SHIFT_CMD_ADDR));
assign fifo_shift_cmd_wr_data = JTAG_SLAVE_WR_DATA;
assign jtag_fifo_shift_cmd_rst = (~rstn) && (~JTAG_STATE_REG_WR[16]);
jtag_fifo_shift_cmd jtag_fifo_shift_cmd_inst(
    .clk        (clk                    ),
    .rst        (jtag_fifo_shift_cmd_rst),
    .wr_en      (fifo_shift_cmd_wr_en   ),
    .wr_data    (fifo_shift_cmd_wr_data ),
    .rd_en      (fifo_shift_cmd_rd_en   ),
    .rd_data    ({cmd,cycle_num}        ),
    .wr_full    (fifo_shift_cmd_full    ),
    .rd_empty   (fifo_shift_cmd_empty   )
);

//TAP FSM implementation
tap_FSM #(
    .CMD_STORE(3),  //2^n
    .CMD_LEN  (4),
    .CYCLE_LEN(28)
)tap_FSM_inst(
.clk          (clk                     ),
.rstn         (rstn                    ),

.tck          (tck                     ),
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
.cmd_done     (cmd_done                )  //暂存列全空标志位
);

endmodule