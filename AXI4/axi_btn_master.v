module axi_btn_master(
    //___________________其他接口_____________________//
    input  wire        clk          ,
    input  wire        rstn         ,
    input  wire [ 3:0] btn          ,
    output  reg [31:0] recv_data    ,

    //___________________AXI接口_____________________//
    output wire        MASTER_CLK          , //向AXI总线提供的本主机时钟信号
    output wire        MASTER_RSTN         , //向AXI总线提供的本主机复位信号

    output wire [ 1:0] MASTER_WR_ADDR_ID   , //写地址通道-ID
    output wire [31:0] MASTER_WR_ADDR      , //写地址通道-地址
    output wire [ 7:0] MASTER_WR_ADDR_LEN  , //写地址通道-突发长度-最小为0（1突发），最大为255（256突发）
    output wire [ 1:0] MASTER_WR_ADDR_BURST, //写地址通道-突发类型
    output wire        MASTER_WR_ADDR_VALID, //写地址通道-握手信号-有效
    input  wire        MASTER_WR_ADDR_READY, //写地址通道-握手信号-准备

    output wire [31:0] MASTER_WR_DATA      , //写数据通道-数据
    output wire [ 3:0] MASTER_WR_STRB      , //写数据通道-选通
    output wire        MASTER_WR_DATA_LAST , //写数据通道-last信号
    output wire        MASTER_WR_DATA_VALID, //写数据通道-握手信号-有效
    input  wire        MASTER_WR_DATA_READY, //写数据通道-握手信号-准备

    input  wire [ 1:0] MASTER_WR_BACK_ID   , //写响应通道-ID
    input  wire [ 1:0] MASTER_WR_BACK_RESP , //写响应通道-响应
    input  wire        MASTER_WR_BACK_VALID, //写响应通道-握手信号-有效
    output wire        MASTER_WR_BACK_READY, //写响应通道-握手信号-准备

    output wire [ 1:0] MASTER_RD_ADDR_ID   , //读地址通道-ID
    output wire [31:0] MASTER_RD_ADDR      , //读地址通道-地址
    output wire [ 7:0] MASTER_RD_ADDR_LEN  , //读地址通道-突发长度。最小为0（1突发），最大为255（256突发）
    output wire [ 1:0] MASTER_RD_ADDR_BURST, //读地址通道-突发类型。
    output wire        MASTER_RD_ADDR_VALID, //读地址通道-握手信号-有效
    input  wire        MASTER_RD_ADDR_READY, //读地址通道-握手信号-准备

    input  wire [ 1:0] MASTER_RD_BACK_ID   , //读数据通道-ID
    input  wire [31:0] MASTER_RD_DATA      , //读数据通道-数据
    input  wire [ 1:0] MASTER_RD_DATA_RESP , //读数据通道-响应
    input  wire        MASTER_RD_DATA_LAST , //读数据通道-last信号
    input  wire        MASTER_RD_DATA_VALID, //读数据通道-握手信号-有效
    output wire        MASTER_RD_DATA_READY  //读数据通道-握手信号-准备
);
assign MASTER_CLK = clk;
assign MASTER_RSTN = rstn;

reg  [3:0] btn_d0, btn_d1;
wire [3:0] btn_pos, btn_neg;
always @(posedge clk) begin
    btn_d0 <= btn;
    btn_d1 <= btn_d0;
end
assign btn_pos = (btn_d0) & (~btn_d1);
assign btn_neg = (~btn_d0) & (btn_d1);

reg trans_data;
always @(posedge clk) begin
    if((~rstn) || (btn_neg[3])) trans_data <= 0;
    else if(btn_neg[1]) trans_data <= trans_data + 1;
    else trans_data <= trans_data;
end

//btn[0] 发送一个地址传输，突发长度0，地址是2000_0000
//btn[1] 发送一个写数据传输，第一次发数据为00000001，之后再按一下就递增
//btn[2] 发送一个读地址传输，突发长度0，地址是2000_0000
//btn[3] 写数据重新从00000000计数


reg cu_wr_addr_st, nt_wr_addr_st;
localparam ST_WR_ADDR_IDLE = 1'b0;
localparam ST_WR_ADDR_TRAN = 1'b1;
always @(*) begin
    if(~rstn) nt_wr_addr_st <= ST_WR_ADDR_IDLE;
    else case (cu_wr_addr_st)
        ST_WR_ADDR_IDLE: nt_wr_addr_st <= (btn_neg[0])?(ST_WR_ADDR_TRAN):(ST_WR_ADDR_IDLE);
        ST_WR_ADDR_TRAN: nt_wr_addr_st <= (MASTER_WR_ADDR_VALID && MASTER_WR_ADDR_READY)?(ST_WR_ADDR_IDLE):(ST_WR_ADDR_TRAN);
    endcase
end
always @(posedge clk) cu_wr_addr_st <= nt_wr_addr_st;


assign MASTER_WR_ADDR_ID    = 0;
assign MASTER_WR_ADDR       = 32'h2000_0000;
assign MASTER_WR_ADDR_LEN   = 0;
assign MASTER_WR_ADDR_BURST = 2'b01;
assign MASTER_WR_ADDR_VALID = (cu_wr_addr_st == ST_WR_ADDR_TRAN);

reg cu_wr_data_st, nt_wr_data_st;
localparam ST_WR_DATA_IDLE = 1'b0;
localparam ST_WR_DATA_TRAN = 1'b1;
always @(*) begin
    if(~rstn) nt_wr_data_st <= ST_WR_DATA_IDLE;
    else case (cu_wr_data_st)
        ST_WR_DATA_IDLE: nt_wr_data_st <= (btn_neg[1])?(ST_WR_DATA_TRAN):(ST_WR_DATA_IDLE);
        ST_WR_DATA_TRAN: nt_wr_data_st <= (MASTER_WR_DATA_VALID && MASTER_WR_DATA_READY && MASTER_WR_DATA_LAST)?(ST_WR_DATA_IDLE):(ST_WR_DATA_TRAN);
    endcase
end
always @(posedge clk) cu_wr_data_st <= nt_wr_data_st;

assign MASTER_WR_DATA       = trans_data;
assign MASTER_WR_DATA_LAST  = 1'b1;
assign MASTER_WR_STRB       = 4'b1111;
assign MASTER_WR_DATA_VALID = (cu_wr_data_st == ST_WR_DATA_TRAN);

assign MASTER_WR_BACK_READY = 1;


reg cu_rd_addr_st, nt_rd_addr_st;
localparam ST_RD_ADDR_IDLE = 1'b0;
localparam ST_RD_ADDR_TRAN = 1'b1;
always @(*) begin
    if(~rstn) nt_rd_addr_st <= ST_RD_ADDR_IDLE;
    else case (cu_rd_addr_st)
        ST_RD_ADDR_IDLE: nt_rd_addr_st <= (btn_neg[2])?(ST_RD_ADDR_TRAN):(ST_RD_ADDR_IDLE);
        ST_RD_ADDR_TRAN: nt_rd_addr_st <= (MASTER_RD_ADDR_VALID && MASTER_RD_ADDR_READY)?(ST_RD_ADDR_IDLE):(ST_RD_ADDR_TRAN);
    endcase
end
always @(posedge clk) cu_rd_addr_st <= nt_rd_addr_st;


assign MASTER_RD_ADDR_ID    = 0;
assign MASTER_RD_ADDR       = 32'h2000_0000;
assign MASTER_RD_ADDR_LEN   = 0;
assign MASTER_RD_ADDR_BURST = 2'b01;
assign MASTER_RD_ADDR_VALID = (cu_rd_addr_st == ST_RD_ADDR_TRAN);

assign MASTER_RD_DATA_READY = 1;
always @(posedge clk) begin
    if(~rstn) recv_data <= 0;
    else if(MASTER_RD_DATA_VALID && MASTER_RD_DATA_READY && MASTER_RD_DATA_LAST) recv_data <= MASTER_RD_DATA;
    else recv_data <= recv_data;
end


endmodule