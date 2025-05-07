module led_display_top(
    input wire clk,
    input wire rstn,
    input wire [NUM-1:0][7:0] led_in, //[A,B,C,D,E,F,G,DP]
);

wire clk;
wire rstn;
wire [NUM-1:0][7:0]   led_in;
wire [7:0]  led_display_seg;
wire [NUM-1:0]  led_display_sel;

led_display_ctrl #(
    .NUM (4),
    .VALID_SIGNAL (1'b0),
    .CLK_CYCLE (1000)
)led_display_ctrl_inst(
    .clk(clk),
    .rstn(rstn),
    .led_in(led_in),
    .led_display_seg(led_display_seg),
    .led_display_sel(led_display_sel)
);

endmodule //led_display_top