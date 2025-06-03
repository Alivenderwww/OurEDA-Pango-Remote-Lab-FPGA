module axi_interconnect #(
    parameter M_ID    = 2,
    parameter M_WIDTH = 2,
    parameter S_WIDTH = 3,
    parameter [0:(2**S_WIDTH-1)][31:0] START_ADDR = {32'h00000000, 32'h10000000, 32'h20000000, 32'h30000000, 32'h40000000, 32'h50000000, 32'h60000000, 32'h70000000},
    parameter [0:(2**S_WIDTH-1)][31:0]   END_ADDR = {32'h0FFFFFFF, 32'h1FFFFFFF, 32'h2FFFFFFF, 32'h3FFFFFFF, 32'h4FFFFFFF, 32'h5FFFFFFF, 32'h6FFFFFFF, 32'h7FFFFFFF}
)(
    input  				                 BUS_CLK,
    input  				                 BUS_RSTN,
	input  [(2**M_WIDTH-1):0] [M_ID-1:0] M_WR_ADDR_ID   ,
	input  [(2**M_WIDTH-1):0] [31:0]     M_WR_ADDR      ,
	input  [(2**M_WIDTH-1):0] [ 7:0]     M_WR_ADDR_LEN  ,
	input  [(2**M_WIDTH-1):0] [ 1:0]     M_WR_ADDR_BURST,
	input  [(2**M_WIDTH-1):0]            M_WR_ADDR_VALID,
	output [(2**M_WIDTH-1):0]            M_WR_ADDR_READY,
	input  [(2**M_WIDTH-1):0] [31:0]     M_WR_DATA      ,
	input  [(2**M_WIDTH-1):0] [ 3:0]     M_WR_STRB      ,
	input  [(2**M_WIDTH-1):0]            M_WR_DATA_LAST ,
	input  [(2**M_WIDTH-1):0]            M_WR_DATA_VALID,
	output [(2**M_WIDTH-1):0]            M_WR_DATA_READY,
	output [(2**M_WIDTH-1):0] [M_ID-1:0] M_WR_BACK_ID   ,
	output [(2**M_WIDTH-1):0] [ 1:0]     M_WR_BACK_RESP ,
	output [(2**M_WIDTH-1):0]            M_WR_BACK_VALID,
	input  [(2**M_WIDTH-1):0]            M_WR_BACK_READY,
	input  [(2**M_WIDTH-1):0] [M_ID-1:0] M_RD_ADDR_ID   ,
	input  [(2**M_WIDTH-1):0] [31:0]     M_RD_ADDR      ,
	input  [(2**M_WIDTH-1):0] [ 7:0]     M_RD_ADDR_LEN  ,
	input  [(2**M_WIDTH-1):0] [ 1:0]     M_RD_ADDR_BURST,
	input  [(2**M_WIDTH-1):0]            M_RD_ADDR_VALID,
	output [(2**M_WIDTH-1):0]            M_RD_ADDR_READY,
	output [(2**M_WIDTH-1):0] [M_ID-1:0] M_RD_BACK_ID   ,
	output [(2**M_WIDTH-1):0] [31:0]     M_RD_DATA      ,
	output [(2**M_WIDTH-1):0] [ 1:0]     M_RD_DATA_RESP ,
	output [(2**M_WIDTH-1):0]            M_RD_DATA_LAST ,
	output [(2**M_WIDTH-1):0]            M_RD_DATA_VALID,
	input  [(2**M_WIDTH-1):0]            M_RD_DATA_READY,

	output [(2**S_WIDTH-1):0]  [M_WIDTH+M_ID-1:0] S_WR_ADDR_ID   ,
	output [(2**S_WIDTH-1):0]  [31:0]         	  S_WR_ADDR      ,
	output [(2**S_WIDTH-1):0]  [ 7:0]         	  S_WR_ADDR_LEN  ,
	output [(2**S_WIDTH-1):0]  [ 1:0]         	  S_WR_ADDR_BURST,
	output [(2**S_WIDTH-1):0]                 	  S_WR_ADDR_VALID,
	input  [(2**S_WIDTH-1):0]                 	  S_WR_ADDR_READY,
	output [(2**S_WIDTH-1):0]  [31:0]         	  S_WR_DATA      ,
	output [(2**S_WIDTH-1):0]  [ 3:0]         	  S_WR_STRB      ,
	output [(2**S_WIDTH-1):0]                 	  S_WR_DATA_LAST ,
	output [(2**S_WIDTH-1):0]                 	  S_WR_DATA_VALID,
	input  [(2**S_WIDTH-1):0]                 	  S_WR_DATA_READY,
	input  [(2**S_WIDTH-1):0]  [M_WIDTH+M_ID-1:0] S_WR_BACK_ID   ,
	input  [(2**S_WIDTH-1):0]  [ 1:0]         	  S_WR_BACK_RESP ,
	input  [(2**S_WIDTH-1):0]                 	  S_WR_BACK_VALID,
	output [(2**S_WIDTH-1):0]                 	  S_WR_BACK_READY,
	output [(2**S_WIDTH-1):0]  [M_WIDTH+M_ID-1:0] S_RD_ADDR_ID   ,
	output [(2**S_WIDTH-1):0]  [31:0]         	  S_RD_ADDR      ,
	output [(2**S_WIDTH-1):0]  [ 7:0]         	  S_RD_ADDR_LEN  ,
	output [(2**S_WIDTH-1):0]  [ 1:0]         	  S_RD_ADDR_BURST,
	output [(2**S_WIDTH-1):0]                 	  S_RD_ADDR_VALID,
	input  [(2**S_WIDTH-1):0]                 	  S_RD_ADDR_READY,
	input  [(2**S_WIDTH-1):0]  [M_WIDTH+M_ID-1:0] S_RD_BACK_ID   ,
	input  [(2**S_WIDTH-1):0]  [31:0]         	  S_RD_DATA      ,
	input  [(2**S_WIDTH-1):0]  [ 1:0]         	  S_RD_DATA_RESP ,
	input  [(2**S_WIDTH-1):0]                 	  S_RD_DATA_LAST ,
	input  [(2**S_WIDTH-1):0]                 	  S_RD_DATA_VALID,
	output [(2**S_WIDTH-1):0]                 	  S_RD_DATA_READY 
);
wire BUS_RSTN_SYNC;
rstn_sync rstn_sync_bus (BUS_CLK, BUS_RSTN, BUS_RSTN_SYNC);

wire [M_WIDTH+M_ID-1:0]   B_WR_ADDR_ID   ;
wire [31:0]         	  B_WR_ADDR      ;
wire [ 7:0]         	  B_WR_ADDR_LEN  ;
wire [ 1:0]         	  B_WR_ADDR_BURST;
wire                	  B_WR_ADDR_VALID;
wire                	  B_WR_ADDR_READY;
wire [31:0]         	  B_WR_DATA      ;
wire [ 3:0]         	  B_WR_STRB      ;
wire                	  B_WR_DATA_LAST ;
wire                	  B_WR_DATA_VALID;
wire                	  B_WR_DATA_READY;
wire [M_WIDTH+M_ID-1:0]   B_WR_BACK_ID   ;
wire [ 1:0]         	  B_WR_BACK_RESP ;
wire                	  B_WR_BACK_VALID;
wire                	  B_WR_BACK_READY;
wire [M_WIDTH+M_ID-1:0]   B_RD_ADDR_ID   ;
wire [31:0]         	  B_RD_ADDR      ;
wire [ 7:0]         	  B_RD_ADDR_LEN  ;
wire [ 1:0]         	  B_RD_ADDR_BURST;
wire                	  B_RD_ADDR_VALID;
wire                	  B_RD_ADDR_READY;
wire [M_WIDTH+M_ID-1:0]   B_RD_BACK_ID   ;
wire [31:0]         	  B_RD_DATA      ;
wire [ 1:0]         	  B_RD_DATA_RESP ;
wire                	  B_RD_DATA_LAST ;
wire                	  B_RD_DATA_VALID;
wire                	  B_RD_DATA_READY;

wire [31:0]               TRANS_B_WR_ADDR;
wire [31:0]               TRANS_B_RD_ADDR;

wire [M_WIDTH-1:0]  wr_addr_master_sel;
wire [M_WIDTH-1:0]  wr_data_master_sel;
wire [M_WIDTH-1:0]  wr_resp_master_sel;
wire [M_WIDTH-1:0]  rd_addr_master_sel;
wire [M_WIDTH-1:0]  rd_data_master_sel;
wire [S_WIDTH-1:0]  wr_addr_slave_sel;
wire [S_WIDTH-1:0]  wr_data_slave_sel;
wire [S_WIDTH-1:0]  wr_resp_slave_sel;
wire [S_WIDTH-1:0]  rd_addr_slave_sel;
wire [S_WIDTH-1:0]  rd_data_slave_sel;

axi_master_switch #(
	.M_WIDTH (M_WIDTH),
	.M_ID    (M_ID)
)u_axi_master_switch(
	.wr_addr_sel 	( wr_addr_master_sel),
	.wr_data_sel 	( wr_data_master_sel),
	.wr_resp_sel 	( wr_resp_master_sel),
	.rd_addr_sel 	( rd_addr_master_sel),
	.rd_data_sel 	( rd_data_master_sel),
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
	.BUS_WR_ADDR_ID      (B_WR_ADDR_ID   ),
	.BUS_WR_ADDR         (B_WR_ADDR      ),
	.BUS_WR_ADDR_LEN     (B_WR_ADDR_LEN  ),
	.BUS_WR_ADDR_BURST   (B_WR_ADDR_BURST),
	.BUS_WR_ADDR_VALID   (B_WR_ADDR_VALID),
	.BUS_WR_ADDR_READY   (B_WR_ADDR_READY),
	.BUS_WR_DATA         (B_WR_DATA      ),
	.BUS_WR_STRB         (B_WR_STRB      ),
	.BUS_WR_DATA_LAST    (B_WR_DATA_LAST ),
	.BUS_WR_DATA_VALID   (B_WR_DATA_VALID),
	.BUS_WR_DATA_READY   (B_WR_DATA_READY),
	.BUS_WR_BACK_ID      (B_WR_BACK_ID   ),
	.BUS_WR_BACK_RESP    (B_WR_BACK_RESP ),
	.BUS_WR_BACK_VALID   (B_WR_BACK_VALID),
	.BUS_WR_BACK_READY   (B_WR_BACK_READY),
	.BUS_RD_ADDR_ID      (B_RD_ADDR_ID   ),
	.BUS_RD_ADDR         (B_RD_ADDR      ),
	.BUS_RD_ADDR_LEN     (B_RD_ADDR_LEN  ),
	.BUS_RD_ADDR_BURST   (B_RD_ADDR_BURST),
	.BUS_RD_ADDR_VALID   (B_RD_ADDR_VALID),
	.BUS_RD_ADDR_READY   (B_RD_ADDR_READY),
	.BUS_RD_BACK_ID      (B_RD_BACK_ID   ),
	.BUS_RD_DATA         (B_RD_DATA      ),
	.BUS_RD_DATA_RESP    (B_RD_DATA_RESP ),
	.BUS_RD_DATA_LAST    (B_RD_DATA_LAST ),
	.BUS_RD_DATA_VALID   (B_RD_DATA_VALID),
	.BUS_RD_DATA_READY   (B_RD_DATA_READY)
);

axi_slave_switch #(
    .S_WIDTH(S_WIDTH),
    .S_ID   (M_ID+M_WIDTH)
)u_axi_slave_switch(
	.wr_addr_sel 	( wr_addr_slave_sel ),
	.wr_data_sel 	( wr_data_slave_sel ),
	.wr_resp_sel 	( wr_resp_slave_sel ),
	.rd_addr_sel 	( rd_addr_slave_sel ),
	.rd_data_sel 	( rd_data_slave_sel ),
	.SLAVE_WR_ADDR_ID    (S_WR_ADDR_ID   ),
	.SLAVE_WR_ADDR       (S_WR_ADDR      ),
	.SLAVE_WR_ADDR_LEN   (S_WR_ADDR_LEN  ),
	.SLAVE_WR_ADDR_BURST (S_WR_ADDR_BURST),
	.SLAVE_WR_ADDR_VALID (S_WR_ADDR_VALID),
	.SLAVE_WR_ADDR_READY (S_WR_ADDR_READY),
	.SLAVE_WR_DATA       (S_WR_DATA      ),
	.SLAVE_WR_STRB       (S_WR_STRB      ),
	.SLAVE_WR_DATA_LAST  (S_WR_DATA_LAST ),
	.SLAVE_WR_DATA_VALID (S_WR_DATA_VALID),
	.SLAVE_WR_DATA_READY (S_WR_DATA_READY),
	.SLAVE_WR_BACK_ID    (S_WR_BACK_ID   ),
	.SLAVE_WR_BACK_RESP  (S_WR_BACK_RESP ),
	.SLAVE_WR_BACK_VALID (S_WR_BACK_VALID),
	.SLAVE_WR_BACK_READY (S_WR_BACK_READY),
	.SLAVE_RD_ADDR_ID    (S_RD_ADDR_ID   ),
	.SLAVE_RD_ADDR       (S_RD_ADDR      ),
	.SLAVE_RD_ADDR_LEN   (S_RD_ADDR_LEN  ),
	.SLAVE_RD_ADDR_BURST (S_RD_ADDR_BURST),
	.SLAVE_RD_ADDR_VALID (S_RD_ADDR_VALID),
	.SLAVE_RD_ADDR_READY (S_RD_ADDR_READY),
	.SLAVE_RD_BACK_ID    (S_RD_BACK_ID   ),
	.SLAVE_RD_DATA       (S_RD_DATA      ),
	.SLAVE_RD_DATA_RESP  (S_RD_DATA_RESP ),
	.SLAVE_RD_DATA_LAST  (S_RD_DATA_LAST ),
	.SLAVE_RD_DATA_VALID (S_RD_DATA_VALID),
	.SLAVE_RD_DATA_READY (S_RD_DATA_READY),
	.BUS_WR_ADDR_ID      (B_WR_ADDR_ID   ),
	.BUS_WR_ADDR         (TRANS_B_WR_ADDR),
	.BUS_WR_ADDR_LEN     (B_WR_ADDR_LEN  ),
	.BUS_WR_ADDR_BURST   (B_WR_ADDR_BURST),
	.BUS_WR_ADDR_VALID   (B_WR_ADDR_VALID),
	.BUS_WR_ADDR_READY   (B_WR_ADDR_READY),
	.BUS_WR_DATA         (B_WR_DATA      ),
	.BUS_WR_STRB         (B_WR_STRB      ),
	.BUS_WR_DATA_LAST    (B_WR_DATA_LAST ),
	.BUS_WR_DATA_VALID   (B_WR_DATA_VALID),
	.BUS_WR_DATA_READY   (B_WR_DATA_READY),
	.BUS_WR_BACK_ID      (B_WR_BACK_ID   ),
	.BUS_WR_BACK_RESP    (B_WR_BACK_RESP ),
	.BUS_WR_BACK_VALID   (B_WR_BACK_VALID),
	.BUS_WR_BACK_READY   (B_WR_BACK_READY),
	.BUS_RD_ADDR_ID      (B_RD_ADDR_ID   ),
	.BUS_RD_ADDR         (TRANS_B_RD_ADDR),
	.BUS_RD_ADDR_LEN     (B_RD_ADDR_LEN  ),
	.BUS_RD_ADDR_BURST   (B_RD_ADDR_BURST),
	.BUS_RD_ADDR_VALID   (B_RD_ADDR_VALID),
	.BUS_RD_ADDR_READY   (B_RD_ADDR_READY),
	.BUS_RD_BACK_ID      (B_RD_BACK_ID   ),
	.BUS_RD_DATA         (B_RD_DATA      ),
	.BUS_RD_DATA_RESP    (B_RD_DATA_RESP ),
	.BUS_RD_DATA_LAST    (B_RD_DATA_LAST ),
	.BUS_RD_DATA_VALID   (B_RD_DATA_VALID),
	.BUS_RD_DATA_READY   (B_RD_DATA_READY)
);

axi_master_arbiter #(
	.M_ID       	( M_ID  ),
	.M_WIDTH    	( M_WIDTH  )
)u_axi_master_arbiter(
	.clk                	( BUS_CLK             ),
	.rstn               	( BUS_RSTN_SYNC       ),
    .MASTER_WR_ADDR_VALID	( M_WR_ADDR_VALID     ),
    .MASTER_RD_ADDR_VALID	( M_RD_ADDR_VALID     ),
    .BUS_WR_ADDR_VALID		( B_WR_ADDR_VALID	  ),
    .BUS_WR_ADDR_READY		( B_WR_ADDR_READY	  ),
    .BUS_WR_DATA_VALID		( B_WR_DATA_VALID	  ),
    .BUS_WR_DATA_READY		( B_WR_DATA_READY	  ),
    .BUS_WR_DATA_LAST		( B_WR_DATA_LAST	  ),
    .BUS_WR_BACK_ID			( B_WR_BACK_ID		  ),
    .BUS_RD_ADDR_VALID		( B_RD_ADDR_VALID	  ),
    .BUS_RD_ADDR_READY		( B_RD_ADDR_READY	  ),
    .BUS_RD_BACK_ID			( B_RD_BACK_ID		  ),
	.wr_addr_master_sel 	( wr_addr_master_sel  ),
	.wr_data_master_sel 	( wr_data_master_sel  ),
	.wr_resp_master_sel 	( wr_resp_master_sel  ),
	.rd_addr_master_sel 	( rd_addr_master_sel  ),
	.rd_data_master_sel 	( rd_data_master_sel  )
);

axi_slave_arbiter #(
	.S_WIDTH      	( S_WIDTH  ),
    .START_ADDR		(START_ADDR	),
    .END_ADDR		(END_ADDR	)
)u_axi_slave_arbiter(
	.clk               	( BUS_CLK            ),
	.rstn              	( BUS_RSTN_SYNC      ),
    .SLAVE_WR_BACK_VALID( S_WR_BACK_VALID	 ),
    .SLAVE_RD_DATA_VALID( S_RD_DATA_VALID	 ),
    .BUS_WR_ADDR		( B_WR_ADDR			 ),
    .BUS_WR_BACK_VALID	( B_WR_BACK_VALID	 ),
    .BUS_WR_BACK_READY	( B_WR_BACK_READY	 ),
    .BUS_RD_ADDR		( B_RD_ADDR			 ),
	.TRANS_WR_ADDR      ( TRANS_B_WR_ADDR    ),
	.TRANS_RD_ADDR		( TRANS_B_RD_ADDR    ),
	.wr_addr_slave_sel 	( wr_addr_slave_sel  ),
	.wr_data_slave_sel 	( wr_data_slave_sel  ),
	.wr_resp_slave_sel 	( wr_resp_slave_sel  ),
	.rd_addr_slave_sel 	( rd_addr_slave_sel  ),
	.rd_data_slave_sel 	( rd_data_slave_sel  )
);

endmodule //axi_arbiterw
