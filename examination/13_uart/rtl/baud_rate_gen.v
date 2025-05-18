// UART波特率生成模块
module baud_rate_gen (
    input        clk,      // 50MHz主时钟
    input        rst_n,    // 低电平复位（异步）
    output reg   baud_en   // 波特率使能信号（每bit周期激活一次）
);

// 参数计算（50MHz时钟 → 9600波特率）
parameter CLK_FREQ = 50_000_000;  // 系统时钟频率
parameter BAUD_RATE = 9600;       // 目标波特率
localparam BAUD_DIV = CLK_FREQ / BAUD_RATE;  // 分频系数 = 5208

reg [12:0] count;  // 计数器（需覆盖0-5207）

// 计数器逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count <= 0;
        baud_en <= 0;
    end
    else begin
        if (count == BAUD_DIV - 1) begin  // 达到分频终点
            count <= 0;                   // 计数器归零
            baud_en <= 1;                 // 生成使能脉冲
        end
        else begin
            count <= count + 1;           // 正常计数
            baud_en <= 0;                 // 保持低电平
        end
    end
end

endmodule