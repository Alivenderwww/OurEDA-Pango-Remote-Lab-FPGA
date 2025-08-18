module hdmi_in_axi_slave(
    input wire        clk,
    input wire        rstn,

    //hdmi interface
    input  wire         hdmi_in_clk,
    input  wire         hdmi_in_rstn,
    input  wire         hdmi_in_vsync,
    input  wire         hdmi_in_hsync,
    input  wire         hdmi_in_de,
    input  wire [23:0]  hdmi_in_rgb,

    //input base and end address
    input  wire         jpeg_encoder_clk,

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

reg         capture_on;
reg         capture_rst;
reg [31:0]  start_write_addr;
reg [31:0]  end_write_addr;
reg [31:0]  capture_frame_sequence;

localparam [31:0]
    ADDR_CAPTURE_CTRL           = 32'h0000_0000, //capture control
    ADDR_START_WRITE_ADDR       = 32'h0000_0001, //start write address
    ADDR_END_WRITE_ADDR         = 32'h0000_0002, //end write
    ADDR_CAPTURE_FRAME_SEQUENCE = 32'h0000_0003, //capture frame sequence
    ADDR_ADD_NEED_FRAME_NUM     = 32'h0000_0004, //add need frame num
    ADDR_FRAME_SAVE_NUM         = 32'h0000_0005, //frame save num
    ADDR_FIFO_FRAME_INFO        = 32'h0000_0006, //fifo frame info
    ADDR_FRAME_NOTREADY         = 32'h0000_0007, //frame not ready
    ADDR_FRAME_HEIGHT_WIDTH     = 32'h0000_0008, //frame height,width
    ADDR_FRAME_DE_NUM           = 32'h0000_0009; //frame data enable num

wire hdmi_rstn_sync;
rstn_sync rstn_sync_hdmi(clk, rstn, hdmi_rstn_sync);

wire rd_clk;

assign SLAVE_CLK  = clk;
assign SLAVE_RSTN = hdmi_rstn_sync;

wire jpeg_rd_data_burst_valid, jpeg_rd_data_burst_ready;
wire [7:0] jpeg_rd_data_burst;
wire jpeg_rd_data_valid, jpeg_rd_data_ready;
wire [31:0] jpeg_rd_data;

wire jpeg_rd_info_valid;
wire jpeg_rd_info_ready;
wire [31:0] jpeg_rd_info;
wire [31:0] frame_save_num;

wire frame_notready;
wire [31:0] frame_height_width;
wire [31:0] frame_de_num;

reg [6:0] add_need_frame;
reg       add_need_frame_d0, add_need_frame_d1;
wire      add_need_frame_pos;
reg [31:0] add_need_frame_num;
wire [31:0] total_need_frame_num;

axi_master_write_dma u_axi_master_write_dma(
	.START_WRITE_ADDR     	( start_write_addr        ),
	.END_WRITE_ADDR       	( end_write_addr          ),
	.clk                  	( clk                     ),
	.rstn                 	( hdmi_rstn_sync          ),
    .rd_clk             	( rd_clk                  ),
	.rd_capture_on        	( capture_on              ),
	.rd_capture_rst       	( capture_rst             ),
    .rd_data_burst_valid    ( jpeg_rd_data_burst_valid),
    .rd_data_burst_ready    ( jpeg_rd_data_burst_ready),
    .rd_data_burst          ( jpeg_rd_data_burst      ),
	.rd_data_ready        	( jpeg_rd_data_ready    ),
	.rd_data_valid        	( jpeg_rd_data_valid    ),
	.rd_data              	( jpeg_rd_data          ),
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

//_________________写___通___道_________________//
reg [ 3:0] wr_addr_id;
reg [31:0] wr_addr;
reg [ 3:0] wr_addr_burst;
reg        wr_transcript_error, wr_transcript_error_reg;
//ANALYZER作为SLAVE不接收WR_ADDR_LEN，其DATA线的结束以WR_DATA_LAST为参考。
reg [ 1:0] cu_wrchannel_st, nt_wrchannel_st;
localparam ST_WR_IDLE = 2'b00, //写通道空闲
           ST_WR_DATA = 2'b01, //地址线握手成功，数据线通道开启
           ST_WR_RESP = 2'b10; //写响应
//_________________读___通___道_________________//
reg [ 3:0] rd_addr_id;
reg [31:0] rd_addr;
reg [ 7:0] rd_addr_len;
reg [ 3:0] rd_addr_burst;
reg [ 7:0] rd_data_trans_num;
reg        rd_transcript_error, rd_transcript_error_reg;
reg [ 1:0] cu_rdchannel_st, nt_rdchannel_st;
localparam ST_RD_IDLE = 2'b00, //发送完LAST和RESP，读通道空闲
           ST_RD_DATA = 2'b01; //地址线握手成功，数据线通道开启

//_______________________________________________________________________________//
always @(*) begin
    case (cu_wrchannel_st)
        ST_WR_IDLE: nt_wrchannel_st = (SLAVE_WR_ADDR_VALID && SLAVE_WR_ADDR_READY)?(ST_WR_DATA):(ST_WR_IDLE);
        ST_WR_DATA: nt_wrchannel_st = (SLAVE_WR_DATA_VALID && SLAVE_WR_DATA_READY && SLAVE_WR_DATA_LAST)?(ST_WR_RESP):(ST_WR_DATA);
        ST_WR_RESP: nt_wrchannel_st = (SLAVE_WR_BACK_VALID && SLAVE_WR_BACK_READY)?(ST_WR_IDLE):(ST_WR_RESP);
        default   : nt_wrchannel_st = ST_WR_IDLE;
    endcase
end
always @(posedge clk or negedge hdmi_rstn_sync) begin
    if(~hdmi_rstn_sync) cu_wrchannel_st <= ST_WR_IDLE;
    else cu_wrchannel_st <= nt_wrchannel_st;
end
assign SLAVE_WR_ADDR_READY = (hdmi_rstn_sync) && (cu_wrchannel_st == ST_WR_IDLE);
assign SLAVE_WR_BACK_VALID = (hdmi_rstn_sync) && (cu_wrchannel_st == ST_WR_RESP);
assign SLAVE_WR_BACK_RESP  = ((hdmi_rstn_sync) && ((~wr_transcript_error) && (~wr_transcript_error_reg)))?(2'b00):(2'b10);
assign SLAVE_WR_BACK_ID    = wr_addr_id;
always @(posedge clk or negedge hdmi_rstn_sync) begin
    if(~hdmi_rstn_sync) begin
        wr_addr_id    <= 0;
        wr_addr_burst <= 0;
    end else if(SLAVE_WR_ADDR_VALID && SLAVE_WR_ADDR_READY) begin
        wr_addr_id    <= SLAVE_WR_ADDR_ID;
        wr_addr_burst <= SLAVE_WR_ADDR_BURST;
    end else begin
        wr_addr_id    <= wr_addr_id;
        wr_addr_burst <= wr_addr_burst;
    end
end
always @(posedge clk or negedge hdmi_rstn_sync) begin
    if(~hdmi_rstn_sync) wr_addr <= 0;
    else if(SLAVE_WR_ADDR_VALID && SLAVE_WR_ADDR_READY) wr_addr <= SLAVE_WR_ADDR;
    else if((wr_addr_burst == 2'b01) && SLAVE_WR_DATA_VALID && SLAVE_WR_DATA_READY) wr_addr <= wr_addr + 1;
    else wr_addr <= wr_addr;
end
always @(*) begin
    if((~hdmi_rstn_sync) || (cu_wrchannel_st == ST_WR_IDLE) || (cu_wrchannel_st == ST_WR_RESP)) wr_transcript_error = 0;
    else if((wr_addr_burst == 2'b10) || (wr_addr_burst == 2'b11)) wr_transcript_error = 1;
    else wr_transcript_error = 0;
end
always @(posedge clk or negedge hdmi_rstn_sync) begin
    if((~hdmi_rstn_sync) || (cu_wrchannel_st == ST_WR_IDLE)) wr_transcript_error_reg <= 0;
    else wr_transcript_error_reg <= (wr_transcript_error)?(1):(wr_transcript_error_reg);
end

//_______________________________________________________________________________//
always @(*) begin
    case (cu_rdchannel_st)
        ST_RD_IDLE: nt_rdchannel_st = (SLAVE_RD_ADDR_VALID && SLAVE_RD_ADDR_READY)?(ST_RD_DATA):(ST_RD_IDLE);
        ST_RD_DATA: nt_rdchannel_st = (SLAVE_RD_DATA_VALID && SLAVE_RD_DATA_READY && SLAVE_RD_DATA_LAST)?(ST_RD_IDLE):(ST_RD_DATA);
        default   : nt_rdchannel_st = ST_RD_IDLE;
    endcase
end
always @(posedge clk or negedge hdmi_rstn_sync)begin
    if(~hdmi_rstn_sync) cu_rdchannel_st <= ST_RD_IDLE;
    else cu_rdchannel_st <= nt_rdchannel_st;
end
assign SLAVE_RD_ADDR_READY = (hdmi_rstn_sync) && (cu_rdchannel_st == ST_RD_IDLE);
always @(posedge clk or negedge hdmi_rstn_sync) begin
    if(~hdmi_rstn_sync) begin
        rd_addr_id    <= 0;
        rd_addr_burst <= 0;
        rd_addr_len   <= 0;
    end else if(SLAVE_RD_ADDR_VALID && SLAVE_RD_ADDR_READY) begin
        rd_addr_id    <= SLAVE_RD_ADDR_ID;
        rd_addr_burst <= SLAVE_RD_ADDR_BURST;
        rd_addr_len   <= SLAVE_RD_ADDR_LEN;
    end else begin
        rd_addr_id    <= rd_addr_id;
        rd_addr_burst <= rd_addr_burst;
        rd_addr_len   <= rd_addr_len;
    end
end
always @(posedge clk or negedge hdmi_rstn_sync) begin
    if(~hdmi_rstn_sync) rd_addr <= 0;
    else if(SLAVE_RD_ADDR_VALID && SLAVE_RD_ADDR_READY) rd_addr <= SLAVE_RD_ADDR;
    else if((rd_addr_burst == 2'b01) && SLAVE_RD_DATA_VALID && SLAVE_RD_DATA_READY) rd_addr <= rd_addr + 1;
    else rd_addr <= rd_addr;
end
always @(posedge clk or negedge hdmi_rstn_sync) begin
    if(~hdmi_rstn_sync || (cu_rdchannel_st == ST_RD_IDLE)) rd_data_trans_num <= 0;
    else if(SLAVE_RD_DATA_VALID && SLAVE_RD_DATA_READY) rd_data_trans_num <= rd_data_trans_num + 1;
    else rd_data_trans_num <= rd_data_trans_num;
end
assign SLAVE_RD_DATA_LAST = (hdmi_rstn_sync) && (cu_rdchannel_st == ST_RD_DATA) && (SLAVE_RD_DATA_VALID) && (rd_data_trans_num == rd_addr_len);
assign SLAVE_RD_BACK_ID = rd_addr_id;
assign SLAVE_RD_DATA_RESP  = ((hdmi_rstn_sync) && (cu_rdchannel_st == ST_RD_DATA) && ((~rd_transcript_error) && (~rd_transcript_error_reg)))?(2'b00):(2'b10);

always @(*) begin
    //写数据READY选通
    if(cu_wrchannel_st == ST_WR_DATA) begin
             SLAVE_WR_DATA_READY = 1;
    end else SLAVE_WR_DATA_READY = 0;
    //读数据VALID选通
    if(cu_rdchannel_st == ST_RD_DATA) case (rd_addr)
        ADDR_FIFO_FRAME_INFO: SLAVE_RD_DATA_VALID = jpeg_rd_info_ready;
        default             : SLAVE_RD_DATA_VALID = 1;
    endcase
    else SLAVE_RD_DATA_VALID = 0;
    //读数据DATA选通
    if(cu_rdchannel_st == ST_RD_DATA) begin
        case(rd_addr)
            ADDR_CAPTURE_CTRL          : SLAVE_RD_DATA = {23'b0, capture_rst, 7'b0, capture_on};
            ADDR_START_WRITE_ADDR      : SLAVE_RD_DATA = start_write_addr;
            ADDR_END_WRITE_ADDR        : SLAVE_RD_DATA = end_write_addr;
            ADDR_CAPTURE_FRAME_SEQUENCE: SLAVE_RD_DATA = capture_frame_sequence;
            ADDR_ADD_NEED_FRAME_NUM    : SLAVE_RD_DATA = total_need_frame_num;
            ADDR_FRAME_SAVE_NUM        : SLAVE_RD_DATA = frame_save_num;
            ADDR_FIFO_FRAME_INFO       : SLAVE_RD_DATA = jpeg_rd_info;
            ADDR_FRAME_NOTREADY        : SLAVE_RD_DATA = {31'b0, frame_notready};
            ADDR_FRAME_HEIGHT_WIDTH    : SLAVE_RD_DATA = frame_height_width;
            ADDR_FRAME_DE_NUM          : SLAVE_RD_DATA = frame_de_num;
            default                    : SLAVE_RD_DATA = 32'hFFFFFFFF; //ERROR，直接跳过默认为全1
        endcase
    end else SLAVE_RD_DATA = 0;
end

always @(*) begin
    if((~hdmi_rstn_sync) || (cu_rdchannel_st == ST_RD_IDLE)) rd_transcript_error = 0;
    else if((rd_addr_burst == 2'b10) || (rd_addr_burst == 2'b11)) rd_transcript_error = 1;
    else rd_transcript_error = 0;
end
always @(posedge clk or negedge hdmi_rstn_sync) begin
    if((~hdmi_rstn_sync) || (cu_rdchannel_st == ST_RD_IDLE)) rd_transcript_error_reg = 0;
    else rd_transcript_error_reg = (rd_transcript_error)?(1):(rd_transcript_error_reg);
end

always @(posedge clk or negedge hdmi_rstn_sync) begin
    if(~hdmi_rstn_sync) begin
        capture_on <= 0;
        capture_rst <= 0;
        start_write_addr <= 0;
        end_write_addr <= 0;
        capture_frame_sequence <= 0;
        add_need_frame_num <= 0;
        add_need_frame <= 0;
    end else if(SLAVE_WR_DATA_VALID && SLAVE_WR_DATA_READY)begin
        case(wr_addr)
            ADDR_CAPTURE_CTRL: begin
                capture_on  <= SLAVE_WR_DATA[0];
                capture_rst <= SLAVE_WR_DATA[8];
            end
            ADDR_START_WRITE_ADDR      : start_write_addr       <= SLAVE_WR_DATA;
            ADDR_END_WRITE_ADDR        : end_write_addr         <= SLAVE_WR_DATA;
            ADDR_CAPTURE_FRAME_SEQUENCE: capture_frame_sequence <= SLAVE_WR_DATA;
            ADDR_ADD_NEED_FRAME_NUM    : begin
                add_need_frame_num     <= SLAVE_WR_DATA;
                add_need_frame         <= 1;
            end
            // ADDR_FRAME_SAVE_NUM     : read only
            // ADDR_FIFO_FRAME_INFO    : read only
            // ADDR_FRAME_NOTREADY     : read only
            // ADDR_FRAME_HEIGHT_WIDTH : read only
            // ADDR_FRAME_DE_NUM       : read only
            default: begin
                add_need_frame_num <= add_need_frame_num;
                add_need_frame <= (add_need_frame != 0)?(add_need_frame + 1):(0);
            end
        endcase
    end else begin
        add_need_frame_num <= add_need_frame_num;
        add_need_frame <= (add_need_frame != 0)?(add_need_frame + 1):(0);
    end
end

always @(posedge hdmi_in_clk or negedge hdmi_rstn_sync) begin
    if(~hdmi_rstn_sync)begin
        add_need_frame_d0 <= 0;
        add_need_frame_d1 <= 0;
    end else begin
        add_need_frame_d0 <= |add_need_frame;
        add_need_frame_d1 <= add_need_frame_d0;
    end
end
assign add_need_frame_pos = (add_need_frame_d0 && ~add_need_frame_d1);

assign jpeg_rd_info_valid = (cu_rdchannel_st == ST_RD_DATA) && (rd_addr == ADDR_FIFO_FRAME_INFO) && (SLAVE_RD_DATA_VALID);
hdmi_data_store u_hdmi_data_store(
	.clk          	       ( rd_clk                  ),
	.rstn         	       ( hdmi_rstn_sync          ),
    .hdmi_in_clk           ( hdmi_in_clk             ),
    .hdmi_in_rstn          ( hdmi_in_rstn            ),
    .hdmi_in_vsync         ( hdmi_in_vsync           ),
    .hdmi_in_hsync         ( hdmi_in_hsync           ),
    .hdmi_in_de            ( hdmi_in_de              ),
    .hdmi_in_rgb           ( hdmi_in_rgb             ),

    .jpeg_encoder_clk      ( jpeg_encoder_clk        ),
    .capture_on  	       ( capture_on              ),
    .frame_notready        ( frame_notready          ),
    .frame_height_width    ( frame_height_width      ),
    .frame_de_num          ( frame_de_num            ),

    .add_need_frame_num    ( add_need_frame_num      ),
    .add_need_frame_pos    ( add_need_frame_pos      ),
    .total_need_frame_num  ( total_need_frame_num          ),
    .capture_frame_sequence( capture_frame_sequence  ),

    .rd_data_burst_valid   ( jpeg_rd_data_burst_valid),
    .rd_data_burst_ready   ( jpeg_rd_data_burst_ready),
    .rd_data_burst         ( jpeg_rd_data_burst      ),
	.rd_data_valid         ( jpeg_rd_data_valid      ),
    .rd_data_ready         ( jpeg_rd_data_ready      ),
	.rd_data 	           ( jpeg_rd_data 	         ),

    .rd_info_valid         ( jpeg_rd_info_valid      ),
    .rd_info_ready         ( jpeg_rd_info_ready      ),
    .rd_info               ( jpeg_rd_info            ),
    .frame_save_num        ( frame_save_num          )
);


endmodule //moduleName
