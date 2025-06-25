module udp_axi_ddr_update_top #(
    parameter BOARD_MAC     = {48'h12_34_56_78_9A_BC      }  ,
    parameter BOARD_IP      = {8'd169,8'd254,8'd109,8'd005}  , //169.254.109.5  8'd169,8'd254,8'd103,8'd006
    parameter DES_MAC       = {48'h84_47_09_4C_47_7C      }  , //00_2B_67_09_FF_5E
    parameter DES_IP        = {8'd169,8'd254,8'd109,8'd183}    //8'd169,8'd254,8'd103,8'd126
)(
//system io
input  wire        external_clk ,
input  wire        external_rstn,
//btn io
input  wire [3:0]  btn          ,
//led io
output wire [7:0]  led8         ,
output wire [3:0]  led4         ,
//jtag io
output wire        tck          ,
output wire        tms          ,
output wire        tdi          ,
input  wire        tdo          ,
//spi io
output wire        spi_cs       ,
// output wire        spi_clk      ,
input  wire        spi_dq1      ,
output wire        spi_dq0      ,
//i2c io
inout  wire        scl,
inout  wire        sda,
//eth io
input  wire        rgmii_rxc    ,
input  wire        rgmii_rx_ctl ,
input  wire [3:0]  rgmii_rxd    ,
output wire        rgmii_txc    ,
output wire        rgmii_tx_ctl ,
output wire [3:0]  rgmii_txd    ,
output wire        eth_rst_n    ,
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
/*
装载比特流的顺序：
0. CMD_JTAG_CLOSE_TEST                  0
1. CMD_JTAG_RUN_TEST                    0
2. CMD_JTAG_LOAD_IR    `JTAG_DR_JRST    10
3. CMD_JTAG_RUN_TEST                    0
4. CMD_JTAG_LOAD_IR    `JTAG_DR_CFGI    10
5. CMD_JTAG_IDLE_DELAY                  75000
6. CMD_JTAG_LOAD_DR    "BITSTREAM"      取决于比特流大小
7. CMD_JTAG_CLOSE_TEST                  0
8. CMD_JTAG_RUN_TEST                    0
9. CMD_JTAG_LOAD_IR    `JTAG_DR_JWAKEUP 10
A. CMD_JTAG_IDLE_DELAY                  1000
B. CMD_JTAG_CLOSE_TEST                  0
*/

/*
获取IDCODE的顺序：
0. CMD_JTAG_CLOSE_TEST                  0
1. CMD_JTAG_RUN_TEST                    0
2. CMD_JTAG_LOAD_IR    `JTAG_DR_IDCODE  10
3. CMD_JTAG_RUN_TEST                    0
4. CMD_JTAG_LOAD_DR    NOTCARE          32
5. CMD_JTAG_CLOSE_TEST                  0
*/

wire scl_out, scl_enable;
wire sda_out, sda_enable;

assign scl = (scl_enable)?(scl_out):(1'bz);
assign sda = (sda_enable)?(sda_out):(1'bz);

localparam M_WIDTH  = 2;
localparam S_WIDTH  = 2;
localparam M_ID     = 2;
localparam [0:(2**S_WIDTH-1)][31:0] START_ADDR = {32'h00000000, 32'h10000000, 32'h20000000, 32'h30000000};
localparam [0:(2**S_WIDTH-1)][31:0]   END_ADDR = {32'h0FFFFFFF, 32'h1FFFFFFF, 32'h2FFFFFFF, 32'h3FFFFFFF};

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
wire clk_lock;

wire [7:0] udp_led;

clk_pll_top clk_pll_top_inst (
  .clkout0(clk_50M),    // output
  .clkout1(clk_200M),    // output
  .clkout2(clk_5M),    // output
  .clkout3(clk_10M),
  .lock   (clk_lock),          // output
  .clkin1 (external_clk)       // input
);
wire sys_clk     = clk_50M;
wire led_clk     = clk_50M;
wire BUS_CLK     = clk_50M;
wire ddr_ref_clk = clk_50M;
wire jtag_clk    = clk_5M;
wire ru_clk      = clk_10M;

wire eth_rst_n   = 1;
wire sys_rstn    = (external_rstn) && (clk_lock);
wire BUS_RSTN    = (external_rstn) && (clk_lock);
wire udp_in_rstn = (external_rstn) && (clk_lock);
wire led_rst_n   = (external_rstn) && (clk_lock);
wire ddr_rst_n   = (external_rstn) && (clk_lock);
wire jtag_rstn   = (external_rstn) && (clk_lock);
wire ru_rstn     = (external_rstn) && (clk_lock);

axi_udp_master #(
	.BOARD_MAC 	(BOARD_MAC),
	.BOARD_IP  	(BOARD_IP ),
	.DES_MAC   	(DES_MAC  ),
	.DES_IP    	(DES_IP   )
)M0(
	.udp_in_rstn            ( udp_in_rstn     ),
	.eth_rst_n              (                 ),
	.rgmii_rxc            	( rgmii_rxc       ),
	.rgmii_rx_ctl         	( rgmii_rx_ctl    ),
	.rgmii_rxd            	( rgmii_rxd       ),
	.rgmii_txc            	( rgmii_txc       ),
	.rgmii_tx_ctl         	( rgmii_tx_ctl    ),
	.rgmii_txd            	( rgmii_txd       ),

    .udp_led                ( udp_led         ),
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


axi_master_default M1(
    .clk                  (sys_clk          ),
    .rstn                 (sys_rstn         ),
    .MASTER_CLK           (M_CLK          [1]),
    .MASTER_RSTN          (M_RSTN         [1]),
    .MASTER_WR_ADDR_ID    (M_WR_ADDR_ID   [1]),
    .MASTER_WR_ADDR       (M_WR_ADDR      [1]),
    .MASTER_WR_ADDR_LEN   (M_WR_ADDR_LEN  [1]),
    .MASTER_WR_ADDR_BURST (M_WR_ADDR_BURST[1]),
    .MASTER_WR_ADDR_VALID (M_WR_ADDR_VALID[1]),
    .MASTER_WR_ADDR_READY (M_WR_ADDR_READY[1]),
    .MASTER_WR_DATA       (M_WR_DATA      [1]),
    .MASTER_WR_STRB       (M_WR_STRB      [1]),
    .MASTER_WR_DATA_LAST  (M_WR_DATA_LAST [1]),
    .MASTER_WR_DATA_VALID (M_WR_DATA_VALID[1]),
    .MASTER_WR_DATA_READY (M_WR_DATA_READY[1]),
    .MASTER_WR_BACK_ID    (M_WR_BACK_ID   [1]),
    .MASTER_WR_BACK_RESP  (M_WR_BACK_RESP [1]),
    .MASTER_WR_BACK_VALID (M_WR_BACK_VALID[1]),
    .MASTER_WR_BACK_READY (M_WR_BACK_READY[1]),
    .MASTER_RD_ADDR_ID    (M_RD_ADDR_ID   [1]),
    .MASTER_RD_ADDR       (M_RD_ADDR      [1]),
    .MASTER_RD_ADDR_LEN   (M_RD_ADDR_LEN  [1]),
    .MASTER_RD_ADDR_BURST (M_RD_ADDR_BURST[1]),
    .MASTER_RD_ADDR_VALID (M_RD_ADDR_VALID[1]),
    .MASTER_RD_ADDR_READY (M_RD_ADDR_READY[1]),
    .MASTER_RD_BACK_ID    (M_RD_BACK_ID   [1]),
    .MASTER_RD_DATA       (M_RD_DATA      [1]),
    .MASTER_RD_DATA_RESP  (M_RD_DATA_RESP [1]),
    .MASTER_RD_DATA_LAST  (M_RD_DATA_LAST [1]),
    .MASTER_RD_DATA_VALID (M_RD_DATA_VALID[1]),
    .MASTER_RD_DATA_READY (M_RD_DATA_READY[1])
);

axi_master_default M2(
    .clk                  (sys_clk          ),
    .rstn                 (sys_rstn         ),
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
    .MASTER_RD_DATA_READY (M_RD_DATA_READY[2])
);

axi_master_default M3(
    .clk                  (sys_clk          ),
    .rstn                 (sys_rstn         ),
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
    .ddr_ref_clk             (ddr_ref_clk      ),
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
    .clk                      (jtag_clk        ),
    .rstn                     (jtag_rstn       ),
    .tck                      (tck             ),
    .tdi                      (tdi             ),
    .tms                      (tms             ),
    .tdo                      (tdo             ),
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
    .clk                 (ru_clk            ),
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
	.clk                 	( sys_clk           ),
	.rstn                	( sys_rstn          ),
    .scl_in                 ( scl               ),
    .scl_out                ( scl_out           ),
    .scl_enable             ( scl_enable        ),
    .sda_in                 ( sda               ),
    .sda_out                ( sda_out           ),
    .sda_enable             ( sda_enable        ),
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

axi_bus #(
	.M_ID       	( M_ID      ),
	.M_WIDTH    	( M_WIDTH   ),
	.S_WIDTH    	( S_WIDTH   ),
	.START_ADDR 	( START_ADDR),
	.END_ADDR   	( END_ADDR  ))
u_axi_bus(
	.BUS_CLK              	( BUS_CLK          ),
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

led8_btn u_led8_btn(
	.clk      	( sys_clk   ),
	.rstn     	( sys_rstn  ),
	.data_in  	( data_in   ),
	.btn_up   	( btn[0]    ),
	.btn_down 	( btn[1]    ),
	.led      	(           ),
	.led_n    	( led8      ),
	.bcd      	( led4      ),
	.bcd_n    	(           )
);


endmodule
