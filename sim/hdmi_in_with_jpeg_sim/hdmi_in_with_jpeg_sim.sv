`timescale 1ns/1ps
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

wire [0:(2**M_WIDTH-1)] [4:0] M_fifo_empty_flag;
wire [0:(2**S_WIDTH-1)] [4:0] S_fifo_empty_flag;

// HDMI video stream signals
reg         hdmi_in_clk;
reg         hdmi_in_rstn;
reg         hdmi_in_hsync;
reg         hdmi_in_vsync;
reg [23:0]  hdmi_in_rgb;
reg         hdmi_in_de;

// JPEG encoder clock
reg         jpeg_encoder_clk;

// HDMI control variables
reg         hdmi_enable;
reg [11:0]  hdmi_frame_width;
reg [11:0]  hdmi_frame_height;
reg [31:0]  hdmi_pixel_count;

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
reg  BUS_RSTN   ;

// Clock generation
always #8.3 BUS_CLK = ~BUS_CLK;           // 33.33MHz bus clock
always #3.367 hdmi_in_clk = ~hdmi_in_clk; // 148.5MHz HDMI pixel clock for 1080p60Hz
always #3.333 jpeg_encoder_clk = ~jpeg_encoder_clk; // 200MHz JPEG encoder clock

initial begin
    // Initialize clocks
    BUS_CLK = 0;
    hdmi_in_clk = 0;
    jpeg_encoder_clk = 0;
    
    // Initialize reset signals
    BUS_RSTN = 0;
    hdmi_in_rstn = 0;
    
    // Initialize HDMI control signals
    hdmi_enable = 0;
    hdmi_frame_width = 1920;   
    hdmi_frame_height = 1080;  
    
    // Initialize HDMI video signals
    hdmi_in_hsync = 0;
    hdmi_in_vsync = 0;
    hdmi_in_rgb = 24'h000000;
    hdmi_in_de = 0;
    
    // Initialize counters
    hdmi_pixel_count = 0;
    
    // Release resets after some time
    #50000 BUS_RSTN = 1;
    #51000 hdmi_in_rstn = 1;
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
    $display("HDMI 1080p60Hz timing parameters:");
    $display("  Horizontal: Active=%d, Front=%d, Sync=%d, Back=%d, Total=%d", 
             1920, H_FRONT_PORCH, H_SYNC_PULSE, H_BACK_PORCH, 
             1920 + H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH);
    $display("  Vertical: Active=%d, Front=%d, Sync=%d, Back=%d, Total=%d", 
             1080, V_FRONT_PORCH, V_SYNC_PULSE, V_BACK_PORCH, 
             1080 + V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH);
    $display("  Pixel Clock: 148.5MHz (period = 6.734ns)");
    
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

hdmi_in_axi_slave M1S1(
	.clk                  	( BUS_CLK               ),
	.rstn                 	( BUS_RSTN              ),

	.hdmi_in_clk          	( hdmi_in_clk           ),
	.hdmi_in_rstn         	( hdmi_in_rstn          ),
	.hdmi_in_hsync        	( hdmi_in_hsync         ),
	.hdmi_in_vsync        	( hdmi_in_vsync         ),
	.hdmi_in_rgb          	( hdmi_in_rgb           ),
	.hdmi_in_de           	( hdmi_in_de            ),

	.jpeg_encoder_clk     	( jpeg_encoder_clk      ),

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

// 生成单帧视频的任务
task automatic hdmi_generate_single_frame();
    automatic int x, y, line_total, frame_total;
    
    line_total = H_SYNC_PULSE + H_BACK_PORCH + hdmi_frame_width + H_FRONT_PORCH;
    frame_total = V_SYNC_PULSE + V_BACK_PORCH + hdmi_frame_height + V_FRONT_PORCH;
    
    hdmi_pixel_count = 0;
    
    for (int frame_line = 0; frame_line < frame_total; frame_line++) begin
        // 垂直同步期
        if (frame_line < V_SYNC_PULSE) begin
            hdmi_in_vsync = 1;
            hdmi_in_hsync = 0;
            hdmi_in_de = 0;
            hdmi_in_rgb = 24'h000000;
            repeat(line_total) @(posedge hdmi_in_clk);
        end
        // 垂直后沿
        else if (frame_line < V_SYNC_PULSE + V_BACK_PORCH) begin
            hdmi_in_vsync = 0;
            hdmi_in_hsync = 0;
            hdmi_in_de = 0;
            hdmi_in_rgb = 24'h000000;
            repeat(line_total) @(posedge hdmi_in_clk);
        end
        // 有效视频行
        else if (frame_line < V_SYNC_PULSE + V_BACK_PORCH + hdmi_frame_height) begin
            y = frame_line - V_SYNC_PULSE - V_BACK_PORCH;
            hdmi_in_vsync = 0;
            
            // 行同步
            hdmi_in_hsync = 1;
            hdmi_in_de = 0;
            hdmi_in_rgb = 24'h000000;
            repeat(H_SYNC_PULSE) @(posedge hdmi_in_clk);
            
            // 行后沿
            hdmi_in_hsync = 0;
            repeat(H_BACK_PORCH) @(posedge hdmi_in_clk);
            
            // 有效像素数据
            hdmi_in_de = 1;
            for (x = 0; x < hdmi_frame_width; x++) begin
                hdmi_in_rgb = generate_test_pixel(x, y);
                hdmi_pixel_count++;
                @(posedge hdmi_in_clk);
            end
            
            // 行前沿
            hdmi_in_de = 0;
            hdmi_in_rgb = 24'h000000;
            repeat(H_FRONT_PORCH) @(posedge hdmi_in_clk);
        end
        // 垂直前沿
        else begin
            hdmi_in_vsync = 0;
            hdmi_in_hsync = 0;
            hdmi_in_de = 0;
            hdmi_in_rgb = 24'h000000;
            repeat(line_total) @(posedge hdmi_in_clk);
        end
        
        if (!hdmi_enable) break; // 允许中途停止
    end
    
    $display("[%t] HDMI: Frame complete - %d pixels sent", $time, hdmi_pixel_count);
endtask

// 生成测试像素数据
function automatic [23:0] generate_test_pixel(input [11:0] x, y);
    automatic logic [7:0] r, g, b;
    r = (x * 256) / hdmi_frame_width;
    g = (y * 256) / hdmi_frame_height;
    b = ((x + y) * 256) / (hdmi_frame_width + hdmi_frame_height);
    return {r, g, b};
endfunction

// 简化的调试监控 - 使用SystemVerilog接口监控
always_ff @(posedge hdmi_in_clk) begin
    // 监控像素数据
    if (hdmi_in_de && hdmi_enable && hdmi_pixel_count % 5000 == 0) begin
        $display("[%t] HDMI: %d pixels sent - RGB=%h", $time, hdmi_pixel_count, hdmi_in_rgb);
    end
end

// 帧同步监控
always @(posedge hdmi_in_vsync) if (hdmi_enable)
    $display("[%t] HDMI: New frame started", $time);
    
always @(negedge hdmi_in_vsync) if (hdmi_enable)
    $display("[%t] HDMI: Frame sync ended", $time);

// HDMI AXI Slave测试序列
task automatic hdmi_axi_slave_test_sequence();
    reg [31:0] read_data;
    reg [M_ID-1:0] read_id;
    reg [1:0] read_resp;
    reg data_valid;
    reg [31:0] frame_count;
    reg [31:0] burst_len;
    
    $display("[%t] Starting HDMI AXI Slave test sequence", $time);
    
    // 步骤1: 写寄存器10000000 = 00000001 (开启捕获)
    $display("[%t] Step 1: Enable capture", $time);
    #5000 M0.send_wr_addr(2'b00, 32'h10000000, 8'd0, 2'b00);
    #5000 M0.send_wr_data(32'h00000001, 4'b1111);
    
    // 步骤2: 写寄存器10000001 = 00000000 (设置DDR首地址)
    $display("[%t] Step 2: Set DDR start address", $time);
    #5000 M0.send_wr_addr(2'b00, 32'h10000001, 8'd0, 2'b00);
    #5000 M0.send_wr_data(32'h00000000, 4'b1111);
    
    // 步骤3: 写寄存器10000002 = 0000FFFF (设置DDR末地址)
    $display("[%t] Step 3: Set DDR end address", $time);
    #5000 M0.send_wr_addr(2'b00, 32'h10000002, 8'd0, 2'b00);
    #5000 M0.send_wr_data(32'h00004FFF, 4'b1111);
    
    // 步骤4: 写寄存器10000003 = FFFFFFFF
    $display("[%t] Step 4: Write register 10000003", $time);
    #5000 M0.send_wr_addr(2'b00, 32'h10000003, 8'd0, 2'b00);
    #5000 M0.send_wr_data(32'hFFFFFFFF, 4'b1111);
    
    // 步骤5: 写寄存器10000004 = 50 (捕获50帧)
    $display("[%t] Step 5: Set frame count to 50", $time);
    #5000 M0.send_wr_addr(2'b00, 32'h10000004, 8'd0, 2'b00);
    #5000 M0.send_wr_data(32'd50, 4'b1111);
    
    // 启动HDMI视频流生成
    $display("[%t] Starting HDMI video stream for capture", $time);
    hdmi_start(1920, 1080);
    
    // 步骤6: 轮询读寄存器10000005直至非零 (等待编码完成)
    $display("[%t] Step 6: Polling for encoder completion", $time);
    frame_count = 0;
    while (frame_count == 0) begin
        #5000 M0.send_rd_addr(2'b01, 32'h10000005, 8'd0, 2'b00);
        // 等待读数据返回并从队列获取
        repeat(100) @(posedge BUS_CLK); // 等待读操作完成
        #5000 M0.get_rd_data_from_queue(read_data, read_id, read_resp, data_valid);
        if (data_valid) begin
            frame_count = read_data;
            $display("[%t] Encoder status: %d frames ready", $time, frame_count);
        end
        if (frame_count == 0) begin
            #1000000; // 等待10us再次检查
        end
    end
    
    // // 停止HDMI流
    // hdmi_stop();
    
    // 步骤7: 读寄存器10000006获取帧信息
    $display("[%t] Step 7: Reading frame information", $time);
    burst_len = frame_count * 2 - 1; // 每帧2个32位数据(长宽各1个，size 1个实际是2个32位)
    #5000 M0.send_rd_addr(2'b01, 32'h10000006, burst_len[7:0], 2'b00); // burst类型00，突发长度
    
    // 等待并读取所有帧信息
    repeat(200) @(posedge BUS_CLK); // 等待突发读完成
    
    // 从队列中获取所有帧信息数据
    for (int i = 0; i < frame_count * 2; i++) begin
        #5000 M0.get_rd_data_from_queue(read_data, read_id, read_resp, data_valid);
        if (data_valid) begin
            if (i % 2 == 0) begin
                // 偶数索引：长宽信息
                $display("[%t] Frame %d: Width=%d, Height=%d", $time, i/2, read_data[15:0], read_data[31:16]);
            end else begin
                // 奇数索引：size信息
                $display("[%t] Frame %d: Size=%d bytes", $time, i/2, read_data);
            end
        end else begin
            $display("[%t] Warning: Failed to read frame info %d", $time, i);
        end
    end
    
    $display("[%t] HDMI AXI Slave test sequence completed", $time);
endtask
endmodule