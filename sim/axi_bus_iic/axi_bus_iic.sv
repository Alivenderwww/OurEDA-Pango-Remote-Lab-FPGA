`timescale 1ns/1ps
module axi_bus_iic ();

localparam M_WIDTH  = 2;
localparam S_WIDTH  = 2;
localparam M_ID     = 2;
localparam [0:(2**S_WIDTH-1)][31:0] START_ADDR = '{32'h00000000, 32'h10000000, 32'h20000000, 32'h30000000};
localparam [0:(2**S_WIDTH-1)][31:0]   END_ADDR = '{32'h0FFFFFFF, 32'h1FFFFFFF, 32'h2FFFFFFF, 32'h3FFFFFFF};

reg iic_axi_clk     ;
reg iic_axi_rstn    ;

wire         scl_out   ;
wire         scl_enable;
wire         sda_out   ;
wire         sda_enable;
wire         sda, scl;
wire         sda_slave_out, sda_memory_ctrl;

assign scl = (scl_enable)?(scl_out):(1'b1);
assign sda = (sda_enable)?(sda_out):((sda_memory_ctrl)?(sda_slave_out):(1'b1));

reg  BUS_CLK    ;
reg  BUS_RSTN   ;
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

always #8  BUS_CLK = ~BUS_CLK; //speed:2

initial iic_axi_clk = 0;
always #10 iic_axi_clk = ~iic_axi_clk;

initial begin
    iic_axi_rstn = 0;
    #5000
    iic_axi_rstn = 1;
end

initial begin
    BUS_CLK = 0; BUS_RSTN = 0;
#5000
    BUS_RSTN = 1;
end

integer i;
initial begin
    #300 M0.set_clk(5);
    #5000
    #300 M0.set_rd_data_channel(31);
    #300 M0.set_wr_data_channel(31);
    //测试多字节读写
    #500000 M0.send_wr_addr(2'b00, 32'h0000_0003, 8'd0, 2'b01);
    #500000 M0.send_wr_data({24'h00, 8'h0}, 4'b1111);
    #500000 M0.send_wr_addr(2'b00, 32'h0000_0003, 8'd0, 2'b01);
    #500000 M0.send_wr_data({24'h00, 8'h0}, 4'b1111);
    #500000 M0.send_wr_addr(2'b00, 32'h0000_0003, 8'd3, 2'b00);
    #500000 M0.send_wr_data({24'h00, 8'd10}, 4'b1111);
    #500000 M0.send_wr_addr(2'b00, 32'h0000_0001, 8'd0, 2'b01);
    #500000 M0.send_wr_data({16'd0, 16'd5}, 4'b1111);
    #500000 M0.send_wr_addr(2'b00, 32'h0000_0000, 8'd0, 2'b01);
    #500000 M0.send_wr_data({8'h1,8'h0,8'h0,1'b0,7'b1010_000}, 4'b1111); //wait
    #5000000;
    #500000 M0.send_wr_addr(2'b00, 32'h0000_0001, 8'd0, 2'b01);
    #500000 M0.send_wr_data({16'd1, 16'd3}, 4'b1111);
    #5000000 M0.send_wr_addr(2'b00, 32'h0000_0000, 8'd0, 2'b01);
    #5000000 M0.send_wr_data({8'h1,8'h1,8'h1,1'b0,7'b1010_000}, 4'b1111); //wait
    #5000000;
    #5000000 M0.send_rd_addr(2'b00, 32'h0000_0004, 8'd3, 2'b00);
end

axi_master_sim M0(
    .MASTER_CLK           (M_CLK          [0] ),
    .MASTER_RSTN          (M_RSTN         [0] ),
    .MASTER_WR_ADDR_ID    (M_WR_ADDR_ID   [0] ),
    .MASTER_WR_ADDR       (M_WR_ADDR      [0] ),
    .MASTER_WR_ADDR_LEN   (M_WR_ADDR_LEN  [0] ),
    .MASTER_WR_ADDR_BURST (M_WR_ADDR_BURST[0] ),
    .MASTER_WR_ADDR_VALID (M_WR_ADDR_VALID[0] ),
    .MASTER_WR_ADDR_READY (M_WR_ADDR_READY[0] ),
    .MASTER_WR_DATA       (M_WR_DATA      [0] ),
    .MASTER_WR_STRB       (M_WR_STRB      [0] ),
    .MASTER_WR_DATA_LAST  (M_WR_DATA_LAST [0] ),
    .MASTER_WR_DATA_VALID (M_WR_DATA_VALID[0] ),
    .MASTER_WR_DATA_READY (M_WR_DATA_READY[0] ),
    .MASTER_WR_BACK_ID    (M_WR_BACK_ID   [0] ),
    .MASTER_WR_BACK_RESP  (M_WR_BACK_RESP [0] ),
    .MASTER_WR_BACK_VALID (M_WR_BACK_VALID[0] ),
    .MASTER_WR_BACK_READY (M_WR_BACK_READY[0] ),
    .MASTER_RD_ADDR_ID    (M_RD_ADDR_ID   [0] ),
    .MASTER_RD_ADDR       (M_RD_ADDR      [0] ),
    .MASTER_RD_ADDR_LEN   (M_RD_ADDR_LEN  [0] ),
    .MASTER_RD_ADDR_BURST (M_RD_ADDR_BURST[0] ),
    .MASTER_RD_ADDR_VALID (M_RD_ADDR_VALID[0] ),
    .MASTER_RD_ADDR_READY (M_RD_ADDR_READY[0] ),
    .MASTER_RD_BACK_ID    (M_RD_BACK_ID   [0] ),
    .MASTER_RD_DATA       (M_RD_DATA      [0] ),
    .MASTER_RD_DATA_RESP  (M_RD_DATA_RESP [0] ),
    .MASTER_RD_DATA_LAST  (M_RD_DATA_LAST [0] ),
    .MASTER_RD_DATA_VALID (M_RD_DATA_VALID[0] ),
    .MASTER_RD_DATA_READY (M_RD_DATA_READY[0] )
);

axi_master_sim M1(
    .MASTER_CLK           (M_CLK          [1] ),
    .MASTER_RSTN          (M_RSTN         [1] ),
    .MASTER_WR_ADDR_ID    (M_WR_ADDR_ID   [1] ),
    .MASTER_WR_ADDR       (M_WR_ADDR      [1] ),
    .MASTER_WR_ADDR_LEN   (M_WR_ADDR_LEN  [1] ),
    .MASTER_WR_ADDR_BURST (M_WR_ADDR_BURST[1] ),
    .MASTER_WR_ADDR_VALID (M_WR_ADDR_VALID[1] ),
    .MASTER_WR_ADDR_READY (M_WR_ADDR_READY[1] ),
    .MASTER_WR_DATA       (M_WR_DATA      [1] ),
    .MASTER_WR_STRB       (M_WR_STRB      [1] ),
    .MASTER_WR_DATA_LAST  (M_WR_DATA_LAST [1] ),
    .MASTER_WR_DATA_VALID (M_WR_DATA_VALID[1] ),
    .MASTER_WR_DATA_READY (M_WR_DATA_READY[1] ),
    .MASTER_WR_BACK_ID    (M_WR_BACK_ID   [1] ),
    .MASTER_WR_BACK_RESP  (M_WR_BACK_RESP [1] ),
    .MASTER_WR_BACK_VALID (M_WR_BACK_VALID[1] ),
    .MASTER_WR_BACK_READY (M_WR_BACK_READY[1] ),
    .MASTER_RD_ADDR_ID    (M_RD_ADDR_ID   [1] ),
    .MASTER_RD_ADDR       (M_RD_ADDR      [1] ),
    .MASTER_RD_ADDR_LEN   (M_RD_ADDR_LEN  [1] ),
    .MASTER_RD_ADDR_BURST (M_RD_ADDR_BURST[1] ),
    .MASTER_RD_ADDR_VALID (M_RD_ADDR_VALID[1] ),
    .MASTER_RD_ADDR_READY (M_RD_ADDR_READY[1] ),
    .MASTER_RD_BACK_ID    (M_RD_BACK_ID   [1] ),
    .MASTER_RD_DATA       (M_RD_DATA      [1] ),
    .MASTER_RD_DATA_RESP  (M_RD_DATA_RESP [1] ),
    .MASTER_RD_DATA_LAST  (M_RD_DATA_LAST [1] ),
    .MASTER_RD_DATA_VALID (M_RD_DATA_VALID[1] ),
    .MASTER_RD_DATA_READY (M_RD_DATA_READY[1] )
);

axi_master_sim M2(
    .MASTER_CLK           (M_CLK          [2] ),
    .MASTER_RSTN          (M_RSTN         [2] ),
    .MASTER_WR_ADDR_ID    (M_WR_ADDR_ID   [2] ),
    .MASTER_WR_ADDR       (M_WR_ADDR      [2] ),
    .MASTER_WR_ADDR_LEN   (M_WR_ADDR_LEN  [2] ),
    .MASTER_WR_ADDR_BURST (M_WR_ADDR_BURST[2] ),
    .MASTER_WR_ADDR_VALID (M_WR_ADDR_VALID[2] ),
    .MASTER_WR_ADDR_READY (M_WR_ADDR_READY[2] ),
    .MASTER_WR_DATA       (M_WR_DATA      [2] ),
    .MASTER_WR_STRB       (M_WR_STRB      [2] ),
    .MASTER_WR_DATA_LAST  (M_WR_DATA_LAST [2] ),
    .MASTER_WR_DATA_VALID (M_WR_DATA_VALID[2] ),
    .MASTER_WR_DATA_READY (M_WR_DATA_READY[2] ),
    .MASTER_WR_BACK_ID    (M_WR_BACK_ID   [2] ),
    .MASTER_WR_BACK_RESP  (M_WR_BACK_RESP [2] ),
    .MASTER_WR_BACK_VALID (M_WR_BACK_VALID[2] ),
    .MASTER_WR_BACK_READY (M_WR_BACK_READY[2] ),
    .MASTER_RD_ADDR_ID    (M_RD_ADDR_ID   [2] ),
    .MASTER_RD_ADDR       (M_RD_ADDR      [2] ),
    .MASTER_RD_ADDR_LEN   (M_RD_ADDR_LEN  [2] ),
    .MASTER_RD_ADDR_BURST (M_RD_ADDR_BURST[2] ),
    .MASTER_RD_ADDR_VALID (M_RD_ADDR_VALID[2] ),
    .MASTER_RD_ADDR_READY (M_RD_ADDR_READY[2] ),
    .MASTER_RD_BACK_ID    (M_RD_BACK_ID   [2] ),
    .MASTER_RD_DATA       (M_RD_DATA      [2] ),
    .MASTER_RD_DATA_RESP  (M_RD_DATA_RESP [2] ),
    .MASTER_RD_DATA_LAST  (M_RD_DATA_LAST [2] ),
    .MASTER_RD_DATA_VALID (M_RD_DATA_VALID[2] ),
    .MASTER_RD_DATA_READY (M_RD_DATA_READY[2] )
);

axi_master_sim M3(
    .MASTER_CLK           (M_CLK          [3] ),
    .MASTER_RSTN          (M_RSTN         [3] ),
    .MASTER_WR_ADDR_ID    (M_WR_ADDR_ID   [3] ),
    .MASTER_WR_ADDR       (M_WR_ADDR      [3] ),
    .MASTER_WR_ADDR_LEN   (M_WR_ADDR_LEN  [3] ),
    .MASTER_WR_ADDR_BURST (M_WR_ADDR_BURST[3] ),
    .MASTER_WR_ADDR_VALID (M_WR_ADDR_VALID[3] ),
    .MASTER_WR_ADDR_READY (M_WR_ADDR_READY[3] ),
    .MASTER_WR_DATA       (M_WR_DATA      [3] ),
    .MASTER_WR_STRB       (M_WR_STRB      [3] ),
    .MASTER_WR_DATA_LAST  (M_WR_DATA_LAST [3] ),
    .MASTER_WR_DATA_VALID (M_WR_DATA_VALID[3] ),
    .MASTER_WR_DATA_READY (M_WR_DATA_READY[3] ),
    .MASTER_WR_BACK_ID    (M_WR_BACK_ID   [3] ),
    .MASTER_WR_BACK_RESP  (M_WR_BACK_RESP [3] ),
    .MASTER_WR_BACK_VALID (M_WR_BACK_VALID[3] ),
    .MASTER_WR_BACK_READY (M_WR_BACK_READY[3] ),
    .MASTER_RD_ADDR_ID    (M_RD_ADDR_ID   [3] ),
    .MASTER_RD_ADDR       (M_RD_ADDR      [3] ),
    .MASTER_RD_ADDR_LEN   (M_RD_ADDR_LEN  [3] ),
    .MASTER_RD_ADDR_BURST (M_RD_ADDR_BURST[3] ),
    .MASTER_RD_ADDR_VALID (M_RD_ADDR_VALID[3] ),
    .MASTER_RD_ADDR_READY (M_RD_ADDR_READY[3] ),
    .MASTER_RD_BACK_ID    (M_RD_BACK_ID   [3] ),
    .MASTER_RD_DATA       (M_RD_DATA      [3] ),
    .MASTER_RD_DATA_RESP  (M_RD_DATA_RESP [3] ),
    .MASTER_RD_DATA_LAST  (M_RD_DATA_LAST [3] ),
    .MASTER_RD_DATA_VALID (M_RD_DATA_VALID[3] ),
    .MASTER_RD_DATA_READY (M_RD_DATA_READY[3] )
);

i2c_master_general_axi_slave #(
	.OFFSET_ADDR 	( START_ADDR[0]  )
)S0(
	.clk                    ( iic_axi_clk       ),
	.rstn                   ( iic_axi_rstn      ),

    .scl_in                 (scl                ),
    .scl_out                (scl_out            ),
    .scl_enable             (scl_enable         ),
    .sda_in                 (sda                ),
    .sda_out                (sda_out            ),
    .sda_enable             (sda_enable         ),

	.SLAVE_CLK           	( S_CLK          [0]  ),
	.SLAVE_RSTN          	( S_RSTN         [0]  ),
	.SLAVE_WR_ADDR_ID    	( S_WR_ADDR_ID   [0]  ),
	.SLAVE_WR_ADDR       	( S_WR_ADDR      [0]  ),
	.SLAVE_WR_ADDR_LEN   	( S_WR_ADDR_LEN  [0]  ),
	.SLAVE_WR_ADDR_BURST 	( S_WR_ADDR_BURST[0]  ),
	.SLAVE_WR_ADDR_VALID 	( S_WR_ADDR_VALID[0]  ),
	.SLAVE_WR_ADDR_READY 	( S_WR_ADDR_READY[0]  ),
	.SLAVE_WR_DATA       	( S_WR_DATA      [0]  ),
	.SLAVE_WR_STRB       	( S_WR_STRB      [0]  ),
	.SLAVE_WR_DATA_LAST  	( S_WR_DATA_LAST [0]  ),
	.SLAVE_WR_DATA_VALID 	( S_WR_DATA_VALID[0]  ),
	.SLAVE_WR_DATA_READY 	( S_WR_DATA_READY[0]  ),
	.SLAVE_WR_BACK_ID    	( S_WR_BACK_ID   [0]  ),
	.SLAVE_WR_BACK_RESP  	( S_WR_BACK_RESP [0]  ),
	.SLAVE_WR_BACK_VALID 	( S_WR_BACK_VALID[0]  ),
	.SLAVE_WR_BACK_READY 	( S_WR_BACK_READY[0]  ),
	.SLAVE_RD_ADDR_ID    	( S_RD_ADDR_ID   [0]  ),
	.SLAVE_RD_ADDR       	( S_RD_ADDR      [0]  ),
	.SLAVE_RD_ADDR_LEN   	( S_RD_ADDR_LEN  [0]  ),
	.SLAVE_RD_ADDR_BURST 	( S_RD_ADDR_BURST[0]  ),
	.SLAVE_RD_ADDR_VALID 	( S_RD_ADDR_VALID[0]  ),
	.SLAVE_RD_ADDR_READY 	( S_RD_ADDR_READY[0]  ),
	.SLAVE_RD_BACK_ID    	( S_RD_BACK_ID   [0]  ),
	.SLAVE_RD_DATA       	( S_RD_DATA      [0]  ),
	.SLAVE_RD_DATA_RESP  	( S_RD_DATA_RESP [0]  ),
	.SLAVE_RD_DATA_LAST  	( S_RD_DATA_LAST [0]  ),
	.SLAVE_RD_DATA_VALID 	( S_RD_DATA_VALID[0]  ),
	.SLAVE_RD_DATA_READY 	( S_RD_DATA_READY[0]  )
);

axi_slave_sim S1(
    .SLAVE_CLK          (S_CLK          [1]),
    .SLAVE_RSTN         (S_RSTN         [1]),
    .SLAVE_WR_ADDR_ID   (S_WR_ADDR_ID   [1]),
    .SLAVE_WR_ADDR      (S_WR_ADDR      [1]),
    .SLAVE_WR_ADDR_LEN  (S_WR_ADDR_LEN  [1]),
    .SLAVE_WR_ADDR_BURST(S_WR_ADDR_BURST[1]),
    .SLAVE_WR_ADDR_VALID(S_WR_ADDR_VALID[1]),
    .SLAVE_WR_ADDR_READY(S_WR_ADDR_READY[1]),
    .SLAVE_WR_DATA      (S_WR_DATA      [1]),
    .SLAVE_WR_STRB      (S_WR_STRB      [1]),
    .SLAVE_WR_DATA_LAST (S_WR_DATA_LAST [1]),
    .SLAVE_WR_DATA_VALID(S_WR_DATA_VALID[1]),
    .SLAVE_WR_DATA_READY(S_WR_DATA_READY[1]),
    .SLAVE_WR_BACK_ID   (S_WR_BACK_ID   [1]),
    .SLAVE_WR_BACK_RESP (S_WR_BACK_RESP [1]),
    .SLAVE_WR_BACK_VALID(S_WR_BACK_VALID[1]),
    .SLAVE_WR_BACK_READY(S_WR_BACK_READY[1]),
    .SLAVE_RD_ADDR_ID   (S_RD_ADDR_ID   [1]),
    .SLAVE_RD_ADDR      (S_RD_ADDR      [1]),
    .SLAVE_RD_ADDR_LEN  (S_RD_ADDR_LEN  [1]),
    .SLAVE_RD_ADDR_BURST(S_RD_ADDR_BURST[1]),
    .SLAVE_RD_ADDR_VALID(S_RD_ADDR_VALID[1]),
    .SLAVE_RD_ADDR_READY(S_RD_ADDR_READY[1]),
    .SLAVE_RD_BACK_ID   (S_RD_BACK_ID   [1]),
    .SLAVE_RD_DATA      (S_RD_DATA      [1]),
    .SLAVE_RD_DATA_RESP (S_RD_DATA_RESP [1]),
    .SLAVE_RD_DATA_LAST (S_RD_DATA_LAST [1]),
    .SLAVE_RD_DATA_VALID(S_RD_DATA_VALID[1]),
    .SLAVE_RD_DATA_READY(S_RD_DATA_READY[1])
);

axi_slave_sim S2(
    .SLAVE_CLK          (S_CLK          [2]),
    .SLAVE_RSTN         (S_RSTN         [2]),
    .SLAVE_WR_ADDR_ID   (S_WR_ADDR_ID   [2]),
    .SLAVE_WR_ADDR      (S_WR_ADDR      [2]),
    .SLAVE_WR_ADDR_LEN  (S_WR_ADDR_LEN  [2]),
    .SLAVE_WR_ADDR_BURST(S_WR_ADDR_BURST[2]),
    .SLAVE_WR_ADDR_VALID(S_WR_ADDR_VALID[2]),
    .SLAVE_WR_ADDR_READY(S_WR_ADDR_READY[2]),
    .SLAVE_WR_DATA      (S_WR_DATA      [2]),
    .SLAVE_WR_STRB      (S_WR_STRB      [2]),
    .SLAVE_WR_DATA_LAST (S_WR_DATA_LAST [2]),
    .SLAVE_WR_DATA_VALID(S_WR_DATA_VALID[2]),
    .SLAVE_WR_DATA_READY(S_WR_DATA_READY[2]),
    .SLAVE_WR_BACK_ID   (S_WR_BACK_ID   [2]),
    .SLAVE_WR_BACK_RESP (S_WR_BACK_RESP [2]),
    .SLAVE_WR_BACK_VALID(S_WR_BACK_VALID[2]),
    .SLAVE_WR_BACK_READY(S_WR_BACK_READY[2]),
    .SLAVE_RD_ADDR_ID   (S_RD_ADDR_ID   [2]),
    .SLAVE_RD_ADDR      (S_RD_ADDR      [2]),
    .SLAVE_RD_ADDR_LEN  (S_RD_ADDR_LEN  [2]),
    .SLAVE_RD_ADDR_BURST(S_RD_ADDR_BURST[2]),
    .SLAVE_RD_ADDR_VALID(S_RD_ADDR_VALID[2]),
    .SLAVE_RD_ADDR_READY(S_RD_ADDR_READY[2]),
    .SLAVE_RD_BACK_ID   (S_RD_BACK_ID   [2]),
    .SLAVE_RD_DATA      (S_RD_DATA      [2]),
    .SLAVE_RD_DATA_RESP (S_RD_DATA_RESP [2]),
    .SLAVE_RD_DATA_LAST (S_RD_DATA_LAST [2]),
    .SLAVE_RD_DATA_VALID(S_RD_DATA_VALID[2]),
    .SLAVE_RD_DATA_READY(S_RD_DATA_READY[2])
);

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

M24AA04 M24AA04_inst(1'b0, 1'b0, 1'b0, 1'b0, sda, sda_slave_out, sda_memory_ctrl, scl, ~rstn);

endmodule