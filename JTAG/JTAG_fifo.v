module cmd_bit_fifo (
    input wire clk          ,
    input wire rst          ,

    input wire wr_en        ,
    input wire wr_bit       ,

    input wire rd_en        ,
    output wire rd_bit      ,

    output wire full        ,
    output wire empty       ,
    output wire almost_full ,
    output wire almost_empty
);

localparam ADDR_WIDTH = 10;

reg [(1 << ADDR_WIDTH)-1:0] fifo_ram;

reg [ADDR_WIDTH:0] rd_ptr, wr_ptr;
wire [ADDR_WIDTH:0] rd_next_ptr = rd_ptr + 1;
wire [ADDR_WIDTH:0] wr_next_ptr = wr_ptr + 1;
wire [ADDR_WIDTH-1:0] rd_addr = rd_ptr[ADDR_WIDTH-1:0];
wire [ADDR_WIDTH-1:0] wr_addr = wr_ptr[ADDR_WIDTH-1:0];

assign full = ((rd_ptr ^ wr_ptr) == {1'b1,{(ADDR_WIDTH-1){1'b0}}});
assign empty = (rd_ptr == wr_ptr);
assign almost_full = ((wr_next_ptr ^ rd_ptr) == {1'b1,{(ADDR_WIDTH-1){1'b0}}}) | full;
assign almost_empty = (rd_next_ptr == wr_ptr) | empty;

always @(posedge clk) begin
    if(rst) fifo_ram <= 0;
    else if((full == 0) && (wr_en == 1)) fifo_ram[wr_addr] <= wr_bit;
    else fifo_ram <= fifo_ram;
end

assign rd_bit = fifo_ram[rd_addr];

always @(posedge clk) begin
    if(rst) rd_ptr <= 0;
    else if((empty == 0) && (rd_en == 1)) rd_ptr <= rd_next_ptr;
    else rd_ptr <= rd_ptr;
end

always @(posedge clk) begin
    if(rst) wr_ptr <= 0;
    else if((full == 0) && (wr_en == 1)) wr_ptr <= wr_next_ptr;
    else wr_ptr <= wr_ptr;
end


endmodule