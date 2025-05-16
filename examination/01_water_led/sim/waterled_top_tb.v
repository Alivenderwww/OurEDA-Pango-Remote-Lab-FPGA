`timescale 1ns/1ns
module waterled_top_tb;

    reg sysclk;
    reg rstn;
    wire [7:0] led;

    // 实例化待测试模块
    waterled_top #(
        .CNT_MAX(32'd100)//为了加快仿真速度，将模块内部CNT_MAX由13_499_999变为1000
    )waterled_top_inst (
        .sysclk(sysclk),
        .rstn(rstn),
        .led(led)
    );
    // 产生系统时钟：周期约为 27Mhz
    initial begin
        sysclk = 0;
        forever #(500/27) sysclk = ~sysclk;
    end

    // 初始化和复位过程
    initial begin
        // 初始化
        rstn = 0;
        #100;           // 保持复位100ns
        rstn = 1;       // 释放复位
    end

endmodule
