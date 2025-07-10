`timescale 1ns/1ps
`include "ddr3_parameters.vh"
module top_sim_test();

// outports wire
wire [7:0]      led8;
wire [3:0]      led4;
wire        	tck;
wire        	tms;
wire        	tdi;
wire        	rgmii_txc;
wire        	rgmii_tx_ctl;
wire [3:0]  	rgmii_txd;
wire        	eth_rst_n;

parameter MEM_DQ_WIDTH = 32;
parameter MEM_DQS_WIDTH = MEM_DQ_WIDTH/8;
parameter MEM_ROW_WIDTH = 15;

///////////////////////////test WRLVL case///////////////////////////
parameter CA_FIRST_DLY          = 0.15;
parameter CA_GROUP_TO_GROUP_DLY = 0.05;
////////////////////////////////////////////////////////////////////
localparam real ACTUAL_RATE  =  800.0   ; 
///////////////////////////test ppll sync case///////////////////////////
// 1 step rst_clk phase adjust changes 2 / 128 ppll fast clk phase. the ppll fast clk frequency is twice the otput frequecey of ppll.
parameter real OUT_SYNC_DLY = (500.0 / ACTUAL_RATE) * (123.0 / 128.0); 
////////////////////////////////////////////////////////////////////

wire         mem_rst_n    ; //Memory复位
wire         mem_ck       ; //Memory差分时钟正端
wire         mem_ck_n     ; //Memory差分时钟负端
wire         mem_cs_n     ; //Memory片选
wire [MEM_ROW_WIDTH-1:0]  mem_a        ; //Memory地址总线
wire [MEM_DQ_WIDTH-1:0]   mem_dq       ; //数据总线
wire [MEM_DQS_WIDTH-1:0]  mem_dqs      ; //数据时钟正端
wire [MEM_DQS_WIDTH-1:0]  mem_dqs_n    ; //数据时钟负端
wire [MEM_DQS_WIDTH-1:0]  mem_dm       ; //数据Mask
wire         mem_cke      ; //Memory差分时钟使能
wire         mem_odt      ; //On Die Termination
wire         mem_ras_n    ; //行地址strobe
wire         mem_cas_n    ; //列地址strobe
wire         mem_we_n     ; //写使能
wire [ 2:0]  mem_ba       ; //Bank地址总线
wire [ADDR_BITS-1:0] mem_addr;

reg external_clk;
initial external_clk = 0;
always #10 external_clk <= ~external_clk;

reg external_rstn;
initial begin
    external_rstn = 0;
    #5000
    external_rstn = 1;
end

reg [3:0] btn;
initial btn = 4'b1111;

wire tdo = 0;

initial begin
    #50000
    btn0_neg();
    #50000
    btn1_neg();
    #50000
    btn2_neg();
end

parameter BOARD_MAC     = {48'h12_34_56_78_9A_BC      }  ;
parameter BOARD_IP      = {8'd169,8'd254,8'd103,8'd006}  ;
parameter DES_MAC       = {48'h00_2B_67_09_FF_5E      }  ;
parameter DES_IP        = {8'd169,8'd254,8'd103,8'd126}  ;
initial begin
    #5000
    // while (~u_udp_axi_ddr_update_top.M_RSTN[0]) #1000;
    while (~u_udp_axi_ddr_update_top.S_RSTN[1]) #10000;
    #10000 u_rgmii_sim.send_rd_addr(2'b01, 2'b00, 3'd0, 32'h1000_0000); //对JTAG状态寄存器读，查看返回的FIFO状态 (32'h01020202)
    #10000 u_rgmii_sim.send_wr_addr(2'b10, 2'b00, 3'd3, 32'h1000_0002); //对JTAG的SHIFT_IN FIFO固定突发写4个数据
    #10000 u_rgmii_sim.send_wr_data(              3'd3, 32'h1234_5678); //写入
    #10000 u_rgmii_sim.send_rd_addr(2'b10, 2'b00, 3'd0, 32'h1000_0000); //对JTAG状态寄存器读，查看返回的FIFO状态是否空标志拉低 (32'h01020002)
    #10000 u_rgmii_sim.send_wr_addr(2'b10, 2'b00, 3'd0, 32'h1000_0000); //写JTAG状态寄存器
    #10000 u_rgmii_sim.send_wr_data(              3'd0, 32'hFFFF_FFFF); //重置FIFO状态
    #10000 u_rgmii_sim.send_rd_addr(2'b11, 2'b00, 3'd0, 32'h1000_0000); //对JTAG状态寄存器读，查看是否重置成功 (32'h01020202)
    #10000 u_rgmii_sim.send_wr_addr(2'b00, 2'b01, 3'd3, 32'h1000_0010); //对JTAG写入错误地址的数据，测试RESP响应
    #10000 u_rgmii_sim.send_wr_data(              3'd3, 32'h1234_5678); //写入，查看RESP响应是否为2'b10

    while (~u_udp_axi_ddr_update_top.S_RSTN[0]) #1000;
    #1000 u_rgmii_sim.send_wr_addr(2'b00, 2'b01, 3'd5, 32'h0101_0101);
    #1000 u_rgmii_sim.send_wr_data(              3'd5, 32'h1234_5678); //写入
    #1000;
    #1000 u_rgmii_sim.send_rd_addr(2'b00, 2'b01, 3'd5, 32'h0101_0101);
    #1000;
    #1000 u_rgmii_sim.send_wr_addr(2'b00, 2'b01, 3'd6, 32'h0000_00F0);
    #1000 u_rgmii_sim.send_wr_data(              3'd6, 32'h0000_0001); //写入
    #1000 u_rgmii_sim.send_rd_addr(2'b00, 2'b01, 3'd6, 32'h0000_00F0);

    #1000 u_rgmii_sim.send_wr_addr(2'b00, 2'b01, 3'd0, 32'h0000_0000);
    #1000 u_rgmii_sim.send_wr_data(              3'd6, 32'h1234_5678); //写入
    #1000 u_rgmii_sim.send_rd_addr(2'b00, 2'b01, 3'd0, 32'h0000_0000);
end

// outports wire
reg        	rgmii_rxc;
reg        	rgmii_rxc_x2;
initial rgmii_rxc = 0;
initial rgmii_rxc_x2 = 0;
always #4 rgmii_rxc <= ~rgmii_rxc;
always #2 rgmii_rxc_x2 <= ~rgmii_rxc_x2;

wire       	rgmii_rx_ctl;
wire [3:0] 	rgmii_rxd;

rgmii_sim #(
    .BOARD_IP       (BOARD_IP),
    .BOARD_MAC      (BOARD_MAC)
)u_rgmii_sim(
	.rgmii_rxc_x2 	( rgmii_rxc_x2  ),
	.rgmii_rxc    	(               ),
	.rgmii_rx_ctl 	( rgmii_rx_ctl  ),
	.rgmii_rxd    	( rgmii_rxd     ),
	.rgmii_txc    	( rgmii_txc     ),
	.rgmii_tx_ctl 	( rgmii_tx_ctl  ),
	.rgmii_txd    	( rgmii_txd     )
);

udp_axi_ddr_update_top #(
	.BOARD_MAC 	( BOARD_MAC   ),
	.BOARD_IP  	( BOARD_IP  ),
	.DES_MAC   	( DES_MAC     ),
	.DES_IP    	( DES_IP   ))
u_udp_axi_ddr_update_top(
	.external_clk      	( external_clk       ),
	.external_rstn     	( external_rstn      ),
	.btn               	( btn                ),
	.led8              	( led8               ),
	.led4              	( led4               ),
	.da_clk            	( da_clk             ),
	.da_data           	( da_data            ),
	.matrix_col        	( matrix_col         ),
	.matrix_row        	( 0         ),
	.lab_fpga_power_on 	( lab_fpga_power_on  ),
	.tck               	( tck                ),
	.tms               	( tms                ),
	.tdi               	( tdi                ),
	.tdo               	( tdo                ),
	.spi_cs            	( spi_cs             ),
	.spi_dq1           	( 0            ),
	.spi_dq0           	( spi_dq0            ),
	.scl_eeprom        	(          ),
	.sda_eeprom        	(          ),
	.scl_camera        	(          ),
	.sda_camera        	(          ),
	.CCD_PDN           	( CCD_PDN            ),
	.CCD_RSTN          	( CCD_RSTN           ),
	.CCD_PCLK          	( external_clk           ),
	.CCD_VSYNC         	( 0          ),
	.CCD_HSYNC         	( 0          ),
	.CCD_DATA          	( 0           ),
	.rgmii_rxc         	( rgmii_rxc          ),
	.rgmii_rx_ctl      	( rgmii_rx_ctl       ),
	.rgmii_rxd         	( rgmii_rxd          ),
	.rgmii_txc         	( rgmii_txc          ),
	.rgmii_tx_ctl      	( rgmii_tx_ctl       ),
	.rgmii_txd         	( rgmii_txd          ),
	.eth_rst_n         	( eth_rst_n          ),
	.i_p_refckn_0      	( 0       ),
	.i_p_refckp_0      	( 0       ),
	.mem_rst_n         	( mem_rst_n          ),
	.mem_ck            	( mem_ck             ),
	.mem_ck_n          	( mem_ck_n           ),
	.mem_cs_n          	( mem_cs_n           ),
	.mem_a             	( mem_a              ),
	.mem_dq            	( mem_dq             ),
	.mem_dqs           	( mem_dqs            ),
	.mem_dqs_n         	( mem_dqs_n          ),
	.mem_dm            	( mem_dm             ),
	.mem_cke           	( mem_cke            ),
	.mem_odt           	( mem_odt            ),
	.mem_ras_n         	( mem_ras_n          ),
	.mem_cas_n         	( mem_cas_n          ),
	.mem_we_n          	( mem_we_n           ),
	.mem_ba            	( mem_ba             )
);

wire [MEM_DQS_WIDTH+1:0] mem_ck_dly;
wire [MEM_DQS_WIDTH+1:0] mem_ck_n_dly;
wire [(MEM_DQS_WIDTH+2)*ADDR_BITS:0] mem_addr_dly;
wire [MEM_DQS_WIDTH+1:0] mem_cke_dly;
wire [MEM_DQS_WIDTH+1:0] mem_odt_dly;
wire [MEM_DQS_WIDTH+1:0] mem_ras_n_dly;
wire [MEM_DQS_WIDTH+1:0] mem_cas_n_dly;
wire [MEM_DQS_WIDTH+1:0] mem_we_n_dly;
wire [MEM_DQS_WIDTH*3+6:0] mem_ba_dly;
wire [MEM_DQS_WIDTH+1:0] mem_cs_n_dly;
wire [MEM_DQS_WIDTH+1:0] mem_rst_n_dly;


assign #CA_FIRST_DLY   mem_ck_dly[1:0]               =  {mem_ck,mem_ck}    ;
assign #CA_FIRST_DLY   mem_ck_n_dly[1:0]             =  {mem_ck_n,mem_ck_n}  ;
assign #CA_FIRST_DLY   mem_addr_dly[ADDR_BITS*2-1:0] =  {mem_addr,mem_addr}  ;
assign #CA_FIRST_DLY   mem_cke_dly[1:0]              =  {mem_cke,mem_cke}   ;
assign #CA_FIRST_DLY   mem_odt_dly[1:0]              =  {mem_odt,mem_odt}   ;
assign #CA_FIRST_DLY   mem_ras_n_dly[1:0]            =  {mem_ras_n,mem_ras_n} ;
assign #CA_FIRST_DLY   mem_cas_n_dly[1:0]            =  {mem_cas_n,mem_cas_n} ;
assign #CA_FIRST_DLY   mem_we_n_dly[1:0]             =  {mem_we_n,mem_we_n}  ;
assign #CA_FIRST_DLY   mem_ba_dly[5:0]               =  {mem_ba,mem_ba}    ;
assign #CA_FIRST_DLY   mem_cs_n_dly[1:0]             =  {mem_cs_n,mem_cs_n}  ;
assign #CA_FIRST_DLY   mem_rst_n_dly[1:0]            =  {mem_rst_n,mem_rst_n} ;


assign mem_addr = {{(ADDR_BITS-MEM_ROW_WIDTH){1'b0}},{mem_a}};

genvar gen_mem;                                                    
generate                                                         
    for(gen_mem=0; gen_mem<(MEM_DQS_WIDTH/2); gen_mem=gen_mem+1) begin: i_mem 
        assign #CA_GROUP_TO_GROUP_DLY   mem_addr_dly[(ADDR_BITS*(gen_mem+1)+ADDR_BITS)*2-1:(ADDR_BITS*(gen_mem+1))*2] =  mem_addr_dly[(ADDR_BITS*gen_mem+ADDR_BITS)*2-1:(ADDR_BITS*gen_mem)*2];
        assign #CA_GROUP_TO_GROUP_DLY   mem_cke_dly[2*gen_mem+3:2*gen_mem+2]                                          =  mem_cke_dly[2*gen_mem+1:2*gen_mem];
        assign #CA_GROUP_TO_GROUP_DLY   mem_odt_dly[2*gen_mem+3:2*gen_mem+2]                                          =  mem_odt_dly[2*gen_mem+1:2*gen_mem];
        assign #CA_GROUP_TO_GROUP_DLY   mem_ras_n_dly[2*gen_mem+3:2*gen_mem+2]                                        =  mem_ras_n_dly[2*gen_mem+1:2*gen_mem];
        assign #CA_GROUP_TO_GROUP_DLY   mem_cas_n_dly[2*gen_mem+3:2*gen_mem+2]                                        =  mem_cas_n_dly[2*gen_mem+1:2*gen_mem];
        assign #CA_GROUP_TO_GROUP_DLY   mem_we_n_dly[2*gen_mem+3:2*gen_mem+2]                                         =  mem_we_n_dly[2*gen_mem+1:2*gen_mem];
        assign #CA_GROUP_TO_GROUP_DLY   mem_ba_dly[(gen_mem+1)*6+5:(gen_mem+1)*6]                                     =  mem_ba_dly[gen_mem*6+5:gen_mem*6];
        assign #CA_GROUP_TO_GROUP_DLY   mem_cs_n_dly[2*gen_mem+3:2*gen_mem+2]                                         =  mem_cs_n_dly[2*gen_mem+1:2*gen_mem];
        assign #CA_GROUP_TO_GROUP_DLY   mem_rst_n_dly[2*gen_mem+3:2*gen_mem+2]                                        =  mem_rst_n_dly[2*gen_mem+1:2*gen_mem];
        assign #CA_GROUP_TO_GROUP_DLY   mem_ck_dly[2*gen_mem+3:2*gen_mem+2]                                           =  mem_ck_dly[2*gen_mem+1:2*gen_mem];
        assign #CA_GROUP_TO_GROUP_DLY   mem_ck_n_dly[2*gen_mem+3:2*gen_mem+2]                                         =  mem_ck_n_dly[2*gen_mem+1:2*gen_mem];
        ddr3 mem_core (
            .rst_n   (mem_rst_n_dly[2*gen_mem+1:2*gen_mem]                                 ),

            .ck      (mem_ck_dly[2*gen_mem+1:2*gen_mem]                                    ),
            .ck_n    (mem_ck_n_dly[2*gen_mem+1:2*gen_mem]                                  ),


            .cs_n    (mem_cs_n_dly[2*gen_mem+1:2*gen_mem]                                  ),

            .ras_n   (mem_ras_n_dly[2*gen_mem+1:2*gen_mem]                                 ),
            .cas_n   (mem_cas_n_dly[2*gen_mem+1:2*gen_mem]                                 ),
            .we_n    (mem_we_n_dly[2*gen_mem+1:2*gen_mem]                                  ),
            .addr    (mem_addr_dly[(ADDR_BITS*gen_mem+ADDR_BITS)*2-1:ADDR_BITS*gen_mem*2]  ),
            .ba      (mem_ba_dly[gen_mem*6+5:gen_mem*6]                                    ),
            .odt     (mem_odt_dly[2*gen_mem+1:2*gen_mem]                                   ),
            .cke     (mem_cke_dly[2*gen_mem+1:2*gen_mem]                                   ),

            .dq      (mem_dq[16*gen_mem+15:16*gen_mem]                                     ),
            .dqs     (mem_dqs[2*gen_mem+1:2*gen_mem]                                       ),
            .dqs_n   (mem_dqs_n[2*gen_mem+1:2*gen_mem]                                     ),
            .dm_tdqs (mem_dm[2*gen_mem+1:2*gen_mem]                                        ),
            .tdqs_n  (                                                                     )
        );
end     
endgenerate

reg grs_n;
GTP_GRS GRS_INST(.GRS_N (grs_n));
initial begin
grs_n = 1'b0;
#5 grs_n = 1'b1;
end

wire b0_gate;
wire b1_gate;
assign b1_gate = top_sim_test.u_udp_axi_ddr_update_top.S0.ddr3_top_inst.axi_ddr3_inst.u_ddrphy_top.ddrphy_reset_ctrl.ddrphy_ioclk_gate[1];
assign #OUT_SYNC_DLY b0_gate =  b1_gate;
initial 
begin    
    force top_sim_test.u_udp_axi_ddr_update_top.S0.ddr3_top_inst.axi_ddr3_inst.u_ddrphy_top.ddrphy_slice_top.i_dqs_bank[0].ddrphy_ppll.clkoutphy_gate = b0_gate;
//    force top_sim_test.u_udp_axi_ddr_update_top.S0.ddr3_top_inst.axi_ddr3_inst.u_ddrphy_top.ddrphy_slice_top.i_dqs_bank[2].ddrphy_ppll.clkoutphy_gate = b0_gate;
end


task automatic btn0_neg;
    btn[0] = 0;
    #200
    btn[0] = 1;
endtask //automatic

task automatic btn1_neg;
    btn[1] = 0;
    #200
    btn[1] = 1;
endtask //automatic

task automatic btn2_neg;
    btn[2] = 0;
    #200
    btn[2] = 1;
endtask //automatic

task automatic btn3_neg;
    btn[3] = 0;
    #200
    btn[3] = 1;
endtask //automatic

endmodule //top_sim_test
