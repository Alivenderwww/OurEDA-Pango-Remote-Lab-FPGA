module matrix_key_top(
//system io
input  wire       external_clk ,
input  wire       external_rstn,

input  wire [ 3:0] col,
output wire [ 3:0] row,
output wire ser,
output wire sck,
output wire rck
);

wire [15:0] key_out;
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

//数码管显示模块
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
    .NUM(16),
    .MODE(1)
)led_display_seg_ctrl_inst(
    .clk(external_clk),
    .rstn(external_rstn),
    .led_en(key_out),
    .assic_seg({"0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"}),
    .seg_point(32'hFFFFFFFF),
    .seg(seg),
    .sel(sel)
  );
endmodule
