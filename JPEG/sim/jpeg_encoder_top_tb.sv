`timescale 1ps / 1ps

module jpeg_encoder_top_tb;

// Include auto-generated parameters
`include "output/testbench_params.v"

// Signal declarations
reg clk;
reg rstn;
reg frame_done;
reg [11:0] pixel_x;
reg [11:0] pixel_y;

// Burst interface signals
wire wr_data_burst_valid;
reg wr_data_burst_ready;
wire [7:0] wr_data_burst;
reg wr_data_valid;
wire wr_data_ready;
reg [31:0] wr_data;
wire wr_data_last;

// JPEG output signals
wire [31:0] bitstream_size;
wire [31:0] JPEG_bitstream;
wire jpeg_enoder_data_ready;
wire [4:0] end_of_file_bitstream_count;
wire eof_data_partial_ready;

// Control variables
integer current_image;
integer current_width, current_height;
integer pixel_count;
integer total_pixels;
integer loop_var;

// Data transmission variables - simplified
integer global_pixel_offset;
integer current_pixel_idx;
reg data_sending_active;

// Dynamic pixel memory - now 32-bit per pixel
reg [31:0] pixel_memory [0:TOTAL_PIXELS-1];

// Image processing control
reg start_new_image;

// Other variables
integer file_handle;
integer output_file;
reg data_loading_done;
reg frame_started;
reg encoding_complete;
reg waiting_for_ready;

// Unit Under Test - 使用新的顶层模块
jpeg_encoder_top UUT (
    .clk(clk),
    .rstn(rstn),
    .frame_done(frame_done),
    .pixel_x(pixel_x),
    .pixel_y(pixel_y),
    
    // Burst interface
    .wr_data_burst_valid(wr_data_burst_valid),
    .wr_data_burst_ready(wr_data_burst_ready),
    .wr_data_burst(wr_data_burst),
    .wr_data_valid(wr_data_valid),
    .wr_data_ready(wr_data_ready),
    .wr_data(wr_data),
    .wr_data_last(wr_data_last),

    // JPEG output
    .bitstream_size(bitstream_size),
    .JPEG_bitstream(JPEG_bitstream),
    .jpeg_enoder_data_ready(jpeg_enoder_data_ready),
    .end_of_file_bitstream_count(end_of_file_bitstream_count),
    .eof_data_partial_ready(eof_data_partial_ready)
);

// Clock generation
initial clk = 0;
always #5000 clk = ~clk;

// Simple data transmission - just send packed 32-bit data directly
initial begin
    wr_data_burst_ready = 1'b1;  // Always ready for burst
    wr_data_valid = 1'b1;        // Always valid
end

// Direct assignment - send current 32-bit word from memory
assign wr_data = pixel_memory[current_pixel_idx];

int last_count;
always @(posedge clk) begin
    if(~rstn) begin
        last_count <= 255;
    end else if(wr_data_valid && wr_data_ready) begin
        last_count <= last_count - 1; // Decrement count on valid data
    end else if(last_count == 0) last_count <= 255;
    else last_count <= last_count; // Maintain count if not valid
end
assign wr_data_last = (last_count == 0); // Last data when count reaches zero

// Counter increment on successful handshake
always @(posedge clk) begin
    if(~rstn) begin
        current_pixel_idx <= 0;
        data_sending_active <= 1'b0;
    end else begin
        if (start_new_image) begin
            // Calculate starting position for current image
            global_pixel_offset = 0;
            for (loop_var = 0; loop_var < current_image; loop_var = loop_var + 1) begin
                global_pixel_offset = global_pixel_offset + (get_image_width(loop_var) * get_image_height(loop_var));
            end
            // Convert pixel count to word count (3 words per 4 pixels)
            current_pixel_idx <= global_pixel_offset;
            data_sending_active <= 1'b1;
        end else if (wr_data_valid && wr_data_ready && data_sending_active) begin
            // Check if we've sent all words for current image
            if (current_pixel_idx < global_pixel_offset + (total_pixels + 1)) begin
                current_pixel_idx <= current_pixel_idx + 1;
            end else begin
                data_sending_active <= 1'b0; // Current image complete
            end
        end
    end
end

// Dynamic image dimension functions using parameter arrays
function integer get_image_width(input integer img_idx);
begin
    if (img_idx >= 0 && img_idx < NUM_IMAGES) begin
        get_image_width = IMAGE_WIDTHS[img_idx];
    end else begin
        get_image_width = 0;
    end
end
endfunction

function integer get_image_height(input integer img_idx);
begin
    if (img_idx >= 0 && img_idx < NUM_IMAGES) begin
        get_image_height = IMAGE_HEIGHTS[img_idx];
    end else begin
        get_image_height = 0;
    end
end
endfunction

// Read hex file and load all pixel data for batch processing
task load_batch_hex_file;
    input [256*8-1:0] filename;
    integer i;
    integer rgb_value;
    integer status;
begin
    file_handle = $fopen(filename, "r");
    if (file_handle == 0) begin
        $display("Error: Cannot open file %s", filename);
        $finish;
    end
    
    $display("Loading batch pixel data from file %s...", filename);
    $display("Memory allocated for %d pixels across %d images", TOTAL_PIXELS, NUM_IMAGES);
    
    i = 0;
    while (!$feof(file_handle) && i < TOTAL_PIXELS) begin
        status = $fscanf(file_handle, "%h", rgb_value);
        if (status == 1) begin
            pixel_memory[i] = rgb_value[31:0]; // Now loading 32-bit packed data
            i = i + 1;
        end
    end
    
    $fclose(file_handle);
    $display("Loaded %d pixels from batch file", i);
    
    if (i != TOTAL_PIXELS) begin
        $display("Warning: Expected %d pixels, but only loaded %d", TOTAL_PIXELS, i);
    end
end
endtask

// Main test sequence - simplified without tasks
initial begin : STIMUL
    // Initialize signals
    rstn = 1'b0;
    frame_done = 1'b0;
    pixel_x = 0;
    pixel_y = 0;
    current_image = 0;
    
    // Open output file
    output_file = $fopen("output/jpeg_output_hex.txt", "w");
    if (output_file == 0) begin
        $display("Error: Cannot create output file");
        $finish;
    end
    
    $display("JPEG batch encoder test started");
    $display("Number of images to process: %d", NUM_IMAGES);
    
    // Load batch hex file data
    load_batch_hex_file("output/ja_pixels.txt");
    
    // Reset release
    #10000;
    rstn = 1'b1;
    #5000;
    
    // Process each image in sequence
    for (current_image = 0; current_image < NUM_IMAGES; current_image = current_image + 1) begin
        current_width = get_image_width(current_image);
        current_height = get_image_height(current_image);
        total_pixels = current_width * current_height;
        
        $display("\n=== Processing Image %d ===", current_image + 1);
        $display("Image size: %dx%d", current_width, current_height);
        $display("Total pixels: %d", total_pixels);
        
        // Send frame start signal with current image dimensions
        @(posedge clk);
        frame_done = 1'b1;
        pixel_x = current_width;
        pixel_y = current_height;
        @(posedge clk);
        frame_done = 1'b0;
        
        // Start data transmission
        @(posedge clk);
        start_new_image = 1'b1;
        @(posedge clk);
        start_new_image = 1'b0;
        
        // Wait for data transmission to complete
        while (data_sending_active) begin
            @(posedge clk);
        end
        
        // Wait for encoding to complete
        while (!eof_data_partial_ready) begin
            @(posedge clk);
        end
        
        $display("Image %d encoding completed", current_image + 1);
        $display("Total pixels sent: %d", current_pixel_idx - global_pixel_offset);
        
        // Small delay between images
        repeat(100) @(posedge clk);
    end
    
    $display("All images processed successfully!");
end

// JPEG output monitoring and logging
always @(posedge clk) begin
    if (jpeg_enoder_data_ready == 1'b1) begin
        // Write output to file and display
        $fwrite(output_file, "%08h\n", JPEG_bitstream);
        // $display("JPEG output: %08h", JPEG_bitstream);
    end
    
    // Handle partial data output - mark end of each image
    if (eof_data_partial_ready) begin
        // Output the full 32-bit value as 8-digit hex
        $fwrite(output_file, "%08h\n", JPEG_bitstream);
        // Add a comment line indicating the number of valid bits
        $fwrite(output_file, "// Valid bits in above data: %d\n", end_of_file_bitstream_count);
        $fwrite(output_file, "// End of Image %d\n", current_image + 1);
        $fwrite(output_file, "// Bitstream size: %d words\n", bitstream_size);
        $display("Partial JPEG data (%d bits): %08h", end_of_file_bitstream_count, JPEG_bitstream);
        $display("Image %d encoding completed!", current_image + 1);
        $display("Total bitstream size: %d words", bitstream_size);
        if(current_image == NUM_IMAGES - 1) begin
            $display("\n=== All %d images processed successfully ===", NUM_IMAGES);
            $fclose(output_file);
            #2000;
            $finish;
        end
    end
end


reg grs_n;
GTP_GRS GRS_INST(.GRS_N (grs_n));
initial begin
grs_n = 1'b0;
#5 grs_n = 1'b1;
end


endmodule
