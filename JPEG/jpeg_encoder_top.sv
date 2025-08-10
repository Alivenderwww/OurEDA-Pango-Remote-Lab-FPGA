module jpeg_encoder_top(
    input  wire        clk,
    input  wire        rstn,
    input  wire        frame_done,    // high valid, indicate old frame done and new frame start
    input  wire [11:0] pixel_x,       // max 4095, can be not 8's multiple, load when frame_done
    input  wire [11:0] pixel_y,       // max 4095, can be not 8's multiple, load when frame_done
    input  wire        data_in_enable,// high valid
    input  wire [23:0] data_in,       // {R,G,B} data input
    
    input  wire        jpeg_encoder_clk, // clock for jpeg encoder, can be different from clk
    output wire [11:0] pixel_x_out, // loaded pixel_x when frame_done
    output wire [11:0] pixel_y_out, // loaded pixel_y when frame_done
    output wire [31:0] bitstream_size, // size of the JPEG bitstream in 4bytes!
    output wire [31:0] JPEG_bitstream, // jpeg bitstream output
    output wire        jpeg_enoder_data_ready, // high valid, indicate jpeg bitstream output valid
    output wire [4:0]  end_of_file_bitstream_count, // indicate how many valid bits in the last JPEG_bitstream
    output wire        eof_data_partial_ready // high valid, indicate the last JPEG_bitstream
);
reg frame_done_d;
wire frame_done_rise = frame_done & ~frame_done_d;
wire frame_done_fall = ~frame_done & frame_done_d;
reg [11:0] pixel_x_load, pixel_y_load;
reg [8:0] block_x_load, block_y_load; // 9 bits to support 4096 pixels
assign pixel_x_out = pixel_x_load;
assign pixel_y_out = pixel_y_load;
reg [11:0] pixel_x_count, pixel_y_count; 

reg  [7:0] fifo_wr_enable;
reg  [7:0] fifo_rd_en;
wire [7:0] [23:0] fifo_rd_data;
wire [7:0] [12:0] fifo_rd_water_level;
wire [7:0] fifo_rd_empty;
wire [7:0] fifo_wr_full;

reg [23:0] jpeg_enoder_data_in;
reg jpeg_enoder_data_enable;

reg [3+3-1:0] blockin_count;
reg  [8:0] block_x, block_y;
wire [2:0] blockin_x, blockin_y;
wire dummy_y, dummy_x;

wire end_of_file_signal;
wire jpeg_encoder_rst;

// outports wire
// wire [31:0] 	JPEG_bitstream;
// wire        	jpeg_enoder_data_ready;
// wire [4:0]  	end_of_file_bitstream_count;
// wire        	eof_data_partial_ready;

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
        block_x_load <= (pixel_x + 7) >> 3; // 8 pixels per block
		pixel_y_load <= pixel_y;
        block_y_load <= (pixel_y + 7) >> 3; // 8 pixels per block
	end else begin
		pixel_x_load <= pixel_x_load;
        block_x_load <= block_x_load;
		pixel_y_load <= pixel_y_load;
        block_y_load <= block_y_load;
	end
end

reg cu_state, nt_state;
localparam 
	ST_IDLE  = 1'b0,
	ST_STORE = 1'b1;
always @(posedge clk or negedge rstn) begin
	if(~rstn) cu_state <= ST_IDLE;
	else cu_state <= nt_state;
end
always @(*) begin
	case (cu_state)
		ST_IDLE:  nt_state = (frame_done_fall)?(ST_STORE):(ST_IDLE);
		ST_STORE: nt_state = (frame_done_rise)?(ST_IDLE):(ST_STORE);
		default:  nt_state = ST_IDLE;
	endcase
end

always @(posedge clk or negedge rstn) begin
	if(~rstn) pixel_x_count <= 0;
	else if(nt_state == ST_STORE) begin
        if(data_in_enable) begin
            if(pixel_x_count >= pixel_x_load - 1)
                 pixel_x_count <= 0;
            else pixel_x_count <= pixel_x_count + 1;
        end else pixel_x_count <= pixel_x_count;
	end else     pixel_x_count <= 0;
end

always @(posedge clk or negedge rstn) begin
	if(~rstn) pixel_y_count <= 0;
	else if(nt_state == ST_STORE) begin
		if(data_in_enable && (pixel_x_count >= pixel_x_load - 1))
			 pixel_y_count <= pixel_y_count + 1;
		else pixel_y_count <= pixel_y_count;
	end else pixel_y_count <= 0;
end

integer i;
always @(*) begin
	for(i=0;i<8;i=i+1) if((nt_state == ST_STORE) && pixel_y_count[2:0] == i) begin
		if(pixel_x_count <= pixel_x_load - 1)
			 fifo_wr_enable[i] = data_in_enable;
		else fifo_wr_enable[i] = 0;
	end else fifo_wr_enable[i] = 0;
end


reg [7:0] fifo_rd_data_valid;
always @(posedge jpeg_encoder_clk or negedge rstn) begin
    if(~rstn) fifo_rd_data_valid <= 0;
    else for(i=0;i<8;i=i+1) begin
        if(fifo_rd_en[i] && fifo_rd_empty[i] && fifo_rd_data_valid[i]) fifo_rd_data_valid[i] <= 0;
        else if((~fifo_rd_empty[i]) && (~fifo_rd_data_valid[i])) fifo_rd_data_valid[i] <= 1;
        else fifo_rd_data_valid[i] <= fifo_rd_data_valid[i];
    end
end
// always begin
//     wait(jpeg_encoder_clk === 1'b1);
//     while((~|fifo_wr_full) === 1'b1) @(posedge jpeg_encoder_clk);
//     $display("[%t] Warning: JPEG encode line FIFO is full, data may be lost!", $time);
//     while((|fifo_wr_full) === 1'b1) @(posedge jpeg_encoder_clk);
// end
genvar ui;
generate
    for (ui = 0; ui < 8; ui++) begin: gen_jpeg_encoder_line_fifo
        jpeg_encoder_line_fifo u_jpeg_encoder_line_fifo(
        	.wr_clk		  (clk              ),
        	.wr_rst 	  (~rstn            ),
        	.wr_en		  (fifo_wr_enable[ui]),
        	.wr_data	  (data_in          ),
            .wr_full      (fifo_wr_full[ui]),

        	.rd_clk		  (jpeg_encoder_clk ),
        	.rd_rst 	  (~rstn            ),
        	.rd_en		  (fifo_rd_en[ui] | ((~fifo_rd_empty[ui]) && (~fifo_rd_data_valid[ui]))),
        	.rd_data	  (fifo_rd_data[ui] ),
            .rd_empty     (fifo_rd_empty[ui]),
            .rd_water_level (fifo_rd_water_level[ui])
        );
    end
endgenerate

reg frame_start, reset_done, data_enough, block_done, delay_done, disable_done, last_block;
reg [2:0] cu_rd_st, nt_rd_st;
localparam
    ST_RD_IDLE       = 3'b000,
    ST_RD_RESET      = 3'b001,
    ST_RD_BLOCK      = 3'b010,
    ST_RD_DELAY      = 3'b011,
    ST_RD_DISABLE    = 3'b100,
    ST_RD_LAST_BLOCK = 3'b101,
    ST_RD_LAST_DELAY = 3'b110,
    ST_RD_WAIT       = 3'b111;
always @(posedge jpeg_encoder_clk or negedge rstn) begin
    if(~rstn) cu_rd_st <= ST_RD_IDLE;
    else cu_rd_st <= nt_rd_st;
end
always @(*) begin
    case (cu_rd_st)
        ST_RD_IDLE:      nt_rd_st = (frame_start)?(ST_RD_RESET):(ST_RD_IDLE);
        ST_RD_RESET:     nt_rd_st = (reset_done && data_enough)?(ST_RD_BLOCK):(ST_RD_RESET);
        ST_RD_BLOCK:     nt_rd_st = (block_done)?(ST_RD_DELAY):(ST_RD_BLOCK);
        ST_RD_LAST_BLOCK:nt_rd_st = (block_done)?(ST_RD_LAST_DELAY):(ST_RD_LAST_BLOCK);
        ST_RD_DELAY:     nt_rd_st = (delay_done & data_enough)?(ST_RD_DISABLE):(ST_RD_DELAY);
        ST_RD_LAST_DELAY:nt_rd_st = (delay_done)?(ST_RD_WAIT):(ST_RD_LAST_DELAY);
        ST_RD_DISABLE:   nt_rd_st = (disable_done)?((last_block)?(ST_RD_LAST_BLOCK):(ST_RD_BLOCK)):(ST_RD_DISABLE);
        ST_RD_WAIT:      nt_rd_st = (eof_data_partial_ready)?(ST_RD_IDLE):(ST_RD_WAIT);
        default:         nt_rd_st = ST_RD_IDLE;
    endcase
end

// frame_start
always @(posedge jpeg_encoder_clk or negedge rstn) begin
    if(~rstn) frame_start <= 0;
    else if(frame_done_rise) frame_start <= 1;
    else if((cu_rd_st == ST_RD_IDLE) && (nt_rd_st == ST_RD_RESET)) frame_start <= 0;
    else frame_start <= frame_start;
end

// reset_done
reg [2:0] reset_count;
always @(posedge jpeg_encoder_clk or negedge rstn) begin
    if(~rstn) reset_count <= 0;
    else if(cu_rd_st == ST_RD_RESET) begin
        if(reset_count < 3'b111) reset_count <= reset_count + 1;
        else reset_count <= reset_count;
    end else reset_count <= 0;
end
always @(*) begin
    if((cu_rd_st == ST_RD_RESET) && (reset_count == 3'b111)) begin
             reset_done <= 1;
    end else reset_done <= 0;
end
//data_enough -> fifo_rd_water_level
reg [7:0] line_data_enough;
always @(*) begin
    for(i=0;i<8;i=i+1) begin
        if((block_y == pixel_y_load[11:3]) && (i >= pixel_y_load[2:0]))  // now in block with dummy y
             line_data_enough[i] = 1;  // line [i] no need data, others also need
        else if(block_x == pixel_x_load[11:3]) // now in block with dummy x
             line_data_enough[i] = (fifo_rd_water_level[i] + fifo_rd_data_valid[i] >= pixel_x_load[2:0]); // same for each line
        else line_data_enough[i] = (fifo_rd_water_level[i] + fifo_rd_data_valid[i] >= 8);
    end
    data_enough = &line_data_enough; // all 8 lines have enough data
end

//jpeg_enoder_data_enable
always @(*) begin
    if(cu_rd_st == ST_RD_BLOCK || cu_rd_st == ST_RD_LAST_BLOCK) begin
             jpeg_enoder_data_enable = 1;
    end else jpeg_enoder_data_enable = 0;
end
assign blockin_x = blockin_count[0+:3];
assign blockin_y = blockin_count[3+:3];
assign dummy_y = (block_y == pixel_y_load[11:3]) && (blockin_y >= pixel_y_load[2:0]);
assign dummy_x = (block_x == pixel_x_load[11:3]) && (blockin_x >= pixel_x_load[2:0]);
always @(posedge jpeg_encoder_clk or negedge rstn) begin
    if(~rstn) blockin_count <= 0;
    else if(cu_rd_st == ST_RD_IDLE) begin
             blockin_count <= 0;
    end else if((cu_rd_st == ST_RD_BLOCK || cu_rd_st == ST_RD_LAST_BLOCK) && jpeg_enoder_data_enable) begin
             blockin_count <= blockin_count + 1;
    end else blockin_count <= blockin_count;
end
always @(posedge jpeg_encoder_clk or negedge rstn) begin
    if(~rstn) begin
        block_x <= 0;
        block_y <= 0;
    end else if(cu_rd_st == ST_RD_IDLE) begin
        block_x <= 0;
        block_y <= 0;
    end else if((cu_rd_st == ST_RD_BLOCK || cu_rd_st == ST_RD_LAST_BLOCK) && jpeg_enoder_data_enable && blockin_count == 6'b111111) begin
        if(block_x >= block_x_load - 1) begin
            block_x <= 0;
            block_y <= block_y + 1;
        end else begin
            block_x <= block_x + 1;
            block_y <= block_y;
        end
    end else begin
        block_x <= block_x;
        block_y <= block_y;
    end
end
always @(*) begin
    case(blockin_count[3+3-1:3])
        3'd0: jpeg_enoder_data_in = fifo_rd_data[0];
        3'd1: jpeg_enoder_data_in = fifo_rd_data[1];
        3'd2: jpeg_enoder_data_in = fifo_rd_data[2];
        3'd3: jpeg_enoder_data_in = fifo_rd_data[3];
        3'd4: jpeg_enoder_data_in = fifo_rd_data[4];
        3'd5: jpeg_enoder_data_in = fifo_rd_data[5];
        3'd6: jpeg_enoder_data_in = fifo_rd_data[6];
        3'd7: jpeg_enoder_data_in = fifo_rd_data[7];
    endcase
end
always @(*) begin
    for(i=0;i<8;i=i+1) if((cu_rd_st == ST_RD_BLOCK || cu_rd_st == ST_RD_LAST_BLOCK) && blockin_y == i) begin
             fifo_rd_en[i] = jpeg_enoder_data_enable && (~dummy_y) && (~dummy_x);
    end else fifo_rd_en[i] = 0;
end
//block_done
always @(*) begin
    if((jpeg_enoder_data_enable) && (cu_rd_st == ST_RD_BLOCK || cu_rd_st == ST_RD_LAST_BLOCK) && (blockin_x == 3'b111) && (blockin_y == 3'b111)) begin
             block_done <= 1;
    end else block_done <= 0;
end
//delay_done //delay 33 cycles
reg [31:0] delay_count;
localparam DELAY_CYCLES = 32'd13;
wire delay_enable = (cu_rd_st == ST_RD_DELAY || cu_rd_st == ST_RD_LAST_DELAY) && (delay_count <= DELAY_CYCLES);
always @(posedge jpeg_encoder_clk or negedge rstn) begin
    if(~rstn) delay_count <= 0;
    else if(cu_rd_st == ST_RD_DELAY || cu_rd_st == ST_RD_LAST_DELAY) begin
        if(delay_count < DELAY_CYCLES) delay_count <= delay_count + 1;
        else delay_count <= delay_count;
    end else delay_count <= 0;
end
always @(*) begin
    if((cu_rd_st == ST_RD_DELAY || cu_rd_st == ST_RD_LAST_DELAY) && (delay_count >= DELAY_CYCLES - 1)) begin
             delay_done <= 1;
    end else delay_done <= 0;
end
//disable_done //disable 1 cycles
reg [31:0] disable_count;
localparam DISABLE_CYCLES = 32'd1;
always @(posedge jpeg_encoder_clk or negedge rstn) begin
    if(~rstn) disable_count <= 0;
    else if(cu_rd_st == ST_RD_DISABLE) begin
        if(disable_count < DISABLE_CYCLES) disable_count <= disable_count + 1;
        else disable_count <= disable_count;
    end else disable_count <= 0;
end
always @(*) begin
    if((cu_rd_st == ST_RD_DISABLE) && (disable_count >= DISABLE_CYCLES - 1)) begin
             disable_done <= 1;
    end else disable_done <= 0;
end
//last_block
always @(*) begin
    if((block_x == block_x_load - 1) && (block_y == block_y_load - 1)) begin
             last_block <= 1;
    end else last_block <= 0;
end

reg [31:0] bitstream_count;
always @(posedge jpeg_encoder_clk or negedge rstn) begin
    if(~rstn) bitstream_count <= 1;
    else if((cu_rd_st == ST_RD_IDLE) || (cu_rd_st == ST_RD_RESET)) begin
        bitstream_count <= 1;
    end else if(jpeg_enoder_data_ready || eof_data_partial_ready) begin
        bitstream_count <= bitstream_count + 1;
    end else begin
        bitstream_count <= bitstream_count;
    end
end

assign end_of_file_signal = ((cu_rd_st == ST_RD_LAST_BLOCK) || (cu_rd_st == ST_RD_LAST_DELAY));
assign jpeg_encoder_rst = (~rstn) || (cu_rd_st == ST_RD_RESET);
wire jpeg_enoder_data_ready_inter;
wire eof_data_partial_ready_inter;
assign jpeg_enoder_data_ready = (cu_rd_st != ST_RD_IDLE) && (cu_rd_st != ST_RD_RESET) && (jpeg_enoder_data_ready_inter);
assign eof_data_partial_ready = (cu_rd_st != ST_RD_IDLE) && (cu_rd_st != ST_RD_RESET) && (eof_data_partial_ready_inter);
assign bitstream_size = bitstream_count;
jpeg_top u_jpeg_top(
	.clk                         	( jpeg_encoder_clk             ),
	.rst                            ( jpeg_encoder_rst             ),
	.end_of_file_signal          	( end_of_file_signal           ),
	.enable                      	( jpeg_enoder_data_enable | delay_enable),
	.data_in                     	( jpeg_enoder_data_in          ),
	.JPEG_bitstream              	( JPEG_bitstream               ),
	.data_ready                  	( jpeg_enoder_data_ready_inter ),
	.end_of_file_bitstream_count 	( end_of_file_bitstream_count  ),
	.eof_data_partial_ready      	( eof_data_partial_ready_inter )
);


endmodule //jpeg_encoder_top
