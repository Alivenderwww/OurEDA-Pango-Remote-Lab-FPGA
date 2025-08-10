/////////////////////////////////////////////////////////////////////
////                                                             ////
////  JPEG Encoder Core - Verilog Testbench (Modified)          ////
////                                                             ////
////  Modified to support hex file input and output logging     ////
////  Original Author: David Lundgren                           ////
////          davidklun@gmail.com                                ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

`timescale 1ps / 1ps

module jpeg_top_tb_hex;

// Parameters for image dimensions (must be multiples of 8)
parameter IMAGE_WIDTH = 592;   // Modify to your image width
parameter IMAGE_HEIGHT = 440;  // Modify to your image height
parameter BLOCKS_PER_ROW = IMAGE_WIDTH / 8;
parameter BLOCKS_PER_COL = IMAGE_HEIGHT / 8;
parameter TOTAL_BLOCKS = BLOCKS_PER_ROW * BLOCKS_PER_COL;
parameter PIXELS_PER_BLOCK = 64;

// Signal declarations
reg end_of_file_signal;
reg [23:0]data_in;
reg clk;
reg rst;
reg enable;
wire [31:0]JPEG_bitstream;
wire data_ready;
wire [4:0]end_of_file_bitstream_count;
wire eof_data_partial_ready;

// Counters and control signals
integer pixel_count;
integer block_count;
integer delay_count;
reg [23:0] pixel_memory [0:TOTAL_BLOCKS*PIXELS_PER_BLOCK-1]; // Store all pixel data
integer file_handle;
integer output_file;
reg data_loading_done;

// Unit Under Test 
jpeg_top UUT (
    .end_of_file_signal(end_of_file_signal),
    .data_in(data_in),
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .JPEG_bitstream(JPEG_bitstream),
    .data_ready(data_ready),
    .end_of_file_bitstream_count(end_of_file_bitstream_count),
    .eof_data_partial_ready(eof_data_partial_ready)
);

// Clock generation
always begin
    clk = 1'b0;
    #5000; // 5ns
    clk = 1'b1;
    #5000; // 5ns
end

// Read hex file and load pixel data
task load_hex_file;
    input [256*8-1:0] filename; // File name string
    integer i;
    integer rgb_value;
    integer status;
begin
    file_handle = $fopen(filename, "r");
    if (file_handle == 0) begin
        $display("Error: Cannot open file %s", filename);
        $finish;
    end
    
    $display("Loading pixel data from file %s...", filename);
    i = 0;
    
    while (!$feof(file_handle) && i < TOTAL_BLOCKS*PIXELS_PER_BLOCK) begin
        status = $fscanf(file_handle, "%h", rgb_value);
        if (status == 1) begin
            pixel_memory[i] = rgb_value[23:0];
            i = i + 1;
        end
    end
    
    $fclose(file_handle);
    $display("Loaded %d pixels", i);
    
    if (i != TOTAL_BLOCKS*PIXELS_PER_BLOCK) begin
        $display("Warning: Expected %d pixels, but only loaded %d", TOTAL_BLOCKS*PIXELS_PER_BLOCK, i);
    end
end
endtask

// Main test sequence
initial begin : STIMUL
    // Initialize signals
    rst = 1'b1;
    enable = 1'b0;
    end_of_file_signal = 1'b0;
    pixel_count = 0;
    block_count = 0;
    delay_count = 0;
    data_loading_done = 1'b0;
    
    // Open output file
    output_file = $fopen("../sim/output/jpeg_output_hex.txt", "w");
    if (output_file == 0) begin
        $display("Error: Cannot create output file");
        $finish;
    end
    
    $display("JPEG encoder test started");
    $display("Image size: %dx%d", IMAGE_WIDTH, IMAGE_HEIGHT);
    $display("8x8 blocks: %d (%dx%d)", TOTAL_BLOCKS, BLOCKS_PER_ROW, BLOCKS_PER_COL);
    
    // Load hex file data (simple hex format)
    load_hex_file("../sim/output/ja_pixels.txt");
    data_loading_done = 1'b1;
    
    // Reset
    #10000;
    rst = 1'b0;
    
    // Start sending pixel data
    send_pixel_data();
    
    // Wait for final processing to complete
    // The simulation will auto-terminate when eof_data_partial_ready is detected
    $display("Waiting for JPEG encoding to complete...");
end

// Task to send pixel data
task send_pixel_data;
    integer block_idx, pixel_idx, total_idx;
begin
    for (block_idx = 0; block_idx < TOTAL_BLOCKS; block_idx = block_idx + 1) begin
        // $display("Processing block %d/%d", block_idx + 1, TOTAL_BLOCKS);
        
        for (pixel_idx = 0; pixel_idx < PIXELS_PER_BLOCK; pixel_idx = pixel_idx + 1) begin
            total_idx = block_idx * PIXELS_PER_BLOCK + pixel_idx;
            @(negedge clk) begin
                data_in <= pixel_memory[total_idx];
                enable <= 1'b1;
                if(block_idx == TOTAL_BLOCKS - 1) end_of_file_signal = 1'b1;
            end
            // $display("Sending pixel %d: %h", total_idx, pixel_memory[total_idx]);
        end
        
        // After sending 8x8 block, handle enable timing for next block (except last block)
        if (block_idx < TOTAL_BLOCKS - 1) begin
            // Keep enable high for at least 13 cycles (processing time)
            repeat(50) @(negedge clk);
            @(negedge clk) enable <= 1'b0;
        end
    end
    
    // Keep enable high for final processing, then disable
    repeat(50) @(negedge clk);  // Allow final block to process
    @(negedge clk) begin
        enable <= 1'b0;
        end_of_file_signal <= 1'b0;
    end
end
endtask

// JPEG output monitoring and logging
always @(posedge clk) begin
    if (data_ready == 1'b1) begin
        // Write output to file and display
        $fwrite(output_file, "%08h\n", JPEG_bitstream);
        // $display("JPEG output: %08h", JPEG_bitstream);
    end
    
    // Handle partial data output
    if (eof_data_partial_ready == 1'b1) begin
        // Output the full 32-bit value as 8-digit hex
        $fwrite(output_file, "%08h\n", JPEG_bitstream);
        // Add a comment line indicating the number of valid bits
        $fwrite(output_file, "// Valid bits in above data: %d\n", end_of_file_bitstream_count);
        $display("Partial JPEG data (%d bits): %08h", end_of_file_bitstream_count, JPEG_bitstream);
        
        // JPEG encoding completed, stop simulation
        $display("JPEG encoding completed successfully!");
        $display("Final partial data contains %d valid bits", end_of_file_bitstream_count);
        $fclose(output_file);
        #1000; // Small delay to ensure all writes complete
        $finish;
    end
end

// Debug monitoring
always @(posedge clk) begin
    if (rst == 1'b0 && enable == 1'b1) begin
        // $display("Time %t: enable=%b, data_in=%h, data_ready=%b", $time, enable, data_in, data_ready);
    end
end

// Simulation status monitoring
always @(posedge clk) begin
    if (rst == 1'b0 && data_loading_done == 1'b1) begin
        // You can add extra monitoring logic here
    end
end

endmodule
