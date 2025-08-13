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
led_display_seg_ctrl  led_display_seg_ctrl_inst (
    .clk(clk),
    .rstn(rstn),
    .led_en(32'hFFFFFFFF),
    .assic_seg({192'b0,"1","2","3","4","5","6","7","8"}),
    .seg_point(32'h0),
    .seg(seg),
    .sel(sel)
  );
endmodule