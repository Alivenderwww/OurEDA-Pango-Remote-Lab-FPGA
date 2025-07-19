module axi_udp_top #(
    parameter BOARD_MAC = 48'h12_34_56_78_9a_bc,
    parameter BOARD_IP  = {8'd0,8'd0,8'd0,8'd0},
    parameter DES_MAC  = 48'h2c_f0_5d_32_f1_07,
    parameter DES_IP   = {8'd0,8'd0,8'd0,8'd0}
) (
    output wire MASTER_CLK ,
    output wire MASTER_RSTN,
    output wire [ 1:0] MASTER_WR_ADDR_ID   ,
    output wire [31:0] MASTER_WR_ADDR      ,
    output wire [ 7:0] MASTER_WR_ADDR_LEN  ,
    output wire [ 1:0] MASTER_WR_ADDR_BURST,
    output wire        MASTER_WR_ADDR_VALID,
    input  wire        MASTER_WR_ADDR_READY,
    output wire [31:0] MASTER_WR_DATA      ,
    output wire [ 3:0] MASTER_WR_STRB      ,
    output wire        MASTER_WR_DATA_LAST ,
    output wire        MASTER_WR_DATA_VALID,
    input  wire        MASTER_WR_DATA_READY,
    input  wire [ 1:0] MASTER_WR_BACK_ID   ,
    input  wire [ 1:0] MASTER_WR_BACK_RESP ,
    input  wire        MASTER_WR_BACK_VALID,
    output wire        MASTER_WR_BACK_READY,
    output wire [ 1:0] MASTER_RD_ADDR_ID   ,
    output wire [31:0] MASTER_RD_ADDR      ,
    output wire [ 7:0] MASTER_RD_ADDR_LEN  ,
    output wire [ 1:0] MASTER_RD_ADDR_BURST,
    output wire        MASTER_RD_ADDR_VALID,
    input  wire        MASTER_RD_ADDR_READY,
    input  wire [ 1:0] MASTER_RD_BACK_ID   ,
    input  wire [31:0] MASTER_RD_DATA      ,
    input  wire [ 1:0] MASTER_RD_DATA_RESP ,
    input  wire        MASTER_RD_DATA_LAST ,
    input  wire        MASTER_RD_DATA_VALID,
    output wire        MASTER_RD_DATA_READY     
);
//udp�ӿ��ź�
wire            rec_pkt_done; //��̫���������ݽ�������ź�
wire            rec_en      ; //��̫�����յ�����ʹ���ź�
wire  [31:0]    rec_data    ; //��̫�����յ�����
wire  [15:0]    rec_byte_num; //��̫�����յ���Ч�ֽ��� ��λ:byte
wire            tx_start_en ; //��̫����ʼ�����ź�
wire  [31:0]    tx_data     ; //��̫������������
wire  [15:0]    tx_byte_num ; //��̫�����͵���Ч�ֽ��� ��λ:byte
wire            tx_done     ; //��̫����������ź�
wire            tx_req      ; //�����������ź�

wire            crc_en      ; //CRC��ʼУ��ʹ��
wire            crc_clr     ; //CRC���ݸ�λ�ź�
wire  [ 7:0]    crc_d8      ; //�����У��8λ����
wire  [31:0]    crc_data    ; //CRCУ������
wire  [31:0]    crc_next    ; //CRC�´�У���������




//GMII�ӿ���RGMII�ӿ� ��ת
gmii_to_rgmii u_gmii_to_rgmii(
    .gmii_rx_clk   (gmii_rx_clk  ),  //gmii����
    .gmii_rx_dv    (gmii_rx_dv   ),
    .gmii_rxd      (gmii_rxd     ),
    .gmii_tx_clk   (gmii_tx_clk  ),  //gmii����
    .gmii_tx_en    (gmii_tx_en   ),
    .gmii_txd      (gmii_txd     ),
 
    .rgmii_rxc     (eth_rxc      ),  //rgmii����
    .rgmii_rx_ctl  (eth_rxdv     ),
    .rgmii_rxd     (eth_rx_data  ),
    .rgmii_txc     (eth_txc      ),  //rgmii����
    .rgmii_tx_ctl  (eth_tx_en_r  ),
    .rgmii_txd     (eth_tx_data_r)
);

//UDPͨ��
udp #(
    .BOARD_MAC     (BOARD_MAC   ),      //��������
    .BOARD_IP      (BOARD_IP    ),
    .DES_MAC       (DES_MAC     ),
    .DES_IP        (DES_IP      )
    )
   u_udp(
    .rst_n         (sys_rst_n   ),

    .gmii_rx_clk   (gmii_rx_clk ),//gmii����
    .gmii_rx_dv    (gmii_rx_dv  ),
    .gmii_rxd      (gmii_rxd    ),
    .gmii_tx_clk   (gmii_tx_clk ),//gmii����
    .gmii_tx_en    (gmii_tx_en  ),
    .gmii_txd      (gmii_txd    ),

    .rec_pkt_done  (rec_pkt_done),  //���ݰ����ս���
    .rec_en        (rec_en      ),  //���ֽڽ���ʹ��
    .rec_data      (rec_data    ),  //��������
    .rec_byte_num  (rec_byte_num),  //���յ�����Ч���ݳ���
    .tx_start_en   (tx_start_en ),  //����ʹ��
    .tx_data       (tx_data     ),  //��������
    .tx_byte_num   (udp_tx_byte_num),  //���ͳ���
    .tx_done       (udp_tx_done ),  //���ͽ���
    .tx_req        (tx_req      )   //���ֽڷ���ʹ��
);

axi_udp_cmd axi_udp_cmd_inst(
    .gmii_rx_clk         (gmii_rx_clk         ),
    .rstn                (sys_rst_n           ),

    .MASTER_CLK          (MASTER_CLK          ), 
    .MASTER_RSTN         (MASTER_RSTN         ), 
    .MASTER_WR_ADDR_ID   (MASTER_WR_ADDR_ID   ), 
    .MASTER_WR_ADDR      (MASTER_WR_ADDR      ), 
    .MASTER_WR_ADDR_LEN  (MASTER_WR_ADDR_LEN  ), 
    .MASTER_WR_ADDR_BURST(MASTER_WR_ADDR_BURST), 
    .MASTER_WR_ADDR_VALID(MASTER_WR_ADDR_VALID), 
    .MASTER_WR_ADDR_READY(MASTER_WR_ADDR_READY), 
    .MASTER_WR_DATA      (MASTER_WR_DATA      ), 
    .MASTER_WR_STRB      (MASTER_WR_STRB      ), 
    .MASTER_WR_DATA_LAST (MASTER_WR_DATA_LAST ), 
    .MASTER_WR_DATA_VALID(MASTER_WR_DATA_VALID), 
    .MASTER_WR_DATA_READY(MASTER_WR_DATA_READY), 
    .MASTER_WR_BACK_ID   (MASTER_WR_BACK_ID   ), 
    .MASTER_WR_BACK_RESP (MASTER_WR_BACK_RESP ), 
    .MASTER_WR_BACK_VALID(MASTER_WR_BACK_VALID), 
    .MASTER_WR_BACK_READY(MASTER_WR_BACK_READY), 
    .MASTER_RD_ADDR_ID   (MASTER_RD_ADDR_ID   ), 
    .MASTER_RD_ADDR      (MASTER_RD_ADDR      ), 
    .MASTER_RD_ADDR_LEN  (MASTER_RD_ADDR_LEN  ), 
    .MASTER_RD_ADDR_BURST(MASTER_RD_ADDR_BURST), 
    .MASTER_RD_ADDR_VALID(MASTER_RD_ADDR_VALID), 
    .MASTER_RD_ADDR_READY(MASTER_RD_ADDR_READY), 
    .MASTER_RD_BACK_ID   (MASTER_RD_BACK_ID   ), 
    .MASTER_RD_DATA      (MASTER_RD_DATA      ), 
    .MASTER_RD_DATA_RESP (MASTER_RD_DATA_RESP ), 
    .MASTER_RD_DATA_LAST (MASTER_RD_DATA_LAST ), 
    .MASTER_RD_DATA_VALID(MASTER_RD_DATA_VALID), 
    .MASTER_RD_DATA_READY(MASTER_RD_DATA_READY), 

    .udp_rx_done         (rec_pkt_done),
    .udp_rx_data         (rec_data    ),
    .udp_rx_en           (rec_en      ),

    .udp_tx_req          (tx_req      ),
    .udp_tx_start        (tx_start_en ),
    .udp_tx_data         (tx_data     ),
    .udp_tx_done         (udp_tx_done ),
    .udp_tx_byte_num     (udp_tx_byte_num)
);

endmodule