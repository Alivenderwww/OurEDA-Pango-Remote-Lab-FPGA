module ddr3_top (
    input  wire         ddr_ref_clk  ,
    input  wire         rst_n        ,
    output wire         ddr_core_clk ,
    output wire         ddr_init_done,

    input  wire [ 27:0] WR_ADDR      ,
    input  wire [  3:0] WR_ID        ,
    input  wire [  3:0] WR_LEN       ,
    input  wire         WR_ADDR_VALID,
    output wire         WR_ADDR_READY,

    input  wire [255:0] WR_DATA      ,
    input  wire [ 31:0] WR_STRB      ,
    output wire         WR_DATA_READY,
    output wire [  3:0] WR_BACK_ID   ,
    output wire         WR_DATA_LAST ,

    input  wire [ 27:0] RD_ADDR      ,
    input  wire [  3:0] RD_ID        ,
    input  wire [  3:0] RD_LEN       ,
    input  wire         RD_ADDR_VALID,
    output wire         RD_ADDR_READY,

    output wire  [255:0] RD_DATA      ,
    output wire  [  3:0] RD_BACK_ID   ,
    output wire          RD_DATA_LAST ,
    output wire          RD_DATA_VALID,

    output  wire         mem_cs_n     ,
    output  wire         mem_rst_n    ,
    output  wire         mem_ck       ,
    output  wire         mem_ck_n     ,
    output  wire         mem_cke      ,
    inout   wire         mem_ras_n    ,
    inout   wire         mem_cas_n    ,
    inout   wire         mem_we_n     ,
    output  wire         mem_odt      ,
    output  wire [ 14:0] mem_a        ,
    output  wire [  2:0] mem_ba       ,
    output  wire [  3:0] mem_dqs      ,
    output  wire [  3:0] mem_dqs_n    ,
    output  wire [ 31:0] mem_dq       ,
    output  wire [  3:0] mem_dm       
);

//------------- axi_ddr3_inst -------------
axi_ddr3 axi_ddr3_inst
(
  .ref_clk          (ddr_ref_clk        ),
  .resetn           (rst_n      ),  // input
  .core_clk         (ddr_core_clk         ),  // output
  .pll_lock         (               ),  // output
  .phy_pll_lock     (               ),  // output
  .gpll_lock        (               ),  // output
  .rst_gpll_lock    (               ),  // output
  .ddrphy_cpd_lock  (               ),  // output
  .ddr_init_done    (ddr_init_done  ),  // output
  
  .mem_cs_n         (mem_cs_n       ),  // output
  .mem_rst_n        (mem_rst_n      ),  // output
  .mem_ck           (mem_ck         ),  // output
  .mem_ck_n         (mem_ck_n       ),  // output
  .mem_cke          (mem_cke        ),  // output
  .mem_ras_n        (mem_ras_n      ),  // output
  .mem_cas_n        (mem_cas_n      ),  // output
  .mem_we_n         (mem_we_n       ),  // output
  .mem_odt          (mem_odt        ),  // output
  .mem_a            (mem_a          ),  // output [14:0]
  .mem_ba           (mem_ba         ),  // output [2:0]
  .mem_dqs          (mem_dqs        ),  // inout  [3:0]
  .mem_dqs_n        (mem_dqs_n      ),  // inout  [3:0]
  .mem_dq           (mem_dq         ),  // inout  [31:0]
  .mem_dm           (mem_dm         ),  // output [3:0]
  .axi_awaddr       (WR_ADDR),  // input [27:0]
  .axi_awuser_ap    (1'b0           ),  // input
  .axi_awuser_id    (WR_ID  ),  // input [3:0]
  .axi_awlen        (WR_LEN ),  // input [3:0]
  .axi_awready      (WR_ADDR_READY), // output
  .axi_awvalid      (WR_ADDR_VALID), // input
  
  .axi_wdata        (WR_DATA      ),  // input [255:0]
  .axi_wstrb        (WR_STRB      ),  // input [31:0]
  .axi_wready       (WR_DATA_READY),  // output
  .axi_wusero_id    (WR_BACK_ID   ),  // output [3:0]
  .axi_wusero_last  (WR_DATA_LAST ),  // output
        
  .axi_araddr       (RD_ADDR),  // input [27:0]
  .axi_aruser_ap    (1'b0           ),  // input
  .axi_aruser_id    (RD_ID        ),  // input [3:0]
  .axi_arlen        (RD_LEN       ),  // input [3:0]
  .axi_arready      (RD_ADDR_READY ), // output
  .axi_arvalid      (RD_ADDR_VALID ), // input
  
  .axi_rdata        (RD_DATA      ),  // output [255:0]
  .axi_rid          (RD_BACK_ID   ),  // output [3:0]
  .axi_rlast        (RD_DATA_LAST ),  // output
  .axi_rvalid       (RD_DATA_VALID),  // output
  
  .apb_clk          (1'b0         ),  // input
  .apb_rst_n        (1'b0         ),  // input
  .apb_sel          (1'b0         ),  // input
  .apb_enable       (1'b0         ),  // input
  .apb_addr         (8'd0         ),  // input [7:0]
  .apb_write        (1'b0         ),  // input
  .apb_ready        (             ),  // output
  .apb_wdata        (16'd0        ),  // input [15:0]
  .apb_rdata        (             ),  // output [15:0]

  .dbg_gate_start           (1'b0       ),  // input
  .dbg_cpd_start            (1'b0       ),  // input 
  .dbg_ddrphy_rst_n         (1'b1       ),  // input
  .dbg_gpll_scan_rst        (1'b0       ),  // input
        
  .samp_position_dyn_adj    (1'b0       ),  // input
  .init_samp_position_even  (32'b0       ),  // input [31:0]
  .init_samp_position_odd   (32'b0       ),  // input [31:0]
        
  .wrcal_position_dyn_adj   (1'b0       ),  // input
  .init_wrcal_position      (32'b0       ),  // input [31:0]
        
  .force_read_clk_ctrl      (1'b0       ),  // input
  .init_slip_step           (16'b0       ),  // input [15:0]
  .init_read_clk_ctrl       (12'b0       ),  // input [11:0]
        
  .debug_calib_ctrl         (       ),  // output [33:0]
  .dbg_slice_status         (       ),  // output [67:0]
  .dbg_slice_state          (       ),  // output [87:0]
  .debug_data               (       ),  // output [275:0]
  .dbg_dll_upd_state        (       ),  // output [1:0]
  .debug_gpll_dps_phase     (       ),  // output [8:0]
        
  .dbg_rst_dps_state        (       ),  // output [2:0]
  .dbg_tran_err_rst_cnt     (       ),  // output [5:0]
  .dbg_ddrphy_init_fail     (       ),  // output
        
  .debug_cpd_offset_adj     (1'b0       ),  // input
  .debug_cpd_offset_dir     (1'b0       ),  // input
  .debug_cpd_offset         (10'b0       ),  // input [9:0]
  .debug_dps_cnt_dir0       (       ),  // output [9:0]
  .debug_dps_cnt_dir1       (       ),  // output [9:0]
        
  .ck_dly_en                (1'b0   ),  // input
  .init_ck_dly_step         (8'b0   ),  // input [7:0]
  .ck_dly_set_bin           (       ),  // output [7:0]
  .align_error              (       ),  // output
  .debug_rst_state          (       ),  // output [3:0]
  .debug_cpd_state          (       )   // output [3:0]
);

endmodule