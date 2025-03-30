module udp_axi_ddr_top #(
    parameter BOARD_MAC     = {48'h12_34_56_78_9A_BC      }  ,
    parameter BOARD_IP      = {8'd169,8'd254,8'd103,8'd006}  ,
    parameter DES_MAC       = {48'h00_2B_67_09_FF_5E      }  ,
    parameter DES_IP        = {8'd169,8'd254,8'd103,8'd126}  
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

localparam S0_START_ADDR = 32'h00_00_00_00;
localparam S0_END_ADDR   = 32'h0F_FF_FF_FF;
localparam S1_START_ADDR = 32'h10_00_00_00;
localparam S1_END_ADDR   = 32'h1F_FF_FF_0F;
localparam S2_START_ADDR = 32'h20_00_00_00;
localparam S2_END_ADDR   = 32'h2F_FF_FF_0F;
localparam S3_START_ADDR = 32'h30_00_00_00;
localparam S3_END_ADDR   = 32'h3F_FF_FF_0F;

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

wire        M0_CLK          ;wire        M1_CLK          ;wire        M2_CLK          ;wire        M3_CLK          ;    wire        S0_CLK          ;wire        S1_CLK          ;wire        S2_CLK          ;wire        S3_CLK          ;
wire        M0_RSTN         ;wire        M1_RSTN         ;wire        M2_RSTN         ;wire        M3_RSTN         ;    wire        S0_RSTN         ;wire        S1_RSTN         ;wire        S2_RSTN         ;wire        S3_RSTN         ;
wire [ 1:0] M0_WR_ADDR_ID   ;wire [ 1:0] M1_WR_ADDR_ID   ;wire [ 1:0] M2_WR_ADDR_ID   ;wire [ 1:0] M3_WR_ADDR_ID   ;    wire [ 3:0] S0_WR_ADDR_ID   ;wire [ 3:0] S1_WR_ADDR_ID   ;wire [ 3:0] S2_WR_ADDR_ID   ;wire [ 3:0] S3_WR_ADDR_ID   ;
wire [31:0] M0_WR_ADDR      ;wire [31:0] M1_WR_ADDR      ;wire [31:0] M2_WR_ADDR      ;wire [31:0] M3_WR_ADDR      ;    wire [31:0] S0_WR_ADDR      ;wire [31:0] S1_WR_ADDR      ;wire [31:0] S2_WR_ADDR      ;wire [31:0] S3_WR_ADDR      ;
wire [ 7:0] M0_WR_ADDR_LEN  ;wire [ 7:0] M1_WR_ADDR_LEN  ;wire [ 7:0] M2_WR_ADDR_LEN  ;wire [ 7:0] M3_WR_ADDR_LEN  ;    wire [ 7:0] S0_WR_ADDR_LEN  ;wire [ 7:0] S1_WR_ADDR_LEN  ;wire [ 7:0] S2_WR_ADDR_LEN  ;wire [ 7:0] S3_WR_ADDR_LEN  ;
wire [ 1:0] M0_WR_ADDR_BURST;wire [ 1:0] M1_WR_ADDR_BURST;wire [ 1:0] M2_WR_ADDR_BURST;wire [ 1:0] M3_WR_ADDR_BURST;    wire [ 1:0] S0_WR_ADDR_BURST;wire [ 1:0] S1_WR_ADDR_BURST;wire [ 1:0] S2_WR_ADDR_BURST;wire [ 1:0] S3_WR_ADDR_BURST;
wire        M0_WR_ADDR_VALID;wire        M1_WR_ADDR_VALID;wire        M2_WR_ADDR_VALID;wire        M3_WR_ADDR_VALID;    wire        S0_WR_ADDR_VALID;wire        S1_WR_ADDR_VALID;wire        S2_WR_ADDR_VALID;wire        S3_WR_ADDR_VALID;
wire        M0_WR_ADDR_READY;wire        M1_WR_ADDR_READY;wire        M2_WR_ADDR_READY;wire        M3_WR_ADDR_READY;    wire        S0_WR_ADDR_READY;wire        S1_WR_ADDR_READY;wire        S2_WR_ADDR_READY;wire        S3_WR_ADDR_READY;
wire [31:0] M0_WR_DATA      ;wire [31:0] M1_WR_DATA      ;wire [31:0] M2_WR_DATA      ;wire [31:0] M3_WR_DATA      ;    wire [31:0] S0_WR_DATA      ;wire [31:0] S1_WR_DATA      ;wire [31:0] S2_WR_DATA      ;wire [31:0] S3_WR_DATA      ;
wire [ 3:0] M0_WR_STRB      ;wire [ 3:0] M1_WR_STRB      ;wire [ 3:0] M2_WR_STRB      ;wire [ 3:0] M3_WR_STRB      ;    wire [ 3:0] S0_WR_STRB      ;wire [ 3:0] S1_WR_STRB      ;wire [ 3:0] S2_WR_STRB      ;wire [ 3:0] S3_WR_STRB      ;
wire        M0_WR_DATA_LAST ;wire        M1_WR_DATA_LAST ;wire        M2_WR_DATA_LAST ;wire        M3_WR_DATA_LAST ;    wire        S0_WR_DATA_LAST ;wire        S1_WR_DATA_LAST ;wire        S2_WR_DATA_LAST ;wire        S3_WR_DATA_LAST ;
wire        M0_WR_DATA_VALID;wire        M1_WR_DATA_VALID;wire        M2_WR_DATA_VALID;wire        M3_WR_DATA_VALID;    wire        S0_WR_DATA_VALID;wire        S1_WR_DATA_VALID;wire        S2_WR_DATA_VALID;wire        S3_WR_DATA_VALID;
wire        M0_WR_DATA_READY;wire        M1_WR_DATA_READY;wire        M2_WR_DATA_READY;wire        M3_WR_DATA_READY;    wire        S0_WR_DATA_READY;wire        S1_WR_DATA_READY;wire        S2_WR_DATA_READY;wire        S3_WR_DATA_READY;
wire [ 1:0] M0_WR_BACK_ID   ;wire [ 1:0] M1_WR_BACK_ID   ;wire [ 1:0] M2_WR_BACK_ID   ;wire [ 1:0] M3_WR_BACK_ID   ;    wire [ 3:0] S0_WR_BACK_ID   ;wire [ 3:0] S1_WR_BACK_ID   ;wire [ 3:0] S2_WR_BACK_ID   ;wire [ 3:0] S3_WR_BACK_ID   ;
wire [ 1:0] M0_WR_BACK_RESP ;wire [ 1:0] M1_WR_BACK_RESP ;wire [ 1:0] M2_WR_BACK_RESP ;wire [ 1:0] M3_WR_BACK_RESP ;    wire [ 1:0] S0_WR_BACK_RESP ;wire [ 1:0] S1_WR_BACK_RESP ;wire [ 1:0] S2_WR_BACK_RESP ;wire [ 1:0] S3_WR_BACK_RESP ;
wire        M0_WR_BACK_VALID;wire        M1_WR_BACK_VALID;wire        M2_WR_BACK_VALID;wire        M3_WR_BACK_VALID;    wire        S0_WR_BACK_VALID;wire        S1_WR_BACK_VALID;wire        S2_WR_BACK_VALID;wire        S3_WR_BACK_VALID;
wire        M0_WR_BACK_READY;wire        M1_WR_BACK_READY;wire        M2_WR_BACK_READY;wire        M3_WR_BACK_READY;    wire        S0_WR_BACK_READY;wire        S1_WR_BACK_READY;wire        S2_WR_BACK_READY;wire        S3_WR_BACK_READY;
wire [ 1:0] M0_RD_ADDR_ID   ;wire [ 1:0] M1_RD_ADDR_ID   ;wire [ 1:0] M2_RD_ADDR_ID   ;wire [ 1:0] M3_RD_ADDR_ID   ;    wire [ 3:0] S0_RD_ADDR_ID   ;wire [ 3:0] S1_RD_ADDR_ID   ;wire [ 3:0] S2_RD_ADDR_ID   ;wire [ 3:0] S3_RD_ADDR_ID   ;
wire [31:0] M0_RD_ADDR      ;wire [31:0] M1_RD_ADDR      ;wire [31:0] M2_RD_ADDR      ;wire [31:0] M3_RD_ADDR      ;    wire [31:0] S0_RD_ADDR      ;wire [31:0] S1_RD_ADDR      ;wire [31:0] S2_RD_ADDR      ;wire [31:0] S3_RD_ADDR      ;
wire [ 7:0] M0_RD_ADDR_LEN  ;wire [ 7:0] M1_RD_ADDR_LEN  ;wire [ 7:0] M2_RD_ADDR_LEN  ;wire [ 7:0] M3_RD_ADDR_LEN  ;    wire [ 7:0] S0_RD_ADDR_LEN  ;wire [ 7:0] S1_RD_ADDR_LEN  ;wire [ 7:0] S2_RD_ADDR_LEN  ;wire [ 7:0] S3_RD_ADDR_LEN  ;
wire [ 1:0] M0_RD_ADDR_BURST;wire [ 1:0] M1_RD_ADDR_BURST;wire [ 1:0] M2_RD_ADDR_BURST;wire [ 1:0] M3_RD_ADDR_BURST;    wire [ 1:0] S0_RD_ADDR_BURST;wire [ 1:0] S1_RD_ADDR_BURST;wire [ 1:0] S2_RD_ADDR_BURST;wire [ 1:0] S3_RD_ADDR_BURST;
wire        M0_RD_ADDR_VALID;wire        M1_RD_ADDR_VALID;wire        M2_RD_ADDR_VALID;wire        M3_RD_ADDR_VALID;    wire        S0_RD_ADDR_VALID;wire        S1_RD_ADDR_VALID;wire        S2_RD_ADDR_VALID;wire        S3_RD_ADDR_VALID;
wire        M0_RD_ADDR_READY;wire        M1_RD_ADDR_READY;wire        M2_RD_ADDR_READY;wire        M3_RD_ADDR_READY;    wire        S0_RD_ADDR_READY;wire        S1_RD_ADDR_READY;wire        S2_RD_ADDR_READY;wire        S3_RD_ADDR_READY;
wire [ 1:0] M0_RD_BACK_ID   ;wire [ 1:0] M1_RD_BACK_ID   ;wire [ 1:0] M2_RD_BACK_ID   ;wire [ 1:0] M3_RD_BACK_ID   ;    wire [ 3:0] S0_RD_BACK_ID   ;wire [ 3:0] S1_RD_BACK_ID   ;wire [ 3:0] S2_RD_BACK_ID   ;wire [ 3:0] S3_RD_BACK_ID   ;
wire [31:0] M0_RD_DATA      ;wire [31:0] M1_RD_DATA      ;wire [31:0] M2_RD_DATA      ;wire [31:0] M3_RD_DATA      ;    wire [31:0] S0_RD_DATA      ;wire [31:0] S1_RD_DATA      ;wire [31:0] S2_RD_DATA      ;wire [31:0] S3_RD_DATA      ;
wire [ 1:0] M0_RD_DATA_RESP ;wire [ 1:0] M1_RD_DATA_RESP ;wire [ 1:0] M2_RD_DATA_RESP ;wire [ 1:0] M3_RD_DATA_RESP ;    wire [ 1:0] S0_RD_DATA_RESP ;wire [ 1:0] S1_RD_DATA_RESP ;wire [ 1:0] S2_RD_DATA_RESP ;wire [ 1:0] S3_RD_DATA_RESP ;
wire        M0_RD_DATA_LAST ;wire        M1_RD_DATA_LAST ;wire        M2_RD_DATA_LAST ;wire        M3_RD_DATA_LAST ;    wire        S0_RD_DATA_LAST ;wire        S1_RD_DATA_LAST ;wire        S2_RD_DATA_LAST ;wire        S3_RD_DATA_LAST ;
wire        M0_RD_DATA_VALID;wire        M1_RD_DATA_VALID;wire        M2_RD_DATA_VALID;wire        M3_RD_DATA_VALID;    wire        S0_RD_DATA_VALID;wire        S1_RD_DATA_VALID;wire        S2_RD_DATA_VALID;wire        S3_RD_DATA_VALID;
wire        M0_RD_DATA_READY;wire        M1_RD_DATA_READY;wire        M2_RD_DATA_READY;wire        M3_RD_DATA_READY;    wire        S0_RD_DATA_READY;wire        S1_RD_DATA_READY;wire        S2_RD_DATA_READY;wire        S3_RD_DATA_READY;

wire clk_50M;
wire clk_200M;
wire clk_5M;
wire clk_lock;

wire sys_clk;
wire BUS_CLK;
wire led_clk;
wire ddr_ref_clk;
wire jtag_clk;

wire sys_rstn   ;
wire BUS_RSTN   ;
wire udp_in_rstn;
wire led_rst_n  ;
wire ddr_rst_n  ;
wire jtag_rstn  ;

wire ddr_init_done;
wire [31:0] axi_led;
wire [31:0] m1_recv_led;

wire [4:0] M0_fifo_empty_flag, M1_fifo_empty_flag, M2_fifo_empty_flag, M3_fifo_empty_flag;
wire [4:0] S0_fifo_empty_flag, S1_fifo_empty_flag, S2_fifo_empty_flag, S3_fifo_empty_flag;

clk_pll_top the_instance_name (
  .clkout0(clk_50M),    // output
  .clkout1(clk_200M),    // output
  .clkout2(clk_5M),    // output
  .lock   (clk_lock),          // output
  .clkin1 (external_clk)       // input
);
assign sys_clk     = clk_50M;
assign led_clk     = clk_50M;
assign BUS_CLK     = clk_50M;
assign ddr_ref_clk = clk_50M;
assign jtag_clk    = clk_5M;

assign sys_rstn    = (external_rstn) & (clk_lock);
assign BUS_RSTN    = (external_rstn) & (clk_lock);
assign udp_in_rstn = (external_rstn) & (clk_lock);
assign led_rst_n   = (external_rstn) & (clk_lock);
assign ddr_rst_n   = (external_rstn) & (clk_lock);
assign jtag_rstn   = (external_rstn) & (clk_lock);

axi_udp_master #(
	.BOARD_MAC 	(BOARD_MAC),
	.BOARD_IP  	(BOARD_IP ),
	.DES_MAC   	(DES_MAC  ),
	.DES_IP    	(DES_IP   )
)M0(
	.udp_in_rstn            ( udp_in_rstn     ),
	.eth_rst_n              ( eth_rst_n       ),
	.rgmii_rxc            	( rgmii_rxc       ),
	.rgmii_rx_ctl         	( rgmii_rx_ctl    ),
	.rgmii_rxd            	( rgmii_rxd       ),
	.rgmii_txc            	( rgmii_txc       ),
	.rgmii_tx_ctl         	( rgmii_tx_ctl    ),
	.rgmii_txd            	( rgmii_txd       ),

   .udp_led                (           ),
	.MASTER_CLK           	( M0_CLK          ),
	.MASTER_RSTN          	( M0_RSTN         ),
	.MASTER_WR_ADDR_ID    	( M0_WR_ADDR_ID   ),
	.MASTER_WR_ADDR       	( M0_WR_ADDR      ),
	.MASTER_WR_ADDR_LEN   	( M0_WR_ADDR_LEN  ),
	.MASTER_WR_ADDR_BURST 	( M0_WR_ADDR_BURST),
	.MASTER_WR_ADDR_VALID 	( M0_WR_ADDR_VALID),
	.MASTER_WR_ADDR_READY 	( M0_WR_ADDR_READY),
	.MASTER_WR_DATA       	( M0_WR_DATA      ),
	.MASTER_WR_STRB       	( M0_WR_STRB      ),
	.MASTER_WR_DATA_LAST  	( M0_WR_DATA_LAST ),
	.MASTER_WR_DATA_VALID 	( M0_WR_DATA_VALID),
	.MASTER_WR_DATA_READY 	( M0_WR_DATA_READY),
	.MASTER_WR_BACK_ID    	( M0_WR_BACK_ID   ),
	.MASTER_WR_BACK_RESP  	( M0_WR_BACK_RESP ),
	.MASTER_WR_BACK_VALID 	( M0_WR_BACK_VALID),
	.MASTER_WR_BACK_READY 	( M0_WR_BACK_READY),
	.MASTER_RD_ADDR_ID    	( M0_RD_ADDR_ID   ),
	.MASTER_RD_ADDR       	( M0_RD_ADDR      ),
	.MASTER_RD_ADDR_LEN   	( M0_RD_ADDR_LEN  ),
	.MASTER_RD_ADDR_BURST 	( M0_RD_ADDR_BURST),
	.MASTER_RD_ADDR_VALID 	( M0_RD_ADDR_VALID),
	.MASTER_RD_ADDR_READY 	( M0_RD_ADDR_READY),
	.MASTER_RD_BACK_ID    	( M0_RD_BACK_ID   ),
	.MASTER_RD_DATA       	( M0_RD_DATA      ),
	.MASTER_RD_DATA_RESP  	( M0_RD_DATA_RESP ),
	.MASTER_RD_DATA_LAST  	( M0_RD_DATA_LAST ),
	.MASTER_RD_DATA_VALID 	( M0_RD_DATA_VALID),
	.MASTER_RD_DATA_READY 	( M0_RD_DATA_READY)
);


axi_master_default M1(
    .clk                  (sys_clk          ),
    .rstn                 (sys_rstn         ),
    .MASTER_CLK           (M1_CLK           ),
    .MASTER_RSTN          (M1_RSTN          ),
    .MASTER_WR_ADDR_ID    (M1_WR_ADDR_ID    ),
    .MASTER_WR_ADDR       (M1_WR_ADDR       ),
    .MASTER_WR_ADDR_LEN   (M1_WR_ADDR_LEN   ),
    .MASTER_WR_ADDR_BURST (M1_WR_ADDR_BURST ),
    .MASTER_WR_ADDR_VALID (M1_WR_ADDR_VALID ),
    .MASTER_WR_ADDR_READY (M1_WR_ADDR_READY ),
    .MASTER_WR_DATA       (M1_WR_DATA       ),
    .MASTER_WR_STRB       (M1_WR_STRB       ),
    .MASTER_WR_DATA_LAST  (M1_WR_DATA_LAST  ),
    .MASTER_WR_DATA_VALID (M1_WR_DATA_VALID ),
    .MASTER_WR_DATA_READY (M1_WR_DATA_READY ),
    .MASTER_WR_BACK_ID    (M1_WR_BACK_ID    ),
    .MASTER_WR_BACK_RESP  (M1_WR_BACK_RESP  ),
    .MASTER_WR_BACK_VALID (M1_WR_BACK_VALID ),
    .MASTER_WR_BACK_READY (M1_WR_BACK_READY ),
    .MASTER_RD_ADDR_ID    (M1_RD_ADDR_ID    ),
    .MASTER_RD_ADDR       (M1_RD_ADDR       ),
    .MASTER_RD_ADDR_LEN   (M1_RD_ADDR_LEN   ),
    .MASTER_RD_ADDR_BURST (M1_RD_ADDR_BURST ),
    .MASTER_RD_ADDR_VALID (M1_RD_ADDR_VALID ),
    .MASTER_RD_ADDR_READY (M1_RD_ADDR_READY ),
    .MASTER_RD_BACK_ID    (M1_RD_BACK_ID    ),
    .MASTER_RD_DATA       (M1_RD_DATA       ),
    .MASTER_RD_DATA_RESP  (M1_RD_DATA_RESP  ),
    .MASTER_RD_DATA_LAST  (M1_RD_DATA_LAST  ),
    .MASTER_RD_DATA_VALID (M1_RD_DATA_VALID ),
    .MASTER_RD_DATA_READY (M1_RD_DATA_READY )
);

axi_master_default M2(
    .clk                  (sys_clk          ),
    .rstn                 (sys_rstn         ),
    .MASTER_CLK           (M2_CLK           ),
    .MASTER_RSTN          (M2_RSTN          ),
    .MASTER_WR_ADDR_ID    (M2_WR_ADDR_ID    ),
    .MASTER_WR_ADDR       (M2_WR_ADDR       ),
    .MASTER_WR_ADDR_LEN   (M2_WR_ADDR_LEN   ),
    .MASTER_WR_ADDR_BURST (M2_WR_ADDR_BURST ),
    .MASTER_WR_ADDR_VALID (M2_WR_ADDR_VALID ),
    .MASTER_WR_ADDR_READY (M2_WR_ADDR_READY ),
    .MASTER_WR_DATA       (M2_WR_DATA       ),
    .MASTER_WR_STRB       (M2_WR_STRB       ),
    .MASTER_WR_DATA_LAST  (M2_WR_DATA_LAST  ),
    .MASTER_WR_DATA_VALID (M2_WR_DATA_VALID ),
    .MASTER_WR_DATA_READY (M2_WR_DATA_READY ),
    .MASTER_WR_BACK_ID    (M2_WR_BACK_ID    ),
    .MASTER_WR_BACK_RESP  (M2_WR_BACK_RESP  ),
    .MASTER_WR_BACK_VALID (M2_WR_BACK_VALID ),
    .MASTER_WR_BACK_READY (M2_WR_BACK_READY ),
    .MASTER_RD_ADDR_ID    (M2_RD_ADDR_ID    ),
    .MASTER_RD_ADDR       (M2_RD_ADDR       ),
    .MASTER_RD_ADDR_LEN   (M2_RD_ADDR_LEN   ),
    .MASTER_RD_ADDR_BURST (M2_RD_ADDR_BURST ),
    .MASTER_RD_ADDR_VALID (M2_RD_ADDR_VALID ),
    .MASTER_RD_ADDR_READY (M2_RD_ADDR_READY ),
    .MASTER_RD_BACK_ID    (M2_RD_BACK_ID    ),
    .MASTER_RD_DATA       (M2_RD_DATA       ),
    .MASTER_RD_DATA_RESP  (M2_RD_DATA_RESP  ),
    .MASTER_RD_DATA_LAST  (M2_RD_DATA_LAST  ),
    .MASTER_RD_DATA_VALID (M2_RD_DATA_VALID ),
    .MASTER_RD_DATA_READY (M2_RD_DATA_READY )
);

axi_master_default M3(
    .clk                  (sys_clk          ),
    .rstn                 (sys_rstn         ),
    .MASTER_CLK           (M3_CLK           ),
    .MASTER_RSTN          (M3_RSTN          ),
    .MASTER_WR_ADDR_ID    (M3_WR_ADDR_ID    ),
    .MASTER_WR_ADDR       (M3_WR_ADDR       ),
    .MASTER_WR_ADDR_LEN   (M3_WR_ADDR_LEN   ),
    .MASTER_WR_ADDR_BURST (M3_WR_ADDR_BURST ),
    .MASTER_WR_ADDR_VALID (M3_WR_ADDR_VALID ),
    .MASTER_WR_ADDR_READY (M3_WR_ADDR_READY ),
    .MASTER_WR_DATA       (M3_WR_DATA       ),
    .MASTER_WR_STRB       (M3_WR_STRB       ),
    .MASTER_WR_DATA_LAST  (M3_WR_DATA_LAST  ),
    .MASTER_WR_DATA_VALID (M3_WR_DATA_VALID ),
    .MASTER_WR_DATA_READY (M3_WR_DATA_READY ),
    .MASTER_WR_BACK_ID    (M3_WR_BACK_ID    ),
    .MASTER_WR_BACK_RESP  (M3_WR_BACK_RESP  ),
    .MASTER_WR_BACK_VALID (M3_WR_BACK_VALID ),
    .MASTER_WR_BACK_READY (M3_WR_BACK_READY ),
    .MASTER_RD_ADDR_ID    (M3_RD_ADDR_ID    ),
    .MASTER_RD_ADDR       (M3_RD_ADDR       ),
    .MASTER_RD_ADDR_LEN   (M3_RD_ADDR_LEN   ),
    .MASTER_RD_ADDR_BURST (M3_RD_ADDR_BURST ),
    .MASTER_RD_ADDR_VALID (M3_RD_ADDR_VALID ),
    .MASTER_RD_ADDR_READY (M3_RD_ADDR_READY ),
    .MASTER_RD_BACK_ID    (M3_RD_BACK_ID    ),
    .MASTER_RD_DATA       (M3_RD_DATA       ),
    .MASTER_RD_DATA_RESP  (M3_RD_DATA_RESP  ),
    .MASTER_RD_DATA_LAST  (M3_RD_DATA_LAST  ),
    .MASTER_RD_DATA_VALID (M3_RD_DATA_VALID ),
    .MASTER_RD_DATA_READY (M3_RD_DATA_READY )
);

slave_ddr3 #(
    .OFFSET_ADDR             (S0_START_ADDR)
)S0(
    .ddr_ref_clk             (ddr_ref_clk      ),
    .rst_n                   (ddr_rst_n        ),
    .ddr_init_done           (ddr_init_done    ),
    .DDR_SLAVE_CLK           (S0_CLK           ),
    .DDR_SLAVE_RSTN          (S0_RSTN          ),
    .DDR_SLAVE_WR_ADDR_ID    (S0_WR_ADDR_ID    ),
    .DDR_SLAVE_WR_ADDR       (S0_WR_ADDR       ),
    .DDR_SLAVE_WR_ADDR_LEN   (S0_WR_ADDR_LEN   ),
    .DDR_SLAVE_WR_ADDR_BURST (S0_WR_ADDR_BURST ),
    .DDR_SLAVE_WR_ADDR_VALID (S0_WR_ADDR_VALID ),
    .DDR_SLAVE_WR_ADDR_READY (S0_WR_ADDR_READY ),
    .DDR_SLAVE_WR_DATA       (S0_WR_DATA       ),
    .DDR_SLAVE_WR_STRB       (S0_WR_STRB       ),
    .DDR_SLAVE_WR_DATA_LAST  (S0_WR_DATA_LAST  ),
    .DDR_SLAVE_WR_DATA_VALID (S0_WR_DATA_VALID ),
    .DDR_SLAVE_WR_DATA_READY (S0_WR_DATA_READY ),
    .DDR_SLAVE_WR_BACK_ID    (S0_WR_BACK_ID    ),
    .DDR_SLAVE_WR_BACK_RESP  (S0_WR_BACK_RESP  ),
    .DDR_SLAVE_WR_BACK_VALID (S0_WR_BACK_VALID ),
    .DDR_SLAVE_WR_BACK_READY (S0_WR_BACK_READY ),
    .DDR_SLAVE_RD_ADDR_ID    (S0_RD_ADDR_ID    ),
    .DDR_SLAVE_RD_ADDR       (S0_RD_ADDR       ),
    .DDR_SLAVE_RD_ADDR_LEN   (S0_RD_ADDR_LEN   ),
    .DDR_SLAVE_RD_ADDR_BURST (S0_RD_ADDR_BURST ),
    .DDR_SLAVE_RD_ADDR_VALID (S0_RD_ADDR_VALID ),
    .DDR_SLAVE_RD_ADDR_READY (S0_RD_ADDR_READY ),
    .DDR_SLAVE_RD_BACK_ID    (S0_RD_BACK_ID    ),
    .DDR_SLAVE_RD_DATA       (S0_RD_DATA       ),
    .DDR_SLAVE_RD_DATA_RESP  (S0_RD_DATA_RESP  ),
    .DDR_SLAVE_RD_DATA_LAST  (S0_RD_DATA_LAST  ),
    .DDR_SLAVE_RD_DATA_VALID (S0_RD_DATA_VALID ),
    .DDR_SLAVE_RD_DATA_READY (S0_RD_DATA_READY ),
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

JTAG_SLAVE  #(
    .OFFSET_ADDR              (S1_START_ADDR)
)S1(
    .clk                      (jtag_clk        ),
    .rstn                     (jtag_rstn       ),
    .tck                      (tck             ),
    .tdi                      (tdi             ),
    .tms                      (tms             ),
    .tdo                      (tdo             ),
    .JTAG_SLAVE_CLK           (S1_CLK          ),
    .JTAG_SLAVE_RSTN          (S1_RSTN         ),
    .JTAG_SLAVE_WR_ADDR_ID    (S1_WR_ADDR_ID   ),
    .JTAG_SLAVE_WR_ADDR       (S1_WR_ADDR      ),
    .JTAG_SLAVE_WR_ADDR_LEN   (S1_WR_ADDR_LEN  ),
    .JTAG_SLAVE_WR_ADDR_BURST (S1_WR_ADDR_BURST),
    .JTAG_SLAVE_WR_ADDR_VALID (S1_WR_ADDR_VALID),
    .JTAG_SLAVE_WR_ADDR_READY (S1_WR_ADDR_READY),
    .JTAG_SLAVE_WR_DATA       (S1_WR_DATA      ),
    .JTAG_SLAVE_WR_STRB       (S1_WR_STRB      ),
    .JTAG_SLAVE_WR_DATA_LAST  (S1_WR_DATA_LAST ),
    .JTAG_SLAVE_WR_DATA_VALID (S1_WR_DATA_VALID),
    .JTAG_SLAVE_WR_DATA_READY (S1_WR_DATA_READY),
    .JTAG_SLAVE_WR_BACK_ID    (S1_WR_BACK_ID   ),
    .JTAG_SLAVE_WR_BACK_RESP  (S1_WR_BACK_RESP ),
    .JTAG_SLAVE_WR_BACK_VALID (S1_WR_BACK_VALID),
    .JTAG_SLAVE_WR_BACK_READY (S1_WR_BACK_READY),
    .JTAG_SLAVE_RD_ADDR_ID    (S1_RD_ADDR_ID   ),
    .JTAG_SLAVE_RD_ADDR       (S1_RD_ADDR      ),
    .JTAG_SLAVE_RD_ADDR_LEN   (S1_RD_ADDR_LEN  ),
    .JTAG_SLAVE_RD_ADDR_BURST (S1_RD_ADDR_BURST),
    .JTAG_SLAVE_RD_ADDR_VALID (S1_RD_ADDR_VALID),
    .JTAG_SLAVE_RD_ADDR_READY (S1_RD_ADDR_READY),
    .JTAG_SLAVE_RD_BACK_ID    (S1_RD_BACK_ID   ),
    .JTAG_SLAVE_RD_DATA       (S1_RD_DATA      ),
    .JTAG_SLAVE_RD_DATA_RESP  (S1_RD_DATA_RESP ),
    .JTAG_SLAVE_RD_DATA_LAST  (S1_RD_DATA_LAST ),
    .JTAG_SLAVE_RD_DATA_VALID (S1_RD_DATA_VALID),
    .JTAG_SLAVE_RD_DATA_READY (S1_RD_DATA_READY)
);

axi_led_slave #(
    .OFFSET_ADDR             (S2_START_ADDR)
)S2(
    .clk                     (led_clk         ),
    .rstn                    (led_rst_n       ),
    .led                     (          ),
    .LED_SLAVE_CLK           (S2_CLK          ),
    .LED_SLAVE_RSTN          (S2_RSTN         ),
    .LED_SLAVE_WR_ADDR_ID    (S2_WR_ADDR_ID   ),
    .LED_SLAVE_WR_ADDR       (S2_WR_ADDR      ),
    .LED_SLAVE_WR_ADDR_LEN   (S2_WR_ADDR_LEN  ),
    .LED_SLAVE_WR_ADDR_BURST (S2_WR_ADDR_BURST),
    .LED_SLAVE_WR_ADDR_VALID (S2_WR_ADDR_VALID),
    .LED_SLAVE_WR_ADDR_READY (S2_WR_ADDR_READY),
    .LED_SLAVE_WR_DATA       (S2_WR_DATA      ),
    .LED_SLAVE_WR_STRB       (S2_WR_STRB      ),
    .LED_SLAVE_WR_DATA_LAST  (S2_WR_DATA_LAST ),
    .LED_SLAVE_WR_DATA_VALID (S2_WR_DATA_VALID),
    .LED_SLAVE_WR_DATA_READY (S2_WR_DATA_READY),
    .LED_SLAVE_WR_BACK_ID    (S2_WR_BACK_ID   ),
    .LED_SLAVE_WR_BACK_RESP  (S2_WR_BACK_RESP ),
    .LED_SLAVE_WR_BACK_VALID (S2_WR_BACK_VALID),
    .LED_SLAVE_WR_BACK_READY (S2_WR_BACK_READY),
    .LED_SLAVE_RD_ADDR_ID    (S2_RD_ADDR_ID   ),
    .LED_SLAVE_RD_ADDR       (S2_RD_ADDR      ),
    .LED_SLAVE_RD_ADDR_LEN   (S2_RD_ADDR_LEN  ),
    .LED_SLAVE_RD_ADDR_BURST (S2_RD_ADDR_BURST),
    .LED_SLAVE_RD_ADDR_VALID (S2_RD_ADDR_VALID),
    .LED_SLAVE_RD_ADDR_READY (S2_RD_ADDR_READY),
    .LED_SLAVE_RD_BACK_ID    (S2_RD_BACK_ID   ),
    .LED_SLAVE_RD_DATA       (S2_RD_DATA      ),
    .LED_SLAVE_RD_DATA_RESP  (S2_RD_DATA_RESP ),
    .LED_SLAVE_RD_DATA_LAST  (S2_RD_DATA_LAST ),
    .LED_SLAVE_RD_DATA_VALID (S2_RD_DATA_VALID),
    .LED_SLAVE_RD_DATA_READY (S2_RD_DATA_READY)
);

axi_slave_default S3(
	.clk                 	( BUS_CLK           ),
	.rstn                	( BUS_RSTN          ),
	.SLAVE_CLK           	( S3_CLK            ),
	.SLAVE_RSTN          	( S3_RSTN           ),
	.SLAVE_WR_ADDR_ID    	( S3_WR_ADDR_ID     ),
	.SLAVE_WR_ADDR       	( S3_WR_ADDR        ),
	.SLAVE_WR_ADDR_LEN   	( S3_WR_ADDR_LEN    ),
	.SLAVE_WR_ADDR_BURST 	( S3_WR_ADDR_BURST  ),
	.SLAVE_WR_ADDR_VALID 	( S3_WR_ADDR_VALID  ),
	.SLAVE_WR_ADDR_READY 	( S3_WR_ADDR_READY  ),
	.SLAVE_WR_DATA       	( S3_WR_DATA        ),
	.SLAVE_WR_STRB       	( S3_WR_STRB        ),
	.SLAVE_WR_DATA_LAST  	( S3_WR_DATA_LAST   ),
	.SLAVE_WR_DATA_VALID 	( S3_WR_DATA_VALID  ),
	.SLAVE_WR_DATA_READY 	( S3_WR_DATA_READY  ),
	.SLAVE_WR_BACK_ID    	( S3_WR_BACK_ID     ),
	.SLAVE_WR_BACK_RESP  	( S3_WR_BACK_RESP   ),
	.SLAVE_WR_BACK_VALID 	( S3_WR_BACK_VALID  ),
	.SLAVE_WR_BACK_READY 	( S3_WR_BACK_READY  ),
	.SLAVE_RD_ADDR_ID    	( S3_RD_ADDR_ID     ),
	.SLAVE_RD_ADDR       	( S3_RD_ADDR        ),
	.SLAVE_RD_ADDR_LEN   	( S3_RD_ADDR_LEN    ),
	.SLAVE_RD_ADDR_BURST 	( S3_RD_ADDR_BURST  ),
	.SLAVE_RD_ADDR_VALID 	( S3_RD_ADDR_VALID  ),
	.SLAVE_RD_ADDR_READY 	( S3_RD_ADDR_READY  ),
	.SLAVE_RD_BACK_ID    	( S3_RD_BACK_ID     ),
	.SLAVE_RD_DATA       	( S3_RD_DATA        ),
	.SLAVE_RD_DATA_RESP  	( S3_RD_DATA_RESP   ),
	.SLAVE_RD_DATA_LAST  	( S3_RD_DATA_LAST   ),
	.SLAVE_RD_DATA_VALID 	( S3_RD_DATA_VALID  ),
	.SLAVE_RD_DATA_READY 	( S3_RD_DATA_READY  )
);


axi_bus #( //AXI顶层总线。支持主从机自设时钟域，内部设置FIFO。支持out-standing超前传输，从机可选择性支持out-of-order乱序执行，支持interleaving读交织。
    .S0_START_ADDR(S0_START_ADDR),
    .S0_END_ADDR  (S0_END_ADDR  ),
    .S1_START_ADDR(S1_START_ADDR),
    .S1_END_ADDR  (S1_END_ADDR  ),
    .S2_START_ADDR(S2_START_ADDR),
    .S2_END_ADDR  (S2_END_ADDR  ),
    .S3_START_ADDR(S3_START_ADDR),
    .S3_END_ADDR  (S3_END_ADDR  )
)axi_bus_inst(
.BUS_CLK         (BUS_CLK         ),
.BUS_RSTN        (BUS_RSTN        ),
.M0_CLK          (M0_CLK          ),   .M1_CLK          (M1_CLK          ),    .M2_CLK          (M2_CLK          ),    .M3_CLK          (M3_CLK          ),
.M0_RSTN         (M0_RSTN         ),   .M1_RSTN         (M1_RSTN         ),    .M2_RSTN         (M2_RSTN         ),    .M3_RSTN         (M3_RSTN         ),
.M0_WR_ADDR_ID   (M0_WR_ADDR_ID   ),   .M1_WR_ADDR_ID   (M1_WR_ADDR_ID   ),    .M2_WR_ADDR_ID   (M2_WR_ADDR_ID   ),    .M3_WR_ADDR_ID   (M3_WR_ADDR_ID   ),
.M0_WR_ADDR      (M0_WR_ADDR      ),   .M1_WR_ADDR      (M1_WR_ADDR      ),    .M2_WR_ADDR      (M2_WR_ADDR      ),    .M3_WR_ADDR      (M3_WR_ADDR      ),
.M0_WR_ADDR_LEN  (M0_WR_ADDR_LEN  ),   .M1_WR_ADDR_LEN  (M1_WR_ADDR_LEN  ),    .M2_WR_ADDR_LEN  (M2_WR_ADDR_LEN  ),    .M3_WR_ADDR_LEN  (M3_WR_ADDR_LEN  ),
.M0_WR_ADDR_BURST(M0_WR_ADDR_BURST),   .M1_WR_ADDR_BURST(M1_WR_ADDR_BURST),    .M2_WR_ADDR_BURST(M2_WR_ADDR_BURST),    .M3_WR_ADDR_BURST(M3_WR_ADDR_BURST),
.M0_WR_ADDR_VALID(M0_WR_ADDR_VALID),   .M1_WR_ADDR_VALID(M1_WR_ADDR_VALID),    .M2_WR_ADDR_VALID(M2_WR_ADDR_VALID),    .M3_WR_ADDR_VALID(M3_WR_ADDR_VALID),
.M0_WR_ADDR_READY(M0_WR_ADDR_READY),   .M1_WR_ADDR_READY(M1_WR_ADDR_READY),    .M2_WR_ADDR_READY(M2_WR_ADDR_READY),    .M3_WR_ADDR_READY(M3_WR_ADDR_READY),
.M0_WR_DATA      (M0_WR_DATA      ),   .M1_WR_DATA      (M1_WR_DATA      ),    .M2_WR_DATA      (M2_WR_DATA      ),    .M3_WR_DATA      (M3_WR_DATA      ),
.M0_WR_STRB      (M0_WR_STRB      ),   .M1_WR_STRB      (M1_WR_STRB      ),    .M2_WR_STRB      (M2_WR_STRB      ),    .M3_WR_STRB      (M3_WR_STRB      ),
.M0_WR_DATA_LAST (M0_WR_DATA_LAST ),   .M1_WR_DATA_LAST (M1_WR_DATA_LAST ),    .M2_WR_DATA_LAST (M2_WR_DATA_LAST ),    .M3_WR_DATA_LAST (M3_WR_DATA_LAST ),
.M0_WR_DATA_VALID(M0_WR_DATA_VALID),   .M1_WR_DATA_VALID(M1_WR_DATA_VALID),    .M2_WR_DATA_VALID(M2_WR_DATA_VALID),    .M3_WR_DATA_VALID(M3_WR_DATA_VALID),
.M0_WR_DATA_READY(M0_WR_DATA_READY),   .M1_WR_DATA_READY(M1_WR_DATA_READY),    .M2_WR_DATA_READY(M2_WR_DATA_READY),    .M3_WR_DATA_READY(M3_WR_DATA_READY),
.M0_WR_BACK_ID   (M0_WR_BACK_ID   ),   .M1_WR_BACK_ID   (M1_WR_BACK_ID   ),    .M2_WR_BACK_ID   (M2_WR_BACK_ID   ),    .M3_WR_BACK_ID   (M3_WR_BACK_ID   ),
.M0_WR_BACK_RESP (M0_WR_BACK_RESP ),   .M1_WR_BACK_RESP (M1_WR_BACK_RESP ),    .M2_WR_BACK_RESP (M2_WR_BACK_RESP ),    .M3_WR_BACK_RESP (M3_WR_BACK_RESP ),
.M0_WR_BACK_VALID(M0_WR_BACK_VALID),   .M1_WR_BACK_VALID(M1_WR_BACK_VALID),    .M2_WR_BACK_VALID(M2_WR_BACK_VALID),    .M3_WR_BACK_VALID(M3_WR_BACK_VALID),
.M0_WR_BACK_READY(M0_WR_BACK_READY),   .M1_WR_BACK_READY(M1_WR_BACK_READY),    .M2_WR_BACK_READY(M2_WR_BACK_READY),    .M3_WR_BACK_READY(M3_WR_BACK_READY),
.M0_RD_ADDR_ID   (M0_RD_ADDR_ID   ),   .M1_RD_ADDR_ID   (M1_RD_ADDR_ID   ),    .M2_RD_ADDR_ID   (M2_RD_ADDR_ID   ),    .M3_RD_ADDR_ID   (M3_RD_ADDR_ID   ),
.M0_RD_ADDR      (M0_RD_ADDR      ),   .M1_RD_ADDR      (M1_RD_ADDR      ),    .M2_RD_ADDR      (M2_RD_ADDR      ),    .M3_RD_ADDR      (M3_RD_ADDR      ),
.M0_RD_ADDR_LEN  (M0_RD_ADDR_LEN  ),   .M1_RD_ADDR_LEN  (M1_RD_ADDR_LEN  ),    .M2_RD_ADDR_LEN  (M2_RD_ADDR_LEN  ),    .M3_RD_ADDR_LEN  (M3_RD_ADDR_LEN  ),
.M0_RD_ADDR_BURST(M0_RD_ADDR_BURST),   .M1_RD_ADDR_BURST(M1_RD_ADDR_BURST),    .M2_RD_ADDR_BURST(M2_RD_ADDR_BURST),    .M3_RD_ADDR_BURST(M3_RD_ADDR_BURST),
.M0_RD_ADDR_VALID(M0_RD_ADDR_VALID),   .M1_RD_ADDR_VALID(M1_RD_ADDR_VALID),    .M2_RD_ADDR_VALID(M2_RD_ADDR_VALID),    .M3_RD_ADDR_VALID(M3_RD_ADDR_VALID),
.M0_RD_ADDR_READY(M0_RD_ADDR_READY),   .M1_RD_ADDR_READY(M1_RD_ADDR_READY),    .M2_RD_ADDR_READY(M2_RD_ADDR_READY),    .M3_RD_ADDR_READY(M3_RD_ADDR_READY),
.M0_RD_BACK_ID   (M0_RD_BACK_ID   ),   .M1_RD_BACK_ID   (M1_RD_BACK_ID   ),    .M2_RD_BACK_ID   (M2_RD_BACK_ID   ),    .M3_RD_BACK_ID   (M3_RD_BACK_ID   ),
.M0_RD_DATA      (M0_RD_DATA      ),   .M1_RD_DATA      (M1_RD_DATA      ),    .M2_RD_DATA      (M2_RD_DATA      ),    .M3_RD_DATA      (M3_RD_DATA      ),
.M0_RD_DATA_RESP (M0_RD_DATA_RESP ),   .M1_RD_DATA_RESP (M1_RD_DATA_RESP ),    .M2_RD_DATA_RESP (M2_RD_DATA_RESP ),    .M3_RD_DATA_RESP (M3_RD_DATA_RESP ),
.M0_RD_DATA_LAST (M0_RD_DATA_LAST ),   .M1_RD_DATA_LAST (M1_RD_DATA_LAST ),    .M2_RD_DATA_LAST (M2_RD_DATA_LAST ),    .M3_RD_DATA_LAST (M3_RD_DATA_LAST ),
.M0_RD_DATA_VALID(M0_RD_DATA_VALID),   .M1_RD_DATA_VALID(M1_RD_DATA_VALID),    .M2_RD_DATA_VALID(M2_RD_DATA_VALID),    .M3_RD_DATA_VALID(M3_RD_DATA_VALID),
.M0_RD_DATA_READY(M0_RD_DATA_READY),   .M1_RD_DATA_READY(M1_RD_DATA_READY),    .M2_RD_DATA_READY(M2_RD_DATA_READY),    .M3_RD_DATA_READY(M3_RD_DATA_READY),
.S0_CLK          (S0_CLK          ),   .S1_CLK          (S1_CLK          ),    .S2_CLK          (S2_CLK          ),    .S3_CLK          (S3_CLK          ),
.S0_RSTN         (S0_RSTN         ),   .S1_RSTN         (S1_RSTN         ),    .S2_RSTN         (S2_RSTN         ),    .S3_RSTN         (S3_RSTN         ),
.S0_WR_ADDR_ID   (S0_WR_ADDR_ID   ),   .S1_WR_ADDR_ID   (S1_WR_ADDR_ID   ),    .S2_WR_ADDR_ID   (S2_WR_ADDR_ID   ),    .S3_WR_ADDR_ID   (S3_WR_ADDR_ID   ),
.S0_WR_ADDR      (S0_WR_ADDR      ),   .S1_WR_ADDR      (S1_WR_ADDR      ),    .S2_WR_ADDR      (S2_WR_ADDR      ),    .S3_WR_ADDR      (S3_WR_ADDR      ),
.S0_WR_ADDR_LEN  (S0_WR_ADDR_LEN  ),   .S1_WR_ADDR_LEN  (S1_WR_ADDR_LEN  ),    .S2_WR_ADDR_LEN  (S2_WR_ADDR_LEN  ),    .S3_WR_ADDR_LEN  (S3_WR_ADDR_LEN  ),
.S0_WR_ADDR_BURST(S0_WR_ADDR_BURST),   .S1_WR_ADDR_BURST(S1_WR_ADDR_BURST),    .S2_WR_ADDR_BURST(S2_WR_ADDR_BURST),    .S3_WR_ADDR_BURST(S3_WR_ADDR_BURST),
.S0_WR_ADDR_VALID(S0_WR_ADDR_VALID),   .S1_WR_ADDR_VALID(S1_WR_ADDR_VALID),    .S2_WR_ADDR_VALID(S2_WR_ADDR_VALID),    .S3_WR_ADDR_VALID(S3_WR_ADDR_VALID),
.S0_WR_ADDR_READY(S0_WR_ADDR_READY),   .S1_WR_ADDR_READY(S1_WR_ADDR_READY),    .S2_WR_ADDR_READY(S2_WR_ADDR_READY),    .S3_WR_ADDR_READY(S3_WR_ADDR_READY),
.S0_WR_DATA      (S0_WR_DATA      ),   .S1_WR_DATA      (S1_WR_DATA      ),    .S2_WR_DATA      (S2_WR_DATA      ),    .S3_WR_DATA      (S3_WR_DATA      ),
.S0_WR_STRB      (S0_WR_STRB      ),   .S1_WR_STRB      (S1_WR_STRB      ),    .S2_WR_STRB      (S2_WR_STRB      ),    .S3_WR_STRB      (S3_WR_STRB      ),
.S0_WR_DATA_LAST (S0_WR_DATA_LAST ),   .S1_WR_DATA_LAST (S1_WR_DATA_LAST ),    .S2_WR_DATA_LAST (S2_WR_DATA_LAST ),    .S3_WR_DATA_LAST (S3_WR_DATA_LAST ),
.S0_WR_DATA_VALID(S0_WR_DATA_VALID),   .S1_WR_DATA_VALID(S1_WR_DATA_VALID),    .S2_WR_DATA_VALID(S2_WR_DATA_VALID),    .S3_WR_DATA_VALID(S3_WR_DATA_VALID),
.S0_WR_DATA_READY(S0_WR_DATA_READY),   .S1_WR_DATA_READY(S1_WR_DATA_READY),    .S2_WR_DATA_READY(S2_WR_DATA_READY),    .S3_WR_DATA_READY(S3_WR_DATA_READY),
.S0_WR_BACK_ID   (S0_WR_BACK_ID   ),   .S1_WR_BACK_ID   (S1_WR_BACK_ID   ),    .S2_WR_BACK_ID   (S2_WR_BACK_ID   ),    .S3_WR_BACK_ID   (S3_WR_BACK_ID   ),
.S0_WR_BACK_RESP (S0_WR_BACK_RESP ),   .S1_WR_BACK_RESP (S1_WR_BACK_RESP ),    .S2_WR_BACK_RESP (S2_WR_BACK_RESP ),    .S3_WR_BACK_RESP (S3_WR_BACK_RESP ),
.S0_WR_BACK_VALID(S0_WR_BACK_VALID),   .S1_WR_BACK_VALID(S1_WR_BACK_VALID),    .S2_WR_BACK_VALID(S2_WR_BACK_VALID),    .S3_WR_BACK_VALID(S3_WR_BACK_VALID),
.S0_WR_BACK_READY(S0_WR_BACK_READY),   .S1_WR_BACK_READY(S1_WR_BACK_READY),    .S2_WR_BACK_READY(S2_WR_BACK_READY),    .S3_WR_BACK_READY(S3_WR_BACK_READY),
.S0_RD_ADDR_ID   (S0_RD_ADDR_ID   ),   .S1_RD_ADDR_ID   (S1_RD_ADDR_ID   ),    .S2_RD_ADDR_ID   (S2_RD_ADDR_ID   ),    .S3_RD_ADDR_ID   (S3_RD_ADDR_ID   ),
.S0_RD_ADDR      (S0_RD_ADDR      ),   .S1_RD_ADDR      (S1_RD_ADDR      ),    .S2_RD_ADDR      (S2_RD_ADDR      ),    .S3_RD_ADDR      (S3_RD_ADDR      ),
.S0_RD_ADDR_LEN  (S0_RD_ADDR_LEN  ),   .S1_RD_ADDR_LEN  (S1_RD_ADDR_LEN  ),    .S2_RD_ADDR_LEN  (S2_RD_ADDR_LEN  ),    .S3_RD_ADDR_LEN  (S3_RD_ADDR_LEN  ),
.S0_RD_ADDR_BURST(S0_RD_ADDR_BURST),   .S1_RD_ADDR_BURST(S1_RD_ADDR_BURST),    .S2_RD_ADDR_BURST(S2_RD_ADDR_BURST),    .S3_RD_ADDR_BURST(S3_RD_ADDR_BURST),
.S0_RD_ADDR_VALID(S0_RD_ADDR_VALID),   .S1_RD_ADDR_VALID(S1_RD_ADDR_VALID),    .S2_RD_ADDR_VALID(S2_RD_ADDR_VALID),    .S3_RD_ADDR_VALID(S3_RD_ADDR_VALID),
.S0_RD_ADDR_READY(S0_RD_ADDR_READY),   .S1_RD_ADDR_READY(S1_RD_ADDR_READY),    .S2_RD_ADDR_READY(S2_RD_ADDR_READY),    .S3_RD_ADDR_READY(S3_RD_ADDR_READY),
.S0_RD_BACK_ID   (S0_RD_BACK_ID   ),   .S1_RD_BACK_ID   (S1_RD_BACK_ID   ),    .S2_RD_BACK_ID   (S2_RD_BACK_ID   ),    .S3_RD_BACK_ID   (S3_RD_BACK_ID   ),
.S0_RD_DATA      (S0_RD_DATA      ),   .S1_RD_DATA      (S1_RD_DATA      ),    .S2_RD_DATA      (S2_RD_DATA      ),    .S3_RD_DATA      (S3_RD_DATA      ),
.S0_RD_DATA_RESP (S0_RD_DATA_RESP ),   .S1_RD_DATA_RESP (S1_RD_DATA_RESP ),    .S2_RD_DATA_RESP (S2_RD_DATA_RESP ),    .S3_RD_DATA_RESP (S3_RD_DATA_RESP ),
.S0_RD_DATA_LAST (S0_RD_DATA_LAST ),   .S1_RD_DATA_LAST (S1_RD_DATA_LAST ),    .S2_RD_DATA_LAST (S2_RD_DATA_LAST ),    .S3_RD_DATA_LAST (S3_RD_DATA_LAST ),
.S0_RD_DATA_VALID(S0_RD_DATA_VALID),   .S1_RD_DATA_VALID(S1_RD_DATA_VALID),    .S2_RD_DATA_VALID(S2_RD_DATA_VALID),    .S3_RD_DATA_VALID(S3_RD_DATA_VALID),
.S0_RD_DATA_READY(S0_RD_DATA_READY),   .S1_RD_DATA_READY(S1_RD_DATA_READY),    .S2_RD_DATA_READY(S2_RD_DATA_READY),    .S3_RD_DATA_READY(S3_RD_DATA_READY),

.M0_fifo_empty_flag(M0_fifo_empty_flag), .M1_fifo_empty_flag(M1_fifo_empty_flag), .M2_fifo_empty_flag(M2_fifo_empty_flag), .M3_fifo_empty_flag(M3_fifo_empty_flag),
.S0_fifo_empty_flag(S0_fifo_empty_flag), .S1_fifo_empty_flag(S1_fifo_empty_flag), .S2_fifo_empty_flag(S2_fifo_empty_flag), .S3_fifo_empty_flag(S3_fifo_empty_flag)
);

// outports wire
wire [7:0]      	led;
wire [3:0]      	bcd;

wire [16*8-1:0] data_in;
assign data_in[(8*0)+:8]    = {3'b0,M0_fifo_empty_flag};
assign data_in[(8*1)+:8]    = {3'b0,M1_fifo_empty_flag};
assign data_in[(8*2)+:8]    = {3'b0,M2_fifo_empty_flag};
assign data_in[(8*3)+:8]    = {3'b0,M3_fifo_empty_flag};
assign data_in[(8*4)+:8]    = {3'b0,S0_fifo_empty_flag};
assign data_in[(8*5)+:8]    = {3'b0,S1_fifo_empty_flag};
assign data_in[(8*6)+:8]    = {3'b0,S2_fifo_empty_flag};
assign data_in[(8*7)+:8]    = {3'b0,S3_fifo_empty_flag};
assign data_in[(8*8)+:8]    = 8'b10101010;
assign data_in[(8*9)+:8]    = 8'b01010101;
assign data_in[(8*10)+:8]   = 8'b11110000;
assign data_in[(8*11)+:8]   = 8'b00001111;
assign data_in[(8*12)+:8]   = 8'b10101010;
assign data_in[(8*13)+:8]   = 8'b01010101;
assign data_in[(8*14)+:8]   = 8'b11110000;
assign data_in[(8*15)+:8]   = 8'b00001111;

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
