interface AXI_INF #(
    parameter [31:0] ID_WIDTH = 2
)();
    logic [ID_WIDTH-1:0]    WR_ADDR_ID   ; //写地址通道-ID
    logic [31:0]            WR_ADDR      ; //写地址通道-地址
    logic [ 7:0]            WR_ADDR_LEN  ; //写地址通道-突发长度-最小为0（1突发），最大为255（256突发）
    logic [ 1:0]            WR_ADDR_BURST; //写地址通道-突发类型
    logic                   WR_ADDR_VALID; //写地址通道-握手信号-有效
    logic                   WR_ADDR_READY; //写地址通道-握手信号-准备
    logic [31:0]            WR_DATA      ; //写数据通道-数据
    logic [ 3:0]            WR_STRB      ; //写数据通道-选通
    logic                   WR_DATA_LAST ; //写数据通道-last信号
    logic                   WR_DATA_VALID; //写数据通道-握手信号-有效
    logic                   WR_DATA_READY; //写数据通道-握手信号-准备
    logic [ID_WIDTH-1:0]    WR_BACK_ID   ; //写响应通道-ID
    logic [ 1:0]            WR_BACK_RESP ; //写响应通道-响应
    logic                   WR_BACK_VALID; //写响应通道-握手信号-有效
    logic                   WR_BACK_READY; //写响应通道-握手信号-准备
    logic [ID_WIDTH-1:0]    RD_ADDR_ID   ; //读地址通道-ID
    logic [31:0]            RD_ADDR      ; //读地址通道-地址
    logic [ 7:0]            RD_ADDR_LEN  ; //读地址通道-突发长度。最小为0（1突发），最大为255（256突发）
    logic [ 1:0]            RD_ADDR_BURST; //读地址通道-突发类型。
    logic                   RD_ADDR_VALID; //读地址通道-握手信号-有效
    logic                   RD_ADDR_READY; //读地址通道-握手信号-准备
    logic [ID_WIDTH-1:0]    RD_BACK_ID   ; //读数据通道-ID
    logic [31:0]            RD_DATA      ; //读数据通道-数据
    logic [ 1:0]            RD_DATA_RESP ; //读数据通道-响应
    logic                   RD_DATA_LAST ; //读数据通道-last信号
    logic                   RD_DATA_VALID; //读数据通道-握手信号-有效
    logic                   RD_DATA_READY; //读数据通道-握手信号-准备
    modport M(
        output WR_ADDR_ID   , //写地址通道-ID
        output WR_ADDR      , //写地址通道-地址
        output WR_ADDR_LEN  , //写地址通道-突发长度-最小为0（1突发），最大为255（256突发）
        output WR_ADDR_BURST, //写地址通道-突发类型
        output WR_ADDR_VALID, //写地址通道-握手信号-有效
        input  WR_ADDR_READY, //写地址通道-握手信号-准备

        output WR_DATA      , //写数据通道-数据
        output WR_STRB      , //写数据通道-选通
        output WR_DATA_LAST , //写数据通道-last信号
        output WR_DATA_VALID, //写数据通道-握手信号-有效
        input  WR_DATA_READY, //写数据通道-握手信号-准备

        input  WR_BACK_ID   , //写响应通道-ID
        input  WR_BACK_RESP , //写响应通道-响应
        input  WR_BACK_VALID, //写响应通道-握手信号-有效
        output WR_BACK_READY, //写响应通道-握手信号-准备

        output RD_ADDR_ID   , //读地址通道-ID
        output RD_ADDR      , //读地址通道-地址
        output RD_ADDR_LEN  , //读地址通道-突发长度。最小为0（1突发），最大为255（256突发）
        output RD_ADDR_BURST, //读地址通道-突发类型。
        output RD_ADDR_VALID, //读地址通道-握手信号-有效
        input  RD_ADDR_READY, //读地址通道-握手信号-准备

        input  RD_BACK_ID   , //读数据通道-ID
        input  RD_DATA      , //读数据通道-数据
        input  RD_DATA_RESP , //读数据通道-响应
        input  RD_DATA_LAST , //读数据通道-last信号
        input  RD_DATA_VALID, //读数据通道-握手信号-有效
        output RD_DATA_READY  //读数据通道-握手信号-准备
    );

    modport S(
        input  WR_ADDR_ID   , //写地址通道-ID
        input  WR_ADDR      , //写地址通道-地址
        input  WR_ADDR_LEN  , //写地址通道-突发长度-最小为0（1突发），最大为255（256突发）
        input  WR_ADDR_BURST, //写地址通道-突发类型
        input  WR_ADDR_VALID, //写地址通道-握手信号-有效
        output WR_ADDR_READY, //写地址通道-握手信号-准备

        input  WR_DATA      , //写数据通道-数据
        input  WR_STRB      , //写数据通道-选通
        input  WR_DATA_LAST , //写数据通道-last信号
        input  WR_DATA_VALID, //写数据通道-握手信号-有效
        output WR_DATA_READY, //写数据通道-握手信号-准备

        output WR_BACK_ID   , //写响应通道-ID
        output WR_BACK_RESP , //写响应通道-响应 //SLAVE_WR_DATA_LAST拉高的同时或者之后 00 01正常 10写错误 11地址有问题找不到从机
        output WR_BACK_VALID, //写响应通道-握手信号-有效
        input  WR_BACK_READY, //写响应通道-握手信号-准备

        input  RD_ADDR_ID   , //读地址通道-ID
        input  RD_ADDR      , //读地址通道-地址
        input  RD_ADDR_LEN  , //读地址通道-突发长度。最小为0（1突发），最大为255（256突发）
        input  RD_ADDR_BURST, //读地址通道-突发类型。
        input  RD_ADDR_VALID, //读地址通道-握手信号-有效
        output RD_ADDR_READY, //读地址通道-握手信号-准备

        output RD_BACK_ID   , //读数据通道-ID
        output RD_DATA      , //读数据通道-数据
        output RD_DATA_RESP , //读数据通道-响应
        output RD_DATA_LAST , //读数据通道-last信号
        output RD_DATA_VALID, //读数据通道-握手信号-有效
        input  RD_DATA_READY  //读数据通道-握手信号-准备
    );
    
endinterface