module waterled_top(
    input sysclk,    //27MHz system clock
    input rstn,      //active low reset
    output [7:0] led
   );
    parameter CNT_MAX = 32'd13_499_999;
    reg [7:0] led_reg;
    reg [31:0] cnt;
    //cnt 当cnt == CNT_MAX时变为0，计数0.5秒
    always @(posedge sysclk) begin
        if (!rstn)
            cnt <= 0;
        else if (cnt < CNT_MAX)
            cnt <= cnt + 1;
        else 
            cnt <= 0;
    end
    //led_reg 当cnt == CNT_MAX时，左移一位。
    always @(posedge sysclk) begin
        if (!rstn)
            led_reg <= 8'b0000_0001;
        else if (led_reg == 8'b1000_0000 && cnt == CNT_MAX)//led7亮0.5s后重回led0
            led_reg <= 8'b0000_0001; 
        else if (cnt == CNT_MAX) //0.5s后左移
            led_reg <= led_reg << 1;
        else
            led_reg <= led_reg;
    end
    //led
    assign led = led_reg;
endmodule