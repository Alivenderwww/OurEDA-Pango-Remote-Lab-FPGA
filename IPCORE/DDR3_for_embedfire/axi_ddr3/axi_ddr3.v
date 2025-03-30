
    
////////////////////////////////////////////////////////////////
// Copyright (c) 2019 PANGO MICROSYSTEMS, INC
// ALL RIGHTS REVERVED.
////////////////////////////////////////////////////////////////
//Description:
//Author:  wxxiao
//History: v1.0
////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
`include "./para.vh"
module axi_ddr3 #(
 
   parameter MEM_ROW_WIDTH       = 15          ,
    
   parameter MEM_COLUMN_WIDTH    = 10          ,
   
   parameter MEM_BANK_WIDTH      = 3           ,
  
  parameter MEM_DQ_WIDTH         =  32         ,
  
  parameter MEM_DM_WIDTH         =  4         ,
  
  parameter MEM_DQS_WIDTH        =  4         ,

  parameter CTRL_ADDR_WIDTH     = MEM_ROW_WIDTH + MEM_COLUMN_WIDTH + MEM_BANK_WIDTH ,
`ifdef AXI_STANDARD_EN

  parameter AXI_ADDR_SHIFT       = 2         ,

  parameter AXI_ADDR_WIDTH     = CTRL_ADDR_WIDTH + AXI_ADDR_SHIFT  ,
  parameter AXI_DATA_WIDTH     = 8*MEM_DQ_WIDTH  ,
`endif

  parameter DEVICE_ID            = 1         


  )(                                                              
   input                              ref_clk                       ,    
   input                              resetn                        ,            
   output                             core_clk                      ,            
   output                             pll_lock                      ,    
   output                             phy_pll_lock                  ,
   output                             gpll_lock                     ,        
   output                             rst_gpll_lock                 ,            
   output                             ddrphy_cpd_lock               ,      
   output                             ddr_init_done                 ,            
`ifdef CONTROLLER_PHY_MODE
`ifdef AXI_REDUCED_EN
   input  [CTRL_ADDR_WIDTH-1:0]       axi_awaddr                    ,
   input                              axi_awuser_ap                 ,
   input  [3:0]                       axi_awuser_id                 ,
   input  [3:0]                       axi_awlen                     ,
   output                             axi_awready                   ,
   input                              axi_awvalid                   ,

   input  [8*MEM_DQ_WIDTH-1:0]        axi_wdata                     ,
   input  [MEM_DQ_WIDTH-1:0]          axi_wstrb                     ,
   output                             axi_wready                    ,
   output [3:0]                       axi_wusero_id                 ,
   output                             axi_wusero_last               ,

   input  [CTRL_ADDR_WIDTH-1:0]       axi_araddr                    ,
   input                              axi_aruser_ap                 ,
   input  [3:0]                       axi_aruser_id                 ,
   input  [3:0]                       axi_arlen                     ,
   output                             axi_arready                   ,
   input                              axi_arvalid                   ,

   output [8*MEM_DQ_WIDTH-1:0]        axi_rdata                     ,
   output [3:0]                       axi_rid                       ,
   output                             axi_rlast                     ,
   output                             axi_rvalid                    ,
`elsif AXI_STANDARD_EN
   input [AXI_ADDR_WIDTH-1:0]         axi_awaddr                    ,
   input [7:0]                        axi_awid                      ,
   input [7:0]                        axi_awlen                     ,
   input [2:0]                        axi_awsize                    ,
   input [1:0]                        axi_awburst                   ,        //only support 2'b01: INCR
   output                             axi_awready                   ,
   input                              axi_awvalid                   ,
   input [8*MEM_DQ_WIDTH-1:0]         axi_wdata                     ,
   input [MEM_DQ_WIDTH-1:0]           axi_wstrb                     ,
   input                              axi_wlast                     ,
   input                              axi_wvalid                    ,
   output                             axi_wready                    ,
   input                              axi_bready                    ,
   output [7:0]                       axi_bid                       ,
   output [1:0]                       axi_bresp                     ,
   output                             axi_bvalid                    ,
 //axi0 read  channel
   input [AXI_ADDR_WIDTH-1:0]         axi_araddr                    ,
   input [7:0]                        axi_arid                      ,
   input [7:0]                        axi_arlen                     ,
   input [2:0]                        axi_arsize                    ,
   input [1:0]                        axi_arburst                   ,       //only support 2'b01: INCR
   input                              axi_arvalid                   ,
   output                             axi_arready                   ,
   input                              axi_rready                    ,
   output [8*MEM_DQ_WIDTH-1:0]        axi_rdata                     ,
   output                             axi_rvalid                    ,
   output                             axi_rlast                     ,
   output [7:0]                       axi_rid                       ,
   output [1:0]                       axi_rresp                     ,
`endif
   input                              apb_clk                       ,
   input                              apb_rst_n                     ,
   input                              apb_sel                       ,
   input                              apb_enable                    ,
   input  [7:0]                       apb_addr                      ,
   input                              apb_write                     ,
   output                             apb_ready                     ,
   input  [15:0]                      apb_wdata                     ,
   output [15:0]                      apb_rdata                     ,
`endif 
`ifdef CS_N_EN
output                                mem_cs_n                      ,
`endif
   output                             mem_rst_n                     ,                       
   output                             mem_ck                        ,
   output                             mem_ck_n                      ,
   output                             mem_cke                       ,
   output                             mem_ras_n                     ,
   output                             mem_cas_n                     ,
   output                             mem_we_n                      , 
   output                             mem_odt                       ,
   output [MEM_ROW_WIDTH-1:0]         mem_a                         ,   
   output [MEM_BANK_WIDTH-1:0]        mem_ba                        ,   
   inout  [MEM_DQS_WIDTH-1:0]         mem_dqs                       ,
   inout  [MEM_DQS_WIDTH-1:0]         mem_dqs_n                     ,
   inout  [MEM_DQ_WIDTH-1:0]          mem_dq                        ,
   output [MEM_DM_WIDTH-1:0]          mem_dm                        , 
`ifdef PHY_ONLY_MODE
//PHY ONLY
   input  [4*MEM_ROW_WIDTH-1:0]       dfi_address                   ,
   input  [4*MEM_BANK_WIDTH-1:0]      dfi_bank                      ,
   input  [3:0]                       dfi_cs_n                      ,
   input  [3:0]                       dfi_cas_n                     ,
   input  [3:0]                       dfi_ras_n                     ,
   input  [3:0]                       dfi_we_n                      ,
   input  [3:0]                       dfi_cke                       ,
   input  [3:0]                       dfi_odt                       ,
   input  [3:0]                       dfi_wrdata_en                 ,
   input  [8*MEM_DQ_WIDTH-1:0]        dfi_wrdata                    ,
   input  [8*MEM_DM_WIDTH-1:0]        dfi_wrdata_mask               ,
   output [8*MEM_DQ_WIDTH-1:0]        dfi_rddata                    ,
   output                             dfi_rddata_valid              ,
   input                              dfi_reset_n                   ,
   output                             dfi_phyupd_req                ,
   input                              dfi_phyupd_ack                ,
   output                             dfi_error                     ,
`endif
   //debug
   input                              dbg_gate_start                ,
   input                              dbg_cpd_start                 ,
   input                              dbg_ddrphy_rst_n              ,
   input                              dbg_gpll_scan_rst             ,

   input                              samp_position_dyn_adj         ,
   input  [8*MEM_DQS_WIDTH-1:0]       init_samp_position_even       ,
   input  [8*MEM_DQS_WIDTH-1:0]       init_samp_position_odd        ,

   input                              wrcal_position_dyn_adj        ,
   input  [8*MEM_DQS_WIDTH-1:0]       init_wrcal_position           ,
 
   input                              force_read_clk_ctrl           ,
   input  [4*MEM_DQS_WIDTH-1:0]       init_slip_step                ,  
   input  [3*MEM_DQS_WIDTH-1:0]       init_read_clk_ctrl            ,

   output [33:0]                      debug_calib_ctrl              ,
   output [4*MEM_DQS_WIDTH + 12:0]    dbg_slice_status              ,
   output [22*MEM_DQS_WIDTH -1:0]     dbg_slice_state               ,
   output [69*MEM_DQS_WIDTH -1:0]     debug_data                    ,
   output [1:0]                       dbg_dll_upd_state             ,
   output [8:0]                       debug_gpll_dps_phase          ,
   
   output [2:0]                       dbg_rst_dps_state             ,
   output [5:0]                       dbg_tran_err_rst_cnt          ,
   output                             dbg_ddrphy_init_fail          , 
   
   input                              debug_cpd_offset_adj          ,
   input                              debug_cpd_offset_dir          ,
   input  [9:0]                       debug_cpd_offset              ,  
   output [9:0]                       debug_dps_cnt_dir0            , 
   output [9:0]                       debug_dps_cnt_dir1            ,

   input                              ck_dly_en                     ,
   input  [7:0]                       init_ck_dly_step              ,
   output [7:0]                       ck_dly_set_bin                ,
  
   output                             align_error                   ,
   output [3:0]                       debug_rst_state               ,
   output [3:0]                       debug_cpd_state               
);
wire  dfi_init_complete   ;
wire [7:0]                       rstclk_phase_adj_cnt          ; //for gate rst debug
wire [3:0]                       debug_check_out_sync_point_state ; //for gate rst debug
`ifdef PHY_ONLY_MODE
assign ddr_init_done = dfi_init_complete ;
`endif
//MR0_DDR3
localparam [0:0] DDR3_PPD      = 1'b1;

localparam [2:0] DDR3_WR       = 3'd1; 

localparam [0:0] DDR3_DLL      = 1'b1;
localparam [0:0] DDR3_TM       = 1'b0;
localparam [0:0] DDR3_RBT      = 1'b0;

localparam [3:0] DDR3_CL       = 4'd4;

localparam [1:0] DDR3_BL       = 2'b00;
localparam [15:0] MR0_DDR3     = {3'b000, DDR3_PPD, DDR3_WR, DDR3_DLL, DDR3_TM, DDR3_CL[3:1], DDR3_RBT, DDR3_CL[0], DDR3_BL};
//MR1_DDR3
localparam [0:0] DDR3_QOFF     = 1'b0;
localparam [0:0] DDR3_TDQS     = 1'b0;

localparam [2:0] DDR3_RTT_NOM  = 3'b001;       

localparam [0:0] DDR3_LEVEL    = 1'b0;

localparam [1:0] DDR3_DIC      = 2'b00;

localparam [1:0] DDR3_AL       = 2'd2;

localparam [0:0] DDR3_DLL_EN   = 1'b0;
localparam [15:0] MR1_DDR3 = {1'b0, DDR3_QOFF, DDR3_TDQS, 1'b0, DDR3_RTT_NOM[2], 1'b0, DDR3_LEVEL, DDR3_RTT_NOM[1], DDR3_DIC[1], DDR3_AL, DDR3_RTT_NOM[0], DDR3_DIC[0], DDR3_DLL_EN};
//MR2_DDR3
localparam [1:0] DDR3_RTT_WR   = 2'b00;
localparam [0:0] DDR3_SRT      = 1'b0;
localparam [0:0] DDR3_ASR      = 1'b0;

localparam [2:0] DDR3_CWL      = 5 - 5;

localparam [2:0] DDR3_PASR     = 3'b000;
localparam [15:0] MR2_DDR3     = {5'b00000, DDR3_RTT_WR, 1'b0, DDR3_SRT, DDR3_ASR, DDR3_CWL, DDR3_PASR};
//MR3_DDR3
localparam [0:0] DDR3_MPR      = 1'b0;
localparam [1:0] DDR3_MPR_LOC  = 2'b00;
localparam [15:0] MR3_DDR3     = {13'b0, DDR3_MPR, DDR3_MPR_LOC};

//MR_DDR2
localparam [2:0] DDR2_BL       = 3'b011;
localparam [0:0] DDR2_BT       = 1'b0; //Sequential

localparam [2:0] DDR2_CL       = 3'd4;

localparam [0:0] DDR2_TM       = 1'b0;
localparam [0:0] DDR2_DLL      = 1'b1;

localparam [2:0] DDR2_WR       = 3'd4; 

localparam [0:0] DDR2_PD       = 1'b0;
localparam [15:0]  MR_DDR2     = {3'b000,DDR2_PD,DDR2_WR,DDR2_DLL,DDR2_TM,DDR2_CL,DDR2_BT,DDR2_BL};

//EMR1_DDR2
localparam [0:0] DDR2_DLL_EN      = 1'b0;

localparam [0:0] DDR2_DIC      = 1'b0;

localparam [1:0] DDR2_RTT_NOM  = 2'b01;     

localparam [2:0] DDR2_AL       = 3'd2; 
 
localparam [2:0] DDR2_OCD      = 3'b000;
localparam [0:0] DDR2_DQS      = 1'b0;
localparam [0:0] DDR2_RDQS     = 1'b0;
localparam [0:0] DDR2_QOFF     = 1'b0;
localparam [15:0] EMR1_DDR2    = {3'b000,DDR2_QOFF,DDR2_RDQS,DDR2_DQS,DDR2_OCD,DDR2_RTT_NOM[1],DDR2_AL,DDR2_RTT_NOM[0],DDR2_DIC,DDR2_DLL_EN};

localparam [15:0] EMR2_DDR2    =16'h0000;
localparam [15:0] EMR3_DDR2    =16'h0000;
 
//MR_LPDDR
localparam [2:0] LPDDR_BL      = 3'b011;
localparam [0:0] LPDDR_BT      = 1'b0;

localparam [2:0] LPDDR_CL      = 3'd2;

localparam [15:0] MR_LPDDR    = {9'd0,LPDDR_CL,LPDDR_BT,LPDDR_BL};

//EMR_LPDDR

localparam [2:0] LPDDR_DS      = 3'b000;

localparam [15:0] EMR_LPDDR    = {8'd0,LPDDR_DS,5'd0};


  localparam         MEM_TYPE     =  "DDR3"      ;
 
localparam DDR_TYPE = (MEM_TYPE == "DDR3") ? 2'b00 : (MEM_TYPE == "DDR2") ? 2'b01 : (MEM_TYPE == "LPDDR") ? 2'b10 : 2'b00;
 
  localparam [7:0]   PHY_TMRD         =  4/4   ;

  localparam [7:0]   PHY_TMOD         =  12/4   ;
  
  localparam [7:0]   PHY_TXPR         =  24   ;
  
  localparam [7:0]   PHY_TRP          =  2   ;
  
  localparam [7:0]   PHY_TRFC         =  23   ;
    
  localparam [7:0]   PHY_TRCD         =  2   ;
            
  localparam DDRC_TXSDLL               = 512  ;
  localparam DDRC_TCCD                 = 4    ;
   
  localparam DDRC_TXP                  = 3   ;
 
  localparam DDRC_TFAW                 = 13   ;

  localparam DDRC_TRAS                 = 12   ;
   
  localparam DDRC_TRCD                 = 5   ;
    
  localparam DDRC_TREFI                = 2340   ;
   
  localparam DDRC_TRFC                 = 90   ;
     
  localparam DDRC_TRC                  = 15   ;

  localparam DDRC_TRP                  = 5   ;

  localparam DDRC_TRRD                 = 3   ;  

  localparam DDRC_TRTP                 = 4   ;

  localparam DDRC_TWR                  = 5   ;

  localparam DDRC_TWTR                 = 4   ;

  localparam AXIADDR_MAPPING_SEL       = 0   ;

localparam REF_NUM                   = 8    ; 

`ifdef CONTROLLER_PHY_MODE
wire                              dfi_phyupd_req              ;
wire                              dfi_phyupd_ack              ;
wire [4*MEM_ROW_WIDTH-1:0]        dfi_address                 ;
wire [4*MEM_BANK_WIDTH-1:0]       dfi_bank                    ;
wire [4-1:0]                      dfi_cs_n                    ;
wire [4-1:0]                      dfi_ras_n                   ;
wire [4-1:0]                      dfi_cas_n                   ;
wire [4-1:0]                      dfi_we_n                    ;
wire [4-1:0]                      dfi_cke                     ;
wire [4-1:0]                      dfi_odt                     ;
wire [2*4*MEM_DQ_WIDTH-1:0]       dfi_wrdata                  ;
wire [4-1:0]                      dfi_wrdata_en               ;
wire [2*4*MEM_DQ_WIDTH/8-1:0]     dfi_wrdata_mask             ;
wire [2*4*MEM_DQ_WIDTH-1:0]       dfi_rddata                  ;
wire                              dfi_rddata_valid            ;
wire                              dfi_error                   ;
`endif
wire                              ddrphy_sysclk               ;
wire                              ddrp_rstn                   ;
wire                              ddrc_rstn                   ;
wire                              ck_step_ov_warning          ;
wire [MEM_DQS_WIDTH-1:0]          wl_step_ov_warning          ; 

assign ddrp_rstn = resetn;

ips2l_rst_sync_v1_3 u_ddrc_rstn_sync(
    .clk                   (ddrphy_sysclk           ),
    .rst_n                 (resetn                  ),
    .sig_async             (1'b1                    ),
    .sig_synced            (ddrc_rstn               )
);

assign core_clk = ddrphy_sysclk;
`ifdef CONTROLLER_PHY_MODE                                             
axi_ddr3_mcdq_wrapper_v1_9 #(
   .MEM_ROW_ADDR_WIDTH (MEM_ROW_WIDTH      ),   
   .MEM_COL_ADDR_WIDTH (MEM_COLUMN_WIDTH   ),   
   .MEM_BA_ADDR_WIDTH  (MEM_BANK_WIDTH     ),    
   .MEM_DQ_WIDTH       (MEM_DQ_WIDTH       ),
   .CTRL_ADDR_WIDTH    (CTRL_ADDR_WIDTH    ),
`ifdef AXI_STANDARD_EN
   .AXI_ADDR_WIDTH     (AXI_ADDR_WIDTH     ),
   .AXI_DATA_WIDTH     (AXI_DATA_WIDTH     ),
`endif
   .ADDR_MAPPING_SEL   (AXIADDR_MAPPING_SEL),  //0:  ROW + BANK + COLUMN   1:BANK + ROW +COLUMN                            

   .MR0_DDR3           (MR0_DDR3           ),  
   .MR1_DDR3           (MR1_DDR3           ),
   .MR2_DDR3           (MR2_DDR3           ),                     
   .MR3_DDR3           (MR3_DDR3           ),  
   .REF_NUM            (REF_NUM            ),                                             
   .TXSDLL             (DDRC_TXSDLL        ),
   .TCCD               (DDRC_TCCD          ),
   .TXP                (DDRC_TXP           ),
   .TFAW               (DDRC_TFAW          ),       
   .TRAS               (DDRC_TRAS          ),       
   .TRCD               (DDRC_TRCD          ),       
   .TREFI              (DDRC_TREFI         ),       
   .TRFC               (DDRC_TRFC          ),  
   .TRC                (DDRC_TRC           ),
   .TRP                (DDRC_TRP           ),       
   .TRRD               (DDRC_TRRD          ),       
   .TRTP               (DDRC_TRTP          ),
   .TWR                (DDRC_TWR           ),      
   .TWTR               (DDRC_TWTR          )        
  )u_ips_ddrc_top(
   .clk                    (ddrphy_sysclk           ),
   .rst_n                  (ddrc_rstn               ),

   .phy_init_done          (dfi_init_complete       ),
   .ddr_init_done          (ddr_init_done           ),
`ifdef AXI_REDUCED_EN
   .axi_awaddr             (axi_awaddr              ),
   .axi_awuser_ap          (axi_awuser_ap           ),
   .axi_awuser_id          (axi_awuser_id           ),
   .axi_awlen              (axi_awlen               ),
   .axi_awready            (axi_awready             ),
   .axi_awvalid            (axi_awvalid             ),

   .axi_wdata              (axi_wdata               ),
   .axi_wstrb              (axi_wstrb               ),
   .axi_wready             (axi_wready              ),
   .axi_wusero_id          (axi_wusero_id           ),
   .axi_wusero_last        (axi_wusero_last         ),

   .axi_araddr             (axi_araddr              ),
   .axi_aruser_ap          (axi_aruser_ap           ),
   .axi_aruser_id          (axi_aruser_id           ),
   .axi_arlen              (axi_arlen               ),
   .axi_arready            (axi_arready             ),
   .axi_arvalid            (axi_arvalid             ),

   .axi_rdata              (axi_rdata               ),
   .axi_rid                (axi_rid                 ),
   .axi_rlast              (axi_rlast               ),
   .axi_rvalid             (axi_rvalid              ),
`elsif AXI_STANDARD_EN
//axi0 write channel
   .axi_awaddr             (axi_awaddr              ),
   .axi_awid               (axi_awid                ),
   .axi_awlen              (axi_awlen               ),
   .axi_awsize             (axi_awsize              ),
   .axi_awburst            (axi_awburst             ),        //only support 2'b01: INCR
   .axi_awready            (axi_awready             ),
   .axi_awvalid            (axi_awvalid             ),
   .axi_wdata              (axi_wdata               ),
   .axi_wstrb              (axi_wstrb               ),
   .axi_wlast              (axi_wlast               ),
   .axi_wvalid             (axi_wvalid              ),
   .axi_wready             (axi_wready              ),
   .axi_bready             (axi_bready              ),
   .axi_bid                (axi_bid                 ),
   .axi_bresp              (axi_bresp               ),
   .axi_bvalid             (axi_bvalid              ),
 //axi0 read  channel
   .axi_araddr             (axi_araddr              ),
   .axi_arid               (axi_arid                ),
   .axi_arlen              (axi_arlen               ),
   .axi_arsize             (axi_arsize              ),
   .axi_arburst            (axi_arburst             ),       //only support 2'b01: INCR
   .axi_arvalid            (axi_arvalid             ),
   .axi_arready            (axi_arready             ),
   .axi_rready             (axi_rready              ),
   .axi_rdata              (axi_rdata               ),
   .axi_rvalid             (axi_rvalid              ),
   .axi_rlast              (axi_rlast               ),
   .axi_rid                (axi_rid                 ),
   .axi_rresp              (axi_rresp               ),
`endif
   .apb_clk                (apb_clk                 ),
   .apb_rst_n              (apb_rst_n               ),
   .apb_sel                (apb_sel                 ),
   .apb_enable             (apb_enable              ),
   .apb_addr               (apb_addr                ),
   .apb_write              (apb_write               ),
   .apb_ready              (apb_ready               ),
   .apb_wdata              (apb_wdata               ),
   .apb_rdata              (apb_rdata               ),
   .ddr_zqcs_req           (1'b0                    ),
   .ddr_zqcs_ack           (                        ),
   .dfi_phyupd_req         (dfi_phyupd_req          ),
   .dfi_phyupd_ack         (dfi_phyupd_ack          ),

   .dfi_address            (dfi_address             ),
   .dfi_bank               (dfi_bank                ),
   .dfi_cs_n               (dfi_cs_n                ),
   .dfi_ras_n              (dfi_ras_n               ),
   .dfi_cas_n              (dfi_cas_n               ),
   .dfi_we_n               (dfi_we_n                ),
   .dfi_cke                (dfi_cke                 ),
   .dfi_odt                (dfi_odt                 ),
   .dfi_wrdata             (dfi_wrdata              ),
   .dfi_wrdata_en          (dfi_wrdata_en           ),
   .dfi_wrdata_mask        (dfi_wrdata_mask         ),
   .dfi_rddata             (dfi_rddata              ),
   .dfi_rddata_valid       (dfi_rddata_valid        )
   );
`endif

 axi_ddr3_ddrphy_top  #(
  .MEM_TYPE                (MEM_TYPE                ),
  .TMRD                    (PHY_TMRD                ),
  .TMOD                    (PHY_TMOD                ),
  .TXPR                    (PHY_TXPR                ),
  .TRP                     (PHY_TRP                 ),
  .TRFC                    (PHY_TRFC                ),
  .TRCD                    (PHY_TRCD                ),
  .MEM_ROW_WIDTH           (MEM_ROW_WIDTH           ),
  .MEM_BANK_WIDTH          (MEM_BANK_WIDTH          ),
  .MEM_DQ_WIDTH            (MEM_DQ_WIDTH            ),
  .MEM_DM_WIDTH            (MEM_DM_WIDTH            ),
  .MEM_DQS_WIDTH           (MEM_DQS_WIDTH           ),
  .DEVICE_ID               (DEVICE_ID               )
 )u_ddrphy_top(
  .ref_clk                 (ref_clk                 ),
  .ddr_rstn                (ddrp_rstn               ),
  .pll_lock                (pll_lock                ),
  .phy_pll_lock            (phy_pll_lock            ),
  .gpll_lock               (gpll_lock               ),
  .rst_gpll_lock           (rst_gpll_lock           ),
  .ddrphy_cpd_lock         (ddrphy_cpd_lock         ),
  .ddrphy_sysclk           (ddrphy_sysclk           ),

  .dfi_address             (dfi_address             ),
  .dfi_bank                (dfi_bank                ),
  .dfi_cs_n                (dfi_cs_n                ),
  .dfi_cas_n               (dfi_cas_n               ),
  .dfi_ras_n               (dfi_ras_n               ),
  .dfi_we_n                (dfi_we_n                ),
  .dfi_cke                 (dfi_cke                 ),
  .dfi_odt                 (dfi_odt                 ),
  .dfi_wrdata_en           (dfi_wrdata_en           ),
  .dfi_wrdata              (dfi_wrdata              ),
  .dfi_wrdata_mask         (dfi_wrdata_mask         ),
  .dfi_rddata              (dfi_rddata              ),
  .dfi_rddata_valid        (dfi_rddata_valid        ),
  .dfi_reset_n             (1'b1                    ),
  .dfi_phyupd_req          (dfi_phyupd_req          ),
  .dfi_phyupd_ack          (dfi_phyupd_ack          ),
  .dfi_init_complete       (dfi_init_complete       ),
  .dfi_error               (dfi_error               ),

`ifdef CS_N_EN
  .mem_cs_n                (mem_cs_n                ),
`endif
  .mem_rst_n               (mem_rst_n               ),
  .mem_ck                  (mem_ck                  ),
  .mem_ck_n                (mem_ck_n                ),
  .mem_cke                 (mem_cke                 ),
  .mem_ras_n               (mem_ras_n               ),
  .mem_cas_n               (mem_cas_n               ),
  .mem_we_n                (mem_we_n                ),
  .mem_odt                 (mem_odt                 ),
  .mem_a                   (mem_a                   ),
  .mem_ba                  (mem_ba                  ),
  .mem_dqs                 (mem_dqs                 ),
  .mem_dqs_n               (mem_dqs_n               ),
  .mem_dq                  (mem_dq                  ),
  .mem_dm                  (mem_dm                  ),

   //debug
  .dbg_gate_start          (dbg_gate_start          ),
  .dbg_cpd_start           (dbg_cpd_start           ),
  .dbg_ddrphy_rst_n        (dbg_ddrphy_rst_n        ),
  .dbg_gpll_scan_rst       (dbg_gpll_scan_rst       ),

  .force_samp_position     (1'b0                    ),
  .samp_position_dyn_adj   (samp_position_dyn_adj   ),
  .init_samp_position_even (init_samp_position_even ),
  .init_samp_position_odd  (init_samp_position_odd  ),

  .wrlvl_en                (1'b1                    ),
  .init_wrlvl_step         ({MEM_DQS_WIDTH{8'd0}}   ),
  .ck_dly_en               (ck_dly_en               ),
  .init_ck_dly_step        (init_ck_dly_step        ),

  .wrcal_position_dyn_adj  (wrcal_position_dyn_adj  ),
  .init_wrcal_position     (init_wrcal_position     ),
  
  .force_read_clk_ctrl     (force_read_clk_ctrl     ),
  .init_slip_step          (init_slip_step          ),  
  .init_read_clk_ctrl      (init_read_clk_ctrl      ),

  .debug_calib_ctrl        (debug_calib_ctrl        ),
  .dbg_slice_status        (dbg_slice_status        ),
  .dbg_slice_state         (dbg_slice_state         ),
  .dbg_dll_upd_state       (dbg_dll_upd_state       ),
  .debug_data              (debug_data              ),
  .debug_gpll_dps_phase    (debug_gpll_dps_phase    ),

  .dbg_rst_dps_state       (dbg_rst_dps_state       ),
  .dbg_tran_err_rst_cnt    (dbg_tran_err_rst_cnt    ),
  .dbg_ddrphy_init_fail    (dbg_ddrphy_init_fail    ),

  .debug_cpd_offset_adj    (debug_cpd_offset_adj    ),
  .debug_cpd_offset_dir    (debug_cpd_offset_dir    ),
  .debug_cpd_offset        (debug_cpd_offset        ),
  .debug_dps_cnt_dir0      (debug_dps_cnt_dir0      ), 
  .debug_dps_cnt_dir1      (debug_dps_cnt_dir1      ), 

  .ck_dly_set_bin          (ck_dly_set_bin          ),

  .ck_step_ov_warning      (ck_step_ov_warning      ),
  .wl_step_ov_warning      (wl_step_ov_warning      ),
  .rstclk_phase_adj_cnt    (rstclk_phase_adj_cnt    ),
  .debug_check_out_sync_point_state    (debug_check_out_sync_point_state    ),

  .align_error             (align_error             ),
  .debug_rst_state         (debug_rst_state         ),
  .debug_cpd_state         (debug_cpd_state         )
);

endmodule

