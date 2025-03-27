module udp_axi_ddr_top(
//system io
input  wire        clk          ,
input  wire        rst_n        ,
//led io
output wire [7:0]  led          ,
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



endmodule
