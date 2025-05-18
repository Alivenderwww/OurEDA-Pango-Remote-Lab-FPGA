module arp #(
    parameter BOARD_MAC = 48'h12_34_56_78_9a_bc,
    parameter BOARD_IP  = {8'd0,8'd0,8'd0,8'd0}
) (
    input                rstn        , //复位信号，低电平有效
    //GMII接口 
    input                gmii_rx_clk , //GMII接收数据时钟
    input                gmii_rx_dv  , //GMII输入数据有效信号
    input        [7:0]   gmii_rxd    , //GMII输入数据
    input                gmii_tx_clk , //GMII发送数据时钟
    output               gmii_tx_en  , //GMII输出数据有效信号
    output       [7:0]   gmii_txd    , //GMII输出数据
    output               arp_working
);
    

wire [47:0]   dec_mac ;
wire [31:0]   dec_ip  ; 
wire          refresh ; //arp接收成功
wire          crc_en  ; //CRC开始校验使能
wire          crc_clr ; //CRC数据复位信号
wire  [7:0]   crc_d8  ; //输入待校验8位数据
wire  [31:0]  crc_data; //CRC校验数据
wire  [31:0]  crc_next; //CRC下次校验完成数据

assign crc_d8 = gmii_txd;

arp_rx # (
    .BOARD_MAC(BOARD_MAC),
    .BOARD_IP(BOARD_IP)
  )
  arp_rx_inst (
    .rstn(rstn),
    .gmii_rx_clk(gmii_rx_clk),
    .gmii_rx_dv(gmii_rx_dv),
    .gmii_rxd(gmii_rxd),
    .dec_mac(dec_mac),
    .dec_ip(dec_ip),
    .refresh(refresh)
  );

arp_tx # (
    .BOARD_MAC(BOARD_MAC),
    .BOARD_IP(BOARD_IP)
  )
  arp_tx_inst (
    .rstn(rstn),
    .gmii_tx_clk(gmii_tx_clk),
    .gmii_tx_en(gmii_tx_en),
    .gmii_txd(gmii_txd),
    .dec_mac(dec_mac),
    .dec_ip(dec_ip),
    .refresh(refresh),
    .crc_data(crc_data),
    .crc_next(crc_next[31:24]),
    .crc_en(crc_en),
    .crc_clr(crc_clr),

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