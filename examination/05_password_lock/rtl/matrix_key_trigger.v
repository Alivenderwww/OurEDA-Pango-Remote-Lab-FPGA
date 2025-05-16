module matrix_key_trigger(
    input  wire clk,
    input  wire rstn,
    input  wire [15:0] key,
    output wire [15:0] key_trigger
);

// 按键上升沿捕获模块

reg [15:0] key_d; // 上一时钟周期的按键状态
reg [15:0] key_d2; // 上两时钟周期的按键状态

assign key_trigger = (key_d) & (~key_d2);

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        key_d <= 0;
        key_d2 <= 0;
    end else begin
        key_d <= key;
        key_d2 <= key_d;
    end
end

endmodule //matrix_key_decode