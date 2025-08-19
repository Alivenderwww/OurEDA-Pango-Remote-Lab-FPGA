`timescale 1ns / 10 fs 
module hdmi_in_with_jpeg_sim ();

localparam M_WIDTH  = 2;
localparam S_WIDTH  = 1;
localparam M_ID     = 2;
localparam [0:(2**S_WIDTH-1)][31:0] START_ADDR = '{32'h00000000, 32'h10000000};
localparam [0:(2**S_WIDTH-1)][31:0]   END_ADDR = '{32'h0FFFFFFF, 32'h1FFFFFFF};

wire [(2**M_WIDTH-1):0]            M_CLK          ;
wire [(2**M_WIDTH-1):0]            M_RSTN         ;
wire [(2**M_WIDTH-1):0] [M_ID-1:0] M_WR_ADDR_ID   ;
wire [(2**M_WIDTH-1):0] [31:0]     M_WR_ADDR      ;
wire [(2**M_WIDTH-1):0] [ 7:0]     M_WR_ADDR_LEN  ;
wire [(2**M_WIDTH-1):0] [ 1:0]     M_WR_ADDR_BURST;
wire [(2**M_WIDTH-1):0]            M_WR_ADDR_VALID;
wire [(2**M_WIDTH-1):0]            M_WR_ADDR_READY;
wire [(2**M_WIDTH-1):0] [31:0]     M_WR_DATA      ;
wire [(2**M_WIDTH-1):0] [ 3:0]     M_WR_STRB      ;
wire [(2**M_WIDTH-1):0]            M_WR_DATA_LAST ;
wire [(2**M_WIDTH-1):0]            M_WR_DATA_VALID;
wire [(2**M_WIDTH-1):0]            M_WR_DATA_READY;
wire [(2**M_WIDTH-1):0] [M_ID-1:0] M_WR_BACK_ID   ;
wire [(2**M_WIDTH-1):0] [ 1:0]     M_WR_BACK_RESP ;
wire [(2**M_WIDTH-1):0]            M_WR_BACK_VALID;
wire [(2**M_WIDTH-1):0]            M_WR_BACK_READY;
wire [(2**M_WIDTH-1):0] [M_ID-1:0] M_RD_ADDR_ID   ;
wire [(2**M_WIDTH-1):0] [31:0]     M_RD_ADDR      ;
wire [(2**M_WIDTH-1):0] [ 7:0]     M_RD_ADDR_LEN  ;
wire [(2**M_WIDTH-1):0] [ 1:0]     M_RD_ADDR_BURST;
wire [(2**M_WIDTH-1):0]            M_RD_ADDR_VALID;
wire [(2**M_WIDTH-1):0]            M_RD_ADDR_READY;
wire [(2**M_WIDTH-1):0] [M_ID-1:0] M_RD_BACK_ID   ;
wire [(2**M_WIDTH-1):0] [31:0]     M_RD_DATA      ;
wire [(2**M_WIDTH-1):0] [ 1:0]     M_RD_DATA_RESP ;
wire [(2**M_WIDTH-1):0]            M_RD_DATA_LAST ;
wire [(2**M_WIDTH-1):0]            M_RD_DATA_VALID;
wire [(2**M_WIDTH-1):0]            M_RD_DATA_READY;

wire [(2**S_WIDTH-1):0]                    S_CLK          ;
wire [(2**S_WIDTH-1):0]                    S_RSTN         ;
wire [(2**S_WIDTH-1):0] [M_ID+M_WIDTH-1:0] S_WR_ADDR_ID   ;
wire [(2**S_WIDTH-1):0] [31:0]             S_WR_ADDR      ;
wire [(2**S_WIDTH-1):0] [ 7:0]             S_WR_ADDR_LEN  ;
wire [(2**S_WIDTH-1):0] [ 1:0]             S_WR_ADDR_BURST;
wire [(2**S_WIDTH-1):0]                    S_WR_ADDR_VALID;
wire [(2**S_WIDTH-1):0]                    S_WR_ADDR_READY;
wire [(2**S_WIDTH-1):0] [31:0]             S_WR_DATA      ;
wire [(2**S_WIDTH-1):0] [ 3:0]             S_WR_STRB      ;
wire [(2**S_WIDTH-1):0]                    S_WR_DATA_LAST ;
wire [(2**S_WIDTH-1):0]                    S_WR_DATA_VALID;
wire [(2**S_WIDTH-1):0]                    S_WR_DATA_READY;
wire [(2**S_WIDTH-1):0] [M_ID+M_WIDTH-1:0] S_WR_BACK_ID   ;
wire [(2**S_WIDTH-1):0] [ 1:0]             S_WR_BACK_RESP ;
wire [(2**S_WIDTH-1):0]                    S_WR_BACK_VALID;
wire [(2**S_WIDTH-1):0]                    S_WR_BACK_READY;
wire [(2**S_WIDTH-1):0] [M_ID+M_WIDTH-1:0] S_RD_ADDR_ID   ;
wire [(2**S_WIDTH-1):0] [31:0]             S_RD_ADDR      ;
wire [(2**S_WIDTH-1):0] [ 7:0]             S_RD_ADDR_LEN  ;
wire [(2**S_WIDTH-1):0] [ 1:0]             S_RD_ADDR_BURST;
wire [(2**S_WIDTH-1):0]                    S_RD_ADDR_VALID;
wire [(2**S_WIDTH-1):0]                    S_RD_ADDR_READY;
wire [(2**S_WIDTH-1):0] [M_ID+M_WIDTH-1:0] S_RD_BACK_ID   ;
wire [(2**S_WIDTH-1):0] [31:0]             S_RD_DATA      ;
wire [(2**S_WIDTH-1):0] [ 1:0]             S_RD_DATA_RESP ;
wire [(2**S_WIDTH-1):0]                    S_RD_DATA_LAST ;
wire [(2**S_WIDTH-1):0]                    S_RD_DATA_VALID;
wire [(2**S_WIDTH-1):0]                    S_RD_DATA_READY;

// 新的寄存器地址定义
localparam [31:0]
    ADDR_CAPTURE_RD_CTRL        = 32'h1000_0000,
    ADDR_CAPTURE_WR_CTRL        = 32'h1000_0001,

    ADDR_START_WRITE_ADDR0      = 32'h1000_0002,
    ADDR_END_WRITE_ADDR0        = 32'h1000_0003,
    ADDR_START_WRITE_ADDR1      = 32'h1000_0004,
    ADDR_END_WRITE_ADDR1        = 32'h1000_0005,
    ADDR_START_READ_ADDR0       = 32'h1000_0006,
    ADDR_END_READ_ADDR0         = 32'h1000_0007,

    ADDR_HDMI_NOTREADY          = 32'h1000_0008,
    ADDR_HDMI_HEIGHT_WIDTH      = 32'h1000_0009,

    ADDR_JPEG_HEIGHT_WIDTH      = 32'h1000_000A,
    ADDR_JPEG_ADD_NEED_FRAME_NUM= 32'h1000_000B,
    ADDR_JPEG_FRAME_SAVE_NUM    = 32'h1000_000C,
    ADDR_FIFO_FRAME_INFO        = 32'h1000_000D;

wire [0:(2**M_WIDTH-1)] [4:0] M_fifo_empty_flag;
wire [0:(2**S_WIDTH-1)] [4:0] S_fifo_empty_flag;

// HDMI video stream signals
reg         hdmi_in_clk;
reg         hdmi_in_rstn;
reg         hdmi_in_hsync;
reg         hdmi_in_vsync;
reg [23:0]  hdmi_in_rgb;
reg         hdmi_in_de;

// HDMI control variables
reg         hdmi_enable;
reg [11:0]  hdmi_frame_width;
reg [11:0]  hdmi_frame_height;
reg [31:0]  hdmi_pixel_count;

// Hex file reader variables - DYNAMIC PARAMETERS (Updated by Python script)
parameter VIDEO_WIDTH = 640;    // Python script will update this
parameter VIDEO_HEIGHT = 480;   // Python script will update this  
parameter VIDEO_TOTAL_PIXELS = 307200; // Python script will update this

reg [23:0] video_hex_data [0:VIDEO_TOTAL_PIXELS-1]; // Dynamic array size
integer hex_pixel_index = 0;
integer total_hex_pixels = 0;
integer frame_pixel_count = 0; // 单帧像素数量
reg hex_file_loaded = 0;

// HDMI timing parameters for 1080p60Hz
localparam  H_SYNC_PULSE = 44;    // 水平同步脉冲
localparam  H_BACK_PORCH = 148;   // 水平后沿
localparam  H_FRONT_PORCH = 88;   // 水平前沿
localparam  V_SYNC_PULSE = 5;     // 垂直同步脉冲
localparam  V_BACK_PORCH = 36;    // 垂直后沿
localparam  V_FRONT_PORCH = 4;    // 垂直前沿

// Digital input signal (from original code)
reg [31:0]  digital_in;

reg  BUS_CLK    ;
reg  ddr_ref_clk;
reg  BUS_RSTN   ;

// Clock generation
always #10 ddr_ref_clk = ~ddr_ref_clk;           // 33.33MHz bus clock
always #8 BUS_CLK = ~BUS_CLK;           // 33.33MHz bus clock
always #8 hdmi_in_clk = ~hdmi_in_clk; // 148.5MHz HDMI pixel clock for 1080p60Hz

initial begin
    // Initialize clocks
    BUS_CLK = 0;
    ddr_ref_clk = 0;
    hdmi_in_clk = 0;
    
    // Initialize reset signals
    BUS_RSTN = 0;
    hdmi_in_rstn = 0;
    
    // Initialize HDMI control signals
    hdmi_enable = 0;
    hdmi_frame_width = VIDEO_WIDTH;   // Use dynamic parameter
    hdmi_frame_height = VIDEO_HEIGHT; // Use dynamic parameter  
    
    // Initialize HDMI video signals
    hdmi_in_hsync = 0;
    hdmi_in_vsync = 0;
    hdmi_in_rgb = 24'h000000;
    hdmi_in_de = 0;
    
    // Initialize counters
    hdmi_pixel_count = 0;
    hex_pixel_index = 0;
    frame_pixel_count = hdmi_frame_width * hdmi_frame_height; // 计算单帧像素数量
    
    // Release resets after some time
    #5000000 BUS_RSTN = 1;
    #51000 hdmi_in_rstn = 1;
end

// 读取hex文件的初始化任务
initial begin
    integer file_handle, scan_result;
    integer pixel_count = 0;
    reg [23:0] pixel_data;
    string line;
    
    // 等待复位释放
    wait(hdmi_in_rstn);
    #1000;
    
    file_handle = $fopen("../output/video_data.hex", "r");
    if (file_handle == 0) begin
        $display("Warning: Cannot open video_data.hex file, using default test pattern");
        hex_file_loaded = 0;
    end else begin
        $display("Loading video hex data...");
        $display("Frame size: %dx%d = %d pixels", hdmi_frame_width, hdmi_frame_height, frame_pixel_count);
        
        // 读取hex数据
        while (!$feof(file_handle) && pixel_count < VIDEO_TOTAL_PIXELS) begin
            scan_result = $fgets(line, file_handle);
            if (scan_result > 0) begin
                scan_result = $sscanf(line, "%h", pixel_data);
                if (scan_result == 1) begin
                    video_hex_data[pixel_count] = pixel_data;
                    pixel_count = pixel_count + 1;
                end
            end
        end
        
        $fclose(file_handle);
        total_hex_pixels = pixel_count;
        hex_file_loaded = 1;
        
        $display("Video hex data loaded: %d pixels", total_hex_pixels);
        if (total_hex_pixels >= frame_pixel_count) begin
            $display("Sufficient data for %d complete frames", total_hex_pixels / frame_pixel_count);
        end else begin
            $display("Warning: Only partial frame data available");
        end
    end
end

initial begin
    #300 M0.set_clk(5);
    #300 M2.set_clk(5);
    #300 M3.set_clk(5);
    #5000
    #300 M0.set_rd_data_channel(31);
    #300 M0.set_wr_data_channel(31);
    #300 M2.set_rd_data_channel(31);
    #300 M2.set_wr_data_channel(31);
    #300 M3.set_rd_data_channel(31);
    #300 M3.set_wr_data_channel(31);
    
    // 等待系统初始化
    wait(hdmi_in_rstn && BUS_RSTN && S_RSTN[0] && S_RSTN[1]);
    repeat(100) @(posedge BUS_CLK);
    
    $display("[%t] Starting HDMI and JPEG system test", $time);
    $display("=== HDMI Dynamic Video Timing Parameters ===");
    $display("  Horizontal: Active=%d, Front=%d, Sync=%d, Back=%d, Total=%d", 
             VIDEO_WIDTH, H_FRONT_PORCH, H_SYNC_PULSE, H_BACK_PORCH, 
             VIDEO_WIDTH + H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH);
    $display("  Vertical: Active=%d, Front=%d, Sync=%d, Back=%d, Total=%d", 
             VIDEO_HEIGHT, V_FRONT_PORCH, V_SYNC_PULSE, V_BACK_PORCH, 
             VIDEO_HEIGHT + V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH);
    $display("  Pixel Clock: 148.5MHz (period = 6.734ns)");
    $display("=== HDMI Signal Definition ===");
    $display("  - DE high: RGB data valid");
    $display("  - VSYNC high: New frame start");
    $display("  - HSYNC high: New line start");
    $display("==========================================");
    
    // 执行HDMI AXI Slave配置序列
    hdmi_axi_slave_test_sequence();
    
    $display("[%t] All HDMI and AXI tests completed", $time);
end

axi_master_sim #(
	.ID_WIDTH(M_ID)
)M0(
.MASTER_CLK          (M_CLK          [0]),
.MASTER_RSTN         (M_RSTN         [0]),
.MASTER_WR_ADDR_ID   (M_WR_ADDR_ID   [0]),
.MASTER_WR_ADDR      (M_WR_ADDR      [0]),
.MASTER_WR_ADDR_LEN  (M_WR_ADDR_LEN  [0]),
.MASTER_WR_ADDR_BURST(M_WR_ADDR_BURST[0]),
.MASTER_WR_ADDR_VALID(M_WR_ADDR_VALID[0]),
.MASTER_WR_ADDR_READY(M_WR_ADDR_READY[0]),
.MASTER_WR_DATA      (M_WR_DATA      [0]),
.MASTER_WR_STRB      (M_WR_STRB      [0]),
.MASTER_WR_DATA_LAST (M_WR_DATA_LAST [0]),
.MASTER_WR_DATA_VALID(M_WR_DATA_VALID[0]),
.MASTER_WR_DATA_READY(M_WR_DATA_READY[0]),
.MASTER_WR_BACK_ID   (M_WR_BACK_ID   [0]),
.MASTER_WR_BACK_RESP (M_WR_BACK_RESP [0]),
.MASTER_WR_BACK_VALID(M_WR_BACK_VALID[0]),
.MASTER_WR_BACK_READY(M_WR_BACK_READY[0]),
.MASTER_RD_ADDR_ID   (M_RD_ADDR_ID   [0]),
.MASTER_RD_ADDR      (M_RD_ADDR      [0]),
.MASTER_RD_ADDR_LEN  (M_RD_ADDR_LEN  [0]),
.MASTER_RD_ADDR_BURST(M_RD_ADDR_BURST[0]),
.MASTER_RD_ADDR_VALID(M_RD_ADDR_VALID[0]),
.MASTER_RD_ADDR_READY(M_RD_ADDR_READY[0]),
.MASTER_RD_BACK_ID   (M_RD_BACK_ID   [0]),
.MASTER_RD_DATA      (M_RD_DATA      [0]),
.MASTER_RD_DATA_RESP (M_RD_DATA_RESP [0]),
.MASTER_RD_DATA_LAST (M_RD_DATA_LAST [0]),
.MASTER_RD_DATA_VALID(M_RD_DATA_VALID[0]),
.MASTER_RD_DATA_READY(M_RD_DATA_READY[0])
);

axi_master_sim #(
	.ID_WIDTH(M_ID)
)M2(
.MASTER_CLK          (M_CLK          [2]),
.MASTER_RSTN         (M_RSTN         [2]),
.MASTER_WR_ADDR_ID   (M_WR_ADDR_ID   [2]),
.MASTER_WR_ADDR      (M_WR_ADDR      [2]),
.MASTER_WR_ADDR_LEN  (M_WR_ADDR_LEN  [2]),
.MASTER_WR_ADDR_BURST(M_WR_ADDR_BURST[2]),
.MASTER_WR_ADDR_VALID(M_WR_ADDR_VALID[2]),
.MASTER_WR_ADDR_READY(M_WR_ADDR_READY[2]),
.MASTER_WR_DATA      (M_WR_DATA      [2]),
.MASTER_WR_STRB      (M_WR_STRB      [2]),
.MASTER_WR_DATA_LAST (M_WR_DATA_LAST [2]),
.MASTER_WR_DATA_VALID(M_WR_DATA_VALID[2]),
.MASTER_WR_DATA_READY(M_WR_DATA_READY[2]),
.MASTER_WR_BACK_ID   (M_WR_BACK_ID   [2]),
.MASTER_WR_BACK_RESP (M_WR_BACK_RESP [2]),
.MASTER_WR_BACK_VALID(M_WR_BACK_VALID[2]),
.MASTER_WR_BACK_READY(M_WR_BACK_READY[2]),
.MASTER_RD_ADDR_ID   (M_RD_ADDR_ID   [2]),
.MASTER_RD_ADDR      (M_RD_ADDR      [2]),
.MASTER_RD_ADDR_LEN  (M_RD_ADDR_LEN  [2]),
.MASTER_RD_ADDR_BURST(M_RD_ADDR_BURST[2]),
.MASTER_RD_ADDR_VALID(M_RD_ADDR_VALID[2]),
.MASTER_RD_ADDR_READY(M_RD_ADDR_READY[2]),
.MASTER_RD_BACK_ID   (M_RD_BACK_ID   [2]),
.MASTER_RD_DATA      (M_RD_DATA      [2]),
.MASTER_RD_DATA_RESP (M_RD_DATA_RESP [2]),
.MASTER_RD_DATA_LAST (M_RD_DATA_LAST [2]),
.MASTER_RD_DATA_VALID(M_RD_DATA_VALID[2]),
.MASTER_RD_DATA_READY(M_RD_DATA_READY[2])
);

axi_master_sim #(
	.ID_WIDTH(M_ID)
)M3(
.MASTER_CLK          (M_CLK          [3]),
.MASTER_RSTN         (M_RSTN         [3]),
.MASTER_WR_ADDR_ID   (M_WR_ADDR_ID   [3]),
.MASTER_WR_ADDR      (M_WR_ADDR      [3]),
.MASTER_WR_ADDR_LEN  (M_WR_ADDR_LEN  [3]),
.MASTER_WR_ADDR_BURST(M_WR_ADDR_BURST[3]),
.MASTER_WR_ADDR_VALID(M_WR_ADDR_VALID[3]),
.MASTER_WR_ADDR_READY(M_WR_ADDR_READY[3]),
.MASTER_WR_DATA      (M_WR_DATA      [3]),
.MASTER_WR_STRB      (M_WR_STRB      [3]),
.MASTER_WR_DATA_LAST (M_WR_DATA_LAST [3]),
.MASTER_WR_DATA_VALID(M_WR_DATA_VALID[3]),
.MASTER_WR_DATA_READY(M_WR_DATA_READY[3]),
.MASTER_WR_BACK_ID   (M_WR_BACK_ID   [3]),
.MASTER_WR_BACK_RESP (M_WR_BACK_RESP [3]),
.MASTER_WR_BACK_VALID(M_WR_BACK_VALID[3]),
.MASTER_WR_BACK_READY(M_WR_BACK_READY[3]),
.MASTER_RD_ADDR_ID   (M_RD_ADDR_ID   [3]),
.MASTER_RD_ADDR      (M_RD_ADDR      [3]),
.MASTER_RD_ADDR_LEN  (M_RD_ADDR_LEN  [3]),
.MASTER_RD_ADDR_BURST(M_RD_ADDR_BURST[3]),
.MASTER_RD_ADDR_VALID(M_RD_ADDR_VALID[3]),
.MASTER_RD_ADDR_READY(M_RD_ADDR_READY[3]),
.MASTER_RD_BACK_ID   (M_RD_BACK_ID   [3]),
.MASTER_RD_DATA      (M_RD_DATA      [3]),
.MASTER_RD_DATA_RESP (M_RD_DATA_RESP [3]),
.MASTER_RD_DATA_LAST (M_RD_DATA_LAST [3]),
.MASTER_RD_DATA_VALID(M_RD_DATA_VALID[3]),
.MASTER_RD_DATA_READY(M_RD_DATA_READY[3])
);

DDR_axi_sim S0(
	.ddr_ref_clk                ( BUS_CLK             ),
	.rst_n                	    ( BUS_RSTN            ),
	.DDR_SLAVE_CLK           	( S_CLK          [0]  ),
	.DDR_SLAVE_RSTN          	( S_RSTN         [0]  ),
	.DDR_SLAVE_WR_ADDR_ID    	( S_WR_ADDR_ID   [0]  ),
	.DDR_SLAVE_WR_ADDR       	( S_WR_ADDR      [0]  ),
	.DDR_SLAVE_WR_ADDR_LEN   	( S_WR_ADDR_LEN  [0]  ),
	.DDR_SLAVE_WR_ADDR_BURST 	( S_WR_ADDR_BURST[0]  ),
	.DDR_SLAVE_WR_ADDR_VALID 	( S_WR_ADDR_VALID[0]  ),
	.DDR_SLAVE_WR_ADDR_READY 	( S_WR_ADDR_READY[0]  ),
	.DDR_SLAVE_WR_DATA       	( S_WR_DATA      [0]  ),
	.DDR_SLAVE_WR_STRB       	( S_WR_STRB      [0]  ),
	.DDR_SLAVE_WR_DATA_LAST  	( S_WR_DATA_LAST [0]  ),
	.DDR_SLAVE_WR_DATA_VALID 	( S_WR_DATA_VALID[0]  ),
	.DDR_SLAVE_WR_DATA_READY 	( S_WR_DATA_READY[0]  ),
	.DDR_SLAVE_WR_BACK_ID    	( S_WR_BACK_ID   [0]  ),
	.DDR_SLAVE_WR_BACK_RESP  	( S_WR_BACK_RESP [0]  ),
	.DDR_SLAVE_WR_BACK_VALID 	( S_WR_BACK_VALID[0]  ),
	.DDR_SLAVE_WR_BACK_READY 	( S_WR_BACK_READY[0]  ),
	.DDR_SLAVE_RD_ADDR_ID    	( S_RD_ADDR_ID   [0]  ),
	.DDR_SLAVE_RD_ADDR       	( S_RD_ADDR      [0]  ),
	.DDR_SLAVE_RD_ADDR_LEN   	( S_RD_ADDR_LEN  [0]  ),
	.DDR_SLAVE_RD_ADDR_BURST 	( S_RD_ADDR_BURST[0]  ),
	.DDR_SLAVE_RD_ADDR_VALID 	( S_RD_ADDR_VALID[0]  ),
	.DDR_SLAVE_RD_ADDR_READY 	( S_RD_ADDR_READY[0]  ),
	.DDR_SLAVE_RD_BACK_ID    	( S_RD_BACK_ID   [0]  ),
	.DDR_SLAVE_RD_DATA       	( S_RD_DATA      [0]  ),
	.DDR_SLAVE_RD_DATA_RESP  	( S_RD_DATA_RESP [0]  ),
	.DDR_SLAVE_RD_DATA_LAST  	( S_RD_DATA_LAST [0]  ),
	.DDR_SLAVE_RD_DATA_VALID 	( S_RD_DATA_VALID[0]  ),
	.DDR_SLAVE_RD_DATA_READY 	( S_RD_DATA_READY[0]  )
);

streaming_axi_master_slave M1S1(
	.clk                  	( BUS_CLK               ),
	.rstn                 	( BUS_RSTN              ),

	.hdmi_in_clk          	( hdmi_in_clk           ),
	.hdmi_in_rstn         	( hdmi_in_rstn          ),
	.hdmi_in_vsync        	( hdmi_in_vsync         ),
	.hdmi_in_hsync        	( hdmi_in_hsync         ),
	.hdmi_in_de           	( hdmi_in_de            ),
	.hdmi_in_rgb          	( hdmi_in_rgb           ),

	.MASTER_CLK           	( M_CLK            [1]),
	.MASTER_RSTN          	( M_RSTN           [1]),
	.MASTER_WR_ADDR_ID    	( M_WR_ADDR_ID     [1]),
	.MASTER_WR_ADDR       	( M_WR_ADDR        [1]),
	.MASTER_WR_ADDR_LEN   	( M_WR_ADDR_LEN    [1]),
	.MASTER_WR_ADDR_BURST 	( M_WR_ADDR_BURST  [1]),
	.MASTER_WR_ADDR_VALID 	( M_WR_ADDR_VALID  [1]),
	.MASTER_WR_ADDR_READY 	( M_WR_ADDR_READY  [1]),
	.MASTER_WR_DATA       	( M_WR_DATA        [1]),
	.MASTER_WR_STRB       	( M_WR_STRB        [1]),
	.MASTER_WR_DATA_LAST  	( M_WR_DATA_LAST   [1]),
	.MASTER_WR_DATA_VALID 	( M_WR_DATA_VALID  [1]),
	.MASTER_WR_DATA_READY 	( M_WR_DATA_READY  [1]),
	.MASTER_WR_BACK_ID    	( M_WR_BACK_ID     [1]),
	.MASTER_WR_BACK_RESP  	( M_WR_BACK_RESP   [1]),
	.MASTER_WR_BACK_VALID 	( M_WR_BACK_VALID  [1]),
	.MASTER_WR_BACK_READY 	( M_WR_BACK_READY  [1]),
	.MASTER_RD_ADDR_ID    	( M_RD_ADDR_ID     [1]),
	.MASTER_RD_ADDR       	( M_RD_ADDR        [1]),
	.MASTER_RD_ADDR_LEN   	( M_RD_ADDR_LEN    [1]),
	.MASTER_RD_ADDR_BURST 	( M_RD_ADDR_BURST  [1]),
	.MASTER_RD_ADDR_VALID 	( M_RD_ADDR_VALID  [1]),
	.MASTER_RD_ADDR_READY 	( M_RD_ADDR_READY  [1]),
	.MASTER_RD_BACK_ID    	( M_RD_BACK_ID     [1]),
	.MASTER_RD_DATA       	( M_RD_DATA        [1]),
	.MASTER_RD_DATA_RESP  	( M_RD_DATA_RESP   [1]),
	.MASTER_RD_DATA_LAST  	( M_RD_DATA_LAST   [1]),
	.MASTER_RD_DATA_VALID 	( M_RD_DATA_VALID  [1]),
	.MASTER_RD_DATA_READY 	( M_RD_DATA_READY  [1]),
	.SLAVE_CLK            	( S_CLK             [1]),
	.SLAVE_RSTN           	( S_RSTN            [1]),
	.SLAVE_WR_ADDR_ID     	( S_WR_ADDR_ID      [1]),
	.SLAVE_WR_ADDR        	( S_WR_ADDR         [1]),
	.SLAVE_WR_ADDR_LEN    	( S_WR_ADDR_LEN     [1]),
	.SLAVE_WR_ADDR_BURST  	( S_WR_ADDR_BURST   [1]),
	.SLAVE_WR_ADDR_VALID  	( S_WR_ADDR_VALID   [1]),
	.SLAVE_WR_ADDR_READY  	( S_WR_ADDR_READY   [1]),
	.SLAVE_WR_DATA        	( S_WR_DATA         [1]),
	.SLAVE_WR_STRB        	( S_WR_STRB         [1]),
	.SLAVE_WR_DATA_LAST   	( S_WR_DATA_LAST    [1]),
	.SLAVE_WR_DATA_VALID  	( S_WR_DATA_VALID   [1]),
	.SLAVE_WR_DATA_READY  	( S_WR_DATA_READY   [1]),
	.SLAVE_WR_BACK_ID     	( S_WR_BACK_ID      [1]),
	.SLAVE_WR_BACK_RESP   	( S_WR_BACK_RESP    [1]),
	.SLAVE_WR_BACK_VALID  	( S_WR_BACK_VALID   [1]),
	.SLAVE_WR_BACK_READY  	( S_WR_BACK_READY   [1]),
	.SLAVE_RD_ADDR_ID     	( S_RD_ADDR_ID      [1]),
	.SLAVE_RD_ADDR        	( S_RD_ADDR         [1]),
	.SLAVE_RD_ADDR_LEN    	( S_RD_ADDR_LEN     [1]),
	.SLAVE_RD_ADDR_BURST  	( S_RD_ADDR_BURST   [1]),
	.SLAVE_RD_ADDR_VALID  	( S_RD_ADDR_VALID   [1]),
	.SLAVE_RD_ADDR_READY  	( S_RD_ADDR_READY   [1]),
	.SLAVE_RD_BACK_ID     	( S_RD_BACK_ID      [1]),
	.SLAVE_RD_DATA        	( S_RD_DATA         [1]),
	.SLAVE_RD_DATA_RESP   	( S_RD_DATA_RESP    [1]),
	.SLAVE_RD_DATA_LAST   	( S_RD_DATA_LAST    [1]),
	.SLAVE_RD_DATA_VALID  	( S_RD_DATA_VALID   [1]),
	.SLAVE_RD_DATA_READY  	( S_RD_DATA_READY   [1])
);


axi_bus #(
	.M_ID       	(M_ID      ),
	.M_WIDTH    	(M_WIDTH   ),
	.S_WIDTH    	(S_WIDTH   ),
	.START_ADDR 	(START_ADDR),
	.END_ADDR   	(END_ADDR  ),
	.M_ASYNC_ON     ({1'b1, 1'b1, 1'b1, 1'b1}),
	.S_ASYNC_ON     ({1'b1, 1'b1})
) u_axi_bus(
	.BUS_CLK           	( BUS_CLK        ),
	.BUS_RSTN          	( BUS_RSTN       ),
    .MASTER_CLK          (M_CLK          ),
    .MASTER_RSTN         (M_RSTN         ),
    .MASTER_WR_ADDR_ID   (M_WR_ADDR_ID   ),
    .MASTER_WR_ADDR      (M_WR_ADDR      ),
    .MASTER_WR_ADDR_LEN  (M_WR_ADDR_LEN  ),
    .MASTER_WR_ADDR_BURST(M_WR_ADDR_BURST),
    .MASTER_WR_ADDR_VALID(M_WR_ADDR_VALID),
    .MASTER_WR_ADDR_READY(M_WR_ADDR_READY),
    .MASTER_WR_DATA      (M_WR_DATA      ),
    .MASTER_WR_STRB      (M_WR_STRB      ),
    .MASTER_WR_DATA_LAST (M_WR_DATA_LAST ),
    .MASTER_WR_DATA_VALID(M_WR_DATA_VALID),
    .MASTER_WR_DATA_READY(M_WR_DATA_READY),
    .MASTER_WR_BACK_ID   (M_WR_BACK_ID   ),
    .MASTER_WR_BACK_RESP (M_WR_BACK_RESP ),
    .MASTER_WR_BACK_VALID(M_WR_BACK_VALID),
    .MASTER_WR_BACK_READY(M_WR_BACK_READY),
    .MASTER_RD_ADDR_ID   (M_RD_ADDR_ID   ),
    .MASTER_RD_ADDR      (M_RD_ADDR      ),
    .MASTER_RD_ADDR_LEN  (M_RD_ADDR_LEN  ),
    .MASTER_RD_ADDR_BURST(M_RD_ADDR_BURST),
    .MASTER_RD_ADDR_VALID(M_RD_ADDR_VALID),
    .MASTER_RD_ADDR_READY(M_RD_ADDR_READY),
    .MASTER_RD_BACK_ID   (M_RD_BACK_ID   ),
    .MASTER_RD_DATA      (M_RD_DATA      ),
    .MASTER_RD_DATA_RESP (M_RD_DATA_RESP ),
    .MASTER_RD_DATA_LAST (M_RD_DATA_LAST ),
    .MASTER_RD_DATA_VALID(M_RD_DATA_VALID),
    .MASTER_RD_DATA_READY(M_RD_DATA_READY),
    .SLAVE_CLK          (S_CLK          ),
    .SLAVE_RSTN         (S_RSTN         ),
    .SLAVE_WR_ADDR_ID   (S_WR_ADDR_ID   ),
    .SLAVE_WR_ADDR      (S_WR_ADDR      ),
    .SLAVE_WR_ADDR_LEN  (S_WR_ADDR_LEN  ),
    .SLAVE_WR_ADDR_BURST(S_WR_ADDR_BURST),
    .SLAVE_WR_ADDR_VALID(S_WR_ADDR_VALID),
    .SLAVE_WR_ADDR_READY(S_WR_ADDR_READY),
    .SLAVE_WR_DATA      (S_WR_DATA      ),
    .SLAVE_WR_STRB      (S_WR_STRB      ),
    .SLAVE_WR_DATA_LAST (S_WR_DATA_LAST ),
    .SLAVE_WR_DATA_VALID(S_WR_DATA_VALID),
    .SLAVE_WR_DATA_READY(S_WR_DATA_READY),
    .SLAVE_WR_BACK_ID   (S_WR_BACK_ID   ),
    .SLAVE_WR_BACK_RESP (S_WR_BACK_RESP ),
    .SLAVE_WR_BACK_VALID(S_WR_BACK_VALID),
    .SLAVE_WR_BACK_READY(S_WR_BACK_READY),
    .SLAVE_RD_ADDR_ID   (S_RD_ADDR_ID   ),
    .SLAVE_RD_ADDR      (S_RD_ADDR      ),
    .SLAVE_RD_ADDR_LEN  (S_RD_ADDR_LEN  ),
    .SLAVE_RD_ADDR_BURST(S_RD_ADDR_BURST),
    .SLAVE_RD_ADDR_VALID(S_RD_ADDR_VALID),
    .SLAVE_RD_ADDR_READY(S_RD_ADDR_READY),
    .SLAVE_RD_BACK_ID   (S_RD_BACK_ID   ),
    .SLAVE_RD_DATA      (S_RD_DATA      ),
    .SLAVE_RD_DATA_RESP (S_RD_DATA_RESP ),
    .SLAVE_RD_DATA_LAST (S_RD_DATA_LAST ),
    .SLAVE_RD_DATA_VALID(S_RD_DATA_VALID),
    .SLAVE_RD_DATA_READY(S_RD_DATA_READY),
	.M_fifo_empty_flag 	( M_fifo_empty_flag  ),
	.S_fifo_empty_flag 	( S_fifo_empty_flag  )
);

reg grs_n;
GTP_GRS GRS_INST(.GRS_N (grs_n));
initial begin
grs_n = 1'b0;
#5 grs_n = 1'b1;
end

// Digital input counter (original functionality)
initial digital_in = 32'h0;
always begin
	#200 digital_in = digital_in + 1;
end

// HDMI Control Tasks - 使用SystemVerilog高级语法
task automatic hdmi_start(input [11:0] width, height);
    $display("[%t] HDMI: Starting video stream - %dx%d", $time, width, height);
    hdmi_frame_width = width;
    hdmi_frame_height = height;
    hdmi_enable = 1;
    // 直接启动，不使用fork避免竞争
endtask

task automatic hdmi_stop();
    $display("[%t] HDMI: Stopping video stream", $time);
    hdmi_enable = 0;
    // 清零所有信号
    repeat(10) @(posedge hdmi_in_clk);
    hdmi_in_hsync = 0;
    hdmi_in_vsync = 0;
    hdmi_in_rgb = 24'h000000;
    hdmi_in_de = 0;
endtask

task automatic hdmi_send_frame(input [11:0] width, height);
    $display("[%t] HDMI: Sending single frame - %dx%d", $time, width, height);
    hdmi_frame_width = width;
    hdmi_frame_height = height;
    hdmi_enable = 1;
    hdmi_generate_single_frame();
    hdmi_enable = 0;
endtask

// 持续的HDMI流生成进程
initial begin
    wait(hdmi_in_rstn); // 等待复位释放
    forever begin
        if (hdmi_enable) begin
            hdmi_generate_single_frame();
        end else begin
            @(posedge hdmi_enable); // 等待使能
        end
    end
end

// 简化的HDMI信号默认状态控制
always @(posedge hdmi_in_clk or negedge hdmi_in_rstn) begin
    if (~hdmi_in_rstn) begin
        // 复位时清零所有信号
        hdmi_in_hsync <= 0;
        hdmi_in_vsync <= 0;
        hdmi_in_rgb <= 24'h000000;
        hdmi_in_de <= 0;
    end
    // 其他时候由任务控制信号
end

// 生成单帧视频的任务 - 1080p60Hz简化时序
task automatic hdmi_generate_single_frame();
    automatic int x, y;
    
    hdmi_pixel_count = 0;
    
    $display("[%t] HDMI: Starting new frame - %dx%d", 
             $time, hdmi_frame_width, hdmi_frame_height);
    
    // 帧同步 - vsync拉高V_SYNC_PULSE个时钟
    hdmi_in_vsync = 1;  // 垂直同步开始，表示新帧
    hdmi_in_hsync = 0;  // vsync期间hsync保持低电平
    hdmi_in_de = 0;     // 无有效数据
    hdmi_in_rgb = 24'h000000;
    repeat(V_SYNC_PULSE) @(posedge hdmi_in_clk);
    
    // vsync结束，开始发送视频数据行
    hdmi_in_vsync = 0;
    
    // 发送所有视频行
    for (y = 0; y < hdmi_frame_height; y++) begin
        if (!hdmi_enable) break; // 允许中途停止
        
        // 行同步 - hsync拉高表示新行开始
        hdmi_in_hsync = 1;
        hdmi_in_de = 0;
        hdmi_in_rgb = 24'h000000;
        repeat(H_SYNC_PULSE) @(posedge hdmi_in_clk);
        
        // hsync结束，开始发送有效像素数据
        hdmi_in_hsync = 0;
        
        // 水平后沿 (可选的消隐期)
        hdmi_in_de = 0;
        hdmi_in_rgb = 24'h000000;
        repeat(H_BACK_PORCH) @(posedge hdmi_in_clk);
        
        // 有效像素数据 - DE高电平表示RGB有效
        hdmi_in_de = 1;  // 数据使能有效
        for (x = 0; x < hdmi_frame_width; x++) begin
            hdmi_in_rgb = generate_test_pixel(x, y);
            hdmi_pixel_count++;
            @(posedge hdmi_in_clk);
        end
        
        // 行结束 - 水平前沿
        hdmi_in_de = 0;  // 数据使能无效
        hdmi_in_rgb = 24'h000000;
        repeat(H_FRONT_PORCH) @(posedge hdmi_in_clk);
    end
    
    // 帧结束 - 垂直前沿
    hdmi_in_de = 0;
    hdmi_in_rgb = 24'h000000;
    repeat(V_FRONT_PORCH) @(posedge hdmi_in_clk);
    
    $display("[%t] HDMI: Frame complete - %d pixels sent", $time, hdmi_pixel_count);
endtask

// 生成测试像素数据
function automatic [23:0] generate_test_pixel(input [11:0] x, y);
    automatic logic [23:0] pixel_data;
    begin
        pixel_data = video_hex_data[hex_pixel_index % total_hex_pixels];
        hex_pixel_index = hex_pixel_index + 1;
        return pixel_data;
    end
endfunction

// 简化的调试监控
always_ff @(posedge hdmi_in_clk) begin
    // 监控像素数据 (只有DE有效时才是有效像素)
    if (hdmi_in_de && hdmi_enable && hdmi_pixel_count % 50000 == 0) begin
        $display("[%t] HDMI: %d pixels sent - RGB=%h", $time, hdmi_pixel_count, hdmi_in_rgb);
    end
end

// HDMI时序监控 - 简化版本
always @(posedge hdmi_in_vsync) begin
    if (hdmi_enable)
        $display("[%t] HDMI: VSYNC=1 - New frame started", $time);
end
    
always @(negedge hdmi_in_vsync) begin
    if (hdmi_enable)
        $display("[%t] HDMI: VSYNC=0 - Frame sync ended", $time);
end

always @(posedge hdmi_in_hsync) begin
    if (hdmi_enable && !hdmi_in_vsync)
        $display("[%t] HDMI: HSYNC=1 - New line started", $time);
end

// DE信号监控
always @(posedge hdmi_in_de) begin
    if (hdmi_enable)
        $display("[%t] HDMI: DE=1 - Active video data starts", $time);
end

always @(negedge hdmi_in_de) begin
    if (hdmi_enable)
        $display("[%t] HDMI: DE=0 - Active video data ends", $time);
end

// HDMI AXI Slave测试序列 - 新寄存器配置模式
task automatic hdmi_axi_slave_test_sequence();
    reg [31:0] read_data;
    reg [M_ID-1:0] read_id;
    reg [1:0] read_resp;
    reg data_valid;
    reg [31:0] hdmi_width, hdmi_height;
    reg [31:0] bitstream_size;
    reg [31:0] hdmi_total_size;
    reg [31:0] read_addr;
    reg [31:0] remaining_size;
    reg [31:0] current_burst_size;
    integer jpeg_file;
    integer i, j;
    
    $display("[%t] Starting HDMI AXI Slave test sequence - New Register Mode", $time);
    
    // 启动HDMI视频流生成
    $display("[%t] Starting HDMI video stream for capture", $time);
    hdmi_start(VIDEO_WIDTH, VIDEO_HEIGHT);

    #300000;
    
    // 计算HDMI图像总大小 (像素数 * 4/3，因为32位字存储24位像素)
    hdmi_total_size = (VIDEO_WIDTH * VIDEO_HEIGHT);
    
    // 步骤1: 配置地址范围 - WRITE_ADDR0 (HDMI帧缓存)
    $display("[%t] Step 1: Configure WRITE_ADDR0 range", $time);
    M2.send_wr_addr(2'b00, ADDR_START_WRITE_ADDR0, 8'd0, 2'b00);
    M2.send_wr_data(32'h00000000, 4'b1111);
    
    M2.send_wr_addr(2'b00, ADDR_END_WRITE_ADDR0, 8'd0, 2'b00);
    M2.send_wr_data(hdmi_total_size - 1, 4'b1111);
    
    // 步骤2: 配置地址范围 - WRITE_ADDR1 (JPEG输出缓存)
    $display("[%t] Step 2: Configure WRITE_ADDR1 range", $time);
    M2.send_wr_addr(2'b00, ADDR_START_WRITE_ADDR1, 8'd0, 2'b00);
    M2.send_wr_data(32'h0080_0000, 4'b1111);
    
    M2.send_wr_addr(2'b00, ADDR_END_WRITE_ADDR1, 8'd0, 2'b00);
    M2.send_wr_data(32'h008F_FFFF, 4'b1111);
    
    // 步骤3: 配置地址范围 - READ_ADDR0 (与WRITE0相同)
    $display("[%t] Step 3: Configure READ_ADDR0 range", $time);
    M2.send_wr_addr(2'b00, ADDR_START_READ_ADDR0, 8'd0, 2'b00);
    M2.send_wr_data(32'h00000000, 4'b1111);
    
    M2.send_wr_addr(2'b00, ADDR_END_READ_ADDR0, 8'd0, 2'b00);
    M2.send_wr_data(hdmi_total_size - 1, 4'b1111);
    
    // 步骤4: 配置CAPTURE_RD_CTRL = 00000001 (开启读取)
    $display("[%t] Step 4: Enable capture read control", $time);
    M2.send_wr_addr(2'b00, ADDR_CAPTURE_RD_CTRL, 8'd0, 2'b00);
    M2.send_wr_data(32'h00000001, 4'b1111);
    
    // 步骤5: 等待HDMI_NOTREADY直到为0 (HDMI准备就绪)
    $display("[%t] Step 5: Wait for HDMI ready", $time);
    read_data = 32'hFFFFFFFF;
    while (read_data != 0) begin
        #5000 M0.send_rd_addr(2'b01, ADDR_HDMI_NOTREADY, 8'd0, 2'b00);
        repeat(100) @(posedge BUS_CLK);
        #5000 M0.get_rd_data_from_queue(read_data, read_id, read_resp, data_valid);
        if (data_valid) begin
            $display("[%t] HDMI Status: NOTREADY = %d", $time, read_data);
        end
        if (read_data != 0) begin
            #1000000; // 等待1ms再次检查
        end
    end
    
    // 步骤6: 读取HDMI长宽信息
    $display("[%t] Step 6: Read HDMI dimensions", $time);
    #5000 M0.send_rd_addr(2'b01, ADDR_HDMI_HEIGHT_WIDTH, 8'd0, 2'b00);
    repeat(100) @(posedge BUS_CLK);
    #5000 M0.get_rd_data_from_queue(read_data, read_id, read_resp, data_valid);
    if (data_valid) begin
        hdmi_width = read_data[15:0];
        hdmi_height = read_data[31:16];
        $display("[%t] HDMI Dimensions: Width=%d, Height=%d", $time, hdmi_width, hdmi_height);
    end
    
    // 步骤7: 将获取到的长宽写入JPEG_HEIGHT_WIDTH
    $display("[%t] Step 7: Set JPEG dimensions", $time);
    #5000 M0.send_wr_addr(2'b00, ADDR_JPEG_HEIGHT_WIDTH, 8'd0, 2'b00);
    #5000 M0.send_wr_data(read_data, 4'b1111); // 直接使用HDMI的长宽数据
    
    // 步骤8: 配置CAPTURE_RD_CTRL = 00000003 (开启读取+写入)
    $display("[%t] Step 8: Enable capture read+write control", $time);
    #5000 M0.send_wr_addr(2'b00, ADDR_CAPTURE_RD_CTRL, 8'd0, 2'b00);
    #5000 M0.send_wr_data(32'h00000003, 4'b1111);
    
    // 步骤9: 配置CAPTURE_WR_CTRL = 00000001 (开启写入控制)
    $display("[%t] Step 9: Enable capture write control", $time);
    #5000 M0.send_wr_addr(2'b00, ADDR_CAPTURE_WR_CTRL, 8'd0, 2'b00);
    #5000 M0.send_wr_data(32'h00000001, 4'b1111);
    
    // 步骤10: 配置JPEG_ADD_NEED_FRAME_NUM = 1 (捕获1帧)
    $display("[%t] Step 10: Set frame count to 1", $time);
    #10000000 M0.send_wr_addr(2'b00, ADDR_JPEG_ADD_NEED_FRAME_NUM, 8'd0, 2'b00);
    #5000 M0.send_wr_data(32'hFF, 4'b1111);
    
    // 步骤11: 等待JPEG_FRAME_SAVE_NUM不为0 (JPEG编码完成)
    $display("[%t] Step 11: Wait for JPEG encoding completion", $time);
    read_data = 0;
    while (read_data == 0) begin
        #5000 M0.send_rd_addr(2'b01, ADDR_JPEG_FRAME_SAVE_NUM, 8'd0, 2'b00);
        repeat(100) @(posedge BUS_CLK);
        #5000 M0.get_rd_data_from_queue(read_data, read_id, read_resp, data_valid);
        if (data_valid) begin
            $display("[%t] JPEG Status: FRAME_SAVE_NUM = %d", $time, read_data);
        end
        if (read_data == 0) begin
            #1000000; // 等待1ms再次检查
        end
    end
    
    // 步骤12: 读取FIFO_FRAME_INFO获取bitstream size (突发长度为0)
    $display("[%t] Step 12: Read bitstream size from FIFO", $time);
    #5000 M0.send_rd_addr(2'b01, ADDR_FIFO_FRAME_INFO, 8'd0, 2'b00); // 突发长度为0
    repeat(100) @(posedge BUS_CLK);
    #5000 M0.get_rd_data_from_queue(bitstream_size, read_id, read_resp, data_valid);
    if (data_valid) begin
        $display("[%t] Bitstream Size: %d words (32-bit units)", $time, bitstream_size);
        
        // 步骤13: 从JPEG缓存区读取编码数据并保存
        $display("[%t] Step 13: Reading JPEG bitstream data", $time);
        
        // 打开输出文件
        jpeg_file = $fopen("../output/jpeg_data_new.hex", "w");
        if (jpeg_file == 0) begin
            $display("Error: Cannot create ../output/jpeg_data_new.hex file");
        end else begin
            // 分段读取JPEG bitstream数据（支持大于255个字的数据）
            read_addr = 32'h0008_0000;
            remaining_size = bitstream_size;
            
            while (remaining_size > 0) begin
                // 计算当前突发的长度 (AXI突发长度限制为最大255)
                if (remaining_size > 256) begin
                    current_burst_size = 256;
                end else begin
                    current_burst_size = remaining_size;
                end
                
                $display("[%t] Reading burst: addr=0x%08x, size=%d words", 
                         $time, read_addr, current_burst_size);
                
                // 发送读地址 (突发长度 = size - 1)
                #5000 M0.send_rd_addr(2'b00, read_addr, current_burst_size - 1, 2'b01); // INCR突发
                
                // 等待数据返回
                repeat(300) @(posedge BUS_CLK);
                
                // 读取当前突发的所有数据
                for (j = 0; j < current_burst_size; j++) begin
                    #5 M0.get_rd_data_from_queue(read_data, read_id, read_resp, data_valid);
                    if (data_valid) begin
                        $fwrite(jpeg_file, "%08X\n", read_data);
                    end else begin
                        $display("[%t] Warning: Failed to read JPEG bitstream word at address 0x%08x + %d", 
                                $time, read_addr, j);
                    end
                end
                
                // 更新地址和剩余大小
                read_addr = read_addr + current_burst_size;
                remaining_size = remaining_size - current_burst_size;
                
                $display("[%t] Burst completed. Remaining: %d words", $time, remaining_size);
            end
            
            $fclose(jpeg_file);
            $display("[%t] JPEG bitstream saved to ../output/jpeg_data_new.hex", $time);
            $display("[%t] Total %d words (32-bit) written", $time, bitstream_size);
        end
    end else begin
        $display("[%t] Error: Failed to read bitstream size", $time);
    end
    
    // ///////第二次捕获


    // // 步骤14: 配置JPEG_ADD_NEED_FRAME_NUM = 1 (捕获1帧)
    // $display("[%t] Step 14: Set frame count to 5", $time);
    // #5000000 M0.send_wr_addr(2'b00, ADDR_JPEG_ADD_NEED_FRAME_NUM, 8'd0, 2'b00);
    // #5000 M0.send_wr_data(32'd5, 4'b1111);
    
    // // 步骤15: 等待JPEG_FRAME_SAVE_NUM不为0 (JPEG编码完成)
    // $display("[%t] Step 15: Wait for JPEG encoding completion", $time);
    // read_data = 0;
    // while (read_data == 0) begin
    //     #5000 M0.send_rd_addr(2'b01, ADDR_JPEG_FRAME_SAVE_NUM, 8'd0, 2'b00);
    //     repeat(100) @(posedge BUS_CLK);
    //     #5000 M0.get_rd_data_from_queue(read_data, read_id, read_resp, data_valid);
    //     if (data_valid) begin
    //         $display("[%t] JPEG Status: FRAME_SAVE_NUM = %d", $time, read_data);
    //     end
    //     if (read_data == 0) begin
    //         #1000000; // 等待1ms再次检查
    //     end
    // end
    
    // // 步骤16: 读取FIFO_FRAME_INFO获取bitstream size (突发长度为0)
    // $display("[%t] Step 16: Read bitstream size from FIFO", $time);
    // #5000 M0.send_rd_addr(2'b01, ADDR_FIFO_FRAME_INFO, 8'd0, 2'b00); // 突发长度为0
    // repeat(100) @(posedge BUS_CLK);
    // #5000 M0.get_rd_data_from_queue(bitstream_size, read_id, read_resp, data_valid);
    // if (data_valid) begin
    //     $display("[%t] Bitstream Size: %d words (32-bit units)", $time, bitstream_size);
        
    //     // 步骤17: 从JPEG缓存区读取编码数据并保存
    //     $display("[%t] Step 17: Reading JPEG bitstream data", $time);
        
    //     // 打开输出文件
    //     jpeg_file = $fopen("../output/jpeg_data_new2.hex", "w");
    //     if (jpeg_file == 0) begin
    //         $display("Error: Cannot create ../output/jpeg_data_new2.hex file");
    //     end else begin
    //         // 分段读取JPEG bitstream数据（支持大于255个字的数据）
    //         // read_addr = 32'h0008_0000;
    //         remaining_size = bitstream_size;
            
    //         while (remaining_size > 0) begin
    //             // 计算当前突发的长度 (AXI突发长度限制为最大255)
    //             if (remaining_size > 256) begin
    //                 current_burst_size = 256;
    //             end else begin
    //                 current_burst_size = remaining_size;
    //             end
                
    //             $display("[%t] Reading burst: addr=0x%08x, size=%d words", 
    //                      $time, read_addr, current_burst_size);
                
    //             // 发送读地址 (突发长度 = size - 1)
    //             #5000 M0.send_rd_addr(2'b00, read_addr, current_burst_size - 1, 2'b01); // INCR突发
                
    //             // 等待数据返回
    //             repeat(300) @(posedge BUS_CLK);
                
    //             // 读取当前突发的所有数据
    //             for (j = 0; j < current_burst_size; j++) begin
    //                 #5 M0.get_rd_data_from_queue(read_data, read_id, read_resp, data_valid);
    //                 if (data_valid) begin
    //                     $fwrite(jpeg_file, "%08X\n", read_data);
    //                 end else begin
    //                     $display("[%t] Warning: Failed to read JPEG bitstream word at address 0x%08x + %d", 
    //                             $time, read_addr, j);
    //                 end
    //             end
                
    //             // 更新地址和剩余大小
    //             read_addr = read_addr + current_burst_size;
    //             remaining_size = remaining_size - current_burst_size;
                
    //             $display("[%t] Burst completed. Remaining: %d words", $time, remaining_size);
    //         end
            
    //         $fclose(jpeg_file);
    //         $display("[%t] JPEG bitstream saved to ../output/jpeg_data_new2.hex", $time);
    //         $display("[%t] Total %d words (32-bit) written", $time, bitstream_size);
    //     end
    // end else begin
    //     $display("[%t] Error: Failed to read bitstream size", $time);
    // end
    
    $display("[%t] HDMI AXI Slave test sequence completed - New Register Mode", $time);
endtask

endmodule