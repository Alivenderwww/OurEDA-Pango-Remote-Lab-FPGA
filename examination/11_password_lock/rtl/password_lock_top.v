
module password_lock_top #(
    parameter VALID_SIGNAL = 1'b0,
    parameter CLK_CYCLE = 27000
)(
//system io
input  wire       external_clk ,
input  wire       external_rstn,

output wire rck,
output wire sck,
output wire ser,

input  wire [3:0] col,
output wire [3:0] row
);

wire [15:0] key_out;
wire [15:0] key_trigger;
wire [8*8-1:0] assic_seg;
wire [7:0] seg_point;

wire [4:0] sel;
wire [7:0] seg;
hc595_ctrl  hc595_ctrl_inst (
    .sys_clk(external_clk),
    .sys_rst_n(external_rstn),
    .sel(sel),
    .seg(seg),
    .rck(rck),
    .sck(sck),
    .ser(ser)
  );    
led_display_seg_ctrl #(
    .NUM(8),
    .MODE(1)
)led_display_seg_ctrl_inst(
    .clk(external_clk),
    .rstn(external_rstn),
    .led_en(8'hFF),
    .assic_seg(assic_seg),
    .seg_point(32'h0),
    .seg(seg),
    .sel(sel)
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
