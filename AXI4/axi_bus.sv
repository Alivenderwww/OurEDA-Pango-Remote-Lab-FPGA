module axi_bus #( //AXI顶层总线。支持主从机自设时钟域，内部设置FIFO。支持out-standing传输暂存，从机可选择性支持out-of-order乱序执行，目前不支持主机interleaving交织。
	parameter M_ID     = 2,
    parameter M_WIDTH  = 2,
    parameter S_WIDTH  = 3,
    parameter [0:(2**M_WIDTH-1)]       M_ASYNC_ON = {1'b1,1'b1,1'b1,1'b1},
    parameter [0:(2**S_WIDTH-1)]       S_ASYNC_ON = {1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1,1'b1},
    parameter [0:(2**S_WIDTH-1)][31:0] START_ADDR = {32'h00000000, 32'h10000000, 32'h20000000, 32'h30000000, 32'h40000000, 32'h50000000, 32'h60000000, 32'h70000000},
    parameter [0:(2**S_WIDTH-1)][31:0]   END_ADDR = {32'h0FFFFFFF, 32'h1FFFFFFF, 32'h2FFFFFFF, 32'h3FFFFFFF, 32'h4FFFFFFF, 32'h5FFFFFFF, 32'h6FFFFFFF, 32'h7FFFFFFF}
)(
	input				                      BUS_CLK			  ,
	input				                      BUS_RSTN			  ,
    input  [(2**M_WIDTH-1):0]  				  MASTER_CLK          ,
    input  [(2**M_WIDTH-1):0]  				  MASTER_RSTN         ,
    input  [(2**M_WIDTH-1):0]  [M_ID-1:0]     MASTER_WR_ADDR_ID   ,
    input  [(2**M_WIDTH-1):0]  [31:0]         MASTER_WR_ADDR      ,
    input  [(2**M_WIDTH-1):0]  [ 7:0]         MASTER_WR_ADDR_LEN  ,
    input  [(2**M_WIDTH-1):0]  [ 1:0]         MASTER_WR_ADDR_BURST,
    input  [(2**M_WIDTH-1):0]                 MASTER_WR_ADDR_VALID,
    output [(2**M_WIDTH-1):0]                 MASTER_WR_ADDR_READY,
    input  [(2**M_WIDTH-1):0]  [31:0]         MASTER_WR_DATA      ,
    input  [(2**M_WIDTH-1):0]  [ 3:0]         MASTER_WR_STRB      ,
    input  [(2**M_WIDTH-1):0]                 MASTER_WR_DATA_LAST ,
    input  [(2**M_WIDTH-1):0]                 MASTER_WR_DATA_VALID,
    output [(2**M_WIDTH-1):0]                 MASTER_WR_DATA_READY,
    output [(2**M_WIDTH-1):0]  [M_ID-1:0]     MASTER_WR_BACK_ID   ,
    output [(2**M_WIDTH-1):0]  [ 1:0]         MASTER_WR_BACK_RESP ,
    output [(2**M_WIDTH-1):0]                 MASTER_WR_BACK_VALID,
    input  [(2**M_WIDTH-1):0]                 MASTER_WR_BACK_READY,
    input  [(2**M_WIDTH-1):0]  [M_ID-1:0]     MASTER_RD_ADDR_ID   ,
    input  [(2**M_WIDTH-1):0]  [31:0]         MASTER_RD_ADDR      ,
    input  [(2**M_WIDTH-1):0]  [ 7:0]         MASTER_RD_ADDR_LEN  ,
    input  [(2**M_WIDTH-1):0]  [ 1:0]         MASTER_RD_ADDR_BURST,
    input  [(2**M_WIDTH-1):0]                 MASTER_RD_ADDR_VALID,
    output [(2**M_WIDTH-1):0]                 MASTER_RD_ADDR_READY,
    output [(2**M_WIDTH-1):0]  [M_ID-1:0]     MASTER_RD_BACK_ID   ,
    output [(2**M_WIDTH-1):0]  [31:0]         MASTER_RD_DATA      ,
    output [(2**M_WIDTH-1):0]  [ 1:0]         MASTER_RD_DATA_RESP ,
    output [(2**M_WIDTH-1):0]                 MASTER_RD_DATA_LAST ,
    output [(2**M_WIDTH-1):0]                 MASTER_RD_DATA_VALID,
    input  [(2**M_WIDTH-1):0]                 MASTER_RD_DATA_READY,
	
    input  [(2**S_WIDTH-1):0]  				      SLAVE_CLK          ,
    input  [(2**S_WIDTH-1):0]  				      SLAVE_RSTN         ,
    output [(2**S_WIDTH-1):0]  [M_WIDTH+M_ID-1:0] SLAVE_WR_ADDR_ID   ,
    output [(2**S_WIDTH-1):0]  [31:0]             SLAVE_WR_ADDR      ,
    output [(2**S_WIDTH-1):0]  [ 7:0]             SLAVE_WR_ADDR_LEN  ,
    output [(2**S_WIDTH-1):0]  [ 1:0]             SLAVE_WR_ADDR_BURST,
    output [(2**S_WIDTH-1):0]                     SLAVE_WR_ADDR_VALID,
    input  [(2**S_WIDTH-1):0]                     SLAVE_WR_ADDR_READY,
    output [(2**S_WIDTH-1):0]  [31:0]             SLAVE_WR_DATA      ,
    output [(2**S_WIDTH-1):0]  [ 3:0]             SLAVE_WR_STRB      ,
    output [(2**S_WIDTH-1):0]                     SLAVE_WR_DATA_LAST ,
    output [(2**S_WIDTH-1):0]                     SLAVE_WR_DATA_VALID,
    input  [(2**S_WIDTH-1):0]                     SLAVE_WR_DATA_READY,
    input  [(2**S_WIDTH-1):0]  [M_WIDTH+M_ID-1:0] SLAVE_WR_BACK_ID   ,
    input  [(2**S_WIDTH-1):0]  [ 1:0]             SLAVE_WR_BACK_RESP ,
    input  [(2**S_WIDTH-1):0]                     SLAVE_WR_BACK_VALID,
    output [(2**S_WIDTH-1):0]                     SLAVE_WR_BACK_READY,
    output [(2**S_WIDTH-1):0]  [M_WIDTH+M_ID-1:0] SLAVE_RD_ADDR_ID   ,
    output [(2**S_WIDTH-1):0]  [31:0]             SLAVE_RD_ADDR      ,
    output [(2**S_WIDTH-1):0]  [ 7:0]             SLAVE_RD_ADDR_LEN  ,
    output [(2**S_WIDTH-1):0]  [ 1:0]             SLAVE_RD_ADDR_BURST,
    output [(2**S_WIDTH-1):0]                     SLAVE_RD_ADDR_VALID,
    input  [(2**S_WIDTH-1):0]                     SLAVE_RD_ADDR_READY,
    input  [(2**S_WIDTH-1):0]  [M_WIDTH+M_ID-1:0] SLAVE_RD_BACK_ID   ,
    input  [(2**S_WIDTH-1):0]  [31:0]             SLAVE_RD_DATA      ,
    input  [(2**S_WIDTH-1):0]  [ 1:0]             SLAVE_RD_DATA_RESP ,
    input  [(2**S_WIDTH-1):0]                     SLAVE_RD_DATA_LAST ,
    input  [(2**S_WIDTH-1):0]                     SLAVE_RD_DATA_VALID,
    output [(2**S_WIDTH-1):0]                     SLAVE_RD_DATA_READY,
	output [(2**M_WIDTH-1):0] [4:0] M_fifo_empty_flag,
	output [(2**S_WIDTH-1):0] [4:0] S_fifo_empty_flag
);

wire [(2**M_WIDTH-1):0]  [M_ID-1:0]           M_B_WR_ADDR_ID   ;
wire [(2**M_WIDTH-1):0]  [31:0]         	  M_B_WR_ADDR      ;
wire [(2**M_WIDTH-1):0]  [ 7:0]         	  M_B_WR_ADDR_LEN  ;
wire [(2**M_WIDTH-1):0]  [ 1:0]         	  M_B_WR_ADDR_BURST;
wire [(2**M_WIDTH-1):0]                 	  M_B_WR_ADDR_VALID;
wire [(2**M_WIDTH-1):0]                 	  M_B_WR_ADDR_READY;
wire [(2**M_WIDTH-1):0]  [31:0]         	  M_B_WR_DATA      ;
wire [(2**M_WIDTH-1):0]  [ 3:0]         	  M_B_WR_STRB      ;
wire [(2**M_WIDTH-1):0]                 	  M_B_WR_DATA_LAST ;
wire [(2**M_WIDTH-1):0]                 	  M_B_WR_DATA_VALID;
wire [(2**M_WIDTH-1):0]                 	  M_B_WR_DATA_READY;
wire [(2**M_WIDTH-1):0]  [M_ID-1:0]           M_B_WR_BACK_ID   ;
wire [(2**M_WIDTH-1):0]  [ 1:0]         	  M_B_WR_BACK_RESP ;
wire [(2**M_WIDTH-1):0]                 	  M_B_WR_BACK_VALID;
wire [(2**M_WIDTH-1):0]                 	  M_B_WR_BACK_READY;
wire [(2**M_WIDTH-1):0]  [M_ID-1:0]           M_B_RD_ADDR_ID   ;
wire [(2**M_WIDTH-1):0]  [31:0]         	  M_B_RD_ADDR      ;
wire [(2**M_WIDTH-1):0]  [ 7:0]         	  M_B_RD_ADDR_LEN  ;
wire [(2**M_WIDTH-1):0]  [ 1:0]         	  M_B_RD_ADDR_BURST;
wire [(2**M_WIDTH-1):0]                 	  M_B_RD_ADDR_VALID;
wire [(2**M_WIDTH-1):0]                 	  M_B_RD_ADDR_READY;
wire [(2**M_WIDTH-1):0]  [M_ID-1:0]   		  M_B_RD_BACK_ID   ;
wire [(2**M_WIDTH-1):0]  [31:0]         	  M_B_RD_DATA      ;
wire [(2**M_WIDTH-1):0]  [ 1:0]         	  M_B_RD_DATA_RESP ;
wire [(2**M_WIDTH-1):0]                 	  M_B_RD_DATA_LAST ;
wire [(2**M_WIDTH-1):0]                 	  M_B_RD_DATA_VALID;
wire [(2**M_WIDTH-1):0]                 	  M_B_RD_DATA_READY;

wire [(2**S_WIDTH-1):0]  [M_WIDTH+M_ID-1:0]   S_B_WR_ADDR_ID   ;
wire [(2**S_WIDTH-1):0]  [31:0]         	  S_B_WR_ADDR      ;
wire [(2**S_WIDTH-1):0]  [ 7:0]         	  S_B_WR_ADDR_LEN  ;
wire [(2**S_WIDTH-1):0]  [ 1:0]         	  S_B_WR_ADDR_BURST;
wire [(2**S_WIDTH-1):0]                 	  S_B_WR_ADDR_VALID;
wire [(2**S_WIDTH-1):0]                 	  S_B_WR_ADDR_READY;
wire [(2**S_WIDTH-1):0]  [31:0]         	  S_B_WR_DATA      ;
wire [(2**S_WIDTH-1):0]  [ 3:0]         	  S_B_WR_STRB      ;
wire [(2**S_WIDTH-1):0]                 	  S_B_WR_DATA_LAST ;
wire [(2**S_WIDTH-1):0]                 	  S_B_WR_DATA_VALID;
wire [(2**S_WIDTH-1):0]                 	  S_B_WR_DATA_READY;
wire [(2**S_WIDTH-1):0]  [M_WIDTH+M_ID-1:0]   S_B_WR_BACK_ID   ;
wire [(2**S_WIDTH-1):0]  [ 1:0]         	  S_B_WR_BACK_RESP ;
wire [(2**S_WIDTH-1):0]                 	  S_B_WR_BACK_VALID;
wire [(2**S_WIDTH-1):0]                 	  S_B_WR_BACK_READY;
wire [(2**S_WIDTH-1):0]  [M_WIDTH+M_ID-1:0]   S_B_RD_ADDR_ID   ;
wire [(2**S_WIDTH-1):0]  [31:0]         	  S_B_RD_ADDR      ;
wire [(2**S_WIDTH-1):0]  [ 7:0]         	  S_B_RD_ADDR_LEN  ;
wire [(2**S_WIDTH-1):0]  [ 1:0]         	  S_B_RD_ADDR_BURST;
wire [(2**S_WIDTH-1):0]                 	  S_B_RD_ADDR_VALID;
wire [(2**S_WIDTH-1):0]                 	  S_B_RD_ADDR_READY;
wire [(2**S_WIDTH-1):0]  [M_WIDTH+M_ID-1:0]   S_B_RD_BACK_ID   ;
wire [(2**S_WIDTH-1):0]  [31:0]         	  S_B_RD_DATA      ;
wire [(2**S_WIDTH-1):0]  [ 1:0]         	  S_B_RD_DATA_RESP ;
wire [(2**S_WIDTH-1):0]                 	  S_B_RD_DATA_LAST ;
wire [(2**S_WIDTH-1):0]                 	  S_B_RD_DATA_VALID;
wire [(2**S_WIDTH-1):0]                 	  S_B_RD_DATA_READY;

axi_clock_converter #(
	.M_WIDTH 	( M_WIDTH  ),
	.S_WIDTH 	( S_WIDTH  ),
    .M_ASYNC_ON ( M_ASYNC_ON ),
    .S_ASYNC_ON ( S_ASYNC_ON ))
u_axi_clock_converter(
	.BUS_CLK           	( BUS_CLK            ),
	.BUS_RSTN          	( BUS_RSTN           ),
    .M_B_WR_ADDR_ID     (M_B_WR_ADDR_ID      ),
    .M_B_WR_ADDR        (M_B_WR_ADDR         ),
    .M_B_WR_ADDR_LEN    (M_B_WR_ADDR_LEN     ),
    .M_B_WR_ADDR_BURST  (M_B_WR_ADDR_BURST   ),
    .M_B_WR_ADDR_VALID  (M_B_WR_ADDR_VALID   ),
    .M_B_WR_ADDR_READY  (M_B_WR_ADDR_READY   ),
    .M_B_WR_DATA        (M_B_WR_DATA         ),
    .M_B_WR_STRB        (M_B_WR_STRB         ),
    .M_B_WR_DATA_LAST   (M_B_WR_DATA_LAST    ),
    .M_B_WR_DATA_VALID  (M_B_WR_DATA_VALID   ),
    .M_B_WR_DATA_READY  (M_B_WR_DATA_READY   ),
    .M_B_WR_BACK_ID     (M_B_WR_BACK_ID      ),
    .M_B_WR_BACK_RESP   (M_B_WR_BACK_RESP    ),
    .M_B_WR_BACK_VALID  (M_B_WR_BACK_VALID   ),
    .M_B_WR_BACK_READY  (M_B_WR_BACK_READY   ),
    .M_B_RD_ADDR_ID     (M_B_RD_ADDR_ID      ),
    .M_B_RD_ADDR        (M_B_RD_ADDR         ),
    .M_B_RD_ADDR_LEN    (M_B_RD_ADDR_LEN     ),
    .M_B_RD_ADDR_BURST  (M_B_RD_ADDR_BURST   ),
    .M_B_RD_ADDR_VALID  (M_B_RD_ADDR_VALID   ),
    .M_B_RD_ADDR_READY  (M_B_RD_ADDR_READY   ),
    .M_B_RD_BACK_ID     (M_B_RD_BACK_ID      ),
    .M_B_RD_DATA        (M_B_RD_DATA         ),
    .M_B_RD_DATA_RESP   (M_B_RD_DATA_RESP    ),
    .M_B_RD_DATA_LAST   (M_B_RD_DATA_LAST    ),
    .M_B_RD_DATA_VALID  (M_B_RD_DATA_VALID   ),
    .M_B_RD_DATA_READY  (M_B_RD_DATA_READY   ),

    .M_CLK              (MASTER_CLK          ),
    .M_RSTN             (MASTER_RSTN         ),
    .M_WR_ADDR_ID       (MASTER_WR_ADDR_ID   ),
    .M_WR_ADDR          (MASTER_WR_ADDR      ),
    .M_WR_ADDR_LEN      (MASTER_WR_ADDR_LEN  ),
    .M_WR_ADDR_BURST    (MASTER_WR_ADDR_BURST),
    .M_WR_ADDR_VALID    (MASTER_WR_ADDR_VALID),
    .M_WR_ADDR_READY    (MASTER_WR_ADDR_READY),
    .M_WR_DATA          (MASTER_WR_DATA      ),
    .M_WR_STRB          (MASTER_WR_STRB      ),
    .M_WR_DATA_LAST     (MASTER_WR_DATA_LAST ),
    .M_WR_DATA_VALID    (MASTER_WR_DATA_VALID),
    .M_WR_DATA_READY    (MASTER_WR_DATA_READY),
    .M_WR_BACK_ID       (MASTER_WR_BACK_ID   ),
    .M_WR_BACK_RESP     (MASTER_WR_BACK_RESP ),
    .M_WR_BACK_VALID    (MASTER_WR_BACK_VALID),
    .M_WR_BACK_READY    (MASTER_WR_BACK_READY),
    .M_RD_ADDR_ID       (MASTER_RD_ADDR_ID   ),
    .M_RD_ADDR          (MASTER_RD_ADDR      ),
    .M_RD_ADDR_LEN      (MASTER_RD_ADDR_LEN  ),
    .M_RD_ADDR_BURST    (MASTER_RD_ADDR_BURST),
    .M_RD_ADDR_VALID    (MASTER_RD_ADDR_VALID),
    .M_RD_ADDR_READY    (MASTER_RD_ADDR_READY),
    .M_RD_BACK_ID       (MASTER_RD_BACK_ID   ),
    .M_RD_DATA          (MASTER_RD_DATA      ),
    .M_RD_DATA_RESP     (MASTER_RD_DATA_RESP ),
    .M_RD_DATA_LAST     (MASTER_RD_DATA_LAST ),
    .M_RD_DATA_VALID    (MASTER_RD_DATA_VALID),
    .M_RD_DATA_READY    (MASTER_RD_DATA_READY),
    
    .S_B_WR_ADDR_ID     (S_B_WR_ADDR_ID   ),
    .S_B_WR_ADDR        (S_B_WR_ADDR      ),
    .S_B_WR_ADDR_LEN    (S_B_WR_ADDR_LEN  ),
    .S_B_WR_ADDR_BURST  (S_B_WR_ADDR_BURST),
    .S_B_WR_ADDR_VALID  (S_B_WR_ADDR_VALID),
    .S_B_WR_ADDR_READY  (S_B_WR_ADDR_READY),
    .S_B_WR_DATA        (S_B_WR_DATA      ),
    .S_B_WR_STRB        (S_B_WR_STRB      ),
    .S_B_WR_DATA_LAST   (S_B_WR_DATA_LAST ),
    .S_B_WR_DATA_VALID  (S_B_WR_DATA_VALID),
    .S_B_WR_DATA_READY  (S_B_WR_DATA_READY),
    .S_B_WR_BACK_ID     (S_B_WR_BACK_ID   ),
    .S_B_WR_BACK_RESP   (S_B_WR_BACK_RESP ),
    .S_B_WR_BACK_VALID  (S_B_WR_BACK_VALID),
    .S_B_WR_BACK_READY  (S_B_WR_BACK_READY),
    .S_B_RD_ADDR_ID     (S_B_RD_ADDR_ID   ),
    .S_B_RD_ADDR        (S_B_RD_ADDR      ),
    .S_B_RD_ADDR_LEN    (S_B_RD_ADDR_LEN  ),
    .S_B_RD_ADDR_BURST  (S_B_RD_ADDR_BURST),
    .S_B_RD_ADDR_VALID  (S_B_RD_ADDR_VALID),
    .S_B_RD_ADDR_READY  (S_B_RD_ADDR_READY),
    .S_B_RD_BACK_ID     (S_B_RD_BACK_ID   ),
    .S_B_RD_DATA        (S_B_RD_DATA      ),
    .S_B_RD_DATA_RESP   (S_B_RD_DATA_RESP ),
    .S_B_RD_DATA_LAST   (S_B_RD_DATA_LAST ),
    .S_B_RD_DATA_VALID  (S_B_RD_DATA_VALID),
    .S_B_RD_DATA_READY  (S_B_RD_DATA_READY),

    .S_CLK              (SLAVE_CLK          ),
    .S_RSTN             (SLAVE_RSTN         ),
    .S_WR_ADDR_ID       (SLAVE_WR_ADDR_ID   ),
    .S_WR_ADDR          (SLAVE_WR_ADDR      ),
    .S_WR_ADDR_LEN      (SLAVE_WR_ADDR_LEN  ),
    .S_WR_ADDR_BURST    (SLAVE_WR_ADDR_BURST),
    .S_WR_ADDR_VALID    (SLAVE_WR_ADDR_VALID),
    .S_WR_ADDR_READY    (SLAVE_WR_ADDR_READY),
    .S_WR_DATA          (SLAVE_WR_DATA      ),
    .S_WR_STRB          (SLAVE_WR_STRB      ),
    .S_WR_DATA_LAST     (SLAVE_WR_DATA_LAST ),
    .S_WR_DATA_VALID    (SLAVE_WR_DATA_VALID),
    .S_WR_DATA_READY    (SLAVE_WR_DATA_READY),
    .S_WR_BACK_ID       (SLAVE_WR_BACK_ID   ),
    .S_WR_BACK_RESP     (SLAVE_WR_BACK_RESP ),
    .S_WR_BACK_VALID    (SLAVE_WR_BACK_VALID),
    .S_WR_BACK_READY    (SLAVE_WR_BACK_READY),
    .S_RD_ADDR_ID       (SLAVE_RD_ADDR_ID   ),
    .S_RD_ADDR          (SLAVE_RD_ADDR      ),
    .S_RD_ADDR_LEN      (SLAVE_RD_ADDR_LEN  ),
    .S_RD_ADDR_BURST    (SLAVE_RD_ADDR_BURST),
    .S_RD_ADDR_VALID    (SLAVE_RD_ADDR_VALID),
    .S_RD_ADDR_READY    (SLAVE_RD_ADDR_READY),
    .S_RD_BACK_ID       (SLAVE_RD_BACK_ID   ),
    .S_RD_DATA          (SLAVE_RD_DATA      ),
    .S_RD_DATA_RESP     (SLAVE_RD_DATA_RESP ),
    .S_RD_DATA_LAST     (SLAVE_RD_DATA_LAST ),
    .S_RD_DATA_VALID    (SLAVE_RD_DATA_VALID),
    .S_RD_DATA_READY    (SLAVE_RD_DATA_READY),
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
	.M_WR_ADDR_ID   (M_B_WR_ADDR_ID   ),
	.M_WR_ADDR      (M_B_WR_ADDR      ),
	.M_WR_ADDR_LEN  (M_B_WR_ADDR_LEN  ),
	.M_WR_ADDR_BURST(M_B_WR_ADDR_BURST),
	.M_WR_ADDR_VALID(M_B_WR_ADDR_VALID),
	.M_WR_ADDR_READY(M_B_WR_ADDR_READY),
	.M_WR_DATA      (M_B_WR_DATA      ),
	.M_WR_STRB      (M_B_WR_STRB      ),
	.M_WR_DATA_LAST (M_B_WR_DATA_LAST ),
	.M_WR_DATA_VALID(M_B_WR_DATA_VALID),
	.M_WR_DATA_READY(M_B_WR_DATA_READY),
	.M_WR_BACK_ID   (M_B_WR_BACK_ID   ),
	.M_WR_BACK_RESP (M_B_WR_BACK_RESP ),
	.M_WR_BACK_VALID(M_B_WR_BACK_VALID),
	.M_WR_BACK_READY(M_B_WR_BACK_READY),
	.M_RD_ADDR_ID   (M_B_RD_ADDR_ID   ),
	.M_RD_ADDR      (M_B_RD_ADDR      ),
	.M_RD_ADDR_LEN  (M_B_RD_ADDR_LEN  ),
	.M_RD_ADDR_BURST(M_B_RD_ADDR_BURST),
	.M_RD_ADDR_VALID(M_B_RD_ADDR_VALID),
	.M_RD_ADDR_READY(M_B_RD_ADDR_READY),
	.M_RD_BACK_ID   (M_B_RD_BACK_ID   ),
	.M_RD_DATA      (M_B_RD_DATA      ),
	.M_RD_DATA_RESP (M_B_RD_DATA_RESP ),
	.M_RD_DATA_LAST (M_B_RD_DATA_LAST ),
	.M_RD_DATA_VALID(M_B_RD_DATA_VALID),
	.M_RD_DATA_READY(M_B_RD_DATA_READY),

	.S_WR_ADDR_ID   (S_B_WR_ADDR_ID   ),
	.S_WR_ADDR      (S_B_WR_ADDR      ),
	.S_WR_ADDR_LEN  (S_B_WR_ADDR_LEN  ),
	.S_WR_ADDR_BURST(S_B_WR_ADDR_BURST),
	.S_WR_ADDR_VALID(S_B_WR_ADDR_VALID),
	.S_WR_ADDR_READY(S_B_WR_ADDR_READY),
	.S_WR_DATA      (S_B_WR_DATA      ),
	.S_WR_STRB      (S_B_WR_STRB      ),
	.S_WR_DATA_LAST (S_B_WR_DATA_LAST ),
	.S_WR_DATA_VALID(S_B_WR_DATA_VALID),
	.S_WR_DATA_READY(S_B_WR_DATA_READY),
	.S_WR_BACK_ID   (S_B_WR_BACK_ID   ),
	.S_WR_BACK_RESP (S_B_WR_BACK_RESP ),
	.S_WR_BACK_VALID(S_B_WR_BACK_VALID),
	.S_WR_BACK_READY(S_B_WR_BACK_READY),
	.S_RD_ADDR_ID   (S_B_RD_ADDR_ID   ),
	.S_RD_ADDR      (S_B_RD_ADDR      ),
	.S_RD_ADDR_LEN  (S_B_RD_ADDR_LEN  ),
	.S_RD_ADDR_BURST(S_B_RD_ADDR_BURST),
	.S_RD_ADDR_VALID(S_B_RD_ADDR_VALID),
	.S_RD_ADDR_READY(S_B_RD_ADDR_READY),
	.S_RD_BACK_ID   (S_B_RD_BACK_ID   ),
	.S_RD_DATA      (S_B_RD_DATA      ),
	.S_RD_DATA_RESP (S_B_RD_DATA_RESP ),
	.S_RD_DATA_LAST (S_B_RD_DATA_LAST ),
	.S_RD_DATA_VALID(S_B_RD_DATA_VALID),
	.S_RD_DATA_READY(S_B_RD_DATA_READY)
);


endmodule