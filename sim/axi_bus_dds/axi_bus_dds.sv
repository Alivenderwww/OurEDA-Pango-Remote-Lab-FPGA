`timescale 1ns/1ps
module axi_bus_dds ();

localparam M_WIDTH = 2;
localparam S_WIDTH  = 2;
localparam [31:0] S_START_ADDR[0:(2**S_WIDTH-1)] = '{32'h00000000, 32'h10000000, 32'h20000000, 32'h30000000};
localparam [31:0]   S_END_ADDR[0:(2**S_WIDTH-1)] = '{32'h0FFFFFFF, 32'h1FFFFFFF, 32'h2FFFFFFF, 32'h3FFFFFFF};

reg dds_clk     ;
reg dds_rstn    ;
wire [2*8-1:0] dds_wave_out;
wire [7:0] dds_wave_out0 = dds_wave_out[7:0];
wire [7:0] dds_wave_out1 = dds_wave_out[15:8];

reg BUS_CLK;
reg BUS_RSTN;
reg M_CLK;[0:(2**M_WIDTH-1)];
reg M_RSTN[0:(2**M_WIDTH-1)];
reg S_CLK[0:(2**S_WIDTH-1)];
reg S_RSTN[0:(2**S_WIDTH-1)];
wire [ 1:0] M_WR_ADDR_ID   [0:(2**M_WIDTH-1)]; wire [ 3:0] S_WR_ADDR_ID   [0:(2**S_WIDTH-1)];
wire [31:0] M_WR_ADDR      [0:(2**M_WIDTH-1)]; wire [31:0] S_WR_ADDR      [0:(2**S_WIDTH-1)];
wire [ 7:0] M_WR_ADDR_LEN  [0:(2**M_WIDTH-1)]; wire [ 7:0] S_WR_ADDR_LEN  [0:(2**S_WIDTH-1)];
wire [ 1:0] M_WR_ADDR_BURST[0:(2**M_WIDTH-1)]; wire [ 1:0] S_WR_ADDR_BURST[0:(2**S_WIDTH-1)];
wire        M_WR_ADDR_VALID[0:(2**M_WIDTH-1)]; wire        S_WR_ADDR_VALID[0:(2**S_WIDTH-1)];
wire        M_WR_ADDR_READY[0:(2**M_WIDTH-1)]; wire        S_WR_ADDR_READY[0:(2**S_WIDTH-1)];
wire [31:0] M_WR_DATA      [0:(2**M_WIDTH-1)]; wire [31:0] S_WR_DATA      [0:(2**S_WIDTH-1)];
wire [ 3:0] M_WR_STRB      [0:(2**M_WIDTH-1)]; wire [ 3:0] S_WR_STRB      [0:(2**S_WIDTH-1)];
wire        M_WR_DATA_LAST [0:(2**M_WIDTH-1)]; wire        S_WR_DATA_LAST [0:(2**S_WIDTH-1)];
wire        M_WR_DATA_VALID[0:(2**M_WIDTH-1)]; wire        S_WR_DATA_VALID[0:(2**S_WIDTH-1)];
wire        M_WR_DATA_READY[0:(2**M_WIDTH-1)]; wire        S_WR_DATA_READY[0:(2**S_WIDTH-1)];
wire [ 1:0] M_WR_BACK_ID   [0:(2**M_WIDTH-1)]; wire [ 3:0] S_WR_BACK_ID   [0:(2**S_WIDTH-1)];
wire [ 1:0] M_WR_BACK_RESP [0:(2**M_WIDTH-1)]; wire [ 1:0] S_WR_BACK_RESP [0:(2**S_WIDTH-1)];
wire        M_WR_BACK_VALID[0:(2**M_WIDTH-1)]; wire        S_WR_BACK_VALID[0:(2**S_WIDTH-1)];
wire        M_WR_BACK_READY[0:(2**M_WIDTH-1)]; wire        S_WR_BACK_READY[0:(2**S_WIDTH-1)];
wire [ 1:0] M_RD_ADDR_ID   [0:(2**M_WIDTH-1)]; wire [ 3:0] S_RD_ADDR_ID   [0:(2**S_WIDTH-1)];
wire [31:0] M_RD_ADDR      [0:(2**M_WIDTH-1)]; wire [31:0] S_RD_ADDR      [0:(2**S_WIDTH-1)];
wire [ 7:0] M_RD_ADDR_LEN  [0:(2**M_WIDTH-1)]; wire [ 7:0] S_RD_ADDR_LEN  [0:(2**S_WIDTH-1)];
wire [ 1:0] M_RD_ADDR_BURST[0:(2**M_WIDTH-1)]; wire [ 1:0] S_RD_ADDR_BURST[0:(2**S_WIDTH-1)];
wire        M_RD_ADDR_VALID[0:(2**M_WIDTH-1)]; wire        S_RD_ADDR_VALID[0:(2**S_WIDTH-1)];
wire        M_RD_ADDR_READY[0:(2**M_WIDTH-1)]; wire        S_RD_ADDR_READY[0:(2**S_WIDTH-1)];
wire [ 1:0] M_RD_BACK_ID   [0:(2**M_WIDTH-1)]; wire [ 3:0] S_RD_BACK_ID   [0:(2**S_WIDTH-1)];
wire [31:0] M_RD_DATA      [0:(2**M_WIDTH-1)]; wire [31:0] S_RD_DATA      [0:(2**S_WIDTH-1)];
wire [ 1:0] M_RD_DATA_RESP [0:(2**M_WIDTH-1)]; wire [ 1:0] S_RD_DATA_RESP [0:(2**S_WIDTH-1)];
wire        M_RD_DATA_LAST [0:(2**M_WIDTH-1)]; wire        S_RD_DATA_LAST [0:(2**S_WIDTH-1)];
wire        M_RD_DATA_VALID[0:(2**M_WIDTH-1)]; wire        S_RD_DATA_VALID[0:(2**S_WIDTH-1)];
wire        M_RD_DATA_READY[0:(2**M_WIDTH-1)]; wire        S_RD_DATA_READY[0:(2**S_WIDTH-1)];

always #8  BUS_CLK = ~BUS_CLK; //speed:2
always #7    M_CLK[0] = ~M_CLK[0]; //speed:1
always #9    M_CLK[1] = ~M_CLK[1]; //speed:3
always #11   M_CLK[2] = ~M_CLK[2]; //speed:5
always #13   M_CLK[3] = ~M_CLK[3]; //speed:7
// always #6    S_CLK[0] = ~S_CLK[0]; //speed:0(FAST)
always #8    S_CLK[1] = ~S_CLK[1]; //speed:2
always #12   S_CLK[2] = ~S_CLK[2]; //speed:6
always #14   S_CLK[3] = ~S_CLK[3]; //speed:8(SLOW)

initial dds_clk = 0;
always #50 dds_clk = ~dds_clk;

initial begin
    dds_rstn = 0;
    #5000
    dds_rstn = 1;
end

initial begin
    BUS_CLK = 0; BUS_RSTN = 0;
    foreach(M_CLK[i])  M_CLK[i] = 0;
    foreach(M_RSTN[i]) M_RSTN[i] = 0;
    foreach(S_CLK[i])  S_CLK[i] = 0;
    foreach(S_RSTN[i]) S_RSTN[i] = 0;
#50000
    M0_RSTN = 1;  // S0_RSTN = 1;
    M1_RSTN = 1;  S1_RSTN = 1;
    M2_RSTN = 1;  S2_RSTN = 1;
    M3_RSTN = 1;  S3_RSTN = 1;
#5000
    BUS_RSTN = 1;
end

integer i;
initial begin
    #5000
    #300 M0.set_rd_data_channel(7);
    #300 M0.set_wr_data_channel(7);
    //IDCODE是器件标识符，同一种芯片的IDCODE相同。
    //JTAG读取IDCODE的流程：
    #300 M0.send_wr_addr(2'b00, 32'h00000000, 8'd000, 2'b00);
    #300 M0.send_wr_data(32'd0, 4'b1111);
    #300 M0.send_wr_addr(2'b00, 32'h00000001, 8'd000, 2'b00);
    #300 M0.send_wr_data(32'd20000, 4'b1111);
    #300 M0.send_wr_addr(2'b00, 32'h00000002, 8'd000, 2'b00);
    #300 M0.send_wr_data(32'd50000, 4'b1111);
    #300 M0.send_wr_addr(2'b00, 32'h00000003, 8'd000, 2'b00);
    #300 M0.send_wr_data(32'd100000, 4'b1111);
    #300 M0.send_wr_addr(2'b00, 32'h00000004, 8'd000, 2'b00);
    #300 M0.send_wr_data(32'd200000, 4'b1111);
    #300 M0.send_wr_addr(2'b00, 32'h00000009, 8'd000, 2'b00);
    #300 M0.send_wr_data(32'hFFFF_FFFF, 4'b1111);
    for(i=0;i<16;i=i+1)begin
        #300 M0.send_wr_addr(2'b00, 32'h0000000A, 8'd255, 2'b00);
        #300 M0.send_wr_data(256*i, 4'b1111);
    end
    // #300 M0.send_wr_addr(2'b00, 32'h00000009, 8'd000, 2'b00);
    // #300 M0.send_wr_data(32'h0000_0000, 4'b1111);
    #4000000 M0.send_wr_addr(2'b00, 32'h00000001, 8'd000, 2'b00);
    #300 M0.send_wr_data(32'd10000, 4'b1111);
    #4000000 M0.send_wr_addr(2'b00, 32'h00000001, 8'd000, 2'b00);
    #300 M0.send_wr_data(32'd50000, 4'b1111);
    #4000000 M0.send_wr_addr(2'b00, 32'h00000001, 8'd000, 2'b00);
    #300 M0.send_wr_data(32'd200000, 4'b1111);
    
    #300 M0.send_wr_addr(2'b00, 32'h00000010, 8'd000, 2'b00);
    #300 M0.send_wr_data(32'd0, 4'b1111);
    #300 M0.send_wr_addr(2'b00, 32'h00000011, 8'd000, 2'b00);
    #300 M0.send_wr_data(32'd20000, 4'b1111);
    #300 M0.send_wr_addr(2'b00, 32'h00000012, 8'd000, 2'b00);
    #300 M0.send_wr_data(32'd50000, 4'b1111);
    #300 M0.send_wr_addr(2'b00, 32'h00000013, 8'd000, 2'b00);
    #300 M0.send_wr_data(32'd100000, 4'b1111);
    #300 M0.send_wr_addr(2'b00, 32'h00000014, 8'd000, 2'b00);
    #300 M0.send_wr_data(32'd200000, 4'b1111);
    #300 M0.send_wr_addr(2'b00, 32'h00000019, 8'd000, 2'b00);
    #300 M0.send_wr_data(32'hFFFF_FFFF, 4'b1111);
    for(i=0;i<16*256;i=i+1)begin
        #300 M0.send_wr_addr(2'b00, 32'h0000001A, 8'd0, 2'b00);
        #300 M0.send_wr_data(square_wave(i), 4'b1111);
    end
    #4000000 M0.send_wr_addr(2'b00, 32'h00000011, 8'd000, 2'b00);
    #300 M0.send_wr_data(32'd10000, 4'b1111);
    #4000000 M0.send_wr_addr(2'b00, 32'h00000011, 8'd000, 2'b00);
    #300 M0.send_wr_data(32'd50000, 4'b1111);
    #4000000 M0.send_wr_addr(2'b00, 32'h00000011, 8'd000, 2'b00);
    #300 M0.send_wr_data(32'd200000, 4'b1111);
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

dds_slave #(
	.CHANNEL_NUM 	( 2          ),
	.OFFSER_ADDR 	( S0_START_ADDR  )
    )u_dds_slave(
	.clk                     	( dds_clk           ),
	.rstn                    	( dds_rstn          ),
	.wave_out                	( dds_wave_out      ),
	.DDS_SLAVE_CLK           	( S0_CLK            ),
	.DDS_SLAVE_RSTN          	( S0_RSTN           ),
	.DDS_SLAVE_WR_ADDR_ID    	( S0_WR_ADDR_ID     ),
	.DDS_SLAVE_WR_ADDR       	( S0_WR_ADDR        ),
	.DDS_SLAVE_WR_ADDR_LEN   	( S0_WR_ADDR_LEN    ),
	.DDS_SLAVE_WR_ADDR_BURST 	( S0_WR_ADDR_BURST  ),
	.DDS_SLAVE_WR_ADDR_VALID 	( S0_WR_ADDR_VALID  ),
	.DDS_SLAVE_WR_ADDR_READY 	( S0_WR_ADDR_READY  ),
	.DDS_SLAVE_WR_DATA       	( S0_WR_DATA        ),
	.DDS_SLAVE_WR_STRB       	( S0_WR_STRB        ),
	.DDS_SLAVE_WR_DATA_LAST  	( S0_WR_DATA_LAST   ),
	.DDS_SLAVE_WR_DATA_VALID 	( S0_WR_DATA_VALID  ),
	.DDS_SLAVE_WR_DATA_READY 	( S0_WR_DATA_READY  ),
	.DDS_SLAVE_WR_BACK_ID    	( S0_WR_BACK_ID     ),
	.DDS_SLAVE_WR_BACK_RESP  	( S0_WR_BACK_RESP   ),
	.DDS_SLAVE_WR_BACK_VALID 	( S0_WR_BACK_VALID  ),
	.DDS_SLAVE_WR_BACK_READY 	( S0_WR_BACK_READY  ),
	.DDS_SLAVE_RD_ADDR_ID    	( S0_RD_ADDR_ID     ),
	.DDS_SLAVE_RD_ADDR       	( S0_RD_ADDR        ),
	.DDS_SLAVE_RD_ADDR_LEN   	( S0_RD_ADDR_LEN    ),
	.DDS_SLAVE_RD_ADDR_BURST 	( S0_RD_ADDR_BURST  ),
	.DDS_SLAVE_RD_ADDR_VALID 	( S0_RD_ADDR_VALID  ),
	.DDS_SLAVE_RD_ADDR_READY 	( S0_RD_ADDR_READY  ),
	.DDS_SLAVE_RD_BACK_ID    	( S0_RD_BACK_ID     ),
	.DDS_SLAVE_RD_DATA       	( S0_RD_DATA        ),
	.DDS_SLAVE_RD_DATA_RESP  	( S0_RD_DATA_RESP   ),
	.DDS_SLAVE_RD_DATA_LAST  	( S0_RD_DATA_LAST   ),
	.DDS_SLAVE_RD_DATA_VALID 	( S0_RD_DATA_VALID  ),
	.DDS_SLAVE_RD_DATA_READY 	( S0_RD_DATA_READY  )
);



assign S1_WR_ADDR_READY = 0; assign S2_WR_ADDR_READY = 0; assign S3_WR_ADDR_READY = 0;
assign S1_WR_DATA_READY = 0; assign S2_WR_DATA_READY = 0; assign S3_WR_DATA_READY = 0;
assign S1_WR_BACK_ID    = 0; assign S2_WR_BACK_ID    = 0; assign S3_WR_BACK_ID    = 0;
assign S1_WR_BACK_RESP  = 0; assign S2_WR_BACK_RESP  = 0; assign S3_WR_BACK_RESP  = 0;
assign S1_WR_BACK_VALID = 0; assign S2_WR_BACK_VALID = 0; assign S3_WR_BACK_VALID = 0;
assign S1_RD_ADDR_READY = 0; assign S2_RD_ADDR_READY = 0; assign S3_RD_ADDR_READY = 0;
assign S1_RD_BACK_ID    = 0; assign S2_RD_BACK_ID    = 0; assign S3_RD_BACK_ID    = 0;
assign S1_RD_DATA       = 0; assign S2_RD_DATA       = 0; assign S3_RD_DATA       = 0;
assign S1_RD_DATA_RESP  = 0; assign S2_RD_DATA_RESP  = 0; assign S3_RD_DATA_RESP  = 0;
assign S1_RD_DATA_LAST  = 0; assign S2_RD_DATA_LAST  = 0; assign S3_RD_DATA_LAST  = 0;
assign S1_RD_DATA_VALID = 0; assign S2_RD_DATA_VALID = 0; assign S3_RD_DATA_VALID = 0;

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

function [7:0] square_wave;
input integer in0;
begin
    square_wave = ((in0 % 500) > 250)?(8'hFF):(8'h00);
end
endfunction


endmodule