`timescale  1ns/1ns
////////////////////////////////////////////////////////////////////////
// Author  : EmbedFire
// 实验平台: 野火FPGA系列开发板
// 公司    : http://www.embedfire.com
// 论坛    : http://www.firebbs.cn
// 淘宝    : https://fire-stm32.taobao.com
////////////////////////////////////////////////////////////////////////

module rgmii_rx(
    //以太网RGMII接口
    input              rgmii_rxc   , //RGMII接收时钟
    input              rgmii_rx_ctl, //RGMII接收数据控制信号
    input       [3:0]  rgmii_rxd   , //RGMII接收数据

    //以太网GMII接口
    output             gmii_rx_clk , //GMII接收时钟
    output              gmii_tx_clk_phase,
    output   reg          gmii_rx_dv  , //GMII接收数据有效信号
    output   reg   [7:0]  gmii_rxd      //GMII接收数据
    );

//wire define
//wire         rgmii_rxc_bufg;     //全局时钟缓存
//wire         rgmii_rxc_bufio;    //全局时钟IO缓存
//wire  [3:0]  rgmii_rxd_delay;    //rgmii_rxd输入延时
//wire         rgmii_rx_ctl_delay; //rgmii_rx_ctl输入延时
//wire  [1:0]  gmii_rxdv_t;        //两位GMII接收有效信号

//*****************************************************
//**                    main code
//*****************************************************

wire            gmii_rx_dv_s;
wire  [ 7:0]    gmii_rxd_s;
//*****************************************************
//**                    main code
//*****************************************************
wire gmii_rx_clk_0;
clk_phase u_clk_phase
(
    .clkin1   (rgmii_rxc     ),  //以太网接收时钟
    .clkout0  (gmii_rx_clk_0 ),  //经过相位偏移后的时钟
    .clkout1  (gmii_tx_clk_phase),
    .rst  ( 1'b0 ),  //pll复位
    .lock (            )   //pll时钟稳定标识
);

GTP_CLKBUFG GTP_CLKBUFG_RXSHFT(
    .CLKIN     (gmii_rx_clk_0),//rgmii_rxc_ibuf
    .CLKOUT    (gmii_rx_clk)
);



always @(posedge gmii_rx_clk)
begin
    gmii_rxd   = gmii_rxd_s;
    gmii_rx_dv = gmii_rx_dv_s;
end

wire [5:0] nc1;
GTP_ISERDES_E2 #
(
.ISERDES_MODE ("DDR1TO2_SAME_PIPELINED"),   //:networking DDR 1:2 same pipelined解串模式
.CASCADE_MODE("MASTER"),                    //主从选择
.BITSLIP_EN("FALSE"),                       //bitslip使能
.GRS_EN ("TRUE"),                           //全局复位使能
.NUM_ICE(1'b0),                             //ice数目选择
.GRS_TYPE_Q0("RESET"),                      //ILOGIC gear中DFFx全局异步复位结果
.GRS_TYPE_Q1("RESET"),
.GRS_TYPE_Q2("RESET"),
.GRS_TYPE_Q3("RESET"),
.LRS_TYPE_Q0("ASYNC_RESET"),                //ILOGCI gear中DFFx本地复位结果
.LRS_TYPE_Q1("ASYNC_RESET"),
.LRS_TYPE_Q2("ASYNC_RESET"),
.LRS_TYPE_Q3("ASYNC_RESET")
) gtp_iserdes_inst0 (
.RST(1'b0),
.ICE0(1'b1),
.ICE1(1'b0),            //LOGIC时钟使能
.DESCLK (gmii_rx_clk),  //ILOGIC解串高速时钟
.ICLK (gmii_rx_clk),    //ILOGIC第一级高速时钟
.ICLKDIV(gmii_rx_clk),  //ILOGIC低速时钟
.DI (rgmii_rxd[0]),
.BITSLIP(),                             //数据输入
.ISHIFTIN0(),                           //级联输入信号
.ISHIFTIN1(),
.IFIFO_WADDR(),                         //FIFO写地址，格雷码
.IFIFO_RADDR(),
.DO({nc1,gmii_rxd_s[4],gmii_rxd_s[0]}), //解串输出
.ISHIFTOUT0(),                          //级联输出信号
.ISHIFTOUT1()
);


wire [5:0] nc2;
GTP_ISERDES_E2 #
(
.ISERDES_MODE ("DDR1TO2_SAME_PIPELINED"), 
.CASCADE_MODE("MASTER"),
.BITSLIP_EN("FALSE"),
.GRS_EN ("TRUE"),
.NUM_ICE(1'b0),
.GRS_TYPE_Q0("RESET"),
.GRS_TYPE_Q1("RESET"),
.GRS_TYPE_Q2("RESET"),
.GRS_TYPE_Q3("RESET"),
.LRS_TYPE_Q0("ASYNC_RESET"),
.LRS_TYPE_Q1("ASYNC_RESET"),
.LRS_TYPE_Q2("ASYNC_RESET"),
.LRS_TYPE_Q3("ASYNC_RESET")
) gtp_iserdes_inst1 (
.RST(1'b0),
.ICE0(1'b1),
.ICE1(1'b0),
.DESCLK (gmii_rx_clk),
.ICLK (gmii_rx_clk),
.ICLKDIV(gmii_rx_clk),
.DI (rgmii_rxd[1]),
.BITSLIP(),
.ISHIFTIN0(),
.ISHIFTIN1(),
.IFIFO_WADDR(),
.IFIFO_RADDR(),
.DO({nc2,gmii_rxd_s[5],gmii_rxd_s[1]}),
.ISHIFTOUT0(),
.ISHIFTOUT1()
);


wire [5:0] nc3;
GTP_ISERDES_E2 #
(
.ISERDES_MODE ("DDR1TO2_SAME_PIPELINED"), 
.CASCADE_MODE("MASTER"),
.BITSLIP_EN("FALSE"),
.GRS_EN ("TRUE"),
.NUM_ICE(1'b0),
.GRS_TYPE_Q0("RESET"),
.GRS_TYPE_Q1("RESET"),
.GRS_TYPE_Q2("RESET"),
.GRS_TYPE_Q3("RESET"),
.LRS_TYPE_Q0("ASYNC_RESET"),
.LRS_TYPE_Q1("ASYNC_RESET"),
.LRS_TYPE_Q2("ASYNC_RESET"),
.LRS_TYPE_Q3("ASYNC_RESET")
) gtp_iserdes_inst2 (
.RST(1'b0),
.ICE0(1'b1),
.ICE1(1'b0),
.DESCLK (gmii_rx_clk),
.ICLK (gmii_rx_clk),
.ICLKDIV(gmii_rx_clk),
.DI (rgmii_rxd[2]),
.BITSLIP(),
.ISHIFTIN0(),
.ISHIFTIN1(),
.IFIFO_WADDR(),
.IFIFO_RADDR(),
.DO ({nc3,gmii_rxd_s[6],gmii_rxd_s[2]}),
.ISHIFTOUT0(),
.ISHIFTOUT1()
);

wire [5:0] nc4;
GTP_ISERDES_E2 #
(
.ISERDES_MODE ("DDR1TO2_SAME_PIPELINED"), 
.CASCADE_MODE("MASTER"),
.BITSLIP_EN("FALSE"),
.GRS_EN ("TRUE"),
.NUM_ICE(1'b0),
.GRS_TYPE_Q0("RESET"),
.GRS_TYPE_Q1("RESET"),
.GRS_TYPE_Q2("RESET"),
.GRS_TYPE_Q3("RESET"),
.LRS_TYPE_Q0("ASYNC_RESET"),
.LRS_TYPE_Q1("ASYNC_RESET"),
.LRS_TYPE_Q2("ASYNC_RESET"),
.LRS_TYPE_Q3("ASYNC_RESET")
) gtp_iserdes_inst3 (
.RST(1'b0),
.ICE0(1'b1),
.ICE1(1'b0),
.DESCLK (gmii_rx_clk),
.ICLK (gmii_rx_clk),
.ICLKDIV(gmii_rx_clk),
.DI (rgmii_rxd[3]),
.BITSLIP(),
.ISHIFTIN0(),
.ISHIFTIN1(),
.IFIFO_WADDR(),
.IFIFO_RADDR(),
.DO ({nc4,gmii_rxd_s[7],gmii_rxd_s[3]}),
.ISHIFTOUT0(),
.ISHIFTOUT1()
);

wire [5:0] nc5;
GTP_ISERDES_E2 #
(
.ISERDES_MODE ("DDR1TO2_SAME_PIPELINED"), 
.CASCADE_MODE("MASTER"),
.BITSLIP_EN("FALSE"),
.GRS_EN ("TRUE"),
.NUM_ICE(1'b0),
.GRS_TYPE_Q0("RESET"),
.GRS_TYPE_Q1("RESET"),
.GRS_TYPE_Q2("RESET"),
.GRS_TYPE_Q3("RESET"),
.LRS_TYPE_Q0("ASYNC_RESET"),
.LRS_TYPE_Q1("ASYNC_RESET"),
.LRS_TYPE_Q2("ASYNC_RESET"),
.LRS_TYPE_Q3("ASYNC_RESET")
) gtp_iserdes_inst4 (
.RST(1'b0),
.ICE0(1'b1),
.ICE1(1'b0),
.DESCLK (gmii_rx_clk),
.ICLK (gmii_rx_clk),
.ICLKDIV(gmii_rx_clk),
.DI (rgmii_rx_ctl),
.BITSLIP(),
.ISHIFTIN0(),
.ISHIFTIN1(),
.IFIFO_WADDR(),
.IFIFO_RADDR(),
.DO ({nc5,rgmii_rx_ctl_s,gmii_rx_dv_s}),
.ISHIFTOUT0(),
.ISHIFTOUT1()
);

endmodule