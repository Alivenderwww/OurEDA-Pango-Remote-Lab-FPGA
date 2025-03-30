module axi_slave_default (
    //___________________其他接口_____________________//
    input  wire        clk          ,
    input  wire        rstn         ,

    //___________________AXI接口_____________________//
    output wire        SLAVE_CLK          , //向AXI总线提供的本主机时钟信号
    output wire        SLAVE_RSTN         , //向AXI总线提供的本主机复位信号

    input  wire [ 3:0] SLAVE_WR_ADDR_ID   , //写地址通道-ID
    input  wire [31:0] SLAVE_WR_ADDR      , //写地址通道-地址
    input  wire [ 7:0] SLAVE_WR_ADDR_LEN  , //写地址通道-突发长度-最小为0（1突发），最大为255（256突发）
    input  wire [ 1:0] SLAVE_WR_ADDR_BURST, //写地址通道-突发类型
    input  wire        SLAVE_WR_ADDR_VALID, //写地址通道-握手信号-有效
    output reg         SLAVE_WR_ADDR_READY, //写地址通道-握手信号-准备

    input  wire [31:0] SLAVE_WR_DATA      , //写数据通道-数据
    input  wire [ 3:0] SLAVE_WR_STRB      , //写数据通道-选通
    input  wire        SLAVE_WR_DATA_LAST , //写数据通道-last信号
    input  wire        SLAVE_WR_DATA_VALID, //写数据通道-握手信号-有效
    output reg         SLAVE_WR_DATA_READY, //写数据通道-握手信号-准备

    output reg  [ 3:0] SLAVE_WR_BACK_ID   , //写响应通道-ID
    output reg  [ 1:0] SLAVE_WR_BACK_RESP , //写响应通道-响应 //SLAVE_WR_DATA_LAST拉高的同时或者之后 00 01正常 10写错误 11地址有问题找不到从机
    output reg         SLAVE_WR_BACK_VALID, //写响应通道-握手信号-有效
    input  wire        SLAVE_WR_BACK_READY, //写响应通道-握手信号-准备

    input  wire [ 3:0] SLAVE_RD_ADDR_ID   , //读地址通道-ID
    input  wire [31:0] SLAVE_RD_ADDR      , //读地址通道-地址
    input  wire [ 7:0] SLAVE_RD_ADDR_LEN  , //读地址通道-突发长度。最小为0（1突发），最大为255（256突发）
    input  wire [ 1:0] SLAVE_RD_ADDR_BURST, //读地址通道-突发类型。
    input  wire        SLAVE_RD_ADDR_VALID, //读地址通道-握手信号-有效
    output reg         SLAVE_RD_ADDR_READY, //读地址通道-握手信号-准备

    output reg  [ 3:0] SLAVE_RD_BACK_ID   , //读数据通道-ID
    output reg  [31:0] SLAVE_RD_DATA      , //读数据通道-数据
    output reg  [ 1:0] SLAVE_RD_DATA_RESP , //读数据通道-响应
    output reg         SLAVE_RD_DATA_LAST , //读数据通道-last信号
    output reg         SLAVE_RD_DATA_VALID, //读数据通道-握手信号-有效
    input  wire        SLAVE_RD_DATA_READY  //读数据通道-握手信号-准备
);
//如果AXI总线某一个模块暂时不需要连接，用default模块代替。

assign SLAVE_CLK = clk;
assign SLAVE_RSTN = rstn;
assign SLAVE_WR_ADDR_READY = 0;
assign SLAVE_WR_DATA_READY = 0;
assign SLAVE_WR_BACK_ID    = 0;
assign SLAVE_WR_BACK_RESP  = 0;
assign SLAVE_WR_BACK_VALID = 0;
assign SLAVE_RD_ADDR_READY = 0;
assign SLAVE_RD_BACK_ID    = 0;
assign SLAVE_RD_DATA       = 0;
assign SLAVE_RD_DATA_RESP  = 0;
assign SLAVE_RD_DATA_LAST  = 0;
assign SLAVE_RD_DATA_VALID = 0;


endmodule