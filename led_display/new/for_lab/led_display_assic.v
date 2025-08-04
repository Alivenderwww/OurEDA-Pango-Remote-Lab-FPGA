module led_display_assic #(
    parameter NUM = 32
)(// 8个数码管显示，阳极管（在selector中已经做了阴阳处理）
    input wire            clk,
    input wire            rstn,
    input wire [8*32-1:0] assic_seg, //ASSIC coding
    input wire [31:0]     seg_point, //显示小数点

    output wire           ser                    ,      //串行输出，先输出Q15，最后输出Q0
    output wire           sck                    ,      //串行输出时钟
    output wire           rck                           //并行输出时钟
);

reg [NUM*8-1:0] led_in;

integer i;
always @(*) begin
    led_in = 0;
    for(i=0;i<NUM;i=i+1) begin //led_in[i*8 +: 8] <---> assic_seg[i*8 +: 8]
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

leddisplay_driver # (
    .NUM(NUM),
    .CLK_CYCLE(1000)
  )
  leddisplay_driver_inst (
    .clk(clk),
    .rstn(rstn),
    .led_in(led_in),
    .ser(ser),
    .sck(sck),
    .rck(rck)
  );

endmodule //moduleName
