
module led_tb;

  // Parameters
  localparam  CLK_CYCLE = 27000000;

  //Ports
  reg clk;
  reg rstn;
  wire [2:0] led1;
  wire [2:0] led2;
  wire [2:0] led3;
  wire [2:0] led4;
  wire sck;
  wire rck;
  wire ser;

  initial begin
    clk <= 0;
    rstn <= 1;
    #10;
    rstn <= 0;
    #10
    rstn <= 1;
  end
  led # (
    .CLK_CYCLE(100)
  )
  led_inst (
    .clk(clk),
    .rstn(rstn),
    .led1(led1),
    .led2(led2),
    .led3(led3),
    .led4(led4),
    .sck(sck),
    .rck(rck),
    .ser(ser)
  );

always #1  clk = ! clk ;

endmodule