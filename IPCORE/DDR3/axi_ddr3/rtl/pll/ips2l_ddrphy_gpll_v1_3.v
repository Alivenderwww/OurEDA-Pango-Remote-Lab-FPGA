////////////////////////////////////////////////////////////////
// Copyright (c) 2019 PANGO MICROSYSTEMS, INC
// ALL RIGHTS REVERVED.
////////////////////////////////////////////////////////////////
//Description:
//Author:  wxxiao
//History: v1.1
////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
module ips2l_ddrphy_gpll_v1_3 #( 
parameter   real CLKIN_FREQ =  50.0,
parameter   BANDWIDTH  = "OPTIMIZED",
parameter   IDIV       =  2,
parameter   FDIV       =  64.0,
parameter   DUTYF      =  64,
parameter   ODIV0      =  4.0,
parameter   ODIV1      =  16,
parameter   DUTY0      =  4,
parameter   STATIC_PHASE0 = 0 ,
parameter   INTERNAL_FB  = "CLKOUTF"
)(
input   clk_in0,
input   pll_rst,
//input   glogen,
input   dps_clk,
input   dps_en ,
input   dps_dir,
input   clkout0_gate,
output  clkout0,
output  clkout0n,
output  clkout1,
output  clkout1n,
output  dps_done,
output  pll_lock
);

parameter  ODIV2   =  4;
parameter  ODIV3   =  8;
parameter  ODIV4   =  16;
parameter  ODIV5   =  32;
parameter  ODIV6   =  64;


GTP_GPLL #(
  .CLKIN_FREQ         (CLKIN_FREQ), 
  .LOCK_MODE          (1'b0      ), 
  .STATIC_RATIOI      (IDIV   ),    
  .STATIC_RATIOM      (1   ),    
  .STATIC_RATIO0      (ODIV0),      
  .STATIC_RATIO1      (ODIV1),      
  .STATIC_RATIO2      (ODIV2),      
  .STATIC_RATIO3      (ODIV3),      
  .STATIC_RATIO4      (ODIV4),      
  .STATIC_RATIO5      (ODIV5),      
  .STATIC_RATIO6      (ODIV6),      
  .STATIC_RATIOF      (FDIV ),      
  .STATIC_DUTY0       (DUTY0),      
  .STATIC_DUTY1       (ODIV1),      
  .STATIC_DUTY2       (ODIV2),      
  .STATIC_DUTY3       (ODIV3),      
  .STATIC_DUTY4       (ODIV4),      
  .STATIC_DUTY5       (ODIV5),      
  .STATIC_DUTY6       (ODIV6),      
  .STATIC_DUTYF       (DUTYF ),      
  .STATIC_PHASE       (0),          
  .STATIC_PHASE0      (STATIC_PHASE0),          
  .STATIC_PHASE1      (0),          
  .STATIC_PHASE2      (0),          
  .STATIC_PHASE3      (0),          
  .STATIC_PHASE4      (0),          
  .STATIC_PHASE5      (0),          
  .STATIC_PHASE6      (0),          
  .STATIC_PHASEF      (0),          
  .STATIC_CPHASE0     (0),          
  .STATIC_CPHASE1     (0),          
  .STATIC_CPHASE2     (0),          
  .STATIC_CPHASE3     (0),          
  .STATIC_CPHASE4     (0),          
  .STATIC_CPHASE5     (0),          
  .STATIC_CPHASE6     (0),          
  .STATIC_CPHASEF     (0),          
  .CLK_DPS0_EN        ("TRUE" ),    
  .CLK_DPS1_EN        ("FALSE"),    
  .CLK_DPS2_EN        ("FALSE"),    
  .CLK_DPS3_EN        ("FALSE"),    
  .CLK_DPS4_EN        ("FALSE"),    
  .CLK_DPS5_EN        ("FALSE"),    
  .CLK_DPS6_EN        ("FALSE"),    
  .CLK_DPSF_EN        ("FALSE"),    
  .CLK_CAS5_EN        ("FALSE"),    
  .CLKOUT0_SYN_EN     ("TRUE" ),    
  .CLKOUT1_SYN_EN     ("FALSE"),    
  .CLKOUT2_SYN_EN     ("FALSE"),    
  .CLKOUT3_SYN_EN     ("FALSE"),    
  .CLKOUT4_SYN_EN     ("FALSE"),    
  .CLKOUT5_SYN_EN     ("FALSE"),    
  .CLKOUT6_SYN_EN     ("FALSE"),    
  .CLKOUTF_SYN_EN     ("FALSE"),    
  .SSC_MODE           ("DISABLE"),  
  .SSC_FREQ           (50.0),       
  .INTERNAL_FB        (INTERNAL_FB),  
  .EXTERNAL_FB        ("DISABLE"),  
  .BANDWIDTH          (BANDWIDTH)
 )u_gpll(
  .CLKOUT0                  (clkout0    ),
  .CLKOUT0N                 (clkout0n   ),
  .CLKOUT1                  (clkout1),
  .CLKOUT1N                 (clkout1n),
  .CLKOUT2                  (),
  .CLKOUT2N                 (),
  .CLKOUT3                  (),
  .CLKOUT3N                 (),
  .CLKOUT4                  (),
  .CLKOUT5                  (),
  .CLKOUT6                  (),
  .CLKOUTF                  (),
  .CLKOUTFN                 (),
  .LOCK                     (pll_lock),
  .DPS_DONE                 (dps_done),
  .APB_RDATA                (),
  .APB_READY                (),
  .CLKIN1                   (clk_in0 ),
  .CLKIN2                   (1'b0    ),
  .CLKFB                    (1'b0    ),
  .CLKIN_SEL                (1'b0    ),
  .DPS_CLK                  (dps_clk ),
  .DPS_EN                   (dps_en  ),
  .DPS_DIR                  (dps_dir ),
  .CLKOUT0_SYN              (clkout0_gate),
  .CLKOUT1_SYN              (1'b0),
  .CLKOUT2_SYN              (1'b0),
  .CLKOUT3_SYN              (1'b0),
  .CLKOUT4_SYN              (1'b0),
  .CLKOUT5_SYN              (1'b0),
  .CLKOUT6_SYN              (1'b0),
  .CLKOUTF_SYN              (1'b0),
  .PLL_PWD                  (1'b0),
  .RST                      (pll_rst),
  .APB_CLK                  (1'b0 ),
  .APB_RST_N                (1'b0 ),
  .APB_ADDR                 (5'b00000),
  .APB_SEL                  (1'b0),
  .APB_EN                   (1'b0),
  .APB_WRITE                (1'b0),
  .APB_WDATA                (16'd0)
 );

endmodule
