`timescale 1ns/1ns
module btn_ggle_tb;

reg clk;
reg rstn;
reg btn;
wire btn_flag;
wire [7:0] led;
btn_ggle btn_ggle_inst (
    .clk(clk),
    .rstn(rstn),
    .btn(btn),
    .btn_flag(btn_flag),
    .led(led)
);

// 27MHz 时钟周期约为 37.037ns，取37ns近似
always #(500/27) clk = ~clk; // 半周期18.5ns ≈ 27MHz

initial begin
    // 初始化
    clk = 0;
    rstn = 0;
    btn = 1;        // 按键默认未按下，高电平有效

    // 释放复位
    #200;
    rstn = 1;

    // 模拟带抖动的按下过程
    #1000  btn = 0;
    #100   btn = 1; // 抖动
    #100   btn = 0;
    #100   btn = 1;
    #100   btn = 0;
    // 稳定按下
    #100000 btn = 0;

    // 模拟抖动松开过程
    #300000 btn = 1;
    #100    btn = 0;
    #100    btn = 1;
    #100    btn = 0;
    #100    btn = 1;
    // 稳定松开
    #100000 btn = 1;

    // 第二次按下
    #300000 btn = 0;
    #100000 btn = 0;

    #300000 $finish;
end

endmodule
