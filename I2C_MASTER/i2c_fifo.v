module i2c_fifo #(
    parameter FIFO_DEPTH = 4 //FIFO深度(2**FIFO_DEPTH)
)( //为IIC专门做的带回退功能的FIFO
    input  wire clk,
    input  wire rstn,
    input  wire wr_en,
    input  wire [7:0] wr_data,
    output wire wr_full,
    input  wire wr_snapshot, //写快照信号
    input  wire wr_rollback, //写回退信号

    input  wire rd_en,
    output  reg [7:0] rd_data,
    output wire rd_empty,
    input  wire rd_snapshot, //读快照信号
    input  wire rd_rollback  //读回退信号
);

reg [7:0] fifo_mem [0:(2**FIFO_DEPTH)-1]; //FIFO存储器
reg [FIFO_DEPTH:0] wr_ptr, wr_ptr_snapshot; //写指针
reg [FIFO_DEPTH:0] rd_ptr, rd_ptr_snapshot; //读指针

assign rd_empty = (wr_ptr == rd_ptr);
assign wr_full  = (wr_ptr[FIFO_DEPTH] != rd_ptr[FIFO_DEPTH]) && (wr_ptr[FIFO_DEPTH-1:0] == rd_ptr[FIFO_DEPTH-1:0]);

always @(posedge clk or negedge rstn) begin
    if(~rstn) wr_ptr_snapshot <= 0;
    else if(wr_snapshot) wr_ptr_snapshot <= wr_ptr;
    else wr_ptr_snapshot <= wr_ptr_snapshot;
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) wr_ptr <= 0;
    else if(wr_en && (~wr_full)) wr_ptr <= wr_ptr + 1;
    else if(wr_rollback) wr_ptr <= wr_ptr_snapshot;
    else wr_ptr <= wr_ptr;
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) rd_ptr_snapshot <= 0;
    else if(rd_snapshot) rd_ptr_snapshot <= rd_ptr;
    else rd_ptr_snapshot <= rd_ptr_snapshot;
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) rd_ptr <= 0;
    else if(rd_en && (~rd_empty)) rd_ptr <= rd_ptr + 1;
    else if(rd_rollback) rd_ptr <= rd_ptr_snapshot;
    else rd_ptr <= rd_ptr;
end

integer i;
initial for(i=0; i<2**(FIFO_DEPTH)-1; i=i+1) fifo_mem[i] = 0;
always @(posedge clk) begin
    if(rstn) begin
        if(wr_en && (~wr_full)) fifo_mem[wr_ptr[FIFO_DEPTH-1:0]] <= wr_data;
        rd_data <= fifo_mem[rd_ptr[FIFO_DEPTH-1:0]];
    end
end


endmodule //i2c_fifo