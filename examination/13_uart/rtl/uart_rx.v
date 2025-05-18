module uart_rx (
    input        clk,        // 50MHz主时钟
    input        rst_n,      // 低电平复位
    input        rx,    // 串行输入信号
    input        baud_en,    // 波特率使能信号
    output reg [7:0] rx_data,  // 接收到的并行数据
    output reg       data_valid // 数据有效标志
);

// 接收状态机定义
localparam [2:0] 
    IDLE  = 3'b000,    // 空闲状态
    START = 3'b001,    // 检测起始位
    DATA  = 3'b010,    // 接收数据位
    STOP  = 3'b011;    // 检测停止位

reg [2:0] state;        // 当前状态
reg [2:0] bit_count;    // 已接收数据位计数
reg [7:0] shift_reg;    // 数据移位寄存器

// 状态机控制逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state      <= IDLE;
        bit_count  <= 0;
        shift_reg  <= 8'h00;
        rx_data   <= 8'h00;
        data_valid <= 0;
    end
    else if (baud_en) begin  // 仅在波特率使能时处理
        case (state)
            IDLE: begin
                data_valid <= 0;
                if (!rx) begin         // 检测起始位（下降沿）
                    state     <= START;
                    bit_count <= 0;
                end
            end
            
            START: begin
                if (!rx) begin         // 确认起始位有效
                    state <= DATA;           // 进入数据接收状态
                end
                else begin
                    state <= IDLE;          // 无效起始位，返回空闲
                end
            end
            
            DATA: begin
                if (bit_count < 7) begin
                    // 在数据位中间采样（提高抗噪能力）
                    shift_reg <= {rx, shift_reg[7:1]};
                    bit_count <= bit_count + 1;
                end
                else begin
                    shift_reg <= {rx, shift_reg[7:1]};  // 最后一位
                    state     <= STOP;
                end
            end
            
            STOP: begin
                if (rx) begin          // 验证停止位（应为高电平）
                    rx_data   <= shift_reg;  // 锁存有效数据
                    data_valid <= 1;          // 输出有效标志
                end
                else begin                  // 停止位错误
                    data_valid <= 0;        // 可添加错误标志
                end
                state <= IDLE;              // 返回空闲状态
            end
            
            default: state <= IDLE;
        endcase
    end
end

endmodule