module led_diaplay_top (
    input  wire clk,
    input  wire rstn,
    output wire ser,
    output wire sck,
    output wire rck
);
wire [4:0] sel;
wire [7:0] seg;
hc595_ctrl  hc595_ctrl_inst (
    .sys_clk(clk),
    .sys_rst_n(rstn),
    .sel(sel),
    .seg(seg),
    .rck(rck),
    .sck(sck),
    .ser(ser)
  );    
led_display_seg_ctrl #(
    .NUM(32),
    .MODE(0)
)led_display_seg_ctrl_inst(
    .clk(clk),
    .rstn(rstn),
    .led_en(32'hFFFFFFFF),
    .assic_seg({"W","V","U","T","S","R","Q","P","O","N","M","L","K","J","I","H","G","F","E","D","C","B","A","9","8","7","6","5","4","3","2","1"}),
//    .assic_seg({{(31){8'h00}},"3"}),
    .seg_point(32'hFFFFFFFF),
    .seg(seg),
    .sel(sel)
  );
endmodule