
////////////////////////////////////////////////////////////////////////////////        
// Copyright (c) 2015 Shenzhen Pango Microsystems CO.,LTD                               
// All Rights Reserved.                                                                 
////////////////////////////////////////////////////////////////////////////////        
`timescale 1ns/1ps
`include "./../../para.vh"
module axi_ddr3_mcdq_wrapper_v1_9 #(
//AXI parameter
`ifdef AXI_STANDARD_EN
  parameter  AXI_ADDR_WIDTH      =  28  ,
  parameter  AXI_DATA_WIDTH      =  128 ,
`endif
  parameter  WR_WEIGHT            =  4   ,        //1-7
  parameter  RD_WEIGHT            =  4   ,        //1-7
//MAC parameter
   parameter [1:0]   DDR_TYPE     = 2'b00 ,  //2'b00:DDR3  2'b01:DDR2  2'b10:LPDDR 
   parameter MEM_ROW_ADDR_WIDTH   = 14    ,
   parameter MEM_COL_ADDR_WIDTH   = 10    ,
   parameter MEM_BA_ADDR_WIDTH    = 3     ,
   parameter MEM_DQ_WIDTH         = 16    ,
   parameter CTRL_ADDR_WIDTH      = MEM_ROW_ADDR_WIDTH + MEM_BA_ADDR_WIDTH + MEM_COL_ADDR_WIDTH,
   parameter ADDR_MAPPING_SEL     = 0,        //0:  ROW + BANK + COLUMN   1:BANK + ROW +COLUMN
   parameter REF_NUM              = 8,

   parameter [15:0]  MR0_DDR3     = 16'd0 ,
   parameter [15:0]  MR1_DDR3     = 16'd0 ,
   parameter [15:0]  MR2_DDR3     = 16'd0 ,
   parameter [15:0]  MR3_DDR3     = 16'd0 ,

   parameter TXSDLL               = 512   ,
   parameter TCCD                 = 4     ,
   parameter TXP                  = 14    ,
   parameter TFAW                 = 40    ,
   parameter TRAS                 = 38    ,
   parameter TRCD                 = 15    ,
   parameter TREFI                = 7800  ,
   parameter TRFC                 = 160   ,
   parameter TRC                  = 40    ,
   parameter TRP                  = 15    ,
   parameter TRRD                 = 15    ,
   parameter TRTP                 = 15    ,
   parameter TWR                  = 15    ,
   parameter TWTR                 = 15
  )
  (
   input                                   clk             ,
   input                                   rst_n           ,

   input                                   phy_init_done   ,
   output                                  ddr_init_done   ,
`ifdef AXI_REDUCED_EN
   input [CTRL_ADDR_WIDTH-1:0]             axi_awaddr      , 
   input                                   axi_awuser_ap   ,
   input [3:0]                             axi_awuser_id   ,
   input [3:0]                             axi_awlen       ,
   output                                  axi_awready     ,
   input                                   axi_awvalid     ,
///                                                        
   input [MEM_DQ_WIDTH*8-1:0]              axi_wdata       ,   
   input [MEM_DQ_WIDTH*8/8-1:0]            axi_wstrb       ,   
   output                                  axi_wready      ,   
   output [3:0]                            axi_wusero_id   ,   
   output                                  axi_wusero_last ,   
///                                                    
   input  [CTRL_ADDR_WIDTH-1:0]            axi_araddr      ,     
   input                                   axi_aruser_ap   ,  
   input  [3:0]                            axi_aruser_id   ,  
   input  [3:0]                            axi_arlen       ,  
   output                                  axi_arready     ,  
   input                                   axi_arvalid     ,  
//                                                         
   output [MEM_DQ_WIDTH*8-1:0]             axi_rdata       ,
   output [3:0]                            axi_rid         , 
   output                                  axi_rlast       , 
   output                                  axi_rvalid      ,  
`elsif AXI_STANDARD_EN
 //axi write channel
   input [AXI_ADDR_WIDTH-1:0]              axi_awaddr      ,
   input [7:0]                             axi_awid        ,
   input [7:0]                             axi_awlen       ,
   input [2:0]                             axi_awsize      ,
   input [1:0]                             axi_awburst     ,        //only support 2'b01: INCR
   output                                  axi_awready     ,
   input                                   axi_awvalid     ,
   input [AXI_DATA_WIDTH-1:0]              axi_wdata       ,
   input [AXI_DATA_WIDTH/8-1:0]            axi_wstrb       ,
   input                                   axi_wlast       ,
   input                                   axi_wvalid      ,
   output                                  axi_wready      ,
   input                                   axi_bready      ,
   output [7:0]                            axi_bid         ,
   output [1:0]                            axi_bresp       ,
   output                                  axi_bvalid      ,
 //axi read  channel
   input [AXI_ADDR_WIDTH-1:0]              axi_araddr      ,
   input [7:0]                             axi_arid        ,
   input [7:0]                             axi_arlen       ,
   input [2:0]                             axi_arsize      ,
   input [1:0]                             axi_arburst     ,       //only support 2'b01: INCR
   input                                   axi_arvalid     ,
   output                                  axi_arready     ,
   input                                   axi_rready      ,
   output [AXI_DATA_WIDTH-1:0]             axi_rdata       ,
   output                                  axi_rvalid      ,
   output                                  axi_rlast       ,
   output [7:0]                            axi_rid         ,
   output [1:0]                            axi_rresp       ,
`endif

   input                                   apb_clk         ,
   input                                   apb_rst_n       ,
   input                                   apb_sel         ,
   input                                   apb_enable      ,
   input  [7:0]                            apb_addr        ,
   input                                   apb_write       ,
   output                                  apb_ready       ,
   input  [15:0]                           apb_wdata       ,
   output [15:0]                           apb_rdata       ,

   input                                   ddr_zqcs_req    ,
   output                                  ddr_zqcs_ack    ,

   input                                   dfi_phyupd_req  ,
   output                                  dfi_phyupd_ack  ,

   output [4*MEM_ROW_ADDR_WIDTH-1:0]       dfi_address     ,
   output [4*MEM_BA_ADDR_WIDTH-1:0]        dfi_bank        ,
   output [4-1:0]                          dfi_cs_n        ,

   output [4-1:0]                          dfi_ras_n       ,
   output [4-1:0]                          dfi_cas_n       ,
   output [4-1:0]                          dfi_we_n        ,
   output [4-1:0]                          dfi_cke         ,
   output [4-1:0]                          dfi_odt         ,
   output [2*4*MEM_DQ_WIDTH-1:0]           dfi_wrdata      ,
   output [4-1:0]                          dfi_wrdata_en   ,
   output [2*4*MEM_DQ_WIDTH/8-1:0]         dfi_wrdata_mask ,
   input  [2*4*MEM_DQ_WIDTH-1:0]           dfi_rddata      ,
   input                                   dfi_rddata_valid
   );

///***********************************************************************
//
//************************************************************************

   wire                           user_cmd_valid       ;
   wire                           user_cmd_ready       ;
   wire                           user_write           ; //1 write; 0  read
   wire                           user_double_wr       ;
   wire                           user_ap              ; //1 ap
   wire [CTRL_ADDR_WIDTH-1:0]     user_addr            ;
   wire [MEM_ROW_ADDR_WIDTH-1:0]  user_old_row_addr    ;
   wire                           user_row_addr_diff   ;
   wire [9:0]                     user_port_id         ;
   wire [3:0]                     user_len             ;

   wire [9:0]                     mac_axi_rid          ;
   wire                           mac_axi_rlast        ;
   wire [MEM_DQ_WIDTH*8-1:0]      mac_axi_rdata        ;
   wire                           mac_axi_rvalid       ;
   wire [9:0]                     mac_axi_wusero_id    ;
   wire                           mac_axi_wready       ;
   wire                           mac_axi_wusero_last  ;
   wire [MEM_DQ_WIDTH*8-1:0]      mac_axi_wdata        ;
   wire [MEM_DQ_WIDTH-1:0]        mac_axi_wstrb        ;
`ifdef AXI_REDUCED_EN
   wire [3:0]                     user_id              ;

ips2l_mcdq_ui_axi_v1_5a  #
(
   .CTRL_ADDR_WIDTH        (CTRL_ADDR_WIDTH      ),  
   .MEM_ROW_ADDR_WIDTH     (MEM_ROW_ADDR_WIDTH   ),   
   .MEM_COL_ADDR_WIDTH     (MEM_COL_ADDR_WIDTH   ),   
   .TOTAL_BA_ADDR_WIDTH    (MEM_BA_ADDR_WIDTH  ), 
   .ADDR_MAPPING_SEL       (ADDR_MAPPING_SEL     )
) mcdq_ui_axi (
   .clk                    (clk                  ),                                  
   .rst_n                  (rst_n                ),                                                             
 ////AXI WRITE ADDR
   .axi_awaddr             (axi_awaddr           ),                                  
   .axi_awuser_ap          (axi_awuser_ap        ),                                  
   .axi_awuser_id          (axi_awuser_id        ),                                  
   .axi_awlen              (axi_awlen            ),                                  
   .axi_awready            (axi_awready          ),                                  
   .axi_awvalid            (axi_awvalid          ),                                                                          
 //axi read addr channel 0
   .axi_araddr             (axi_araddr           ),                                  
   .axi_aruser_ap          (axi_aruser_ap        ),                                  
   .axi_aruser_id          (axi_aruser_id        ),                                  
   .axi_arlen              (axi_arlen            ),                                  
   .axi_arready            (axi_arready          ),                                  
   .axi_arvalid            (axi_arvalid          ),                                                           
 ///dcd 
   .user_cmd_valid         (user_cmd_valid       ),                                  
   .user_cmd_ready         (user_cmd_ready       ),                                  
   .user_write             (user_write           ), //1 write; 0  read     
   .user_double_wr         (user_double_wr       ),          
   .user_ap                (user_ap              ), //1 ap                           
   .user_addr              (user_addr            ),  
   .user_old_row_addr      (user_old_row_addr    ),
   .user_row_addr_diff     (user_row_addr_diff   ),                               
   .user_id                (user_id              ),                                  
   .user_len               (user_len             )
);

assign user_port_id    = {6'b0,user_id};
assign axi_rid         = mac_axi_rid[3:0]   ;
assign axi_rlast       = mac_axi_rlast      ;
assign axi_rdata       = mac_axi_rdata      ;
assign axi_rvalid      = mac_axi_rvalid     ;
assign axi_wusero_id   = mac_axi_wusero_id[3:0];
assign axi_wready      = mac_axi_wready     ;
assign axi_wusero_last = mac_axi_wusero_last;
assign mac_axi_wdata   = axi_wdata          ;
assign mac_axi_wstrb   = axi_wstrb          ;
`elsif AXI_STANDARD_EN
ips2l_mcdq_axi_mc_v1_6  #
(
  .AXI0_ADDR_WIDTH        (AXI_ADDR_WIDTH       ),
  .AXI0_DATA_WIDTH        (AXI_DATA_WIDTH       ),
  .WR_WEIGHT              (WR_WEIGHT             ),        //1-7
  .RD_WEIGHT              (RD_WEIGHT             ),        //1-7
  .MEM_ROW_ADDR_WIDTH     (MEM_ROW_ADDR_WIDTH    ),
  .MEM_COL_ADDR_WIDTH     (MEM_COL_ADDR_WIDTH    ),
  .TOTAL_BA_ADDR_WIDTH    (MEM_BA_ADDR_WIDTH   ),
  .CTRL_ADDR_WIDTH        (CTRL_ADDR_WIDTH       ),
  .MEM_DQ_WIDTH           (MEM_DQ_WIDTH          )
)
mcdq_axi_mc
(
   .clk                     (clk                    ),
   .rst_n                   (rst_n                  ),

   .axi0_awaddr             (axi_awaddr             ),
   .axi0_awid               (axi_awid               ),
   .axi0_awlen              (axi_awlen              ),
   .axi0_awsize             (axi_awsize             ),
   .axi0_awburst            (axi_awburst            ),        //only support 2'b01: INCR
   .axi0_awready            (axi_awready            ),
   .axi0_awvalid            (axi_awvalid            ),
   .axi0_wdata              (axi_wdata              ),
   .axi0_wstrb              (axi_wstrb              ),
   .axi0_wlast              (axi_wlast              ),
   .axi0_wvalid             (axi_wvalid             ),
   .axi0_wready             (axi_wready             ),
   .axi0_bready             (axi_bready             ),
   .axi0_bid                (axi_bid                ),
   .axi0_bresp              (axi_bresp              ),
   .axi0_bvalid             (axi_bvalid             ),

   .axi0_araddr             (axi_araddr             ),
   .axi0_arid               (axi_arid               ),
   .axi0_arlen              (axi_arlen              ),
   .axi0_arsize             (axi_arsize             ),
   .axi0_arburst            (axi_arburst            ),       //only support 2'b01: INCR
   .axi0_arvalid            (axi_arvalid            ),
   .axi0_arready            (axi_arready            ),
   .axi0_rready             (axi_rready             ),
   .axi0_rdata              (axi_rdata              ),
   .axi0_rvalid             (axi_rvalid             ),
   .axi0_rlast              (axi_rlast              ),
   .axi0_rid                (axi_rid                ),
   .axi0_rresp              (axi_rresp              ),

//mac
   .user_cmd_valid           (user_cmd_valid           ),
   .user_cmd_ready           (user_cmd_ready           ),
   .user_write               (user_write               ),     //1 write; 0  read
   .user_double_wr           (user_double_wr           ),
   .user_ap                  (user_ap                  ),     //1 ap
   .user_addr                (user_addr                ),
   .user_old_row_addr        (user_old_row_addr        ),
   .user_row_addr_diff       (user_row_addr_diff       ),
   .user_port_id             (user_port_id             ),     //{user_port,user_id}
   .user_len                 (user_len                 ),

   .mac_axi_rid              (mac_axi_rid              ),
   .mac_axi_rlast            (mac_axi_rlast            ),
   .mac_axi_rdata            (mac_axi_rdata            ),
   .mac_axi_rvalid           (mac_axi_rvalid           ),
   .mac_axi_wusero_id        (mac_axi_wusero_id        ),
   .mac_axi_wready           (mac_axi_wready           ),
   .mac_axi_wusero_last      (mac_axi_wusero_last      ),
   .mac_axi_wdata            (mac_axi_wdata            ),
   .mac_axi_wstrb            (mac_axi_wstrb            )
);
`endif

ips2l_mcdq_mac_top_v1_8b #(
   .DDR_TYPE                 (DDR_TYPE                 ),
   .MEM_ROW_ADDR_WIDTH       (MEM_ROW_ADDR_WIDTH       ),
   .MEM_COL_ADDR_WIDTH       (MEM_COL_ADDR_WIDTH       ),
   .MEM_BA_ADDR_WIDTH        (MEM_BA_ADDR_WIDTH        ),
   .MEM_DQ_WIDTH             (MEM_DQ_WIDTH             ),
   .CTRL_ADDR_WIDTH          (CTRL_ADDR_WIDTH          ),
   .TOTAL_ADDR_WIDTH         (MEM_ROW_ADDR_WIDTH       ),
   .REF_NUM                  (REF_NUM                  ),

   .MR0_DDR3                 (MR0_DDR3                 ),
   .MR1_DDR3                 (MR1_DDR3                 ),
   .MR2_DDR3                 (MR2_DDR3                 ),
   .MR3_DDR3                 (MR3_DDR3                 ),
   .MR_DDR2                  (16'd0                    ),
   .EMR1_DDR2                (16'd0                    ),
   .EMR2_DDR2                (16'd0                    ),
   .EMR3_DDR2                (16'd0                    ),
   .MR_LPDDR                 (16'd0                    ),
   .EMR_LPDDR                (16'd0                    ),

   .TXSDLL                   (TXSDLL                   ),
   .TCCD                     (TCCD                     ),
   .TXP                      (TXP                      ),
   .TFAW                     (TFAW                     ),
   .TRAS                     (TRAS                     ),
   .TRCD                     (TRCD                     ),
   .TREFI                    (TREFI                    ),
   .TRFC                     (TRFC                     ),
   .TRC                      (TRC                      ),
   .TRP                      (TRP                      ),
   .TRRD                     (TRRD                     ),
   .TRTP                     (TRTP                     ),
   .TWR                      (TWR                      ),
   .TWTR                     (TWTR                     )
  )
  mcdq_mac_top
  (
   .clk                          (clk                      ),
   .rst_n                        (rst_n                    ),

   .user_cmd_valid               (user_cmd_valid           ),
   .user_cmd_ready               (user_cmd_ready           ),
   .user_write                   (user_write               ),
   .user_double_wr               (user_double_wr           ),
   .user_ap                      (user_ap                  ),
   .user_addr                    (user_addr                ),
   .user_old_row_addr            (user_old_row_addr        ),
   .user_row_addr_diff           (user_row_addr_diff       ),
   .user_id                      (user_port_id             ),   //{user_port,user_id}
   .user_len                     (user_len                 ),

   .mac_axi_rid                  (mac_axi_rid              ),
   .mac_axi_rlast                (mac_axi_rlast            ),
   .mac_axi_rdata                (mac_axi_rdata            ),
   .mac_axi_rvalid               (mac_axi_rvalid           ),
   .mac_axi_wusero_id            (mac_axi_wusero_id        ),
   .mac_axi_wready               (mac_axi_wready           ),
   .mac_axi_wusero_last          (mac_axi_wusero_last      ),
   .mac_axi_wdata                (mac_axi_wdata            ),
   .mac_axi_wstrb                (mac_axi_wstrb            ),

   .phy_init_done                (phy_init_done            ),
   .ddr_init_done                (ddr_init_done            ),

   .apb_clk                      (apb_clk                  ),
   .apb_rst_n                    (apb_rst_n                ),
   .apb_sel                      (apb_sel                  ),
   .apb_enable                   (apb_enable               ),
   .apb_addr                     (apb_addr                 ),
   .apb_write                    (apb_write                ),
   .apb_ready                    (apb_ready                ),
   .apb_wdata                    (apb_wdata                ),
   .apb_rdata                    (apb_rdata                ),

   .ddr_zqcs_req                 (ddr_zqcs_req             ),
   .ddr_zqcs_ack                 (ddr_zqcs_ack             ),

   .dfi_phyupd_req               (dfi_phyupd_req           ),
   .dfi_phyupd_ack               (dfi_phyupd_ack           ),

   .dfi_address                  (dfi_address              ),
   .dfi_bank                     (dfi_bank                 ),
   .dfi_cs_n                     (dfi_cs_n                 ),
   `ifdef IPS2T_DDR4
   .dfi_bg                       (dfi_bg                   ),
   .dfi_act_n                    (dfi_act_n                ),
   `else
   .dfi_ras_n                    (dfi_ras_n                ),
   .dfi_cas_n                    (dfi_cas_n                ),
   .dfi_we_n                     (dfi_we_n                 ),
   `endif
   .dfi_cke                      (dfi_cke                  ),
   .dfi_odt                      (dfi_odt                  ),
   .dfi_wrdata                   (dfi_wrdata               ),
   .dfi_wrdata_en                (dfi_wrdata_en            ),
   .dfi_wrdata_mask              (dfi_wrdata_mask          ),
   .dfi_rddata                   (dfi_rddata               ),
   .dfi_rddata_valid             (dfi_rddata_valid         )
   );  
                                                               
endmodule              
