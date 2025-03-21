`timescale 1ns/1ns
module JTAG_sim_test ();



reg clk;
initial clk = 0;
always #20 clk = ~clk;

reg rst_n;
initial begin
    rst_n = 0;
    #10000
    rst_n = 1;
end

wire tck, tms, tdi, tdo;
assign tdo = 1;


JTAG_test_IDCODE_top JTAG_test_IDCODE_top_inst(
    .clk    (clk),
    .rst_n  (rst_n),

    .tck    (tck),
    .tms    (tms),
    .tdi    (tdi),
    .tdo    (tdo)
);

wire GRS_N;
GTP_GRS GRS_INST (
.GRS_N(1'b1)
);
endmodule