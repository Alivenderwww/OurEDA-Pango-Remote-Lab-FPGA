`timescale 1ns/1ps
`include "ddr3_parameters.vh"
`include "JTAG_CMD.vh"
module axi_bus_ddr_jtag_test ();
//DDR，JTAG和AXI-MASTER-SIM，AXI_SLAVE_SIM，AXI-BUS，AXI-INTERCONNECT，AXI_CLOCK_CONVERTER模块的配合

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

reg  jtag_clk ;
reg  jtag_rst_n;
wire tck      ;
wire tdi      ;
wire tms      ;
wire tdo      ;

reg          ddr_ref_clk  ;
reg          ddr_rst_n    ;
wire         ddr_init_done;

reg led_clk;
reg led_rst_n;
wire [31:0] led;

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

reg BUS_CLK;
reg BUS_RSTN;
reg M0_CLK;reg S0_CLK;reg M0_RSTN;reg S0_RSTN;
reg M1_CLK;reg S1_CLK;reg M1_RSTN;reg S1_RSTN;
reg M2_CLK;reg S2_CLK;reg M2_RSTN;reg S2_RSTN;
reg M3_CLK;reg S3_CLK;reg M3_RSTN;reg S3_RSTN;
wire [ 1:0] M0_WR_ADDR_ID   ;wire [ 1:0] M1_WR_ADDR_ID   ;wire [ 1:0] M2_WR_ADDR_ID   ;wire [ 1:0] M3_WR_ADDR_ID   ;
wire [31:0] M0_WR_ADDR      ;wire [31:0] M1_WR_ADDR      ;wire [31:0] M2_WR_ADDR      ;wire [31:0] M3_WR_ADDR      ;
wire [ 7:0] M0_WR_ADDR_LEN  ;wire [ 7:0] M1_WR_ADDR_LEN  ;wire [ 7:0] M2_WR_ADDR_LEN  ;wire [ 7:0] M3_WR_ADDR_LEN  ;
wire [ 1:0] M0_WR_ADDR_BURST;wire [ 1:0] M1_WR_ADDR_BURST;wire [ 1:0] M2_WR_ADDR_BURST;wire [ 1:0] M3_WR_ADDR_BURST;
wire        M0_WR_ADDR_VALID;wire        M1_WR_ADDR_VALID;wire        M2_WR_ADDR_VALID;wire        M3_WR_ADDR_VALID;
wire        M0_WR_ADDR_READY;wire        M1_WR_ADDR_READY;wire        M2_WR_ADDR_READY;wire        M3_WR_ADDR_READY;
wire [31:0] M0_WR_DATA      ;wire [31:0] M1_WR_DATA      ;wire [31:0] M2_WR_DATA      ;wire [31:0] M3_WR_DATA      ;
wire [ 3:0] M0_WR_STRB      ;wire [ 3:0] M1_WR_STRB      ;wire [ 3:0] M2_WR_STRB      ;wire [ 3:0] M3_WR_STRB      ;
wire        M0_WR_DATA_LAST ;wire        M1_WR_DATA_LAST ;wire        M2_WR_DATA_LAST ;wire        M3_WR_DATA_LAST ;
wire        M0_WR_DATA_VALID;wire        M1_WR_DATA_VALID;wire        M2_WR_DATA_VALID;wire        M3_WR_DATA_VALID;
wire        M0_WR_DATA_READY;wire        M1_WR_DATA_READY;wire        M2_WR_DATA_READY;wire        M3_WR_DATA_READY;
wire [ 1:0] M0_WR_BACK_ID   ;wire [ 1:0] M1_WR_BACK_ID   ;wire [ 1:0] M2_WR_BACK_ID   ;wire [ 1:0] M3_WR_BACK_ID   ;
wire [ 1:0] M0_WR_BACK_RESP ;wire [ 1:0] M1_WR_BACK_RESP ;wire [ 1:0] M2_WR_BACK_RESP ;wire [ 1:0] M3_WR_BACK_RESP ;
wire        M0_WR_BACK_VALID;wire        M1_WR_BACK_VALID;wire        M2_WR_BACK_VALID;wire        M3_WR_BACK_VALID;
wire        M0_WR_BACK_READY;wire        M1_WR_BACK_READY;wire        M2_WR_BACK_READY;wire        M3_WR_BACK_READY;
wire [ 1:0] M0_RD_ADDR_ID   ;wire [ 1:0] M1_RD_ADDR_ID   ;wire [ 1:0] M2_RD_ADDR_ID   ;wire [ 1:0] M3_RD_ADDR_ID   ;
wire [31:0] M0_RD_ADDR      ;wire [31:0] M1_RD_ADDR      ;wire [31:0] M2_RD_ADDR      ;wire [31:0] M3_RD_ADDR      ;
wire [ 7:0] M0_RD_ADDR_LEN  ;wire [ 7:0] M1_RD_ADDR_LEN  ;wire [ 7:0] M2_RD_ADDR_LEN  ;wire [ 7:0] M3_RD_ADDR_LEN  ;
wire [ 1:0] M0_RD_ADDR_BURST;wire [ 1:0] M1_RD_ADDR_BURST;wire [ 1:0] M2_RD_ADDR_BURST;wire [ 1:0] M3_RD_ADDR_BURST;
wire        M0_RD_ADDR_VALID;wire        M1_RD_ADDR_VALID;wire        M2_RD_ADDR_VALID;wire        M3_RD_ADDR_VALID;
wire        M0_RD_ADDR_READY;wire        M1_RD_ADDR_READY;wire        M2_RD_ADDR_READY;wire        M3_RD_ADDR_READY;
wire [ 1:0] M0_RD_BACK_ID   ;wire [ 1:0] M1_RD_BACK_ID   ;wire [ 1:0] M2_RD_BACK_ID   ;wire [ 1:0] M3_RD_BACK_ID   ;
wire [31:0] M0_RD_DATA      ;wire [31:0] M1_RD_DATA      ;wire [31:0] M2_RD_DATA      ;wire [31:0] M3_RD_DATA      ;
wire [ 1:0] M0_RD_DATA_RESP ;wire [ 1:0] M1_RD_DATA_RESP ;wire [ 1:0] M2_RD_DATA_RESP ;wire [ 1:0] M3_RD_DATA_RESP ;
wire        M0_RD_DATA_LAST ;wire        M1_RD_DATA_LAST ;wire        M2_RD_DATA_LAST ;wire        M3_RD_DATA_LAST ;
wire        M0_RD_DATA_VALID;wire        M1_RD_DATA_VALID;wire        M2_RD_DATA_VALID;wire        M3_RD_DATA_VALID;
wire        M0_RD_DATA_READY;wire        M1_RD_DATA_READY;wire        M2_RD_DATA_READY;wire        M3_RD_DATA_READY;
wire [ 3:0] S0_WR_ADDR_ID   ;wire [ 3:0] S1_WR_ADDR_ID   ;wire [ 3:0] S2_WR_ADDR_ID   ;wire [ 3:0] S3_WR_ADDR_ID   ;
wire [31:0] S0_WR_ADDR      ;wire [31:0] S1_WR_ADDR      ;wire [31:0] S2_WR_ADDR      ;wire [31:0] S3_WR_ADDR      ;
wire [ 7:0] S0_WR_ADDR_LEN  ;wire [ 7:0] S1_WR_ADDR_LEN  ;wire [ 7:0] S2_WR_ADDR_LEN  ;wire [ 7:0] S3_WR_ADDR_LEN  ;
wire [ 1:0] S0_WR_ADDR_BURST;wire [ 1:0] S1_WR_ADDR_BURST;wire [ 1:0] S2_WR_ADDR_BURST;wire [ 1:0] S3_WR_ADDR_BURST;
wire        S0_WR_ADDR_VALID;wire        S1_WR_ADDR_VALID;wire        S2_WR_ADDR_VALID;wire        S3_WR_ADDR_VALID;
wire        S0_WR_ADDR_READY;wire        S1_WR_ADDR_READY;wire        S2_WR_ADDR_READY;wire        S3_WR_ADDR_READY;
wire [31:0] S0_WR_DATA      ;wire [31:0] S1_WR_DATA      ;wire [31:0] S2_WR_DATA      ;wire [31:0] S3_WR_DATA      ;
wire [ 3:0] S0_WR_STRB      ;wire [ 3:0] S1_WR_STRB      ;wire [ 3:0] S2_WR_STRB      ;wire [ 3:0] S3_WR_STRB      ;
wire        S0_WR_DATA_LAST ;wire        S1_WR_DATA_LAST ;wire        S2_WR_DATA_LAST ;wire        S3_WR_DATA_LAST ;
wire        S0_WR_DATA_VALID;wire        S1_WR_DATA_VALID;wire        S2_WR_DATA_VALID;wire        S3_WR_DATA_VALID;
wire        S0_WR_DATA_READY;wire        S1_WR_DATA_READY;wire        S2_WR_DATA_READY;wire        S3_WR_DATA_READY;
wire [ 3:0] S0_WR_BACK_ID   ;wire [ 3:0] S1_WR_BACK_ID   ;wire [ 3:0] S2_WR_BACK_ID   ;wire [ 3:0] S3_WR_BACK_ID   ;
wire [ 1:0] S0_WR_BACK_RESP ;wire [ 1:0] S1_WR_BACK_RESP ;wire [ 1:0] S2_WR_BACK_RESP ;wire [ 1:0] S3_WR_BACK_RESP ;
wire        S0_WR_BACK_VALID;wire        S1_WR_BACK_VALID;wire        S2_WR_BACK_VALID;wire        S3_WR_BACK_VALID;
wire        S0_WR_BACK_READY;wire        S1_WR_BACK_READY;wire        S2_WR_BACK_READY;wire        S3_WR_BACK_READY;
wire [ 3:0] S0_RD_ADDR_ID   ;wire [ 3:0] S1_RD_ADDR_ID   ;wire [ 3:0] S2_RD_ADDR_ID   ;wire [ 3:0] S3_RD_ADDR_ID   ;
wire [31:0] S0_RD_ADDR      ;wire [31:0] S1_RD_ADDR      ;wire [31:0] S2_RD_ADDR      ;wire [31:0] S3_RD_ADDR      ;
wire [ 7:0] S0_RD_ADDR_LEN  ;wire [ 7:0] S1_RD_ADDR_LEN  ;wire [ 7:0] S2_RD_ADDR_LEN  ;wire [ 7:0] S3_RD_ADDR_LEN  ;
wire [ 1:0] S0_RD_ADDR_BURST;wire [ 1:0] S1_RD_ADDR_BURST;wire [ 1:0] S2_RD_ADDR_BURST;wire [ 1:0] S3_RD_ADDR_BURST;
wire        S0_RD_ADDR_VALID;wire        S1_RD_ADDR_VALID;wire        S2_RD_ADDR_VALID;wire        S3_RD_ADDR_VALID;
wire        S0_RD_ADDR_READY;wire        S1_RD_ADDR_READY;wire        S2_RD_ADDR_READY;wire        S3_RD_ADDR_READY;
wire [ 3:0] S0_RD_BACK_ID   ;wire [ 3:0] S1_RD_BACK_ID   ;wire [ 3:0] S2_RD_BACK_ID   ;wire [ 3:0] S3_RD_BACK_ID   ;
wire [31:0] S0_RD_DATA      ;wire [31:0] S1_RD_DATA      ;wire [31:0] S2_RD_DATA      ;wire [31:0] S3_RD_DATA      ;
wire [ 1:0] S0_RD_DATA_RESP ;wire [ 1:0] S1_RD_DATA_RESP ;wire [ 1:0] S2_RD_DATA_RESP ;wire [ 1:0] S3_RD_DATA_RESP ;
wire        S0_RD_DATA_LAST ;wire        S1_RD_DATA_LAST ;wire        S2_RD_DATA_LAST ;wire        S3_RD_DATA_LAST ;
wire        S0_RD_DATA_VALID;wire        S1_RD_DATA_VALID;wire        S2_RD_DATA_VALID;wire        S3_RD_DATA_VALID;
wire        S0_RD_DATA_READY;wire        S1_RD_DATA_READY;wire        S2_RD_DATA_READY;wire        S3_RD_DATA_READY;


parameter S0_START_ADDR = 32'h00_00_00_00,
          S0_END_ADDR   = 32'h0F_FF_FF_FF,
          S1_START_ADDR = 32'h10_00_00_00,
          S1_END_ADDR   = 32'h1F_FF_FF_0F,
          S2_START_ADDR = 32'h20_00_00_00,
          S2_END_ADDR   = 32'h2F_FF_FF_0F,
          S3_START_ADDR = 32'h30_00_00_00,
          S3_END_ADDR   = 32'h3F_FF_FF_0F;

always #10 ddr_ref_clk = ~ddr_ref_clk;
always #7  jtag_clk = ~jtag_clk;
always #30 led_clk = ~led_clk;

always #8  BUS_CLK = ~BUS_CLK; //speed:2
always #7    M0_CLK = ~M0_CLK; //speed:1
always #9    M1_CLK = ~M1_CLK; //speed:3
always #11   M2_CLK = ~M2_CLK; //speed:5
always #13   M3_CLK = ~M3_CLK; //speed:7
// always #6    S0_CLK = ~S0_CLK; //speed:0(FAST)
// always #8    S1_CLK = ~S1_CLK; //speed:2
// always #12   S2_CLK = ~S2_CLK; //speed:6
always #14   S3_CLK = ~S3_CLK; //speed:8(SLOW)

initial begin
    ddr_ref_clk = 0;
    ddr_rst_n = 0;
    #300000 ddr_rst_n = 1;
end

initial begin
    jtag_clk = 0;
    jtag_rst_n = 0;
    #500 jtag_rst_n = 1;
end

initial begin
    led_clk = 0;
    led_rst_n = 0;
    #500 led_rst_n = 1;
end
assign tdo = 0;

initial begin
    BUS_CLK = 0; BUS_RSTN = 0;
    M0_CLK  = 0; M0_RSTN  = 0;
    M1_CLK  = 0; M1_RSTN  = 0;
    M2_CLK  = 0; M2_RSTN  = 0;
    M3_CLK  = 0; M3_RSTN  = 0;
    // S0_CLK  = 0; S0_RSTN  = 0;
    // S1_CLK  = 0; S1_RSTN  = 0;
    // S2_CLK  = 0; S2_RSTN  = 0;
    S3_CLK  = 0; S3_RSTN  = 0;
#50000
    M0_RSTN = 1;  // S0_RSTN = 1;
    M1_RSTN = 1;  // S1_RSTN = 1;
    M2_RSTN = 1;  // S2_RSTN = 1;
    M3_RSTN = 1;  S3_RSTN = 1;
#5000
    BUS_RSTN = 1;
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
    #5000
    #300 M0.set_rd_data_channel(7);
    #300 M0.set_wr_data_channel(7);
    //IDCODE是器件标识符，同一种芯片的IDCODE相同。
    //JTAG读取IDCODE的流程：
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

    #300 M0.send_wr_addr(2'b00, 32'h20000000, 8'd000, 2'b00);
    #300 M0.send_wr_data(32'h10101010, 4'b1111);
    #300 M0.send_wr_addr(2'b01, 32'h20000010, 8'd000, 2'b00);
    #300 M0.send_wr_data(32'h10101010, 4'b1111);
    #300 M0.send_wr_addr(2'b10, 32'h20000000, 8'd003, 2'b00);
    #300 M0.send_wr_data(32'h10101010, 4'b1111);
    #300 M0.send_wr_addr(2'b11, 32'h20000000, 8'd000, 2'b10);
    #300 M0.send_wr_data(32'h10101010, 4'b1111);
    #300 M0.send_rd_addr(2'b01, 32'h20000000, 8'd000, 2'b00);

    while (~ddr_init_done) #1000;
    #300 M0.send_wr_addr(2'b00, 32'h00000000, 8'd255, 2'b01);
    #300 M0.send_wr_addr(2'b01, 32'h00010000, 8'd255, 2'b01);
    #300 M0.send_wr_data(32'h00000000, 4'b1111);
    #300 M0.send_wr_data(32'h10000000, 4'b1111);

    #300 M0.send_rd_addr(2'b00, 32'h00000000, 8'd255, 2'b01);
    #300 M0.send_rd_addr(2'b00, 32'h00010000, 8'd255, 2'b01);
    $display("here!");
    #300 M0.send_rd_addr(2'b00, 32'h000000F0, 8'h10, 2'b01);
end

axi_master_sim M0(
    .clk                  (M0_CLK           ),
    .rstn                 (M0_RSTN          ),
    .MASTER_CLK           (                 ),
    .MASTER_RSTN          (                 ),
    .MASTER_WR_ADDR_ID    (M0_WR_ADDR_ID    ),
    .MASTER_WR_ADDR       (M0_WR_ADDR       ),
    .MASTER_WR_ADDR_LEN   (M0_WR_ADDR_LEN   ),
    .MASTER_WR_ADDR_BURST (M0_WR_ADDR_BURST ),
    .MASTER_WR_ADDR_VALID (M0_WR_ADDR_VALID ),
    .MASTER_WR_ADDR_READY (M0_WR_ADDR_READY ),
    .MASTER_WR_DATA       (M0_WR_DATA       ),
    .MASTER_WR_STRB       (M0_WR_STRB       ),
    .MASTER_WR_DATA_LAST  (M0_WR_DATA_LAST  ),
    .MASTER_WR_DATA_VALID (M0_WR_DATA_VALID ),
    .MASTER_WR_DATA_READY (M0_WR_DATA_READY ),
    .MASTER_WR_BACK_ID    (M0_WR_BACK_ID    ),
    .MASTER_WR_BACK_RESP  (M0_WR_BACK_RESP  ),
    .MASTER_WR_BACK_VALID (M0_WR_BACK_VALID ),
    .MASTER_WR_BACK_READY (M0_WR_BACK_READY ),
    .MASTER_RD_ADDR_ID    (M0_RD_ADDR_ID    ),
    .MASTER_RD_ADDR       (M0_RD_ADDR       ),
    .MASTER_RD_ADDR_LEN   (M0_RD_ADDR_LEN   ),
    .MASTER_RD_ADDR_BURST (M0_RD_ADDR_BURST ),
    .MASTER_RD_ADDR_VALID (M0_RD_ADDR_VALID ),
    .MASTER_RD_ADDR_READY (M0_RD_ADDR_READY ),
    .MASTER_RD_BACK_ID    (M0_RD_BACK_ID    ),
    .MASTER_RD_DATA       (M0_RD_DATA       ),
    .MASTER_RD_DATA_RESP  (M0_RD_DATA_RESP  ),
    .MASTER_RD_DATA_LAST  (M0_RD_DATA_LAST  ),
    .MASTER_RD_DATA_VALID (M0_RD_DATA_VALID ),
    .MASTER_RD_DATA_READY (M0_RD_DATA_READY )
);

axi_master_default M1(
    .clk                  (M1_CLK           ),
    .rstn                 (M1_RSTN          ),
    .MASTER_CLK           (                 ),
    .MASTER_RSTN          (                 ),
    .MASTER_WR_ADDR_ID    (M1_WR_ADDR_ID    ),
    .MASTER_WR_ADDR       (M1_WR_ADDR       ),
    .MASTER_WR_ADDR_LEN   (M1_WR_ADDR_LEN   ),
    .MASTER_WR_ADDR_BURST (M1_WR_ADDR_BURST ),
    .MASTER_WR_ADDR_VALID (M1_WR_ADDR_VALID ),
    .MASTER_WR_ADDR_READY (M1_WR_ADDR_READY ),
    .MASTER_WR_DATA       (M1_WR_DATA       ),
    .MASTER_WR_STRB       (M1_WR_STRB       ),
    .MASTER_WR_DATA_LAST  (M1_WR_DATA_LAST  ),
    .MASTER_WR_DATA_VALID (M1_WR_DATA_VALID ),
    .MASTER_WR_DATA_READY (M1_WR_DATA_READY ),
    .MASTER_WR_BACK_ID    (M1_WR_BACK_ID    ),
    .MASTER_WR_BACK_RESP  (M1_WR_BACK_RESP  ),
    .MASTER_WR_BACK_VALID (M1_WR_BACK_VALID ),
    .MASTER_WR_BACK_READY (M1_WR_BACK_READY ),
    .MASTER_RD_ADDR_ID    (M1_RD_ADDR_ID    ),
    .MASTER_RD_ADDR       (M1_RD_ADDR       ),
    .MASTER_RD_ADDR_LEN   (M1_RD_ADDR_LEN   ),
    .MASTER_RD_ADDR_BURST (M1_RD_ADDR_BURST ),
    .MASTER_RD_ADDR_VALID (M1_RD_ADDR_VALID ),
    .MASTER_RD_ADDR_READY (M1_RD_ADDR_READY ),
    .MASTER_RD_BACK_ID    (M1_RD_BACK_ID    ),
    .MASTER_RD_DATA       (M1_RD_DATA       ),
    .MASTER_RD_DATA_RESP  (M1_RD_DATA_RESP  ),
    .MASTER_RD_DATA_LAST  (M1_RD_DATA_LAST  ),
    .MASTER_RD_DATA_VALID (M1_RD_DATA_VALID ),
    .MASTER_RD_DATA_READY (M1_RD_DATA_READY )
);

axi_master_default M2(
    .clk                  (M2_CLK           ),
    .rstn                 (M2_RSTN          ),
    .MASTER_CLK           (                 ),
    .MASTER_RSTN          (                 ),
    .MASTER_WR_ADDR_ID    (M2_WR_ADDR_ID    ),
    .MASTER_WR_ADDR       (M2_WR_ADDR       ),
    .MASTER_WR_ADDR_LEN   (M2_WR_ADDR_LEN   ),
    .MASTER_WR_ADDR_BURST (M2_WR_ADDR_BURST ),
    .MASTER_WR_ADDR_VALID (M2_WR_ADDR_VALID ),
    .MASTER_WR_ADDR_READY (M2_WR_ADDR_READY ),
    .MASTER_WR_DATA       (M2_WR_DATA       ),
    .MASTER_WR_STRB       (M2_WR_STRB       ),
    .MASTER_WR_DATA_LAST  (M2_WR_DATA_LAST  ),
    .MASTER_WR_DATA_VALID (M2_WR_DATA_VALID ),
    .MASTER_WR_DATA_READY (M2_WR_DATA_READY ),
    .MASTER_WR_BACK_ID    (M2_WR_BACK_ID    ),
    .MASTER_WR_BACK_RESP  (M2_WR_BACK_RESP  ),
    .MASTER_WR_BACK_VALID (M2_WR_BACK_VALID ),
    .MASTER_WR_BACK_READY (M2_WR_BACK_READY ),
    .MASTER_RD_ADDR_ID    (M2_RD_ADDR_ID    ),
    .MASTER_RD_ADDR       (M2_RD_ADDR       ),
    .MASTER_RD_ADDR_LEN   (M2_RD_ADDR_LEN   ),
    .MASTER_RD_ADDR_BURST (M2_RD_ADDR_BURST ),
    .MASTER_RD_ADDR_VALID (M2_RD_ADDR_VALID ),
    .MASTER_RD_ADDR_READY (M2_RD_ADDR_READY ),
    .MASTER_RD_BACK_ID    (M2_RD_BACK_ID    ),
    .MASTER_RD_DATA       (M2_RD_DATA       ),
    .MASTER_RD_DATA_RESP  (M2_RD_DATA_RESP  ),
    .MASTER_RD_DATA_LAST  (M2_RD_DATA_LAST  ),
    .MASTER_RD_DATA_VALID (M2_RD_DATA_VALID ),
    .MASTER_RD_DATA_READY (M2_RD_DATA_READY )
);

axi_master_default M3(
    .clk                  (M3_CLK           ),
    .rstn                 (M3_RSTN          ),
    .MASTER_CLK           (                 ),
    .MASTER_RSTN          (                 ),
    .MASTER_WR_ADDR_ID    (M3_WR_ADDR_ID    ),
    .MASTER_WR_ADDR       (M3_WR_ADDR       ),
    .MASTER_WR_ADDR_LEN   (M3_WR_ADDR_LEN   ),
    .MASTER_WR_ADDR_BURST (M3_WR_ADDR_BURST ),
    .MASTER_WR_ADDR_VALID (M3_WR_ADDR_VALID ),
    .MASTER_WR_ADDR_READY (M3_WR_ADDR_READY ),
    .MASTER_WR_DATA       (M3_WR_DATA       ),
    .MASTER_WR_STRB       (M3_WR_STRB       ),
    .MASTER_WR_DATA_LAST  (M3_WR_DATA_LAST  ),
    .MASTER_WR_DATA_VALID (M3_WR_DATA_VALID ),
    .MASTER_WR_DATA_READY (M3_WR_DATA_READY ),
    .MASTER_WR_BACK_ID    (M3_WR_BACK_ID    ),
    .MASTER_WR_BACK_RESP  (M3_WR_BACK_RESP  ),
    .MASTER_WR_BACK_VALID (M3_WR_BACK_VALID ),
    .MASTER_WR_BACK_READY (M3_WR_BACK_READY ),
    .MASTER_RD_ADDR_ID    (M3_RD_ADDR_ID    ),
    .MASTER_RD_ADDR       (M3_RD_ADDR       ),
    .MASTER_RD_ADDR_LEN   (M3_RD_ADDR_LEN   ),
    .MASTER_RD_ADDR_BURST (M3_RD_ADDR_BURST ),
    .MASTER_RD_ADDR_VALID (M3_RD_ADDR_VALID ),
    .MASTER_RD_ADDR_READY (M3_RD_ADDR_READY ),
    .MASTER_RD_BACK_ID    (M3_RD_BACK_ID    ),
    .MASTER_RD_DATA       (M3_RD_DATA       ),
    .MASTER_RD_DATA_RESP  (M3_RD_DATA_RESP  ),
    .MASTER_RD_DATA_LAST  (M3_RD_DATA_LAST  ),
    .MASTER_RD_DATA_VALID (M3_RD_DATA_VALID ),
    .MASTER_RD_DATA_READY (M3_RD_DATA_READY )
);

slave_ddr3 #(
    .OFFSET_ADDR             (S0_START_ADDR)
)S0(
    .ddr_ref_clk             (ddr_ref_clk      ),
    .rst_n                   (ddr_rst_n        ),
    .ddr_init_done           (ddr_init_done    ),
    .DDR_SLAVE_CLK           (S0_CLK           ),
    .DDR_SLAVE_RSTN          (S0_RSTN          ),
    .DDR_SLAVE_WR_ADDR_ID    (S0_WR_ADDR_ID    ),
    .DDR_SLAVE_WR_ADDR       (S0_WR_ADDR       ),
    .DDR_SLAVE_WR_ADDR_LEN   (S0_WR_ADDR_LEN   ),
    .DDR_SLAVE_WR_ADDR_BURST (S0_WR_ADDR_BURST ),
    .DDR_SLAVE_WR_ADDR_VALID (S0_WR_ADDR_VALID ),
    .DDR_SLAVE_WR_ADDR_READY (S0_WR_ADDR_READY ),
    .DDR_SLAVE_WR_DATA       (S0_WR_DATA       ),
    .DDR_SLAVE_WR_STRB       (S0_WR_STRB       ),
    .DDR_SLAVE_WR_DATA_LAST  (S0_WR_DATA_LAST  ),
    .DDR_SLAVE_WR_DATA_VALID (S0_WR_DATA_VALID ),
    .DDR_SLAVE_WR_DATA_READY (S0_WR_DATA_READY ),
    .DDR_SLAVE_WR_BACK_ID    (S0_WR_BACK_ID    ),
    .DDR_SLAVE_WR_BACK_RESP  (S0_WR_BACK_RESP  ),
    .DDR_SLAVE_WR_BACK_VALID (S0_WR_BACK_VALID ),
    .DDR_SLAVE_WR_BACK_READY (S0_WR_BACK_READY ),
    .DDR_SLAVE_RD_ADDR_ID    (S0_RD_ADDR_ID    ),
    .DDR_SLAVE_RD_ADDR       (S0_RD_ADDR       ),
    .DDR_SLAVE_RD_ADDR_LEN   (S0_RD_ADDR_LEN   ),
    .DDR_SLAVE_RD_ADDR_BURST (S0_RD_ADDR_BURST ),
    .DDR_SLAVE_RD_ADDR_VALID (S0_RD_ADDR_VALID ),
    .DDR_SLAVE_RD_ADDR_READY (S0_RD_ADDR_READY ),
    .DDR_SLAVE_RD_BACK_ID    (S0_RD_BACK_ID    ),
    .DDR_SLAVE_RD_DATA       (S0_RD_DATA       ),
    .DDR_SLAVE_RD_DATA_RESP  (S0_RD_DATA_RESP  ),
    .DDR_SLAVE_RD_DATA_LAST  (S0_RD_DATA_LAST  ),
    .DDR_SLAVE_RD_DATA_VALID (S0_RD_DATA_VALID ),
    .DDR_SLAVE_RD_DATA_READY (S0_RD_DATA_READY ),
    .mem_rst_n               (mem_rst_n               ),
    .mem_ck                  (mem_ck                  ),
    .mem_ck_n                (mem_ck_n                ),
    .mem_cs_n                (mem_cs_n                ),
    .mem_a                   (mem_a                   ),
    .mem_dq                  (mem_dq                  ),
    .mem_dqs                 (mem_dqs                 ),
    .mem_dqs_n               (mem_dqs_n               ),
    .mem_dm                  (mem_dm                  ),
    .mem_cke                 (mem_cke                 ),
    .mem_odt                 (mem_odt                 ),
    .mem_ras_n               (mem_ras_n               ),
    .mem_cas_n               (mem_cas_n               ),
    .mem_we_n                (mem_we_n                ),
    .mem_ba                  (mem_ba                  )
);

JTAG_SLAVE  #(
    .OFFSET_ADDR              (S1_START_ADDR)
)S1(
    .clk                      (jtag_clk                 ),
    .rstn                     (jtag_rst_n               ),
    .tck                      (tck                      ),
    .tdi                      (tdi                      ),
    .tms                      (tms                      ),
    .tdo                      (tdo                      ),
    .JTAG_SLAVE_CLK           (S1_CLK                   ),
    .JTAG_SLAVE_RSTN          (S1_RSTN                  ),
    .JTAG_SLAVE_WR_ADDR_ID    (S1_WR_ADDR_ID            ),
    .JTAG_SLAVE_WR_ADDR       (S1_WR_ADDR               ),
    .JTAG_SLAVE_WR_ADDR_LEN   (S1_WR_ADDR_LEN           ),
    .JTAG_SLAVE_WR_ADDR_BURST (S1_WR_ADDR_BURST         ),
    .JTAG_SLAVE_WR_ADDR_VALID (S1_WR_ADDR_VALID         ),
    .JTAG_SLAVE_WR_ADDR_READY (S1_WR_ADDR_READY         ),
    .JTAG_SLAVE_WR_DATA       (S1_WR_DATA               ),
    .JTAG_SLAVE_WR_STRB       (S1_WR_STRB               ),
    .JTAG_SLAVE_WR_DATA_LAST  (S1_WR_DATA_LAST          ),
    .JTAG_SLAVE_WR_DATA_VALID (S1_WR_DATA_VALID         ),
    .JTAG_SLAVE_WR_DATA_READY (S1_WR_DATA_READY         ),
    .JTAG_SLAVE_WR_BACK_ID    (S1_WR_BACK_ID            ),
    .JTAG_SLAVE_WR_BACK_RESP  (S1_WR_BACK_RESP          ),
    .JTAG_SLAVE_WR_BACK_VALID (S1_WR_BACK_VALID         ),
    .JTAG_SLAVE_WR_BACK_READY (S1_WR_BACK_READY         ),
    .JTAG_SLAVE_RD_ADDR_ID    (S1_RD_ADDR_ID            ),
    .JTAG_SLAVE_RD_ADDR       (S1_RD_ADDR               ),
    .JTAG_SLAVE_RD_ADDR_LEN   (S1_RD_ADDR_LEN           ),
    .JTAG_SLAVE_RD_ADDR_BURST (S1_RD_ADDR_BURST         ),
    .JTAG_SLAVE_RD_ADDR_VALID (S1_RD_ADDR_VALID         ),
    .JTAG_SLAVE_RD_ADDR_READY (S1_RD_ADDR_READY         ),
    .JTAG_SLAVE_RD_BACK_ID    (S1_RD_BACK_ID            ),
    .JTAG_SLAVE_RD_DATA       (S1_RD_DATA               ),
    .JTAG_SLAVE_RD_DATA_RESP  (S1_RD_DATA_RESP          ),
    .JTAG_SLAVE_RD_DATA_LAST  (S1_RD_DATA_LAST          ),
    .JTAG_SLAVE_RD_DATA_VALID (S1_RD_DATA_VALID         ),
    .JTAG_SLAVE_RD_DATA_READY (S1_RD_DATA_READY         )
);

axi_led_slave #(
    .OFFSET_ADDR             (S2_START_ADDR)
)S2(
    .clk                     (led_clk                  ),
    .rstn                    (led_rst_n                ),
    .led                     (led                      ),
    .LED_SLAVE_CLK           (S2_CLK                   ),
    .LED_SLAVE_RSTN          (S2_RSTN                  ),
    .LED_SLAVE_WR_ADDR_ID    (S2_WR_ADDR_ID            ),
    .LED_SLAVE_WR_ADDR       (S2_WR_ADDR               ),
    .LED_SLAVE_WR_ADDR_LEN   (S2_WR_ADDR_LEN           ),
    .LED_SLAVE_WR_ADDR_BURST (S2_WR_ADDR_BURST         ),
    .LED_SLAVE_WR_ADDR_VALID (S2_WR_ADDR_VALID         ),
    .LED_SLAVE_WR_ADDR_READY (S2_WR_ADDR_READY         ),
    .LED_SLAVE_WR_DATA       (S2_WR_DATA               ),
    .LED_SLAVE_WR_STRB       (S2_WR_STRB               ),
    .LED_SLAVE_WR_DATA_LAST  (S2_WR_DATA_LAST          ),
    .LED_SLAVE_WR_DATA_VALID (S2_WR_DATA_VALID         ),
    .LED_SLAVE_WR_DATA_READY (S2_WR_DATA_READY         ),
    .LED_SLAVE_WR_BACK_ID    (S2_WR_BACK_ID            ),
    .LED_SLAVE_WR_BACK_RESP  (S2_WR_BACK_RESP          ),
    .LED_SLAVE_WR_BACK_VALID (S2_WR_BACK_VALID         ),
    .LED_SLAVE_WR_BACK_READY (S2_WR_BACK_READY         ),
    .LED_SLAVE_RD_ADDR_ID    (S2_RD_ADDR_ID            ),
    .LED_SLAVE_RD_ADDR       (S2_RD_ADDR               ),
    .LED_SLAVE_RD_ADDR_LEN   (S2_RD_ADDR_LEN           ),
    .LED_SLAVE_RD_ADDR_BURST (S2_RD_ADDR_BURST         ),
    .LED_SLAVE_RD_ADDR_VALID (S2_RD_ADDR_VALID         ),
    .LED_SLAVE_RD_ADDR_READY (S2_RD_ADDR_READY         ),
    .LED_SLAVE_RD_BACK_ID    (S2_RD_BACK_ID            ),
    .LED_SLAVE_RD_DATA       (S2_RD_DATA               ),
    .LED_SLAVE_RD_DATA_RESP  (S2_RD_DATA_RESP          ),
    .LED_SLAVE_RD_DATA_LAST  (S2_RD_DATA_LAST          ),
    .LED_SLAVE_RD_DATA_VALID (S2_RD_DATA_VALID         ),
    .LED_SLAVE_RD_DATA_READY (S2_RD_DATA_READY         )
);


assign S3_WR_ADDR_READY = 0;
assign S3_WR_DATA_READY = 0;
assign S3_WR_BACK_ID    = 0;
assign S3_WR_BACK_RESP  = 0;
assign S3_WR_BACK_VALID = 0;
assign S3_RD_ADDR_READY = 0;
assign S3_RD_BACK_ID    = 0;
assign S3_RD_DATA       = 0;
assign S3_RD_DATA_RESP  = 0;
assign S3_RD_DATA_LAST  = 0;
assign S3_RD_DATA_VALID = 0;

axi_bus #( //AXI顶层总线。支持主从机自设时钟域，内部设置FIFO。支持out-standing传输暂存，从机可选择性支持out-of-order乱序执行，目前不支持主机interleaving交织。
    .S0_START_ADDR(S0_START_ADDR),
    .S0_END_ADDR  (S0_END_ADDR  ),
    .S1_START_ADDR(S1_START_ADDR),
    .S1_END_ADDR  (S1_END_ADDR  ),
    .S2_START_ADDR(S2_START_ADDR),
    .S2_END_ADDR  (S2_END_ADDR  ),
    .S3_START_ADDR(S3_START_ADDR),
    .S3_END_ADDR  (S3_END_ADDR  )
)axi_bus_inst(
.BUS_CLK         (BUS_CLK         ),
.BUS_RSTN        (BUS_RSTN        ),
.M0_CLK          (M0_CLK          ),   .M1_CLK          (M1_CLK          ),    .M2_CLK          (M2_CLK          ),    .M3_CLK          (M3_CLK          ),
.M0_RSTN         (M0_RSTN         ),   .M1_RSTN         (M1_RSTN         ),    .M2_RSTN         (M2_RSTN         ),    .M3_RSTN         (M3_RSTN         ),
.M0_WR_ADDR_ID   (M0_WR_ADDR_ID   ),   .M1_WR_ADDR_ID   (M1_WR_ADDR_ID   ),    .M2_WR_ADDR_ID   (M2_WR_ADDR_ID   ),    .M3_WR_ADDR_ID   (M3_WR_ADDR_ID   ),
.M0_WR_ADDR      (M0_WR_ADDR      ),   .M1_WR_ADDR      (M1_WR_ADDR      ),    .M2_WR_ADDR      (M2_WR_ADDR      ),    .M3_WR_ADDR      (M3_WR_ADDR      ),
.M0_WR_ADDR_LEN  (M0_WR_ADDR_LEN  ),   .M1_WR_ADDR_LEN  (M1_WR_ADDR_LEN  ),    .M2_WR_ADDR_LEN  (M2_WR_ADDR_LEN  ),    .M3_WR_ADDR_LEN  (M3_WR_ADDR_LEN  ),
.M0_WR_ADDR_BURST(M0_WR_ADDR_BURST),   .M1_WR_ADDR_BURST(M1_WR_ADDR_BURST),    .M2_WR_ADDR_BURST(M2_WR_ADDR_BURST),    .M3_WR_ADDR_BURST(M3_WR_ADDR_BURST),
.M0_WR_ADDR_VALID(M0_WR_ADDR_VALID),   .M1_WR_ADDR_VALID(M1_WR_ADDR_VALID),    .M2_WR_ADDR_VALID(M2_WR_ADDR_VALID),    .M3_WR_ADDR_VALID(M3_WR_ADDR_VALID),
.M0_WR_ADDR_READY(M0_WR_ADDR_READY),   .M1_WR_ADDR_READY(M1_WR_ADDR_READY),    .M2_WR_ADDR_READY(M2_WR_ADDR_READY),    .M3_WR_ADDR_READY(M3_WR_ADDR_READY),
.M0_WR_DATA      (M0_WR_DATA      ),   .M1_WR_DATA      (M1_WR_DATA      ),    .M2_WR_DATA      (M2_WR_DATA      ),    .M3_WR_DATA      (M3_WR_DATA      ),
.M0_WR_STRB      (M0_WR_STRB      ),   .M1_WR_STRB      (M1_WR_STRB      ),    .M2_WR_STRB      (M2_WR_STRB      ),    .M3_WR_STRB      (M3_WR_STRB      ),
.M0_WR_DATA_LAST (M0_WR_DATA_LAST ),   .M1_WR_DATA_LAST (M1_WR_DATA_LAST ),    .M2_WR_DATA_LAST (M2_WR_DATA_LAST ),    .M3_WR_DATA_LAST (M3_WR_DATA_LAST ),
.M0_WR_DATA_VALID(M0_WR_DATA_VALID),   .M1_WR_DATA_VALID(M1_WR_DATA_VALID),    .M2_WR_DATA_VALID(M2_WR_DATA_VALID),    .M3_WR_DATA_VALID(M3_WR_DATA_VALID),
.M0_WR_DATA_READY(M0_WR_DATA_READY),   .M1_WR_DATA_READY(M1_WR_DATA_READY),    .M2_WR_DATA_READY(M2_WR_DATA_READY),    .M3_WR_DATA_READY(M3_WR_DATA_READY),
.M0_WR_BACK_ID   (M0_WR_BACK_ID   ),   .M1_WR_BACK_ID   (M1_WR_BACK_ID   ),    .M2_WR_BACK_ID   (M2_WR_BACK_ID   ),    .M3_WR_BACK_ID   (M3_WR_BACK_ID   ),
.M0_WR_BACK_RESP (M0_WR_BACK_RESP ),   .M1_WR_BACK_RESP (M1_WR_BACK_RESP ),    .M2_WR_BACK_RESP (M2_WR_BACK_RESP ),    .M3_WR_BACK_RESP (M3_WR_BACK_RESP ),
.M0_WR_BACK_VALID(M0_WR_BACK_VALID),   .M1_WR_BACK_VALID(M1_WR_BACK_VALID),    .M2_WR_BACK_VALID(M2_WR_BACK_VALID),    .M3_WR_BACK_VALID(M3_WR_BACK_VALID),
.M0_WR_BACK_READY(M0_WR_BACK_READY),   .M1_WR_BACK_READY(M1_WR_BACK_READY),    .M2_WR_BACK_READY(M2_WR_BACK_READY),    .M3_WR_BACK_READY(M3_WR_BACK_READY),
.M0_RD_ADDR_ID   (M0_RD_ADDR_ID   ),   .M1_RD_ADDR_ID   (M1_RD_ADDR_ID   ),    .M2_RD_ADDR_ID   (M2_RD_ADDR_ID   ),    .M3_RD_ADDR_ID   (M3_RD_ADDR_ID   ),
.M0_RD_ADDR      (M0_RD_ADDR      ),   .M1_RD_ADDR      (M1_RD_ADDR      ),    .M2_RD_ADDR      (M2_RD_ADDR      ),    .M3_RD_ADDR      (M3_RD_ADDR      ),
.M0_RD_ADDR_LEN  (M0_RD_ADDR_LEN  ),   .M1_RD_ADDR_LEN  (M1_RD_ADDR_LEN  ),    .M2_RD_ADDR_LEN  (M2_RD_ADDR_LEN  ),    .M3_RD_ADDR_LEN  (M3_RD_ADDR_LEN  ),
.M0_RD_ADDR_BURST(M0_RD_ADDR_BURST),   .M1_RD_ADDR_BURST(M1_RD_ADDR_BURST),    .M2_RD_ADDR_BURST(M2_RD_ADDR_BURST),    .M3_RD_ADDR_BURST(M3_RD_ADDR_BURST),
.M0_RD_ADDR_VALID(M0_RD_ADDR_VALID),   .M1_RD_ADDR_VALID(M1_RD_ADDR_VALID),    .M2_RD_ADDR_VALID(M2_RD_ADDR_VALID),    .M3_RD_ADDR_VALID(M3_RD_ADDR_VALID),
.M0_RD_ADDR_READY(M0_RD_ADDR_READY),   .M1_RD_ADDR_READY(M1_RD_ADDR_READY),    .M2_RD_ADDR_READY(M2_RD_ADDR_READY),    .M3_RD_ADDR_READY(M3_RD_ADDR_READY),
.M0_RD_BACK_ID   (M0_RD_BACK_ID   ),   .M1_RD_BACK_ID   (M1_RD_BACK_ID   ),    .M2_RD_BACK_ID   (M2_RD_BACK_ID   ),    .M3_RD_BACK_ID   (M3_RD_BACK_ID   ),
.M0_RD_DATA      (M0_RD_DATA      ),   .M1_RD_DATA      (M1_RD_DATA      ),    .M2_RD_DATA      (M2_RD_DATA      ),    .M3_RD_DATA      (M3_RD_DATA      ),
.M0_RD_DATA_RESP (M0_RD_DATA_RESP ),   .M1_RD_DATA_RESP (M1_RD_DATA_RESP ),    .M2_RD_DATA_RESP (M2_RD_DATA_RESP ),    .M3_RD_DATA_RESP (M3_RD_DATA_RESP ),
.M0_RD_DATA_LAST (M0_RD_DATA_LAST ),   .M1_RD_DATA_LAST (M1_RD_DATA_LAST ),    .M2_RD_DATA_LAST (M2_RD_DATA_LAST ),    .M3_RD_DATA_LAST (M3_RD_DATA_LAST ),
.M0_RD_DATA_VALID(M0_RD_DATA_VALID),   .M1_RD_DATA_VALID(M1_RD_DATA_VALID),    .M2_RD_DATA_VALID(M2_RD_DATA_VALID),    .M3_RD_DATA_VALID(M3_RD_DATA_VALID),
.M0_RD_DATA_READY(M0_RD_DATA_READY),   .M1_RD_DATA_READY(M1_RD_DATA_READY),    .M2_RD_DATA_READY(M2_RD_DATA_READY),    .M3_RD_DATA_READY(M3_RD_DATA_READY),
.S0_CLK          (S0_CLK          ),   .S1_CLK          (S1_CLK          ),    .S2_CLK          (S2_CLK          ),    .S3_CLK          (S3_CLK          ),
.S0_RSTN         (S0_RSTN         ),   .S1_RSTN         (S1_RSTN         ),    .S2_RSTN         (S2_RSTN         ),    .S3_RSTN         (S3_RSTN         ),
.S0_WR_ADDR_ID   (S0_WR_ADDR_ID   ),   .S1_WR_ADDR_ID   (S1_WR_ADDR_ID   ),    .S2_WR_ADDR_ID   (S2_WR_ADDR_ID   ),    .S3_WR_ADDR_ID   (S3_WR_ADDR_ID   ),
.S0_WR_ADDR      (S0_WR_ADDR      ),   .S1_WR_ADDR      (S1_WR_ADDR      ),    .S2_WR_ADDR      (S2_WR_ADDR      ),    .S3_WR_ADDR      (S3_WR_ADDR      ),
.S0_WR_ADDR_LEN  (S0_WR_ADDR_LEN  ),   .S1_WR_ADDR_LEN  (S1_WR_ADDR_LEN  ),    .S2_WR_ADDR_LEN  (S2_WR_ADDR_LEN  ),    .S3_WR_ADDR_LEN  (S3_WR_ADDR_LEN  ),
.S0_WR_ADDR_BURST(S0_WR_ADDR_BURST),   .S1_WR_ADDR_BURST(S1_WR_ADDR_BURST),    .S2_WR_ADDR_BURST(S2_WR_ADDR_BURST),    .S3_WR_ADDR_BURST(S3_WR_ADDR_BURST),
.S0_WR_ADDR_VALID(S0_WR_ADDR_VALID),   .S1_WR_ADDR_VALID(S1_WR_ADDR_VALID),    .S2_WR_ADDR_VALID(S2_WR_ADDR_VALID),    .S3_WR_ADDR_VALID(S3_WR_ADDR_VALID),
.S0_WR_ADDR_READY(S0_WR_ADDR_READY),   .S1_WR_ADDR_READY(S1_WR_ADDR_READY),    .S2_WR_ADDR_READY(S2_WR_ADDR_READY),    .S3_WR_ADDR_READY(S3_WR_ADDR_READY),
.S0_WR_DATA      (S0_WR_DATA      ),   .S1_WR_DATA      (S1_WR_DATA      ),    .S2_WR_DATA      (S2_WR_DATA      ),    .S3_WR_DATA      (S3_WR_DATA      ),
.S0_WR_STRB      (S0_WR_STRB      ),   .S1_WR_STRB      (S1_WR_STRB      ),    .S2_WR_STRB      (S2_WR_STRB      ),    .S3_WR_STRB      (S3_WR_STRB      ),
.S0_WR_DATA_LAST (S0_WR_DATA_LAST ),   .S1_WR_DATA_LAST (S1_WR_DATA_LAST ),    .S2_WR_DATA_LAST (S2_WR_DATA_LAST ),    .S3_WR_DATA_LAST (S3_WR_DATA_LAST ),
.S0_WR_DATA_VALID(S0_WR_DATA_VALID),   .S1_WR_DATA_VALID(S1_WR_DATA_VALID),    .S2_WR_DATA_VALID(S2_WR_DATA_VALID),    .S3_WR_DATA_VALID(S3_WR_DATA_VALID),
.S0_WR_DATA_READY(S0_WR_DATA_READY),   .S1_WR_DATA_READY(S1_WR_DATA_READY),    .S2_WR_DATA_READY(S2_WR_DATA_READY),    .S3_WR_DATA_READY(S3_WR_DATA_READY),
.S0_WR_BACK_ID   (S0_WR_BACK_ID   ),   .S1_WR_BACK_ID   (S1_WR_BACK_ID   ),    .S2_WR_BACK_ID   (S2_WR_BACK_ID   ),    .S3_WR_BACK_ID   (S3_WR_BACK_ID   ),
.S0_WR_BACK_RESP (S0_WR_BACK_RESP ),   .S1_WR_BACK_RESP (S1_WR_BACK_RESP ),    .S2_WR_BACK_RESP (S2_WR_BACK_RESP ),    .S3_WR_BACK_RESP (S3_WR_BACK_RESP ),
.S0_WR_BACK_VALID(S0_WR_BACK_VALID),   .S1_WR_BACK_VALID(S1_WR_BACK_VALID),    .S2_WR_BACK_VALID(S2_WR_BACK_VALID),    .S3_WR_BACK_VALID(S3_WR_BACK_VALID),
.S0_WR_BACK_READY(S0_WR_BACK_READY),   .S1_WR_BACK_READY(S1_WR_BACK_READY),    .S2_WR_BACK_READY(S2_WR_BACK_READY),    .S3_WR_BACK_READY(S3_WR_BACK_READY),
.S0_RD_ADDR_ID   (S0_RD_ADDR_ID   ),   .S1_RD_ADDR_ID   (S1_RD_ADDR_ID   ),    .S2_RD_ADDR_ID   (S2_RD_ADDR_ID   ),    .S3_RD_ADDR_ID   (S3_RD_ADDR_ID   ),
.S0_RD_ADDR      (S0_RD_ADDR      ),   .S1_RD_ADDR      (S1_RD_ADDR      ),    .S2_RD_ADDR      (S2_RD_ADDR      ),    .S3_RD_ADDR      (S3_RD_ADDR      ),
.S0_RD_ADDR_LEN  (S0_RD_ADDR_LEN  ),   .S1_RD_ADDR_LEN  (S1_RD_ADDR_LEN  ),    .S2_RD_ADDR_LEN  (S2_RD_ADDR_LEN  ),    .S3_RD_ADDR_LEN  (S3_RD_ADDR_LEN  ),
.S0_RD_ADDR_BURST(S0_RD_ADDR_BURST),   .S1_RD_ADDR_BURST(S1_RD_ADDR_BURST),    .S2_RD_ADDR_BURST(S2_RD_ADDR_BURST),    .S3_RD_ADDR_BURST(S3_RD_ADDR_BURST),
.S0_RD_ADDR_VALID(S0_RD_ADDR_VALID),   .S1_RD_ADDR_VALID(S1_RD_ADDR_VALID),    .S2_RD_ADDR_VALID(S2_RD_ADDR_VALID),    .S3_RD_ADDR_VALID(S3_RD_ADDR_VALID),
.S0_RD_ADDR_READY(S0_RD_ADDR_READY),   .S1_RD_ADDR_READY(S1_RD_ADDR_READY),    .S2_RD_ADDR_READY(S2_RD_ADDR_READY),    .S3_RD_ADDR_READY(S3_RD_ADDR_READY),
.S0_RD_BACK_ID   (S0_RD_BACK_ID   ),   .S1_RD_BACK_ID   (S1_RD_BACK_ID   ),    .S2_RD_BACK_ID   (S2_RD_BACK_ID   ),    .S3_RD_BACK_ID   (S3_RD_BACK_ID   ),
.S0_RD_DATA      (S0_RD_DATA      ),   .S1_RD_DATA      (S1_RD_DATA      ),    .S2_RD_DATA      (S2_RD_DATA      ),    .S3_RD_DATA      (S3_RD_DATA      ),
.S0_RD_DATA_RESP (S0_RD_DATA_RESP ),   .S1_RD_DATA_RESP (S1_RD_DATA_RESP ),    .S2_RD_DATA_RESP (S2_RD_DATA_RESP ),    .S3_RD_DATA_RESP (S3_RD_DATA_RESP ),
.S0_RD_DATA_LAST (S0_RD_DATA_LAST ),   .S1_RD_DATA_LAST (S1_RD_DATA_LAST ),    .S2_RD_DATA_LAST (S2_RD_DATA_LAST ),    .S3_RD_DATA_LAST (S3_RD_DATA_LAST ),
.S0_RD_DATA_VALID(S0_RD_DATA_VALID),   .S1_RD_DATA_VALID(S1_RD_DATA_VALID),    .S2_RD_DATA_VALID(S2_RD_DATA_VALID),    .S3_RD_DATA_VALID(S3_RD_DATA_VALID),
.S0_RD_DATA_READY(S0_RD_DATA_READY),   .S1_RD_DATA_READY(S1_RD_DATA_READY),    .S2_RD_DATA_READY(S2_RD_DATA_READY),    .S3_RD_DATA_READY(S3_RD_DATA_READY)
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
assign b1_gate = axi_bus_ddr_jtag_test.S0.ddr3_top_inst.axi_ddr3_inst.u_ddrphy_top.ddrphy_reset_ctrl.ddrphy_ioclk_gate[1];
assign #OUT_SYNC_DLY b0_gate =  b1_gate;
initial 
begin    
    force axi_bus_ddr_jtag_test.S0.ddr3_top_inst.axi_ddr3_inst.u_ddrphy_top.ddrphy_slice_top.i_dqs_bank[0].ddrphy_ppll.clkoutphy_gate = b0_gate;
//    force axi_bus_ddr_jtag_test.S0.ddr3_top_inst.axi_ddr3_inst.u_ddrphy_top.ddrphy_slice_top.i_dqs_bank[2].ddrphy_ppll.clkoutphy_gate = b0_gate;
end



endmodule