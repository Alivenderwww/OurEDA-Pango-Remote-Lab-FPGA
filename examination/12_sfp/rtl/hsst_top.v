module hsst_top (
    input clk,
    input rstn,
    input i_p_refckn_0,
    input i_p_refckp_0,
    output [7:0] led
);
wire i_free_clk;
wire i_pll_rst_0;
wire o_pll_done_0;
wire o_txlane_done_3;
wire o_rxlane_done_3;
wire o_p_clk2core_tx_3;
wire i_p_tx3_clk_fr_core;
wire o_p_clk2core_rx_3;
wire i_p_rx3_clk_fr_core;
wire o_p_pll_lock_0;
wire o_p_rx_sigdet_sta_3;
wire o_p_lx_cdr_align_3;
wire i_p_l3rxn;
wire i_p_l3rxp;
wire o_p_l3txn;
wire o_p_l3txp;
wire [3:0] i_tdispsel_3;
wire [3:0] i_tdispctrl_3;
wire [2:0] o_rxstatus_3;
wire [3:0] o_rdisper_3;
wire [3:0] o_rdecer_3;
wire txclk;
reg [31:0] i_txd_3;
reg [ 3:0] i_txk_3;
wire rxclk;
wire [31:0] o_rxd_3;
wire [ 3:0] o_rxk_3;
assign i_free_clk                = clk;
assign i_pll_rst_0               = ~rstn;
assign i_p_tx3_clk_fr_core       = o_p_clk2core_tx_3; 
assign i_p_rx3_clk_fr_core       = o_p_clk2core_rx_3;
assign txclk                     = i_p_tx3_clk_fr_core;
assign rxclk                     = i_p_rx3_clk_fr_core;
hsst hsst_inst (
  .i_free_clk               (i_free_clk         ), //复位序列参考时钟 
  .i_pll_rst_0              (i_pll_rst_0        ), //pll复位
  .i_wtchdg_clr_0           (),                    // 
  .o_wtchdg_st_0            (),                    //
  .i_p_refckn_0             (i_p_refckn_0       ), //pll参考差分时钟
  .i_p_refckp_0             (i_p_refckp_0       ), //
  .o_pll_done_0             (o_pll_done_0       ), //pll复位完成
  .o_txlane_done_3          (o_txlane_done_3    ), //tx通道初始化完成 
  .o_rxlane_done_3          (o_rxlane_done_3    ), //rx通道初始化完成
  .o_p_pll_lock_0           (o_p_pll_lock_0     ), //pll lock信号
  .o_p_rx_sigdet_sta_3      (o_p_rx_sigdet_sta_3), //sigdet_sta状态信号
  .o_p_lx_cdr_align_3       (o_p_lx_cdr_align_3 ), //cdr_align状态信号
  .o_p_clk2core_tx_3        (o_p_clk2core_tx_3  ), //output传输时钟
  .i_p_tx3_clk_fr_core      (i_p_tx3_clk_fr_core), //input
  .o_p_clk2core_rx_3        (o_p_clk2core_rx_3  ), //output接收时钟
  .i_p_rx3_clk_fr_core      (i_p_rx3_clk_fr_core), //input
  .i_p_pcs_word_align_en_3  (1'b1               ), //使能word_align
  .i_p_l3rxn                (i_p_l3rxn          ), //差分数据线
  .i_p_l3rxp                (i_p_l3rxp          ), //差分数据线
  .o_p_l3txn                (o_p_l3txn          ), //差分数据线
  .o_p_l3txp                (o_p_l3txp          ), //差分数据线
  .i_txd_3                  (i_txd_3            ), //传输的32位数据
  .i_tdispsel_3             (i_tdispsel_3       ), //
  .i_tdispctrl_3            (i_tdispctrl_3      ), //
  .i_txk_3                  (i_txk_3            ), //传输的数据类型，0：普通数据，1：K码
  .o_rxstatus_3             (o_rxstatus_3       ), //
  .o_rxd_3                  (o_rxd_3            ), //接收的32位数据
  .o_rdisper_3              (o_rdisper_3        ), //
  .o_rdecer_3               (o_rdecer_3         ), //
  .o_rxk_3                  (o_rxk_3            )  //接收的数据类型，0：普通数据，1：K码
);
//*******************************************************************//

reg [ 2:0] tx_state;
reg [15:0] txcnt;
wire tx_rstn = rstn && o_txlane_done_3 && o_rxlane_done_3;
always @(posedge txclk or negedge tx_rstn)begin
    if(~tx_rstn)begin
        i_txd_3 <= 32'hBCBCBCBC;
        i_txk_3 <=  4'b1111;
    end
    else if(tx_state == 0)begin
        i_txd_3 <= 32'hBCBCBCBC;
        i_txk_3 <=  4'b1111;
    end
    else if(tx_state == 1)begin
        i_txd_3 <= 32'h00000000;
        i_txk_3 <=  4'b0000;
    end
    else if(tx_state == 2)begin
        i_txd_3 <= i_txd_3 + 1;
        i_txk_3 <=  4'b0000;
    end
end
always @(posedge txclk or negedge tx_rstn)begin
    if(~tx_rstn)begin
        tx_state <= 0;
    end
    else if(tx_state == 0)begin
        if(txcnt == 7)
            tx_state <= 1;
        else 
            tx_state <= 0;
    end
    else if(tx_state == 1)begin
        tx_state <= 2;
    end
    else if(tx_state == 2)begin
        if(txcnt == 1032)
            tx_state <= 0;
        else 
            tx_state <= 2;
    end
end
always @(posedge txclk or negedge tx_rstn)begin
    if(~tx_rstn)
        txcnt <= 0;
    else if(txcnt == 1032)
        txcnt <= 0;
    else 
        txcnt <= txcnt + 1;
end
wire Word_Alignment_rstn = rstn && o_txlane_done_3 && o_rxlane_done_3;
wire data_valid;
wire [31:0] data_af_align;
wire data_last;
Word_Alignment_32bit  Word_Alignment_32bit_inst (
    .clk            (rxclk              ),
    .rstn           (Word_Alignment_rstn),
    .data_bf_align  (o_rxd_3            ),
    .rxk            (o_rxk_3            ),
    .data_valid     (data_valid         ),
    .data_af_align  (data_af_align      ),
    .data_done      (data_last          )
  );
//**********************************//

reg [31:0] data_bf_Alignment_judge;
reg [31:0] data_af_Alignment_judge;

always@(posedge rxclk or negedge Word_Alignment_rstn)begin
    if(~Word_Alignment_rstn)data_bf_Alignment_judge <= 0;
    else if(o_rxk_3 == 4'b0000) data_bf_Alignment_judge <= data_bf_Alignment_judge + 1;
    else data_bf_Alignment_judge <= 0;
end
always@(posedge rxclk or negedge Word_Alignment_rstn)begin
    if(~Word_Alignment_rstn)data_af_Alignment_judge <= 0;
    else if(data_valid) data_af_Alignment_judge <= data_af_Alignment_judge + 1;
    else data_af_Alignment_judge <= 0;
end

assign led = {o_pll_done_0,o_p_pll_lock_0,o_txlane_done_3,o_rxlane_done_3,1'b0,1'b0,data_af_Alignment_judge == data_af_align,data_bf_Alignment_judge == o_rxd_3};
endmodule