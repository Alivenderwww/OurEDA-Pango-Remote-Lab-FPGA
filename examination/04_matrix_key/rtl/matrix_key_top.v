module matrix_key_top(
//system io
input  wire       external_clk ,
input  wire       external_rstn,

input  wire [ 3:0] col,
output wire [ 3:0] row,
output wire [15:0] led,
output wire [ 7:0] led_display_sel
);

wire [15:0] key_out;
assign led_display_sel = 8'b01111111;
assign led = key_out;
matrix_key #(
	.ROW_NUM       	( 4     ),
	.COL_NUM       	( 4     ),
	.DEBOUNCE_TIME 	( 10000 ),
	.DELAY_TIME    	( 2000  ))
u_matrix_key(
	.clk     	( external_clk  ),
	.rstn    	( external_rstn ),
	.row     	( row           ),
	.col     	( col           ),
	.key_out 	( key_out       )
);


endmodule
