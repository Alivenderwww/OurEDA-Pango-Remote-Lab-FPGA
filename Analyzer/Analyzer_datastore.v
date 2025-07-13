module Analyzer_datastore #(
    parameter WAVE_ADDR_WIDTH = 12, // 波形存储地址宽度
    parameter DIGITAL_IN_NUM = 8   // 数字输入引脚数量
    )(
    input  wire                       clk,
    input  wire                       rstn,
    input  wire [DIGITAL_IN_NUM-1:0]  digital_in, // 输入数字信号
    input  wire                       trig,       // 触发信号，##高电平##触发
    output wire                       busy,       // 采集忙
    output wire                       done,       // 采集完成
    input  wire [WAVE_ADDR_WIDTH-1:0] wave_addr,  // 读存储地址
    output wire [31:0]                wave_out    // 输出数据
);
/*
逻辑分析仪组件
输入时钟、复位、控制信号和待测引脚
作为AXI从机存储测量值至RAM中等待主机读取
*/
localparam SAVE_CNT = (1 << WAVE_ADDR_WIDTH); // 存储采样点数
reg [WAVE_ADDR_WIDTH-1:0] write_addr; // 采样点计数器，同时也是写地址

localparam ST_IDLE       = 2'b00,
           ST_COLLECTING = 2'b01,
           ST_DONE       = 2'b10;
reg [1:0] current_state, next_state;

reg [DIGITAL_IN_NUM-1:0] ram_data [0: SAVE_CNT - 1]; // RAM数据存储

always @(posedge clk or negedge rstn) begin
    if (!rstn) current_state <= ST_IDLE;
    else current_state <= next_state;
end

always @(*) begin
    case (current_state)
        ST_IDLE      : next_state = (trig)?(ST_COLLECTING):(ST_IDLE);
        ST_COLLECTING: next_state = (write_addr >= SAVE_CNT - 1)?(ST_DONE):(ST_COLLECTING);
        ST_DONE      : next_state = (trig)?(ST_COLLECTING):(ST_DONE);
        default      : next_state = ST_IDLE;
    endcase
end

always @(posedge clk) begin
    if(!rstn) write_addr <= 0;
    else if(current_state == ST_COLLECTING) write_addr <= write_addr + 1;
    else if(current_state == ST_DONE) write_addr <= 0; // 完成后重置写地址
    else write_addr <= write_addr;
end

assign busy = (current_state == ST_COLLECTING);
assign done = (current_state == ST_DONE);

wire wr_en = (current_state == ST_COLLECTING);
analyzer_ram analyzer_ram_u (
  .wr_clk (clk),
  .wr_rst (~rstn),
  .wr_en  (wr_en),
  .wr_addr(write_addr),
  .wr_data(digital_in),

  .rd_clk (clk),
  .rd_rst (~rstn),
  .rd_addr(wave_addr),
  .rd_data(wave_out)
);

endmodule //Analyzer