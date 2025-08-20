module jpeg_data_store (
    input  wire        clk,
    input  wire        rstn,
    input  wire        capture_on,
    input  wire [11:0] frame_width,
    input  wire [11:0] frame_height,
    input  wire [31:0] add_need_frame_num,
    input  wire        add_need_frame_pos,
    output  reg [31:0] total_need_frame_num,
    //in data
    output wire        wr_data_burst_valid,
    input  wire        wr_data_burst_ready,
    output wire        wr_addr_reset,
    output  reg [ 7:0] wr_data_burst,
    input  wire        wr_data_valid,
    output wire        wr_data_ready,
    input  wire [31:0] wr_data,
    input  wire        wr_data_last,

    output wire        rd_data_burst_valid,
    input  wire        rd_data_burst_ready,
    output wire        rd_addr_reset,
    output  reg [ 7:0] rd_data_burst,
    output wire        rd_data_valid,
    input  wire        rd_data_ready,
    output wire [31:0] rd_data,
    output wire        rd_data_last,

    input  wire        rd_info_valid,
    output wire        rd_info_ready,
    output wire [31:0] rd_info,
    output wire [31:0] frame_save_num,
    
    output wire [13*8*8 - 1:0] Y_Quantizer,
    output wire [13*8*8 - 1:0] CB_Quantizer,
    output wire [13*8*8 - 1:0] CR_Quantizer
);

// outports wire
wire [31:0] 	bitstream_size; // size of the JPEG bitstream in 4bytes!
reg  [31:0]     bitstream_size_reg;
wire [31:0] 	JPEG_bitstream;
wire        	jpeg_enoder_data_ready;
wire [4:0]  	end_of_file_bitstream_count;
wire        	eof_data_partial_ready;

localparam [7:0] JPEG_FIFO_TRHSHOLD_LEVEL = 255; // 260*32 = 8320 bits, 1040 bytes, 1.04 KB

wire fifo_wr_en;
wire fifo_rd_en;
wire fifo_rst;
wire rd_empty;
wire [12:0] rd_water_level;
wire fifo_wr_full;
wire jpeg_encode_bitstream_fifo_almost_full;

wire fifo_wr_info_en;
wire fifo_rd_info_en;
wire rd_info_empty;

reg [7:0] rd_data_burst_count;

reg [1:0] cu_fifo_rd_st, nt_fifo_rd_st;
reg [31:0] bitstream_trans_size;
reg frame_need_trans_all;
localparam
    FIFO_RD_ST_IDLE        = 2'b00,
    FIFO_RD_ST_TRANS_BURST = 2'b01,
    FIFO_RD_ST_TRANS_DATA  = 2'b10,
    FIFO_RD_ST_FRAME_OVER  = 2'b11;


reg [1:0] cu_st_store, nt_st_store;
localparam ST_IDLE  = 2'b00, 
           ST_REST  = 2'b01,
           ST_TRANS = 2'b10;

always @(posedge clk or negedge rstn) begin
    if(~rstn) cu_st_store <= ST_IDLE;
    else cu_st_store <= nt_st_store;
end
always @(*) begin
    if(~capture_on) nt_st_store = ST_IDLE;
    else case (cu_st_store)
        ST_IDLE : nt_st_store = (capture_on)?(ST_REST):(ST_IDLE);
        ST_REST : nt_st_store = (total_need_frame_num != 0)?(ST_TRANS):(ST_REST);
        ST_TRANS: nt_st_store = ((cu_fifo_rd_st == FIFO_RD_ST_FRAME_OVER) && (nt_fifo_rd_st == FIFO_RD_ST_IDLE))?(ST_REST):(ST_TRANS);
        default : nt_st_store = ST_IDLE;
    endcase
end
always @(posedge clk or negedge rstn) begin
    if(~rstn) total_need_frame_num <= 0;
    else if(~capture_on) total_need_frame_num <= 0;
    else if(cu_st_store == ST_TRANS && nt_st_store == ST_REST) begin
        if(add_need_frame_pos)      total_need_frame_num <= total_need_frame_num + add_need_frame_num - 1;
        else                        total_need_frame_num <= total_need_frame_num - 1;
    end else if(add_need_frame_pos) total_need_frame_num <= total_need_frame_num + add_need_frame_num;
    else                            total_need_frame_num <= total_need_frame_num;
end

wire jpeg_encoder_in_frame_done = (cu_st_store == ST_REST) && (nt_st_store == ST_TRANS);
assign wr_addr_reset = 0;
jpeg_encoder_top u_jpeg_encoder_top(
	.clk                         	( clk                          ),
	.rstn                        	( (capture_on)                 ),
	.frame_done                  	( jpeg_encoder_in_frame_done   ),
	.pixel_x                     	( frame_width                  ),
	.pixel_y                     	( frame_height                 ),
    .jpeg_encode_bitstream_fifo_almost_full ( jpeg_encode_bitstream_fifo_almost_full ),

    .wr_data_burst_valid            (wr_data_burst_valid           ),
    .wr_data_burst_ready            (wr_data_burst_ready           ),
    .wr_data_burst                  (wr_data_burst                 ),
    .wr_data_valid                  (wr_data_valid                 ),
    .wr_data_ready                  (wr_data_ready                 ),
    .wr_data                        (wr_data                       ),
    .wr_data_last                   (wr_data_last                  ),
    
    .bitstream_size               	( bitstream_size               ),
	.JPEG_bitstream              	( JPEG_bitstream               ),
	.jpeg_enoder_data_ready      	( jpeg_enoder_data_ready       ),
	.end_of_file_bitstream_count 	( end_of_file_bitstream_count  ),
	.eof_data_partial_ready      	( eof_data_partial_ready       ),
    .Y_Quantizer                    ( Y_Quantizer                  ),
    .CB_Quantizer                   ( CB_Quantizer                 ),
    .CR_Quantizer                   ( CR_Quantizer                 )
);

always @(posedge clk or negedge rstn) begin
    if(~rstn) bitstream_size_reg <= 0;
    else if(eof_data_partial_ready) bitstream_size_reg <= bitstream_size;
    else bitstream_size_reg <= bitstream_size_reg;
end

reg fifo_rd_data_valid;
always @(posedge clk or negedge rstn) begin
    if(~rstn) fifo_rd_data_valid <= 1'b0;
    else if(~capture_on) fifo_rd_data_valid <= 1'b0;
    else if(rd_data_valid && rd_data_ready && rd_empty && fifo_rd_data_valid) fifo_rd_data_valid <= 1'b0;
    else if(fifo_rd_en && (~rd_empty) && (~fifo_rd_data_valid)) fifo_rd_data_valid <= 1'b1;
    else fifo_rd_data_valid <= fifo_rd_data_valid;
end

assign fifo_rst = (~rstn) || (~capture_on);
assign fifo_wr_en = jpeg_enoder_data_ready | eof_data_partial_ready;
assign fifo_rd_en = (~rd_empty) && ((rd_data_valid && rd_data_ready) || (~fifo_rd_data_valid));

jpeg_encode_bitstream_fifo u_jpeg_encode_bitstream_fifo(
    .clk            ( clk             ),
    .rst            ( fifo_rst        ),

    .wr_en          ( fifo_wr_en      ),
    .wr_data        ( JPEG_bitstream  ),
    .almost_full    ( jpeg_encode_bitstream_fifo_almost_full    ),
    .wr_full        ( fifo_wr_full    ),

    .rd_en          ( fifo_rd_en      ),
    .rd_data        ( rd_data         ),
    .rd_empty       ( rd_empty        ),
    .rd_water_level ( rd_water_level  )
);

always @(posedge clk or negedge rstn) begin
    if(~rstn) frame_need_trans_all <= 0;
    else if(frame_need_trans_all == 0) frame_need_trans_all <= eof_data_partial_ready;
    else if(cu_fifo_rd_st == FIFO_RD_ST_FRAME_OVER) frame_need_trans_all <= 0;
    else frame_need_trans_all <= frame_need_trans_all;
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) bitstream_trans_size <= 0;
    else if(cu_fifo_rd_st == FIFO_RD_ST_FRAME_OVER) bitstream_trans_size <= 0;
    else if(cu_fifo_rd_st == FIFO_RD_ST_TRANS_DATA && rd_data_valid && rd_data_ready)
         bitstream_trans_size <= bitstream_trans_size + 1;
    else bitstream_trans_size <= bitstream_trans_size;
end
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
             rd_data_burst <= 0;
    end else if((cu_fifo_rd_st == FIFO_RD_ST_IDLE) && (nt_fifo_rd_st == FIFO_RD_ST_TRANS_BURST)) begin
        if(rd_water_level + fifo_rd_data_valid >= JPEG_FIFO_TRHSHOLD_LEVEL)
             rd_data_burst <= 8'hff; // burst size is 255
        else if(frame_need_trans_all && fifo_rd_data_valid)
             rd_data_burst <= 0;
        else rd_data_burst <= rd_data_burst;
    end else rd_data_burst <= rd_data_burst;
end
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
             rd_data_burst_count <= 0;
    end else if(cu_fifo_rd_st == FIFO_RD_ST_TRANS_BURST) begin
             rd_data_burst_count <= rd_data_burst;
    end else if(cu_fifo_rd_st == FIFO_RD_ST_TRANS_DATA && rd_data_valid && rd_data_ready) begin
             rd_data_burst_count <= (rd_data_last) ? (rd_data_burst_count) : (rd_data_burst_count - 1);
    end else rd_data_burst_count <= rd_data_burst_count;
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) cu_fifo_rd_st <= FIFO_RD_ST_IDLE;
    else cu_fifo_rd_st <= nt_fifo_rd_st;
end
always @(*) begin
    if(~capture_on) nt_fifo_rd_st = FIFO_RD_ST_IDLE;
    else case (cu_fifo_rd_st)
        FIFO_RD_ST_IDLE        : nt_fifo_rd_st = ((rd_water_level + fifo_rd_data_valid >= JPEG_FIFO_TRHSHOLD_LEVEL) || (frame_need_trans_all && (fifo_rd_data_valid)))?(FIFO_RD_ST_TRANS_BURST):(FIFO_RD_ST_IDLE);
        FIFO_RD_ST_TRANS_BURST : nt_fifo_rd_st = (rd_data_burst_valid && rd_data_burst_ready)?(FIFO_RD_ST_TRANS_DATA):(FIFO_RD_ST_TRANS_BURST);
        FIFO_RD_ST_TRANS_DATA  : nt_fifo_rd_st = (rd_data_valid && rd_data_ready && rd_data_last)?((frame_need_trans_all && (bitstream_trans_size == bitstream_size_reg - 1))?(FIFO_RD_ST_FRAME_OVER):(FIFO_RD_ST_IDLE)):(FIFO_RD_ST_TRANS_DATA);
        FIFO_RD_ST_FRAME_OVER  : nt_fifo_rd_st = (frame_need_trans_all == 0)?(FIFO_RD_ST_IDLE):(FIFO_RD_ST_FRAME_OVER);
    endcase
end
assign rd_data_burst_valid = (cu_fifo_rd_st == FIFO_RD_ST_TRANS_BURST);
// assign rd_addr_reset = (cu_fifo_rd_st == FIFO_RD_ST_FRAME_OVER) && (nt_fifo_rd_st == FIFO_RD_ST_IDLE);
assign rd_addr_reset = 0;
assign rd_data_last = (cu_fifo_rd_st == FIFO_RD_ST_TRANS_DATA) && (rd_data_burst_count == 0);
assign rd_data_valid = (cu_fifo_rd_st == FIFO_RD_ST_TRANS_DATA) && (fifo_rd_data_valid);

reg fifo_rd_info_valid;
always @(posedge clk or negedge rstn) begin
    if(~rstn) fifo_rd_info_valid <= 1'b0;
    else if(~capture_on) fifo_rd_info_valid <= 1'b0;
    else if(rd_info_valid && rd_info_ready && rd_info_empty && fifo_rd_info_valid) fifo_rd_info_valid <= 1'b0;
    else if(fifo_rd_info_en && (~rd_info_empty) && (~fifo_rd_info_valid)) fifo_rd_info_valid <= 1'b1;
    else fifo_rd_info_valid <= fifo_rd_info_valid;
end

reg eof_data_partial_ready_d;
always @(posedge clk or negedge rstn) begin
    if(~rstn) eof_data_partial_ready_d <= 1'b0;
    else eof_data_partial_ready_d <= eof_data_partial_ready;
end
assign fifo_info_rst = (~rstn) || (~capture_on);
assign fifo_wr_info_en = eof_data_partial_ready_d;
assign fifo_rd_info_en = (~rd_info_empty) && ((rd_info_valid && rd_info_ready) || (~fifo_rd_info_valid));
assign rd_info_ready = fifo_rd_info_valid;
wire [9:0] frame_save_num_inter;
assign frame_save_num = frame_save_num_inter+ fifo_rd_info_valid;
//8'b0,32,12,12
wire fifo_wr_info_full;
jpeg_encode_info_fifo u_jpeg_encode_info_fifo(
    .clk            ( clk                  ),
    .rst            ( fifo_info_rst        ),

    .wr_en          ( fifo_wr_info_en      ),
    .wr_data        ( bitstream_size_reg   ),
    .wr_water_level ( frame_save_num_inter ),
    .wr_full        ( fifo_wr_info_full    ),

    .rd_en          ( fifo_rd_info_en      ),
    .rd_data        ( rd_info              ),
    .rd_empty       ( rd_info_empty        )
);

endmodule