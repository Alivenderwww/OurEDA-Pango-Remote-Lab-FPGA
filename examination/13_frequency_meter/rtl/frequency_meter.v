module frequency_meter(
    input         clk,
    input         rstn,       // 复位信号
    output        ad_clk,     // AD时钟
    input  [7:0]  ad_data,    // AD输入数据
    output [7:0]  led_display_seg,
    output wire [7:0] led_display_sel
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
led_display_driver  led_display_driver_inst (
    .clk(clk),
    .rstn(rstn),
    .assic_seg(asciidata),
    .seg_point(8'b00000000),
    .led_display_seg(led_display_seg),
    .led_display_sel(led_display_sel)
  );
endmodule