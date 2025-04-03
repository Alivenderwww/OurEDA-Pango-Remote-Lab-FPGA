module axi_interconnect #(
    parameter M_ID    = 2,
    parameter M_WIDTH = 2,
    parameter S_WIDTH = 3,
    parameter [31:0] START_ADDR[0:(2**S_WIDTH-1)] = '{32'h00000000, 32'h10000000, 32'h20000000, 32'h30000000, 32'h40000000, 32'h50000000, 32'h60000000, 32'h70000000},
    parameter [31:0]   END_ADDR[0:(2**S_WIDTH-1)] = '{32'h0FFFFFFF, 32'h1FFFFFFF, 32'h2FFFFFFF, 32'h3FFFFFFF, 32'h4FFFFFFF, 32'h5FFFFFFF, 32'h6FFFFFFF, 32'h7FFFFFFF}
)(
    input  wire BUS_CLK,
    input  wire BUS_RSTN,
    AXI_INF.SYNC_S AXI_M[0:(2**M_WIDTH-1)],
    AXI_INF.SYNC_M AXI_S[0:(2**S_WIDTH-1)]
);
wire BUS_RSTN_SYNC;
rstn_sync rstn_sync_bus (BUS_CLK, BUS_RSTN, BUS_RSTN_SYNC);
AXI_INF #(.ID_WIDTH(M_ID+M_WIDTH)) AXI_B();

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
	.AXI_MASTER  	( AXI_M             ),
	.AXI_BUS     	( AXI_B             )
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
	.AXI_SLAVE   	( AXI_S             ),
	.AXI_BUS     	( AXI_B             )
);

axi_master_arbiter #(
	.M_ID       	( M_ID  ),
	.M_WIDTH    	( M_WIDTH  )
)u_axi_master_arbiter(
	.clk                	( BUS_CLK             ),
	.rstn               	( BUS_RSTN_SYNC       ),
	.AXI_MASTER         	( AXI_M               ),
	.AXI_BUS            	( AXI_B               ),
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
	.AXI_SLAVE         	( AXI_S              ),
	.AXI_BUS           	( AXI_B              ),
	.wr_addr_slave_sel 	( wr_addr_slave_sel  ),
	.wr_data_slave_sel 	( wr_data_slave_sel  ),
	.wr_resp_slave_sel 	( wr_resp_slave_sel  ),
	.rd_addr_slave_sel 	( rd_addr_slave_sel  ),
	.rd_data_slave_sel 	( rd_data_slave_sel  )
);

endmodule //axi_arbiterw
