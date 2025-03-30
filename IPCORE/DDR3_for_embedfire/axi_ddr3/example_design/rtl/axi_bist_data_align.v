////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2021 Shenzhen Pango Microsystems CO.,LTD
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module axi_bist_data_align #(
  parameter AXI_ADDR_WIDTH         = 32 ,
  parameter AXI_DATA_WIDTH         = 256,   //32,64,128,256,512
  parameter CTRL_ADDR_WIDTH        = 32 ,
  parameter MEM_DQ_WIDTH           = 16    //8,16,32,64
)(

   input                            clk          ,
   input                            rst_n        ,
//AXI
   input   [CTRL_ADDR_WIDTH-1:0]    bist_axi_awaddr     ,
   input                            bist_axi_awuser_ap  ,
   input   [3:0]                    bist_axi_awuser_id  ,
   input   [3:0]                    bist_axi_awlen      ,
   output                           bist_axi_awready    ,
   input                            bist_axi_awvalid    ,
   output                           bist_axi_bvalid     ,

   input  [MEM_DQ_WIDTH*8-1:0]      bist_axi_wdata      ,
   input  [MEM_DQ_WIDTH*8/8-1:0]    bist_axi_wstrb      ,
   output reg                       bist_axi_wready     ,
   input   [CTRL_ADDR_WIDTH-1:0]    bist_axi_araddr     ,
   input                            bist_axi_aruser_ap  ,
   input   [3:0]                    bist_axi_aruser_id  ,
   input   [3:0]                    bist_axi_arlen      ,
   output                           bist_axi_arready    ,
   input                            bist_axi_arvalid    ,
   output [MEM_DQ_WIDTH*8-1:0]      bist_axi_rdata      ,
   output                           bist_axi_rvalid     ,

 //axi write channel
   output [AXI_ADDR_WIDTH-1:0]       axi_awaddr     ,
   output [7:0]                      axi_awid       ,
   output [7:0]                      axi_awlen      ,
   output [2:0]                      axi_awsize     ,
   output [1:0]                      axi_awburst    ,        //only support 2'b01: INCR
   input                             axi_awready    ,
   output reg                        axi_awvalid    ,
   output [AXI_DATA_WIDTH-1:0]       axi_wdata      ,
   output [AXI_DATA_WIDTH/8-1:0]     axi_wstrb      ,
   output                            axi_wlast      ,
   output                            axi_wvalid     ,
   input                             axi_wready     ,
   output                            axi_bready     ,
   input [7:0]                       axi_bid        ,
   input [1:0]                       axi_bresp      ,
   input                             axi_bvalid     ,
 //axi read  channel
   output [AXI_ADDR_WIDTH-1:0]       axi_araddr     ,
   output [7:0]                      axi_arid       ,
   output [7:0]                      axi_arlen      ,
   output [2:0]                      axi_arsize     ,
   output [1:0]                      axi_arburst    ,       //only support 2'b01: INCR
   output                            axi_arvalid    ,
   input                             axi_arready    ,
   output                            axi_rready     ,
   input [AXI_DATA_WIDTH-1:0]        axi_rdata      ,
   input                             axi_rvalid     ,
   input                             axi_rlast      ,
   input [7:0]                       axi_rid        ,
   input [1:0]                       axi_rresp
);

parameter AXI_ADDR_SHIFT = (MEM_DQ_WIDTH == 8)  ? 0 :
                           (MEM_DQ_WIDTH == 16) ? 1 :
                           (MEM_DQ_WIDTH == 32) ? 2 :
                           (MEM_DQ_WIDTH == 64) ? 3 : 3;

parameter DATA_WIDTH_MUL = MEM_DQ_WIDTH*8/AXI_DATA_WIDTH;
parameter LEN_SHIFT = (DATA_WIDTH_MUL == 1)  ? 0 :
                      (DATA_WIDTH_MUL == 2)  ? 1 :
                      (DATA_WIDTH_MUL == 4)  ? 2 :
                      (DATA_WIDTH_MUL == 8)  ? 3 :
                      (DATA_WIDTH_MUL == 16) ? 4 : 4;

parameter SAMEWIDTH_EN = (MEM_DQ_WIDTH*8 == AXI_DATA_WIDTH) ? 1 : 0 ;

reg [CTRL_ADDR_WIDTH-1:0] bist_axi_awaddr_d1;
reg [3:0] bist_axi_awuser_id_d1;
reg [3:0] bist_axi_awlen_d1;
reg [3:0] bist_axi_wdata_cnt;
reg [7:0] axi_wdata_cnt;
reg wr_align_done;
wire [8:0] axi_awlen_a;
wire [8:0] axi_awlen_b;

assign axi_awburst = 2'b01;
assign axi_arburst = 2'b01;
assign axi_awsize = (AXI_DATA_WIDTH == 32)  ? 3'b010 :
                    (AXI_DATA_WIDTH == 64)  ? 3'b011 :
                    (AXI_DATA_WIDTH == 128) ? 3'b100 :
                    (AXI_DATA_WIDTH == 256) ? 3'b101 :
                    (AXI_DATA_WIDTH == 512) ? 3'b110 : 3'b110;

assign axi_arsize = (AXI_DATA_WIDTH == 32)  ? 3'b010 :
                    (AXI_DATA_WIDTH == 64)  ? 3'b011 :
                    (AXI_DATA_WIDTH == 128) ? 3'b100 :
                    (AXI_DATA_WIDTH == 256) ? 3'b101 :
                    (AXI_DATA_WIDTH == 512) ? 3'b110 : 3'b110;

assign bist_axi_awready = bist_axi_awvalid & wr_align_done & axi_awready;
assign bist_axi_bvalid = axi_bvalid;

assign axi_awaddr = {bist_axi_awaddr_d1,{AXI_ADDR_SHIFT{1'b0}}};
assign axi_awid = {4'd0,bist_axi_awuser_id};
assign axi_awlen_a = ({5'b0,bist_axi_awlen_d1} + 9'd1) << LEN_SHIFT;
assign axi_awlen_b = axi_awlen_a - 9'b1;
assign axi_awlen = axi_awlen_b[7:0];
assign axi_wlast = axi_wdata_cnt == axi_awlen;
assign axi_bready = 1;

  always @(posedge clk or negedge rst_n )
  begin
  	if(!rst_n)begin
  		bist_axi_awaddr_d1 <= {CTRL_ADDR_WIDTH{1'b0}};
  		bist_axi_awuser_id_d1 <= 4'd0;
  		bist_axi_awlen_d1 <= 4'd0;
  	end
  	else if(bist_axi_awready & bist_axi_awvalid) begin
  		bist_axi_awaddr_d1 <= bist_axi_awaddr;
  		bist_axi_awuser_id_d1 <= bist_axi_awuser_id;
  		bist_axi_awlen_d1 <= bist_axi_awlen;
  	end
  end

  always @(posedge clk or negedge rst_n )
  begin
  	if(!rst_n)
  	axi_awvalid <= 0;
  	else if(bist_axi_awready & bist_axi_awvalid)
  	axi_awvalid <= 1;
  	else if(axi_awready & axi_awvalid)
  	axi_awvalid <= 0;
  end

  always @(posedge clk or negedge rst_n )
  begin
  	if(!rst_n)
  	bist_axi_wdata_cnt <= 4'd0;
  	else if(bist_axi_awready & bist_axi_awvalid)
  	bist_axi_wdata_cnt <= 4'd0;
  	else if(bist_axi_wready)
  	bist_axi_wdata_cnt <= bist_axi_wdata_cnt + 4'd1;
  end

  always @(posedge clk or negedge rst_n )
  begin
  	if(!rst_n)
  	bist_axi_wready <= 0;
  	else if(bist_axi_awready & bist_axi_awvalid)
  	bist_axi_wready <= 1;
  	else if(bist_axi_wdata_cnt == bist_axi_awlen_d1)
  	bist_axi_wready <= 0;
  end

  always @(posedge clk or negedge rst_n )
  begin
  	if(!rst_n)
  	axi_wdata_cnt <= 8'd0;
  	else if(bist_axi_awready & bist_axi_awvalid)
  	axi_wdata_cnt <= 8'd0;
  	else if(axi_wready & axi_wvalid)
  	axi_wdata_cnt <= axi_wdata_cnt + 8'd1;
  end

  always @(posedge clk or negedge rst_n )
  begin
  	if(!rst_n)
    wr_align_done <= 1;
    else if(bist_axi_awready & bist_axi_awvalid)
    wr_align_done <= 0;
    else if(axi_wready & axi_wvalid & (axi_wdata_cnt == axi_awlen))
    wr_align_done <= 1;
  end

ips2t_data_fifo #(
 .SAMEWIDTH_EN        (SAMEWIDTH_EN           ),         // @IPC bool
 .WR_DEPTH_WIDTH      (9                      ),         // @IPC int 8,20
 .WR_DATA_WIDTH       (MEM_DQ_WIDTH*8         ),         // @IPC int 1,1152
 .RD_DEPTH_WIDTH      (9 + LEN_SHIFT          ),         // @IPC int 8,20
 .RD_DATA_WIDTH       (AXI_DATA_WIDTH         )          // @IPC int 1,1152
)
u_axi_wdata_align_fifo
(
 .clk              (clk              ),
 .rst_n            (rst_n            ),
 .wvalid           (bist_axi_wready  ),
 .wdata            (bist_axi_wdata   ),
 .wready           (    ),
 .wdata_out_ready  (axi_wready       ),
 .wdata_out_valid  (axi_wvalid       ),
 .wdata_out        (axi_wdata        )
);

ips2t_data_fifo #(
 .SAMEWIDTH_EN        (SAMEWIDTH_EN           ),         // @IPC bool
 .WR_DEPTH_WIDTH      (9                      ),         // @IPC int 8,20
 .WR_DATA_WIDTH       (MEM_DQ_WIDTH           ),         // @IPC int 1,1152
 .RD_DEPTH_WIDTH      (9 + LEN_SHIFT          ),         // @IPC int 8,20
 .RD_DATA_WIDTH       (AXI_DATA_WIDTH/8       )          // @IPC int 1,1152
)
u_axi_wstrb_align_fifo
(
 .clk              (clk              ),
 .rst_n            (rst_n            ),
 .wvalid           (bist_axi_wready  ),
 .wdata            (bist_axi_wstrb   ),
 .wready           ( ),
 .wdata_out_ready  (axi_wready      ),
 .wdata_out_valid  (  ),
 .wdata_out        (axi_wstrb       )
);

wire [8:0] axi_arlen_a;
wire [8:0] axi_arlen_b;

assign bist_axi_arready = bist_axi_arvalid & axi_arready;
assign axi_arvalid = bist_axi_arvalid;
assign axi_araddr = {bist_axi_araddr,{AXI_ADDR_SHIFT{1'b0}}};
assign axi_arlen_a = ({5'b0,bist_axi_arlen} + 9'd1) << LEN_SHIFT;
assign axi_arlen_b = axi_arlen_a - 9'b1;
assign axi_arlen = axi_arlen_b[7:0];
assign axi_arid = {4'd0,bist_axi_aruser_id};

ips2t_data_fifo #(
 .SAMEWIDTH_EN        (SAMEWIDTH_EN           ),         // @IPC bool
 .WR_DEPTH_WIDTH      (9 + LEN_SHIFT          ),         // @IPC int 8,20
 .WR_DATA_WIDTH       (AXI_DATA_WIDTH         ),         // @IPC int 1,1152
 .RD_DEPTH_WIDTH      (9                      ),         // @IPC int 8,20
 .RD_DATA_WIDTH       (MEM_DQ_WIDTH*8         )          // @IPC int 1,1152
)
u_axi_rdata_align_fifo
(
 .clk              (clk              ),
 .rst_n            (rst_n            ),
 .wvalid           (axi_rvalid       ),
 .wdata            (axi_rdata        ),
 .wready           (axi_rready       ),
 .wdata_out_ready  (1'b1             ),
 .wdata_out_valid  (bist_axi_rvalid  ),
 .wdata_out        (bist_axi_rdata   )
);




endmodule
