module udp_axi_ddr_update_top #(
    parameter ADMIN_BOARD_MAC     = {48'h12_34_56_78_9A_BC      }  ,
    // parameter BOARD_MAC     = {48'h12_34_56_78_9A_aa      }  ,
    parameter ADMIN_BOARD_IP      = {8'd169,8'd254,8'd109,8'd000}  , //169.254.109.0  8'd169,8'd254,8'd103,8'd006
    // parameter BOARD_IP      = {8'd169,8'd254,8'd109,8'd005}  , //169.254.109.5  8'd169,8'd254,8'd103,8'd006
    parameter ADMIN_DES_MAC       = {48'h84_47_09_4C_47_7C      }  , //00_2B_67_09_FF_5E
    // parameter DES_MAC       = {48'h00_2B_67_09_FF_5E      }  , //00_2B_67_09_FF_5E
    parameter ADMIN_DES_IP        = {8'd169,8'd254,8'd109,8'd183}    //8'd169,8'd254,8'd103,8'd126
    // parameter DES_IP        = {8'd169,8'd254,8'd103,8'd126}    //8'd169,8'd254,8'd103,8'd126
    // parameter DES_IP        = {8'd169,8'd254,8'd103,8'd126}    //8'd169,8'd254,8'd103,8'd126
)(
//system io
input  wire        external_clk ,
input  wire        external_rstn,
//btn io
input  wire [3:0]  btn          ,
//led io
output wire [7:0]  led8         ,
output wire [3:0]  led4         ,
//dac io
output wire        da_clk       ,
output wire [7:0]  da_data      ,
//adc io
output wire        ad_clk       ,
input  wire [7:0]  ad_data      ,
// analyzer io
input  wire [7:0]  digital_in   ,
output wire        test_capture0,
output wire        test_capture1,
//matrix control io
output wire [3:0]  matrix_col   ,
input  wire [3:0]  matrix_row   ,
//lab fpga power io
output wire        lab_fpga_power_on,
//jtag io
output wire        tck          ,
output wire        tms          ,
output wire        tdi          ,
input  wire        tdo          ,
//spi io
output wire        spi_cs       ,
// output wire     spi_clk      ,
input  wire        spi_dq1      ,
output wire        spi_dq0      ,
//i2c io
inout  wire        scl_eeprom,
inout  wire        sda_eeprom,
inout  wire        scl_camera,
inout  wire        sda_camera,
//ov5640 io
output wire        CCD_PDN,
output wire        CCD_RSTN,
// output wire        CCD_CLKIN,
input  wire        CCD_PCLK,
input  wire        CCD_VSYNC,
input  wire        CCD_HSYNC,
input  wire [7:0]  CCD_DATA,
//eth io
input  wire        rgmii_rxc    ,
input  wire        rgmii_rx_ctl ,
input  wire [3:0]  rgmii_rxd    ,
output wire        rgmii_txc    ,
output wire        rgmii_tx_ctl ,
output wire [3:0]  rgmii_txd    ,
output wire        eth_rst_n    ,
//hsst io
input  wire        i_p_refckn_0 ,
input  wire        i_p_refckp_0 ,
//ddrmem io
output wire        mem_rst_n    ,
output wire        mem_ck       ,
output wire        mem_ck_n     ,
output wire        mem_cs_n     ,
output wire [14:0] mem_a        ,
inout  wire [31:0] mem_dq       ,
inout  wire [ 3:0] mem_dqs      ,
inout  wire [ 3:0] mem_dqs_n    ,
output wire [ 3:0] mem_dm       ,
output wire        mem_cke      ,
output wire        mem_odt      ,
output wire        mem_ras_n    ,
output wire        mem_cas_n    ,
output wire        mem_we_n     ,
output wire [ 2:0] mem_ba       
);

wire [31:0]  eeprom_host_ip  ;
wire [47:0]  eeprom_host_mac ;
wire [31:0]  eeprom_board_ip ;
wire [47:0]  eeprom_board_mac;

wire [31:0] DMA0_START_WRITE_ADDR;
wire [31:0] DMA0_END_WRITE_ADDR  ;
wire        DMA0_capture_on     ;
wire		DMA0_capture_rst    ;
wire [15:0] OV_expect_width   ; //期望宽度
wire [15:0] OV_expect_height  ; //期望高度


wire [31:0] DMA1_START_WRITE_ADDR;
wire [31:0] DMA1_END_WRITE_ADDR  ;
wire DMA1_rd_clk                 ;
wire DMA1_capture_on             ;
wire DMA1_capture_rst            ;
wire DMA1_rd_data_ready          ;
wire DMA1_rd_data_valid          ;
wire [31:0] DMA1_rd_data         ;

wire scl_eeprom_out, scl_eeprom_enable;
wire sda_eeprom_out, sda_eeprom_enable;
wire scl_camera_out, scl_camera_enable;
wire sda_camera_out, sda_camera_enable;

assign scl_eeprom = (scl_eeprom_enable)?(scl_eeprom_out):(1'bz);
assign sda_eeprom = (sda_eeprom_enable)?(sda_eeprom_out):(1'bz);

assign scl_camera = (scl_camera_enable)?(scl_camera_out):(1'bz);
assign sda_camera = (sda_camera_enable)?(sda_camera_out):(1'bz);

assign test_capture0 = scl_camera;
assign test_capture1 = sda_camera;

wire timestamp_rst;
wire booting;
wire admin_mode;

localparam M_WIDTH  = 2;
localparam S_WIDTH  = 4;
localparam M_ID     = 2;
localparam [0:(2**M_WIDTH-1)]       M_ASYNC_ON = {1'b1,1'b1,1'b1,1'b1};//M0 UDP需要, M1 摄像头数据传递，现在用50M不需要， M2是DMA，现在用50M不需要， M3 没用上，不需要
localparam [0:(2**S_WIDTH-1)]       S_ASYNC_ON = {1'b1,1'b1,1'b1,1'b0, //S0 DDR需要, S1 JTAG需要, S2 SPI需要, S3 I2C需要
								 				  1'b1,1'b1,1'b0,1'b0, //S4 信号发生器需要, S5 HSST需要, S6 camera的i2c需要 S7没用上，不需要
								 				  1'b1,1'b1,1'b0,1'b0, //
								 				  1'b0,1'b0,1'b0,1'b0};//
localparam [0:(2**S_WIDTH-1)][31:0] START_ADDR = {32'h00000000, 32'h10000000, 32'h20000000, 32'h30000000,
												  32'h40000000, 32'h50000000, 32'h60000000, 32'h70000000,
												  32'h80000000, 32'h90000000, 32'ha0000000, 32'hb0000000,
												  32'hc0000000, 32'hd0000000, 32'he0000000, 32'hf0000000};
localparam [0:(2**S_WIDTH-1)][31:0]   END_ADDR = {32'h0FFFFFFF, 32'h1FFFFFFF, 32'h2FFFFFFF, 32'h3FFFFFFF,
												  32'h4FFFFFFF, 32'h5FFFFFFF, 32'h6FFFFFFF, 32'h7FFFFFFF,
												  32'h8FFFFFFF, 32'h9FFFFFFF, 32'haFFFFFFF, 32'hbFFFFFFF,
												  32'hcFFFFFFF, 32'hdFFFFFFF, 32'heFFFFFFF, 32'hfFFFFFFF};

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

wire clk_50M;
wire clk_200M;
wire clk_5M;
wire clk_10M;
wire clk_25M;
wire clk_120M;
wire clk_lock;

wire [7:0] udp_led;

clk_pll_top clk_pll_top_inst (
  .clkout0(clk_50M),
  .clkout1(clk_200M),
  .clkout2(clk_5M),
  .clkout3(clk_10M),
  .clkout4(clk_25M),
  .clkout5(clk_120M),
  .lock   (clk_lock),
  .clkin1 (external_clk)
);
assign da_clk    = clk_10M;
assign ad_clk    = clk_10M;

assign eth_rst_n   = 1;
wire sys_rstn    = (external_rstn) && (clk_lock);
wire BUS_RSTN    = (external_rstn) && (clk_lock);
wire udp_in_rstn = (external_rstn) && (clk_lock);
wire led_rst_n   = (external_rstn) && (clk_lock);
wire ddr_rst_n   = (external_rstn) && (clk_lock);
wire jtag_rstn   = (external_rstn) && (clk_lock);
wire ru_rstn     = (external_rstn) && (clk_lock);

wire OV_ccd_rstn;
assign CCD_RSTN = (sys_rstn) && OV_ccd_rstn;

axi_udp_master #(
	.ADMIN_BOARD_MAC 	(ADMIN_BOARD_MAC),
	.ADMIN_BOARD_IP  	(ADMIN_BOARD_IP ),
	.ADMIN_DES_MAC   	(ADMIN_DES_MAC  ),
	.ADMIN_DES_IP    	(ADMIN_DES_IP   )
)M0(
	.udp_in_rstn                ( udp_in_rstn     ),
	.eth_rst_n                  (                 ),
	.rgmii_rxc            	    ( rgmii_rxc       ),
	.rgmii_rx_ctl         	    ( rgmii_rx_ctl    ),
	.rgmii_rxd            	    ( rgmii_rxd       ),
	.rgmii_txc            	    ( rgmii_txc       ),
	.rgmii_tx_ctl         	    ( rgmii_tx_ctl    ),
	.rgmii_txd            	    ( rgmii_txd       ),
    .udp_led                    ( udp_led         ),
	.timestamp_rst              ( timestamp_rst   ),
	.booting				    ( booting         ),
	.admin_mode			        ( admin_mode      ),
	.eeprom_des_ip              ( eeprom_host_ip  ),
	.eeprom_des_mac             ( eeprom_host_mac ),
	.eeprom_board_ip            ( eeprom_board_ip ),
	.eeprom_board_mac           ( eeprom_board_mac),
	.ETH_MASTER_CLK           	( M_CLK          [0]),
	.ETH_MASTER_RSTN          	( M_RSTN         [0]),
	.ETH_MASTER_WR_ADDR_ID    	( M_WR_ADDR_ID   [0]),
	.ETH_MASTER_WR_ADDR       	( M_WR_ADDR      [0]),
	.ETH_MASTER_WR_ADDR_LEN   	( M_WR_ADDR_LEN  [0]),
	.ETH_MASTER_WR_ADDR_BURST 	( M_WR_ADDR_BURST[0]),
	.ETH_MASTER_WR_ADDR_VALID 	( M_WR_ADDR_VALID[0]),
	.ETH_MASTER_WR_ADDR_READY 	( M_WR_ADDR_READY[0]),
	.ETH_MASTER_WR_DATA       	( M_WR_DATA      [0]),
	.ETH_MASTER_WR_STRB       	( M_WR_STRB      [0]),
	.ETH_MASTER_WR_DATA_LAST  	( M_WR_DATA_LAST [0]),
	.ETH_MASTER_WR_DATA_VALID 	( M_WR_DATA_VALID[0]),
	.ETH_MASTER_WR_DATA_READY 	( M_WR_DATA_READY[0]),
	.ETH_MASTER_WR_BACK_ID    	( M_WR_BACK_ID   [0]),
	.ETH_MASTER_WR_BACK_RESP  	( M_WR_BACK_RESP [0]),
	.ETH_MASTER_WR_BACK_VALID 	( M_WR_BACK_VALID[0]),
	.ETH_MASTER_WR_BACK_READY 	( M_WR_BACK_READY[0]),
	.ETH_MASTER_RD_ADDR_ID    	( M_RD_ADDR_ID   [0]),
	.ETH_MASTER_RD_ADDR       	( M_RD_ADDR      [0]),
	.ETH_MASTER_RD_ADDR_LEN   	( M_RD_ADDR_LEN  [0]),
	.ETH_MASTER_RD_ADDR_BURST 	( M_RD_ADDR_BURST[0]),
	.ETH_MASTER_RD_ADDR_VALID 	( M_RD_ADDR_VALID[0]),
	.ETH_MASTER_RD_ADDR_READY 	( M_RD_ADDR_READY[0]),
	.ETH_MASTER_RD_BACK_ID    	( M_RD_BACK_ID   [0]),
	.ETH_MASTER_RD_DATA       	( M_RD_DATA      [0]),
	.ETH_MASTER_RD_DATA_RESP  	( M_RD_DATA_RESP [0]),
	.ETH_MASTER_RD_DATA_LAST  	( M_RD_DATA_LAST [0]),
	.ETH_MASTER_RD_DATA_VALID 	( M_RD_DATA_VALID[0]),
	.ETH_MASTER_RD_DATA_READY 	( M_RD_DATA_READY[0])
);

ov5640_axi_master M1(
	.clk                  	( clk_120M              ),
	.rstn                 	( sys_rstn              ),
	.CCD_RSTN              	( CCD_RSTN              ),
	.CCD_PCLK             	( CCD_PCLK              ),
	.CCD_VSYNC            	( CCD_VSYNC             ),
	.CCD_HSYNC            	( CCD_HSYNC             ),
	.CCD_DATA             	( CCD_DATA              ),
	.START_WRITE_ADDR      	( DMA0_START_WRITE_ADDR ),//START_ADDR[0]       
	.END_WRITE_ADDR         ( DMA0_END_WRITE_ADDR   ),//((640*480)*16)/32   
	.capture_on		    	( DMA0_capture_on       ),
	.capture_rst		 	( DMA0_capture_rst      ),        
	.expect_width         	( OV_expect_width     ),//期望宽度
	.expect_height        	( OV_expect_height    ),//期望高度   
	.MASTER_CLK           	( M_CLK          [1]  ),
	.MASTER_RSTN          	( M_RSTN         [1]  ),
	.MASTER_WR_ADDR_ID    	( M_WR_ADDR_ID   [1]  ),
	.MASTER_WR_ADDR       	( M_WR_ADDR      [1]  ),
	.MASTER_WR_ADDR_LEN   	( M_WR_ADDR_LEN  [1]  ),
	.MASTER_WR_ADDR_BURST 	( M_WR_ADDR_BURST[1]  ),
	.MASTER_WR_ADDR_VALID 	( M_WR_ADDR_VALID[1]  ),
	.MASTER_WR_ADDR_READY 	( M_WR_ADDR_READY[1]  ),
	.MASTER_WR_DATA       	( M_WR_DATA      [1]  ),
	.MASTER_WR_STRB       	( M_WR_STRB      [1]  ),
	.MASTER_WR_DATA_LAST  	( M_WR_DATA_LAST [1]  ),
	.MASTER_WR_DATA_VALID 	( M_WR_DATA_VALID[1]  ),
	.MASTER_WR_DATA_READY 	( M_WR_DATA_READY[1]  ),
	.MASTER_WR_BACK_ID    	( M_WR_BACK_ID   [1]  ),
	.MASTER_WR_BACK_RESP  	( M_WR_BACK_RESP [1]  ),
	.MASTER_WR_BACK_VALID 	( M_WR_BACK_VALID[1]  ),
	.MASTER_WR_BACK_READY 	( M_WR_BACK_READY[1]  ),
	.MASTER_RD_ADDR_ID    	( M_RD_ADDR_ID   [1]  ),
	.MASTER_RD_ADDR       	( M_RD_ADDR      [1]  ),
	.MASTER_RD_ADDR_LEN   	( M_RD_ADDR_LEN  [1]  ),
	.MASTER_RD_ADDR_BURST 	( M_RD_ADDR_BURST[1]  ),
	.MASTER_RD_ADDR_VALID 	( M_RD_ADDR_VALID[1]  ),
	.MASTER_RD_ADDR_READY 	( M_RD_ADDR_READY[1]  ),
	.MASTER_RD_BACK_ID    	( M_RD_BACK_ID   [1]  ),
	.MASTER_RD_DATA       	( M_RD_DATA      [1]  ),
	.MASTER_RD_DATA_RESP  	( M_RD_DATA_RESP [1]  ),
	.MASTER_RD_DATA_LAST  	( M_RD_DATA_LAST [1]  ),
	.MASTER_RD_DATA_VALID 	( M_RD_DATA_VALID[1]  ),
	.MASTER_RD_DATA_READY 	( M_RD_DATA_READY[1]  )
);

axi_master_initial_boot #(
	.I2C_EEPROM_SLAVE_BASEADDR (START_ADDR[3])
)M2(
    .clk                  (clk_120M          ),
    .rstn                 (sys_rstn          ),
    .eeprom_host_ip  	  (eeprom_host_ip    ),
    .eeprom_host_mac 	  (eeprom_host_mac   ),
    .eeprom_board_ip 	  (eeprom_board_ip   ),
    .eeprom_board_mac	  (eeprom_board_mac  ),
    .MASTER_CLK           (M_CLK          [2]),
    .MASTER_RSTN          (M_RSTN         [2]),
    .MASTER_WR_ADDR_ID    (M_WR_ADDR_ID   [2]),
    .MASTER_WR_ADDR       (M_WR_ADDR      [2]),
    .MASTER_WR_ADDR_LEN   (M_WR_ADDR_LEN  [2]),
    .MASTER_WR_ADDR_BURST (M_WR_ADDR_BURST[2]),
    .MASTER_WR_ADDR_VALID (M_WR_ADDR_VALID[2]),
    .MASTER_WR_ADDR_READY (M_WR_ADDR_READY[2]),
    .MASTER_WR_DATA       (M_WR_DATA      [2]),
    .MASTER_WR_STRB       (M_WR_STRB      [2]),
    .MASTER_WR_DATA_LAST  (M_WR_DATA_LAST [2]),
    .MASTER_WR_DATA_VALID (M_WR_DATA_VALID[2]),
    .MASTER_WR_DATA_READY (M_WR_DATA_READY[2]),
    .MASTER_WR_BACK_ID    (M_WR_BACK_ID   [2]),
    .MASTER_WR_BACK_RESP  (M_WR_BACK_RESP [2]),
    .MASTER_WR_BACK_VALID (M_WR_BACK_VALID[2]),
    .MASTER_WR_BACK_READY (M_WR_BACK_READY[2]),
    .MASTER_RD_ADDR_ID    (M_RD_ADDR_ID   [2]),
    .MASTER_RD_ADDR       (M_RD_ADDR      [2]),
    .MASTER_RD_ADDR_LEN   (M_RD_ADDR_LEN  [2]),
    .MASTER_RD_ADDR_BURST (M_RD_ADDR_BURST[2]),
    .MASTER_RD_ADDR_VALID (M_RD_ADDR_VALID[2]),
    .MASTER_RD_ADDR_READY (M_RD_ADDR_READY[2]),
    .MASTER_RD_BACK_ID    (M_RD_BACK_ID   [2]),
    .MASTER_RD_DATA       (M_RD_DATA      [2]),
    .MASTER_RD_DATA_RESP  (M_RD_DATA_RESP [2]),
    .MASTER_RD_DATA_LAST  (M_RD_DATA_LAST [2]),
    .MASTER_RD_DATA_VALID (M_RD_DATA_VALID[2]),
    .MASTER_RD_DATA_READY (M_RD_DATA_READY[2]));

axi_master_write_dma M3(
    .clk                  (clk_120M             ),
    .rstn                 (sys_rstn             ),
	.START_WRITE_ADDR	  (DMA1_START_WRITE_ADDR),
	.END_WRITE_ADDR	      (DMA1_END_WRITE_ADDR  ),
	.rd_clk               (DMA1_rd_clk          ),
	.rd_capture_on		  (DMA1_capture_on      ),
	.rd_capture_rst		  (DMA1_capture_rst     ),
	.rd_data_ready        (DMA1_rd_data_ready),
	.rd_data_valid        (DMA1_rd_data_valid),
	.rd_data              (DMA1_rd_data      ),
    .MASTER_CLK           (M_CLK          [3]),
    .MASTER_RSTN          (M_RSTN         [3]),
    .MASTER_WR_ADDR_ID    (M_WR_ADDR_ID   [3]),
    .MASTER_WR_ADDR       (M_WR_ADDR      [3]),
    .MASTER_WR_ADDR_LEN   (M_WR_ADDR_LEN  [3]),
    .MASTER_WR_ADDR_BURST (M_WR_ADDR_BURST[3]),
    .MASTER_WR_ADDR_VALID (M_WR_ADDR_VALID[3]),
    .MASTER_WR_ADDR_READY (M_WR_ADDR_READY[3]),
    .MASTER_WR_DATA       (M_WR_DATA      [3]),
    .MASTER_WR_STRB       (M_WR_STRB      [3]),
    .MASTER_WR_DATA_LAST  (M_WR_DATA_LAST [3]),
    .MASTER_WR_DATA_VALID (M_WR_DATA_VALID[3]),
    .MASTER_WR_DATA_READY (M_WR_DATA_READY[3]),
    .MASTER_WR_BACK_ID    (M_WR_BACK_ID   [3]),
    .MASTER_WR_BACK_RESP  (M_WR_BACK_RESP [3]),
    .MASTER_WR_BACK_VALID (M_WR_BACK_VALID[3]),
    .MASTER_WR_BACK_READY (M_WR_BACK_READY[3]),
    .MASTER_RD_ADDR_ID    (M_RD_ADDR_ID   [3]),
    .MASTER_RD_ADDR       (M_RD_ADDR      [3]),
    .MASTER_RD_ADDR_LEN   (M_RD_ADDR_LEN  [3]),
    .MASTER_RD_ADDR_BURST (M_RD_ADDR_BURST[3]),
    .MASTER_RD_ADDR_VALID (M_RD_ADDR_VALID[3]),
    .MASTER_RD_ADDR_READY (M_RD_ADDR_READY[3]),
    .MASTER_RD_BACK_ID    (M_RD_BACK_ID   [3]),
    .MASTER_RD_DATA       (M_RD_DATA      [3]),
    .MASTER_RD_DATA_RESP  (M_RD_DATA_RESP [3]),
    .MASTER_RD_DATA_LAST  (M_RD_DATA_LAST [3]),
    .MASTER_RD_DATA_VALID (M_RD_DATA_VALID[3]),
    .MASTER_RD_DATA_READY (M_RD_DATA_READY[3])
);

slave_ddr3 S0(
    .ddr_ref_clk             (clk_50M      ),
    .rst_n                   (ddr_rst_n        ),
    .DDR_SLAVE_CLK           (S_CLK          [0]),
    .DDR_SLAVE_RSTN          (S_RSTN         [0]),
    .DDR_SLAVE_WR_ADDR_ID    (S_WR_ADDR_ID   [0]),
    .DDR_SLAVE_WR_ADDR       (S_WR_ADDR      [0]),
    .DDR_SLAVE_WR_ADDR_LEN   (S_WR_ADDR_LEN  [0]),
    .DDR_SLAVE_WR_ADDR_BURST (S_WR_ADDR_BURST[0]),
    .DDR_SLAVE_WR_ADDR_VALID (S_WR_ADDR_VALID[0]),
    .DDR_SLAVE_WR_ADDR_READY (S_WR_ADDR_READY[0]),
    .DDR_SLAVE_WR_DATA       (S_WR_DATA      [0]),
    .DDR_SLAVE_WR_STRB       (S_WR_STRB      [0]),
    .DDR_SLAVE_WR_DATA_LAST  (S_WR_DATA_LAST [0]),
    .DDR_SLAVE_WR_DATA_VALID (S_WR_DATA_VALID[0]),
    .DDR_SLAVE_WR_DATA_READY (S_WR_DATA_READY[0]),
    .DDR_SLAVE_WR_BACK_ID    (S_WR_BACK_ID   [0]),
    .DDR_SLAVE_WR_BACK_RESP  (S_WR_BACK_RESP [0]),
    .DDR_SLAVE_WR_BACK_VALID (S_WR_BACK_VALID[0]),
    .DDR_SLAVE_WR_BACK_READY (S_WR_BACK_READY[0]),
    .DDR_SLAVE_RD_ADDR_ID    (S_RD_ADDR_ID   [0]),
    .DDR_SLAVE_RD_ADDR       (S_RD_ADDR      [0]),
    .DDR_SLAVE_RD_ADDR_LEN   (S_RD_ADDR_LEN  [0]),
    .DDR_SLAVE_RD_ADDR_BURST (S_RD_ADDR_BURST[0]),
    .DDR_SLAVE_RD_ADDR_VALID (S_RD_ADDR_VALID[0]),
    .DDR_SLAVE_RD_ADDR_READY (S_RD_ADDR_READY[0]),
    .DDR_SLAVE_RD_BACK_ID    (S_RD_BACK_ID   [0]),
    .DDR_SLAVE_RD_DATA       (S_RD_DATA      [0]),
    .DDR_SLAVE_RD_DATA_RESP  (S_RD_DATA_RESP [0]),
    .DDR_SLAVE_RD_DATA_LAST  (S_RD_DATA_LAST [0]),
    .DDR_SLAVE_RD_DATA_VALID (S_RD_DATA_VALID[0]),
    .DDR_SLAVE_RD_DATA_READY (S_RD_DATA_READY[0]),
    .mem_rst_n               (mem_rst_n        ),
    .mem_ck                  (mem_ck           ),
    .mem_ck_n                (mem_ck_n         ),
    .mem_cs_n                (mem_cs_n         ),
    .mem_a                   (mem_a            ),
    .mem_dq                  (mem_dq           ),
    .mem_dqs                 (mem_dqs          ),
    .mem_dqs_n               (mem_dqs_n        ),
    .mem_dm                  (mem_dm           ),
    .mem_cke                 (mem_cke          ),
    .mem_odt                 (mem_odt          ),
    .mem_ras_n               (mem_ras_n        ),
    .mem_cas_n               (mem_cas_n        ),
    .mem_we_n                (mem_we_n         ),
    .mem_ba                  (mem_ba           )
);

JTAG_SLAVE S1(
    .clk                      (clk_25M           ),
    .rstn                     (jtag_rstn         ),
    .tck                      (tck               ),
    .tdi                      (tdi               ),
    .tms                      (tms               ),
    .tdo                      (tdo               ),
	.matrix_key_col		      (matrix_col        ),
	.matrix_key_row		      (matrix_row        ),
	.lab_fpga_power_on	      (lab_fpga_power_on ),
    .JTAG_SLAVE_CLK           (S_CLK          [1]),
    .JTAG_SLAVE_RSTN          (S_RSTN         [1]),
    .JTAG_SLAVE_WR_ADDR_ID    (S_WR_ADDR_ID   [1]),
    .JTAG_SLAVE_WR_ADDR       (S_WR_ADDR      [1]),
    .JTAG_SLAVE_WR_ADDR_LEN   (S_WR_ADDR_LEN  [1]),
    .JTAG_SLAVE_WR_ADDR_BURST (S_WR_ADDR_BURST[1]),
    .JTAG_SLAVE_WR_ADDR_VALID (S_WR_ADDR_VALID[1]),
    .JTAG_SLAVE_WR_ADDR_READY (S_WR_ADDR_READY[1]),
    .JTAG_SLAVE_WR_DATA       (S_WR_DATA      [1]),
    .JTAG_SLAVE_WR_STRB       (S_WR_STRB      [1]),
    .JTAG_SLAVE_WR_DATA_LAST  (S_WR_DATA_LAST [1]),
    .JTAG_SLAVE_WR_DATA_VALID (S_WR_DATA_VALID[1]),
    .JTAG_SLAVE_WR_DATA_READY (S_WR_DATA_READY[1]),
    .JTAG_SLAVE_WR_BACK_ID    (S_WR_BACK_ID   [1]),
    .JTAG_SLAVE_WR_BACK_RESP  (S_WR_BACK_RESP [1]),
    .JTAG_SLAVE_WR_BACK_VALID (S_WR_BACK_VALID[1]),
    .JTAG_SLAVE_WR_BACK_READY (S_WR_BACK_READY[1]),
    .JTAG_SLAVE_RD_ADDR_ID    (S_RD_ADDR_ID   [1]),
    .JTAG_SLAVE_RD_ADDR       (S_RD_ADDR      [1]),
    .JTAG_SLAVE_RD_ADDR_LEN   (S_RD_ADDR_LEN  [1]),
    .JTAG_SLAVE_RD_ADDR_BURST (S_RD_ADDR_BURST[1]),
    .JTAG_SLAVE_RD_ADDR_VALID (S_RD_ADDR_VALID[1]),
    .JTAG_SLAVE_RD_ADDR_READY (S_RD_ADDR_READY[1]),
    .JTAG_SLAVE_RD_BACK_ID    (S_RD_BACK_ID   [1]),
    .JTAG_SLAVE_RD_DATA       (S_RD_DATA      [1]),
    .JTAG_SLAVE_RD_DATA_RESP  (S_RD_DATA_RESP [1]),
    .JTAG_SLAVE_RD_DATA_LAST  (S_RD_DATA_LAST [1]),
    .JTAG_SLAVE_RD_DATA_VALID (S_RD_DATA_VALID[1]),
    .JTAG_SLAVE_RD_DATA_READY (S_RD_DATA_READY[1])
);

remote_update_axi_slave #(
    .FPGA_VERSION           (48'h2024_1119_1943 ),
    .DEVICE                 ("PG2L100H"         ),
    .USER_BITSTREAM_CNT     (2'd3               ),
    .USER_BITSTREAM1_ADDR   (24'h3a_4000        ),
    .USER_BITSTREAM2_ADDR   (24'h74_2000        ),
    .USER_BITSTREAM3_ADDR   (24'hae_0000        )
)S2(
    .clk                 (clk_10M           ),
    .rstn                (ru_rstn           ),
    .spi_cs              (spi_cs            ),
    .spi_clk             (spi_clk           ),
    .spi_dq1             (spi_dq1           ),
    .spi_dq0             (spi_dq0           ),
    .SLAVE_CLK           (S_CLK          [2]),
    .SLAVE_RSTN          (S_RSTN         [2]),
    .SLAVE_WR_ADDR_ID    (S_WR_ADDR_ID   [2]),
    .SLAVE_WR_ADDR       (S_WR_ADDR      [2]),
    .SLAVE_WR_ADDR_LEN   (S_WR_ADDR_LEN  [2]),
    .SLAVE_WR_ADDR_BURST (S_WR_ADDR_BURST[2]),
    .SLAVE_WR_ADDR_VALID (S_WR_ADDR_VALID[2]),
    .SLAVE_WR_ADDR_READY (S_WR_ADDR_READY[2]),
    .SLAVE_WR_DATA       (S_WR_DATA      [2]),
    .SLAVE_WR_STRB       (S_WR_STRB      [2]),
    .SLAVE_WR_DATA_LAST  (S_WR_DATA_LAST [2]),
    .SLAVE_WR_DATA_VALID (S_WR_DATA_VALID[2]),
    .SLAVE_WR_DATA_READY (S_WR_DATA_READY[2]),
    .SLAVE_WR_BACK_ID    (S_WR_BACK_ID   [2]),
    .SLAVE_WR_BACK_RESP  (S_WR_BACK_RESP [2]),
    .SLAVE_WR_BACK_VALID (S_WR_BACK_VALID[2]),
    .SLAVE_WR_BACK_READY (S_WR_BACK_READY[2]),
    .SLAVE_RD_ADDR_ID    (S_RD_ADDR_ID   [2]),
    .SLAVE_RD_ADDR       (S_RD_ADDR      [2]),
    .SLAVE_RD_ADDR_LEN   (S_RD_ADDR_LEN  [2]),
    .SLAVE_RD_ADDR_BURST (S_RD_ADDR_BURST[2]),
    .SLAVE_RD_ADDR_VALID (S_RD_ADDR_VALID[2]),
    .SLAVE_RD_ADDR_READY (S_RD_ADDR_READY[2]),
    .SLAVE_RD_BACK_ID    (S_RD_BACK_ID   [2]),
    .SLAVE_RD_DATA       (S_RD_DATA      [2]),
    .SLAVE_RD_DATA_RESP  (S_RD_DATA_RESP [2]),
    .SLAVE_RD_DATA_LAST  (S_RD_DATA_LAST [2]),
    .SLAVE_RD_DATA_VALID (S_RD_DATA_VALID[2]),
    .SLAVE_RD_DATA_READY (S_RD_DATA_READY[2])
);

i2c_master_axi_slave S3(
	.clk                 	( clk_120M          ),
	.rstn                	( BUS_RSTN          ),
    .scl_in                 ( scl_eeprom        ),
    .scl_out                ( scl_eeprom_out    ),
    .scl_enable             ( scl_eeprom_enable ),
    .sda_in                 ( sda_eeprom        ),
    .sda_out                ( sda_eeprom_out    ),
    .sda_enable             ( sda_eeprom_enable ),
	.SLAVE_CLK           	( S_CLK          [3]),
	.SLAVE_RSTN          	( S_RSTN         [3]),
	.SLAVE_WR_ADDR_ID    	( S_WR_ADDR_ID   [3]),
	.SLAVE_WR_ADDR       	( S_WR_ADDR      [3]),
	.SLAVE_WR_ADDR_LEN   	( S_WR_ADDR_LEN  [3]),
	.SLAVE_WR_ADDR_BURST 	( S_WR_ADDR_BURST[3]),
	.SLAVE_WR_ADDR_VALID 	( S_WR_ADDR_VALID[3]),
	.SLAVE_WR_ADDR_READY 	( S_WR_ADDR_READY[3]),
	.SLAVE_WR_DATA       	( S_WR_DATA      [3]),
	.SLAVE_WR_STRB       	( S_WR_STRB      [3]),
	.SLAVE_WR_DATA_LAST  	( S_WR_DATA_LAST [3]),
	.SLAVE_WR_DATA_VALID 	( S_WR_DATA_VALID[3]),
	.SLAVE_WR_DATA_READY 	( S_WR_DATA_READY[3]),
	.SLAVE_WR_BACK_ID    	( S_WR_BACK_ID   [3]),
	.SLAVE_WR_BACK_RESP  	( S_WR_BACK_RESP [3]),
	.SLAVE_WR_BACK_VALID 	( S_WR_BACK_VALID[3]),
	.SLAVE_WR_BACK_READY 	( S_WR_BACK_READY[3]),
	.SLAVE_RD_ADDR_ID    	( S_RD_ADDR_ID   [3]),
	.SLAVE_RD_ADDR       	( S_RD_ADDR      [3]),
	.SLAVE_RD_ADDR_LEN   	( S_RD_ADDR_LEN  [3]),
	.SLAVE_RD_ADDR_BURST 	( S_RD_ADDR_BURST[3]),
	.SLAVE_RD_ADDR_VALID 	( S_RD_ADDR_VALID[3]),
	.SLAVE_RD_ADDR_READY 	( S_RD_ADDR_READY[3]),
	.SLAVE_RD_BACK_ID    	( S_RD_BACK_ID   [3]),
	.SLAVE_RD_DATA       	( S_RD_DATA      [3]),
	.SLAVE_RD_DATA_RESP  	( S_RD_DATA_RESP [3]),
	.SLAVE_RD_DATA_LAST  	( S_RD_DATA_LAST [3]),
	.SLAVE_RD_DATA_VALID 	( S_RD_DATA_VALID[3]),
	.SLAVE_RD_DATA_READY 	( S_RD_DATA_READY[3])
);

dds_slave #(
    .CHANNEL_NUM(1),
    .VERTICAL_RESOLUTION(8)
)S4(
	.clk                 	    ( da_clk            ),
	.rstn                	    ( sys_rstn          ),
    .wave_out            	    ( da_data           ),
	.DDS_SLAVE_CLK           	( S_CLK          [4]),
	.DDS_SLAVE_RSTN          	( S_RSTN         [4]),
	.DDS_SLAVE_WR_ADDR_ID    	( S_WR_ADDR_ID   [4]),
	.DDS_SLAVE_WR_ADDR       	( S_WR_ADDR      [4]),
	.DDS_SLAVE_WR_ADDR_LEN   	( S_WR_ADDR_LEN  [4]),
	.DDS_SLAVE_WR_ADDR_BURST 	( S_WR_ADDR_BURST[4]),
	.DDS_SLAVE_WR_ADDR_VALID 	( S_WR_ADDR_VALID[4]),
	.DDS_SLAVE_WR_ADDR_READY 	( S_WR_ADDR_READY[4]),
	.DDS_SLAVE_WR_DATA       	( S_WR_DATA      [4]),
	.DDS_SLAVE_WR_STRB       	( S_WR_STRB      [4]),
	.DDS_SLAVE_WR_DATA_LAST  	( S_WR_DATA_LAST [4]),
	.DDS_SLAVE_WR_DATA_VALID 	( S_WR_DATA_VALID[4]),
	.DDS_SLAVE_WR_DATA_READY 	( S_WR_DATA_READY[4]),
	.DDS_SLAVE_WR_BACK_ID    	( S_WR_BACK_ID   [4]),
	.DDS_SLAVE_WR_BACK_RESP  	( S_WR_BACK_RESP [4]),
	.DDS_SLAVE_WR_BACK_VALID 	( S_WR_BACK_VALID[4]),
	.DDS_SLAVE_WR_BACK_READY 	( S_WR_BACK_READY[4]),
	.DDS_SLAVE_RD_ADDR_ID    	( S_RD_ADDR_ID   [4]),
	.DDS_SLAVE_RD_ADDR       	( S_RD_ADDR      [4]),
	.DDS_SLAVE_RD_ADDR_LEN   	( S_RD_ADDR_LEN  [4]),
	.DDS_SLAVE_RD_ADDR_BURST 	( S_RD_ADDR_BURST[4]),
	.DDS_SLAVE_RD_ADDR_VALID 	( S_RD_ADDR_VALID[4]),
	.DDS_SLAVE_RD_ADDR_READY 	( S_RD_ADDR_READY[4]),
	.DDS_SLAVE_RD_BACK_ID    	( S_RD_BACK_ID   [4]),
	.DDS_SLAVE_RD_DATA       	( S_RD_DATA      [4]),
	.DDS_SLAVE_RD_DATA_RESP  	( S_RD_DATA_RESP [4]),
	.DDS_SLAVE_RD_DATA_LAST  	( S_RD_DATA_LAST [4]),
	.DDS_SLAVE_RD_DATA_VALID 	( S_RD_DATA_VALID[4]),
	.DDS_SLAVE_RD_DATA_READY 	( S_RD_DATA_READY[4])
);

hsst_axi_slave  S5 (
    .i_p_refckn_0           ( i_p_refckn_0      ),
    .i_p_refckp_0           ( i_p_refckp_0      ),
    .rstn                   ( sys_rstn          ),
    .i_free_clk             ( clk_50M           ),
    .SLAVE_CLK              ( S_CLK          [5]),
    .SLAVE_RSTN             ( S_RSTN         [5]),
    .SLAVE_WR_ADDR_ID       ( S_WR_ADDR_ID   [5]),
    .SLAVE_WR_ADDR          ( S_WR_ADDR      [5]),
    .SLAVE_WR_ADDR_LEN      ( S_WR_ADDR_LEN  [5]),
    .SLAVE_WR_ADDR_BURST    ( S_WR_ADDR_BURST[5]),
    .SLAVE_WR_ADDR_VALID    ( S_WR_ADDR_VALID[5]),
    .SLAVE_WR_ADDR_READY    ( S_WR_ADDR_READY[5]),
    .SLAVE_WR_DATA          ( S_WR_DATA      [5]),
    .SLAVE_WR_STRB          ( S_WR_STRB      [5]),
    .SLAVE_WR_DATA_LAST     ( S_WR_DATA_LAST [5]),
    .SLAVE_WR_DATA_VALID    ( S_WR_DATA_VALID[5]),
    .SLAVE_WR_DATA_READY    ( S_WR_DATA_READY[5]),
    .SLAVE_WR_BACK_ID       ( S_WR_BACK_ID   [5]),
    .SLAVE_WR_BACK_RESP     ( S_WR_BACK_RESP [5]),
    .SLAVE_WR_BACK_VALID    ( S_WR_BACK_VALID[5]),
    .SLAVE_WR_BACK_READY    ( S_WR_BACK_READY[5]),
    .SLAVE_RD_ADDR_ID       ( S_RD_ADDR_ID   [5]),
    .SLAVE_RD_ADDR          ( S_RD_ADDR      [5]),
    .SLAVE_RD_ADDR_LEN      ( S_RD_ADDR_LEN  [5]),
    .SLAVE_RD_ADDR_BURST    ( S_RD_ADDR_BURST[5]),
    .SLAVE_RD_ADDR_VALID    ( S_RD_ADDR_VALID[5]),
    .SLAVE_RD_ADDR_READY    ( S_RD_ADDR_READY[5]),
    .SLAVE_RD_BACK_ID       ( S_RD_BACK_ID   [5]),
    .SLAVE_RD_DATA          ( S_RD_DATA      [5]),
    .SLAVE_RD_DATA_RESP     ( S_RD_DATA_RESP [5]),
    .SLAVE_RD_DATA_LAST     ( S_RD_DATA_LAST [5]),
    .SLAVE_RD_DATA_VALID    ( S_RD_DATA_VALID[5]),
    .SLAVE_RD_DATA_READY    ( S_RD_DATA_READY[5])
  );

i2c_master_general_axi_slave S6(
	.clk                 	( clk_120M          ),
	.rstn                	( BUS_RSTN          ),
    .scl_in                 ( scl_camera        ),
    .scl_out                ( scl_camera_out    ),
    .scl_enable             ( scl_camera_enable ),
    .sda_in                 ( sda_camera        ),
    .sda_out                ( sda_camera_out    ),
    .sda_enable             ( sda_camera_enable ),
	.SLAVE_CLK           	( S_CLK          [6]),
	.SLAVE_RSTN          	( S_RSTN         [6]),
	.SLAVE_WR_ADDR_ID    	( S_WR_ADDR_ID   [6]),
	.SLAVE_WR_ADDR       	( S_WR_ADDR      [6]),
	.SLAVE_WR_ADDR_LEN   	( S_WR_ADDR_LEN  [6]),
	.SLAVE_WR_ADDR_BURST 	( S_WR_ADDR_BURST[6]),
	.SLAVE_WR_ADDR_VALID 	( S_WR_ADDR_VALID[6]),
	.SLAVE_WR_ADDR_READY 	( S_WR_ADDR_READY[6]),
	.SLAVE_WR_DATA       	( S_WR_DATA      [6]),
	.SLAVE_WR_STRB       	( S_WR_STRB      [6]),
	.SLAVE_WR_DATA_LAST  	( S_WR_DATA_LAST [6]),
	.SLAVE_WR_DATA_VALID 	( S_WR_DATA_VALID[6]),
	.SLAVE_WR_DATA_READY 	( S_WR_DATA_READY[6]),
	.SLAVE_WR_BACK_ID    	( S_WR_BACK_ID   [6]),
	.SLAVE_WR_BACK_RESP  	( S_WR_BACK_RESP [6]),
	.SLAVE_WR_BACK_VALID 	( S_WR_BACK_VALID[6]),
	.SLAVE_WR_BACK_READY 	( S_WR_BACK_READY[6]),
	.SLAVE_RD_ADDR_ID    	( S_RD_ADDR_ID   [6]),
	.SLAVE_RD_ADDR       	( S_RD_ADDR      [6]),
	.SLAVE_RD_ADDR_LEN   	( S_RD_ADDR_LEN  [6]),
	.SLAVE_RD_ADDR_BURST 	( S_RD_ADDR_BURST[6]),
	.SLAVE_RD_ADDR_VALID 	( S_RD_ADDR_VALID[6]),
	.SLAVE_RD_ADDR_READY 	( S_RD_ADDR_READY[6]),
	.SLAVE_RD_BACK_ID    	( S_RD_BACK_ID   [6]),
	.SLAVE_RD_DATA       	( S_RD_DATA      [6]),
	.SLAVE_RD_DATA_RESP  	( S_RD_DATA_RESP [6]),
	.SLAVE_RD_DATA_LAST  	( S_RD_DATA_LAST [6]),
	.SLAVE_RD_DATA_VALID 	( S_RD_DATA_VALID[6]),
	.SLAVE_RD_DATA_READY 	( S_RD_DATA_READY[6])
);

wire [15:0]     axi_master_rstn_status;
wire [15:0]     axi_slave_rstn_status;
wire [63:0]     uid;
wire [47:0]     default_mac_addr;
wire [31:0]     default_ip_addr;
wire [31:0]     default_host_ip_addr;
wire [15:0]  	axi_master_reset;
wire [15:0]  	axi_slave_reset;
wire [7:0]   	power_status;
wire [7:0]   	power_reset;

sys_status_axi_slave S7(
	.clk                        	( clk_120M              ),
	.rstn                       	( BUS_RSTN              ),
	.STATUS_SLAVE_CLK           	( S_CLK          [7]    ),
	.STATUS_SLAVE_RSTN          	( S_RSTN         [7]    ),
	.STATUS_SLAVE_WR_ADDR_ID    	( S_WR_ADDR_ID   [7]    ),
	.STATUS_SLAVE_WR_ADDR       	( S_WR_ADDR      [7]    ),
	.STATUS_SLAVE_WR_ADDR_LEN   	( S_WR_ADDR_LEN  [7]    ),
	.STATUS_SLAVE_WR_ADDR_BURST 	( S_WR_ADDR_BURST[7]    ),
	.STATUS_SLAVE_WR_ADDR_VALID 	( S_WR_ADDR_VALID[7]    ),
	.STATUS_SLAVE_WR_ADDR_READY 	( S_WR_ADDR_READY[7]    ),
	.STATUS_SLAVE_WR_DATA       	( S_WR_DATA      [7]    ),
	.STATUS_SLAVE_WR_STRB       	( S_WR_STRB      [7]    ),
	.STATUS_SLAVE_WR_DATA_LAST  	( S_WR_DATA_LAST [7]    ),
	.STATUS_SLAVE_WR_DATA_VALID 	( S_WR_DATA_VALID[7]    ),
	.STATUS_SLAVE_WR_DATA_READY 	( S_WR_DATA_READY[7]    ),
	.STATUS_SLAVE_WR_BACK_ID    	( S_WR_BACK_ID   [7]    ),
	.STATUS_SLAVE_WR_BACK_RESP  	( S_WR_BACK_RESP [7]    ),
	.STATUS_SLAVE_WR_BACK_VALID 	( S_WR_BACK_VALID[7]    ),
	.STATUS_SLAVE_WR_BACK_READY 	( S_WR_BACK_READY[7]    ),
	.STATUS_SLAVE_RD_ADDR_ID    	( S_RD_ADDR_ID   [7]    ),
	.STATUS_SLAVE_RD_ADDR       	( S_RD_ADDR      [7]    ),
	.STATUS_SLAVE_RD_ADDR_LEN   	( S_RD_ADDR_LEN  [7]    ),
	.STATUS_SLAVE_RD_ADDR_BURST 	( S_RD_ADDR_BURST[7]    ),
	.STATUS_SLAVE_RD_ADDR_VALID 	( S_RD_ADDR_VALID[7]    ),
	.STATUS_SLAVE_RD_ADDR_READY 	( S_RD_ADDR_READY[7]    ),
	.STATUS_SLAVE_RD_BACK_ID    	( S_RD_BACK_ID   [7]    ),
	.STATUS_SLAVE_RD_DATA       	( S_RD_DATA      [7]    ),
	.STATUS_SLAVE_RD_DATA_RESP  	( S_RD_DATA_RESP [7]    ),
	.STATUS_SLAVE_RD_DATA_LAST  	( S_RD_DATA_LAST [7]    ),
	.STATUS_SLAVE_RD_DATA_VALID 	( S_RD_DATA_VALID[7]    ),
	.STATUS_SLAVE_RD_DATA_READY 	( S_RD_DATA_READY[7]    ),
	.axi_master_rstn_status     	( axi_master_rstn_status),
	.axi_slave_rstn_status      	( axi_slave_rstn_status ),
	.axi_master_reset           	( axi_master_reset      ),
	.axi_slave_reset            	( axi_slave_reset       ),
	.uid_high                   	( uid[63:32]            ),
	.uid_low                    	( uid[31:0]             ),
	.power_status               	( power_status          ),
	.power_reset                	( power_reset           ),
	.eeprom_host_ip_addr            ( eeprom_host_ip        ),
	.eeprom_board_ip_addr           ( eeprom_board_ip       ),
	.eeprom_host_mac_addr           ( eeprom_host_mac       ),
	.eeprom_board_mac_addr          ( eeprom_board_mac      ),
	.DMA0_START_WRITE_ADDR    		( DMA0_START_WRITE_ADDR     ),
	.DMA0_END_WRITE_ADDR      		( DMA0_END_WRITE_ADDR       ),
	.DMA0_capture_on			    ( DMA0_capture_on          ),
	.DMA0_capture_rst 		        ( DMA0_capture_rst         ),
	.DMA1_START_WRITE_ADDR          ( DMA1_START_WRITE_ADDR     ),
	.DMA1_END_WRITE_ADDR            ( DMA1_END_WRITE_ADDR       ),
	.DMA1_capture_on                ( DMA1_capture_on           ),
	.DMA1_capture_rst               ( DMA1_capture_rst          ),
	.OV_EXPECT_WIDTH			    ( OV_expect_width       ),
	.OV_EXPECT_HEIGHT			    ( OV_expect_height      ),
	.OV_ccd_rstn					( OV_ccd_rstn           ),
	.OV_ccd_pdn					    ( CCD_PDN               ),
	.ETH_timestamp_rst 			    ( timestamp_rst         )
);

dso_axi_slave #(
	.CLK_FS 	(32'd50_000_000)
)S8(
	.clk                     	( clk_50M                  ),
	.rstn                    	( BUS_RSTN                 ),
	.ad_clk                  	( ad_clk                   ),
	.ad_data                 	( ad_data                  ),
	.DSO_SLAVE_CLK           	( S_CLK          [8]       ),
	.DSO_SLAVE_RSTN          	( S_RSTN         [8]       ),
	.DSO_SLAVE_WR_ADDR_ID    	( S_WR_ADDR_ID   [8]       ),
	.DSO_SLAVE_WR_ADDR       	( S_WR_ADDR      [8]       ),
	.DSO_SLAVE_WR_ADDR_LEN   	( S_WR_ADDR_LEN  [8]       ),
	.DSO_SLAVE_WR_ADDR_BURST 	( S_WR_ADDR_BURST[8]       ),
	.DSO_SLAVE_WR_ADDR_VALID 	( S_WR_ADDR_VALID[8]       ),
	.DSO_SLAVE_WR_ADDR_READY 	( S_WR_ADDR_READY[8]       ),
	.DSO_SLAVE_WR_DATA       	( S_WR_DATA      [8]       ),
	.DSO_SLAVE_WR_STRB       	( S_WR_STRB      [8]       ),
	.DSO_SLAVE_WR_DATA_LAST  	( S_WR_DATA_LAST [8]       ),
	.DSO_SLAVE_WR_DATA_VALID 	( S_WR_DATA_VALID[8]       ),
	.DSO_SLAVE_WR_DATA_READY 	( S_WR_DATA_READY[8]       ),
	.DSO_SLAVE_WR_BACK_ID    	( S_WR_BACK_ID   [8]       ),
	.DSO_SLAVE_WR_BACK_RESP  	( S_WR_BACK_RESP [8]       ),
	.DSO_SLAVE_WR_BACK_VALID 	( S_WR_BACK_VALID[8]       ),
	.DSO_SLAVE_WR_BACK_READY 	( S_WR_BACK_READY[8]       ),
	.DSO_SLAVE_RD_ADDR_ID    	( S_RD_ADDR_ID   [8]       ),
	.DSO_SLAVE_RD_ADDR       	( S_RD_ADDR      [8]       ),
	.DSO_SLAVE_RD_ADDR_LEN   	( S_RD_ADDR_LEN  [8]       ),
	.DSO_SLAVE_RD_ADDR_BURST 	( S_RD_ADDR_BURST[8]       ),
	.DSO_SLAVE_RD_ADDR_VALID 	( S_RD_ADDR_VALID[8]       ),
	.DSO_SLAVE_RD_ADDR_READY 	( S_RD_ADDR_READY[8]       ),
	.DSO_SLAVE_RD_BACK_ID    	( S_RD_BACK_ID   [8]       ),
	.DSO_SLAVE_RD_DATA       	( S_RD_DATA      [8]       ),
	.DSO_SLAVE_RD_DATA_RESP  	( S_RD_DATA_RESP [8]       ),
	.DSO_SLAVE_RD_DATA_LAST  	( S_RD_DATA_LAST [8]       ),
	.DSO_SLAVE_RD_DATA_VALID 	( S_RD_DATA_VALID[8]       ),
	.DSO_SLAVE_RD_DATA_READY 	( S_RD_DATA_READY[8]       )
);

Analazer S9(
	.clk                          	( clk_5M              ),
	.rstn                         	( sys_rstn            ),
	.digital_in                   	( digital_in          ),
	.rd_clk					  	    ( DMA1_rd_clk         ),
	.rd_data_ready			 	    ( DMA1_rd_data_ready  ),
	.rd_data_valid			 	    ( DMA1_rd_data_valid  ),
	.rd_data				        ( DMA1_rd_data        ),
	.ANALYZER_SLAVE_CLK           	( S_CLK          [9]  ),
	.ANALYZER_SLAVE_RSTN          	( S_RSTN         [9]  ),
	.ANALYZER_SLAVE_WR_ADDR_ID    	( S_WR_ADDR_ID   [9]  ),
	.ANALYZER_SLAVE_WR_ADDR       	( S_WR_ADDR      [9]  ),
	.ANALYZER_SLAVE_WR_ADDR_LEN   	( S_WR_ADDR_LEN  [9]  ),
	.ANALYZER_SLAVE_WR_ADDR_BURST 	( S_WR_ADDR_BURST[9]  ),
	.ANALYZER_SLAVE_WR_ADDR_VALID 	( S_WR_ADDR_VALID[9]  ),
	.ANALYZER_SLAVE_WR_ADDR_READY 	( S_WR_ADDR_READY[9]  ),
	.ANALYZER_SLAVE_WR_DATA       	( S_WR_DATA      [9]  ),
	.ANALYZER_SLAVE_WR_STRB       	( S_WR_STRB      [9]  ),
	.ANALYZER_SLAVE_WR_DATA_LAST  	( S_WR_DATA_LAST [9]  ),
	.ANALYZER_SLAVE_WR_DATA_VALID 	( S_WR_DATA_VALID[9]  ),
	.ANALYZER_SLAVE_WR_DATA_READY 	( S_WR_DATA_READY[9]  ),
	.ANALYZER_SLAVE_WR_BACK_ID    	( S_WR_BACK_ID   [9]  ),
	.ANALYZER_SLAVE_WR_BACK_RESP  	( S_WR_BACK_RESP [9]  ),
	.ANALYZER_SLAVE_WR_BACK_VALID 	( S_WR_BACK_VALID[9]  ),
	.ANALYZER_SLAVE_WR_BACK_READY 	( S_WR_BACK_READY[9]  ),
	.ANALYZER_SLAVE_RD_ADDR_ID    	( S_RD_ADDR_ID   [9]  ),
	.ANALYZER_SLAVE_RD_ADDR       	( S_RD_ADDR      [9]  ),
	.ANALYZER_SLAVE_RD_ADDR_LEN   	( S_RD_ADDR_LEN  [9]  ),
	.ANALYZER_SLAVE_RD_ADDR_BURST 	( S_RD_ADDR_BURST[9]  ),
	.ANALYZER_SLAVE_RD_ADDR_VALID 	( S_RD_ADDR_VALID[9]  ),
	.ANALYZER_SLAVE_RD_ADDR_READY 	( S_RD_ADDR_READY[9]  ),
	.ANALYZER_SLAVE_RD_BACK_ID    	( S_RD_BACK_ID   [9]  ),
	.ANALYZER_SLAVE_RD_DATA       	( S_RD_DATA      [9]  ),
	.ANALYZER_SLAVE_RD_DATA_RESP  	( S_RD_DATA_RESP [9]  ),
	.ANALYZER_SLAVE_RD_DATA_LAST  	( S_RD_DATA_LAST [9]  ),
	.ANALYZER_SLAVE_RD_DATA_VALID 	( S_RD_DATA_VALID[9]  ),
	.ANALYZER_SLAVE_RD_DATA_READY 	( S_RD_DATA_READY[9]  )
);


axi_slave_default S10(
	.clk 				(clk_120M          ),
	.rstn 				(BUS_RSTN          ),
	.SLAVE_CLK          (S_CLK          [10]),
	.SLAVE_RSTN         (S_RSTN         [10]),
	.SLAVE_WR_ADDR_ID   (S_WR_ADDR_ID   [10]),
	.SLAVE_WR_ADDR      (S_WR_ADDR      [10]),
	.SLAVE_WR_ADDR_LEN  (S_WR_ADDR_LEN  [10]),
	.SLAVE_WR_ADDR_BURST(S_WR_ADDR_BURST[10]),
	.SLAVE_WR_ADDR_VALID(S_WR_ADDR_VALID[10]),
	.SLAVE_WR_ADDR_READY(S_WR_ADDR_READY[10]),
	.SLAVE_WR_DATA      (S_WR_DATA      [10]),
	.SLAVE_WR_STRB      (S_WR_STRB      [10]),
	.SLAVE_WR_DATA_LAST (S_WR_DATA_LAST [10]),
	.SLAVE_WR_DATA_VALID(S_WR_DATA_VALID[10]),
	.SLAVE_WR_DATA_READY(S_WR_DATA_READY[10]),
	.SLAVE_WR_BACK_ID   (S_WR_BACK_ID   [10]),
	.SLAVE_WR_BACK_RESP (S_WR_BACK_RESP [10]),
	.SLAVE_WR_BACK_VALID(S_WR_BACK_VALID[10]),
	.SLAVE_WR_BACK_READY(S_WR_BACK_READY[10]),
	.SLAVE_RD_ADDR_ID   (S_RD_ADDR_ID   [10]),
	.SLAVE_RD_ADDR      (S_RD_ADDR      [10]),
	.SLAVE_RD_ADDR_LEN  (S_RD_ADDR_LEN  [10]),
	.SLAVE_RD_ADDR_BURST(S_RD_ADDR_BURST[10]),
	.SLAVE_RD_ADDR_VALID(S_RD_ADDR_VALID[10]),
	.SLAVE_RD_ADDR_READY(S_RD_ADDR_READY[10]),
	.SLAVE_RD_BACK_ID   (S_RD_BACK_ID   [10]),
	.SLAVE_RD_DATA      (S_RD_DATA      [10]),
	.SLAVE_RD_DATA_RESP (S_RD_DATA_RESP [10]),
	.SLAVE_RD_DATA_LAST (S_RD_DATA_LAST [10]),
	.SLAVE_RD_DATA_VALID(S_RD_DATA_VALID[10]),
	.SLAVE_RD_DATA_READY(S_RD_DATA_READY[10])
);

axi_slave_default S11(
	.clk 				(clk_120M          ),
	.rstn 				(BUS_RSTN          ),
	.SLAVE_CLK          (S_CLK          [11]),
	.SLAVE_RSTN         (S_RSTN         [11]),
	.SLAVE_WR_ADDR_ID   (S_WR_ADDR_ID   [11]),
	.SLAVE_WR_ADDR      (S_WR_ADDR      [11]),
	.SLAVE_WR_ADDR_LEN  (S_WR_ADDR_LEN  [11]),
	.SLAVE_WR_ADDR_BURST(S_WR_ADDR_BURST[11]),
	.SLAVE_WR_ADDR_VALID(S_WR_ADDR_VALID[11]),
	.SLAVE_WR_ADDR_READY(S_WR_ADDR_READY[11]),
	.SLAVE_WR_DATA      (S_WR_DATA      [11]),
	.SLAVE_WR_STRB      (S_WR_STRB      [11]),
	.SLAVE_WR_DATA_LAST (S_WR_DATA_LAST [11]),
	.SLAVE_WR_DATA_VALID(S_WR_DATA_VALID[11]),
	.SLAVE_WR_DATA_READY(S_WR_DATA_READY[11]),
	.SLAVE_WR_BACK_ID   (S_WR_BACK_ID   [11]),
	.SLAVE_WR_BACK_RESP (S_WR_BACK_RESP [11]),
	.SLAVE_WR_BACK_VALID(S_WR_BACK_VALID[11]),
	.SLAVE_WR_BACK_READY(S_WR_BACK_READY[11]),
	.SLAVE_RD_ADDR_ID   (S_RD_ADDR_ID   [11]),
	.SLAVE_RD_ADDR      (S_RD_ADDR      [11]),
	.SLAVE_RD_ADDR_LEN  (S_RD_ADDR_LEN  [11]),
	.SLAVE_RD_ADDR_BURST(S_RD_ADDR_BURST[11]),
	.SLAVE_RD_ADDR_VALID(S_RD_ADDR_VALID[11]),
	.SLAVE_RD_ADDR_READY(S_RD_ADDR_READY[11]),
	.SLAVE_RD_BACK_ID   (S_RD_BACK_ID   [11]),
	.SLAVE_RD_DATA      (S_RD_DATA      [11]),
	.SLAVE_RD_DATA_RESP (S_RD_DATA_RESP [11]),
	.SLAVE_RD_DATA_LAST (S_RD_DATA_LAST [11]),
	.SLAVE_RD_DATA_VALID(S_RD_DATA_VALID[11]),
	.SLAVE_RD_DATA_READY(S_RD_DATA_READY[11])
);

axi_slave_default S12(
	.clk 				(clk_120M          ),
	.rstn 				(BUS_RSTN          ),
	.SLAVE_CLK          (S_CLK          [12]),
	.SLAVE_RSTN         (S_RSTN         [12]),
	.SLAVE_WR_ADDR_ID   (S_WR_ADDR_ID   [12]),
	.SLAVE_WR_ADDR      (S_WR_ADDR      [12]),
	.SLAVE_WR_ADDR_LEN  (S_WR_ADDR_LEN  [12]),
	.SLAVE_WR_ADDR_BURST(S_WR_ADDR_BURST[12]),
	.SLAVE_WR_ADDR_VALID(S_WR_ADDR_VALID[12]),
	.SLAVE_WR_ADDR_READY(S_WR_ADDR_READY[12]),
	.SLAVE_WR_DATA      (S_WR_DATA      [12]),
	.SLAVE_WR_STRB      (S_WR_STRB      [12]),
	.SLAVE_WR_DATA_LAST (S_WR_DATA_LAST [12]),
	.SLAVE_WR_DATA_VALID(S_WR_DATA_VALID[12]),
	.SLAVE_WR_DATA_READY(S_WR_DATA_READY[12]),
	.SLAVE_WR_BACK_ID   (S_WR_BACK_ID   [12]),
	.SLAVE_WR_BACK_RESP (S_WR_BACK_RESP [12]),
	.SLAVE_WR_BACK_VALID(S_WR_BACK_VALID[12]),
	.SLAVE_WR_BACK_READY(S_WR_BACK_READY[12]),
	.SLAVE_RD_ADDR_ID   (S_RD_ADDR_ID   [12]),
	.SLAVE_RD_ADDR      (S_RD_ADDR      [12]),
	.SLAVE_RD_ADDR_LEN  (S_RD_ADDR_LEN  [12]),
	.SLAVE_RD_ADDR_BURST(S_RD_ADDR_BURST[12]),
	.SLAVE_RD_ADDR_VALID(S_RD_ADDR_VALID[12]),
	.SLAVE_RD_ADDR_READY(S_RD_ADDR_READY[12]),
	.SLAVE_RD_BACK_ID   (S_RD_BACK_ID   [12]),
	.SLAVE_RD_DATA      (S_RD_DATA      [12]),
	.SLAVE_RD_DATA_RESP (S_RD_DATA_RESP [12]),
	.SLAVE_RD_DATA_LAST (S_RD_DATA_LAST [12]),
	.SLAVE_RD_DATA_VALID(S_RD_DATA_VALID[12]),
	.SLAVE_RD_DATA_READY(S_RD_DATA_READY[12])
);

axi_slave_default S13(
	.clk 				(clk_120M          ),
	.rstn 				(BUS_RSTN          ),
	.SLAVE_CLK          (S_CLK          [13]),
	.SLAVE_RSTN         (S_RSTN         [13]),
	.SLAVE_WR_ADDR_ID   (S_WR_ADDR_ID   [13]),
	.SLAVE_WR_ADDR      (S_WR_ADDR      [13]),
	.SLAVE_WR_ADDR_LEN  (S_WR_ADDR_LEN  [13]),
	.SLAVE_WR_ADDR_BURST(S_WR_ADDR_BURST[13]),
	.SLAVE_WR_ADDR_VALID(S_WR_ADDR_VALID[13]),
	.SLAVE_WR_ADDR_READY(S_WR_ADDR_READY[13]),
	.SLAVE_WR_DATA      (S_WR_DATA      [13]),
	.SLAVE_WR_STRB      (S_WR_STRB      [13]),
	.SLAVE_WR_DATA_LAST (S_WR_DATA_LAST [13]),
	.SLAVE_WR_DATA_VALID(S_WR_DATA_VALID[13]),
	.SLAVE_WR_DATA_READY(S_WR_DATA_READY[13]),
	.SLAVE_WR_BACK_ID   (S_WR_BACK_ID   [13]),
	.SLAVE_WR_BACK_RESP (S_WR_BACK_RESP [13]),
	.SLAVE_WR_BACK_VALID(S_WR_BACK_VALID[13]),
	.SLAVE_WR_BACK_READY(S_WR_BACK_READY[13]),
	.SLAVE_RD_ADDR_ID   (S_RD_ADDR_ID   [13]),
	.SLAVE_RD_ADDR      (S_RD_ADDR      [13]),
	.SLAVE_RD_ADDR_LEN  (S_RD_ADDR_LEN  [13]),
	.SLAVE_RD_ADDR_BURST(S_RD_ADDR_BURST[13]),
	.SLAVE_RD_ADDR_VALID(S_RD_ADDR_VALID[13]),
	.SLAVE_RD_ADDR_READY(S_RD_ADDR_READY[13]),
	.SLAVE_RD_BACK_ID   (S_RD_BACK_ID   [13]),
	.SLAVE_RD_DATA      (S_RD_DATA      [13]),
	.SLAVE_RD_DATA_RESP (S_RD_DATA_RESP [13]),
	.SLAVE_RD_DATA_LAST (S_RD_DATA_LAST [13]),
	.SLAVE_RD_DATA_VALID(S_RD_DATA_VALID[13]),
	.SLAVE_RD_DATA_READY(S_RD_DATA_READY[13])
);

axi_slave_default S14(
	.clk 				(clk_120M          ),
	.rstn 				(BUS_RSTN          ),
	.SLAVE_CLK          (S_CLK          [14]),
	.SLAVE_RSTN         (S_RSTN         [14]),
	.SLAVE_WR_ADDR_ID   (S_WR_ADDR_ID   [14]),
	.SLAVE_WR_ADDR      (S_WR_ADDR      [14]),
	.SLAVE_WR_ADDR_LEN  (S_WR_ADDR_LEN  [14]),
	.SLAVE_WR_ADDR_BURST(S_WR_ADDR_BURST[14]),
	.SLAVE_WR_ADDR_VALID(S_WR_ADDR_VALID[14]),
	.SLAVE_WR_ADDR_READY(S_WR_ADDR_READY[14]),
	.SLAVE_WR_DATA      (S_WR_DATA      [14]),
	.SLAVE_WR_STRB      (S_WR_STRB      [14]),
	.SLAVE_WR_DATA_LAST (S_WR_DATA_LAST [14]),
	.SLAVE_WR_DATA_VALID(S_WR_DATA_VALID[14]),
	.SLAVE_WR_DATA_READY(S_WR_DATA_READY[14]),
	.SLAVE_WR_BACK_ID   (S_WR_BACK_ID   [14]),
	.SLAVE_WR_BACK_RESP (S_WR_BACK_RESP [14]),
	.SLAVE_WR_BACK_VALID(S_WR_BACK_VALID[14]),
	.SLAVE_WR_BACK_READY(S_WR_BACK_READY[14]),
	.SLAVE_RD_ADDR_ID   (S_RD_ADDR_ID   [14]),
	.SLAVE_RD_ADDR      (S_RD_ADDR      [14]),
	.SLAVE_RD_ADDR_LEN  (S_RD_ADDR_LEN  [14]),
	.SLAVE_RD_ADDR_BURST(S_RD_ADDR_BURST[14]),
	.SLAVE_RD_ADDR_VALID(S_RD_ADDR_VALID[14]),
	.SLAVE_RD_ADDR_READY(S_RD_ADDR_READY[14]),
	.SLAVE_RD_BACK_ID   (S_RD_BACK_ID   [14]),
	.SLAVE_RD_DATA      (S_RD_DATA      [14]),
	.SLAVE_RD_DATA_RESP (S_RD_DATA_RESP [14]),
	.SLAVE_RD_DATA_LAST (S_RD_DATA_LAST [14]),
	.SLAVE_RD_DATA_VALID(S_RD_DATA_VALID[14]),
	.SLAVE_RD_DATA_READY(S_RD_DATA_READY[14])
);

axi_slave_default S15(
	.clk 				(clk_120M          ),
	.rstn 				(BUS_RSTN          ),
	.SLAVE_CLK          (S_CLK          [15]),
	.SLAVE_RSTN         (S_RSTN         [15]),
	.SLAVE_WR_ADDR_ID   (S_WR_ADDR_ID   [15]),
	.SLAVE_WR_ADDR      (S_WR_ADDR      [15]),
	.SLAVE_WR_ADDR_LEN  (S_WR_ADDR_LEN  [15]),
	.SLAVE_WR_ADDR_BURST(S_WR_ADDR_BURST[15]),
	.SLAVE_WR_ADDR_VALID(S_WR_ADDR_VALID[15]),
	.SLAVE_WR_ADDR_READY(S_WR_ADDR_READY[15]),
	.SLAVE_WR_DATA      (S_WR_DATA      [15]),
	.SLAVE_WR_STRB      (S_WR_STRB      [15]),
	.SLAVE_WR_DATA_LAST (S_WR_DATA_LAST [15]),
	.SLAVE_WR_DATA_VALID(S_WR_DATA_VALID[15]),
	.SLAVE_WR_DATA_READY(S_WR_DATA_READY[15]),
	.SLAVE_WR_BACK_ID   (S_WR_BACK_ID   [15]),
	.SLAVE_WR_BACK_RESP (S_WR_BACK_RESP [15]),
	.SLAVE_WR_BACK_VALID(S_WR_BACK_VALID[15]),
	.SLAVE_WR_BACK_READY(S_WR_BACK_READY[15]),
	.SLAVE_RD_ADDR_ID   (S_RD_ADDR_ID   [15]),
	.SLAVE_RD_ADDR      (S_RD_ADDR      [15]),
	.SLAVE_RD_ADDR_LEN  (S_RD_ADDR_LEN  [15]),
	.SLAVE_RD_ADDR_BURST(S_RD_ADDR_BURST[15]),
	.SLAVE_RD_ADDR_VALID(S_RD_ADDR_VALID[15]),
	.SLAVE_RD_ADDR_READY(S_RD_ADDR_READY[15]),
	.SLAVE_RD_BACK_ID   (S_RD_BACK_ID   [15]),
	.SLAVE_RD_DATA      (S_RD_DATA      [15]),
	.SLAVE_RD_DATA_RESP (S_RD_DATA_RESP [15]),
	.SLAVE_RD_DATA_LAST (S_RD_DATA_LAST [15]),
	.SLAVE_RD_DATA_VALID(S_RD_DATA_VALID[15]),
	.SLAVE_RD_DATA_READY(S_RD_DATA_READY[15])
);


axi_bus #(
	.M_ID       	( M_ID      ),
	.M_WIDTH    	( M_WIDTH   ),
	.S_WIDTH    	( S_WIDTH   ),
    .M_ASYNC_ON     ( M_ASYNC_ON),
    .S_ASYNC_ON     ( S_ASYNC_ON),
	.START_ADDR 	( START_ADDR),
	.END_ADDR   	( END_ADDR  ))
u_axi_bus(
	.BUS_CLK              	( clk_120M         ),
	.BUS_RSTN             	( BUS_RSTN         ),
	.MASTER_CLK           	( M_CLK            ),
	.MASTER_RSTN          	( M_RSTN           ),
	.MASTER_WR_ADDR_ID    	( M_WR_ADDR_ID     ),
	.MASTER_WR_ADDR       	( M_WR_ADDR        ),
	.MASTER_WR_ADDR_LEN   	( M_WR_ADDR_LEN    ),
	.MASTER_WR_ADDR_BURST 	( M_WR_ADDR_BURST  ),
	.MASTER_WR_ADDR_VALID 	( M_WR_ADDR_VALID  ),
	.MASTER_WR_ADDR_READY 	( M_WR_ADDR_READY  ),
	.MASTER_WR_DATA       	( M_WR_DATA        ),
	.MASTER_WR_STRB       	( M_WR_STRB        ),
	.MASTER_WR_DATA_LAST  	( M_WR_DATA_LAST   ),
	.MASTER_WR_DATA_VALID 	( M_WR_DATA_VALID  ),
	.MASTER_WR_DATA_READY 	( M_WR_DATA_READY  ),
	.MASTER_WR_BACK_ID    	( M_WR_BACK_ID     ),
	.MASTER_WR_BACK_RESP  	( M_WR_BACK_RESP   ),
	.MASTER_WR_BACK_VALID 	( M_WR_BACK_VALID  ),
	.MASTER_WR_BACK_READY 	( M_WR_BACK_READY  ),
	.MASTER_RD_ADDR_ID    	( M_RD_ADDR_ID     ),
	.MASTER_RD_ADDR       	( M_RD_ADDR        ),
	.MASTER_RD_ADDR_LEN   	( M_RD_ADDR_LEN    ),
	.MASTER_RD_ADDR_BURST 	( M_RD_ADDR_BURST  ),
	.MASTER_RD_ADDR_VALID 	( M_RD_ADDR_VALID  ),
	.MASTER_RD_ADDR_READY 	( M_RD_ADDR_READY  ),
	.MASTER_RD_BACK_ID    	( M_RD_BACK_ID     ),
	.MASTER_RD_DATA       	( M_RD_DATA        ),
	.MASTER_RD_DATA_RESP  	( M_RD_DATA_RESP   ),
	.MASTER_RD_DATA_LAST  	( M_RD_DATA_LAST   ),
	.MASTER_RD_DATA_VALID 	( M_RD_DATA_VALID  ),
	.MASTER_RD_DATA_READY 	( M_RD_DATA_READY  ),
	.SLAVE_CLK            	( S_CLK            ),
	.SLAVE_RSTN           	( S_RSTN           ),
	.SLAVE_WR_ADDR_ID     	( S_WR_ADDR_ID     ),
	.SLAVE_WR_ADDR        	( S_WR_ADDR        ),
	.SLAVE_WR_ADDR_LEN    	( S_WR_ADDR_LEN    ),
	.SLAVE_WR_ADDR_BURST  	( S_WR_ADDR_BURST  ),
	.SLAVE_WR_ADDR_VALID  	( S_WR_ADDR_VALID  ),
	.SLAVE_WR_ADDR_READY  	( S_WR_ADDR_READY  ),
	.SLAVE_WR_DATA        	( S_WR_DATA        ),
	.SLAVE_WR_STRB        	( S_WR_STRB        ),
	.SLAVE_WR_DATA_LAST   	( S_WR_DATA_LAST   ),
	.SLAVE_WR_DATA_VALID  	( S_WR_DATA_VALID  ),
	.SLAVE_WR_DATA_READY  	( S_WR_DATA_READY  ),
	.SLAVE_WR_BACK_ID     	( S_WR_BACK_ID     ),
	.SLAVE_WR_BACK_RESP   	( S_WR_BACK_RESP   ),
	.SLAVE_WR_BACK_VALID  	( S_WR_BACK_VALID  ),
	.SLAVE_WR_BACK_READY  	( S_WR_BACK_READY  ),
	.SLAVE_RD_ADDR_ID     	( S_RD_ADDR_ID     ),
	.SLAVE_RD_ADDR        	( S_RD_ADDR        ),
	.SLAVE_RD_ADDR_LEN    	( S_RD_ADDR_LEN    ),
	.SLAVE_RD_ADDR_BURST  	( S_RD_ADDR_BURST  ),
	.SLAVE_RD_ADDR_VALID  	( S_RD_ADDR_VALID  ),
	.SLAVE_RD_ADDR_READY  	( S_RD_ADDR_READY  ),
	.SLAVE_RD_BACK_ID     	( S_RD_BACK_ID     ),
	.SLAVE_RD_DATA        	( S_RD_DATA        ),
	.SLAVE_RD_DATA_RESP   	( S_RD_DATA_RESP   ),
	.SLAVE_RD_DATA_LAST   	( S_RD_DATA_LAST   ),
	.SLAVE_RD_DATA_VALID  	( S_RD_DATA_VALID  ),
	.SLAVE_RD_DATA_READY  	( S_RD_DATA_READY  ),
	.M_fifo_empty_flag    	( M_fifo_empty_flag),
	.S_fifo_empty_flag    	( S_fifo_empty_flag)
);


wire [15:0][7:0] data_in;
assign data_in[0]    = {3'b0,M_fifo_empty_flag[0]};
assign data_in[1]    = {3'b0,M_fifo_empty_flag[1]};
assign data_in[2]    = {3'b0,M_fifo_empty_flag[2]};
assign data_in[3]    = {3'b0,M_fifo_empty_flag[3]};
assign data_in[4]    = {3'b0,S_fifo_empty_flag[0]};
assign data_in[5]    = {3'b0,S_fifo_empty_flag[1]};
assign data_in[6]    = {3'b0,S_fifo_empty_flag[2]};
assign data_in[7]    = {3'b0,S_fifo_empty_flag[3]};
assign data_in[8]    = {udp_led};
assign data_in[9]    = 8'b00001111;
assign data_in[10]   = 8'b11110000;
assign data_in[11]   = 8'b00001111;
assign data_in[12]   = 8'b10101010;
assign data_in[13]   = 8'b01010101;
assign data_in[14]   = 8'b11110000;
assign data_in[15]   = 8'b00001111;

// led8_btn u_led8_btn(
// 	.clk      	( clk_50M   ),
// 	.rstn     	( sys_rstn  ),
// 	.data_in  	( data_in   ),
// 	.btn_up   	( btn[0]    ),
// 	.btn_down 	( btn[1]    ),
// 	.led      	(           ),
// 	.led_n    	( led8      ),
// 	.bcd      	( led4      ),
// 	.bcd_n    	(           )
// );

btn_led_boot_ctrl u_btn_led_boot_ctrl(
	.clk        	( clk_50M     ),
	.rstn       	( sys_rstn    ),
	.btn        	( &btn        ),
	.booting		( booting     ),
	.admin_mode 	( admin_mode  ),
	.led        	( led4        )
);


endmodule
