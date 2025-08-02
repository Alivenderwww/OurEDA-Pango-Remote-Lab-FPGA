module ov_hdmi_axi_master(
    input wire        clk,
    input wire        rstn,

    //camera interface (no need iic)
    input  wire       CCD_RSTN,
    input  wire       CCD_PCLK,
    input  wire       CCD_VSYNC,
    input  wire       CCD_HSYNC, //原理图把HREF和HSYNC搞混了
    input  wire [7:0] CCD_DATA,

    //hdmi interface
    input  wire        hdmi_in_clk,
    input  wire        hdmi_in_rstn,
    input  wire        hdmi_in_hsync,
    input  wire        hdmi_in_vsync,
    input  wire[23:0]  hdmi_in_rgb,
    input  wire        hdmi_in_de,

    //input base and end address
    input  wire [31:0] START_WRITE_ADDR,
    input  wire [31:0] END_WRITE_ADDR,
    input  wire        capture_on,
    input  wire        capture_rst,
    input  wire [15:0] expect_width, //期望宽度
    input  wire [15:0] expect_height, //期望高度

    //AXI MASTER interface
    output wire         MASTER_CLK          ,
    output wire         MASTER_RSTN         ,
    output wire [2-1:0] MASTER_WR_ADDR_ID   ,
    output wire [31:0]  MASTER_WR_ADDR      ,
    output wire [ 7:0]  MASTER_WR_ADDR_LEN  ,
    output wire [ 1:0]  MASTER_WR_ADDR_BURST,
    output wire         MASTER_WR_ADDR_VALID,
    input  wire         MASTER_WR_ADDR_READY,
    output wire [31:0]  MASTER_WR_DATA      ,
    output wire [ 3:0]  MASTER_WR_STRB      ,
    output wire         MASTER_WR_DATA_LAST ,
    output wire         MASTER_WR_DATA_VALID,
    input  wire         MASTER_WR_DATA_READY,
    input  wire [2-1:0] MASTER_WR_BACK_ID   ,
    input  wire [ 1:0]  MASTER_WR_BACK_RESP ,
    input  wire         MASTER_WR_BACK_VALID,
    output wire         MASTER_WR_BACK_READY,
    output wire [2-1:0] MASTER_RD_ADDR_ID   ,
    output wire [31:0]  MASTER_RD_ADDR      ,
    output wire [ 7:0]  MASTER_RD_ADDR_LEN  ,
    output wire [ 1:0]  MASTER_RD_ADDR_BURST,
    output wire         MASTER_RD_ADDR_VALID,
    input  wire         MASTER_RD_ADDR_READY,
    input  wire [2-1:0] MASTER_RD_BACK_ID   ,
    input  wire [31:0]  MASTER_RD_DATA      ,
    input  wire [ 1:0]  MASTER_RD_DATA_RESP ,
    input  wire         MASTER_RD_DATA_LAST ,
    input  wire         MASTER_RD_DATA_VALID,
    output wire         MASTER_RD_DATA_READY);

wire ov_hdmi_rstn_sync;
rstn_sync rstn_sync_ov_hdmi(clk, rstn, ov_hdmi_rstn_sync);

wire rd_clk;
wire rd_data_ready ,ov_rd_data_ready, hdmi_rd_data_ready;
wire rd_data_valid;
wire [31:0] rd_data, ov_rd_data, hdmi_rd_data;

assign rd_data_ready = hdmi_rd_data_ready;
assign rd_data = hdmi_rd_data;

axi_master_write_dma u_axi_master_write_dma(
	.START_WRITE_ADDR     	( START_WRITE_ADDR      ),
	.END_WRITE_ADDR       	( END_WRITE_ADDR        ),
	.clk                  	( clk                   ),
	.rstn                 	( ov_hdmi_rstn_sync     ),
	.rd_clk               	( rd_clk                ),
	.rd_capture_on        	( capture_on            ),
	.rd_capture_rst       	( capture_rst           ),
	.rd_data_ready        	( rd_data_ready         ),
	.rd_data_valid        	( rd_data_valid         ),
	.rd_data              	( rd_data               ),
	.MASTER_CLK           	( MASTER_CLK            ),
	.MASTER_RSTN          	( MASTER_RSTN           ),
	.MASTER_WR_ADDR_ID    	( MASTER_WR_ADDR_ID     ),
	.MASTER_WR_ADDR       	( MASTER_WR_ADDR        ),
	.MASTER_WR_ADDR_LEN   	( MASTER_WR_ADDR_LEN    ),
	.MASTER_WR_ADDR_BURST 	( MASTER_WR_ADDR_BURST  ),
	.MASTER_WR_ADDR_VALID 	( MASTER_WR_ADDR_VALID  ),
	.MASTER_WR_ADDR_READY 	( MASTER_WR_ADDR_READY  ),
	.MASTER_WR_DATA       	( MASTER_WR_DATA        ),
	.MASTER_WR_STRB       	( MASTER_WR_STRB        ),
	.MASTER_WR_DATA_LAST  	( MASTER_WR_DATA_LAST   ),
	.MASTER_WR_DATA_VALID 	( MASTER_WR_DATA_VALID  ),
	.MASTER_WR_DATA_READY 	( MASTER_WR_DATA_READY  ),
	.MASTER_WR_BACK_ID    	( MASTER_WR_BACK_ID     ),
	.MASTER_WR_BACK_RESP  	( MASTER_WR_BACK_RESP   ),
	.MASTER_WR_BACK_VALID 	( MASTER_WR_BACK_VALID  ),
	.MASTER_WR_BACK_READY 	( MASTER_WR_BACK_READY  ),
	.MASTER_RD_ADDR_ID    	( MASTER_RD_ADDR_ID     ),
	.MASTER_RD_ADDR       	( MASTER_RD_ADDR        ),
	.MASTER_RD_ADDR_LEN   	( MASTER_RD_ADDR_LEN    ),
	.MASTER_RD_ADDR_BURST 	( MASTER_RD_ADDR_BURST  ),
	.MASTER_RD_ADDR_VALID 	( MASTER_RD_ADDR_VALID  ),
	.MASTER_RD_ADDR_READY 	( MASTER_RD_ADDR_READY  ),
	.MASTER_RD_BACK_ID    	( MASTER_RD_BACK_ID     ),
	.MASTER_RD_DATA       	( MASTER_RD_DATA        ),
	.MASTER_RD_DATA_RESP  	( MASTER_RD_DATA_RESP   ),
	.MASTER_RD_DATA_LAST  	( MASTER_RD_DATA_LAST   ),
	.MASTER_RD_DATA_VALID 	( MASTER_RD_DATA_VALID  ),
	.MASTER_RD_DATA_READY 	( MASTER_RD_DATA_READY  )
);

wire trans_once_done = MASTER_WR_DATA_LAST && MASTER_WR_DATA_VALID && MASTER_WR_DATA_READY;
ov56450_data_store u_ov56450_data_store(
	.clk          	( rd_clk        ),
	.rstn         	( ov_hdmi_rstn_sync),
	.CCD_RSTN      	( CCD_RSTN      ),
	.CCD_PCLK     	( CCD_PCLK      ),
	.CCD_VSYNC    	( CCD_VSYNC     ),
	.CCD_HSYNC    	( CCD_HSYNC     ),
	.CCD_DATA     	( CCD_DATA      ),
    .capture_on  	( capture_on    ),
    .expect_width   ( expect_width  ),
    .expect_height  ( expect_height ),
    .trans_once_done( trans_once_done),
	.rd_data_valid  ( rd_data_valid ),
    .rd_data_ready  ( ov_rd_data_ready ),
	.rd_data 	    ( ov_rd_data       )
);

hdmi_data_store u_hdmi_data_store(
	.clk          	( rd_clk            ),
	.rstn         	( ov_hdmi_rstn_sync ),
    .hdmi_in_clk    ( hdmi_in_clk       ),
    .hdmi_in_rstn   ( hdmi_in_rstn      ),
    .hdmi_in_href   ( hdmi_in_de        ),
    .hdmi_in_vsync  ( hdmi_in_vsync     ),
    .hdmi_in_rgb    ( hdmi_in_rgb       ),
    .capture_on  	( capture_on        ),
    .trans_once_done( trans_once_done   ),
	.rd_data_valid  ( rd_data_valid     ),
    .rd_data_ready  ( hdmi_rd_data_ready),
	.rd_data 	    ( hdmi_rd_data 	    )
);


endmodule //ov5640_axi_master
