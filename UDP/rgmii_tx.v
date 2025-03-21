`timescale  1ns/1ns
////////////////////////////////////////////////////////////////////////
// Author  : EmbedFire
// 实验平台: 野火FPGA系列开发板
// 公司    : http://www.embedfire.com
// 论坛    : http://www.firebbs.cn
// 淘宝    : https://fire-stm32.taobao.com
////////////////////////////////////////////////////////////////////////

module rgmii_tx(
    //GMII发送端口
    input              gmii_tx_clk , //GMII发送时钟
    input              gmii_tx_en  , //GMII输出数据有效信号
    input       [7:0]  gmii_txd    , //GMII输出数据
    input              gmii_tx_clk_phase,
    //RGMII发送端口
    output             rgmii_txc   , //RGMII发送数据时钟
    output             rgmii_tx_ctl, //RGMII输出数据有效信号
    output      [3:0]  rgmii_txd     //RGMII输出数据
    );

//*****************************************************
//**                    main code
//*****************************************************

// registers
reg             tx_reset_d1    ;
reg             tx_reset_sync  ;
reg             rx_reset_d1    ;

reg   [ 7:0]    gmii_txd_r     ;
reg   [ 7:0]    gmii_txd_r_d1  ;

reg             gmii_tx_en_r   ;
reg             gmii_tx_en_r_d1;

reg             gmii_tx_er_r   ;

reg             rgmii_tx_ctl_r ;
reg   [ 3:0]    gmii_txd_low   ;

// wire
wire            padt1   ;
wire            padt2   ;
wire            padt3   ;
wire            padt4   ;
wire            padt5   ;
wire            padt6   ;
wire            stx_txc ;
wire            stx_ctr ;
wire  [3:0]     stxd_rgm;

assign  reset = 1'b0;
assign  gmii_tx_er = 1'b0;


//*****************************************************
//**                    main code
//*****************************************************

always @(posedge gmii_tx_clk) begin
    tx_reset_d1   <= reset;
    tx_reset_sync <= tx_reset_d1;
end

always @(posedge gmii_tx_clk) begin
    if (tx_reset_sync == 1'b1) begin
        gmii_txd_r   <= 8'h0;
        gmii_tx_en_r <= 1'b0;
        gmii_tx_er_r <= 1'b0;
    end
    else
    begin
        gmii_txd_r      <= gmii_txd;
        gmii_tx_en_r    <= gmii_tx_en;
        gmii_tx_er_r    <= gmii_tx_er;
        gmii_txd_r_d1   <= gmii_txd_r;
        gmii_tx_en_r_d1 <= gmii_tx_en_r;
    end
end

always @(posedge gmii_tx_clk)
begin
    rgmii_tx_ctl_r = gmii_tx_en_r ^ gmii_tx_er_r;
    gmii_txd_low   = gmii_txd_r[7:4];
end

GTP_OSERDES_E2 #
(
. GRS_EN ("TRUE"),
. OSERDES_MODE ("DDR2TO1_SAME_EDGE"),
. TSERDES_EN ("FALSE"),
. UPD0_SHIFT_EN ("FALSE"), 
. UPD1_SHIFT_EN ("FALSE"), 
. INIT_SET (2'b00), 
. GRS_TYPE_DQ ("RESET"), 
. LRS_TYPE_DQ0 ("ASYNC_RESET"), 
. LRS_TYPE_DQ1 ("ASYNC_RESET"), 
. LRS_TYPE_DQ2 ("ASYNC_RESET"), 
. LRS_TYPE_DQ3 ("ASYNC_RESET"), 
. GRS_TYPE_TQ ("RESET"), 
. LRS_TYPE_TQ0 ("ASYNC_RESET"), 
. LRS_TYPE_TQ1 ("ASYNC_RESET"), 
. LRS_TYPE_TQ2 ("ASYNC_RESET"), 
. LRS_TYPE_TQ3 ("ASYNC_RESET"), 
. TRI_EN  ("FALSE"),
. TBYTE_EN ("FALSE"), 
. MIPI_EN ("FALSE"), 
. OCASCADE_EN ("FALSE")
) GTP_OSERDES_E2_INST5 (
. RST (tx_reset_sync),
. OCE (1'b1),
. TCE (1'b0),
. OCLKDIV (gmii_tx_clk),
. SERCLK (gmii_tx_clk),
. OCLK (gmii_tx_clk),
. MIPI_CTRL (),
. UPD0_SHIFT (1'b0),
. UPD1_SHIFT (1'b0),
. OSHIFTIN0 (),
. OSHIFTIN1 (),
. DI (8'b00000001),    
. TI (),
. TBYTE_IN (),
. OSHIFTOUT0 (),
. OSHIFTOUT1 (),
. DO (stx_txc),
. TQ (padt6)
);
GTP_OUTBUF  gtp_outbuft6
(
    .I    (stx_txc  ),
    .O    (rgmii_txc)
);


GTP_OSERDES_E2 #
(
. GRS_EN ("TRUE"),
. OSERDES_MODE ("DDR2TO1_SAME_EDGE"),
. TSERDES_EN ("FALSE"),
. UPD0_SHIFT_EN ("FALSE"), 
. UPD1_SHIFT_EN ("FALSE"), 
. INIT_SET (2'b00), 
. GRS_TYPE_DQ ("RESET"), 
. LRS_TYPE_DQ0 ("ASYNC_RESET"), 
. LRS_TYPE_DQ1 ("ASYNC_RESET"), 
. LRS_TYPE_DQ2 ("ASYNC_RESET"), 
. LRS_TYPE_DQ3 ("ASYNC_RESET"), 
. GRS_TYPE_TQ ("RESET"), 
. LRS_TYPE_TQ0 ("ASYNC_RESET"), 
. LRS_TYPE_TQ1 ("ASYNC_RESET"), 
. LRS_TYPE_TQ2 ("ASYNC_RESET"), 
. LRS_TYPE_TQ3 ("ASYNC_RESET"), 
. TRI_EN  ("FALSE"),
. TBYTE_EN ("FALSE"), 
. MIPI_EN ("FALSE"), 
. OCASCADE_EN ("FALSE")
) GTP_OSERDES_E2_INST1 (
. RST (tx_reset_sync),
. OCE (1'b1),
. TCE (1'b0),
. OCLKDIV (gmii_tx_clk),
. SERCLK (gmii_tx_clk),
. OCLK (gmii_tx_clk),
. MIPI_CTRL (),
. UPD0_SHIFT (1'b0),
. UPD1_SHIFT (1'b0),
. OSHIFTIN0 (),
. OSHIFTIN1 (),
. DI ({6'd0,gmii_txd_low[3],gmii_txd_r_d1[3]}),    // DDR capture data
. TI (),
. TBYTE_IN (),
. OSHIFTOUT0 (),
. OSHIFTOUT1 (),
. DO (stxd_rgm[3]),
. TQ (padt2)
);
GTP_OUTBUF  gtp_outbuft2
(
    .I    (stxd_rgm[3]),
    .O    (rgmii_txd[3])
);


GTP_OSERDES_E2 #
(
. GRS_EN ("TRUE"),
. OSERDES_MODE ("DDR2TO1_SAME_EDGE"),
. TSERDES_EN ("FALSE"),
. UPD0_SHIFT_EN ("FALSE"), 
. UPD1_SHIFT_EN ("FALSE"), 
. INIT_SET (2'b00), 
. GRS_TYPE_DQ ("RESET"), 
. LRS_TYPE_DQ0 ("ASYNC_RESET"), 
. LRS_TYPE_DQ1 ("ASYNC_RESET"), 
. LRS_TYPE_DQ2 ("ASYNC_RESET"), 
. LRS_TYPE_DQ3 ("ASYNC_RESET"), 
. GRS_TYPE_TQ ("RESET"), 
. LRS_TYPE_TQ0 ("ASYNC_RESET"), 
. LRS_TYPE_TQ1 ("ASYNC_RESET"), 
. LRS_TYPE_TQ2 ("ASYNC_RESET"), 
. LRS_TYPE_TQ3 ("ASYNC_RESET"), 
. TRI_EN  ("FALSE"),
. TBYTE_EN ("FALSE"), 
. MIPI_EN ("FALSE"), 
. OCASCADE_EN ("FALSE")
) GTP_OSERDES_E2_INST2 (
. RST (tx_reset_sync),
. OCE (1'b1),
. TCE (1'b0),
. OCLKDIV (gmii_tx_clk),
. SERCLK (gmii_tx_clk),
. OCLK (gmii_tx_clk),
. MIPI_CTRL (),
. UPD0_SHIFT (1'b0),
. UPD1_SHIFT (1'b0),
. OSHIFTIN0 (),
. OSHIFTIN1 (),
. DI ({6'd0,gmii_txd_low[2],gmii_txd_r_d1[2]}),
. TI (),
. TBYTE_IN (),
. OSHIFTOUT0 (),
. OSHIFTOUT1 (),
. DO (stxd_rgm[2]),
. TQ (padt3)
);
GTP_OUTBUF  gtp_outbuft3
(    
    .I    (stxd_rgm[2]),
    .O    (rgmii_txd[2])
);


GTP_OSERDES_E2 #
(
. GRS_EN ("TRUE"),
. OSERDES_MODE ("DDR2TO1_SAME_EDGE"),
. TSERDES_EN ("FALSE"),
. UPD0_SHIFT_EN ("FALSE"), 
. UPD1_SHIFT_EN ("FALSE"), 
. INIT_SET (2'b00), 
. GRS_TYPE_DQ ("RESET"), 
. LRS_TYPE_DQ0 ("ASYNC_RESET"), 
. LRS_TYPE_DQ1 ("ASYNC_RESET"), 
. LRS_TYPE_DQ2 ("ASYNC_RESET"), 
. LRS_TYPE_DQ3 ("ASYNC_RESET"), 
. GRS_TYPE_TQ ("RESET"), 
. LRS_TYPE_TQ0 ("ASYNC_RESET"), 
. LRS_TYPE_TQ1 ("ASYNC_RESET"), 
. LRS_TYPE_TQ2 ("ASYNC_RESET"), 
. LRS_TYPE_TQ3 ("ASYNC_RESET"), 
. TRI_EN  ("FALSE"),
. TBYTE_EN ("FALSE"), 
. MIPI_EN ("FALSE"), 
. OCASCADE_EN ("FALSE")
) GTP_OSERDES_E2_INST3 (
. RST (tx_reset_sync),
. OCE (1'b1),
. TCE (1'b0),
. OCLKDIV (gmii_tx_clk),
. SERCLK (gmii_tx_clk),
. OCLK (gmii_tx_clk),
. MIPI_CTRL (),
. UPD0_SHIFT (1'b0),
. UPD1_SHIFT (1'b0),
. OSHIFTIN0 (),
. OSHIFTIN1 (),
. DI ({6'd0,gmii_txd_low[1],gmii_txd_r_d1[1]}),
. TI (),
. TBYTE_IN (),
. OSHIFTOUT0 (),
. OSHIFTOUT1 (),
. DO (stxd_rgm[1]),
. TQ (padt4)
);
GTP_OUTBUF  gtp_outbuft4
(
    .I    (stxd_rgm[1]),
    .O    (rgmii_txd[1])
);


GTP_OSERDES_E2 #
(
. GRS_EN ("TRUE"),
. OSERDES_MODE ("DDR2TO1_SAME_EDGE"),
. TSERDES_EN ("FALSE"),
. UPD0_SHIFT_EN ("FALSE"), 
. UPD1_SHIFT_EN ("FALSE"), 
. INIT_SET (2'b00), 
. GRS_TYPE_DQ ("RESET"), 
. LRS_TYPE_DQ0 ("ASYNC_RESET"), 
. LRS_TYPE_DQ1 ("ASYNC_RESET"), 
. LRS_TYPE_DQ2 ("ASYNC_RESET"), 
. LRS_TYPE_DQ3 ("ASYNC_RESET"), 
. GRS_TYPE_TQ ("RESET"), 
. LRS_TYPE_TQ0 ("ASYNC_RESET"), 
. LRS_TYPE_TQ1 ("ASYNC_RESET"), 
. LRS_TYPE_TQ2 ("ASYNC_RESET"), 
. LRS_TYPE_TQ3 ("ASYNC_RESET"), 
. TRI_EN  ("FALSE"),
. TBYTE_EN ("FALSE"), 
. MIPI_EN ("FALSE"), 
. OCASCADE_EN ("FALSE")
) GTP_OSERDES_E2_INST4 (
. RST (tx_reset_sync),
. OCE (1'b1),
. TCE (1'b0),
. OCLKDIV (gmii_tx_clk),
. SERCLK (gmii_tx_clk),
. OCLK (gmii_tx_clk),
. MIPI_CTRL (),
. UPD0_SHIFT (1'b0),
. UPD1_SHIFT (1'b0),
. OSHIFTIN0 (),
. OSHIFTIN1 (),
. DI ({6'd0,gmii_txd_low[0],gmii_txd_r_d1[0]}),
. TI (),
. TBYTE_IN (),
. OSHIFTOUT0 (),
. OSHIFTOUT1 (),
. DO (stxd_rgm[0]),
. TQ (padt5)
);
GTP_OUTBUF  gtp_outbuft5
(
    .I    (stxd_rgm[0]),
    .O    (rgmii_txd[0])
);


//输出双沿采样寄存器 (rgmii_tx_ctl)
GTP_OSERDES_E2 #
(
. GRS_EN ("TRUE"),
. OSERDES_MODE ("DDR2TO1_SAME_EDGE"),
. TSERDES_EN ("FALSE"),
. UPD0_SHIFT_EN ("FALSE"), 
. UPD1_SHIFT_EN ("FALSE"), 
. INIT_SET (2'b00), 
. GRS_TYPE_DQ ("RESET"), 
. LRS_TYPE_DQ0 ("ASYNC_RESET"), 
. LRS_TYPE_DQ1 ("ASYNC_RESET"), 
. LRS_TYPE_DQ2 ("ASYNC_RESET"), 
. LRS_TYPE_DQ3 ("ASYNC_RESET"), 
. GRS_TYPE_TQ ("RESET"), 
. LRS_TYPE_TQ0 ("ASYNC_RESET"), 
. LRS_TYPE_TQ1 ("ASYNC_RESET"), 
. LRS_TYPE_TQ2 ("ASYNC_RESET"), 
. LRS_TYPE_TQ3 ("ASYNC_RESET"), 
. TRI_EN  ("FALSE"),
. TBYTE_EN ("FALSE"), 
. MIPI_EN ("FALSE"), 
. OCASCADE_EN ("FALSE")
) GTP_OSERDES_E2_INST0 (
. RST (tx_reset_sync),
. OCE (1'b1),
. TCE (1'b0),
. OCLKDIV (gmii_tx_clk),
. SERCLK (gmii_tx_clk),
. OCLK (gmii_tx_clk),
. MIPI_CTRL (),
. UPD0_SHIFT (1'b0),
. UPD1_SHIFT (1'b0),
. OSHIFTIN0 (),
. OSHIFTIN1 (),
. DI ({6'd0,rgmii_tx_ctl_r,gmii_tx_en_r_d1}),
. TI (),
. TBYTE_IN (),
. OSHIFTOUT0 (),
. OSHIFTOUT1 (),
. DO (stx_ctr),
. TQ (padt1)
);
 GTP_OUTBUF  gtp_outbuft1
(
    .I    (stx_ctr     ),
    .O    (rgmii_tx_ctl)
); 

endmodule