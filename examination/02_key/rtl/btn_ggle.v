module btn_ggle(
    input wire clk,
    input wire rstn,
    input wire btn,
    output wire btn_flag,
    output reg [7:0] led
);
reg btn_ggle;
reg btn_flag_d0,btn_flag_d1;
reg [7:0] cnt;
reg btn_temp;
//检测按键状态
always @(posedge clk) btn_temp <= btn;
//按键状态改变时开始计数
always @(posedge clk) begin
    if(~rstn) cnt <= 0;
    else if(btn_temp != btn) cnt <= 1;
    else if(cnt != 0) cnt <= cnt + 1;
    else cnt <= 0;
end
//计数到255时认为按键值稳定
always @(posedge clk) begin
    if(~rstn) btn_ggle <= btn;
    else if(cnt == 8'hFF) btn_ggle <= btn_temp;
    else btn_ggle <= btn_ggle;
end
//对btn_ggle信号延迟打拍
always @(posedge clk) begin
    if(~rstn) begin
        btn_flag_d0 <= 0;
        btn_flag_d1 <= 0;
    end
    else begin
        btn_flag_d0 <= btn_ggle;
        btn_flag_d1 <= btn_flag_d0;
    end
end
//btn_flag检测btn_ggle的下降沿
assign btn_flag = ~btn_flag_d0 && btn_flag_d1;
//检测到按键按下的标志位（btn_flag），led会加1
always @(posedge clk) begin
    if(~rstn) led <= 0;
    else if(btn_flag) led <= led + 1;
    else led <= led;
end
endmodule 