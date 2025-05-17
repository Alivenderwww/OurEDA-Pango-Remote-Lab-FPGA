`timescale  1ns/1ns
////////////////////////////////////////////////////////////////////////
// Author  : EmbedFire
// ʵ��ƽ̨: Ұ��FPGAϵ�п�����
// ��˾    : http://www.embedfire.com
// ��̳    : http://www.firebbs.cn
// �Ա�    : https://fire-stm32.taobao.com
////////////////////////////////////////////////////////////////////////

module rgmii_rx(
    //��̫��RGMII�ӿ�
    input              rgmii_rxc   , //RGMII����ʱ��
    input              rgmii_rx_ctl, //RGMII�������ݿ����ź�
    input       [3:0]  rgmii_rxd   , //RGMII��������

    //��̫��GMII�ӿ�
    output             gmii_rx_clk , //GMII����ʱ��
    output              gmii_tx_clk_phase,
    output   reg          gmii_rx_dv  , //GMII����������Ч�ź�
    output   reg   [7:0]  gmii_rxd      //GMII��������
    );

//wire define
//wire         rgmii_rxc_bufg;     //ȫ��ʱ�ӻ���
//wire         rgmii_rxc_bufio;    //ȫ��ʱ��IO����
//wire  [3:0]  rgmii_rxd_delay;    //rgmii_rxd������ʱ
//wire         rgmii_rx_ctl_delay; //rgmii_rx_ctl������ʱ
//wire  [1:0]  gmii_rxdv_t;        //��λGMII������Ч�ź�

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
    .clkin1   (rgmii_rxc     ),  //��̫������ʱ��
    .clkout0  (gmii_rx_clk_0 ),  //������λƫ�ƺ��ʱ��
    .clkout1  (gmii_tx_clk_phase),
    .rst  ( 1'b0 ),  //pll��λ
    .lock (            )   //pllʱ���ȶ���ʶ
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
.ISERDES_MODE ("DDR1TO2_SAME_PIPELINED"),   //:networking DDR 1:2 same pipelined�⴮ģʽ
.CASCADE_MODE("MASTER"),                    //����ѡ��
.BITSLIP_EN("FALSE"),                       //bitslipʹ��
.GRS_EN ("TRUE"),                           //ȫ�ָ�λʹ��
.NUM_ICE(1'b0),                             //ice��Ŀѡ��
.GRS_TYPE_Q0("RESET"),                      //ILOGIC gear��DFFxȫ���첽��λ���
.GRS_TYPE_Q1("RESET"),
.GRS_TYPE_Q2("RESET"),
.GRS_TYPE_Q3("RESET"),
.LRS_TYPE_Q0("ASYNC_RESET"),                //ILOGCI gear��DFFx���ظ�λ���
.LRS_TYPE_Q1("ASYNC_RESET"),
.LRS_TYPE_Q2("ASYNC_RESET"),
.LRS_TYPE_Q3("ASYNC_RESET")
) gtp_iserdes_inst0 (
.RST(1'b0),
.ICE0(1'b1),
.ICE1(1'b0),            //LOGICʱ��ʹ��
.DESCLK (gmii_rx_clk),  //ILOGIC�⴮����ʱ��
.ICLK (gmii_rx_clk),    //ILOGIC��һ������ʱ��
.ICLKDIV(gmii_rx_clk),  //ILOGIC����ʱ��
.DI (rgmii_rxd[0]),
.BITSLIP(),                             //��������
.ISHIFTIN0(),                           //���������ź�
.ISHIFTIN1(),
.IFIFO_WADDR(),                         //FIFOд��ַ��������
.IFIFO_RADDR(),
.DO({nc1,gmii_rxd_s[4],gmii_rxd_s[0]}), //�⴮���
.ISHIFTOUT0(),                          //��������ź�
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