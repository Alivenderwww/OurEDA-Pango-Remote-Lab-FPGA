module pwm(
    input wire sysclk,     // 27MHz 系统时钟
    input wire rstn,    // 低有效复位
    output wire led     // PWM 控制LED输出
);

parameter PWM_PERIOD = 16'd27000;//1ms
// 单一PWM周期，1ms
// duty上升的次数是1000次，下降的次数也是1000次，说明pwm的半周期是 1ms * 1000 = 1s
// pwm的一次全周期是 1s * 2 = 2s
reg [15:0] pwm_cnt;
reg [15:0] duty;
reg inc_dec_flag;//0表示duty+ ，1表示duty-
//计数器1，不断累加
always @(posedge sysclk or negedge rstn) begin
    if (!rstn)
        pwm_cnt <= 0;
    else if (pwm_cnt < PWM_PERIOD - 1)
        pwm_cnt <= pwm_cnt + 1;
    else
        pwm_cnt <= 0;
end
//计数器2，控制占空比，单一周期结束进行一次累加或者减
always @(posedge sysclk or negedge rstn) begin
    if (!rstn)
        duty <= 0;
    else if (pwm_cnt == PWM_PERIOD - 1)begin
        if(inc_dec_flag == 0)
            duty <= duty + 27;
        else 
            duty <= duty - 27;
    end
    else duty <= duty;
end
//加减的标志位，半周期结束后反转。
always @(posedge sysclk or negedge rstn) begin
    if(~rstn)
        inc_dec_flag <= 0;
    else if(duty == PWM_PERIOD)
        inc_dec_flag <= 1;
    else if(duty == 0)
        inc_dec_flag <= 0;
    else 
        inc_dec_flag <= inc_dec_flag;
end

assign led = (pwm_cnt < duty) ? 1'b1 : 1'b0;
endmodule
