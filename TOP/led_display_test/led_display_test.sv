module led_display_test #(
    parameter NUM = 8,
    parameter VALID_SIGNAL = 1'b0,
    parameter CLK_CYCLE = 5000
)(
//system io
input  wire        external_clk ,
input  wire        external_rstn,

output wire [7:0]     led_display_seg,
output wire [NUM-1:0] led_display_sel
);

reg [NUM-1:0][7:0] led_in;

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
        led_in[0] <= 8'b1111_0101;
        led_in[1] <= 8'b0000_0010;
        led_in[2] <= 8'b0000_0100;
        led_in[3] <= 8'b0000_1000;
        led_in[4] <= 8'b0001_0000;
        led_in[5] <= 8'b0010_0000;
        led_in[6] <= 8'b0100_0000;
        led_in[7] <= 8'b1000_0000;
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

endmodule
