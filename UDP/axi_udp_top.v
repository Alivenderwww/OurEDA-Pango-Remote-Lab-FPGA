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




//GMII接口与RGMII接口 互转
gmii_to_rgmii u_gmii_to_rgmii(
    .gmii_rx_clk   (gmii_rx_clk  ),  //gmii接收
    .gmii_rx_dv    (gmii_rx_dv   ),
    .gmii_rxd      (gmii_rxd     ),
    .gmii_tx_clk   (gmii_tx_clk  ),  //gmii发送
    .gmii_tx_en    (gmii_tx_en   ),
    .gmii_txd      (gmii_txd     ),
 
    .rgmii_rxc     (eth_rxc      ),  //rgmii接收
    .rgmii_rx_ctl  (eth_rxdv     ),
    .rgmii_rxd     (eth_rx_data  ),
    .rgmii_txc     (eth_txc      ),  //rgmii发送
    .rgmii_tx_ctl  (eth_tx_en_r  ),
    .rgmii_txd     (eth_tx_data_r)
);

//UDP通信
udp #(
    .BOARD_MAC     (BOARD_MAC   ),      //参数例化
    .BOARD_IP      (BOARD_IP    ),
    .DES_MAC       (DES_MAC     ),
    .DES_IP        (DES_IP      )
    )
   u_udp(
    .rst_n         (sys_rst_n   ),

    .gmii_rx_clk   (gmii_rx_clk ),//gmii接收
    .gmii_rx_dv    (gmii_rx_dv  ),
    .gmii_rxd      (gmii_rxd    ),
    .gmii_tx_clk   (gmii_tx_clk ),//gmii发送
    .gmii_tx_en    (gmii_tx_en  ),
    .gmii_txd      (gmii_txd    ),

    .rec_pkt_done  (rec_pkt_done),  //数据包接收结束
    .rec_en        (rec_en      ),  //四字节接收使能
    .rec_data      (rec_data    ),  //接收数据
    .rec_byte_num  (rec_byte_num),  //接收到的有效数据长度
    .tx_start_en   (tx_start_en ),  //发送使能
    .tx_data       (tx_data     ),  //发送数据
    .tx_byte_num   (udp_tx_byte_num),  //发送长度
    .tx_done       (udp_tx_done ),  //发送结束
    .tx_req        (tx_req      )   //四字节发送使能
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