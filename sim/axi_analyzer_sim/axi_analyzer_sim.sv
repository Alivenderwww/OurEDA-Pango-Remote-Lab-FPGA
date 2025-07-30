`timescale 1ns/1ps
module axi_analyzer_sim ();

localparam M_WIDTH  = 2;
localparam S_WIDTH  = 1;
localparam M_ID     = 2;
localparam [0:(2**S_WIDTH-1)][31:0] START_ADDR = '{32'h00000000, 32'h10000000};
localparam [0:(2**S_WIDTH-1)][31:0]   END_ADDR = '{32'h0FFFFFFF, 32'h1FFFFFFF};

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

reg [7:0] digital_in;

wire DMA1_rd_clk                 ;
wire DMA1_capture_on             ;
wire DMA1_capture_rst            ;
wire DMA1_rd_data_ready          ;
wire DMA1_rd_data_valid          ;
wire [31:0] DMA1_rd_data         ;

reg  BUS_CLK    ;
reg  BUS_RSTN   ;

always #15 BUS_CLK = ~BUS_CLK;

initial begin
        BUS_CLK = 0;
        BUS_RSTN = 0;
#50000  BUS_RSTN = 1;
end

initial begin
    #300 M0.set_clk(5);
    #300 M2.set_clk(5);
    #300 M3.set_clk(5);
    #5000
    #300 M0.set_rd_data_channel(31);
    #300 M0.set_wr_data_channel(31);
    #300 M2.set_rd_data_channel(31);
    #300 M2.set_wr_data_channel(31);
    #300 M3.set_rd_data_channel(31);
    #300 M3.set_wr_data_channel(31);
    while (~S_RSTN[0]) #500;
    while (~S_RSTN[1]) #500;
    
    #300 M0.send_wr_addr(2, 32'h10000000, 8'd0, 2'b00);
    #300 M0.send_wr_data(32'h00000000, 4'b1111);

    #300 M0.send_wr_addr(3, 32'h10000001, 8'd0, 2'b00);
    #300 M0.send_wr_data({30'b0, 2'b00}, 4'b1111); //00: 全局与

    #300 M0.send_wr_addr(3, 32'h10000002, 8'd0, 2'b00);
    #300 M0.send_wr_data(32'h00001000-1, 4'b1111);

    #300 M0.send_wr_addr(3, 32'h10000003, 8'd0, 2'b00);
    #300 M0.send_wr_data(32'd100, 4'b1111);

    #300 M0.send_wr_addr(3, 32'h10000012, 8'd0, 2'b00);
    #300 M0.send_wr_data({26'b0, 3'b000, 3'b000}, 4'b1111); //[0]==0

    #300 M0.send_wr_addr(3, 32'h10000013, 8'd0, 2'b00);
    #300 M0.send_wr_data({26'b0, 3'b000, 3'b011}, 4'b1111); //[1]==up

    #8000 M0.send_wr_addr(2, 32'h10000000, 8'd0, 2'b00);
	#300 M0.send_wr_data(32'h00000001, 4'b1111);

	#5000000
	#80000 M0.send_rd_addr(2, 32'h11000000, 8'd255, 2'b01);
	#80000 M0.send_rd_addr(2, 32'h11000100, 8'd255, 2'b01);
	#80000 M0.send_rd_addr(2, 32'h11000200, 8'd255, 2'b01);
	#80000 M0.send_rd_addr(2, 32'h11000300, 8'd255, 2'b01);
end

axi_master_sim #(
	.ID_WIDTH(M_ID)
)M0(
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

axi_master_write_dma M1(
.clk                  (BUS_CLK             ),
.rstn                 (BUS_RSTN             ),
.START_WRITE_ADDR	  (32'h00000000),
.END_WRITE_ADDR	      (32'h00001000-1),
.rd_clk               (DMA1_rd_clk          ),
.rd_capture_on		  (1'b1      ),
.rd_capture_rst		  (1'b0      ),
.rd_data_ready        (DMA1_rd_data_ready),
.rd_data_valid        (DMA1_rd_data_valid),
.rd_data              (DMA1_rd_data      ),
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

axi_master_sim #(
	.ID_WIDTH(M_ID)
)M2(
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

axi_master_sim #(
	.ID_WIDTH(M_ID)
)M3(
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

DDR_axi_sim S0(
	.ddr_ref_clk                ( BUS_CLK             ),
	.rst_n                	    ( BUS_RSTN            ),
	.DDR_SLAVE_CLK           	( S_CLK          [0]  ),
	.DDR_SLAVE_RSTN          	( S_RSTN         [0]  ),
	.DDR_SLAVE_WR_ADDR_ID    	( S_WR_ADDR_ID   [0]  ),
	.DDR_SLAVE_WR_ADDR       	( S_WR_ADDR      [0]  ),
	.DDR_SLAVE_WR_ADDR_LEN   	( S_WR_ADDR_LEN  [0]  ),
	.DDR_SLAVE_WR_ADDR_BURST 	( S_WR_ADDR_BURST[0]  ),
	.DDR_SLAVE_WR_ADDR_VALID 	( S_WR_ADDR_VALID[0]  ),
	.DDR_SLAVE_WR_ADDR_READY 	( S_WR_ADDR_READY[0]  ),
	.DDR_SLAVE_WR_DATA       	( S_WR_DATA      [0]  ),
	.DDR_SLAVE_WR_STRB       	( S_WR_STRB      [0]  ),
	.DDR_SLAVE_WR_DATA_LAST  	( S_WR_DATA_LAST [0]  ),
	.DDR_SLAVE_WR_DATA_VALID 	( S_WR_DATA_VALID[0]  ),
	.DDR_SLAVE_WR_DATA_READY 	( S_WR_DATA_READY[0]  ),
	.DDR_SLAVE_WR_BACK_ID    	( S_WR_BACK_ID   [0]  ),
	.DDR_SLAVE_WR_BACK_RESP  	( S_WR_BACK_RESP [0]  ),
	.DDR_SLAVE_WR_BACK_VALID 	( S_WR_BACK_VALID[0]  ),
	.DDR_SLAVE_WR_BACK_READY 	( S_WR_BACK_READY[0]  ),
	.DDR_SLAVE_RD_ADDR_ID    	( S_RD_ADDR_ID   [0]  ),
	.DDR_SLAVE_RD_ADDR       	( S_RD_ADDR      [0]  ),
	.DDR_SLAVE_RD_ADDR_LEN   	( S_RD_ADDR_LEN  [0]  ),
	.DDR_SLAVE_RD_ADDR_BURST 	( S_RD_ADDR_BURST[0]  ),
	.DDR_SLAVE_RD_ADDR_VALID 	( S_RD_ADDR_VALID[0]  ),
	.DDR_SLAVE_RD_ADDR_READY 	( S_RD_ADDR_READY[0]  ),
	.DDR_SLAVE_RD_BACK_ID    	( S_RD_BACK_ID   [0]  ),
	.DDR_SLAVE_RD_DATA       	( S_RD_DATA      [0]  ),
	.DDR_SLAVE_RD_DATA_RESP  	( S_RD_DATA_RESP [0]  ),
	.DDR_SLAVE_RD_DATA_LAST  	( S_RD_DATA_LAST [0]  ),
	.DDR_SLAVE_RD_DATA_VALID 	( S_RD_DATA_VALID[0]  ),
	.DDR_SLAVE_RD_DATA_READY 	( S_RD_DATA_READY[0]  )
);

Analazer u_Analazer(
	.clk                          	( BUS_CLK             ),
	.rstn                         	( BUS_RSTN            ),
	.digital_in                   	( digital_in          ),
	.rd_clk                         ( DMA1_rd_clk         ),
	.rd_data_ready                  ( DMA1_rd_data_ready  ),
	.rd_data_valid                  ( DMA1_rd_data_valid  ),
	.rd_data                        ( DMA1_rd_data        ),
	.ANALYZER_SLAVE_CLK           	( S_CLK          [1]  ),
	.ANALYZER_SLAVE_RSTN          	( S_RSTN         [1]  ),
	.ANALYZER_SLAVE_WR_ADDR_ID    	( S_WR_ADDR_ID   [1]  ),
	.ANALYZER_SLAVE_WR_ADDR       	( S_WR_ADDR      [1]  ),
	.ANALYZER_SLAVE_WR_ADDR_LEN   	( S_WR_ADDR_LEN  [1]  ),
	.ANALYZER_SLAVE_WR_ADDR_BURST 	( S_WR_ADDR_BURST[1]  ),
	.ANALYZER_SLAVE_WR_ADDR_VALID 	( S_WR_ADDR_VALID[1]  ),
	.ANALYZER_SLAVE_WR_ADDR_READY 	( S_WR_ADDR_READY[1]  ),
	.ANALYZER_SLAVE_WR_DATA       	( S_WR_DATA      [1]  ),
	.ANALYZER_SLAVE_WR_STRB       	( S_WR_STRB      [1]  ),
	.ANALYZER_SLAVE_WR_DATA_LAST  	( S_WR_DATA_LAST [1]  ),
	.ANALYZER_SLAVE_WR_DATA_VALID 	( S_WR_DATA_VALID[1]  ),
	.ANALYZER_SLAVE_WR_DATA_READY 	( S_WR_DATA_READY[1]  ),
	.ANALYZER_SLAVE_WR_BACK_ID    	( S_WR_BACK_ID   [1]  ),
	.ANALYZER_SLAVE_WR_BACK_RESP  	( S_WR_BACK_RESP [1]  ),
	.ANALYZER_SLAVE_WR_BACK_VALID 	( S_WR_BACK_VALID[1]  ),
	.ANALYZER_SLAVE_WR_BACK_READY 	( S_WR_BACK_READY[1]  ),
	.ANALYZER_SLAVE_RD_ADDR_ID    	( S_RD_ADDR_ID   [1]  ),
	.ANALYZER_SLAVE_RD_ADDR       	( S_RD_ADDR      [1]  ),
	.ANALYZER_SLAVE_RD_ADDR_LEN   	( S_RD_ADDR_LEN  [1]  ),
	.ANALYZER_SLAVE_RD_ADDR_BURST 	( S_RD_ADDR_BURST[1]  ),
	.ANALYZER_SLAVE_RD_ADDR_VALID 	( S_RD_ADDR_VALID[1]  ),
	.ANALYZER_SLAVE_RD_ADDR_READY 	( S_RD_ADDR_READY[1]  ),
	.ANALYZER_SLAVE_RD_BACK_ID    	( S_RD_BACK_ID   [1]  ),
	.ANALYZER_SLAVE_RD_DATA       	( S_RD_DATA      [1]  ),
	.ANALYZER_SLAVE_RD_DATA_RESP  	( S_RD_DATA_RESP [1]  ),
	.ANALYZER_SLAVE_RD_DATA_LAST  	( S_RD_DATA_LAST [1]  ),
	.ANALYZER_SLAVE_RD_DATA_VALID 	( S_RD_DATA_VALID[1]  ),
	.ANALYZER_SLAVE_RD_DATA_READY 	( S_RD_DATA_READY[1]  )
);

axi_bus #(
	.M_ID       	(M_ID      ),
	.M_WIDTH    	(M_WIDTH   ),
	.S_WIDTH    	(S_WIDTH   ),
	.START_ADDR 	(START_ADDR),
	.END_ADDR   	(END_ADDR  ),
	.M_ASYNC_ON     ({1'b1, 1'b1, 1'b1, 1'b1}),
	.S_ASYNC_ON     ({1'b1, 1'b1})
) u_axi_bus(
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

initial digital_in = 8'h00;
always begin
	#50000 digital_in[0] = $random;
	#50000 digital_in[1] = $random;
	#50000 digital_in[2] = $random;
	#50000 digital_in[3] = $random;
	#50000 digital_in[4] = $random;
	#50000 digital_in[5] = $random;
	#50000 digital_in[6] = $random;
	#50000 digital_in[7] = $random;
end

endmodule