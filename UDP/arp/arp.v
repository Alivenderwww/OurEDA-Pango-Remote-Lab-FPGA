module arp (
    input                rstn        , //复位信号，低电平有效
    //GMII接口 
    input                gmii_rx_clk , //GMII接收数据时钟
    input                gmii_rx_dv  , //GMII输入数据有效信号
    input        [7:0]   gmii_rxd    , //GMII输入数据
    input                gmii_tx_clk , //GMII发送数据时钟
    output               gmii_tx_en  , //GMII输出数据有效信号
    output       [7:0]   gmii_txd    , //GMII输出数据
    input                arp_tx_sel  ,
    output               arp_tx_done ,
    output               arp_tx_req  ,
    output               arp_working ,

    input       [31:0]   des_ip      ,
    input       [47:0]   des_mac     ,
    input       [31:0]   board_ip    ,
    input       [47:0]   board_mac   ,
    output      [47:0]   dec_mac     ,
    output      [31:0]   dec_ip      ,

    output               arp_valid 
);

//wire [31:0]   dec_ip  ; 
wire          crc_en  ; //CRC开始校验使能
wire          crc_clr ; //CRC数据复位信号
wire  [7:0]   crc_d8  ; //输入待校验8位数据
wire  [31:0]  crc_data; //CRC校验数据
wire  [31:0]  crc_next; //CRC下次校验完成数据

assign crc_d8 = gmii_txd;

arp_rx arp_rx_inst (
    .rstn(rstn),
    .gmii_rx_clk(gmii_rx_clk),
    .gmii_rx_dv(gmii_rx_dv),
    .gmii_rxd(gmii_rxd),

    .board_ip(board_ip),
    .dec_mac(dec_mac),
    .dec_ip(dec_ip),
    .arp_valid(arp_valid)
  );

arp_tx arp_tx_inst (
    .rstn(rstn),
    .gmii_tx_clk(gmii_tx_clk),
    .gmii_tx_en(gmii_tx_en),
    .gmii_txd(gmii_txd),
    .board_ip(board_ip),
    .board_mac(board_mac),
    .dec_mac(dec_mac),
    .dec_ip(dec_ip),
    .arp_valid(arp_valid),
    .crc_data(crc_data),
    .crc_next(crc_next[31:24]),
    .crc_en(crc_en),
    .crc_clr(crc_clr),
    .arp_tx_sel(arp_tx_sel),
    .arp_tx_done(arp_tx_done),
    .arp_tx_req(arp_tx_req),
    .arp_working(arp_working)
  );


  //以太网发送CRC校验模块
crc32_d8   u_crc32_d8(
    .clk             (gmii_tx_clk),
    .rst_n           (rstn       ),
    .data            (crc_d8     ),
    .crc_en          (crc_en     ),
    .crc_clr         (crc_clr    ),
    .crc_data        (crc_data   ),
    .crc_next        (crc_next   )
    );
endmodule