`timescale  1ns/1ns
////////////////////////////////////////////////////////////////////////
// Author  : EmbedFire
// 实验平台: 野火FPGA系列开发板
// 公司    : http://www.embedfire.com
// 论坛    : http://www.firebbs.cn
// 淘宝    : https://fire-stm32.taobao.com
////////////////////////////////////////////////////////////////////////

module gmii_to_rgmii(
    //以太网GMII接口
    output             gmii_rx_clk , //GMII接收时钟
    output             gmii_rx_dv  , //GMII接收数据有效信号
    output      [7:0]  gmii_rxd    , //GMII接收数据
    output             gmii_tx_clk , //GMII发送时钟
    input              gmii_tx_en  , //GMII发送数据使能信号
    input       [7:0]  gmii_txd    , //GMII发送数据
    //以太网RGMII接口
    input              rgmii_rxc   , //RGMII接收时钟
    input              rgmii_rx_ctl, //RGMII接收数据控制信号
    input       [3:0]  rgmii_rxd   , //RGMII接收数据
    output             rgmii_txc   /* synthesis PAP_MARK_DEBUG=”true” */, //RGMII发送时钟
    output             rgmii_tx_ctl/* synthesis PAP_MARK_DEBUG=”true” */, //RGMII发送数据控制信号
    output      [3:0]  rgmii_txd   /* synthesis PAP_MARK_DEBUG=”true” */  //RGMII发送数据
    );


//*****************************************************
//**                    main code
//*****************************************************

assign gmii_tx_clk = gmii_rx_clk;

//RGMII接收
rgmii_rx u_rgmii_rx(
    .gmii_rx_clk   (gmii_rx_clk ),
    .rgmii_rxc     (rgmii_rxc   ),
    .rgmii_rx_ctl  (rgmii_rx_ctl),
    .rgmii_rxd     (rgmii_rxd   ),
    .gmii_tx_clk_phase(gmii_tx_clk_phase),
    .gmii_rx_dv    (gmii_rx_dv  ),
    .gmii_rxd      (gmii_rxd    )
    );

//RGMII发送
rgmii_tx u_rgmii_tx(
    .gmii_tx_clk   (gmii_tx_clk ),
    .gmii_tx_en    (gmii_tx_en  ),
    .gmii_txd      (gmii_txd    ),

    .gmii_tx_clk_phase(gmii_tx_clk_phase),
    .rgmii_txc     (rgmii_txc   ),
    .rgmii_tx_ctl  (rgmii_tx_ctl),
    .rgmii_txd     (rgmii_txd   )
    );

endmodule