module axi_master_default (
    //___________________其他接口_____________________//
    input  wire        clk          ,
    input  wire        rstn         ,

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
//如果AXI总线某一个模块暂时不需要连接，用default模块代替。

assign MASTER_CLK = clk;
rstn_sync rstn_sync_u(MASTER_CLK, rstn, MASTER_RSTN);
assign MASTER_RSTN = rstn;
assign MASTER_WR_ADDR_ID    = 0;
assign MASTER_WR_ADDR       = 0;
assign MASTER_WR_ADDR_LEN   = 0;
assign MASTER_WR_ADDR_BURST = 0;
assign MASTER_WR_ADDR_VALID = 0;
assign MASTER_WR_DATA       = 0;
assign MASTER_WR_STRB       = 0;
assign MASTER_WR_DATA_LAST  = 0;
assign MASTER_WR_DATA_VALID = 0;
assign MASTER_WR_BACK_READY = 0;
assign MASTER_RD_ADDR_ID    = 0;
assign MASTER_RD_ADDR       = 0;
assign MASTER_RD_ADDR_LEN   = 0;
assign MASTER_RD_ADDR_BURST = 0;
assign MASTER_RD_ADDR_VALID = 0;
assign MASTER_RD_DATA_READY = 0;

endmodule