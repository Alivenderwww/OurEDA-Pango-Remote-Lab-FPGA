`timescale 1ns/1ps
module remote_update_test ();

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

reg ru_clk;
reg ru_rstn;
// outports wire
wire        	spi_cs;
wire            spi_dq1;
wire        	spi_dq0;
initial ru_clk = 0;
always #50 ru_clk = ~ru_clk;
initial begin
    ru_rstn = 0;
    #10000
    ru_rstn = 1;
end

parameter S0_START_ADDR = 32'h00_00_00_00,
          S0_END_ADDR   = 32'h0F_FF_FF_FF,
          S1_START_ADDR = 32'h10_00_00_00,
          S1_END_ADDR   = 32'h1F_FF_FF_0F,
          S2_START_ADDR = 32'h20_00_00_00,
          S2_END_ADDR   = 32'h2F_FF_FF_0F,
          S3_START_ADDR = 32'h30_00_00_00,
          S3_END_ADDR   = 32'h3F_FF_FF_0F;

always #8  BUS_CLK = ~BUS_CLK; //speed:2
always #7    M0_CLK = ~M0_CLK; //speed:1
always #9    M1_CLK = ~M1_CLK; //speed:3
always #11   M2_CLK = ~M2_CLK; //speed:5
always #13   M3_CLK = ~M3_CLK; //speed:7
// always #6    S0_CLK = ~S0_CLK; //speed:0(FAST)
always #8    S1_CLK = ~S1_CLK; //speed:2
always #12   S2_CLK = ~S2_CLK; //speed:6
always #14   S3_CLK = ~S3_CLK; //speed:8(SLOW)

initial begin
    BUS_CLK = 0; BUS_RSTN = 0;
    M0_CLK  = 0; M0_RSTN  = 0;
    M1_CLK  = 0; M1_RSTN  = 0;
    M2_CLK  = 0; M2_RSTN  = 0;
    M3_CLK  = 0; M3_RSTN  = 0;
    // S0_CLK  = 0; S0_RSTN  = 0;
    S1_CLK  = 0; S1_RSTN  = 0;
    S2_CLK  = 0; S2_RSTN  = 0;
    S3_CLK  = 0; S3_RSTN  = 0;
#50000
    M0_RSTN = 1;  // S0_RSTN = 1;
    M1_RSTN = 1;  S1_RSTN = 1;
    M2_RSTN = 1;  S2_RSTN = 1;
    M3_RSTN = 1;  S3_RSTN = 1;
#5000
    BUS_RSTN = 1;
end

integer j;
initial begin
    #5000
    while(~BUS_RSTN) #300;
    while(~S0_RSTN) #300;
    #300 M0.set_rd_data_channel(7);
    #300 M0.set_wr_data_channel(1);

    #300 M0.send_wr_addr(2'b00, 32'h00000000, 8'd000, 2'b01);
    #300 M0.send_wr_data(32'h00_00_00_07, 4'b0001); //上位机将 bitstream_wr_num 修改为想要重新写的应用位流num号，上位机将 flash_wr_en 置1，模块自动置0
    
    #1000 M0.send_rd_addr(2'b00, 32'h00000002, 8'd000, 2'b00);
    #1000 M0.send_rd_addr(2'b00, 32'h00000002, 8'd000, 2'b00);
    #1000 M0.send_rd_addr(2'b00, 32'h00000002, 8'd000, 2'b00); //模块将 clear_bs_done 置1，标志擦除完成指示

    //100H需要发送926*4KB数据，即3704KB数据，一次255突发数据量为256*4bytes=1KB，因此共传3704次。
    //SIMULATE设定需要发15*4KB数据
    for(j=0;j<15*4;j=j+1) begin
        #300 M0.send_wr_addr(2'b00, 32'h00000001, 8'd255, 2'b00);
        #300 M0.send_wr_data(j*256, 4'b1111);
    end
    
    #1000 M0.send_rd_addr(2'b00, 32'h00000002, 8'd000, 2'b00);
    #1000 M0.send_rd_addr(2'b00, 32'h00000002, 8'd000, 2'b00);
    #1000 M0.send_rd_addr(2'b00, 32'h00000002, 8'd000, 2'b00); //模块将 bitstream_wr_done 置1，标志写位流完成，写入比特流流程结束

    #300 M0.send_wr_addr(2'b00, 32'h00000003, 8'd000, 2'b01);
    #300 M0.send_wr_data(32'h00_00_01_07, 4'b1111); //bs_crc32_ok设置为无效；crc_check_en置0不校验；bitstream_up2cpu_en为1回读；上位机将 bitstream_rd_num 修改为想要读的应用位流num号；上位机将 flash_rd_en 置1，模块自动置0

    for(j=0;j<15*4;j=j+1) begin
        #300 M0.send_rd_addr(2'b00, 32'h00000004, 8'd255, 2'b00); //回读比特流
    end

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

remote_update_axi_slave #(
    .OFFSET_ADDR            (S0_START_ADDR        ),
	.FPGA_VERSION          	( 48'h2024_1119_1943  ),
	.DEVICE               	( "SIMULATE"          ),//100H的文件太大了，仿真太慢，搞小一点
	.USER_BITSTREAM_CNT   	( 2'd3                ),
	.USER_BITSTREAM1_ADDR 	( 24'h3a_0000         ),
	.USER_BITSTREAM2_ADDR 	( 24'h41_0000         ),
	.USER_BITSTREAM3_ADDR 	( 24'h61_5000         ))
S0(
	.clk                 	( ru_clk            ),
	.rstn                	( ru_rstn           ),
	.spi_cs              	( spi_cs            ),
	.spi_dq1             	( spi_dq1           ),
	.spi_dq0             	( spi_dq0           ),
	.SLAVE_CLK           	( S0_CLK            ),
	.SLAVE_RSTN          	( S0_RSTN           ),
	.SLAVE_WR_ADDR_ID    	( S0_WR_ADDR_ID     ),
	.SLAVE_WR_ADDR       	( S0_WR_ADDR        ),
	.SLAVE_WR_ADDR_LEN   	( S0_WR_ADDR_LEN    ),
	.SLAVE_WR_ADDR_BURST 	( S0_WR_ADDR_BURST  ),
	.SLAVE_WR_ADDR_VALID 	( S0_WR_ADDR_VALID  ),
	.SLAVE_WR_ADDR_READY 	( S0_WR_ADDR_READY  ),
	.SLAVE_WR_DATA       	( S0_WR_DATA        ),
	.SLAVE_WR_STRB       	( S0_WR_STRB        ),
	.SLAVE_WR_DATA_LAST  	( S0_WR_DATA_LAST   ),
	.SLAVE_WR_DATA_VALID 	( S0_WR_DATA_VALID  ),
	.SLAVE_WR_DATA_READY 	( S0_WR_DATA_READY  ),
	.SLAVE_WR_BACK_ID    	( S0_WR_BACK_ID     ),
	.SLAVE_WR_BACK_RESP  	( S0_WR_BACK_RESP   ),
	.SLAVE_WR_BACK_VALID 	( S0_WR_BACK_VALID  ),
	.SLAVE_WR_BACK_READY 	( S0_WR_BACK_READY  ),
	.SLAVE_RD_ADDR_ID    	( S0_RD_ADDR_ID     ),
	.SLAVE_RD_ADDR       	( S0_RD_ADDR        ),
	.SLAVE_RD_ADDR_LEN   	( S0_RD_ADDR_LEN    ),
	.SLAVE_RD_ADDR_BURST 	( S0_RD_ADDR_BURST  ),
	.SLAVE_RD_ADDR_VALID 	( S0_RD_ADDR_VALID  ),
	.SLAVE_RD_ADDR_READY 	( S0_RD_ADDR_READY  ),
	.SLAVE_RD_BACK_ID    	( S0_RD_BACK_ID     ),
	.SLAVE_RD_DATA       	( S0_RD_DATA        ),
	.SLAVE_RD_DATA_RESP  	( S0_RD_DATA_RESP   ),
	.SLAVE_RD_DATA_LAST  	( S0_RD_DATA_LAST   ),
	.SLAVE_RD_DATA_VALID 	( S0_RD_DATA_VALID  ),
	.SLAVE_RD_DATA_READY 	( S0_RD_DATA_READY  )
);


assign S1_WR_ADDR_READY = 0;assign S2_WR_ADDR_READY = 0;assign S3_WR_ADDR_READY = 0;
assign S1_WR_DATA_READY = 0;assign S2_WR_DATA_READY = 0;assign S3_WR_DATA_READY = 0;
assign S1_WR_BACK_ID    = 0;assign S2_WR_BACK_ID    = 0;assign S3_WR_BACK_ID    = 0;
assign S1_WR_BACK_RESP  = 0;assign S2_WR_BACK_RESP  = 0;assign S3_WR_BACK_RESP  = 0;
assign S1_WR_BACK_VALID = 0;assign S2_WR_BACK_VALID = 0;assign S3_WR_BACK_VALID = 0;
assign S1_RD_ADDR_READY = 0;assign S2_RD_ADDR_READY = 0;assign S3_RD_ADDR_READY = 0;
assign S1_RD_BACK_ID    = 0;assign S2_RD_BACK_ID    = 0;assign S3_RD_BACK_ID    = 0;
assign S1_RD_DATA       = 0;assign S2_RD_DATA       = 0;assign S3_RD_DATA       = 0;
assign S1_RD_DATA_RESP  = 0;assign S2_RD_DATA_RESP  = 0;assign S3_RD_DATA_RESP  = 0;
assign S1_RD_DATA_LAST  = 0;assign S2_RD_DATA_LAST  = 0;assign S3_RD_DATA_LAST  = 0;
assign S1_RD_DATA_VALID = 0;assign S2_RD_DATA_VALID = 0;assign S3_RD_DATA_VALID = 0;

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

reg grs_n;
GTP_GRS GRS_INST(.GRS_N (grs_n));
initial begin
grs_n = 1'b0;
#5 grs_n = 1'b1;
end

MX25L12805D flash_u( ru_clk, spi_cs, spi_dq0, spi_dq1, 1'b0, 1'b1 );


endmodule