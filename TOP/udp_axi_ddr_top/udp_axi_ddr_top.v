module udp_axi_ddr_top(
input  wire        clk          ,
input  wire        rst_n        ,
output wire [3:0]  led          ,

input  wire        rgmii_rxc    ,
input  wire        rgmii_rx_ctl ,
input  wire [3:0]  rgmii_rxd    ,
output wire        rgmii_txc    ,
output wire        rgmii_tx_ctl ,
output wire [3:0]  rgmii_txd    ,

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

wire        gmii_rx_clk ;
wire        gmii_rx_dv  ;
wire [7:0]  gmii_rxd    ;
wire        gmii_tx_clk ;
wire        gmii_tx_en  ;
wire [7:0]  gmii_txd    ;

wire    ddr_ref_clk      ;
wire    ddr_init_done    ;
wire    BUS_CLK          ;
wire    BUS_RST          ;

wire [27:0]  BUS_WR_ADDR      ;
wire [ 7:0]  BUS_WR_LEN       ;
wire         BUS_WR_ADDR_VALID;
wire        BUS_WR_ADDR_READY;
wire [ 31:0] BUS_WR_DATA      ;
wire [  3:0] BUS_WR_STRB      ;
wire        BUS_WR_DATA_VALID;
wire        BUS_WR_DATA_READY;
wire        BUS_WR_DATA_LAST ;
wire [27:0]  BUS_RD_ADDR      ;
wire [ 7:0]  BUS_RD_LEN       ;
wire         BUS_RD_ADDR_VALID;
wire        BUS_RD_ADDR_READY;
wire [31:0] BUS_RD_DATA      ;
wire        BUS_RD_DATA_LAST ;
wire        BUS_RD_DATA_READY;
wire        BUS_RD_DATA_VALID;

assign led = {ddr_init_done, 1'b1, 1'b1, 1'b1};
assign BUS_RST = ((!rst_n) || (!ddr_init_done));
assign ddr_ref_clk = clk;
    
gmii_to_rgmii u_gmii_to_rgmii(
    .gmii_rx_clk  (gmii_rx_clk  ),
    .gmii_rx_dv   (gmii_rx_dv   ),
    .gmii_rxd     (gmii_rxd     ),
    .gmii_tx_clk  (gmii_tx_clk  ),
    .gmii_tx_en   (gmii_tx_en   ),
    .gmii_txd     (gmii_txd     ),
    .rgmii_rxc    (rgmii_rxc    ),
    .rgmii_rx_ctl (rgmii_rx_ctl ),
    .rgmii_rxd    (rgmii_rxd    ),
    .rgmii_txc    (rgmii_txc    ),
    .rgmii_tx_ctl (rgmii_tx_ctl ),
    .rgmii_txd    (rgmii_txd    )
);

axi_udp_top #(
    .BOARD_MAC(48'h12_34_56_78_9A_BC),
    .BOARD_IP ({8'd169,8'd254,8'd1,8'd23}),
    .DES_MAC  (48'h00_2B_67_09_FF_5E),
    .DES_IP   ({8'd169,8'd254,8'd103,8'd126})
) u_axi_udp_top(
    .BUS_CLK       (BUS_CLK       ),
    .rstn          (rst_n          ),
    .wr_addr       (BUS_WR_ADDR   ),
    .wr_len        (BUS_WR_LEN       ),
    .wr_addr_valid (BUS_WR_ADDR_VALID),
    .wr_addr_ready (BUS_WR_ADDR_READY),
    .wr_data       (BUS_WR_DATA      ),
    .wr_strb       (BUS_WR_STRB      ),
    .wr_data_valid (BUS_WR_DATA_VALID),
    .wr_data_ready (BUS_WR_DATA_READY),
    .wr_data_last  (BUS_WR_DATA_LAST ),
    .rd_addr       (BUS_RD_ADDR      ),
    .rd_len        (BUS_RD_LEN       ),
    .rd_addr_valid (BUS_RD_ADDR_VALID),
    .rd_addr_ready (BUS_RD_ADDR_READY),
    .rd_data       (BUS_RD_DATA      ),
    .rd_data_last  (BUS_RD_DATA_LAST ),
    .rd_data_ready (BUS_RD_DATA_READY),
    .rd_data_valid (BUS_RD_DATA_VALID),
    .gmii_rx_clk   (gmii_rx_clk   ),
    .gmii_rx_dv    (gmii_rx_dv    ),
    .gmii_rxd      (gmii_rxd      ),
    .gmii_tx_clk   (gmii_tx_clk   ),
    .gmii_tx_en    (gmii_tx_en    ),
    .gmii_txd      (gmii_txd      )
);

slave_ddr3 u_slave_ddr3(
    .ddr_ref_clk       (ddr_ref_clk       ),
    .rst_n             (rst_n             ),
    .ddr_init_done     (ddr_init_done     ),
    .BUS_CLK           (BUS_CLK           ),
    .BUS_RST           (BUS_RST           ),
    .BUS_WR_ADDR       (BUS_WR_ADDR       ),
    .BUS_WR_LEN        (BUS_WR_LEN        ),
    .BUS_WR_ADDR_VALID (BUS_WR_ADDR_VALID ),
    .BUS_WR_ADDR_READY (BUS_WR_ADDR_READY ),
    .BUS_WR_DATA       (BUS_WR_DATA       ),
    .BUS_WR_STRB       (BUS_WR_STRB       ),
    .BUS_WR_DATA_VALID (BUS_WR_DATA_VALID ),
    .BUS_WR_DATA_READY (BUS_WR_DATA_READY ),
    .BUS_WR_DATA_LAST  (BUS_WR_DATA_LAST  ),
    .BUS_RD_ADDR       (BUS_RD_ADDR       ),
    .BUS_RD_LEN        (BUS_RD_LEN        ),
    .BUS_RD_ADDR_VALID (BUS_RD_ADDR_VALID ),
    .BUS_RD_ADDR_READY (BUS_RD_ADDR_READY ),
    .BUS_RD_DATA       (BUS_RD_DATA       ),
    .BUS_RD_DATA_LAST  (BUS_RD_DATA_LAST  ),
    .BUS_RD_DATA_READY (BUS_RD_DATA_READY ),
    .BUS_RD_DATA_VALID (BUS_RD_DATA_VALID ),
    .mem_rst_n         (mem_rst_n         ),
    .mem_ck            (mem_ck            ),
    .mem_ck_n          (mem_ck_n          ),
    .mem_cs_n          (mem_cs_n          ),
    .mem_a             (mem_a             ),
    .mem_dq            (mem_dq            ),
    .mem_dqs           (mem_dqs           ),
    .mem_dqs_n         (mem_dqs_n         ),
    .mem_dm            (mem_dm            ),
    .mem_cke           (mem_cke           ),
    .mem_odt           (mem_odt           ),
    .mem_ras_n         (mem_ras_n         ),
    .mem_cas_n         (mem_cas_n         ),
    .mem_we_n          (mem_we_n          ),
    .mem_ba            (mem_ba            )
);


endmodule
