`timescale 1ns/1ns
module pwm_tb;

    reg sysclk;
    reg rstn;
    wire led;

    // 实例化待测试模块
    pwm #(
        .PWM_PERIOD(270)//为了减少仿真时间，将单一pwm周期从27000等比例缩小为270
    ) pwm_inst (
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
