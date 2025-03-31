module led8_btn(
    input  wire clk,
    input  wire rstn,

    input  wire [16*8-1:0] data_in,
    input  wire       btn_up,
    input  wire       btn_down,
    output  reg [7:0] led,
    output wire [7:0] led_n,
    output  reg [3:0] bcd,
    output wire [3:0] bcd_n
);

reg btn_up_d0, btn_up_d1;
reg [5:0] cnt0;
wire btn_up_neg = (~btn_up_d0) & (btn_up_d1);
wire btn_up_neg_d = (cnt0 == 6'b111111);
always @(posedge clk) begin
    if(~rstn) cnt0 <= 0;
    else if(cnt0==0 && btn_up_neg_d) cnt0 <= cnt0 + 1;
    else if(cnt0!=0) cnt0 <= cnt0 + 1;
    else cnt0 <= 0;
end

reg btn_down_d0, btn_down_d1;
reg [5:0] cnt1;
wire btn_down_neg = (~btn_down_d0) & (btn_down_d1);
wire btn_down_neg_d = (cnt1 == 6'b111111);
always @(posedge clk) begin
    btn_up_d0 <= btn_up;
    btn_up_d1 <= btn_up_d0;
end
always @(posedge clk) begin
    btn_down_d0 <= btn_down;
    btn_down_d1 <= btn_down_d0;
end
always @(posedge clk) begin
    if(~rstn) cnt1 <= 0;
    else if(cnt1==0 && btn_up_neg_d) cnt1 <= cnt1 + 1;
    else if(cnt1!=0) cnt1 <= cnt1 + 1;
    else cnt1 <= 0;
end

always @(posedge clk) begin
    if(~rstn) bcd <= 0;
    else if(btn_up_neg_d) bcd <= bcd + 1;
    else if(btn_down_neg_d) bcd <= bcd - 1;
    else bcd <= bcd;
end

always @(*) begin
    case (bcd)
        4'b0000: led <= data_in[(8*0)+:8];
        4'b0001: led <= data_in[(8*1)+:8];
        4'b0010: led <= data_in[(8*2)+:8];
        4'b0011: led <= data_in[(8*3)+:8];
        4'b0100: led <= data_in[(8*4)+:8];
        4'b0101: led <= data_in[(8*5)+:8];
        4'b0110: led <= data_in[(8*6)+:8];
        4'b0111: led <= data_in[(8*7)+:8];
        4'b1000: led <= data_in[(8*8)+:8];
        4'b1001: led <= data_in[(8*9)+:8];
        4'b1010: led <= data_in[(8*10)+:8];
        4'b1011: led <= data_in[(8*11)+:8];
        4'b1100: led <= data_in[(8*12)+:8];
        4'b1101: led <= data_in[(8*13)+:8];
        4'b1110: led <= data_in[(8*14)+:8];
        4'b1111: led <= data_in[(8*15)+:8];
    endcase
end

assign bcd_n = ~bcd;
assign led_n = ~led;

endmodule