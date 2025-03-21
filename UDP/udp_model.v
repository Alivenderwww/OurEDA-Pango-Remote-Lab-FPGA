`timescale  1ns/1ns
module udp_model(
    input  gmii_rx_clk,
    input  rstn,
    input  wr_en,//检测此信号上升沿为发送
    input  rd_en,
    input  [7:0] wr_num,//1个32位数据为1
    input  [7:0] rd_num,
    input  [27:0] wr_addr,
    input  [27:0] rd_addr,
    output reg rec_pkt_done,
    output reg [31:0] udp_rx_data,
    output reg rec_en,
    output reg tx_req,
    input  tx_start_en,
    input  [31:0] udp_tx_data
);
reg [1:0] rec_en_cnt;
reg [1:0] tx_req_cnt;
reg [1:0] tx_rx_cnt;
reg [31:0] rx_num_cnt;
reg [31:0] tx_num_cnt;
reg tx_start_en_reg;
reg wr_en_reg;
reg wr_end0,wr_end1;
wire wr_enup;
reg rd_en_reg;
reg rd_end0,rd_end1;
wire rd_enup;
assign wr_enup = wr_end0 && ~ wr_end1;
assign rd_enup = rd_end0 && ~ rd_end1;
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn)begin
        wr_end0 <= 0;
        wr_end1 <= 0;
        rd_end0 <= 0;
        rd_end1 <= 0;
    end
    else begin
        wr_end0 <= wr_en;
        wr_end1 <= wr_end0;
        rd_end0 <= rd_en;
        rd_end1 <= rd_end0;
    end
end
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn)wr_en_reg<=0;
    else if(wr_enup) wr_en_reg<=1;
    else if(rec_pkt_done) wr_en_reg <= 0;
    else wr_en_reg<=wr_en_reg;
end 
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn)rd_en_reg<=0;
    else if(rd_enup) rd_en_reg<=1;
    else if(tx_num_cnt == rd_num - 1 && tx_req_cnt == 3) rd_en_reg <= 0;
    else rd_en_reg<=rd_en_reg;
end 
///////////////////////////////
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn) rec_en_cnt <= 0;
    else  if (wr_en_reg) rec_en_cnt <= rec_en_cnt + 1;
    else rec_en_cnt <= 0;
end
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn) begin
        rx_num_cnt <= 0;
        rec_en <= 0;
    end
    else if(rec_pkt_done)begin
        rx_num_cnt <= 0;
        rec_en <= 0;
    end
    else  if(rec_en_cnt == 3) begin
        rx_num_cnt <= rx_num_cnt + 1;
        rec_en <= 1;
    end
    else if(tx_req_cnt == 3 && tx_rx_cnt != 2) rec_en <= 1;
    else begin
        rx_num_cnt <= rx_num_cnt;
        rec_en <= 0;
    end
end
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn)rec_pkt_done<= 0;
    else if(rx_num_cnt == wr_num - 1 +2 && rec_en_cnt == 3)
        rec_pkt_done<= 1;
    else if(tx_rx_cnt == 2 && rec_en)rec_pkt_done<= 1;
    else rec_pkt_done<= 0;
end
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn) udp_rx_data <= {8'h80,wr_num,16'h0000};
    else if(wr_enup)udp_rx_data<={8'h80,wr_num,16'h0000};
    else if(rec_en_cnt >=1  && rx_num_cnt == 1)udp_rx_data <= {4'h0,wr_addr};
    else if(rx_num_cnt == 2) udp_rx_data<=0;
    else if(rx_num_cnt > 2) udp_rx_data<=udp_rx_data +1;
    else if(rd_en_reg && tx_rx_cnt == 0) udp_rx_data <= {8'h40,rd_num,16'h0000};
    else if(rd_en_reg && tx_rx_cnt == 1)     udp_rx_data <= {4'h0,rd_addr};
    else udp_rx_data<=udp_rx_data;
end
//always #5  clk = ! clk ;
//////////////////////////////////////////
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn) tx_start_en_reg <= 0;
    else if(tx_start_en) tx_start_en_reg <= 1;
    else if(tx_num_cnt == rd_num - 1 && tx_req_cnt == 3) tx_start_en_reg <=0;
    else tx_start_en_reg <= tx_start_en_reg;
end

always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn)tx_req_cnt<= 0;
    else if(rd_en_reg)tx_req_cnt<= tx_req_cnt+1;
    else tx_req_cnt<= 0;
end
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn) tx_rx_cnt<= 0;
    else if(!rd_en_reg) tx_rx_cnt<= 0;
    else if(tx_rx_cnt == 2) tx_rx_cnt<= 2;
    else if(tx_req_cnt == 3) tx_rx_cnt<= tx_rx_cnt+1;
end
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn)begin
        tx_num_cnt<=0;
        tx_req<=0;
    end
    else if(tx_num_cnt == rd_num - 1 && tx_req_cnt == 3) begin
        tx_num_cnt<=0;
        tx_req<=0;
    end
    else if(tx_start_en_reg && tx_req_cnt == 3 && tx_rx_cnt == 2)begin
        tx_num_cnt<=tx_num_cnt+1;
        tx_req <=1;
    end
    else begin
        tx_num_cnt <=tx_num_cnt;
        tx_req <= 0;
    end
end
endmodule