`timescale 1ns/1ps
module udp_axi_master_sim(//本模块不需要输入时钟
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

parameter BOARD_MAC = 48'h12_34_56_78_9a_bc;
parameter BOARD_IP  = {8'd192,8'd168,8'd0,8'd234}; 
parameter DES_MAC   = 48'h00_2B_67_09_FF_5E;
parameter DES_IP    = {8'd169,8'd254,8'd103,8'd126};

reg             sys_clk         ;   //PHY芯片接收数据时钟信号
reg             sys_rst_n       ;   //系统复位,低电平有效
reg             eth_rxc         ;
reg             eth_rxc_x2      ;
reg             eth_rxdv        ;   //PHY芯片输入数据有效信号
wire            eth_txc         ;
wire            eth_tx_en_r     ;   //PHY芯片输出数据有效信号
wire    [3:0]   eth_tx_data_r   ;   //PHY芯片输出数据
wire    [3:0]   eth_rx_data     ;   //PHY芯片输入数据
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
wire            tx_req          ;
wire    [15:0]  udp_tx_byte_num ;

initial begin
    sys_clk    = 1'b1;
    eth_rxc    = 1'b1;
    eth_rxc_x2 = 1'b1;
    sys_rst_n  = 1'b0;
    eth_rxdv   = 0;
    #2000 sys_rst_n  = 1'b1;
end
always  #10 sys_clk = ~sys_clk; //50M
always  #4 eth_rxc = ~eth_rxc; //125M
always  #2 eth_rxc_x2 = ~eth_rxc_x2; //250M

localparam board_ip =  32'hEA_00_A8_C0;
localparam board_mac = 48'hBC_9A_78_56_34_12;
localparam data_byte_num = 16'h20_00;    //传32字节
localparam udp_byte_num = 16'h28_00; //data_byte_num+8,udp部首长8
reg [3:0] trans_bit4;
initial trans_bit4 = 0;

task  send_to_udp;
    input [     7:0] trans_num;
    input [32*8-1:0] trans_data;
    reg   [32*8-1:0] trans_data_reg;
    reg   [ 400-1:0] fixed_trans_data;
    integer i;
    begin
        @(negedge eth_rxc_x2) begin
            trans_data_reg <= trans_data;
            fixed_trans_data <= {16'h00_00,{(trans_num+8'd1+8'd8),8'h00},32'hD2_04_D2_04,board_ip,192'h91_00_A8_C0_00_00_11_80_00_00_00_5F_3C_00_00_45_00_08_2D_DB_4A_5E_D5_E0,board_mac,64'hD5_55_55_55_55_55_55_55};
            eth_rxdv <= 0;
        end
        for(i=0; i<(400)/4; i=i+1) begin
            @(negedge eth_rxc_x2) begin
                 eth_rxdv <= 1;
                 fixed_trans_data <= fixed_trans_data >> 4;
                 trans_bit4 <= fixed_trans_data[3:0];
             end
        end
        for(i=0; i<((32*8-(trans_num+1)*8)/4); i=i+1) trans_data_reg = trans_data_reg << 4;
        for(i=0; i<(((trans_num+1)*8)/4)/2; i=i+1) begin
            @(negedge eth_rxc_x2) begin
                 trans_bit4 <= trans_data_reg[(32*8-1-4)-:(4)];
             end
            @(negedge eth_rxc_x2) begin
                 trans_bit4 <= trans_data_reg[(32*8-1)-:(4)];
                 trans_data_reg <= trans_data_reg << 8;
             end
        end
        @(negedge eth_rxc_x2) eth_rxdv <= 0;
    end
endtask
assign eth_rx_data = (eth_rxdv)?(trans_bit4):(0);


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


endmodule //udp_axi_master_sim
