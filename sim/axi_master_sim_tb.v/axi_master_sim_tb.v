`timescale 1ns/1ps
module axi_master_sim_tb ();

reg clk;
reg rst;
always #10 clk = ~clk;

wire       WR_ADDR_READY ;
wire       WR_DATA_READY ;
wire       RD_ADDR_READY ;
wire       RD_DATA_VALID ;
wire       RD_DATA_LAST  ; 
wire [ 1:0] WR_BACK_ID   ;
wire [ 1:0] RD_BACK_ID   ;
wire [31:0] RD_DATA      ;
wire [31:0] WR_ADDR      ;
wire [ 7:0] WR_LEN       ;
wire [ 1:0] WR_ID        ;
wire        WR_ADDR_VALID;
wire [31:0] WR_DATA      ;
wire [ 3:0] WR_STRB      ;
wire        WR_DATA_VALID;
wire        WR_DATA_LAST ;
wire [31:0] RD_ADDR      ;
wire [ 7:0] RD_LEN       ;
wire [ 1:0] RD_ID        ;
wire        RD_ADDR_VALID;
wire        RD_DATA_READY;

initial begin
    clk = 0;
    rst = 1;
    #500
    rst = 0;
end

reg [3:0] wr_addr_cnt; //MASTER的写地址线通道，测试用
assign WR_ADDR_READY = (wr_addr_cnt == 4'b1111);
always @(posedge clk) begin
    if(rst) wr_addr_cnt <= 0;
    else if(WR_ADDR_VALID)begin
        wr_addr_cnt <= (wr_addr_cnt==4'b1111)?(wr_addr_cnt):(wr_addr_cnt + 1);
    end else wr_addr_cnt <= 0;
end

reg [3:0] rd_addr_cnt; //MASTER的读地址线通道，测试用
assign RD_ADDR_READY = (rd_addr_cnt == 4'b1111);
always @(posedge clk) begin
    if(rst) rd_addr_cnt <= 0;
    else if(RD_ADDR_VALID)begin
        rd_addr_cnt <= (rd_addr_cnt==4'b1111)?(rd_addr_cnt):(rd_addr_cnt + 1);
    end else rd_addr_cnt <= 0;
end

reg [3:0] wr_data_cnt; //MASTER的写数据线通道，测试用
assign WR_BACK_ID = 0;
assign WR_DATA_READY = (wr_data_cnt == 4'b1111);
always @(posedge clk) begin
    if(rst) wr_data_cnt <= 0;
    else if(WR_DATA_VALID)begin
        wr_data_cnt <= (wr_data_cnt==4'b1111)?(wr_data_cnt):(wr_data_cnt + 1);
    end else wr_data_cnt <= 0;
end

reg [7:0] rd_data_cnt; //MASTER的读数据线通道，测试用
assign RD_BACK_ID = 0;
assign RD_DATA_VALID = (rd_data_cnt >= 8'd10 && rd_data_cnt <= 8'd110);
assign RD_DATA_LAST = (rd_data_cnt == 8'd110);
assign RD_DATA = rd_data_cnt - 10;
always @(posedge clk) begin
    if(rst) rd_data_cnt <= 0;
    else if(RD_DATA_READY)begin
        rd_data_cnt <= (rd_data_cnt == 8'd110)?(rd_data_cnt):(rd_data_cnt + 1);
    end else rd_data_cnt <= 0;
end

axi_master_sim axi_master_sim_inst(
    .clk           (clk           ),
    .rst           (rst           ),
    .WR_ADDR       (WR_ADDR       ),
    .WR_LEN        (WR_LEN        ),
    .WR_ID         (WR_ID         ),
    .WR_ADDR_VALID (WR_ADDR_VALID ),
    .WR_ADDR_READY (WR_ADDR_READY ),
    .WR_DATA       (WR_DATA       ),
    .WR_STRB       (WR_STRB       ),
    .WR_BACK_ID    (WR_BACK_ID    ),
    .WR_DATA_VALID (WR_DATA_VALID ),
    .WR_DATA_READY (WR_DATA_READY ),
    .WR_DATA_LAST  (WR_DATA_LAST  ),
    .RD_ADDR       (RD_ADDR       ),
    .RD_LEN        (RD_LEN        ),
    .RD_ID         (RD_ID         ),
    .RD_ADDR_VALID (RD_ADDR_VALID ),
    .RD_ADDR_READY (RD_ADDR_READY ),
    .RD_DATA       (RD_DATA       ),
    .RD_DATA_LAST  (RD_DATA_LAST  ),
    .RD_BACK_ID    (RD_BACK_ID    ),
    .RD_DATA_READY (RD_DATA_READY ),
    .RD_DATA_VALID (RD_DATA_VALID )
);


endmodule