module led_display_seg_ctrl (
    input wire            clk,//27M
    input wire            rstn,
    input wire [31:0]     led_en,
    input wire [8*32-1:0] assic_seg, //ASSIC coding
    input wire [31:0]     seg_point, //显示小数点

    output reg [7:0]      seg,
    output reg [4:0]      sel
);
reg [32*8-1:0] led_in;
//遵循100HZ无闪烁规则
parameter CNT_100Hz = 32'd8000;
reg [31:0] cnt;
reg sel_flag;
reg seg_flag;
always @(posedge clk or negedge rstn) begin
    if(~rstn)
        cnt <= 0;
    else if(cnt == CNT_100Hz)
        cnt <= 0;
    else 
        cnt <= cnt + 1;
end
always @(posedge clk or negedge rstn) begin
    if(~rstn)
        sel_flag <= 0;
    else if(cnt == CNT_100Hz - 2) 
        sel_flag <= 1;
    else 
        sel_flag <= 0;
end
always @(posedge clk or negedge rstn) begin
    if(~rstn)
        seg_flag <= 0;
    else if(cnt == CNT_100Hz - 1) 
        seg_flag <= 1;
    else 
        seg_flag <= 0;
end
//******************************************//
always @(posedge clk or negedge rstn) begin
    if(~rstn)
        sel <= 0;
    else if(sel_flag)begin
        if(sel == 31)
            sel <= 0;
        else 
            sel <= sel + 1;
    end
    else 
        sel <= sel;
end
always @(posedge clk or negedge rstn) begin
    if(~rstn)
        seg <= 0;
    else if(seg_flag)
        seg <= led_in[sel*8 +: 8];
    else 
        seg <= seg;
end

//
integer i;
always @(*) begin
    led_in = 0;
    for(i=0;i<32;i=i+1) begin //led_in[i*8 +: 8] <---> assic_seg[i*8 +: 8]
        if(led_en[i] == 0)
            led_in[i*8 +: 8] = 8'h00;
        else 
            case (assic_seg[i*8 +: 8])
                "0":     led_in[i*8 +: 8] = (8'h3f) | {seg_point[i],7'b0};
                "1":     led_in[i*8 +: 8] = (8'h06) | {seg_point[i],7'b0};
                "2":     led_in[i*8 +: 8] = (8'h5b) | {seg_point[i],7'b0};
                "3":     led_in[i*8 +: 8] = (8'h4f) | {seg_point[i],7'b0};
                "4":     led_in[i*8 +: 8] = (8'h66) | {seg_point[i],7'b0};
                "5":     led_in[i*8 +: 8] = (8'h6d) | {seg_point[i],7'b0};
                "6":     led_in[i*8 +: 8] = (8'h7d) | {seg_point[i],7'b0};
                "7":     led_in[i*8 +: 8] = (8'h07) | {seg_point[i],7'b0};
                "8":     led_in[i*8 +: 8] = (8'h7f) | {seg_point[i],7'b0};
                "9":     led_in[i*8 +: 8] = (8'h6f) | {seg_point[i],7'b0};
                "A","a": led_in[i*8 +: 8] = (8'h77) | {seg_point[i],7'b0};
                "B","b": led_in[i*8 +: 8] = (8'h7c) | {seg_point[i],7'b0};
                "C","c": led_in[i*8 +: 8] = (8'h39) | {seg_point[i],7'b0};
                "D","d": led_in[i*8 +: 8] = (8'h5e) | {seg_point[i],7'b0};
                "E","e": led_in[i*8 +: 8] = (8'h79) | {seg_point[i],7'b0};
                "F","f": led_in[i*8 +: 8] = (8'h71) | {seg_point[i],7'b0};
                "G","g": led_in[i*8 +: 8] = (8'h3d) | {seg_point[i],7'b0};
                "H","h": led_in[i*8 +: 8] = (8'h76) | {seg_point[i],7'b0};
                "I","i": led_in[i*8 +: 8] = (8'h0f) | {seg_point[i],7'b0};
                "J","j": led_in[i*8 +: 8] = (8'h0e) | {seg_point[i],7'b0};
                "K","k": led_in[i*8 +: 8] = (8'h75) | {seg_point[i],7'b0};
                "L","l": led_in[i*8 +: 8] = (8'h38) | {seg_point[i],7'b0};
                "M","m": led_in[i*8 +: 8] = (8'h37) | {seg_point[i],7'b0};
                "N","n": led_in[i*8 +: 8] = (8'h54) | {seg_point[i],7'b0};
                "O","o": led_in[i*8 +: 8] = (8'h5c) | {seg_point[i],7'b0};
                "P","p": led_in[i*8 +: 8] = (8'h73) | {seg_point[i],7'b0};
                "Q","q": led_in[i*8 +: 8] = (8'h67) | {seg_point[i],7'b0};
                "R","r": led_in[i*8 +: 8] = (8'h31) | {seg_point[i],7'b0};
                "S","s": led_in[i*8 +: 8] = (8'h49) | {seg_point[i],7'b0};
                "T","t": led_in[i*8 +: 8] = (8'h78) | {seg_point[i],7'b0};
                "U","u": led_in[i*8 +: 8] = (8'h3e) | {seg_point[i],7'b0};
                "V","v": led_in[i*8 +: 8] = (8'h1c) | {seg_point[i],7'b0};
                "W","w": led_in[i*8 +: 8] = (8'h7e) | {seg_point[i],7'b0};
                "X","x": led_in[i*8 +: 8] = (8'h64) | {seg_point[i],7'b0};
                "Y","y": led_in[i*8 +: 8] = (8'h6e) | {seg_point[i],7'b0};
                "Z","z": led_in[i*8 +: 8] = (8'h59) | {seg_point[i],7'b0};
                " ":     led_in[i*8 +: 8] = (8'h00) | {seg_point[i],7'b0};
                "-":     led_in[i*8 +: 8] = (8'h40) | {seg_point[i],7'b0};
                "_":     led_in[i*8 +: 8] = (8'h08) | {seg_point[i],7'b0};
                "=":     led_in[i*8 +: 8] = (8'h48) | {seg_point[i],7'b0};
                "+":     led_in[i*8 +: 8] = (8'h5c) | {seg_point[i],7'b0};
                "(":     led_in[i*8 +: 8] = (8'h39) | {seg_point[i],7'b0};
                ")":     led_in[i*8 +: 8] = (8'h0F) | {seg_point[i],7'b0};
                default: led_in[i*8 +: 8] = (8'h00) | {seg_point[i],7'b0};
            endcase
    end
end
//********************************//

endmodule