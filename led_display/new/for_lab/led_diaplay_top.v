
module led_diaplay_top(
    //system io
    input  wire       external_clk ,
    input  wire       external_rstn,
    //led display io
    output wire ser,
    output wire sck,
    output wire rck
);

reg [43*8-1:0] assic_seg;
reg [31:0]     seg_point;

reg [31:0] clk_cnt;
always @(posedge external_clk or negedge external_rstn) begin
    if(!external_rstn) clk_cnt <= 0;
    else clk_cnt <= clk_cnt + 1;
end

always @(posedge external_clk or negedge external_rstn) begin
    if(!external_rstn) begin
        assic_seg <= "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ -_=+()";
        seg_point <= 32'b00000001;
    end else if({clk_cnt[24]==1'b1} && (clk_cnt[23:0]==24'b0))begin
        assic_seg <= {assic_seg[8*43-8-1:0], assic_seg[8*43-1 -: 8]};
        seg_point <= {seg_point[30:0], seg_point[31]};
    end else begin
        assic_seg <= assic_seg;
        seg_point <= seg_point;
    end
end

led_display_assic # (
    .NUM(32)
  )
  led_display_assic_inst (
    .clk(external_clk),
    .rstn(external_rstn),
    .assic_seg(assic_seg[8*43-1 -: 8*32]),
    .seg_point(seg_point),
    .ser(ser),
    .sck(sck),
    .rck(rck)
  );

endmodule //led_diaplay_top
