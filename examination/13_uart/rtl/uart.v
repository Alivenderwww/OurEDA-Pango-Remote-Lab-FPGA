module uart (
    input  clk/* synthesis PAP_MARK_DEBUG="true" */,
    input  rstn,
    input  rx,
    output tx,
    output [7:0] led
);
wire baud_en/* synthesis PAP_MARK_DEBUG="true" */;
wire [7:0] rx_data/* synthesis PAP_MARK_DEBUG="true" */;
wire data_valid/* synthesis PAP_MARK_DEBUG="true" */;

assign led = rx_data;

baud_rate_gen  baud_rate_gen_inst (
    .clk(clk),
    .rst_n(rstn),
    .baud_en(baud_en)
  );
uart_rx  uart_rx_inst (
    .clk(clk),
    .rst_n(rstn),
    .rx(rx),
    .baud_en(baud_en),
    .rx_data(rx_data),
    .data_valid(data_valid)
  );
endmodule