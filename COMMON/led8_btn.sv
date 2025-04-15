module led8_btn(
    input  wire clk,
    input  wire rstn,

    input  wire [15:0][7:0] data_in,
    input  wire       btn_up,
    input  wire       btn_down,
    output  reg [7:0] led,
    output wire [7:0] led_n,
    output  reg [3:0] bcd,
    output wire [3:0] bcd_n
);

wire btn_up_ggle, btn_down_ggle;
btn_ggle btn_ggle0(clk, rstn, btn_up, btn_up_ggle);
btn_ggle btn_ggle1(clk, rstn, btn_down, btn_down_ggle);

reg btn_up_d0, btn_up_d1;
wire btn_up_neg = (~btn_up_d0) & (btn_up_d1);
always @(posedge clk) begin
    btn_up_d0 <= btn_up_ggle;
    btn_up_d1 <= btn_up_d0;
end

reg btn_down_d0, btn_down_d1;
wire btn_down_neg = (~btn_down_d0) & (btn_down_d1);
always @(posedge clk) begin
    btn_down_d0 <= btn_down_ggle;
    btn_down_d1 <= btn_down_d0;
end

always @(posedge clk) begin
    if(~rstn) bcd <= 0;
    else if(btn_up_neg) bcd <= bcd + 1;
    else if(btn_down_neg) bcd <= bcd - 1;
    else bcd <= bcd;
end

always @(*) begin
    case (bcd)
        4'b0000: led <= data_in[0];
        4'b0001: led <= data_in[1];
        4'b0010: led <= data_in[2];
        4'b0011: led <= data_in[3];
        4'b0100: led <= data_in[4];
        4'b0101: led <= data_in[5];
        4'b0110: led <= data_in[6];
        4'b0111: led <= data_in[7];
        4'b1000: led <= data_in[8];
        4'b1001: led <= data_in[9];
        4'b1010: led <= data_in[10];
        4'b1011: led <= data_in[11];
        4'b1100: led <= data_in[12];
        4'b1101: led <= data_in[13];
        4'b1110: led <= data_in[14];
        4'b1111: led <= data_in[15];
    endcase
end

assign bcd_n = ~bcd;
assign led_n = ~led;

endmodule