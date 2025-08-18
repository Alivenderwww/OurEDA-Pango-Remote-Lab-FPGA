module jpeg_encoder_top(
    input  wire        clk,
    input  wire        rstn,
    input  wire        frame_done,    // high valid, indicate old frame done and new frame start
    input  wire [11:0] pixel_x,       // max 4095, can be not 8's multiple, load when frame_done
    input  wire [11:0] pixel_y,       // max 4095, can be not 8's multiple, load when frame_done
    input  wire        jpeg_encode_bitstream_fifo_almost_full,

    output  reg        wr_data_burst_valid,
    input  wire        wr_data_burst_ready,
    output  reg [ 7:0] wr_data_burst,
    input  wire        wr_data_valid,
    output  reg        wr_data_ready,
    input  wire [31:0] wr_data,
    input  wire        wr_data_last, // high valid, indicate this wr_data is the last data of a burst
    
    output wire [31:0] bitstream_size, // size of the JPEG bitstream in 4bytes!
    output wire [31:0] JPEG_bitstream, // jpeg bitstream output
    output wire        jpeg_enoder_data_ready, // high valid, indicate jpeg bitstream output valid
    output wire [4:0]  end_of_file_bitstream_count, // indicate how many valid bits in the last JPEG_bitstream
    output wire        eof_data_partial_ready,// high valid, indicate the last JPEG_bitstream
    output wire [13*8*8 - 1:0] Y_Quantizer, 
    output wire [13*8*8 - 1:0] CB_Quantizer,
    output wire [13*8*8 - 1:0] CR_Quantizer
);
reg frame_done_d;
wire frame_done_rise = frame_done & ~frame_done_d;
wire frame_done_fall = ~frame_done & frame_done_d;

reg [11:0] pixel_x_load, pixel_y_load;
reg [8:0] block_x_load, block_y_load;

reg [11:0] pixel_x_wr_count, pixel_y_wr_count; 
reg [ 8:0] block_x_wr_count, block_y_wr_count;
reg [ 8:0] block_x_wr_ready, block_y_wr_ready; //below this's block is ready to read
reg [ 2:0] inblock_x_wr_count, inblock_y_wr_count;

reg [ 8:0] block_x_rd_count, block_y_rd_count;
reg [ 2:0] inblock_x_rd_count, inblock_y_rd_count;

wire [23:0] jpeg_enoder_data_in;
reg jpeg_enoder_data_enable;

wire end_of_file_signal;
wire jpeg_encoder_rst;

reg [14:0] wr_addr, rd_addr;

reg line8_wr_over;

reg if_this_wr_is_FRAME;
reg if_this_rd_is_FRAME;

reg data_in_enable;
reg [23:0] jpeg_encoder_before_data;

reg wr_full, wr_almost_full;

always @(posedge clk or negedge rstn) begin
	if(~rstn) frame_done_d <= 0;
	else frame_done_d <= frame_done;
end

always @(posedge clk or negedge rstn) begin
	if(~rstn) begin
		pixel_x_load <= 0;
		pixel_y_load <= 0;
        block_x_load <= 0;
        block_y_load <= 0;
	end else if(frame_done_rise) begin
		pixel_x_load <= pixel_x;
		pixel_y_load <= pixel_y;
        block_x_load <= (pixel_x + 7) >> 3; // 8 pixels per block
        block_y_load <= (pixel_y + 7) >> 3; // 8 pixels per block
	end else begin
		pixel_x_load <= pixel_x_load;
		pixel_y_load <= pixel_y_load;
        block_x_load <= block_x_load;
        block_y_load <= block_y_load;
	end
end

reg [1:0] cu_wr_state, nt_wr_state;
localparam 
	ST_WR_IDLE  = 2'b00,
    ST_WR_BURST = 2'b01,
	ST_WR_DATA  = 2'b10;

always @(posedge clk or negedge rstn) begin
	if(~rstn) cu_wr_state <= ST_WR_IDLE;
	else      cu_wr_state <= nt_wr_state;
end
always @(*) begin
	case (cu_wr_state)
		ST_WR_IDLE : nt_wr_state = (frame_done_fall)?(ST_WR_BURST):(ST_WR_IDLE);
        ST_WR_BURST: nt_wr_state = (wr_data_burst_valid && wr_data_burst_ready)?(ST_WR_DATA):(ST_WR_BURST);
        ST_WR_DATA : nt_wr_state = (wr_data_valid && wr_data_ready && wr_data_last)?(ST_WR_BURST):(ST_WR_DATA);
		default:     nt_wr_state = ST_WR_IDLE;
	endcase
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
             wr_data_burst <= 0;
    end else if(nt_wr_state == ST_WR_BURST) begin
             wr_data_burst <= 8'hff; // burst size is always 255
    end else wr_data_burst <= wr_data_burst;
end

//data_in_enable, jpeg_encoder_before_data
always @(*) begin
    if(cu_wr_state == ST_WR_DATA) wr_data_ready = 1;
    else wr_data_ready = 1'b0;
    
    if(wr_data_valid && wr_data_ready) begin
        data_in_enable = 1;
        jpeg_encoder_before_data = wr_data[23:0];
    end else begin
        data_in_enable = 0;
        jpeg_encoder_before_data = 24'hffffff;
    end
end

//if_this_wr_is_FRAME
always @(posedge clk or negedge rstn) begin
	if(~rstn) if_this_wr_is_FRAME <= 0;
    else if(line8_wr_over) begin
             if_this_wr_is_FRAME <= ~if_this_wr_is_FRAME;
    end else if_this_wr_is_FRAME <= if_this_wr_is_FRAME;
end

always @(*) begin
    wr_almost_full = (if_this_wr_is_FRAME != if_this_rd_is_FRAME) && ((inblock_y_wr_count >= 3'b101) || (pixel_y_wr_count >= pixel_y_load - 3));
    wr_data_burst_valid = (cu_wr_state == ST_WR_BURST) && (~wr_almost_full);
    line8_wr_over = (pixel_x_wr_count >= pixel_x_load - 1) && ((inblock_y_wr_count == 3'b111) || (pixel_y_wr_count >= pixel_y_load - 1)) && data_in_enable;
    wr_full = (if_this_wr_is_FRAME != if_this_rd_is_FRAME) && (pixel_x_wr_count >= pixel_x_load - 1) && ((inblock_y_wr_count == 3'b111) || (pixel_y_wr_count >= pixel_y_load - 1));
end

always @(posedge clk or negedge rstn) begin
	if(~rstn) pixel_x_wr_count <= 0;
    else if(nt_wr_state == ST_WR_IDLE) pixel_x_wr_count <= 0;
	else begin
        if(data_in_enable) begin
            if(pixel_x_wr_count >= pixel_x_load - 1)
                 pixel_x_wr_count <= 0;
            else pixel_x_wr_count <= pixel_x_wr_count + 1;
        end else pixel_x_wr_count <= pixel_x_wr_count;
	end
end

always @(posedge clk or negedge rstn) begin
	if(~rstn) pixel_y_wr_count <= 0;
    else if(nt_wr_state == ST_WR_IDLE) pixel_y_wr_count <= 0;
	else begin
		if(data_in_enable && (pixel_x_wr_count >= pixel_x_load - 1))
			 pixel_y_wr_count <= (pixel_y_wr_count >= pixel_y_load - 1)?(0):(pixel_y_wr_count + 1);
		else pixel_y_wr_count <= pixel_y_wr_count;
	end
end

always @(*) begin
    block_x_wr_count   = pixel_x_wr_count >> 3;
    block_y_wr_count   = pixel_y_wr_count >> 3;
    inblock_x_wr_count = pixel_x_wr_count[2:0];
    inblock_y_wr_count = pixel_y_wr_count[2:0];
end

//wr_addr
always @(*) begin
    // if(if_this_wr_is_FRAME[0]) begin // line stage0: 存储方式1
        wr_addr[14]   = if_this_wr_is_FRAME;
        wr_addr[13:0] = (block_x_wr_count * 64) + inblock_x_wr_count + (inblock_y_wr_count * 8);
    // end else begin // line stage1: 存储方式2
        // wr_addr = (block_x_wr_count *  8) + inblock_x_wr_count + (inblock_y_wr_count * block_x_load * 8);
    // end
end

//block_x_wr_ready, block_y_wr_ready
always @(*) begin
    block_x_wr_ready = (inblock_y_wr_count == 3'b111) ? (block_x_wr_count):(0);
    block_y_wr_ready = block_y_wr_count;
end

/*
HDMI - JPEG 编码器 暂存RAM
ram地址14位，共可存储[11位]+[3位]即2048*8行像素

存储和读取方式：
第一次存储：按block内逐行逐列，block外逐行逐列顺序存储，即每写8个像素点就跳到下一个block的位置
第一次读取：等待第一个block写完。由于存储时按照block顺序存，所以读取时直接按addr顺序读取即可
第二次存储：由于读取时按照addr顺序读取，所以第二次存储时需要按addr顺序写入，覆盖无用数据
第二次读取：按block内逐行逐列，block外逐行逐列顺序读取，即每读8个像素点就跳到下一个block的位置读
第三次存储：由于读取时按block内逐行逐列，block外逐行逐列顺序读取，覆盖无用数据，因此存储时按照第一次存储的方式即可，开始循环

wr_clk的数据来源是hdmi的话，hdmi每行每帧有效数据之间有间隔，降低了wr_clk传输频率
jpeg_encoder每传输1个block需要休息13个时钟周期，降低了rd_clk传输频率
jpeg_encoder要求行宽是8的倍数，长宽非8倍数的视频流会传输dummy数据，降低了rd_clk传输频率
*/
jpeg_encoder_before_ram jpeg_encoder_before_ram_inst (
  .wr_clk   (clk                     ),// input
  .wr_rst   (~rstn                   ),// input
  .wr_en    (data_in_enable          ),// input
  .wr_addr  (wr_addr                 ),// input [14:0]
  .wr_data  (jpeg_encoder_before_data),// input [23:0]

  .rd_clk   (clk                     ),// input
  .rd_rst   (~rstn                   ),// input
  .rd_addr  (rd_addr                 ),// input  [14:0]
  .rd_data  (jpeg_enoder_data_in     ) // output [23:0]
);

// parameter VIDEO_TOTAL_PIXELS = 307200; // Python script will update this
// reg [23:0] video_hex_data [0:VIDEO_TOTAL_PIXELS-1]; // Dynamic array size
// initial begin
//     integer file_handle, scan_result;
//     integer pixel_count = 0;
//     reg [23:0] pixel_data;
//     string line;
//     #10000;
//     file_handle = $fopen("../output/video_data.hex", "r");
//     if (file_handle == 0) begin
//         $display("Warning: Cannot open video_data.hex file, using default test pattern");
//     end else begin
//         // 读取hex数据
//         while (!$feof(file_handle) && pixel_count < VIDEO_TOTAL_PIXELS) begin
//             scan_result = $fgets(line, file_handle);
//             if (scan_result > 0) begin
//                 scan_result = $sscanf(line, "%h", pixel_data);
//                 if (scan_result == 1) begin
//                     video_hex_data[pixel_count] = pixel_data;
//                     pixel_count = pixel_count + 1;
//                 end
//             end
//         end
//         $fclose(file_handle);
//     end
// end

// int hdmi_pixel_count;
// always @(posedge clk) begin
//     if(~rstn) hdmi_pixel_count <= 0;
//     else if(data_in_enable) begin
//         if(jpeg_encoder_before_data != video_hex_data[hdmi_pixel_count])
//             $display("Error: time %t, jpeg_encoder_top get wrong data from ram, addr=%d, expect=%h, get=%h", $time, hdmi_pixel_count, video_hex_data[hdmi_pixel_count], jpeg_enoder_data_in);
//         hdmi_pixel_count <=  hdmi_pixel_count + 1;
//     end
// end

reg reset_done, data_enough, block_done, delay_done, disable_done, last_block, last_block_delay;
reg reset_signal;
reg [2:0] cu_rd_state, nt_rd_state;
localparam
    ST_RD_IDLE    = 3'b000,
    ST_RD_RESET   = 3'b001,
    ST_RD_DATA    = 3'b010,
    ST_RD_DELAY   = 3'b011,
    ST_RD_DISABLE = 3'b100,
    ST_RD_WAIT    = 3'b101;
always @(posedge clk or negedge rstn) begin
    if(~rstn) cu_rd_state <= ST_RD_IDLE;
    else      cu_rd_state <= nt_rd_state;
end
always @(*) begin
    case (cu_rd_state)
        ST_RD_IDLE:    nt_rd_state = (frame_done_fall)?(ST_RD_RESET):(ST_RD_IDLE);
        ST_RD_RESET:   nt_rd_state = (reset_done && data_enough)?(ST_RD_DATA):(ST_RD_RESET);
        ST_RD_DATA:    nt_rd_state = (block_done)?(ST_RD_DELAY):(ST_RD_DATA);
        ST_RD_DELAY:   nt_rd_state = (delay_done)?((last_block_delay)?(ST_RD_WAIT):((data_enough)?(ST_RD_DISABLE):(ST_RD_DELAY))):(ST_RD_DELAY);
        ST_RD_DISABLE: nt_rd_state = (disable_done)?(ST_RD_DATA):(ST_RD_DISABLE);
        ST_RD_WAIT:    nt_rd_state = (eof_data_partial_ready)?(ST_RD_IDLE):(ST_RD_WAIT);
        default:       nt_rd_state = ST_RD_IDLE;
    endcase
end

always @(posedge clk or negedge rstn) begin
	if(~rstn) {inblock_y_rd_count, inblock_x_rd_count} <= 0;
    else if(nt_rd_state == ST_RD_RESET) {inblock_y_rd_count, inblock_x_rd_count} <= 0;
	else if(nt_rd_state == ST_RD_DATA) begin
             {inblock_y_rd_count, inblock_x_rd_count} <= {inblock_y_rd_count, inblock_x_rd_count} + 1;
    end else {inblock_y_rd_count, inblock_x_rd_count} <= {inblock_y_rd_count, inblock_x_rd_count};
end

always @(posedge clk or negedge rstn) begin
	if(~rstn) block_x_rd_count <= 0;
    else if(nt_rd_state == ST_RD_RESET) block_x_rd_count <= 0;
	else if(nt_rd_state == ST_RD_DATA && ({inblock_y_rd_count, inblock_x_rd_count} == 6'b111111)) begin
        if(block_x_rd_count >= block_x_load - 1)
             block_x_rd_count <= 0;
        else block_x_rd_count <= block_x_rd_count + 1;
    end else block_x_rd_count <= block_x_rd_count;
end

always @(posedge clk or negedge rstn) begin
	if(~rstn) block_y_rd_count <= 0;
    else if(nt_rd_state == ST_RD_RESET) block_y_rd_count <= 0;
	else if(nt_rd_state == ST_RD_DATA && ({inblock_y_rd_count, inblock_x_rd_count} == 6'b111111) && (block_x_rd_count >= block_x_load - 1)) begin
             block_y_rd_count <= block_y_rd_count + 1;
    end else block_y_rd_count <= block_y_rd_count;
end

// reset_done
reg [7:0] reset_count;
always @(posedge clk or negedge rstn) begin
    if(~rstn) reset_count <= 0;
    else if(cu_rd_state == ST_RD_RESET) begin
        if(reset_count < 8'hFF) reset_count <= reset_count + 1;
        else reset_count <= reset_count;
    end else reset_count <= 0;
end
always @(*) begin
    if((cu_rd_state == ST_RD_RESET) && (reset_count == 8'hFF)) begin
             reset_done = 1;
    end else reset_done = 0;
    if((cu_rd_state == ST_RD_RESET) && (reset_count <= 8'h8F)) begin
             reset_signal = 1;
    end else reset_signal = 0;
end

//data_enough
always @(*) begin
    if(jpeg_encode_bitstream_fifo_almost_full)
        data_enough = 0;
    else if(if_this_rd_is_FRAME != if_this_wr_is_FRAME) // mismatch means data is enough
        data_enough = 1;
    else if((block_y_wr_ready > block_y_rd_count) || ((block_y_wr_ready == block_y_rd_count) && (block_x_wr_ready > block_x_rd_count))) begin
             data_enough = 1;
    end else data_enough = 0;
end

//block_done
always @(*) begin
    if((jpeg_enoder_data_enable) && (cu_rd_state == ST_RD_DATA) && ({inblock_y_rd_count, inblock_x_rd_count} == 6'b000000)) begin
             block_done = 1;
    end else block_done = 0;
end

//last_block, last_block_delay
always @(*) begin
    if((block_x_rd_count == block_x_load - 1) && (block_y_rd_count == block_y_load - 1)) begin
             last_block = 1;
    end else last_block = 0;
end
always @(posedge clk or negedge rstn) begin
    if(~rstn) last_block_delay <= 0;
    else if(cu_rd_state == ST_RD_RESET) last_block_delay <= 0;
    else if(cu_rd_state == ST_RD_DELAY && nt_rd_state == ST_RD_DISABLE)
         last_block_delay <= last_block;
    else last_block_delay <= last_block_delay;
end

//jpeg_enoder_data_enable
always @(*) begin
    if(cu_rd_state == ST_RD_DATA) begin
             jpeg_enoder_data_enable = 1;
    end else jpeg_enoder_data_enable = 0;
end

//if_this_rd_is_FRAME
always @(posedge clk or negedge rstn) begin
    if(~rstn) if_this_rd_is_FRAME <= 0;
    else if((cu_rd_state == ST_RD_DATA) && (nt_rd_state == ST_RD_DELAY) && (block_x_rd_count == 3'b000)) begin
             if_this_rd_is_FRAME <= ~if_this_rd_is_FRAME;
    end else if_this_rd_is_FRAME <= if_this_rd_is_FRAME;
end

//rd_addr
always @(*) begin
    // if(if_this_rd_is_FRAME[0]) begin //line stage0: 读取方式1
        rd_addr[14]   = if_this_rd_is_FRAME;
        rd_addr[13:0] = (block_x_rd_count * 64) + inblock_x_rd_count + (inblock_y_rd_count * 8);
    // end else begin //line stage1: 读取方式2
        // rd_addr = (block_x_rd_count *  8) + inblock_x_rd_count + (inblock_y_rd_count * block_x_load * 8);
    // end
end

//delay_done //delay 13 cycles
reg [31:0] delay_count;
localparam DELAY_CYCLES = 32'd13;
wire delay_enable = (cu_rd_state == ST_RD_DELAY) && (delay_count <= DELAY_CYCLES);
always @(posedge clk or negedge rstn) begin
    if(~rstn) delay_count <= 0;
    else if(cu_rd_state == ST_RD_DELAY) begin
        if(delay_count < DELAY_CYCLES) 
             delay_count <= delay_count + 1;
        else delay_count <= delay_count;
    end else delay_count <= 0;
end
always @(*) begin
    if((cu_rd_state == ST_RD_DELAY) && (delay_count >= DELAY_CYCLES - 1)) begin
             delay_done = 1;
    end else delay_done = 0;
end
//disable_done //disable 1 cycles
reg [31:0] disable_count;
localparam DISABLE_CYCLES = 32'd1;
always @(posedge clk or negedge rstn) begin
    if(~rstn) disable_count <= 0;
    else if(cu_rd_state == ST_RD_DISABLE) begin
        if(disable_count < DISABLE_CYCLES)
             disable_count <= disable_count + 1;
        else disable_count <= disable_count;
    end else disable_count <= 0;
end
always @(*) begin
    if((cu_rd_state == ST_RD_DISABLE) && (disable_count >= DISABLE_CYCLES - 1)) begin
             disable_done = 1;
    end else disable_done = 0;
end

reg [31:0] bitstream_count;
always @(posedge clk or negedge rstn) begin
    if(~rstn) bitstream_count <= 1;
    else if(cu_rd_state == ST_RD_RESET) begin
        bitstream_count <= 1;
    end else if(jpeg_enoder_data_ready || eof_data_partial_ready) begin
        bitstream_count <= bitstream_count + 1;
    end else begin
        bitstream_count <= bitstream_count;
    end
end

assign end_of_file_signal = ((last_block_delay) && ((cu_rd_state == ST_RD_DATA) || (cu_rd_state == ST_RD_DELAY)));
assign jpeg_encoder_rst = (~rstn) || (reset_signal);
wire jpeg_enoder_data_ready_inter;
wire eof_data_partial_ready_inter;
assign jpeg_enoder_data_ready = (cu_rd_state != ST_RD_RESET) && (jpeg_enoder_data_ready_inter);
assign eof_data_partial_ready = (cu_rd_state != ST_RD_RESET) && (eof_data_partial_ready_inter);
assign bitstream_size = bitstream_count;
jpeg_top_fake u_jpeg_top(
	.clk                         	( clk                          ),
	.rst                            ( jpeg_encoder_rst             ),
	.end_of_file_signal          	( end_of_file_signal           ),
	.enable                      	( jpeg_enoder_data_enable | delay_enable),
	.data_in                     	( jpeg_enoder_data_in          ),
	.JPEG_bitstream              	( JPEG_bitstream               ),
	.data_ready                  	( jpeg_enoder_data_ready_inter ),
	.end_of_file_bitstream_count 	( end_of_file_bitstream_count  ),
	.eof_data_partial_ready      	( eof_data_partial_ready_inter ),
    .Y_Quantizer                    ( Y_Quantizer                   ),
    .CB_Quantizer                   ( CB_Quantizer                  ),
    .CR_Quantizer                   ( CR_Quantizer                  )
);


endmodule //jpeg_encoder_top
