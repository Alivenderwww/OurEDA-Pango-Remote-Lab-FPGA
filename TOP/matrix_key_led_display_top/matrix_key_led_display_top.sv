module matrix_key_led_display_top #(
    parameter NUM = 8,
    parameter VALID_SIGNAL = 1'b0,
    parameter CLK_CYCLE = 5000
)(
//system io
input  wire        external_clk ,
input  wire        external_rstn,

output wire [7:0]     led_display_seg,
output wire [NUM-1:0] led_display_sel,

input  wire [3:0] col,
output wire [3:0] row
);

reg [NUM-1:0][7:0] led_in;
// outports wire
wire [4-1:0]    row;
wire [4*4-1:0] 	key_out;

always @(posedge external_clk or negedge external_rstn) begin
    if(~external_rstn) begin
        led_in[0] <= 8'b0000_0000;
        led_in[1] <= 8'b0000_0000;
        led_in[2] <= 8'b0000_0000;
        led_in[3] <= 8'b0000_0000;
        led_in[4] <= 8'b0000_0000;
        led_in[5] <= 8'b0000_0000;
        led_in[6] <= 8'b0000_0000;
        led_in[7] <= 8'b0000_0000;
    end else begin
        led_in[0] <= key_out[7:0];
        led_in[1] <= key_out[15:8];
        led_in[2] <= 8'b0000_0000;
        led_in[3] <= 8'b0000_0000;
        led_in[4] <= 8'b0000_0000;
        led_in[5] <= 8'b0000_0000;
        led_in[6] <= 8'b0000_0000;
        led_in[7] <= 8'b0000_0000;
    end
end

led_display_ctrl #(
    .NUM (NUM),
    .VALID_SIGNAL (VALID_SIGNAL),
    .CLK_CYCLE (CLK_CYCLE)
)led_display_ctrl_inst(
    .clk(external_clk),
    .rstn(external_rstn),
    .led_in(led_in),
    .led_display_seg(led_display_seg),
    .led_display_sel(led_display_sel)
);


matrix_key #(
	.ROW_NUM       	( 4     ),
	.COL_NUM       	( 4     ),
	.DEBOUNCE_TIME 	( 2000  ),
	.DELAY_TIME    	( 200   ))
u_matrix_key(
	.clk     	( external_clk  ),
	.rstn    	( external_rstn ),
	.row     	( row           ),
	.col     	( col           ),
	.key_out 	( key_out       )
);


endmodule
