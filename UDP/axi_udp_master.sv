`timescale 1ns/1ps
module axi_udp_master #(
    parameter BOARD_MAC = 48'h12_34_56_78_9a_bc         ,
    parameter BOARD_IP  = {8'd192,8'd168,8'd0,8'd234}   ,
    parameter DES_MAC   = 48'h00_2B_67_09_FF_5E         ,
    parameter DES_IP    = {8'd169,8'd254,8'd103,8'd126} 
)(
    input  wire        udp_in_rstn  , //连什么线？
    output wire        eth_rst_n    ,

    output wire [7:0]  udp_led      ,
    //以太网rgmii外部接口
    input  wire        rgmii_rxc    ,
    input  wire        rgmii_rx_ctl ,
    input  wire [ 3:0] rgmii_rxd    ,
    output wire        rgmii_txc    ,
    output wire        rgmii_tx_ctl ,
    output wire [ 3:0] rgmii_txd    ,

    output wire        ETH_MASTER_CLK          ,
    output wire        ETH_MASTER_RSTN         ,
    output wire [ 1:0] ETH_MASTER_WR_ADDR_ID   ,
    output wire [31:0] ETH_MASTER_WR_ADDR      ,
    output wire [ 7:0] ETH_MASTER_WR_ADDR_LEN  ,
    output wire [ 1:0] ETH_MASTER_WR_ADDR_BURST,
    output wire        ETH_MASTER_WR_ADDR_VALID,
    input  wire        ETH_MASTER_WR_ADDR_READY,

    output wire [31:0] ETH_MASTER_WR_DATA      ,
    output wire [ 3:0] ETH_MASTER_WR_STRB      ,
    output wire        ETH_MASTER_WR_DATA_LAST ,
    output wire        ETH_MASTER_WR_DATA_VALID,
    input  wire        ETH_MASTER_WR_DATA_READY,

    input  wire [ 1:0] ETH_MASTER_WR_BACK_ID   ,
    input  wire [ 1:0] ETH_MASTER_WR_BACK_RESP ,
    input  wire        ETH_MASTER_WR_BACK_VALID,
    output wire        ETH_MASTER_WR_BACK_READY,

    output wire [ 1:0] ETH_MASTER_RD_ADDR_ID   ,
    output wire [31:0] ETH_MASTER_RD_ADDR      ,
    output wire [ 7:0] ETH_MASTER_RD_ADDR_LEN  ,
    output wire [ 1:0] ETH_MASTER_RD_ADDR_BURST,
    output wire        ETH_MASTER_RD_ADDR_VALID,
    input  wire        ETH_MASTER_RD_ADDR_READY,

    input  wire [ 1:0] ETH_MASTER_RD_BACK_ID   ,
    input  wire [31:0] ETH_MASTER_RD_DATA      ,
    input  wire [ 1:0] ETH_MASTER_RD_DATA_RESP ,
    input  wire        ETH_MASTER_RD_DATA_LAST ,
    input  wire        ETH_MASTER_RD_DATA_VALID,
    output wire        ETH_MASTER_RD_DATA_READY 
);
wire eth_rstn_sync;

//assign eth_rst_n = eth_rstn_sync;

wire            gmii_rx_clk     ;
wire            gmii_rx_dv      ;
wire    [7:0]   gmii_rxd        ;
wire            gmii_tx_clk     ;
wire            gmii_tx_en      ;
wire    [7:0]   gmii_txd        ;
wire            rec_pkt_done    ;
wire            rec_en          ;
wire    [31:0]  rec_data        ;
wire    [15:0]  rec_byte_num    ;
wire            tx_start_en     ;
wire    [31:0]  tx_data         ;
wire            udp_tx_done     ;
wire            tx_data_req          ;
wire    [15:0]  udp_tx_byte_num ;

wire            gmii_tx_en_udp;
wire            gmii_tx_en_arp;
wire    [7:0]   gmii_txd_udp;
wire    [7:0]   gmii_txd_arp;
wire    [47:0]  dec_mac;
wire    [31:0]   dec_ip; 
wire            refresh;

wire udp_tx_sel;
wire udp_tx_req;
wire udp_tx_working;
wire arp_tx_done;
wire arp_tx_sel;
wire arp_tx_req;
wire arp_working;
// assign gmii_tx_en = gmii_tx_en_udp;
// assign gmii_txd   = gmii_txd_udp;
assign gmii_tx_en = arp_working ? gmii_tx_en_arp : gmii_tx_en_udp;
assign gmii_txd   = arp_working ? gmii_txd_arp   : gmii_txd_udp;

rstn_sync rstn_sync_eth(gmii_rx_clk, udp_in_rstn, eth_rstn_sync);
//GMII接口与RGMII接口 互转
gmii_to_rgmii u_gmii_to_rgmii(
    .gmii_rx_clk   (gmii_rx_clk  ),  //gmii接收
    .gmii_rx_dv    (gmii_rx_dv   ),
    .gmii_rxd      (gmii_rxd     ),
    .gmii_tx_clk   (gmii_tx_clk  ),  //gmii发送
    .gmii_tx_en    (gmii_tx_en   ),
    .gmii_txd      (gmii_txd     ),
 
    .rgmii_rxc     (rgmii_rxc   ),  //rgmii接收
    .rgmii_rx_ctl  (rgmii_rx_ctl),
    .rgmii_rxd     (rgmii_rxd   ),
    .rgmii_txc     (rgmii_txc   ),  //rgmii发送
    .rgmii_tx_ctl  (rgmii_tx_ctl),
    .rgmii_txd     (rgmii_txd   )
);

// //UDP通信
// udp #(
//     .BOARD_MAC     (BOARD_MAC   ),      //参数例化
//     .BOARD_IP      (BOARD_IP    ),
//     .DES_MAC       (DES_MAC     ),
//     .DES_IP        (DES_IP      )
//     )
//    u_udp(
//     .rst_n         (eth_rstn_sync),

//     .gmii_rx_clk   (gmii_rx_clk ),//gmii接收
//     .gmii_rx_dv    (gmii_rx_dv  ),
//     .gmii_rxd      (gmii_rxd    ),
//     .gmii_tx_clk   (gmii_tx_clk ),//gmii发送
//     .gmii_tx_en    (gmii_tx_en_udp  ),
//     .gmii_txd      (gmii_txd_udp    ),

//     .rec_pkt_done  (rec_pkt_done),  //数据包接收结束
//     .rec_en        (rec_en      ),  //四字节接收使能
//     .rec_data      (rec_data    ),  //接收数据
//     .rec_byte_num  (rec_byte_num),  //接收到的有效数据长度
//     .tx_start_en   (tx_start_en ),  //发送使能
//     .tx_data       (tx_data     ),  //发送数据
//     .tx_byte_num   (udp_tx_byte_num),  //发送长度
//     .tx_done       (udp_tx_done ),  //发送结束
//     .tx_req        (tx_data_req      )   //四字节发送使能
// );
udp #(
    .BOARD_MAC     (BOARD_MAC),      //参数例化
    .BOARD_IP      (BOARD_IP ),
    .DES_MAC       (DES_MAC  ),
    .DES_IP        (DES_IP   )
    )
   u_udp(
    .rst_n         (eth_rstn_sync   ),
    .dec_mac       (dec_mac         ),
    .dec_ip        (dec_ip          ),
    .refresh       (refresh         ),

    .gmii_rx_clk   (gmii_rx_clk ),//gmii接收
    .gmii_rx_dv    (gmii_rx_dv  ),
    .gmii_rxd      (gmii_rxd    ),
    .gmii_tx_clk   (gmii_tx_clk ),//gmii发送
    .gmii_tx_en    (gmii_tx_en_udp  ),
    .gmii_txd      (gmii_txd_udp    ),

    .rec_pkt_done  (rec_pkt_done),  //数据包接收结束
    .rec_en        (rec_en      ),  //四字节接收使能
    .rec_data      (rec_data    ),  //接收数据
    .rec_byte_num  (rec_byte_num),  //接收到的有效数据长度
    .tx_start_en   (tx_start_en),  //发送使能
    .tx_data       (tx_data     ),  //发送数据
    .tx_byte_num   (udp_tx_byte_num),  //发送长度
    .udp_tx_sel    (udp_tx_sel),
    .udp_tx_req    (udp_tx_req),
    .udp_tx_working(udp_tx_working),
    .tx_done       (udp_tx_done ),  //发送结束
    .tx_req        (tx_data_req      )   //四字节发送使能
    );

axi_udp_cmd axi_udp_cmd_inst(
    .gmii_rx_clk         (gmii_rx_clk         ),
    .rstn                (eth_rstn_sync       ),

    .cmdled              (udp_led             ),    

    .MASTER_CLK          (ETH_MASTER_CLK          ), 
    .MASTER_RSTN         (ETH_MASTER_RSTN         ), 
    .MASTER_WR_ADDR_ID   (ETH_MASTER_WR_ADDR_ID   ), 
    .MASTER_WR_ADDR      (ETH_MASTER_WR_ADDR      ), 
    .MASTER_WR_ADDR_LEN  (ETH_MASTER_WR_ADDR_LEN  ), 
    .MASTER_WR_ADDR_BURST(ETH_MASTER_WR_ADDR_BURST), 
    .MASTER_WR_ADDR_VALID(ETH_MASTER_WR_ADDR_VALID), 
    .MASTER_WR_ADDR_READY(ETH_MASTER_WR_ADDR_READY), 
    .MASTER_WR_DATA      (ETH_MASTER_WR_DATA      ), 
    .MASTER_WR_STRB      (ETH_MASTER_WR_STRB      ), 
    .MASTER_WR_DATA_LAST (ETH_MASTER_WR_DATA_LAST ), 
    .MASTER_WR_DATA_VALID(ETH_MASTER_WR_DATA_VALID), 
    .MASTER_WR_DATA_READY(ETH_MASTER_WR_DATA_READY), 
    .MASTER_WR_BACK_ID   (ETH_MASTER_WR_BACK_ID   ), 
    .MASTER_WR_BACK_RESP (ETH_MASTER_WR_BACK_RESP ), 
    .MASTER_WR_BACK_VALID(ETH_MASTER_WR_BACK_VALID), 
    .MASTER_WR_BACK_READY(ETH_MASTER_WR_BACK_READY), 
    .MASTER_RD_ADDR_ID   (ETH_MASTER_RD_ADDR_ID   ), 
    .MASTER_RD_ADDR      (ETH_MASTER_RD_ADDR      ), 
    .MASTER_RD_ADDR_LEN  (ETH_MASTER_RD_ADDR_LEN  ), 
    .MASTER_RD_ADDR_BURST(ETH_MASTER_RD_ADDR_BURST), 
    .MASTER_RD_ADDR_VALID(ETH_MASTER_RD_ADDR_VALID), 
    .MASTER_RD_ADDR_READY(ETH_MASTER_RD_ADDR_READY), 
    .MASTER_RD_BACK_ID   (ETH_MASTER_RD_BACK_ID   ), 
    .MASTER_RD_DATA      (ETH_MASTER_RD_DATA      ), 
    .MASTER_RD_DATA_RESP (ETH_MASTER_RD_DATA_RESP ), 
    .MASTER_RD_DATA_LAST (ETH_MASTER_RD_DATA_LAST ), 
    .MASTER_RD_DATA_VALID(ETH_MASTER_RD_DATA_VALID), 
    .MASTER_RD_DATA_READY(ETH_MASTER_RD_DATA_READY), 

    .udp_rx_done         (rec_pkt_done),
    .udp_rx_data         (rec_data    ),
    .udp_rx_en           (rec_en      ),

    .udp_tx_req          (tx_data_req      ),
    .udp_tx_start        (tx_start_en ),
    .udp_tx_data         (tx_data     ),
    .udp_tx_done         (udp_tx_done ),
    .udp_tx_byte_num     (udp_tx_byte_num)
);

// arp # (
//     .BOARD_MAC(BOARD_MAC),
//     .BOARD_IP(BOARD_IP)
//   )
//   arp_inst (
//     .rstn(eth_rstn_sync),
//     .gmii_rx_clk(gmii_rx_clk),
//     .gmii_rx_dv(gmii_rx_dv),
//     .gmii_rxd(gmii_rxd),
//     .gmii_tx_clk(gmii_tx_clk),
//     .gmii_tx_en(gmii_tx_en_arp),
//     .gmii_txd(gmii_txd_arp),
//     .arp_working(arp_working)
//   );

arp # (
    .BOARD_MAC(BOARD_MAC),
    .BOARD_IP(BOARD_IP),
    .DES_MAC(DES_MAC),
    .DES_IP(DES_IP)
  )
  arp_inst (
    .rstn(eth_rstn_sync),
    .gmii_rx_clk(gmii_rx_clk),
    .gmii_rx_dv(gmii_rx_dv),
    .gmii_rxd(gmii_rxd),
    .gmii_tx_clk(gmii_tx_clk),
    .gmii_tx_en(gmii_tx_en_arp),
    .gmii_txd(gmii_txd_arp),
    .arp_tx_sel(arp_tx_sel),
    .arp_tx_done(arp_tx_done),
    .arp_tx_req(arp_tx_req),
    .arp_working(arp_working),
    .dec_mac(dec_mac),
    .dec_ip(dec_ip),
    .refresh(refresh)
  );


eth_Arbiter  eth_Arbiter_inst (
  .clk(gmii_rx_clk),
  .rstn(eth_rstn_sync),
  .port0_req(arp_tx_req),
  .port0_done(arp_tx_done),
  .port0_sel(arp_tx_sel),
  .port1_req(udp_tx_req),
  .port1_done(udp_tx_done),
  .port1_sel(udp_tx_sel)
);

endmodule //udp_axi_master_sim
