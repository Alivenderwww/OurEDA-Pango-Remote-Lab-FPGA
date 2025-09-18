`define SIM
`timescale 1ns / 1ns
module hdmi_top_tb;

  // Parameters

  //Ports
  reg  sys_clk;
  reg rstn_in;
  wire rstn_out;
  wire hd_scl;
  wire hd_sda;
  wire led_int;
  wire pixclk_out;
  wire  vs_out;
  wire  hs_out;
  wire  de_out;
  wire [7:0] r_out;
  wire [7:0] g_out;
  wire [7:0] b_out;

  initial begin
    sys_clk = 0;
    rstn_in = 0;
    #100
    rstn_in = 1;
  end
  always #(500/27) sys_clk = ~sys_clk;
  hdmi_top  hdmi_top_inst (
    .sys_clk(sys_clk),
    .rstn_in(rstn_in),
    .rstn_out(rstn_out),
    .hd_scl(hd_scl),
    .hd_sda(hd_sda),
    .led_int(led_int),
    .pixclk_out(pixclk_out),
    .vs_out(vs_out),
    .hs_out(hs_out),
    .de_out(de_out),
    .r_out(r_out),
    .g_out(g_out),
    .b_out(b_out)
  );

endmodule