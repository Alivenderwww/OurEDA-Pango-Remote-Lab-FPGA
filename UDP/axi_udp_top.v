module axi_udp_top #(
    parameter BOARD_MAC = 48'h12_34_56_78_9a_bc,
    parameter BOARD_IP  = {8'd0,8'd0,8'd0,8'd0},
    parameter DES_MAC  = 48'h2c_f0_5d_32_f1_07,
    parameter DES_IP   = {8'd0,8'd0,8'd0,8'd0}
) (
    output            BUS_CLK        ,
    input wire        rstn           ,
    //AXI_master接口
    output reg [27:0] wr_addr        , //写地址
    output reg [ 7:0] wr_len         , //写长度，实际长度为wr_len+1
    output reg        wr_addr_valid  , //写地址有效信号
    input wire        wr_addr_ready  , //写地址准备好信号

    output reg [31:0] wr_data        , //写数据
    output reg [ 3:0] wr_strb        , //写数据掩码
    output reg        wr_data_valid  , //写数据有效信号
    input wire        wr_data_ready  , //写数据准备好信号
    output reg        wr_data_last   , //写数据最后一个信号

    output reg [27:0] rd_addr        , //读地址
    output reg [ 7:0] rd_len         , //读长度，实际长度为rd_len+1 一个4字节
    output reg        rd_addr_valid  , //读地址有效信号
    input wire        rd_addr_ready  , //读地址准备好信号

    input wire [31:0] rd_data        , //读数据
    input wire        rd_data_last   , //读数据最后一个信号
    output reg        rd_data_ready  , //读数据准备好信号
    input wire        rd_data_valid  , //读数据有效信号
    
    //GMII接口
    input             gmii_rx_clk    , //GMII接收数据时钟
    input             gmii_rx_dv     , //GMII输入数据有效信号
    input      [7:0]  gmii_rxd       , //GMII输入数据
    input             gmii_tx_clk    , //GMII发送数据时钟    //事实上与rx相同
    output            gmii_tx_en     , //GMII输出数据有效信号
    output     [7:0]  gmii_txd         //GMII输出数据
);
//udp接口信号
wire            rec_pkt_done; //以太网单包数据接收完成信号
wire            rec_en      ; //以太网接收的数据使能信号
wire  [31:0]    rec_data    ; //以太网接收的数据
wire  [15:0]    rec_byte_num; //以太网接收的有效字节数 单位:byte
wire            tx_start_en ; //以太网开始发送信号
wire  [31:0]    tx_data     ; //以太网待发送数据
wire  [15:0]    tx_byte_num ; //以太网发送的有效字节数 单位:byte
wire            tx_done     ; //以太网发送完成信号
wire            tx_req      ; //读数据请求信号

wire            crc_en      ; //CRC开始校验使能
wire            crc_clr     ; //CRC数据复位信号
wire  [ 7:0]    crc_d8      ; //输入待校验8位数据
wire  [31:0]    crc_data    ; //CRC校验数据
wire  [31:0]    crc_next    ; //CRC下次校验完成数据

assign  crc_d8 = gmii_txd;
assign BUS_CLK = gmii_rx_clk;


//以太网接收模块
udp_rx
   #(
    .BOARD_MAC       (BOARD_MAC),         //参数例化
    .BOARD_IP        (BOARD_IP )
    )
   u_udp_rx(
    .clk             (gmii_rx_clk ),
    .rst_n           (rstn        ),
    .gmii_rx_dv      (gmii_rx_dv  ),
    .gmii_rxd        (gmii_rxd    ),
    .rec_pkt_done    (rec_pkt_done),
    .rec_en          (rec_en      ),
    .rec_data        (rec_data    ),
    .rec_byte_num    (rec_byte_num)
    );

//以太网发送模块
udp_tx
   #(
    .BOARD_MAC       (BOARD_MAC ),         //参数例化
    .BOARD_IP        (BOARD_IP  ),
    .DES_MAC         (DES_MAC   ),
    .DES_IP          (DES_IP    )
    )
   u_udp_tx(
    .clk             (gmii_tx_clk),
    .rst_n           (rstn       ),
    .tx_start_en     (tx_start_en),
    .tx_data         ( tx_data   ),
    .tx_byte_num     ((rd_len+1)*4),
    .crc_data        (crc_data   ),
    .crc_next        (crc_next[31:24]),
    .tx_done         (tx_done    ),
    .tx_req          (   tx_req  ),
    .gmii_tx_en      (gmii_tx_en ),
    .gmii_txd        (gmii_txd   ),
    .crc_en          (crc_en     ),
    .crc_clr         (crc_clr    )
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

axi_udp_cmd axi_udp_cmd_inst (
    .gmii_rx_clk(gmii_rx_clk),
    .rstn(rstn),
    .wr_addr(wr_addr),
    .wr_len(wr_len),
    .wr_addr_valid(wr_addr_valid),
    .wr_addr_ready(wr_addr_ready),
    .wr_data(wr_data),
    .wr_strb(wr_strb),
    .wr_data_valid(wr_data_valid),
    .wr_data_ready(wr_data_ready),
    .wr_data_last(wr_data_last),
    .rd_addr(rd_addr),
    .rd_len(rd_len),
    .rd_addr_valid(rd_addr_valid),
    .rd_addr_ready(rd_addr_ready),
    .rd_data(rd_data),
    .rd_data_last(rd_data_last),
    .rd_data_ready(rd_data_ready),
    .rd_data_valid(rd_data_valid),


    .rec_pkt_done(rec_pkt_done),
    .datain(rec_data),
    .rec_en(rec_en),
    .tx_req(tx_req),
    .tx_start_en(tx_start_en),
    .udp_tx_data(tx_data)
  );    

endmodule