`timescale  1ns/1ns
////////////////////////////////////////////////////////////////////////
// Author  : EmbedFire
// ʵ��ƽ̨: Ұ��FPGAϵ�п�����
// ��˾    : http://www.embedfire.com
// ��̳    : http://www.firebbs.cn
// �Ա�    : https://fire-stm32.taobao.com
////////////////////////////////////////////////////////////////////////

module udp(
    input                rst_n       , //��λ�źţ��͵�ƽ��Ч
    input        [31:0]  des_ip      ,
    input        [47:0]  des_mac     ,
    input        [31:0]  board_ip    ,
    input        [47:0]  board_mac   ,
    //GMII�ӿ�
    input                gmii_rx_clk , //GMII��������ʱ��
    input                gmii_rx_dv  , //GMII����������Ч�ź�
    input        [7:0]   gmii_rxd    , //GMII��������
    input                gmii_tx_clk , //GMII��������ʱ��
    output               gmii_tx_en  , //GMII���������Ч�ź�
    output       [7:0]   gmii_txd    , //GMII�������
    //�û��ӿ�
    output               rec_pkt_done, //��̫���������ݽ�������ź�
    output               rec_en      , //��̫�����յ�����ʹ���ź�
    output       [31:0]  rec_data    , //��̫�����յ�����
    output       [15:0]  rec_byte_num, //��̫�����յ���Ч�ֽ��� ��λ:byte
    input                tx_start_en , //��̫����ʼ�����ź�
    input        [31:0]  tx_data     , //��̫������������
    input        [15:0]  tx_byte_num , //��̫�����͵���Ч�ֽ��� ��λ:byte
    input                udp_tx_sel,
    output               udp_tx_req,
    output               udp_tx_working,
    output               tx_done     , //��̫����������ź�
    output               tx_req      , //�����������ź�
    input                timestamp_rst //ʱ�����λ�ź�
    );

//wire define
wire          crc_en  ; //CRC��ʼУ��ʹ��
wire          crc_clr ; //CRC���ݸ�λ�ź�
wire  [7:0]   crc_d8  ; //�����У��8λ����

wire  [31:0]  crc_data; //CRCУ������
wire  [31:0]  crc_next; //CRC�´�У���������

//*****************************************************
//**                    main code
//*****************************************************

assign  crc_d8 = gmii_txd;

//��̫������ģ��
udp_rx u_udp_rx(
    .clk             (gmii_rx_clk ),
    .rst_n           (rst_n       ),
    .board_ip        (board_ip    ),
    .board_mac       (board_mac   ),
    .gmii_rx_dv      (gmii_rx_dv  ),
    .gmii_rxd        (gmii_rxd    ),
    .rec_pkt_done    (rec_pkt_done),
    .rec_en          (rec_en      ),
    .rec_data        (rec_data    ),
    .rec_byte_num    (rec_byte_num)
    );

//��̫������ģ��
udp_tx u_udp_tx(
    .clk             (gmii_tx_clk),
    .rst_n           (rst_n      ),
    .tx_start_en     (tx_start_en),
    .tx_data         (tx_data    ),
    .tx_byte_num     (tx_byte_num),
    .crc_data        (crc_data   ),
    .crc_next        (crc_next[31:24]),
    .udp_tx_sel      (udp_tx_sel),
    .udp_tx_req      (udp_tx_req),
    .udp_tx_working  (udp_tx_working),
    .tx_done         (tx_done    ),
    .tx_req          (tx_req     ),
    .gmii_tx_en      (gmii_tx_en ),
    .gmii_txd        (gmii_txd   ),
    .crc_en          (crc_en     ),
    .crc_clr         (crc_clr    ),
    .board_ip        (board_ip   ),
    .board_mac       (board_mac  ),
    .des_ip          (des_ip     ),
    .des_mac         (des_mac    ),
    .timestamp_rst   (timestamp_rst)
);

//��̫������CRCУ��ģ��
crc32_d8   u_crc32_d8(
    .clk             (gmii_tx_clk),
    .rst_n           (rst_n      ),
    .data            (crc_d8     ),
    .crc_en          (crc_en     ),
    .crc_clr         (crc_clr    ),
    .crc_data        (crc_data   ),
    .crc_next        (crc_next   )
    );

endmodule