module axi_bus #( //AXI顶层总线。支持主从机自设时钟域，内部设置FIFO。支持out-standing传输暂存，从机可选择性支持out-of-order乱序执行，目前不支持主机interleaving交织。
	parameter M_ID     = 2,
    parameter M_WIDTH  = 2,
    parameter S_WIDTH  = 3,
    parameter [31:0]   START_ADDR[0:(2**S_WIDTH-1)] = '{32'h00000000, 32'h10000000, 32'h20000000, 32'h30000000},
    parameter [31:0]     END_ADDR[0:(2**S_WIDTH-1)] = '{32'h0FFFFFFF, 32'h1FFFFFFF, 32'h2FFFFFFF, 32'h3FFFFFFF}
)(
	input wire BUS_CLK,
	input wire BUS_RSTN,
	AXI_INF.INTER_M  AXI_M[0:(2**M_WIDTH-1)],
	AXI_INF.INTER_S  AXI_S[0:(2**S_WIDTH-1)],
	output wire [4:0] M_fifo_empty_flag[0:(2**M_WIDTH-1)],
	output wire [4:0] S_fifo_empty_flag[0:(2**S_WIDTH-1)]
);

AXI_INF #(.ID_WIDTH(M_ID        )) AXI_M_BUS[0:(2**M_WIDTH-1)]();
AXI_INF #(.ID_WIDTH(M_ID+M_WIDTH)) AXI_S_BUS[0:(2**S_WIDTH-1)]();

axi_clock_converter #(
	.M_WIDTH 	( M_WIDTH  ),
	.S_WIDTH 	( S_WIDTH  ))
u_axi_clock_converter(
	.BUS_CLK           	( BUS_CLK            ),
	.BUS_RSTN          	( BUS_RSTN           ),
	.AXI_M_BUS         	( AXI_M_BUS          ),
	.AXI_S_BUS         	( AXI_S_BUS          ),
	.AXI_M             	( AXI_M              ),
	.AXI_S             	( AXI_S              ),
	.M_fifo_empty_flag 	( M_fifo_empty_flag  ),
	.S_fifo_empty_flag 	( S_fifo_empty_flag  )
);

axi_interconnect #(
	.M_ID         	( M_ID        ),
	.M_WIDTH      	( M_WIDTH     ),
	.S_WIDTH      	( S_WIDTH     ),
	.START_ADDR 	( START_ADDR),
	.END_ADDR   	( END_ADDR  ))
u_axi_interconnect(
	.BUS_CLK  	( BUS_CLK   ),
	.BUS_RSTN 	( BUS_RSTN  ),
	.AXI_M    	( AXI_M_BUS ),
	.AXI_S    	( AXI_S_BUS )
);


endmodule