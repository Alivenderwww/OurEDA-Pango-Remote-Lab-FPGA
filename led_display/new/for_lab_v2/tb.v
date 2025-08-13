
module led_diaplay_top_tb;

   // Parameters
 
   //Ports
   reg  clk;
   reg  rstn;
   wire  ser;
   wire  sck;
   wire  rck;
initial begin
    clk = 0;
    rstn = 1;
    #100
    rstn = 0;
    #100
    rstn = 1;
end
led_diaplay_top  led_diaplay_top_inst (
    .clk(clk),
    .rstn(rstn),
    .ser(ser),
    .sck(sck),
    .rck(rck)
  );

always #(500/27)  clk = ! clk ;

endmodule