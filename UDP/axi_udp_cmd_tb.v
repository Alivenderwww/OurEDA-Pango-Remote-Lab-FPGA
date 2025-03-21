`timescale  1ns/1ns
//////wrlast拉低的方法
module axi_udp_cmd_tb;

  // Parameters
  localparam  ID = 0;

  //Ports
  reg  gmii_rx_clk;
  reg  rstn;
  wire [27:0] wr_addr;
  wire [ 3:0] wr_ID;
  wire [ 7:0] wr_len;
  wire wr_addr_valid;
  reg  wr_addr_ready;
  wire [31:0] wr_data;
  wire [ 3:0] wr_strb;
  wire wr_data_valid;
  reg  wr_data_ready;
  reg  wr_back_ID;
  wire wr_data_last;
  wire [27:0] rd_addr;
  wire [ 3:0] rd_ID;
  wire [ 7:0] rd_len;
  wire rd_addr_valid;
  reg  rd_addr_ready;
  reg [31:0] rd_data;
  reg [ 3:0] rd_back_ID;
  reg  rd_data_last;
  wire rd_data_ready;
  reg  rd_data_valid;
  reg  rec_pkt_done;
  reg [31:0] datain;
  reg  rec_en;
  reg  tx_req;
  wire tx_start_en;
  wire [31:0] udp_tx_data;

always  #5   gmii_rx_clk = ~ gmii_rx_clk ;

reg wr_data_ready_cnt;
initial begin
    rstn = 0;
    gmii_rx_clk = 0;
    #10 rstn = 1;
end
//axi
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn || wr_data_last) wr_addr_ready <= 0;
    else if(wr_addr_valid && wr_addr_ready) wr_addr_ready <= 0;
    else if(wr_addr_valid)wr_addr_ready <= 1;
    else wr_addr_ready <= 0;
end
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn || wr_data_last) wr_data_ready_cnt <= 0;
    else if(wr_data_valid) wr_data_ready_cnt <= wr_data_ready_cnt + 1;
    else wr_data_ready_cnt <= 0;
end
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn ) wr_data_ready_cnt <= 0;
    else if(wr_data_last) wr_data_ready <=  1;
    else if(wr_data_valid && wr_data_ready_cnt == 1) wr_data_ready <=  1;
    else wr_data_ready <= 0;
end
//udp
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn) datain <= 32'h80000000;
    else if(wr_data_last) datain <= 32'h40000000;
    else datain <= datain + 1;
end
reg [1:0] rec_en_cnt;
reg [31:0] rec_pkt_done_cnt;
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn || wr_data_last) rec_en_cnt <= 0;
    else if(rec_pkt_done_cnt == 0) rec_en_cnt <= 0;
    else rec_en_cnt <= rec_en_cnt + 1;
end
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn || wr_data_last) rec_en <= 0;
    else if(rec_en_cnt == 3) rec_en <= 1;
    else rec_en <= 0;
end

always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn ) rec_pkt_done_cnt <= 1;
    else if(rec_pkt_done_cnt == 255 && rec_pkt_done|| wr_data_last) rec_pkt_done_cnt <= 0;
    else if(rec_en && rec_pkt_done_cnt != 0) rec_pkt_done_cnt <= rec_pkt_done_cnt + 1;
    else rec_pkt_done_cnt <= rec_pkt_done_cnt;
end
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn || wr_data_last) rec_pkt_done <= 0;
    else if(rec_pkt_done_cnt == 255 && rec_en_cnt == 3) rec_pkt_done <= 1;
    else rec_pkt_done <= 0;
end

//rd
reg [31:0] rd_data_last_cnt;
reg [1:0] rec_en_rd_cnt;
reg rec_pkt_done_rd;
reg rec_en_rd;
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn) rec_en_rd_cnt <= 0;
    else if(wr_data_last && wr_data_ready) rec_en_rd_cnt <= 1;
    else if(rec_en_rd_cnt == 2)rec_en_rd_cnt<=0;
    else if(rec_en_rd_cnt )rec_en_rd_cnt <= rec_en_rd_cnt+1;
end
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn) rec_en_rd <= 0;
    else if(rec_en_rd_cnt) rec_en_rd <=1;
    else if(!rec_en_rd_cnt)rec_en_rd <=0;
end
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn) rec_pkt_done_rd <= 0;
    else if(rec_en_rd_cnt == 2) rec_pkt_done_rd <=1;
    else rec_pkt_done_rd <=0;
end
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn || wr_data_last) rd_addr_ready <= 0;
    else if(rd_addr_valid && rd_addr_ready) rd_addr_ready <= 0;
    else if(rd_addr_valid)rd_addr_ready <= 1;
    else rd_addr_ready <= 0;
end
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn || wr_data_last) rd_data <= 0;
    else if (rd_data_ready)rd_data <= rd_data + 1;
end
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn || wr_data_last) rd_data_valid <= 0;
    else if(~rd_data_ready)rd_data_valid <= 0;
    else if(~rd_data_valid) rd_data_valid <= 1;
    else if (rd_data_ready)rd_data_valid <=  0;
end
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn || wr_data_last) rd_data_last_cnt <= 0;
    else if(rd_data_last) rd_data_last_cnt <= 0;
    else if(rd_data_ready && rd_data_valid) rd_data_last_cnt <= rd_data_last_cnt + 1;
    else rd_data_last_cnt <= rd_data_last_cnt;
end
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn || wr_data_last) rd_data_last <= 0;
    else if(rd_data_last_cnt == 255) rd_data_last <= 1;
    else rd_data_last <= 0;
end

  axi_udp_cmd axi_udp_cmd_inst (
    .gmii_rx_clk(gmii_rx_clk),
    .rstn(rstn),
    .wr_addr(wr_addr),
    .wr_ID(wr_ID),
    .wr_len(wr_len),
    .wr_addr_valid(wr_addr_valid),
    .wr_addr_ready(wr_addr_ready),
    .wr_data(wr_data),
    .wr_strb(wr_strb),
    .wr_data_valid(wr_data_valid),
    .wr_data_ready(wr_data_ready),
    .wr_back_ID(wr_back_ID),
    .wr_data_last(wr_data_last),
    .rd_addr(rd_addr),
    .rd_ID(rd_ID),
    .rd_len(rd_len),
    .rd_addr_valid(rd_addr_valid),
    .rd_addr_ready(rd_addr_ready),
    .rd_data(rd_data),
    .rd_back_ID(rd_back_ID),
    .rd_data_last(rd_data_last),
    .rd_data_ready(rd_data_ready),
    .rd_data_valid(rd_data_valid),
    .rec_pkt_done(rec_pkt_done || rec_pkt_done_rd),
    .datain(datain),
    .rec_en(rec_en || rec_en_rd),
    .tx_req(tx_req),
    .tx_start_en(tx_start_en),
    .udp_tx_data(udp_tx_data)
  );
GTP_GRS GRS_INST
(
    .GRS_N(1'b1)

);

//always #5  clk = ! clk ;

endmodule