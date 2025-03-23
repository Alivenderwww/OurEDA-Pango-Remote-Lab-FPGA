// Created by IP Generator (Version 2021.1-SP5 build 79250)


//////////////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2019 PANGO MICROSYSTEMS, INC
// ALL RIGHTS REVERVED.
//
// THE SOURCE CODE CONTAINED HEREIN IS PROPRIETARY TO PANGO MICROSYSTEMS, INC.
// IT SHALL NOT BE REPRODUCED OR DISCLOSED IN WHOLE OR IN PART OR USED BY
// PARTIES WITHOUT WRITTEN AUTHORIZATION FROM THE OWNER.
//
//////////////////////////////////////////////////////////////////////////////
// Library:
// Filename:ips2t_drm_fifo.v
//////////////////////////////////////////////////////////////////////////////

module ips2t_data_fifo #(
  parameter SAMEWIDTH_EN     = 1          , // @IPC bool
  parameter WR_DEPTH_WIDTH   = 8          , // @IPC int 9,20
  parameter WR_DATA_WIDTH    = 256        , // @IPC int 1,1152
  parameter RD_DEPTH_WIDTH   = 8          , // @IPC int 9,20
  parameter RD_DATA_WIDTH    = 256          // @IPC int 1,1152
)
(
input                        clk           ,
input                        rst_n         ,
input                        wvalid        ,
input [WR_DATA_WIDTH-1:0]    wdata         ,
output                       wready        ,
input                        wdata_out_ready ,
output reg                   wdata_out_valid ,
output [RD_DATA_WIDTH-1:0]   wdata_out     
);

localparam ALMOST_FULL_NUM = 2**WR_DEPTH_WIDTH -4;

wire wr_en      ;
wire [WR_DATA_WIDTH-1:0] wr_data;
wire almost_full;
wire rd_en;
wire [RD_DATA_WIDTH-1:0] rd_data;
wire rd_empty;

assign wready = ~almost_full;
assign wr_en = wvalid & wready;
assign wr_data = wdata;
assign rd_en = ~rd_empty & (wdata_out_ready | ~wdata_out_valid);
assign wdata_out = rd_data;

  always @(posedge clk or negedge rst_n )
  begin
  	if(!rst_n)
  	wdata_out_valid <= 0;
  	else if(rd_en)
  	wdata_out_valid <= 1;
  	else if(wdata_out_ready)
  	wdata_out_valid <= 0;
  end

ips2t_drm_fifo #
(
  .RESET_TYPE        ( "ASYNC"       ), // @IPC enum SYNC,ASYNC
  .FIFO_TYPE         ( "SYN_FIFO"    ), // @IPC enum SYN_FIFO,ASYN_FIFO
  .POWER_OPT         ( 1             ), // @IPC bool
  .SAMEWIDTH_EN      ( SAMEWIDTH_EN  ), // @IPC bool
  .WR_DEPTH_WIDTH    ( WR_DEPTH_WIDTH), // @IPC int 9,20
  .WR_DATA_WIDTH     ( WR_DATA_WIDTH ), // @IPC int 1,1152
  .RD_DEPTH_WIDTH    ( RD_DEPTH_WIDTH), // @IPC int 9,20
  .RD_DATA_WIDTH     ( RD_DATA_WIDTH ), // @IPC int 1,1152
  .ALMOST_FULL_NUM   ( ALMOST_FULL_NUM), // @IPC int
  .ALMOST_EMPTY_NUM  ( 4             )  // @IPC int
)
u_ips2t_drm_fifo
(
  .clk             (clk           ),  // sync fifo clock in
  .rst             (~rst_n        ),  // sync fifo reset in    
  .wr_en           (wr_en         ),  // input write enable 1 active
  .wr_data         (wr_data       ),  // input write data
  .wr_full         (         ),  // output write full  flag 1 active    
  .rd_en           (rd_en         ),  // input read enable
  .rd_data         (rd_data       ),  // output read data    
  .almost_full     (almost_full   ),  // output write almost full
  .rd_empty        (rd_empty      ),  // output read empty   
  .almost_empty    (   )   // output write almost empty 
   );

endmodule
