`timescale  1ns/1ns
module udp_model_tb;

  // Parameters

  //Ports
  reg gmii_rx_clk;
  reg rstn;
  reg wr_en;
  reg rd_en;
  reg [7:0] wr_num;
  reg [7:0] rd_num;
  reg [27:0] wr_addr;
  reg [27:0] rd_addr;
  wire rec_pkt_done;
  wire [31:0] udp_rx_data;
  wire rec_en;
  wire tx_req;
  wire tx_start_en;
  wire [31:0] udp_tx_data;

  always #5  gmii_rx_clk = ! gmii_rx_clk ;
  initial begin
    gmii_rx_clk = 0;
    rstn = 0;
    wr_en = 0;
    rd_en = 0;
    #10 rstn = 1;
    
    wr_addr = 0;
    #10 
wr_num = 255;
    wr_en = 1;

  end

  always @(posedge gmii_rx_clk or negedge rstn) begin
    if (!rstn) rd_en <= 0;
    else if (rec_pkt_done) begin
      rd_en <= 1;
      rd_num <= 255;
      rd_addr <= 0;
    end
    else rd_en <= 0;
    
  end


  
  udp_model  udp_model_inst (
    .gmii_rx_clk(gmii_rx_clk),
    .rstn(rstn),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .wr_num(wr_num),
    .rd_num(rd_num),
    .wr_addr(wr_addr),
    .rd_addr(rd_addr),
    .rec_pkt_done(rec_pkt_done),
    .udp_rx_data(udp_rx_data),
    .rec_en(rec_en),
    .tx_req(tx_req),
    .tx_start_en(tx_start_en),
    .udp_tx_data(udp_tx_data)
  );

  wire [27:0] axi_wr_addr;
  wire [ 7:0] wr_len;
  wire wr_addr_valid;
  wire  wr_addr_ready;
  wire [31:0] wr_data;
  wire wr_data_valid;
  wire  wr_data_ready;
  wire  wr_back_ID;
  wire wr_data_last;
  wire [27:0] axi_rd_addr;
  wire [ 3:0] rd_ID;
  wire [ 7:0] rd_len;
  wire rd_addr_valid;
  wire  rd_addr_ready;
  wire [31:0] rd_data;
  wire [ 3:0] rd_back_ID;
  wire  rd_data_last;
  wire rd_data_ready;
  wire  rd_data_valid;

  axi_udp_cmd  axi_udp_cmd_inst (
    .gmii_rx_clk(gmii_rx_clk),
    .rstn(rstn),
    .BUSCLK(),
    .wr_addr(axi_wr_addr),
    .wr_ID(),
    .wr_len(wr_len),
    .wr_addr_valid(wr_addr_valid),
    .wr_addr_ready(wr_addr_ready),
    .wr_data(wr_data),
    .wr_strb(),
    .wr_data_valid(wr_data_valid),
    .wr_data_ready(wr_data_ready),
    .wr_back_ID(wr_back_ID),
    .wr_data_last(wr_data_last),
    .rd_addr(axi_rd_addr),
    .rd_len(rd_len),
    .rd_addr_valid(rd_addr_valid),
    .rd_addr_ready(rd_addr_ready),
    .rd_data(rd_data),
    .rd_back_ID(rd_back_ID),
    .rd_data_last(rd_data_last),
    .rd_data_ready(rd_data_ready),
    .rd_data_valid(rd_data_valid),

    .rec_pkt_done(rec_pkt_done),
    .datain(udp_rx_data),
    .rec_en(rec_en),
    .tx_req(tx_req),
    .tx_start_en(tx_start_en),
    .udp_tx_data(udp_tx_data)
  );
//always #5  clk = ! clk ;
  GTP_GRS GRS_INST
(
    .GRS_N(1'b1)

);

endmodule