`timescale  1ns/1ns
////////////////////////////////////////////////////////////////////////
// Author        : EmbedFire
// 实验平台: 野火FPGA系列开发板
// 公司    : http://www.embedfire.com
// 论坛    : http://www.firebbs.cn
// 淘宝    : https://fire-stm32.taobao.com
////////////////////////////////////////////////////////////////////////

module  eth_udp_cmd_tb();

//parameter define
//开发板MAC地址
parameter  BOARD_MAC = 48'h12_34_56_78_9a_bc;
//开发板IP地址
parameter  BOARD_IP  = {8'd192,8'd168,8'd0,8'd234}; 
//目的MAC地址
parameter  DES_MAC   = 48'h00_2B_67_09_FF_5E;
//目的IP地址
parameter  DES_IP    = {8'd169,8'd254,8'd103,8'd126};
//********************************************************************//
//****************** Parameter and Internal Signal *******************//
//********************************************************************//
//reg   define
reg             sys_clk         ;   //PHY芯片接收数据时钟信号
reg             sys_rst_n       ;   //系统复位,低电平有效
reg             eth_rxc         ;
reg             eth_rxc_x2      ;
reg             eth_rxdv        ;   //PHY芯片输入数据有效信号

reg     [11:0]  cnt_data        ;   //数据包字节计数器
reg             start_flag      ;   //数据输入开始标志信号

//wire define

wire            eth_txc         ;
wire            eth_tx_en_r     ;   //PHY芯片输出数据有效信号
wire    [3:0]   eth_tx_data_r   ;   //PHY芯片输出数据
wire            eth_rst_n       ;   //PHY芯片复位信号,低电平有效
wire    [3:0]   eth_rx_data     ;   //PHY芯片输入数据

//********************************************************************//
//***************************** Main Code ****************************//
//********************************************************************//
//时钟、复位信号
initial
  begin
    sys_clk  =   1'b1    ;
    eth_rxc  =   1'b1    ;
    eth_rxc_x2  =   1'b1    ;
    sys_rst_n   <=  1'b0    ;
    start_flag  <=  1'b0    ;
    #2000
    sys_rst_n   <=  1'b1    ;
    #1000
    start_flag  <=  1'b1    ;
    #50
    start_flag  <=  1'b0    ;
  end
//sys_clk   50M
always  #10 sys_clk = ~sys_clk;
//eth_rxc   125M
always  #4 eth_rxc = ~eth_rxc;
//eth_rxc_x2   250M
always  #2 eth_rxc_x2 = ~eth_rxc_x2;



localparam board_ip =  32'hEA_00_A8_C0;
localparam board_mac = 48'hBC_9A_78_56_34_12;
localparam data_byte_num = 16'h20_00;    //传32字节
localparam udp_byte_num = 16'h28_00; //data_byte_num+8,udp部首长8

reg [400+data_byte_num*8-1:0] data_mem        ;   //data_mem是一个存储器,相当于一个ram
reg [data_byte_num*8-1:0] data = 'h55555555_41_41_41_00_44444444_31_31_31_00_33333333_21_21_21_00_22222222_11_11_11_FF;
//data_mem
always@(negedge eth_rxc_x2 or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        data_mem    <=  {data,16'h00_00,udp_byte_num,32'hD2_04_D2_04,board_ip,192'h91_00_A8_C0_00_00_11_80_00_00_00_5F_3C_00_00_45_00_08_2D_DB_4A_5E_D5_E0,board_mac,64'hD5_55_55_55_55_55_55_55};
    else    if(eth_rxdv == 1'b1)
        data_mem    <=  data_mem >>4;
    else
        data_mem    <=  data_mem;

//eth_rxdv:PHY芯片输入数据有效信号
always@(negedge eth_rxc_x2 or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        eth_rxdv    <=  1'b0;
    else    if(cnt_data == 163)
        eth_rxdv    <=  1'b0;
    else    if(start_flag == 1'b1)
        eth_rxdv    <=  1'b1;
    else
        eth_rxdv    <=  eth_rxdv;

//cnt_data:数据包字节计数器
always@(negedge eth_rxc_x2 or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_data    <=  12'd0;
    else    if(eth_rxdv == 1'b1)
        cnt_data    <=  cnt_data + 1'b1;
    else
        cnt_data    <=  cnt_data;

//eth_rx_data:PHY芯片输入数据
assign  eth_rx_data = (eth_rxdv == 1'b1)
                    ? data_mem[3:0] : 4'b0;

//********************************************************************//
//*************************** Instantiation **************************//
//********************************************************************//
wire gmii_rx_clk ;
wire gmii_rx_dv  ;
wire [7:0] gmii_rxd    ;
wire gmii_tx_clk ;
wire gmii_tx_en  ;
wire [7:0] gmii_txd    ;
wire rec_pkt_done;
wire rec_en      ;
wire [31:0] rec_data    ;
wire [15:0] rec_byte_num;
wire tx_start_en ;
wire [31:0] tx_data     ;
wire udp_tx_done ;
wire tx_req      ;
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
    .tx_byte_num   (rec_byte_num),  //发送长度
    .tx_done       (udp_tx_done ),  //发送结束
    .tx_req        (tx_req      )   //四字节发送使能
);

axi_udp_cmd axi_udp_cmd_inst(
    .gmii_rx_clk         (gmii_rx_clk),
    .rstn                (sys_rst_n  ),
//..  __AXI接口____()
    .MASTER_CLK          (), 
    .MASTER_RSTN         (), 
    .MASTER_WR_ADDR_ID   (), 
    .MASTER_WR_ADDR      (), 
    .MASTER_WR_ADDR_LEN  (), 
    .MASTER_WR_ADDR_BURST(), 
    .MASTER_WR_ADDR_VALID(), 
    .MASTER_WR_ADDR_READY(), 
    .MASTER_WR_DATA      (), 
    .MASTER_WR_STRB      (), 
    .MASTER_WR_DATA_LAST (), 
    .MASTER_WR_DATA_VALID(), 
    .MASTER_WR_DATA_READY(), 
    .MASTER_WR_BACK_ID   (), 
    .MASTER_WR_BACK_RESP (), 
    .MASTER_WR_BACK_VALID(), 
    .MASTER_WR_BACK_READY(), 
    .MASTER_RD_ADDR_ID   (), 
    .MASTER_RD_ADDR      (), 
    .MASTER_RD_ADDR_LEN  (), 
    .MASTER_RD_ADDR_BURST(), 
    .MASTER_RD_ADDR_VALID(), 
    .MASTER_RD_ADDR_READY(), 
    .MASTER_RD_BACK_ID   (), 
    .MASTER_RD_DATA      (), 
    .MASTER_RD_DATA_RESP (), 
    .MASTER_RD_DATA_LAST (), 
    .MASTER_RD_DATA_VALID(), 
    .MASTER_RD_DATA_READY(), 
//  .  __UDP接口__()
    .udp_rx_done         (rec_pkt_done),
    .udp_rx_data         (rec_data    ),
    .udp_rx_en           (rec_en      ),
    .udp_tx_req          (tx_req      ),
    .udp_tx_start        (tx_start_en ),
    .udp_tx_data         (tx_data     )
);

reg grs_n;
GTP_GRS GRS_INST(.GRS_N (grs_n));
initial begin
grs_n = 1'b0;
#5 grs_n = 1'b1;
end

endmodule
