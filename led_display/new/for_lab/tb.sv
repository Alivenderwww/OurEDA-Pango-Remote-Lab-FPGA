`timescale 1ns/1ns
module led_diaplay_top_tb;

  // Parameters

  //Ports
  reg  external_clk;
  reg  external_rstn;
  wire ser;
  wire sck;
  wire rck;
initial begin
  external_rstn = 0;
  external_clk = 0;
  #100
  external_rstn = 1;
end
led_diaplay_top  led_diaplay_top_inst (
    .external_clk(external_clk),
    .external_rstn(external_rstn),
    .ser(ser),
    .sck(sck),
    .rck(rck)
  );

always #5  external_clk = ! external_clk ;

endmodule