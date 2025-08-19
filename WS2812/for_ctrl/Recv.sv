module Recv #(
    parameter DEPTH = 24, //RGB888
    parameter CLKHZ = 32'd50_000_000,
    parameter WS_NUM = 7
)(
    input wire clk,
    input wire rstn,
    input wire data_stream,
    output reg [DEPTH - 1:0] wscolor [WS_NUM],
    output reg data_valid
);

// WS2812时序参数 (考虑容错范围)
localparam
    TIME_0H_MIN = (32'd150    )/((32'd1000_000_000) / (CLKHZ)),  // 150ns
    TIME_0H_MAX = (32'd450    )/((32'd1000_000_000) / (CLKHZ)),  // 450ns
    TIME_1H_MIN = (32'd600    )/((32'd1000_000_000) / (CLKHZ)),  // 600ns
    TIME_1H_MAX = (32'd900    )/((32'd1000_000_000) / (CLKHZ)),  // 900ns
    TIME_LOW_MIN = (32'd600   )/((32'd1000_000_000) / (CLKHZ)),  // 600ns
    TIME_LOW_MAX = (32'd900   )/((32'd1000_000_000) / (CLKHZ)),  // 900ns
    TIME_RESET_MIN = (32'd80000)/((32'd1000_000_000) / (CLKHZ)); // 80us

// 状态定义
localparam ST_IDLE = 3'd0,
           ST_HIGH = 3'd1,
           ST_LOW  = 3'd2,
           ST_RESET = 3'd3;

// 寄存器定义
reg [2:0] state_current, state_next;
reg [31:0] cnt_high, cnt_low, cnt_reset;
reg data_stream_r1, data_stream_r2;
reg [DEPTH-1:0] shift_reg;
reg [4:0] bit_cnt;
reg [3:0] led_cnt;
reg bit_received;
reg [31:0] saved_high_time; // 保存高电平时间用于bit判断

// 边沿检测
wire pos_edge = data_stream && !data_stream_r1;
wire neg_edge = !data_stream && data_stream_r1;

// 同步输入信号
always @(posedge clk) begin
    if (!rstn) begin
        data_stream_r1 <= 1'b0;
        data_stream_r2 <= 1'b0;
    end else begin
        data_stream_r1 <= data_stream;
        data_stream_r2 <= data_stream_r1;
    end
end

// 状态机
always @(posedge clk) begin
    if (!rstn) 
        state_current <= ST_IDLE;
    else 
        state_current <= state_next;
end

always @(*) begin
    case (state_current)
        ST_IDLE: begin
            if (pos_edge)
                state_next = ST_HIGH;
            else if (!data_stream && cnt_reset >= TIME_RESET_MIN)
                state_next = ST_RESET;
            else
                state_next = ST_IDLE;
        end
        
        ST_HIGH: begin
            if (neg_edge)
                state_next = ST_LOW;
            else
                state_next = ST_HIGH;
        end
        
        ST_LOW: begin
            if (pos_edge)
                state_next = ST_HIGH;
            else if (cnt_low >= TIME_RESET_MIN)
                state_next = ST_RESET;
            else
                state_next = ST_LOW;
        end
        
        ST_RESET: begin
            if (pos_edge)
                state_next = ST_HIGH;
            else
                state_next = ST_RESET;
        end
        
        default: state_next = ST_IDLE;
    endcase
end

// 高电平时间计数器
always @(posedge clk) begin
    if (!rstn) begin
        cnt_high <= 0;
    end else if (state_current == ST_HIGH) begin
        cnt_high <= cnt_high + 1;
    end else if (pos_edge) begin
        cnt_high <= 0;  // 只在新的高电平开始时清零
    end
end

// 低电平时间计数器
always @(posedge clk) begin
    if (!rstn) begin
        cnt_low <= 0;
    end else if (state_current == ST_LOW) begin
        cnt_low <= cnt_low + 1;
    end else begin
        cnt_low <= 0;
    end
end

// 复位时间计数器
always @(posedge clk) begin
    if (!rstn) begin
        cnt_reset <= 0;
    end else if (!data_stream && (state_current == ST_IDLE || state_current == ST_LOW)) begin
        cnt_reset <= cnt_reset + 1;
    end else begin
        cnt_reset <= 0;
    end
end

// 位识别和数据接收
always @(posedge clk) begin
    if (!rstn) begin
        bit_received <= 1'b0;
        saved_high_time <= 0;
    end else if (state_current == ST_LOW && state_next == ST_HIGH) begin
        // 低电平结束，判断之前的位并保存高电平时间
        saved_high_time <= cnt_high;
        if (cnt_high >= TIME_0H_MIN && cnt_high <= TIME_0H_MAX && 
            cnt_low >= TIME_LOW_MIN && cnt_low <= TIME_LOW_MAX) begin
            bit_received <= 1'b1; // 接收到bit 0
        end else if (cnt_high >= TIME_1H_MIN && cnt_high <= TIME_1H_MAX && 
                     cnt_low >= TIME_LOW_MIN && cnt_low <= TIME_LOW_MAX) begin
            bit_received <= 1'b1; // 接收到bit 1
        end else begin
            bit_received <= 1'b0;
        end
    end else if (state_current == ST_LOW && state_next == ST_RESET) begin
        // 进入复位状态，最后一位
        saved_high_time <= cnt_high;
        if (cnt_high >= TIME_0H_MIN && cnt_high <= TIME_0H_MAX) begin
            bit_received <= 1'b1; // 接收到bit 0
        end else if (cnt_high >= TIME_1H_MIN && cnt_high <= TIME_1H_MAX) begin
            bit_received <= 1'b1; // 接收到bit 1
        end else begin
            bit_received <= 1'b0;
        end
    end else begin
        bit_received <= 1'b0;
    end
end

// 移位寄存器和计数器
always @(posedge clk) begin
    if (!rstn) begin
        shift_reg <= 0;
        bit_cnt <= 0;
        led_cnt <= 0;
    end else if (state_next == ST_RESET) begin
        // 复位状态，清零计数器
        bit_cnt <= 0;
        led_cnt <= 0;
    end else if (bit_received) begin
        // 判断接收到的位值
        if (saved_high_time >= TIME_1H_MIN && saved_high_time <= TIME_1H_MAX) begin
            shift_reg <= {shift_reg[DEPTH-2:0], 1'b1}; // bit 1
        end else begin
            shift_reg <= {shift_reg[DEPTH-2:0], 1'b0}; // bit 0
        end
        
        if (bit_cnt == DEPTH - 1) begin
            bit_cnt <= 0;
            if (led_cnt < WS_NUM - 1)
                led_cnt <= led_cnt + 1;
        end else begin
            bit_cnt <= bit_cnt + 1;
        end
    end
end

// 输出颜色数据 (GRB -> RGB转换)
integer i;
always @(posedge clk) begin
    if (!rstn) begin
        for (i = 0; i < WS_NUM; i = i + 1) begin
            wscolor[i] <= 0;
        end
        data_valid <= 1'b0;
    end else if (bit_received && bit_cnt == DEPTH - 1) begin
        // 完成一个LED的数据接收，进行GRB到RGB的转换
        wscolor[led_cnt] <= {shift_reg[15:8], shift_reg[23:16], shift_reg[7:0]};
        
        // 如果接收完所有LED数据，置位有效标志
        if (led_cnt == WS_NUM - 1) begin
            data_valid <= 1'b1;
        end
    end else if (state_next == ST_RESET) begin
        data_valid <= 1'b0;
    end
end

endmodule