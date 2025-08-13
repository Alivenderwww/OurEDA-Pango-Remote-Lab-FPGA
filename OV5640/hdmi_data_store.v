module hdmi_data_store (
    input wire        clk,
    input wire        rstn,

    //camera interface (no need iic)
    input  wire        hdmi_in_clk,
    input  wire        hdmi_in_rstn,
    input  wire        hdmi_in_href,
    input  wire        hdmi_in_vsync,
    input  wire [23:0] hdmi_in_rgb,

    input  wire        jpeg_encoder_clk,
    input  wire        capture_on,
    output wire        frame_notready,

    input  wire [31:0] add_need_frame_num,
    input  wire        add_need_frame,
    input  wire [31:0] capture_frame_sequence,

    output wire        rd_data_burst_valid,
    input  wire        rd_data_burst_ready,
    output  reg [ 7:0] rd_data_burst,
    input  wire        rd_data_valid,
    output wire        rd_data_ready,
    output wire [31:0] rd_data,

    input  wire        rd_info_valid,
    output wire        rd_info_ready,
    output wire [31:0] rd_info,
    output wire [31:0] frame_save_num
);

reg if_this_frame_capture;
reg [31:0] total_need_frame_num;

// outports wire
wire [11:0] 	pixel_x_out;
wire [11:0] 	pixel_y_out;
wire [31:0] 	bitstream_size; // size of the JPEG bitstream in 4bytes!
reg  [31:0]     bitstream_size_reg;
wire [31:0] 	JPEG_bitstream;
wire        	jpeg_enoder_data_ready;
wire [4:0]  	end_of_file_bitstream_count;
wire        	eof_data_partial_ready;

wire fifo_wr_rst, fifo_wr_en;
wire fifo_rd_rst, fifo_rd_en;
wire rd_empty;
wire [12:0] rd_water_level;

wire fifo_wr_info_rst, fifo_wr_info_en;
wire fifo_rd_info_rst, fifo_rd_info_en;
wire rd_info_empty;

reg HDMI_VSYNC_d1, HDMI_VSYNC_d2;
reg HDMI_HREF_d1, HDMI_HREF_d2;
reg [23:0] HDMI_DATA_d1;
reg [11:0] camera_hcount, camera_vcount;
reg [11:0] camera_v, camera_h;
reg [3:0] stage_width_cnt, stage_height_cnt; //帧计数
// wire frame_notready = 0;
assign frame_notready = (stage_height_cnt <= 4'd1) || (stage_width_cnt <= 4'd1);

wire HDMI_VSYNC_pos = (HDMI_VSYNC_d1 == 1'b1 && HDMI_VSYNC_d2 == 1'b0);
wire HDMI_VSYNC_neg = (HDMI_VSYNC_d1 == 1'b0 && HDMI_VSYNC_d2 == 1'b1);
wire HDMI_HREF_pos  = (HDMI_HREF_d1 == 1'b1 && HDMI_HREF_d2 == 1'b0);
wire HDMI_HREF_neg  = (HDMI_HREF_d1 == 1'b0 && HDMI_HREF_d2 == 1'b1);
always @(posedge hdmi_in_clk or negedge hdmi_in_rstn) begin
    if(~hdmi_in_rstn) begin
        HDMI_VSYNC_d1 <= 1'b0;
        HDMI_VSYNC_d2 <= 1'b0;
        HDMI_HREF_d1 <= 1'b0;
        HDMI_HREF_d2 <= 1'b0;
        HDMI_DATA_d1 <= 24'h00;
    end
    else begin
        HDMI_VSYNC_d1 <= hdmi_in_vsync;
        HDMI_VSYNC_d2 <= HDMI_VSYNC_d1;
        HDMI_HREF_d1  <= hdmi_in_href;
        HDMI_HREF_d2  <= HDMI_HREF_d1;
        HDMI_DATA_d1  <= hdmi_in_rgb;
        // if(HDMI_VSYNC_neg) HDMI_DATA_d1 <= 0;
        // else HDMI_DATA_d1 <= (~HDMI_VSYNC)&&(HDMI_HREF)?(HDMI_DATA_d1+1):(HDMI_DATA_d1);
    end
end

always @(posedge hdmi_in_clk or negedge hdmi_in_rstn) begin
    if(~hdmi_in_rstn) camera_hcount <= 0;
    else if(HDMI_VSYNC_neg || HDMI_HREF_neg) camera_hcount <= 0;
    else if(HDMI_HREF_d1) camera_hcount <= camera_hcount + 1;
    else camera_hcount <= camera_hcount;
end
always @(posedge hdmi_in_clk or negedge hdmi_in_rstn) begin
    if(~hdmi_in_rstn) camera_h <= 0;
    else if(HDMI_HREF_neg) camera_h <= camera_hcount;
    else camera_h <= camera_h;
end
always @(posedge hdmi_in_clk or negedge hdmi_in_rstn) begin
    if(~hdmi_in_rstn) camera_vcount <= 0;
    else if(HDMI_VSYNC_neg) camera_vcount <= 0;
    else if(HDMI_HREF_neg) camera_vcount <= camera_vcount + 1;
    else camera_vcount <= camera_vcount;
end
always @(posedge hdmi_in_clk or negedge hdmi_in_rstn) begin
    if(~hdmi_in_rstn) camera_v <= 0;
    else if(HDMI_VSYNC_neg) camera_v <= camera_vcount;
    else camera_v <= camera_v;
end

reg [1:0] cu_st_store, nt_st_store;
localparam ST_IDLE = 2'b00, 
           ST_STORE = 2'b01;
always @(posedge hdmi_in_clk or negedge hdmi_in_rstn) begin
    if(~hdmi_in_rstn) cu_st_store <= ST_IDLE;
    else cu_st_store <= nt_st_store;
end
always @(*) begin
    if(((~capture_on) && HDMI_VSYNC_neg) || (frame_notready)) nt_st_store = ST_IDLE;
    else case (cu_st_store)
        ST_IDLE : nt_st_store = (capture_on && HDMI_VSYNC_neg)?(ST_STORE):(ST_IDLE);
        ST_STORE: nt_st_store = ST_STORE;
        default : nt_st_store = ST_IDLE;
    endcase
end
always @(posedge hdmi_in_clk or negedge hdmi_in_rstn) begin
    if(~hdmi_in_rstn) stage_width_cnt <= 0;
    else if(HDMI_VSYNC_neg) begin
        if((camera_vcount + 0) == camera_v) begin
            if(stage_width_cnt < 4'd15)
                 stage_width_cnt <= stage_width_cnt + 1;
            else stage_width_cnt <= 4'd15;
        end else stage_width_cnt <= 0;
    end else     stage_width_cnt <= stage_width_cnt;
end
always @(posedge hdmi_in_clk or negedge hdmi_in_rstn) begin
    if(~hdmi_in_rstn) stage_height_cnt <= 0;
    else if(HDMI_HREF_neg) begin
        if((camera_hcount + 0) == camera_h) begin
            if(stage_height_cnt < 4'd15)
                 stage_height_cnt <= stage_height_cnt + 1;
            else stage_height_cnt <= 4'd15;
        end else stage_height_cnt <= 0;
    end else     stage_height_cnt <= stage_height_cnt;
end

//total_need_frame_num, if_this_frame_capture
//hdmi_vsync_neg_for_clk_d0
reg [4:0] frame_sequence;
reg hdmi_vsync_for_clk_d0, hdmi_vsync_for_clk_d1;
wire hdmi_vsync_neg_for_clk = (hdmi_vsync_for_clk_d0 == 1'b0 && hdmi_vsync_for_clk_d1 == 1'b1);
always @(posedge clk) begin
    hdmi_vsync_for_clk_d0 <= hdmi_in_vsync;
    hdmi_vsync_for_clk_d1 <= hdmi_vsync_for_clk_d0;
end
always @(posedge clk or negedge rstn) begin
   if(~rstn) frame_sequence <= 0;
   else if(hdmi_vsync_neg_for_clk) frame_sequence <= frame_sequence + 1;
   else frame_sequence <= frame_sequence;
end
always @(posedge clk or negedge rstn) begin
   if(~rstn) if_this_frame_capture <= 0;
   else if(hdmi_vsync_neg_for_clk && (nt_st_store == ST_STORE)) case (frame_sequence)
        0: if_this_frame_capture <= capture_frame_sequence[ 0]; 1: if_this_frame_capture <= capture_frame_sequence[ 1];
        2: if_this_frame_capture <= capture_frame_sequence[ 2]; 3: if_this_frame_capture <= capture_frame_sequence[ 3];
        4: if_this_frame_capture <= capture_frame_sequence[ 4]; 5: if_this_frame_capture <= capture_frame_sequence[ 5];
        6: if_this_frame_capture <= capture_frame_sequence[ 6]; 7: if_this_frame_capture <= capture_frame_sequence[ 7];
        8: if_this_frame_capture <= capture_frame_sequence[ 8]; 9: if_this_frame_capture <= capture_frame_sequence[ 9];
       10: if_this_frame_capture <= capture_frame_sequence[10];11: if_this_frame_capture <= capture_frame_sequence[11];
       12: if_this_frame_capture <= capture_frame_sequence[12];13: if_this_frame_capture <= capture_frame_sequence[13];
       14: if_this_frame_capture <= capture_frame_sequence[14];15: if_this_frame_capture <= capture_frame_sequence[15];
       16: if_this_frame_capture <= capture_frame_sequence[16];17: if_this_frame_capture <= capture_frame_sequence[17];
       18: if_this_frame_capture <= capture_frame_sequence[18];19: if_this_frame_capture <= capture_frame_sequence[19];
       20: if_this_frame_capture <= capture_frame_sequence[20];21: if_this_frame_capture <= capture_frame_sequence[21];
       22: if_this_frame_capture <= capture_frame_sequence[22];23: if_this_frame_capture <= capture_frame_sequence[23];
       24: if_this_frame_capture <= capture_frame_sequence[24];25: if_this_frame_capture <= capture_frame_sequence[25];
       26: if_this_frame_capture <= capture_frame_sequence[26];27: if_this_frame_capture <= capture_frame_sequence[27];
       28: if_this_frame_capture <= capture_frame_sequence[28];29: if_this_frame_capture <= capture_frame_sequence[29];
       30: if_this_frame_capture <= capture_frame_sequence[30];31: if_this_frame_capture <= capture_frame_sequence[31];
       default: if_this_frame_capture <= 1'b0;
   endcase else if_this_frame_capture <= if_this_frame_capture;
end
always @(posedge clk or negedge rstn) begin
    if(~rstn) total_need_frame_num <= 0;
    else if(add_need_frame) begin
        if(total_need_frame_num == 0)
                                         total_need_frame_num <= total_need_frame_num + add_need_frame_num;
        else if(nt_st_store == ST_STORE) total_need_frame_num <= total_need_frame_num + add_need_frame_num - (hdmi_vsync_neg_for_clk & if_this_frame_capture);
    end else if(nt_st_store == ST_STORE) total_need_frame_num <= total_need_frame_num - (hdmi_vsync_neg_for_clk & if_this_frame_capture);
    else                                 total_need_frame_num <= total_need_frame_num;
end

jpeg_encoder_top u_jpeg_encoder_top(
	.clk                         	( hdmi_in_clk                  ),
	.rstn                        	( (capture_on)                 ),
	.frame_done                  	( HDMI_VSYNC_d1 && (~frame_notready)),
	.pixel_x                     	( camera_h                     ),
	.pixel_y                     	( camera_v                     ),
	.data_in_enable              	( (nt_st_store == ST_STORE) && (HDMI_HREF_d1) && if_this_frame_capture && (total_need_frame_num != 0)  ),
	.data_in                     	( HDMI_DATA_d1                 ),
	.jpeg_encoder_clk            	( jpeg_encoder_clk             ),
	.pixel_x_out                 	( pixel_x_out                  ),
	.pixel_y_out                 	( pixel_y_out                  ),
    .bitstream_size               	( bitstream_size               ),
	.JPEG_bitstream              	( JPEG_bitstream               ),
	.jpeg_enoder_data_ready      	( jpeg_enoder_data_ready       ),
	.end_of_file_bitstream_count 	( end_of_file_bitstream_count  ),
	.eof_data_partial_ready      	( eof_data_partial_ready       )
);
always @(posedge jpeg_encoder_clk or negedge rstn) begin
    if(~rstn) bitstream_size_reg <= 0;
    else if(eof_data_partial_ready) bitstream_size_reg <= bitstream_size;
    else bitstream_size_reg <= bitstream_size_reg;
end

reg fifo_rd_data_valid;
always @(posedge clk or negedge rstn) begin
    if(~rstn) fifo_rd_data_valid <= 1'b0;
    else if((~capture_on) || (frame_notready)) fifo_rd_data_valid <= 1'b0;
    else if(rd_data_valid && rd_data_ready && rd_empty && fifo_rd_data_valid) fifo_rd_data_valid <= 1'b0;
    else if(fifo_rd_en && (~rd_empty) && (~fifo_rd_data_valid)) fifo_rd_data_valid <= 1'b1;
    else fifo_rd_data_valid <= fifo_rd_data_valid;
end

assign fifo_wr_rst = (~hdmi_in_rstn) || ((~capture_on) || (frame_notready));
assign fifo_wr_en = jpeg_enoder_data_ready | eof_data_partial_ready;
assign fifo_rd_rst = (~rstn) || ((~capture_on) || (frame_notready));
assign fifo_rd_en = (~rd_empty) && ((rd_data_valid && rd_data_ready) || (~fifo_rd_data_valid));
assign rd_data_ready = fifo_rd_data_valid;

wire fifo_wr_full;
// always begin
//     wait(jpeg_encoder_clk === 1'b1);
//     while((~fifo_wr_full) === 1'b1) @(posedge jpeg_encoder_clk);
//     $display("[%t] Warning: JPEG bitstream FIFO is full, data may be lost!", $time);
//     while(fifo_wr_full === 1'b1) @(posedge jpeg_encoder_clk);
// end
jpeg_encode_bitstream_fifo u_jpeg_encode_bitstream_fifo(
    .wr_clk         ( jpeg_encoder_clk),
    .wr_rst         ( fifo_wr_rst     ),
    .wr_en          ( fifo_wr_en      ),
    .wr_data        ( JPEG_bitstream  ),
    .wr_full        ( fifo_wr_full    ),

    .rd_clk         ( clk             ),
    .rd_rst         ( fifo_rd_rst     ),
    .rd_en          ( fifo_rd_en      ),
    .rd_data        ( rd_data         ),
    .rd_empty       ( rd_empty        ),
    .rd_water_level ( rd_water_level)
);

reg [1:0] cu_fifo_rd_st, nt_fifo_rd_st;
reg [31:0] bitstream_trans_size;
reg frame_need_trans_all;
localparam
    FIFO_RD_ST_IDLE        = 2'b00,
    FIFO_RD_ST_TRANS_BURST = 2'b01,
    FIFO_RD_ST_TRANS_DATA  = 2'b10,
    FIFO_RD_ST_FRAME_OVER  = 2'b11;

always @(posedge jpeg_encoder_clk or negedge rstn) begin
    if(~rstn) frame_need_trans_all <= 0;
    else if(frame_need_trans_all == 0) frame_need_trans_all <= eof_data_partial_ready;
    else if(cu_fifo_rd_st == FIFO_RD_ST_FRAME_OVER)
         frame_need_trans_all <= 0;
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
    end else if(cu_fifo_rd_st == FIFO_RD_ST_IDLE) begin
        if(rd_water_level + fifo_rd_data_valid >= 255)
             rd_data_burst <= 8'hff; // burst size is 255
        else if(frame_need_trans_all)
             rd_data_burst <= (rd_water_level + fifo_rd_data_valid - 1);
        else rd_data_burst <= rd_data_burst;
    end else if(cu_fifo_rd_st == FIFO_RD_ST_TRANS_DATA && rd_data_valid && rd_data_ready) begin
             rd_data_burst <= rd_data_burst - 1;
    end else rd_data_burst <= rd_data_burst;
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) cu_fifo_rd_st <= FIFO_RD_ST_IDLE;
    else cu_fifo_rd_st <= nt_fifo_rd_st;
end
always @(*) begin
    case (cu_fifo_rd_st)
        FIFO_RD_ST_IDLE        : nt_fifo_rd_st = ((rd_water_level + fifo_rd_data_valid >= 255) | frame_need_trans_all)?(FIFO_RD_ST_TRANS_BURST):(FIFO_RD_ST_IDLE);
        FIFO_RD_ST_TRANS_BURST : nt_fifo_rd_st = (rd_data_burst_valid && rd_data_burst_ready)?(FIFO_RD_ST_TRANS_DATA):(FIFO_RD_ST_TRANS_BURST);
        FIFO_RD_ST_TRANS_DATA  : nt_fifo_rd_st = (rd_data_valid && rd_data_ready && (rd_data_burst == 0))?((frame_need_trans_all && (bitstream_trans_size == bitstream_size_reg - 1))?(FIFO_RD_ST_FRAME_OVER):(FIFO_RD_ST_IDLE)):(FIFO_RD_ST_TRANS_DATA);
        FIFO_RD_ST_FRAME_OVER  : nt_fifo_rd_st = (frame_need_trans_all == 0)?(FIFO_RD_ST_IDLE):(FIFO_RD_ST_FRAME_OVER);
    endcase
end
assign rd_data_burst_valid = (cu_fifo_rd_st == FIFO_RD_ST_TRANS_BURST);

reg fifo_rd_info_valid;
always @(posedge clk or negedge rstn) begin
    if(~rstn) fifo_rd_info_valid <= 1'b0;
    else if(~capture_on) fifo_rd_info_valid <= 1'b0;
    else if(rd_info_valid && rd_info_ready && rd_info_empty && fifo_rd_info_valid) fifo_rd_info_valid <= 1'b0;
    else if(fifo_rd_info_en && (~rd_info_empty) && (~fifo_rd_info_valid)) fifo_rd_info_valid <= 1'b1;
    else fifo_rd_info_valid <= fifo_rd_info_valid;
end

reg eof_data_partial_ready_d;
reg [31:0] jpeg_encode_info_fifo_wr_data;
always @(posedge jpeg_encoder_clk or negedge rstn) begin
    if(~rstn) eof_data_partial_ready_d <= 1'b0;
    else eof_data_partial_ready_d <= eof_data_partial_ready;
end
always @(*) begin
    if(eof_data_partial_ready) jpeg_encode_info_fifo_wr_data = {4'b0, pixel_y_out, 4'b0, pixel_x_out};
    else if(eof_data_partial_ready_d) jpeg_encode_info_fifo_wr_data = bitstream_size_reg;
    else jpeg_encode_info_fifo_wr_data = 32'h0;
end
assign fifo_wr_info_rst = (~hdmi_in_rstn) || (~capture_on);
assign fifo_wr_info_en = eof_data_partial_ready || eof_data_partial_ready_d;
assign fifo_rd_info_rst = (~rstn) || (~capture_on);
assign fifo_rd_info_en = (~rd_info_empty) && ((rd_info_valid && rd_info_ready) || (~fifo_rd_info_valid));
assign rd_info_ready = fifo_rd_info_valid;
wire [9:0] frame_save_num_inter;
assign frame_save_num = (frame_save_num_inter / 2) + fifo_rd_info_valid;
//8'b0,32,12,12
wire fifo_wr_info_full;
// always begin
//     wait(jpeg_encoder_clk === 1'b1);
//     while((~fifo_wr_info_full) === 1'b1) @(posedge jpeg_encoder_clk);
//     $display("[%t] Warning: JPEG encode info FIFO is full, data may be lost!", $time);
//     while(fifo_wr_info_full === 1'b1) @(posedge jpeg_encoder_clk);
// end
jpeg_encode_info_fifo u_jpeg_encode_info_fifo(
    .wr_clk         ( jpeg_encoder_clk     ),
    .wr_rst         ( fifo_wr_info_rst     ),
    .wr_en          ( fifo_wr_info_en      ),
    .wr_data        ( jpeg_encode_info_fifo_wr_data),
    .wr_water_level ( frame_save_num_inter ),
    .wr_full        ( fifo_wr_info_full    ),

    .rd_clk         ( clk                  ),
    .rd_rst         ( fifo_rd_info_rst     ),
    .rd_en          ( fifo_rd_info_en      ),
    .rd_data        ( rd_info              ),
    .rd_empty       ( rd_info_empty        )
);

endmodule