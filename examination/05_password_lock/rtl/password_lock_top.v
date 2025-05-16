
module password_lock_top #(
    parameter VALID_SIGNAL = 1'b0,
    parameter CLK_CYCLE = 5000
)(
//system io
input  wire       external_clk ,
input  wire       external_rstn,

output wire [7:0] led_display_seg,
output wire [7:0] led_display_sel,

input  wire [3:0] col,
output wire [3:0] row
);

wire [15:0] key_out;
wire [15:0] key_trigger;
wire [8*8-1:0] assic_seg;
wire [7:0] seg_point;

led_display_driver #(
    .VALID_SIGNAL (VALID_SIGNAL),
    .CLK_CYCLE (CLK_CYCLE)
)u_led_display_driver(
	.clk             	( external_clk    ),
	.rstn            	( external_rstn   ),
	.assic_seg       	( assic_seg       ),
	.seg_point       	( seg_point       ),
	.led_display_seg 	( led_display_seg ),
	.led_display_sel 	( led_display_sel )
);

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

matrix_key_trigger u_matrix_key_trigger(
	.clk         	( external_clk ),
	.rstn        	( external_rstn),
	.key         	( key_out      ),
	.key_trigger 	( key_trigger  )
);

password_lock u_password_lock(
    .clk         	( external_clk ),
    .rstn        	( external_rstn),
    .key_trigger 	( key_trigger  ),
    .assic_seg   	( assic_seg    ),
	.seg_point   	( seg_point    )
);

endmodule //led_diaplay_top
