module frequency_meter(
    input         clk,
    input         rstn,       // 复位信号
    output        ad_clk,     // AD时钟
    input  [7:0]  ad_data,    // AD输入数据
    output rck,
    output sck,
    output ser
);
wire ad_pulse;
wire [19:0] data_fx;
wire [25:0] bcd;
wire [31:0] data_bcd;
wire [63:0] asciidata;
assign data_bcd = {6'b00,bcd};
//生成ad驱动时钟，由于使用杜邦线连接，ad_clk不要超过10M
PLL PLLinst(
    .clkout0(ad_clk),    // output 10M
    .lock(),
    .clkin1(clk)       // input
);

pulse_gen  pulse_gen_inst (
    .rstn(rstn),
    .trig_level(8'd128),
    .ad_clk(ad_clk),
    .ad_data(ad_data),
    .ad_pulse(ad_pulse)
  );

cymometer # (
    .CLK_FS(32'd27_000_000)
  )
  cymometer_inst (
    .clk_fs(clk),
    .rstn(rstn),
    .clk_fx(ad_pulse),
    .data_fx(data_fx)
  );
//二进制转bcd码模块
bin2bcd # (
    .W(20)
  )
  bin2bcd_inst (
    .bin(data_fx),
    .bcd(bcd)
  );
//4位BCD码转ascii模块，例化8次使8个bcd同时输出ascii
genvar i;
generate
  for (i = 0; i < 8; i = i + 1) begin : generate_module
    bcd2ascii  bcd2ascii_inst (
        .bcd(data_bcd[i*4 +:4]),
        .asciidata(asciidata[i*8 +: 8])
      );
  end
endgenerate
//数码管显示模块
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
    .NUM(8),
    .MODE(1)
)led_display_seg_ctrl_inst(
    .clk(clk),
    .rstn(rstn),
    .led_en(32'hFFFFFFFF),
    .assic_seg(asciidata),
//    .assic_seg({{(31){8'h00}},"3"}),
    .seg_point(32'hFFFFFFFF),
    .seg(seg),
    .sel(sel)
  );
endmodule