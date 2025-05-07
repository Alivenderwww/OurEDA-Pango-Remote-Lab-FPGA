`timescale 1ns/1ps
module led_display_test ();

    parameter NUM = 4;
    parameter VALID_SIGNAL = 1'b0;
    parameter CLK_CYCLE = 1000;

    reg clk;
    reg rstn;

    initial begin
        clk = 0;
        rstn = 0;
        #5 rstn = 1; // Release reset
    end
    always #5 clk = ~clk; // Generate clock signal
    
    reg [NUM-1:0][7:0]   led_in;
    wire [7:0]  led_display_seg;
    wire [NUM-1:0]  led_display_sel;

    initial begin
        led_in[0] = 8'hFF;
        led_in[1] = 8'hAA;
        led_in[2] = 8'h55;
        led_in[3] = 8'h00;
    end

    led_display_ctrl #(
        .NUM (NUM),
        .VALID_SIGNAL (VALID_SIGNAL),
        .CLK_CYCLE (CLK_CYCLE)
    )led_display_ctrl_inst(
        .clk(clk),
        .rstn(rstn),
        .led_in(led_in),
        .led_display_seg(led_display_seg),
        .led_display_sel(led_display_sel)
    );

    reg grs_n;
    GTP_GRS GRS_INST(.GRS_N (grs_n));
    initial begin
    grs_n = 1'b0;
    #5 grs_n = 1'b1;
    end
endmodule