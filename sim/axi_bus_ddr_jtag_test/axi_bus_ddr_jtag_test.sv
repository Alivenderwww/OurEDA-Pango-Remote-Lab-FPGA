`timescale 1ns/1ps
`include "JTAG_CMD.vh"
module axi_bus_ddr_jtag_test ();
//DDR，JTAG和AXI-MASTER-SIM，AXI_SLAVE_SIM，AXI-BUS，AXI-INTERCONNECT，AXI_CLOCK_CONVERTER模块的配合

localparam M_WIDTH  = 2;
localparam S_WIDTH  = 3;
localparam M_ID     = 2;
localparam [31:0] START_ADDR[0:(2**S_WIDTH-1)] = '{32'h00000000, 32'h10000000, 32'h20000000, 32'h30000000, 32'h40000000, 32'h50000000, 32'h60000000, 32'h70000000};
localparam [31:0]   END_ADDR[0:(2**S_WIDTH-1)] = '{32'h0FFFFFFF, 32'h1FFFFFFF, 32'h2FFFFFFF, 32'h3FFFFFFF, 32'h4FFFFFFF, 32'h5FFFFFFF, 32'h6FFFFFFF, 32'h7FFFFFFF};

AXI_INF #(.ID_WIDTH(M_ID        ))AXI_MB[0:2**M_WIDTH-1]();
AXI_INF #(.ID_WIDTH(M_ID+M_WIDTH))AXI_BS[0:2**S_WIDTH-1]();
wire [4:0] M_fifo_empty_flag[0:(2**M_WIDTH-1)];
wire [4:0] S_fifo_empty_flag[0:(2**S_WIDTH-1)];

wire [7:0] dds_wave1, dds_wave0;

reg  ddr_ref_clk;
reg  ddr_rst_n  ;
reg  jtag_clk   ;
reg  jtag_rst_n ;
reg  dds_clk    ;
reg  dds_rstn   ;
reg  BUS_CLK    ;
reg  BUS_RSTN   ;

wire tck      ;
wire tdi      ;
wire tms      ;
wire tdo      ;
assign tdo = 0;

always #10 ddr_ref_clk = ~ddr_ref_clk;
always #7  jtag_clk = ~jtag_clk;
always #30 dds_clk = ~dds_clk;
always #15 BUS_CLK = ~BUS_CLK;

initial begin
    ddr_ref_clk = 0;
    ddr_rst_n = 0;
  #300000;
    ddr_rst_n = 1;
end

initial begin
     jtag_clk = 0;
     jtag_rst_n = 0;
#500 jtag_rst_n = 1;
end

initial begin
      dds_clk = 0;
      dds_rstn = 0;
#5000 dds_rstn = 1;
end

initial begin
        BUS_CLK = 0;
        BUS_RSTN = 0;
#50000  BUS_RSTN = 1;
end

initial begin
    #300 M0.set_clk(5);
    #300 S3.set_clk(15);
    #300 S4.set_clk(16);
    #300 S5.set_clk(17);
    #300 S6.set_clk(18);
    #300 S7.set_clk(19);
    #5000
    #300 M0.set_rd_data_channel(31);
    #300 M0.set_wr_data_channel(31);
    //IDCODE是器件标识符，同一种芯片的IDCODE相同。
    //JTAG读取IDCODE的流程：
    while (~AXI_BS[1].RSTN) #500;
    #300 M0.send_wr_addr(2'b00, 32'h10000000, 8'd000, 2'b01); //写JTAG状态寄存器
    #300 M0.send_wr_data(32'hFFFFFFFF, 4'b1111);              //清空全部fifo
    #300 M0.send_rd_addr(2'b00, 32'h10000000, 8'd000, 2'b01); //读取JTAG状态寄存器确认全部清空

    #300 M0.send_wr_addr(2'b00, 32'h10000003, 8'd000, 2'b00);    //写JTAG的cmd_fifo入口
    #300 M0.send_wr_data({{`CMD_JTAG_RUN_TEST}, 28'd00}, 4'b1111);//`CMD_JTAG_RUN_TEST，JTAG启动
    #300 M0.send_rd_addr(2'b00, 32'h10000000, 8'd000, 2'b00);    //读取JTAG状态寄存器确认CMD_DONE执行完毕，这里上位机做等待机制

    #300 M0.send_wr_addr(2'b00, 32'h10000002, 8'd000, 2'b00);    //写JTAG的data_in_fifo入口
    #300 M0.send_wr_data({22'b0,{`JTAG_DR_IDCODE}}, 4'b1111);    //写入JTAG指令`JTAG_DR_IDCODE，低10位有效，高22位无效
    #300 M0.send_wr_addr(2'b00, 32'h10000003, 8'd000, 2'b00);    //写JTAG的cmd_fifo入口
    #300 M0.send_wr_data({{`CMD_JTAG_LOAD_IR}, 28'd10}, 4'b1111);//{cmd,cyclenum} = {`CMD_JTAG_LOAD_IR，循环长度10}
    #300 M0.send_rd_addr(2'b00, 32'h10000000, 8'd000, 2'b00);    //读取JTAG状态寄存器确认CMD_DONE执行完毕，这里上位机做等待机制
    #300 M0.send_wr_addr(2'b00, 32'h10000000, 8'd000, 2'b00);    //写JTAG状态寄存器
    #300 M0.send_wr_data(32'h00001100, 4'b0010);                 //选通[15:8]，清空data_in_fifo以清除22位无效数据（或者FFFFFFFF全部清空）

    #300 M0.send_wr_addr(2'b00, 32'h10000003, 8'd000, 2'b00);     //写JTAG的cmd_fifo入口
    #300 M0.send_wr_data({{`CMD_JTAG_LOAD_DR_CAREO}, 28'd32}, 4'b1111);//{cmd,cyclenum} = {`CMD_JTAG_LOAD_DR_CAREO，循环长度32}
    #300 M0.send_rd_addr(2'b00, 32'h10000001, 8'd000, 2'b00);     //读取JTAG的data_out_fifo，读32bit（突发长度0）

    #300 M0.send_wr_addr(2'b00, 32'h10000003, 8'd000, 2'b00);     //写JTAG的cmd_fifo入口
    #300 M0.send_wr_data({{`CMD_JTAG_LOAD_DR_CAREI}, 28'd5000}, 4'b1111);//{cmd,cyclenum} = {`CMD_JTAG_LOAD_DR_CAREO，循环长度5000}
    #300 M0.send_wr_addr(2'b00, 32'h10000002, 8'd156, 2'b00);     //写JTAG的data_in_fifo入口，突发长度5000/32=156.25~157
    #300 M0.send_wr_data(32'hFFFFFFFF, 4'b1111);                  //写入比特流
    #900 M0.send_rd_addr(2'b00, 32'h10000000, 8'd000, 2'b00);     //读取JTAG状态寄存器确认CMD_DONE执行完毕，这里上位机做等待机制

    while (~AXI_BS[0].RSTN) #500;
    #300 M0.send_wr_addr(2'b00, 32'h00000000, 8'd255, 2'b01);
    #300 M0.send_wr_addr(2'b01, 32'h00010000, 8'd255, 2'b01);
    #300 M0.send_wr_data(32'h00000000, 4'b1111);
    #300 M0.send_wr_data(32'h10000000, 4'b1111);

    #300 M0.send_rd_addr(2'b00, 32'h00000000, 8'd255, 2'b01);
    #300 M0.send_rd_addr(2'b00, 32'h00010000, 8'd255, 2'b01);
    $display("here!");
    #300 M0.send_rd_addr(2'b00, 32'h000000F0, 8'h10, 2'b01);
end

initial begin
    #300 M1.set_clk(6);
    #5000
    #300 M1.set_rd_data_channel(31);
    #300 M1.set_wr_data_channel(31);
    while (~AXI_BS[2].RSTN) #1000;
    #300 M1.send_wr_addr(2'b00, 32'h20000000, 8'd000, 2'b00);
    #300 M1.send_wr_data(32'd0, 4'b1111);
    #300 M1.send_wr_addr(2'b00, 32'h20000001, 8'd000, 2'b00);
    #300 M1.send_wr_data(32'd20000, 4'b1111);
    #300 M1.send_wr_addr(2'b00, 32'h20000002, 8'd000, 2'b00);
    #300 M1.send_wr_data(32'd50000, 4'b1111);
    #300 M1.send_wr_addr(2'b00, 32'h20000003, 8'd000, 2'b00);
    #300 M1.send_wr_data(32'd100000, 4'b1111);
    #300 M1.send_wr_addr(2'b00, 32'h20000004, 8'd000, 2'b00);
    #300 M1.send_wr_data(32'd200000, 4'b1111);
    #300 M1.send_wr_addr(2'b00, 32'h20000009, 8'd000, 2'b00);
    #300 M1.send_wr_data(32'hFFFF_FFFF, 4'b1111);
    for(int i=0;i<16;i=i+1)begin
        #300 M1.send_wr_addr(2'b00, 32'h2000000A, 8'd255, 2'b00);
        #300 M1.send_wr_data(256*i, 4'b1111);
    end
    // #300 M1.send_wr_addr(2'b00, 32'h20000009, 8'd000, 2'b00);
    // #300 M1.send_wr_data(32'h0000_0000, 4'b1111);
    #400000 M1.send_wr_addr(2'b00, 32'h20000001, 8'd000, 2'b00);
    #300 M1.send_wr_data(32'd10000, 4'b1111);
    #400000 M1.send_wr_addr(2'b00, 32'h20000001, 8'd000, 2'b00);
    #300 M1.send_wr_data(32'd50000, 4'b1111);
    #400000 M1.send_wr_addr(2'b00, 32'h20000001, 8'd000, 2'b00);
    #300 M1.send_wr_data(32'd200000, 4'b1111);
    
    #300 M1.send_wr_addr(2'b00, 32'h20000010, 8'd000, 2'b00);
    #300 M1.send_wr_data(32'd0, 4'b1111);
    #300 M1.send_wr_addr(2'b00, 32'h20000011, 8'd000, 2'b00);
    #300 M1.send_wr_data(32'd20000, 4'b1111);
    #300 M1.send_wr_addr(2'b00, 32'h20000012, 8'd000, 2'b00);
    #300 M1.send_wr_data(32'd50000, 4'b1111);
    #300 M1.send_wr_addr(2'b00, 32'h20000013, 8'd000, 2'b00);
    #300 M1.send_wr_data(32'd100000, 4'b1111);
    #300 M1.send_wr_addr(2'b00, 32'h20000014, 8'd000, 2'b00);
    #300 M1.send_wr_data(32'd200000, 4'b1111);
    #300 M1.send_wr_addr(2'b00, 32'h20000019, 8'd000, 2'b00);
    #300 M1.send_wr_data(32'hFFFF_FFFF, 4'b1111);
    for(int i=0;i<16*256;i=i+1)begin
        #300 M1.send_wr_addr(2'b00, 32'h2000001A, 8'd0, 2'b00);
        #300 M1.send_wr_data(square_wave(i), 4'b1111);
    end
    #400000 M1.send_wr_addr(2'b00, 32'h20000011, 8'd000, 2'b00);
    #300 M1.send_wr_data(32'd10000, 4'b1111);
    #400000 M1.send_wr_addr(2'b00, 32'h20000011, 8'd000, 2'b00);
    #300 M1.send_wr_data(32'd50000, 4'b1111);
    #400000 M1.send_wr_addr(2'b00, 32'h20000011, 8'd000, 2'b00);
    #300 M1.send_wr_data(32'd200000, 4'b1111);
end

axi_master_sim M0(AXI_MB[0]);
axi_master_sim M1(AXI_MB[1]);
axi_master_sim M2(AXI_MB[2]);
axi_master_sim M3(AXI_MB[3]);

// axi_slave_default S0(AXI_BS[0]);
// axi_slave_default S1(AXI_BS[1]);
// axi_slave_default S2(AXI_BS[2]);
axi_slave_default S3(AXI_BS[3]);
axi_slave_default S4(AXI_BS[4]);
axi_slave_default S5(AXI_BS[5]);
axi_slave_default S6(AXI_BS[6]);
axi_slave_default S7(AXI_BS[7]);

ddr3_slave_sim #(
    .OFFSET_ADDR(START_ADDR[0]))
    S0(    //DDR时钟/复位/初始化接口
    .ddr_ref_clk   (ddr_ref_clk),
    .rst_n         (ddr_rst_n  ),
    .AXI_DDR_S     (AXI_BS[0]  )
);

JTAG_SLAVE #(
    .OFFSET_ADDR              (START_ADDR[1]))
    S1(
    .clk                      (jtag_clk  ),
    .rstn                     (jtag_rst_n),
    .tck                      (tck       ),
    .tdi                      (tdi       ),
    .tms                      (tms       ),
    .tdo                      (tdo       ),
    .JTAG_AXI_SLAVE           (AXI_BS[1] )
);

dds_slave #(
	.CHANNEL_NUM 	(2             ),
	.OFFSER_ADDR 	(START_ADDR[2]))
    S2(
	.clk            ( dds_clk      ),
	.rstn           ( dds_rstn     ),
	.wave_out       ( {dds_wave1,dds_wave0} ),
    .AXI_S          ( AXI_BS[2]    )
);

axi_bus #(
	.M_ID       	(M_ID      ),
	.M_WIDTH    	(M_WIDTH   ),
	.S_WIDTH    	(S_WIDTH   ),
	.START_ADDR 	(START_ADDR),
	.END_ADDR   	(END_ADDR  ))
u_axi_bus(
	.BUS_CLK           	( BUS_CLK            ),
	.BUS_RSTN          	( BUS_RSTN           ),
	.AXI_M             	( AXI_MB             ),
	.AXI_S             	( AXI_BS             ),
	.M_fifo_empty_flag 	( M_fifo_empty_flag  ),
	.S_fifo_empty_flag 	( S_fifo_empty_flag  )
);

reg grs_n;
GTP_GRS GRS_INST(.GRS_N (grs_n));
initial begin
grs_n = 1'b0;
#5 grs_n = 1'b1;
end

function [7:0] square_wave;
input integer in0;
begin
    square_wave = ((in0 % 500) > 250)?(8'hFF):(8'h00);
end
endfunction

endmodule