module streaming_axi_master_slave(
    input wire        clk,
    input wire        rstn,

    //hdmi interface
    input  wire         hdmi_in_clk,
    input  wire         hdmi_in_rstn,
    input  wire         hdmi_in_vsync,
    input  wire         hdmi_in_hsync,
    input  wire         hdmi_in_de,
    input  wire [23:0]  hdmi_in_rgb,

    //AXI MASTER interface
    output logic         MASTER_CLK          ,
    output logic         MASTER_RSTN         ,
    output logic [2-1:0] MASTER_WR_ADDR_ID   ,
    output logic [31:0]  MASTER_WR_ADDR      ,
    output logic [ 7:0]  MASTER_WR_ADDR_LEN  ,
    output logic [ 1:0]  MASTER_WR_ADDR_BURST,
    output logic         MASTER_WR_ADDR_VALID,
    input  logic         MASTER_WR_ADDR_READY,
    output logic [31:0]  MASTER_WR_DATA      ,
    output logic [ 3:0]  MASTER_WR_STRB      ,
    output logic         MASTER_WR_DATA_LAST ,
    output logic         MASTER_WR_DATA_VALID,
    input  logic         MASTER_WR_DATA_READY,
    input  logic [2-1:0] MASTER_WR_BACK_ID   ,
    input  logic [ 1:0]  MASTER_WR_BACK_RESP ,
    input  logic         MASTER_WR_BACK_VALID,
    output logic         MASTER_WR_BACK_READY,
    output logic [2-1:0] MASTER_RD_ADDR_ID   ,
    output logic [31:0]  MASTER_RD_ADDR      ,
    output logic [ 7:0]  MASTER_RD_ADDR_LEN  ,
    output logic [ 1:0]  MASTER_RD_ADDR_BURST,
    output logic         MASTER_RD_ADDR_VALID,
    input  logic         MASTER_RD_ADDR_READY,
    input  logic [2-1:0] MASTER_RD_BACK_ID   ,
    input  logic [31:0]  MASTER_RD_DATA      ,
    input  logic [ 1:0]  MASTER_RD_DATA_RESP ,
    input  logic         MASTER_RD_DATA_LAST ,
    input  logic         MASTER_RD_DATA_VALID,
    output logic         MASTER_RD_DATA_READY,
    
    //AXI SLAVE interface
    output logic         SLAVE_CLK          ,
    output logic         SLAVE_RSTN         ,
    input  logic [4-1:0] SLAVE_WR_ADDR_ID   ,
    input  logic [31:0]  SLAVE_WR_ADDR      ,
    input  logic [ 7:0]  SLAVE_WR_ADDR_LEN  ,
    input  logic [ 1:0]  SLAVE_WR_ADDR_BURST,
    input  logic         SLAVE_WR_ADDR_VALID,
    output logic         SLAVE_WR_ADDR_READY,
    input  logic [31:0]  SLAVE_WR_DATA      ,
    input  logic [ 3:0]  SLAVE_WR_STRB      ,
    input  logic         SLAVE_WR_DATA_LAST ,
    input  logic         SLAVE_WR_DATA_VALID,
    output logic         SLAVE_WR_DATA_READY,
    output logic [4-1:0] SLAVE_WR_BACK_ID   ,
    output logic [ 1:0]  SLAVE_WR_BACK_RESP ,
    output logic         SLAVE_WR_BACK_VALID,
    input  logic         SLAVE_WR_BACK_READY,
    input  logic [4-1:0] SLAVE_RD_ADDR_ID   ,
    input  logic [31:0]  SLAVE_RD_ADDR      ,
    input  logic [ 7:0]  SLAVE_RD_ADDR_LEN  ,
    input  logic [ 1:0]  SLAVE_RD_ADDR_BURST,
    input  logic         SLAVE_RD_ADDR_VALID,
    output logic         SLAVE_RD_ADDR_READY,
    output logic [4-1:0] SLAVE_RD_BACK_ID   ,
    output logic [31:0]  SLAVE_RD_DATA      ,
    output logic [ 1:0]  SLAVE_RD_DATA_RESP ,
    output logic         SLAVE_RD_DATA_LAST ,
    output logic         SLAVE_RD_DATA_VALID,
    input  logic         SLAVE_RD_DATA_READY);

localparam RD_INTERFACE_NUM = 2;
localparam WR_INTERFACE_NUM = 1;

wire [RD_INTERFACE_NUM-1:0] [31:0]  start_write_addr;
wire [RD_INTERFACE_NUM-1:0] [31:0]  end_write_addr;
wire [WR_INTERFACE_NUM-1:0] [31:0]  start_read_addr;
wire [WR_INTERFACE_NUM-1:0] [31:0]  end_read_addr;

wire [RD_INTERFACE_NUM-1:0]         rd_rstn;
wire [16-1:0]                       rd_capture_rstn;
wire [RD_INTERFACE_NUM-1:0]         rd_addr_reset;
wire [RD_INTERFACE_NUM-1:0]         rd_data_burst_valid;
wire [RD_INTERFACE_NUM-1:0]         rd_data_burst_ready;
wire [RD_INTERFACE_NUM-1:0] [7:0]   rd_data_burst;
wire [RD_INTERFACE_NUM-1:0]         rd_data_valid;
wire [RD_INTERFACE_NUM-1:0]         rd_data_ready;
wire [RD_INTERFACE_NUM-1:0] [31:0]  rd_data;
wire [RD_INTERFACE_NUM-1:0]         rd_data_last;

wire [WR_INTERFACE_NUM-1:0]         wr_rstn;
wire [16-1:0]                       wr_capture_rstn;
wire [WR_INTERFACE_NUM-1:0]         wr_addr_reset;
wire [WR_INTERFACE_NUM-1:0]         wr_data_burst_valid;
wire [WR_INTERFACE_NUM-1:0]         wr_data_burst_ready;
wire [WR_INTERFACE_NUM-1:0] [7:0]   wr_data_burst;
wire [WR_INTERFACE_NUM-1:0]         wr_data_valid;
wire [WR_INTERFACE_NUM-1:0]         wr_data_ready;
wire [WR_INTERFACE_NUM-1:0] [31:0]  wr_data;
wire [WR_INTERFACE_NUM-1:0]         wr_data_last;

axi_master_write_dma #(
    .RD_INTERFACE_NUM(RD_INTERFACE_NUM),
    .WR_INTERFACE_NUM(WR_INTERFACE_NUM)
)u_axi_master_write_dma(
	.START_WRITE_ADDR     	( start_write_addr      ),
	.END_WRITE_ADDR       	( end_write_addr        ),
	.START_READ_ADDR     	( start_read_addr       ),
	.END_READ_ADDR       	( end_read_addr         ),
	.clk                  	( clk                   ),
	.rstn                 	( rstn                  ),

    .rd_rstn                ( rd_rstn               ),
	.rd_capture_rstn      	( rd_capture_rstn[RD_INTERFACE_NUM-1:0]),
    .rd_addr_reset          ( rd_addr_reset         ),
    .rd_data_burst_valid    ( rd_data_burst_valid   ),
    .rd_data_burst_ready    ( rd_data_burst_ready   ),
    .rd_data_burst          ( rd_data_burst         ),
	.rd_data_ready        	( rd_data_ready         ),
	.rd_data_valid        	( rd_data_valid         ),
	.rd_data              	( rd_data               ),
    .rd_data_last           ( rd_data_last          ),

    .wr_rstn                ( wr_rstn               ),
	.wr_capture_rstn      	( wr_capture_rstn[WR_INTERFACE_NUM-1:0]),
    .wr_addr_reset          ( wr_addr_reset         ),
    .wr_data_burst_valid    ( wr_data_burst_valid   ),
    .wr_data_burst_ready    ( wr_data_burst_ready   ),
    .wr_data_burst          ( wr_data_burst         ),
	.wr_data_ready        	( wr_data_ready         ),
	.wr_data_valid        	( wr_data_valid         ),
	.wr_data              	( wr_data               ),
    .wr_data_last           ( wr_data_last          ),

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

wire        jpeg_add_need_frame_pos;
wire [31:0] jpeg_add_need_frame_num;
wire [31:0] jpeg_total_need_frame_num;
wire [31:0] jpeg_height_width;
wire [31:0] jpeg_save_num;
wire        jpeg_rd_info_valid;
wire        jpeg_rd_info_ready;
wire [31:0] jpeg_rd_info;

wire hdmi_notready;
wire [31:0] hdmi_height_width;

wire [13*8*8 - 1:0] Y_Quantizer;
wire [13*8*8 - 1:0] CB_Quantizer;
wire [13*8*8 - 1:0] CR_Quantizer;

streaming_axi_slave u_streaming_axi_slave(
	.clk                       	( clk                        ),
	.rstn                      	( rstn                       ),

	.rd_capture_rstn            ( rd_capture_rstn            ),
	.wr_capture_rstn            ( wr_capture_rstn            ),
	.start_write_addr0         	( start_write_addr[0]        ),
	.end_write_addr0           	( end_write_addr[0]          ),
	.start_write_addr1         	( start_write_addr[1]        ),
	.end_write_addr1           	( end_write_addr[1]          ),
	.start_read_addr0          	( start_read_addr[0]         ),
	.end_read_addr0            	( end_read_addr[0]           ),
	.hdmi_notready             	( hdmi_notready              ),
	.hdmi_height_width         	( hdmi_height_width          ),
	.jpeg_height_width         	( jpeg_height_width          ),
	.jpeg_add_need_frame_pos   	( jpeg_add_need_frame_pos    ),
	.jpeg_add_need_frame_num   	( jpeg_add_need_frame_num    ),
	.jpeg_total_need_frame_num 	( jpeg_total_need_frame_num  ),
	.jpeg_save_num             	( jpeg_save_num              ),
	.jpeg_rd_info_valid        	( jpeg_rd_info_valid         ),
	.jpeg_rd_info              	( jpeg_rd_info               ),
	.jpeg_rd_info_ready        	( jpeg_rd_info_ready         ),
    .Y_Quantizer                ( Y_Quantizer                ),
    .CB_Quantizer               ( CB_Quantizer               ),
    .CR_Quantizer               ( CR_Quantizer               ),

	.SLAVE_CLK                 	( SLAVE_CLK                  ),
	.SLAVE_RSTN                	( SLAVE_RSTN                 ),
	.SLAVE_WR_ADDR_ID          	( SLAVE_WR_ADDR_ID           ),
	.SLAVE_WR_ADDR             	( SLAVE_WR_ADDR              ),
	.SLAVE_WR_ADDR_LEN         	( SLAVE_WR_ADDR_LEN          ),
	.SLAVE_WR_ADDR_BURST       	( SLAVE_WR_ADDR_BURST        ),
	.SLAVE_WR_ADDR_VALID       	( SLAVE_WR_ADDR_VALID        ),
	.SLAVE_WR_ADDR_READY       	( SLAVE_WR_ADDR_READY        ),
	.SLAVE_WR_DATA             	( SLAVE_WR_DATA              ),
	.SLAVE_WR_STRB             	( SLAVE_WR_STRB              ),
	.SLAVE_WR_DATA_LAST        	( SLAVE_WR_DATA_LAST         ),
	.SLAVE_WR_DATA_VALID       	( SLAVE_WR_DATA_VALID        ),
	.SLAVE_WR_DATA_READY       	( SLAVE_WR_DATA_READY        ),
	.SLAVE_WR_BACK_ID          	( SLAVE_WR_BACK_ID           ),
	.SLAVE_WR_BACK_RESP        	( SLAVE_WR_BACK_RESP         ),
	.SLAVE_WR_BACK_VALID       	( SLAVE_WR_BACK_VALID        ),
	.SLAVE_WR_BACK_READY       	( SLAVE_WR_BACK_READY        ),
	.SLAVE_RD_ADDR_ID          	( SLAVE_RD_ADDR_ID           ),
	.SLAVE_RD_ADDR             	( SLAVE_RD_ADDR              ),
	.SLAVE_RD_ADDR_LEN         	( SLAVE_RD_ADDR_LEN          ),
	.SLAVE_RD_ADDR_BURST       	( SLAVE_RD_ADDR_BURST        ),
	.SLAVE_RD_ADDR_VALID       	( SLAVE_RD_ADDR_VALID        ),
	.SLAVE_RD_ADDR_READY       	( SLAVE_RD_ADDR_READY        ),
	.SLAVE_RD_BACK_ID          	( SLAVE_RD_BACK_ID           ),
	.SLAVE_RD_DATA             	( SLAVE_RD_DATA              ),
	.SLAVE_RD_DATA_RESP        	( SLAVE_RD_DATA_RESP         ),
	.SLAVE_RD_DATA_LAST        	( SLAVE_RD_DATA_LAST         ),
	.SLAVE_RD_DATA_VALID       	( SLAVE_RD_DATA_VALID        ),
	.SLAVE_RD_DATA_READY       	( SLAVE_RD_DATA_READY        )
);

// read fifo 0: HDMI in
hdmi_data_store hdmi_data_store_inst(
    .hdmi_in_clk        (hdmi_in_clk           ),
    .hdmi_in_rstn       (hdmi_in_rstn          ),
    .hdmi_in_vsync      (hdmi_in_vsync         ),
    .hdmi_in_hsync      (hdmi_in_hsync         ),
    .hdmi_in_de         (hdmi_in_de            ),
    .hdmi_in_rgb        (hdmi_in_rgb           ),
    .frame_notready     (hdmi_notready         ),
    .frame_height_width (hdmi_height_width     ),
    .rd_clk             (clk                   ),
    .rd_rstn            (rd_rstn            [0]),
    .capture_on         (rd_capture_rstn    [0]),
    .rd_addr_reset      (rd_addr_reset      [0]),
    .rd_data_burst_valid(rd_data_burst_valid[0]),
    .rd_data_burst_ready(rd_data_burst_ready[0]),
    .rd_data_burst      (rd_data_burst      [0]),
    .rd_data_valid      (rd_data_valid      [0]),
    .rd_data_ready      (rd_data_ready      [0]),
    .rd_data            (rd_data            [0]),
    .rd_data_last       (rd_data_last       [0])
);

//write fifo 0, read fifo 1: JPEG encoder (read frame from DDR, write encoded frame to DDR)
jpeg_data_store jpeg_data_store_inst(
    .clk                    (clk                    ),
    .rstn                   (wr_rstn[0] & rd_rstn[1]),
    .capture_on             (wr_capture_rstn[0] & rd_capture_rstn[1]),
    .frame_width            (jpeg_height_width[11:0]         ),
    .frame_height           (jpeg_height_width[27:16]        ),
    .add_need_frame_num     (jpeg_add_need_frame_num  ),
    .add_need_frame_pos     (jpeg_add_need_frame_pos  ),
    .total_need_frame_num   (jpeg_total_need_frame_num),

    .wr_addr_reset          (wr_addr_reset      [0]),
    .wr_data_burst_valid    (wr_data_burst_valid[0]),
    .wr_data_burst_ready    (wr_data_burst_ready[0]),
    .wr_data_burst          (wr_data_burst      [0]),
    .wr_data_valid          (wr_data_valid      [0]),
    .wr_data_ready          (wr_data_ready      [0]),
    .wr_data                (wr_data            [0]),
    .wr_data_last           (wr_data_last       [0]),

    .rd_addr_reset          (rd_addr_reset      [1]),
    .rd_data_burst_valid    (rd_data_burst_valid[1]),
    .rd_data_burst_ready    (rd_data_burst_ready[1]),
    .rd_data_burst          (rd_data_burst      [1]),
    .rd_data_valid          (rd_data_valid      [1]),
    .rd_data_ready          (rd_data_ready      [1]),
    .rd_data                (rd_data            [1]),
    .rd_data_last           (rd_data_last       [1]),

    .rd_info_valid          (jpeg_rd_info_valid  ),
    .rd_info_ready          (jpeg_rd_info_ready  ),
    .rd_info                (jpeg_rd_info        ),
    .frame_save_num         (jpeg_save_num       ),

    .Y_Quantizer            (Y_Quantizer         ),
    .CB_Quantizer           (CB_Quantizer        ),
    .CR_Quantizer           (CR_Quantizer        )
);

endmodule