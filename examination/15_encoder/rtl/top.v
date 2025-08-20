module top (
    input clk,
    input rstn,
    input A_1,
    input B_1,
    input A_2,
    input B_2,
    input A_3,
    input B_3,
    input encoder_keyin_1,
    input encoder_keyin_2,
    output sck,
    output rck,
    output ser
);
wire [19:0] cnt_1;
wire [19:0] cnt_2;
wire [19:0] cnt_3;
wire [4:0] sel;
wire [7:0] seg;
wire [25:0] bcd_1;
wire [25:0] bcd_2;
wire [25:0] bcd_3;
wire [31:0] data_bcd_1;
wire [31:0] data_bcd_2;
wire [31:0] data_bcd_3;
wire [63:0] asciidata_1;
wire [63:0] asciidata_2;
wire [63:0] asciidata_3;
assign data_bcd_1 = {6'b00,bcd_1};
assign data_bcd_2 = {6'b00,bcd_2};
assign data_bcd_3 = {6'b00,bcd_3};
//二进制转bcd码模块
bin2bcd # (
    .W(20)
  )
  bin2bcd_inst_1 (
    .bin(cnt_1),
    .bcd(bcd_1)
  );

bin2bcd # (
    .W(20)
  )
  bin2bcd_inst_2 (
    .bin(cnt_2),
    .bcd(bcd_2)
  );

bin2bcd # (
    .W(20)
  )
  bin2bcd_inst_3 (
    .bin(cnt_3),
    .bcd(bcd_3)
  );
//4位BCD码转ascii模块，例化8次使8个bcd同时输出ascii
genvar i;
generate
  for (i = 0; i < 8; i = i + 1) begin : generate_module_1
    bcd2ascii  bcd2ascii_inst_1 (
        .bcd(data_bcd_1[i*4 +:4]),
        .asciidata(asciidata_1[i*8 +: 8])
      );
  end
  for (i = 0; i < 8; i = i + 1) begin : generate_module_2
    bcd2ascii  bcd2ascii_inst_2 (
        .bcd(data_bcd_2[i*4 +:4]),
        .asciidata(asciidata_2[i*8 +: 8])
      );
  end
  for (i = 0; i < 8; i = i + 1) begin : generate_module_3
    bcd2ascii  bcd2ascii_inst_3 (
        .bcd(data_bcd_3[i*4 +:4]),
        .asciidata(asciidata_3[i*8 +: 8])
      );
  end
endgenerate
abcode  abcode_inst_1 (
    .clk(clk),
    .rstn(rstn),
    .A(A_1),
    .B(B_1),
    .keyin(encoder_keyin_1),
    .testcnt(cnt_1)
  );
abcode  abcode_inst_2 (
    .clk(clk),
    .rstn(rstn),
    .A(A_2),
    .B(B_2),
    .keyin(encoder_keyin_2),
    .testcnt(cnt_2)
  );
abcode  abcode_inst_3 (
    .clk(clk),
    .rstn(rstn),
    .A(A_3),
    .B(B_3),
    .keyin(),
    .testcnt(cnt_3)
  );
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
    .NUM(24),
    .MODE(1)
)led_display_seg_ctrl_inst(
    .clk(clk),
    .rstn(rstn),
    .led_en(32'hFFFFFFFF),
    .assic_seg({asciidata_1,asciidata_2,asciidata_3}),
    .seg_point(32'hFFFFFFFF),
    .seg(seg),
    .sel(sel)
  );
endmodule