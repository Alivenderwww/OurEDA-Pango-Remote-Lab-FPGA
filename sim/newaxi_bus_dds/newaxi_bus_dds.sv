`timescale 1ns/1ps
module newaxi_bus_dds ();

localparam M_WIDTH  = 2;
localparam S_WIDTH  = 3;
localparam M_ID     = 2;
localparam [31:0] START_ADDR[0:(2**S_WIDTH-1)] = '{32'h00000000, 32'h10000000, 32'h20000000, 32'h30000000, 32'h40000000, 32'h50000000, 32'h60000000, 32'h70000000};
localparam [31:0]   END_ADDR[0:(2**S_WIDTH-1)] = '{32'h0FFFFFFF, 32'h1FFFFFFF, 32'h2FFFFFFF, 32'h3FFFFFFF, 32'h4FFFFFFF, 32'h5FFFFFFF, 32'h6FFFFFFF, 32'h7FFFFFFF};

AXI_INF #(.ID_WIDTH(M_ID        ))AXI_MB[0:2**M_WIDTH-1]();
AXI_INF #(.ID_WIDTH(M_ID+M_WIDTH))AXI_BS[0:2**S_WIDTH-1]();
wire [4:0] M_fifo_empty_flag[0:(2**M_WIDTH-1)];
wire [4:0] S_fifo_empty_flag[0:(2**S_WIDTH-1)];
reg M_CLK [2**M_WIDTH-1:0];
reg M_RSTN[2**M_WIDTH-1:0];
reg S_CLK [2**S_WIDTH-1:0];
reg S_RSTN[2**S_WIDTH-1:0];

reg dds_clk     ;
reg dds_rstn    ;
wire [2*8-1:0] dds_wave_out;
wire [7:0] dds_wave_out0 = dds_wave_out[7:0];
wire [7:0] dds_wave_out1 = dds_wave_out[15:8];

reg BUS_CLK;
reg BUS_RSTN;

initial begin
    BUS_CLK = 0; BUS_RSTN = 0;
    foreach(M_CLK[i]) M_CLK[i] = 0;
    foreach(S_CLK[i]) S_CLK[i] = 0;
    foreach(M_RSTN[i]) M_RSTN[i] = 0;
    foreach(S_RSTN[i]) S_RSTN[i] = 0;
    #50000;
    BUS_RSTN = 1;
    foreach(M_RSTN[i]) M_RSTN[i] = 1;
    foreach(S_RSTN[i]) S_RSTN[i] = 1;
end

always #10 BUS_CLK = ~BUS_CLK;
always #10 M_CLK[0] = ~M_CLK[0];
always #10 M_CLK[1] = ~M_CLK[1];
always #10 M_CLK[2] = ~M_CLK[2];
always #10 M_CLK[3] = ~M_CLK[3];
always #10 S_CLK[0] = ~S_CLK[0];
always #10 S_CLK[1] = ~S_CLK[1];
always #10 S_CLK[2] = ~S_CLK[2];
always #10 S_CLK[3] = ~S_CLK[3];
always #10 S_CLK[4] = ~S_CLK[4];
always #10 S_CLK[5] = ~S_CLK[5];
always #10 S_CLK[6] = ~S_CLK[6];
always #10 S_CLK[7] = ~S_CLK[7];

integer i;
initial begin
    #500000
    #300 M0.set_rd_data_channel(31);
    #300 M0.set_wr_data_channel(31);
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
    .clk                  (BUS_CLK ),
    .rstn                 (BUS_RSTN),
    .AXI_M                (AXI_MB[0])
);

axi_master_default M1(.AXI_M(AXI_MB[1]));
axi_master_default M2(.AXI_M(AXI_MB[2]));
axi_master_default M3(.AXI_M(AXI_MB[3]));

dds_slave #(
	.CHANNEL_NUM 	( 2          ),
	.OFFSER_ADDR 	( START_ADDR[0]  )
)S0(
	.clk            ( BUS_CLK      ),
	.rstn           ( BUS_RSTN     ),
	.wave_out       ( dds_wave_out ),
    .AXI_S          ( AXI_BS[0]    )
);

axi_slave_default S1(.AXI_S(AXI_BS[1]));
axi_slave_default S2(.AXI_S(AXI_BS[2]));
axi_slave_default S3(.AXI_S(AXI_BS[3]));
axi_slave_default S4(.AXI_S(AXI_BS[4]));
axi_slave_default S5(.AXI_S(AXI_BS[5]));
axi_slave_default S6(.AXI_S(AXI_BS[6]));
axi_slave_default S7(.AXI_S(AXI_BS[7]));

axi_bus #(
	.M_ID      (M_ID     ),
    .M_WIDTH   (M_WIDTH  ),
    .S_WIDTH   (S_WIDTH  ),
    .START_ADDR(START_ADDR),
    .END_ADDR  (END_ADDR))
axi_bus_inst(
	.BUS_CLK            ( BUS_CLK          ),
	.BUS_RSTN           ( BUS_RSTN         ),
	.M_CLK              ( M_CLK            ),
	.M_RSTN             ( M_RSTN           ),
	.S_CLK              ( S_CLK            ),
	.S_RSTN             ( S_RSTN           ),
	.AXI_M              ( AXI_MB            ),
	.AXI_S              ( AXI_BS            ),
	.M_fifo_empty_flag  ( M_fifo_empty_flag),
	.S_fifo_empty_flag  ( S_fifo_empty_flag)        
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