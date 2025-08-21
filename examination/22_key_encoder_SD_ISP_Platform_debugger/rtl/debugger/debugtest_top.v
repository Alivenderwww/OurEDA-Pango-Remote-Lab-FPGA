module debugtest_top #(
  parameter PORT_NUM = 3,
  parameter SAMPLE_DEPTH = 1024
)(
    input clk,//
    input clk_27M,
    input rstn,

    input i_p_refckn_1,
    input i_p_refckp_1,
    input [32*PORT_NUM - 1 : 0] i_testport,

    output debugger_init,
    output o_pll_done_0,
    output o_txlane_done_2,
    output o_rxlane_done_2,
    output o_p_pll_lock_0,
    output o_p_rx_sigdet_sta_2,
    output o_p_lx_cdr_align_2
);
wire [31:0] testport      [PORT_NUM - 1 : 0];
//************************************//
genvar n;
generate
  for (n = 0; n < PORT_NUM; n = n + 1) begin : generate_testport
    assign testport[n] = i_testport[32*(n + 1) - 1 : 32*n];
  end
endgenerate
//************************************//
wire rxclk/* synthesis PAP_MARK_DEBUG="1" */;
wire txclk/* synthesis PAP_MARK_DEBUG="1" */;
wire[31:0] sfp_rxdata/* synthesis PAP_MARK_DEBUG="1" */;
wire       sfp_rxdatavalid/* synthesis PAP_MARK_DEBUG="1" */;
wire       sfp_rxdatalast/* synthesis PAP_MARK_DEBUG="1" */;
localparam PORT_WIDTH   = 32;
//**********
localparam IDLE     = 8'd0;
// localparam HEAD     = 8'd1;
localparam TRIGEND  = 8'd2;
localparam PORTDATA = 8'd3;
localparam WRRESP   = 8'd4;
localparam RDRESP   = 8'd5;
reg [ 7:0] txstate;
reg [ 7:0] txnextstate;
reg [31:0] headdata;
reg [31:0] cmddata;
reg [31:0] sfp_txdata/* synthesis PAP_MARK_DEBUG="1" */;
reg [ 3:0] sfp_txk/* synthesis PAP_MARK_DEBUG="1" */;
reg        sfp_txdatavalid/* synthesis PAP_MARK_DEBUG="1" */;
reg        sfp_txdatalast/* synthesis PAP_MARK_DEBUG="1" */;

//***********
wire [31:0] tx_portdata   [PORT_NUM - 1 : 0];
wire [PORT_NUM - 1 : 0]      porten        ;
wire [PORT_NUM - 1 : 0]      tx_datavalid  ;
wire [PORT_NUM - 1 : 0]      tx_sel        ;
wire [PORT_NUM - 1 : 0]      tx_datalast   ; 
wire [PORT_NUM - 1 : 0]      trigdone      ; 
reg  [PORT_NUM - 1 : 0]      trigdone_reg/* synthesis PAP_MARK_DEBUG="1" */; 
wire [PORT_NUM * PORT_WIDTH - 1 : 0] trig_en       ;
wire [PORT_NUM * PORT_WIDTH - 1 : 0] trigger_sel   ;
wire trig_all/* synthesis PAP_MARK_DEBUG="1" */;
wire [15:0] addr;
wire [ 9:0] rdnum;
wire [ 2:0] mode;
wire refresh/* synthesis PAP_MARK_DEBUG="1" */;
wire trigger/* synthesis PAP_MARK_DEBUG="1" */;
reg  trigger_clk;
reg  trigger_rxclk;
wire txidle;
assign txidle = txstate == IDLE;
//***************mux_txportdata*************//
reg [31:0] sfp_txportdata;
reg        sfp_txportdatavalid;
reg        sfp_txportdatalast;
integer g;
genvar i;
genvar j;
always @(posedge txclk or negedge rstn) begin : data_mux
    if (!rstn) begin
        sfp_txportdata      <= 32'b0;
        sfp_txportdatavalid <= 0;
        sfp_txportdatalast  <= 0;
    end else begin
        sfp_txportdata      <= 32'b0;
        sfp_txportdatavalid <= 0;
        sfp_txportdatalast  <= 0;
        for (g = 0; g < PORT_NUM; g = g + 1) begin
            if (tx_sel[g]) begin
                sfp_txportdata      <= tx_portdata[g];
                sfp_txportdatavalid <= tx_datavalid[g];
                sfp_txportdatalast  <= tx_datalast[g];
            end
        end
    end
end

//trigdone_reg
always @(posedge txclk or negedge rstn) begin
  if(~rstn) trigdone_reg <= 0;
  else if(txstate == TRIGEND) trigdone_reg <= 0;
  else begin
    for (g = 0; g < PORT_NUM; g = g + 1) begin
      if (trigdone[g]) begin
        trigdone_reg[g] <= 1;
      end
  end
  end
end

//00_xxxxxx状�??,FF_xxxxxx数杮
always @(posedge txclk or negedge rstn) begin
  if(~rstn)begin
    txstate     <= IDLE;
    txnextstate <= IDLE;
    cmddata     <= 0;
    sfp_txdata      <= 0;
    sfp_txk         <= 0;
    sfp_txdatavalid <= 0;
    sfp_txdatalast  <= 0;
  end
  else begin
    case(txstate)
        IDLE : begin : tx_headdata
          if(&trigdone_reg)begin 
            sfp_txdata      <= 32'h00_000000;
            sfp_txk         <= 4'b0000;
            sfp_txdatavalid <= 1;
            sfp_txdatalast  <= 0;
            txstate <= TRIGEND;
            cmddata <= 32'hFFFFFFFF;
          end
          else if(|tx_sel)begin
            sfp_txdata      <= 32'hFF_000000;
            sfp_txk         <= 4'b0000;
            sfp_txdatavalid <= 1;
            sfp_txdatalast  <= 0;
            txstate <= PORTDATA;
          end
          else begin
            sfp_txdata      <= 0;
            sfp_txk         <= 4'b0000;
            sfp_txdatavalid <= 0;
            sfp_txdatalast  <= 0;
            txstate <= IDLE;
          end
        end
        TRIGEND : begin
          sfp_txdata      <= cmddata;
          sfp_txk         <= 4'b0000;
          sfp_txdatavalid <= 1;
          sfp_txdatalast  <= 1;
          txstate <= IDLE;
        end
        PORTDATA : begin
          sfp_txdata      <= sfp_txportdata      ;
          sfp_txk         <= 4'b0000             ;
          sfp_txdatavalid <= sfp_txportdatavalid ;
          sfp_txdatalast  <= sfp_txportdatalast  ;
          if(sfp_txportdatalast) txstate <= IDLE;
        end
        default : txstate <= IDLE;
    endcase
  end
end


generate
  for (i = 0; i < PORT_NUM; i = i + 1) begin : generate_module
    mydebugger # (
      .PORT_WIDTH     (PORT_WIDTH  ),
      .SAMPLE_DEPTH   (SAMPLE_DEPTH)
    )
    mydebugger_inst (
      .clk            (clk            ),
      .txclk          (txclk          ),
      .rxclk          (rxclk          ),
      .rstn           (rstn           ),
      .testport       (testport[i]    ),
      .porten         (porten[i]      ),
      .addr           (addr           ),
      .rdnum          (rdnum          ),
      .tx_sel         (tx_sel[i]      ),
      .tx_datalast    (tx_datalast[i] ),
      .trigger        (trig_all       ),
      .refresh        (refresh        ),
      .trigdone       (trigdone[i]    ),
      .tx_datavalid   (tx_datavalid[i]),
      .tx_portdata    (tx_portdata[i] )
    );
  end
endgenerate
generate
  for (i = 0; i < PORT_NUM; i = i + 1) begin
    for (j = 0; j < PORT_WIDTH; j = j + 1) begin
      trigger_1bit # (
        .PORT_WIDTH(PORT_WIDTH)
      )
      trigger_1bit_inst (
        .clk            (clk                  ),
        .rxclk          (rxclk                ),
        .rstn           (rstn                 ),
        .mode_en        (trigger_sel[i*32 + j]),
        .mode           (mode                 ),
        .testport       (testport[i][j]       ),
        .trig_en        (trig_en[i*32 + j]    )
      );
      end
  end
endgenerate
decoder # (
  .PORT_NUM(PORT_NUM),
  .PORT_WIDTH(PORT_WIDTH),
  .MAX_SAMPLE_DEPTH(SAMPLE_DEPTH)
)
decoder_inst (
  .rxclk              (rxclk          ),
  .rstn               (rstn           ),
  .sfp_rxdatalast     (sfp_rxdatalast ),
  .sfp_rxdatavalid    (sfp_rxdatavalid),
  .sfp_rxdata         (sfp_rxdata     ),
  .refresh            (refresh        ),
  .trigger_sel        (trigger_sel    ),
  .mode               (mode           ),
  .trigger            (trigger        ),
  .porten             (porten         ),
  .addr               (addr           ),
  .num                (rdnum          )
);

mux # (
  .PORT_NUM(PORT_NUM)
)
mux_inst (
  .rxclk              (rxclk            ),
  .txclk              (txclk            ),
  .rstn               (rstn             ),
  .txidle             (txidle           ),
  .porten             (porten           ),
  .tx_datalast        (tx_datalast      ),
  .portsel            (tx_sel           )
);
assign trig_all = (&trig_en) && (trigger_clk);
always @(posedge clk or negedge rstn) begin
    if(~rstn) trigger_clk <= 0;
    else if(trigger_rxclk) trigger_clk <= 1;
    else if(trig_all) trigger_clk <= 0;
    else trigger_clk <= trigger_clk ;
end

always @(posedge rxclk or negedge rstn) begin
    if(~rstn) trigger_rxclk <= 0;
    else if(trigger_clk) trigger_rxclk <= 0;
    else if(trigger) trigger_rxclk <= 1;
    else trigger_rxclk <= trigger_rxclk;
end

//----------------------------------------------------//
// wire o_pll_done_0;
// wire o_txlane_done_2;
// wire o_rxlane_done_2;
// wire o_p_pll_lock_0;
// wire o_p_rx_sigdet_sta_2;
// wire o_p_lx_cdr_align_2;
wire i_p_l2rxn;
wire i_p_l2rxp;
wire o_p_l2txn;
wire o_p_l2txp;
assign debugger_init = o_txlane_done_2 & o_rxlane_done_2 & o_p_pll_lock_0 & o_p_rx_sigdet_sta_2 & o_p_lx_cdr_align_2;
hsst_for_labfpga_dut_top  hsst_for_labfpga_dut_top_inst (
  .i_free_clk(clk_27M),
  .rstn(rstn),
  .rxclk(rxclk),
  .txclk(txclk),
  .o_pll_done_0(o_pll_done_0),
  .o_txlane_done_2(o_txlane_done_2),
  .o_rxlane_done_2(o_rxlane_done_2),
  .i_p_refckn_1(i_p_refckn_1),
  .i_p_refckp_1(i_p_refckp_1),
  .o_p_pll_lock_0(o_p_pll_lock_0),
  .o_p_rx_sigdet_sta_2(o_p_rx_sigdet_sta_2),
  .o_p_lx_cdr_align_2(o_p_lx_cdr_align_2),
  .i_p_l2rxn(i_p_l2rxn),
  .i_p_l2rxp(i_p_l2rxp),
  .o_p_l2txn(o_p_l2txn),
  .o_p_l2txp(o_p_l2txp),
  .i_txd_2(sfp_txdata),
  .i_txk_2(sfp_txk),
  .i_txv_2(sfp_txdatavalid),
  .data_af_align(sfp_rxdata),
  .data_valid(sfp_rxdatavalid),
  .data_last(sfp_rxdatalast),
  .o_rxstatus_2(),
  .o_rdisper_2(),
  .o_rdecer_2()
);
endmodule