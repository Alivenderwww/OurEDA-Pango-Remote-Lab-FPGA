`timescale 1ns / 100ps
module jpeg_top_fake(clk, rst, end_of_file_signal, enable, data_in, JPEG_bitstream, 
data_ready, end_of_file_bitstream_count, eof_data_partial_ready,
Y_Quantizer, CB_Quantizer, CR_Quantizer);
input		    clk;
input		    rst;
input		    end_of_file_signal;
input		    enable;
input	[23:0]	data_in;
output  reg [31:0]  JPEG_bitstream;
output	reg 	    data_ready;
output	[4:0]   end_of_file_bitstream_count;
output	reg 	    eof_data_partial_ready;
output  [13*8*8 - 1:0] Y_Quantizer, CB_Quantizer, CR_Quantizer; // 13 bits per quantized value, 8x8 block

reg [2:0] state;

wire behind_trans_over;
reg [3:0] JPEG_out_count;
reg [7:0] once_enable_count;
reg [15:0] behind_trans_count;
wire enable_pos;
wire end_of_file_signal_neg;
reg enable_d;
reg end_of_file_signal_d;

always @(posedge clk or posedge rst) begin
    if (rst) JPEG_out_count <= 0;
    else JPEG_out_count <= JPEG_out_count + 1;
end

always @(posedge clk or posedge rst) begin
    if (rst) once_enable_count <= 0;
    else if(enable_pos) once_enable_count <= 0;
    else once_enable_count <= (once_enable_count == 8'hFF)?(once_enable_count):(once_enable_count + 1);
end

always @(posedge clk or posedge rst) begin
    if (rst) behind_trans_count <= 0;
    else if (state == 3'd2) behind_trans_count <= behind_trans_count + 1;
    else behind_trans_count <= 0;
end
assign behind_trans_over = (behind_trans_count > 1000);

assign end_of_file_signal_neg = (end_of_file_signal_d) & (~end_of_file_signal);
always @(posedge clk or posedge rst) begin
    if (rst) end_of_file_signal_d <= 0;
    else end_of_file_signal_d <= end_of_file_signal;
end

assign enable_pos = (enable) & (~enable_d);
always @(posedge clk or posedge rst) begin
    if (rst) enable_d <= 0;
    else enable_d <= enable;
end

always @(posedge clk or posedge rst) begin
    if(rst) begin
        state <= 0;
        JPEG_bitstream <= 0;
        data_ready <= 0;
        eof_data_partial_ready <= 0;
    end else begin
        case(state)
            3'd0: begin //wait
                JPEG_bitstream <= 0;
                data_ready <= 0;
                eof_data_partial_ready <= 0;
                if(enable) state <= 3'd1;
                else state <= state;
            end
            3'd1: begin //trans
                JPEG_bitstream <= ((JPEG_out_count == 0) && (once_enable_count != 8'hFF)) ? (JPEG_bitstream + 1) : (JPEG_bitstream);
                data_ready <= ((JPEG_out_count == 0) && (once_enable_count != 8'hFF)) ? (1) : (0);
                eof_data_partial_ready <= 0;
                if(end_of_file_signal_neg) state <= 3'd2;
                else state <= state;
            end
            3'd2: begin //outside is stop, still trans little bit
                JPEG_bitstream <= ((JPEG_out_count == 0) && (once_enable_count != 8'hFF)) ? (JPEG_bitstream + 1) : (JPEG_bitstream);
                data_ready <= ((JPEG_out_count == 0) && (once_enable_count != 8'hFF)) ? (1) : (0);
                eof_data_partial_ready <= 0;
                if(behind_trans_over) state <= 3'd3;
                else state <= state;
            end
            3'd3: begin //stop
                JPEG_bitstream <= (32'hFF00FF00);
                data_ready <= 0;
                eof_data_partial_ready <= 1;
                state <= 3'd0;
            end
        endcase
    end
end



assign end_of_file_bitstream_count = 0; // Fake output for end of file bitstream count
assign Y_Quantizer = 0;
assign CB_Quantizer = 0;
assign CR_Quantizer = 0;



 endmodule