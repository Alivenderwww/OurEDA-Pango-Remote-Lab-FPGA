`timescale 1ps / 1ps

module jpeg_encoder_top_tb;

// Include auto-generated parameters
`include "output/testbench_params.v"

// Signal declarations
reg clk;
reg jpeg_encoder_clk;
reg rstn;
reg frame_done;
reg [11:0] pixel_x;
reg [11:0] pixel_y;
reg data_in_enable;
reg [23:0] data_in;

wire [31:0] JPEG_bitstream;
wire jpeg_enoder_data_ready;
wire [4:0] end_of_file_bitstream_count;
wire eof_data_partial_ready;

// Control variables
integer current_image;
integer current_width, current_height;
integer pixel_count;
integer total_pixels;
integer loop_var; // 用于循环的变量

// Dynamic pixel memory - sized exactly to what we need
reg [23:0] pixel_memory [0:TOTAL_PIXELS-1];

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
    .data_in_enable(data_in_enable),
    .data_in(data_in),

    .jpeg_encoder_clk(jpeg_encoder_clk),
    .JPEG_bitstream(JPEG_bitstream),
    .jpeg_enoder_data_ready(jpeg_enoder_data_ready),
    .end_of_file_bitstream_count(end_of_file_bitstream_count),
    .eof_data_partial_ready(eof_data_partial_ready)
);

// Clock generation
initial clk = 0;
always #5000 clk = ~clk;
initial jpeg_encoder_clk = 0;
always #2000 jpeg_encoder_clk = ~jpeg_encoder_clk;

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
            pixel_memory[i] = rgb_value[23:0];
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

// Main test sequence for batch processing
initial begin : STIMUL
    // Initialize signals
    rstn = 1'b0;
    frame_done = 1'b0;
    pixel_x = 0;
    pixel_y = 0;
    data_in_enable = 1'b0;
    data_in = 24'h000000;
    pixel_count = 0;
    data_loading_done = 1'b0;
    frame_started = 1'b0;
    current_image = 0;
    encoding_complete = 1'b0;
    waiting_for_ready = 1'b0;
    
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
    data_loading_done = 1'b1;
    
    // Reset release
    #10000;
    rstn = 1'b1;
    #5000;
    
    // Process each image in sequence
    process_batch_images();
    
    $display("All images processed successfully!");
end

// Task to process all images in batch
task process_batch_images;
    integer img_idx;
begin
    for (img_idx = 0; img_idx < NUM_IMAGES; img_idx = img_idx + 1) begin
        current_image = img_idx;
        current_width = get_image_width(img_idx);
        current_height = get_image_height(img_idx);
        total_pixels = current_width * current_height;
        
        $display("\n=== Processing Image %d ===", img_idx + 1);
        $display("Image size: %dx%d", current_width, current_height);
        $display("Total pixels: %d", total_pixels);
        
        // Send frame start signal with current image dimensions
        @(posedge clk);
        frame_done <= 1'b1;
        pixel_x <= current_width;
        pixel_y <= current_height;
        @(posedge clk);
        frame_done <= 1'b0;
        frame_started <= 1'b1;
        
        // Send pixel data for current image
        send_current_image_data();
        
        // Wait for encoding to complete
        wait_for_encoding_complete();
        
        $display("Image %d encoding completed", img_idx + 1);
        
        // Small delay between images
        repeat(100) @(posedge clk);
    end
end
endtask

// Task to send pixel data for current image
task send_current_image_data;
    integer row, col, pixel_idx;
    integer pixels_sent_for_current_image;
    integer global_pixel_offset;
begin
    $display("Starting to send pixel data for image %d...", current_image + 1);
    
    // 等待几个时钟周期让模块准备好
    repeat(10) @(posedge clk);
    
    pixels_sent_for_current_image = 0;
    
    // 计算当前图片在全局pixel_memory中的起始位置
    global_pixel_offset = 0;
    for (loop_var = 0; loop_var < current_image; loop_var = loop_var + 1) begin
        global_pixel_offset = global_pixel_offset + (get_image_width(loop_var) * get_image_height(loop_var));
    end
    
    // 按行扫描发送像素数据
    for (row = 0; row < current_height; row = row + 1) begin
        for (col = 0; col < current_width; col = col + 1) begin
            pixel_idx = global_pixel_offset + (row * current_width + col);
            
            @(posedge clk) begin
                data_in <= pixel_memory[pixel_idx];
                data_in_enable <= 1'b1;
                pixels_sent_for_current_image <= pixels_sent_for_current_image + 1;
            end
            
            // 每隔一段时间显示进度
            if (pixels_sent_for_current_image % 5000 == 0) begin
                $display("Sent %d/%d pixels (%d%%) for image %d", 
                        pixels_sent_for_current_image, total_pixels, 
                        (pixels_sent_for_current_image * 100) / total_pixels, 
                        current_image + 1);
            end
        end
    end
    
    // 结束数据发送
    @(posedge clk) begin
        data_in_enable <= 1'b0;
    end
    
    $display("Finished sending all %d pixels for image %d", pixels_sent_for_current_image, current_image + 1);
    waiting_for_ready <= 1'b1;
end
endtask

// Task to wait for encoding completion
task wait_for_encoding_complete;
begin
    $display("Waiting for image %d encoding to complete...", current_image + 1);
    encoding_complete = 1'b0;
    
    // Wait for the encoding to complete (detected by eof_data_partial_ready)
    while (!eof_data_partial_ready) begin
        @(posedge jpeg_encoder_clk);
    end
    
    // Wait for one more clock cycle to ensure data is stable
    @(posedge jpeg_encoder_clk);
    
    waiting_for_ready <= 1'b0;
    encoding_complete = 1'b1;
    $display("Image %d encoding completed successfully", current_image + 1);
end
endtask

// JPEG output monitoring and logging
always @(posedge jpeg_encoder_clk) begin
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
        $display("Partial JPEG data (%d bits): %08h", end_of_file_bitstream_count, JPEG_bitstream);
        $display("Image %d encoding completed!", current_image + 1);
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
