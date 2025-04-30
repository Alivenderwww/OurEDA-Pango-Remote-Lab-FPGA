`timescale 1ns/1ps
`include "JTAG_CMD.vh"
module axi_bus_ddr_jtag_test ();
//DDR，JTAG和AXI-MASTER-SIM，AXI_SLAVE_SIM，AXI-BUS，AXI-INTERCONNECT，AXI_CLOCK_CONVERTER模块的配合

localparam M_WIDTH  = 2;
localparam S_WIDTH  = 3;
localparam M_ID     = 2;
localparam [0:(2**S_WIDTH-1)][31:0] START_ADDR = '{32'h00000000, 32'h10000000, 32'h20000000, 32'h30000000, 32'h40000000, 32'h50000000, 32'h60000000, 32'h70000000};
localparam [0:(2**S_WIDTH-1)][31:0]   END_ADDR = '{32'h0FFFFFFF, 32'h1FFFFFFF, 32'h2FFFFFFF, 32'h3FFFFFFF, 32'h4FFFFFFF, 32'h5FFFFFFF, 32'h6FFFFFFF, 32'h7FFFFFFF};

wire [(2**M_WIDTH-1):0]            M_CLK          ;
wire [(2**M_WIDTH-1):0]            M_RSTN         ;
wire [(2**M_WIDTH-1):0] [M_ID-1:0] M_WR_ADDR_ID   ;
wire [(2**M_WIDTH-1):0] [31:0]     M_WR_ADDR      ;
wire [(2**M_WIDTH-1):0] [ 7:0]     M_WR_ADDR_LEN  ;
wire [(2**M_WIDTH-1):0] [ 1:0]     M_WR_ADDR_BURST;
wire [(2**M_WIDTH-1):0]            M_WR_ADDR_VALID;
wire [(2**M_WIDTH-1):0]            M_WR_ADDR_READY;
wire [(2**M_WIDTH-1):0] [31:0]     M_WR_DATA      ;
wire [(2**M_WIDTH-1):0] [ 3:0]     M_WR_STRB      ;
wire [(2**M_WIDTH-1):0]            M_WR_DATA_LAST ;
wire [(2**M_WIDTH-1):0]            M_WR_DATA_VALID;
wire [(2**M_WIDTH-1):0]            M_WR_DATA_READY;
wire [(2**M_WIDTH-1):0] [M_ID-1:0] M_WR_BACK_ID   ;
wire [(2**M_WIDTH-1):0] [ 1:0]     M_WR_BACK_RESP ;
wire [(2**M_WIDTH-1):0]            M_WR_BACK_VALID;
wire [(2**M_WIDTH-1):0]            M_WR_BACK_READY;
wire [(2**M_WIDTH-1):0] [M_ID-1:0] M_RD_ADDR_ID   ;
wire [(2**M_WIDTH-1):0] [31:0]     M_RD_ADDR      ;
wire [(2**M_WIDTH-1):0] [ 7:0]     M_RD_ADDR_LEN  ;
wire [(2**M_WIDTH-1):0] [ 1:0]     M_RD_ADDR_BURST;
wire [(2**M_WIDTH-1):0]            M_RD_ADDR_VALID;
wire [(2**M_WIDTH-1):0]            M_RD_ADDR_READY;
wire [(2**M_WIDTH-1):0] [M_ID-1:0] M_RD_BACK_ID   ;
wire [(2**M_WIDTH-1):0] [31:0]     M_RD_DATA      ;
wire [(2**M_WIDTH-1):0] [ 1:0]     M_RD_DATA_RESP ;
wire [(2**M_WIDTH-1):0]            M_RD_DATA_LAST ;
wire [(2**M_WIDTH-1):0]            M_RD_DATA_VALID;
wire [(2**M_WIDTH-1):0]            M_RD_DATA_READY;

wire [(2**S_WIDTH-1):0]                    S_CLK          ;
wire [(2**S_WIDTH-1):0]                    S_RSTN         ;
wire [(2**S_WIDTH-1):0] [M_ID+M_WIDTH-1:0] S_WR_ADDR_ID   ;
wire [(2**S_WIDTH-1):0] [31:0]             S_WR_ADDR      ;
wire [(2**S_WIDTH-1):0] [ 7:0]             S_WR_ADDR_LEN  ;
wire [(2**S_WIDTH-1):0] [ 1:0]             S_WR_ADDR_BURST;
wire [(2**S_WIDTH-1):0]                    S_WR_ADDR_VALID;
wire [(2**S_WIDTH-1):0]                    S_WR_ADDR_READY;
wire [(2**S_WIDTH-1):0] [31:0]             S_WR_DATA      ;
wire [(2**S_WIDTH-1):0] [ 3:0]             S_WR_STRB      ;
wire [(2**S_WIDTH-1):0]                    S_WR_DATA_LAST ;
wire [(2**S_WIDTH-1):0]                    S_WR_DATA_VALID;
wire [(2**S_WIDTH-1):0]                    S_WR_DATA_READY;
wire [(2**S_WIDTH-1):0] [M_ID+M_WIDTH-1:0] S_WR_BACK_ID   ;
wire [(2**S_WIDTH-1):0] [ 1:0]             S_WR_BACK_RESP ;
wire [(2**S_WIDTH-1):0]                    S_WR_BACK_VALID;
wire [(2**S_WIDTH-1):0]                    S_WR_BACK_READY;
wire [(2**S_WIDTH-1):0] [M_ID+M_WIDTH-1:0] S_RD_ADDR_ID   ;
wire [(2**S_WIDTH-1):0] [31:0]             S_RD_ADDR      ;
wire [(2**S_WIDTH-1):0] [ 7:0]             S_RD_ADDR_LEN  ;
wire [(2**S_WIDTH-1):0] [ 1:0]             S_RD_ADDR_BURST;
wire [(2**S_WIDTH-1):0]                    S_RD_ADDR_VALID;
wire [(2**S_WIDTH-1):0]                    S_RD_ADDR_READY;
wire [(2**S_WIDTH-1):0] [M_ID+M_WIDTH-1:0] S_RD_BACK_ID   ;
wire [(2**S_WIDTH-1):0] [31:0]             S_RD_DATA      ;
wire [(2**S_WIDTH-1):0] [ 1:0]             S_RD_DATA_RESP ;
wire [(2**S_WIDTH-1):0]                    S_RD_DATA_LAST ;
wire [(2**S_WIDTH-1):0]                    S_RD_DATA_VALID;
wire [(2**S_WIDTH-1):0]                    S_RD_DATA_READY;

wire [0:(2**M_WIDTH-1)] [4:0] M_fifo_empty_flag;
wire [0:(2**S_WIDTH-1)] [4:0] S_fifo_empty_flag;

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
    ddr_rst_n = 0;
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

/*
装载比特流的顺序：
0. CMD_JTAG_CLOSE_TEST                  0
1. CMD_JTAG_RUN_TEST                    0
2. CMD_JTAG_LOAD_IR    `JTAG_DR_JRST    10
3. CMD_JTAG_RUN_TEST                    0
4. CMD_JTAG_LOAD_IR    `JTAG_DR_CFGI    10
5. CMD_JTAG_IDLE_DELAY                  75000
6. CMD_JTAG_LOAD_DR    "BITSTREAM"      取决于比特流大小
7. CMD_JTAG_CLOSE_TEST                  0
8. CMD_JTAG_RUN_TEST                    0
9. CMD_JTAG_LOAD_IR    `JTAG_DR_JWAKEUP 10
A. CMD_JTAG_IDLE_DELAY                  1000
B. CMD_JTAG_CLOSE_TEST                  0
*/

/*
获取IDCODE的顺序：
0. CMD_JTAG_CLOSE_TEST                  0
1. CMD_JTAG_RUN_TEST                    0
2. CMD_JTAG_LOAD_IR    `JTAG_DR_IDCODE  10
3. CMD_JTAG_RUN_TEST                    0
4. CMD_JTAG_LOAD_DR    NOTCARE          32
5. CMD_JTAG_CLOSE_TEST                  0
*/

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
    while (~S_RSTN[1]) #500;
    
    #300 M0.send_wr_addr(2'b00, 32'h10000004, 8'd1023, 2'b00);      //写JTAG的data_in_fifo入口，突发长度256*666/32
    #300 M0.send_wr_data(32'h00000000, 4'b1111);                  //写入比特流
    
    #300 M0.send_wr_addr(2'b00, 32'h10000004, 8'd1023, 2'b00);      //写JTAG的data_in_fifo入口，突发长度256*666/32
    #300 M0.send_wr_data(32'h10002000, 4'b1111);                  //写入比特流

    // #300 M0.send_wr_addr(2'b00, 32'h10000000, 8'd000, 2'b01); //写JTAG状态寄存器
    // #300 M0.send_wr_data(32'hFFFFFFFF, 4'b1111);              //清空全部fifo
    // #300 M0.send_rd_addr(2'b00, 32'h10000000, 8'd000, 2'b01); //读取JTAG状态寄存器确认全部清空

    // #300 M0.send_wr_addr(2'b00, 32'h10000003, 8'd000, 2'b00);    //写JTAG的cmd_fifo入口
    // #300 M0.send_wr_data({{`CMD_JTAG_RUN_TEST}, 28'd00}, 4'b1111);//`CMD_JTAG_RUN_TEST，JTAG启动
    // #8000 M0.send_rd_addr(2'b00, 32'h10000000, 8'd000, 2'b00);    //读取JTAG状态寄存器确认CMD_DONE执行完毕，这里上位机做等待机制

    // #300 M0.send_wr_addr(2'b00, 32'h10000002, 8'd000, 2'b00);    //写JTAG的data_in_fifo入口
    // #300 M0.send_wr_data({22'b0,{`JTAG_DR_IDCODE}}, 4'b1111);    //写入JTAG指令`JTAG_DR_IDCODE，低10位有效，高22位无效
    // #300 M0.send_wr_addr(2'b00, 32'h10000003, 8'd000, 2'b00);    //写JTAG的cmd_fifo入口
    // #300 M0.send_wr_data({{`CMD_JTAG_LOAD_IR}, 28'd10}, 4'b1111);//{cmd,cyclenum} = {`CMD_JTAG_LOAD_IR，循环长度10}
    // #8000 M0.send_rd_addr(2'b00, 32'h10000000, 8'd000, 2'b00);    //读取JTAG状态寄存器确认CMD_DONE执行完毕，这里上位机做等待机制
    // #8000 M0.send_wr_addr(2'b00, 32'h10000000, 8'd000, 2'b00);    //写JTAG状态寄存器
    // #8000 M0.send_wr_data(32'h00001100, 4'b0010);                 //选通[15:8]，清空data_in_fifo以清除22位无效数据（或者FFFFFFFF全部清空）

    // #300 M0.send_wr_addr(2'b00, 32'h10000003, 8'd000, 2'b00);     //写JTAG的cmd_fifo入口
    // #300 M0.send_wr_data({{`CMD_JTAG_LOAD_DR_CAREO}, 28'd32}, 4'b1111);//{cmd,cyclenum} = {`CMD_JTAG_LOAD_DR_CAREO，循环长度32}
    // #300 M0.send_rd_addr(2'b00, 32'h10000001, 8'd000, 2'b00);     //读取JTAG的data_out_fifo，读32bit（突发长度0）


    // //start of download bitstream

    // #300 M0.send_wr_addr(2'b00, 32'h10000003, 8'd000, 2'b00);    //写JTAG的cmd_fifo入口
    // #300 M0.send_wr_data({{`CMD_JTAG_RUN_TEST}, 28'd00}, 4'b1111);//`CMD_JTAG_RUN_TEST，JTAG启动
    // #300 M0.send_rd_addr(2'b00, 32'h10000000, 8'd000, 2'b00);    //读取JTAG状态寄存器确认CMD_DONE执行完毕，这里上位机做等待机制

    // #300 M0.send_wr_addr(2'b00, 32'h10000002, 8'd000, 2'b00);    //写JTAG的data_in_fifo入口
    // #300 M0.send_wr_data({22'b0,{`JTAG_DR_JRST}}, 4'b1111);    //写入JTAG指令`JTAG_DR_JRST，低10位有效，高22位无效
    // #300 M0.send_wr_addr(2'b00, 32'h10000003, 8'd000, 2'b00);    //写JTAG的cmd_fifo入口
    // #300 M0.send_wr_data({{`CMD_JTAG_LOAD_IR}, 28'd10}, 4'b1111);//{cmd,cyclenum} = {`CMD_JTAG_LOAD_IR，循环长度10}
    // #300 M0.send_rd_addr(2'b00, 32'h10000000, 8'd000, 2'b00);    //读取JTAG状态寄存器确认CMD_DONE执行完毕，这里上位机做等待机制
    // #300 M0.send_wr_addr(2'b00, 32'h10000000, 8'd000, 2'b00);    //写JTAG状态寄存器
    // #300 M0.send_wr_data(32'h00001100, 4'b0010);                 //选通[15:8]，清空data_in_fifo以清除22位无效数据（或者FFFFFFFF全部清空）

    // #300 M0.send_wr_addr(2'b00, 32'h10000003, 8'd000, 2'b00);    
    // #300 M0.send_wr_data({{`CMD_JTAG_RUN_TEST}, 28'd00}, 4'b1111);
    // #300 M0.send_rd_addr(2'b00, 32'h10000000, 8'd000, 2'b00);   

    // #300 M0.send_wr_addr(2'b00, 32'h10000002, 8'd000, 2'b00);  
    // #300 M0.send_wr_data({22'b0,{`JTAG_DR_CFGI}}, 4'b1111);    
    // #300 M0.send_wr_addr(2'b00, 32'h10000003, 8'd000, 2'b00);  
    // #300 M0.send_wr_data({{`CMD_JTAG_LOAD_IR}, 28'd10}, 4'b1111);
    // #300 M0.send_rd_addr(2'b00, 32'h10000000, 8'd000, 2'b00);    
    // #300 M0.send_wr_addr(2'b00, 32'h10000000, 8'd000, 2'b00);    
    // #300 M0.send_wr_data(32'h00001100, 4'b0010);                 

    // #300 M0.send_wr_addr(2'b00, 32'h10000003, 8'd000, 2'b00);    
    // #300 M0.send_wr_data({{`CMD_JTAG_IDLE_DELAY}, 28'd1000}, 4'b1111);
    // #300 M0.send_rd_addr(2'b00, 32'h10000000, 8'd000, 2'b00);   

    // #300 M0.send_wr_addr(2'b00, 32'h10000003, 8'd000, 2'b00);     //写JTAG的cmd_fifo入口
    // #300 M0.send_wr_data({{`CMD_JTAG_LOAD_DR_CAREI}, 28'd256*28'd666}, 4'b1111);//{cmd,cyclenum} = {`CMD_JTAG_LOAD_DR_CAREO，循环长度设置为256*666}
    // #300 M0.send_wr_addr(2'b00, 32'h10000002, 8'd1023, 2'b00);      //写JTAG的data_in_fifo入口，突发长度256*666/32=5328=1024+1024+1024+1024+1024+1024+208
    // #300 M0.send_wr_data(32'h00000000, 4'b1111);                  //写入比特流
    // #300 M0.send_wr_addr(2'b00, 32'h10000002, 8'd1023, 2'b00);      //写JTAG的data_in_fifo入口，突发长度256*666/32
    // #300 M0.send_wr_data(32'h00000000, 4'b1111);                  //写入比特流
    // #300 M0.send_wr_addr(2'b00, 32'h10000002, 8'd1023, 2'b00);      //写JTAG的data_in_fifo入口，突发长度256*666/32
    // #300 M0.send_wr_data(32'h00000000, 4'b1111);                  //写入比特流
    // #300 M0.send_wr_addr(2'b00, 32'h10000002, 8'd1023, 2'b00);      //写JTAG的data_in_fifo入口，突发长度256*666/32
    // #300 M0.send_wr_data(32'h00000000, 4'b1111);                  //写入比特流
    // #300 M0.send_wr_addr(2'b00, 32'h10000002, 8'd1023, 2'b00);      //写JTAG的data_in_fifo入口，突发长度256*666/32
    // #300 M0.send_wr_data(32'h00000000, 4'b1111);                  //写入比特流
    // #300 M0.send_wr_addr(2'b00, 32'h10000002, 8'd1023, 2'b00);      //写JTAG的data_in_fifo入口，突发长度256*666/32
    // #300 M0.send_wr_data(32'h00000000, 4'b1111);                  //写入比特流
    // #300 M0.send_wr_addr(2'b00, 32'h10000002, 8'd208-8'd1, 2'b00);      //写JTAG的data_in_fifo入口，突发长度256*666/32
    // #300 M0.send_wr_data(32'h00000000, 4'b1111);                  //写入比特流
    // #900 M0.send_rd_addr(2'b00, 32'h10000000, 8'd000, 2'b00);     //读取JTAG状态寄存器确认CMD_DONE执行完毕，这里上位机做等待机制
    // #300000
    // #900 M0.send_rd_addr(2'b00, 32'h10000000, 8'd000, 2'b00);     //读取JTAG状态寄存器确认CMD_DONE执行完毕，这里上位机做等待机制

    // #300 M0.send_wr_addr(2'b00, 32'h10000003, 8'd000, 2'b00);   
    // #300 M0.send_wr_data({{`CMD_JTAG_CLOSE_TEST}, 28'd00}, 4'b1111);
    // #300 M0.send_rd_addr(2'b00, 32'h10000000, 8'd000, 2'b00); 

    // #300 M0.send_wr_addr(2'b00, 32'h10000003, 8'd000, 2'b00);   
    // #300 M0.send_wr_data({{`CMD_JTAG_RUN_TEST}, 28'd00}, 4'b1111);
    // #300 M0.send_rd_addr(2'b00, 32'h10000000, 8'd000, 2'b00); 

    // #300 M0.send_wr_addr(2'b00, 32'h10000002, 8'd000, 2'b00);  
    // #300 M0.send_wr_data({22'b0,{`JTAG_DR_JWAKEUP}}, 4'b1111);    
    // #300 M0.send_wr_addr(2'b00, 32'h10000003, 8'd000, 2'b00);  
    // #300 M0.send_wr_data({{`CMD_JTAG_LOAD_IR}, 28'd10}, 4'b1111);
    // #300 M0.send_rd_addr(2'b00, 32'h10000000, 8'd000, 2'b00);    
    // #300 M0.send_wr_addr(2'b00, 32'h10000000, 8'd000, 2'b00);    
    // #300 M0.send_wr_data(32'h00001100, 4'b0010);          

    // #300 M0.send_wr_addr(2'b00, 32'h10000003, 8'd000, 2'b00);    
    // #300 M0.send_wr_data({{`CMD_JTAG_IDLE_DELAY}, 28'd1000}, 4'b1111);
    // #300 M0.send_rd_addr(2'b00, 32'h10000000, 8'd000, 2'b00); 

    // #300 M0.send_wr_addr(2'b00, 32'h10000003, 8'd000, 2'b00);   
    // #300 M0.send_wr_data({{`CMD_JTAG_CLOSE_TEST}, 28'd00}, 4'b1111);
    // #300 M0.send_rd_addr(2'b00, 32'h10000000, 8'd000, 2'b00);   

    //end of download bitstream
    while (~S_RSTN[0]) #500;
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
    while (~S_RSTN[2]) #1000;
    // #300 M1.send_wr_addr(2'b00, 32'h20000000, 8'd000, 2'b00);
    // #300 M1.send_wr_data(32'd0, 4'b1111);
    // #300 M1.send_wr_addr(2'b00, 32'h20000001, 8'd000, 2'b00);
    // #300 M1.send_wr_data(32'd20000, 4'b1111);
    // #300 M1.send_wr_addr(2'b00, 32'h20000002, 8'd000, 2'b00);
    // #300 M1.send_wr_data(32'd50000, 4'b1111);
    // #300 M1.send_wr_addr(2'b00, 32'h20000003, 8'd000, 2'b00);
    // #300 M1.send_wr_data(32'd100000, 4'b1111);
    // #300 M1.send_wr_addr(2'b00, 32'h20000004, 8'd000, 2'b00);
    // #300 M1.send_wr_data(32'd200000, 4'b1111);
    // #300 M1.send_wr_addr(2'b00, 32'h20000009, 8'd000, 2'b00);
    // #300 M1.send_wr_data(32'hFFFF_FFFF, 4'b1111);
    // for(int i=0;i<16;i=i+1)begin
    //     #300 M1.send_wr_addr(2'b00, 32'h2000000A, 8'd255, 2'b00);
    //     #300 M1.send_wr_data(256*i, 4'b1111);
    // end
    // // #300 M1.send_wr_addr(2'b00, 32'h20000009, 8'd000, 2'b00);
    // // #300 M1.send_wr_data(32'h0000_0000, 4'b1111);
    // #400000 M1.send_wr_addr(2'b00, 32'h20000001, 8'd000, 2'b00);
    // #300 M1.send_wr_data(32'd10000, 4'b1111);
    // #400000 M1.send_wr_addr(2'b00, 32'h20000001, 8'd000, 2'b00);
    // #300 M1.send_wr_data(32'd50000, 4'b1111);
    // #400000 M1.send_wr_addr(2'b00, 32'h20000001, 8'd000, 2'b00);
    // #300 M1.send_wr_data(32'd200000, 4'b1111);
    
    // #300 M1.send_wr_addr(2'b00, 32'h20000010, 8'd000, 2'b00);
    // #300 M1.send_wr_data(32'd0, 4'b1111);
    // #300 M1.send_wr_addr(2'b00, 32'h20000011, 8'd000, 2'b00);
    // #300 M1.send_wr_data(32'd20000, 4'b1111);
    // #300 M1.send_wr_addr(2'b00, 32'h20000012, 8'd000, 2'b00);
    // #300 M1.send_wr_data(32'd50000, 4'b1111);
    // #300 M1.send_wr_addr(2'b00, 32'h20000013, 8'd000, 2'b00);
    // #300 M1.send_wr_data(32'd100000, 4'b1111);
    // #300 M1.send_wr_addr(2'b00, 32'h20000014, 8'd000, 2'b00);
    // #300 M1.send_wr_data(32'd200000, 4'b1111);
    // #300 M1.send_wr_addr(2'b00, 32'h20000019, 8'd000, 2'b00);
    // #300 M1.send_wr_data(32'hFFFF_FFFF, 4'b1111);
    // for(int i=0;i<16*256;i=i+1)begin
    //     #300 M1.send_wr_addr(2'b00, 32'h2000001A, 8'd0, 2'b00);
    //     #300 M1.send_wr_data(square_wave(i), 4'b1111);
    // end
    // #400000 M1.send_wr_addr(2'b00, 32'h20000011, 8'd000, 2'b00);
    // #300 M1.send_wr_data(32'd10000, 4'b1111);
    // #400000 M1.send_wr_addr(2'b00, 32'h20000011, 8'd000, 2'b00);
    // #300 M1.send_wr_data(32'd50000, 4'b1111);
    // #400000 M1.send_wr_addr(2'b00, 32'h20000011, 8'd000, 2'b00);
    // #300 M1.send_wr_data(32'd200000, 4'b1111);
end

axi_master_sim M0(
.MASTER_CLK          (M_CLK          [0]),
.MASTER_RSTN         (M_RSTN         [0]),
.MASTER_WR_ADDR_ID   (M_WR_ADDR_ID   [0]),
.MASTER_WR_ADDR      (M_WR_ADDR      [0]),
.MASTER_WR_ADDR_LEN  (M_WR_ADDR_LEN  [0]),
.MASTER_WR_ADDR_BURST(M_WR_ADDR_BURST[0]),
.MASTER_WR_ADDR_VALID(M_WR_ADDR_VALID[0]),
.MASTER_WR_ADDR_READY(M_WR_ADDR_READY[0]),
.MASTER_WR_DATA      (M_WR_DATA      [0]),
.MASTER_WR_STRB      (M_WR_STRB      [0]),
.MASTER_WR_DATA_LAST (M_WR_DATA_LAST [0]),
.MASTER_WR_DATA_VALID(M_WR_DATA_VALID[0]),
.MASTER_WR_DATA_READY(M_WR_DATA_READY[0]),
.MASTER_WR_BACK_ID   (M_WR_BACK_ID   [0]),
.MASTER_WR_BACK_RESP (M_WR_BACK_RESP [0]),
.MASTER_WR_BACK_VALID(M_WR_BACK_VALID[0]),
.MASTER_WR_BACK_READY(M_WR_BACK_READY[0]),
.MASTER_RD_ADDR_ID   (M_RD_ADDR_ID   [0]),
.MASTER_RD_ADDR      (M_RD_ADDR      [0]),
.MASTER_RD_ADDR_LEN  (M_RD_ADDR_LEN  [0]),
.MASTER_RD_ADDR_BURST(M_RD_ADDR_BURST[0]),
.MASTER_RD_ADDR_VALID(M_RD_ADDR_VALID[0]),
.MASTER_RD_ADDR_READY(M_RD_ADDR_READY[0]),
.MASTER_RD_BACK_ID   (M_RD_BACK_ID   [0]),
.MASTER_RD_DATA      (M_RD_DATA      [0]),
.MASTER_RD_DATA_RESP (M_RD_DATA_RESP [0]),
.MASTER_RD_DATA_LAST (M_RD_DATA_LAST [0]),
.MASTER_RD_DATA_VALID(M_RD_DATA_VALID[0]),
.MASTER_RD_DATA_READY(M_RD_DATA_READY[0])
);

axi_master_sim M1(
.MASTER_CLK          (M_CLK          [1]),
.MASTER_RSTN         (M_RSTN         [1]),
.MASTER_WR_ADDR_ID   (M_WR_ADDR_ID   [1]),
.MASTER_WR_ADDR      (M_WR_ADDR      [1]),
.MASTER_WR_ADDR_LEN  (M_WR_ADDR_LEN  [1]),
.MASTER_WR_ADDR_BURST(M_WR_ADDR_BURST[1]),
.MASTER_WR_ADDR_VALID(M_WR_ADDR_VALID[1]),
.MASTER_WR_ADDR_READY(M_WR_ADDR_READY[1]),
.MASTER_WR_DATA      (M_WR_DATA      [1]),
.MASTER_WR_STRB      (M_WR_STRB      [1]),
.MASTER_WR_DATA_LAST (M_WR_DATA_LAST [1]),
.MASTER_WR_DATA_VALID(M_WR_DATA_VALID[1]),
.MASTER_WR_DATA_READY(M_WR_DATA_READY[1]),
.MASTER_WR_BACK_ID   (M_WR_BACK_ID   [1]),
.MASTER_WR_BACK_RESP (M_WR_BACK_RESP [1]),
.MASTER_WR_BACK_VALID(M_WR_BACK_VALID[1]),
.MASTER_WR_BACK_READY(M_WR_BACK_READY[1]),
.MASTER_RD_ADDR_ID   (M_RD_ADDR_ID   [1]),
.MASTER_RD_ADDR      (M_RD_ADDR      [1]),
.MASTER_RD_ADDR_LEN  (M_RD_ADDR_LEN  [1]),
.MASTER_RD_ADDR_BURST(M_RD_ADDR_BURST[1]),
.MASTER_RD_ADDR_VALID(M_RD_ADDR_VALID[1]),
.MASTER_RD_ADDR_READY(M_RD_ADDR_READY[1]),
.MASTER_RD_BACK_ID   (M_RD_BACK_ID   [1]),
.MASTER_RD_DATA      (M_RD_DATA      [1]),
.MASTER_RD_DATA_RESP (M_RD_DATA_RESP [1]),
.MASTER_RD_DATA_LAST (M_RD_DATA_LAST [1]),
.MASTER_RD_DATA_VALID(M_RD_DATA_VALID[1]),
.MASTER_RD_DATA_READY(M_RD_DATA_READY[1])
);

axi_master_sim M2(
.MASTER_CLK          (M_CLK          [2]),
.MASTER_RSTN         (M_RSTN         [2]),
.MASTER_WR_ADDR_ID   (M_WR_ADDR_ID   [2]),
.MASTER_WR_ADDR      (M_WR_ADDR      [2]),
.MASTER_WR_ADDR_LEN  (M_WR_ADDR_LEN  [2]),
.MASTER_WR_ADDR_BURST(M_WR_ADDR_BURST[2]),
.MASTER_WR_ADDR_VALID(M_WR_ADDR_VALID[2]),
.MASTER_WR_ADDR_READY(M_WR_ADDR_READY[2]),
.MASTER_WR_DATA      (M_WR_DATA      [2]),
.MASTER_WR_STRB      (M_WR_STRB      [2]),
.MASTER_WR_DATA_LAST (M_WR_DATA_LAST [2]),
.MASTER_WR_DATA_VALID(M_WR_DATA_VALID[2]),
.MASTER_WR_DATA_READY(M_WR_DATA_READY[2]),
.MASTER_WR_BACK_ID   (M_WR_BACK_ID   [2]),
.MASTER_WR_BACK_RESP (M_WR_BACK_RESP [2]),
.MASTER_WR_BACK_VALID(M_WR_BACK_VALID[2]),
.MASTER_WR_BACK_READY(M_WR_BACK_READY[2]),
.MASTER_RD_ADDR_ID   (M_RD_ADDR_ID   [2]),
.MASTER_RD_ADDR      (M_RD_ADDR      [2]),
.MASTER_RD_ADDR_LEN  (M_RD_ADDR_LEN  [2]),
.MASTER_RD_ADDR_BURST(M_RD_ADDR_BURST[2]),
.MASTER_RD_ADDR_VALID(M_RD_ADDR_VALID[2]),
.MASTER_RD_ADDR_READY(M_RD_ADDR_READY[2]),
.MASTER_RD_BACK_ID   (M_RD_BACK_ID   [2]),
.MASTER_RD_DATA      (M_RD_DATA      [2]),
.MASTER_RD_DATA_RESP (M_RD_DATA_RESP [2]),
.MASTER_RD_DATA_LAST (M_RD_DATA_LAST [2]),
.MASTER_RD_DATA_VALID(M_RD_DATA_VALID[2]),
.MASTER_RD_DATA_READY(M_RD_DATA_READY[2])
);

axi_master_sim M3(
.MASTER_CLK          (M_CLK          [3]),
.MASTER_RSTN         (M_RSTN         [3]),
.MASTER_WR_ADDR_ID   (M_WR_ADDR_ID   [3]),
.MASTER_WR_ADDR      (M_WR_ADDR      [3]),
.MASTER_WR_ADDR_LEN  (M_WR_ADDR_LEN  [3]),
.MASTER_WR_ADDR_BURST(M_WR_ADDR_BURST[3]),
.MASTER_WR_ADDR_VALID(M_WR_ADDR_VALID[3]),
.MASTER_WR_ADDR_READY(M_WR_ADDR_READY[3]),
.MASTER_WR_DATA      (M_WR_DATA      [3]),
.MASTER_WR_STRB      (M_WR_STRB      [3]),
.MASTER_WR_DATA_LAST (M_WR_DATA_LAST [3]),
.MASTER_WR_DATA_VALID(M_WR_DATA_VALID[3]),
.MASTER_WR_DATA_READY(M_WR_DATA_READY[3]),
.MASTER_WR_BACK_ID   (M_WR_BACK_ID   [3]),
.MASTER_WR_BACK_RESP (M_WR_BACK_RESP [3]),
.MASTER_WR_BACK_VALID(M_WR_BACK_VALID[3]),
.MASTER_WR_BACK_READY(M_WR_BACK_READY[3]),
.MASTER_RD_ADDR_ID   (M_RD_ADDR_ID   [3]),
.MASTER_RD_ADDR      (M_RD_ADDR      [3]),
.MASTER_RD_ADDR_LEN  (M_RD_ADDR_LEN  [3]),
.MASTER_RD_ADDR_BURST(M_RD_ADDR_BURST[3]),
.MASTER_RD_ADDR_VALID(M_RD_ADDR_VALID[3]),
.MASTER_RD_ADDR_READY(M_RD_ADDR_READY[3]),
.MASTER_RD_BACK_ID   (M_RD_BACK_ID   [3]),
.MASTER_RD_DATA      (M_RD_DATA      [3]),
.MASTER_RD_DATA_RESP (M_RD_DATA_RESP [3]),
.MASTER_RD_DATA_LAST (M_RD_DATA_LAST [3]),
.MASTER_RD_DATA_VALID(M_RD_DATA_VALID[3]),
.MASTER_RD_DATA_READY(M_RD_DATA_READY[3])
);

// axi_slave_sim S0(AXI_BS[0]);
// axi_slave_sim S1(AXI_BS[1]);
// axi_slave_sim S2(AXI_BS[2]);
axi_slave_sim S3(
    .SLAVE_CLK          (S_CLK          [3]),
    .SLAVE_RSTN         (S_RSTN         [3]),
    .SLAVE_WR_ADDR_ID   (S_WR_ADDR_ID   [3]),
    .SLAVE_WR_ADDR      (S_WR_ADDR      [3]),
    .SLAVE_WR_ADDR_LEN  (S_WR_ADDR_LEN  [3]),
    .SLAVE_WR_ADDR_BURST(S_WR_ADDR_BURST[3]),
    .SLAVE_WR_ADDR_VALID(S_WR_ADDR_VALID[3]),
    .SLAVE_WR_ADDR_READY(S_WR_ADDR_READY[3]),
    .SLAVE_WR_DATA      (S_WR_DATA      [3]),
    .SLAVE_WR_STRB      (S_WR_STRB      [3]),
    .SLAVE_WR_DATA_LAST (S_WR_DATA_LAST [3]),
    .SLAVE_WR_DATA_VALID(S_WR_DATA_VALID[3]),
    .SLAVE_WR_DATA_READY(S_WR_DATA_READY[3]),
    .SLAVE_WR_BACK_ID   (S_WR_BACK_ID   [3]),
    .SLAVE_WR_BACK_RESP (S_WR_BACK_RESP [3]),
    .SLAVE_WR_BACK_VALID(S_WR_BACK_VALID[3]),
    .SLAVE_WR_BACK_READY(S_WR_BACK_READY[3]),
    .SLAVE_RD_ADDR_ID   (S_RD_ADDR_ID   [3]),
    .SLAVE_RD_ADDR      (S_RD_ADDR      [3]),
    .SLAVE_RD_ADDR_LEN  (S_RD_ADDR_LEN  [3]),
    .SLAVE_RD_ADDR_BURST(S_RD_ADDR_BURST[3]),
    .SLAVE_RD_ADDR_VALID(S_RD_ADDR_VALID[3]),
    .SLAVE_RD_ADDR_READY(S_RD_ADDR_READY[3]),
    .SLAVE_RD_BACK_ID   (S_RD_BACK_ID   [3]),
    .SLAVE_RD_DATA      (S_RD_DATA      [3]),
    .SLAVE_RD_DATA_RESP (S_RD_DATA_RESP [3]),
    .SLAVE_RD_DATA_LAST (S_RD_DATA_LAST [3]),
    .SLAVE_RD_DATA_VALID(S_RD_DATA_VALID[3]),
    .SLAVE_RD_DATA_READY(S_RD_DATA_READY[3])
);
axi_slave_sim S4(
    .SLAVE_CLK          (S_CLK          [4]),
    .SLAVE_RSTN         (S_RSTN         [4]),
    .SLAVE_WR_ADDR_ID   (S_WR_ADDR_ID   [4]),
    .SLAVE_WR_ADDR      (S_WR_ADDR      [4]),
    .SLAVE_WR_ADDR_LEN  (S_WR_ADDR_LEN  [4]),
    .SLAVE_WR_ADDR_BURST(S_WR_ADDR_BURST[4]),
    .SLAVE_WR_ADDR_VALID(S_WR_ADDR_VALID[4]),
    .SLAVE_WR_ADDR_READY(S_WR_ADDR_READY[4]),
    .SLAVE_WR_DATA      (S_WR_DATA      [4]),
    .SLAVE_WR_STRB      (S_WR_STRB      [4]),
    .SLAVE_WR_DATA_LAST (S_WR_DATA_LAST [4]),
    .SLAVE_WR_DATA_VALID(S_WR_DATA_VALID[4]),
    .SLAVE_WR_DATA_READY(S_WR_DATA_READY[4]),
    .SLAVE_WR_BACK_ID   (S_WR_BACK_ID   [4]),
    .SLAVE_WR_BACK_RESP (S_WR_BACK_RESP [4]),
    .SLAVE_WR_BACK_VALID(S_WR_BACK_VALID[4]),
    .SLAVE_WR_BACK_READY(S_WR_BACK_READY[4]),
    .SLAVE_RD_ADDR_ID   (S_RD_ADDR_ID   [4]),
    .SLAVE_RD_ADDR      (S_RD_ADDR      [4]),
    .SLAVE_RD_ADDR_LEN  (S_RD_ADDR_LEN  [4]),
    .SLAVE_RD_ADDR_BURST(S_RD_ADDR_BURST[4]),
    .SLAVE_RD_ADDR_VALID(S_RD_ADDR_VALID[4]),
    .SLAVE_RD_ADDR_READY(S_RD_ADDR_READY[4]),
    .SLAVE_RD_BACK_ID   (S_RD_BACK_ID   [4]),
    .SLAVE_RD_DATA      (S_RD_DATA      [4]),
    .SLAVE_RD_DATA_RESP (S_RD_DATA_RESP [4]),
    .SLAVE_RD_DATA_LAST (S_RD_DATA_LAST [4]),
    .SLAVE_RD_DATA_VALID(S_RD_DATA_VALID[4]),
    .SLAVE_RD_DATA_READY(S_RD_DATA_READY[4])
);
axi_slave_sim S5(
    .SLAVE_CLK          (S_CLK          [5]),
    .SLAVE_RSTN         (S_RSTN         [5]),
    .SLAVE_WR_ADDR_ID   (S_WR_ADDR_ID   [5]),
    .SLAVE_WR_ADDR      (S_WR_ADDR      [5]),
    .SLAVE_WR_ADDR_LEN  (S_WR_ADDR_LEN  [5]),
    .SLAVE_WR_ADDR_BURST(S_WR_ADDR_BURST[5]),
    .SLAVE_WR_ADDR_VALID(S_WR_ADDR_VALID[5]),
    .SLAVE_WR_ADDR_READY(S_WR_ADDR_READY[5]),
    .SLAVE_WR_DATA      (S_WR_DATA      [5]),
    .SLAVE_WR_STRB      (S_WR_STRB      [5]),
    .SLAVE_WR_DATA_LAST (S_WR_DATA_LAST [5]),
    .SLAVE_WR_DATA_VALID(S_WR_DATA_VALID[5]),
    .SLAVE_WR_DATA_READY(S_WR_DATA_READY[5]),
    .SLAVE_WR_BACK_ID   (S_WR_BACK_ID   [5]),
    .SLAVE_WR_BACK_RESP (S_WR_BACK_RESP [5]),
    .SLAVE_WR_BACK_VALID(S_WR_BACK_VALID[5]),
    .SLAVE_WR_BACK_READY(S_WR_BACK_READY[5]),
    .SLAVE_RD_ADDR_ID   (S_RD_ADDR_ID   [5]),
    .SLAVE_RD_ADDR      (S_RD_ADDR      [5]),
    .SLAVE_RD_ADDR_LEN  (S_RD_ADDR_LEN  [5]),
    .SLAVE_RD_ADDR_BURST(S_RD_ADDR_BURST[5]),
    .SLAVE_RD_ADDR_VALID(S_RD_ADDR_VALID[5]),
    .SLAVE_RD_ADDR_READY(S_RD_ADDR_READY[5]),
    .SLAVE_RD_BACK_ID   (S_RD_BACK_ID   [5]),
    .SLAVE_RD_DATA      (S_RD_DATA      [5]),
    .SLAVE_RD_DATA_RESP (S_RD_DATA_RESP [5]),
    .SLAVE_RD_DATA_LAST (S_RD_DATA_LAST [5]),
    .SLAVE_RD_DATA_VALID(S_RD_DATA_VALID[5]),
    .SLAVE_RD_DATA_READY(S_RD_DATA_READY[5])
);
axi_slave_sim S6(
    .SLAVE_CLK          (S_CLK          [6]),
    .SLAVE_RSTN         (S_RSTN         [6]),
    .SLAVE_WR_ADDR_ID   (S_WR_ADDR_ID   [6]),
    .SLAVE_WR_ADDR      (S_WR_ADDR      [6]),
    .SLAVE_WR_ADDR_LEN  (S_WR_ADDR_LEN  [6]),
    .SLAVE_WR_ADDR_BURST(S_WR_ADDR_BURST[6]),
    .SLAVE_WR_ADDR_VALID(S_WR_ADDR_VALID[6]),
    .SLAVE_WR_ADDR_READY(S_WR_ADDR_READY[6]),
    .SLAVE_WR_DATA      (S_WR_DATA      [6]),
    .SLAVE_WR_STRB      (S_WR_STRB      [6]),
    .SLAVE_WR_DATA_LAST (S_WR_DATA_LAST [6]),
    .SLAVE_WR_DATA_VALID(S_WR_DATA_VALID[6]),
    .SLAVE_WR_DATA_READY(S_WR_DATA_READY[6]),
    .SLAVE_WR_BACK_ID   (S_WR_BACK_ID   [6]),
    .SLAVE_WR_BACK_RESP (S_WR_BACK_RESP [6]),
    .SLAVE_WR_BACK_VALID(S_WR_BACK_VALID[6]),
    .SLAVE_WR_BACK_READY(S_WR_BACK_READY[6]),
    .SLAVE_RD_ADDR_ID   (S_RD_ADDR_ID   [6]),
    .SLAVE_RD_ADDR      (S_RD_ADDR      [6]),
    .SLAVE_RD_ADDR_LEN  (S_RD_ADDR_LEN  [6]),
    .SLAVE_RD_ADDR_BURST(S_RD_ADDR_BURST[6]),
    .SLAVE_RD_ADDR_VALID(S_RD_ADDR_VALID[6]),
    .SLAVE_RD_ADDR_READY(S_RD_ADDR_READY[6]),
    .SLAVE_RD_BACK_ID   (S_RD_BACK_ID   [6]),
    .SLAVE_RD_DATA      (S_RD_DATA      [6]),
    .SLAVE_RD_DATA_RESP (S_RD_DATA_RESP [6]),
    .SLAVE_RD_DATA_LAST (S_RD_DATA_LAST [6]),
    .SLAVE_RD_DATA_VALID(S_RD_DATA_VALID[6]),
    .SLAVE_RD_DATA_READY(S_RD_DATA_READY[6])
);
axi_slave_sim S7(
    .SLAVE_CLK          (S_CLK          [7]),
    .SLAVE_RSTN         (S_RSTN         [7]),
    .SLAVE_WR_ADDR_ID   (S_WR_ADDR_ID   [7]),
    .SLAVE_WR_ADDR      (S_WR_ADDR      [7]),
    .SLAVE_WR_ADDR_LEN  (S_WR_ADDR_LEN  [7]),
    .SLAVE_WR_ADDR_BURST(S_WR_ADDR_BURST[7]),
    .SLAVE_WR_ADDR_VALID(S_WR_ADDR_VALID[7]),
    .SLAVE_WR_ADDR_READY(S_WR_ADDR_READY[7]),
    .SLAVE_WR_DATA      (S_WR_DATA      [7]),
    .SLAVE_WR_STRB      (S_WR_STRB      [7]),
    .SLAVE_WR_DATA_LAST (S_WR_DATA_LAST [7]),
    .SLAVE_WR_DATA_VALID(S_WR_DATA_VALID[7]),
    .SLAVE_WR_DATA_READY(S_WR_DATA_READY[7]),
    .SLAVE_WR_BACK_ID   (S_WR_BACK_ID   [7]),
    .SLAVE_WR_BACK_RESP (S_WR_BACK_RESP [7]),
    .SLAVE_WR_BACK_VALID(S_WR_BACK_VALID[7]),
    .SLAVE_WR_BACK_READY(S_WR_BACK_READY[7]),
    .SLAVE_RD_ADDR_ID   (S_RD_ADDR_ID   [7]),
    .SLAVE_RD_ADDR      (S_RD_ADDR      [7]),
    .SLAVE_RD_ADDR_LEN  (S_RD_ADDR_LEN  [7]),
    .SLAVE_RD_ADDR_BURST(S_RD_ADDR_BURST[7]),
    .SLAVE_RD_ADDR_VALID(S_RD_ADDR_VALID[7]),
    .SLAVE_RD_ADDR_READY(S_RD_ADDR_READY[7]),
    .SLAVE_RD_BACK_ID   (S_RD_BACK_ID   [7]),
    .SLAVE_RD_DATA      (S_RD_DATA      [7]),
    .SLAVE_RD_DATA_RESP (S_RD_DATA_RESP [7]),
    .SLAVE_RD_DATA_LAST (S_RD_DATA_LAST [7]),
    .SLAVE_RD_DATA_VALID(S_RD_DATA_VALID[7]),
    .SLAVE_RD_DATA_READY(S_RD_DATA_READY[7])
);

ddr3_slave_sim #(
    .OFFSET_ADDR(START_ADDR[0]))
    S0(    //DDR时钟/复位/初始化接口
    .ddr_ref_clk            (ddr_ref_clk),
    .rst_n                  (ddr_rst_n  ),
    .DDR_SLAVE_CLK          (S_CLK          [0]),
    .DDR_SLAVE_RSTN         (S_RSTN         [0]),
    .DDR_SLAVE_WR_ADDR_ID   (S_WR_ADDR_ID   [0]),
    .DDR_SLAVE_WR_ADDR      (S_WR_ADDR      [0]),
    .DDR_SLAVE_WR_ADDR_LEN  (S_WR_ADDR_LEN  [0]),
    .DDR_SLAVE_WR_ADDR_BURST(S_WR_ADDR_BURST[0]),
    .DDR_SLAVE_WR_ADDR_VALID(S_WR_ADDR_VALID[0]),
    .DDR_SLAVE_WR_ADDR_READY(S_WR_ADDR_READY[0]),
    .DDR_SLAVE_WR_DATA      (S_WR_DATA      [0]),
    .DDR_SLAVE_WR_STRB      (S_WR_STRB      [0]),
    .DDR_SLAVE_WR_DATA_LAST (S_WR_DATA_LAST [0]),
    .DDR_SLAVE_WR_DATA_VALID(S_WR_DATA_VALID[0]),
    .DDR_SLAVE_WR_DATA_READY(S_WR_DATA_READY[0]),
    .DDR_SLAVE_WR_BACK_ID   (S_WR_BACK_ID   [0]),
    .DDR_SLAVE_WR_BACK_RESP (S_WR_BACK_RESP [0]),
    .DDR_SLAVE_WR_BACK_VALID(S_WR_BACK_VALID[0]),
    .DDR_SLAVE_WR_BACK_READY(S_WR_BACK_READY[0]),
    .DDR_SLAVE_RD_ADDR_ID   (S_RD_ADDR_ID   [0]),
    .DDR_SLAVE_RD_ADDR      (S_RD_ADDR      [0]),
    .DDR_SLAVE_RD_ADDR_LEN  (S_RD_ADDR_LEN  [0]),
    .DDR_SLAVE_RD_ADDR_BURST(S_RD_ADDR_BURST[0]),
    .DDR_SLAVE_RD_ADDR_VALID(S_RD_ADDR_VALID[0]),
    .DDR_SLAVE_RD_ADDR_READY(S_RD_ADDR_READY[0]),
    .DDR_SLAVE_RD_BACK_ID   (S_RD_BACK_ID   [0]),
    .DDR_SLAVE_RD_DATA      (S_RD_DATA      [0]),
    .DDR_SLAVE_RD_DATA_RESP (S_RD_DATA_RESP [0]),
    .DDR_SLAVE_RD_DATA_LAST (S_RD_DATA_LAST [0]),
    .DDR_SLAVE_RD_DATA_VALID(S_RD_DATA_VALID[0]),
    .DDR_SLAVE_RD_DATA_READY(S_RD_DATA_READY[0])
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
    .JTAG_SLAVE_CLK          (S_CLK          [1]),
    .JTAG_SLAVE_RSTN         (S_RSTN         [1]),
    .JTAG_SLAVE_WR_ADDR_ID   (S_WR_ADDR_ID   [1]),
    .JTAG_SLAVE_WR_ADDR      (S_WR_ADDR      [1]),
    .JTAG_SLAVE_WR_ADDR_LEN  (S_WR_ADDR_LEN  [1]),
    .JTAG_SLAVE_WR_ADDR_BURST(S_WR_ADDR_BURST[1]),
    .JTAG_SLAVE_WR_ADDR_VALID(S_WR_ADDR_VALID[1]),
    .JTAG_SLAVE_WR_ADDR_READY(S_WR_ADDR_READY[1]),
    .JTAG_SLAVE_WR_DATA      (S_WR_DATA      [1]),
    .JTAG_SLAVE_WR_STRB      (S_WR_STRB      [1]),
    .JTAG_SLAVE_WR_DATA_LAST (S_WR_DATA_LAST [1]),
    .JTAG_SLAVE_WR_DATA_VALID(S_WR_DATA_VALID[1]),
    .JTAG_SLAVE_WR_DATA_READY(S_WR_DATA_READY[1]),
    .JTAG_SLAVE_WR_BACK_ID   (S_WR_BACK_ID   [1]),
    .JTAG_SLAVE_WR_BACK_RESP (S_WR_BACK_RESP [1]),
    .JTAG_SLAVE_WR_BACK_VALID(S_WR_BACK_VALID[1]),
    .JTAG_SLAVE_WR_BACK_READY(S_WR_BACK_READY[1]),
    .JTAG_SLAVE_RD_ADDR_ID   (S_RD_ADDR_ID   [1]),
    .JTAG_SLAVE_RD_ADDR      (S_RD_ADDR      [1]),
    .JTAG_SLAVE_RD_ADDR_LEN  (S_RD_ADDR_LEN  [1]),
    .JTAG_SLAVE_RD_ADDR_BURST(S_RD_ADDR_BURST[1]),
    .JTAG_SLAVE_RD_ADDR_VALID(S_RD_ADDR_VALID[1]),
    .JTAG_SLAVE_RD_ADDR_READY(S_RD_ADDR_READY[1]),
    .JTAG_SLAVE_RD_BACK_ID   (S_RD_BACK_ID   [1]),
    .JTAG_SLAVE_RD_DATA      (S_RD_DATA      [1]),
    .JTAG_SLAVE_RD_DATA_RESP (S_RD_DATA_RESP [1]),
    .JTAG_SLAVE_RD_DATA_LAST (S_RD_DATA_LAST [1]),
    .JTAG_SLAVE_RD_DATA_VALID(S_RD_DATA_VALID[1]),
    .JTAG_SLAVE_RD_DATA_READY(S_RD_DATA_READY[1])
);

dds_slave #(
	.CHANNEL_NUM 	(2             ),
	.OFFSER_ADDR 	(START_ADDR[2]))
    S2(
	.clk            ( dds_clk      ),
	.rstn           ( dds_rstn     ),
	.wave_out       ( {dds_wave1,dds_wave0} ),
    .DDS_SLAVE_CLK          (S_CLK          [2]),
    .DDS_SLAVE_RSTN         (S_RSTN         [2]),
    .DDS_SLAVE_WR_ADDR_ID   (S_WR_ADDR_ID   [2]),
    .DDS_SLAVE_WR_ADDR      (S_WR_ADDR      [2]),
    .DDS_SLAVE_WR_ADDR_LEN  (S_WR_ADDR_LEN  [2]),
    .DDS_SLAVE_WR_ADDR_BURST(S_WR_ADDR_BURST[2]),
    .DDS_SLAVE_WR_ADDR_VALID(S_WR_ADDR_VALID[2]),
    .DDS_SLAVE_WR_ADDR_READY(S_WR_ADDR_READY[2]),
    .DDS_SLAVE_WR_DATA      (S_WR_DATA      [2]),
    .DDS_SLAVE_WR_STRB      (S_WR_STRB      [2]),
    .DDS_SLAVE_WR_DATA_LAST (S_WR_DATA_LAST [2]),
    .DDS_SLAVE_WR_DATA_VALID(S_WR_DATA_VALID[2]),
    .DDS_SLAVE_WR_DATA_READY(S_WR_DATA_READY[2]),
    .DDS_SLAVE_WR_BACK_ID   (S_WR_BACK_ID   [2]),
    .DDS_SLAVE_WR_BACK_RESP (S_WR_BACK_RESP [2]),
    .DDS_SLAVE_WR_BACK_VALID(S_WR_BACK_VALID[2]),
    .DDS_SLAVE_WR_BACK_READY(S_WR_BACK_READY[2]),
    .DDS_SLAVE_RD_ADDR_ID   (S_RD_ADDR_ID   [2]),
    .DDS_SLAVE_RD_ADDR      (S_RD_ADDR      [2]),
    .DDS_SLAVE_RD_ADDR_LEN  (S_RD_ADDR_LEN  [2]),
    .DDS_SLAVE_RD_ADDR_BURST(S_RD_ADDR_BURST[2]),
    .DDS_SLAVE_RD_ADDR_VALID(S_RD_ADDR_VALID[2]),
    .DDS_SLAVE_RD_ADDR_READY(S_RD_ADDR_READY[2]),
    .DDS_SLAVE_RD_BACK_ID   (S_RD_BACK_ID   [2]),
    .DDS_SLAVE_RD_DATA      (S_RD_DATA      [2]),
    .DDS_SLAVE_RD_DATA_RESP (S_RD_DATA_RESP [2]),
    .DDS_SLAVE_RD_DATA_LAST (S_RD_DATA_LAST [2]),
    .DDS_SLAVE_RD_DATA_VALID(S_RD_DATA_VALID[2]),
    .DDS_SLAVE_RD_DATA_READY(S_RD_DATA_READY[2])
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
    .MASTER_CLK          (M_CLK          ),
    .MASTER_RSTN         (M_RSTN         ),
    .MASTER_WR_ADDR_ID   (M_WR_ADDR_ID   ),
    .MASTER_WR_ADDR      (M_WR_ADDR      ),
    .MASTER_WR_ADDR_LEN  (M_WR_ADDR_LEN  ),
    .MASTER_WR_ADDR_BURST(M_WR_ADDR_BURST),
    .MASTER_WR_ADDR_VALID(M_WR_ADDR_VALID),
    .MASTER_WR_ADDR_READY(M_WR_ADDR_READY),
    .MASTER_WR_DATA      (M_WR_DATA      ),
    .MASTER_WR_STRB      (M_WR_STRB      ),
    .MASTER_WR_DATA_LAST (M_WR_DATA_LAST ),
    .MASTER_WR_DATA_VALID(M_WR_DATA_VALID),
    .MASTER_WR_DATA_READY(M_WR_DATA_READY),
    .MASTER_WR_BACK_ID   (M_WR_BACK_ID   ),
    .MASTER_WR_BACK_RESP (M_WR_BACK_RESP ),
    .MASTER_WR_BACK_VALID(M_WR_BACK_VALID),
    .MASTER_WR_BACK_READY(M_WR_BACK_READY),
    .MASTER_RD_ADDR_ID   (M_RD_ADDR_ID   ),
    .MASTER_RD_ADDR      (M_RD_ADDR      ),
    .MASTER_RD_ADDR_LEN  (M_RD_ADDR_LEN  ),
    .MASTER_RD_ADDR_BURST(M_RD_ADDR_BURST),
    .MASTER_RD_ADDR_VALID(M_RD_ADDR_VALID),
    .MASTER_RD_ADDR_READY(M_RD_ADDR_READY),
    .MASTER_RD_BACK_ID   (M_RD_BACK_ID   ),
    .MASTER_RD_DATA      (M_RD_DATA      ),
    .MASTER_RD_DATA_RESP (M_RD_DATA_RESP ),
    .MASTER_RD_DATA_LAST (M_RD_DATA_LAST ),
    .MASTER_RD_DATA_VALID(M_RD_DATA_VALID),
    .MASTER_RD_DATA_READY(M_RD_DATA_READY),
    .SLAVE_CLK          (S_CLK          ),
    .SLAVE_RSTN         (S_RSTN         ),
    .SLAVE_WR_ADDR_ID   (S_WR_ADDR_ID   ),
    .SLAVE_WR_ADDR      (S_WR_ADDR      ),
    .SLAVE_WR_ADDR_LEN  (S_WR_ADDR_LEN  ),
    .SLAVE_WR_ADDR_BURST(S_WR_ADDR_BURST),
    .SLAVE_WR_ADDR_VALID(S_WR_ADDR_VALID),
    .SLAVE_WR_ADDR_READY(S_WR_ADDR_READY),
    .SLAVE_WR_DATA      (S_WR_DATA      ),
    .SLAVE_WR_STRB      (S_WR_STRB      ),
    .SLAVE_WR_DATA_LAST (S_WR_DATA_LAST ),
    .SLAVE_WR_DATA_VALID(S_WR_DATA_VALID),
    .SLAVE_WR_DATA_READY(S_WR_DATA_READY),
    .SLAVE_WR_BACK_ID   (S_WR_BACK_ID   ),
    .SLAVE_WR_BACK_RESP (S_WR_BACK_RESP ),
    .SLAVE_WR_BACK_VALID(S_WR_BACK_VALID),
    .SLAVE_WR_BACK_READY(S_WR_BACK_READY),
    .SLAVE_RD_ADDR_ID   (S_RD_ADDR_ID   ),
    .SLAVE_RD_ADDR      (S_RD_ADDR      ),
    .SLAVE_RD_ADDR_LEN  (S_RD_ADDR_LEN  ),
    .SLAVE_RD_ADDR_BURST(S_RD_ADDR_BURST),
    .SLAVE_RD_ADDR_VALID(S_RD_ADDR_VALID),
    .SLAVE_RD_ADDR_READY(S_RD_ADDR_READY),
    .SLAVE_RD_BACK_ID   (S_RD_BACK_ID   ),
    .SLAVE_RD_DATA      (S_RD_DATA      ),
    .SLAVE_RD_DATA_RESP (S_RD_DATA_RESP ),
    .SLAVE_RD_DATA_LAST (S_RD_DATA_LAST ),
    .SLAVE_RD_DATA_VALID(S_RD_DATA_VALID),
    .SLAVE_RD_DATA_READY(S_RD_DATA_READY),
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