`timescale 1ns / 1ns
module hdmi_top(
    input wire          sys_clk       ,// input system clock 50MHz   
    input               rstn_in       , 
    output              rstn_out      ,
    output              hd_scl        ,
    inout               hd_sda        ,
    output              led_int       ,

//hdmi_out 
    output              pixclk_out    ,//pixclk                           
    output  wire        vs_out        , 
    output  wire        hs_out        , 
    output  wire        de_out        ,
    output  wire [7:0]  r_out         , 
    output  wire [7:0]  g_out         , 
    output  wire [7:0]  b_out         

);
wire                        cfg_clk    ;
wire                        locked     ;
wire                        rstn       ;
wire                        init_over  ;
reg  [15:0]                 rstn_1ms   ;
//**********************************************//
//*****************MS7210初始化******************//
//**********************************************//
//**************仿真时不编译此部分***************//
`ifndef SIM
//初始化成功标志
assign    led_int    =     init_over;
//生成10M IIC时钟
PLL u_pll (
  .clkout0(cfg_clk),    // output
  .lock(locked),          // output
  .clkin1(sys_clk)       // input
);
//ms7210初始化模块
ms7210_ctrl_iic_top ms7210_ctrl_iic_top_inst(
    .clk         (  cfg_clk    ), //input       clk,
    .rst_n       (  rstn_out   ), //input       rstn,
                        
    .init_over   (  init_over  ), //output      init_over,
    .iic_scl     (  hd_scl    ), //output      iic_scl,
    .iic_sda     (  hd_sda    )  //inout       iic_sda
);
//延迟复位
always @(posedge cfg_clk)
begin
	if(!locked)
	    rstn_1ms <= 16'd0;
	else
	begin
		if(rstn_1ms == 16'h2710)
		    rstn_1ms <= rstn_1ms;
		else
		    rstn_1ms <= rstn_1ms + 1'b1;
	end
end
assign rstn_out = (rstn_1ms == 16'h2710) && rstn_in;
//**********************************************//
`else
assign led_int  =     1;
assign rstn_out = rstn_in;

`endif
//**********************************************//
//**********************************************//
//**********************************************//
//**********************************************//
wire [15:0] rgb565;
wire [15:0] pix_data ;
wire [11:0] pix_x;
wire [11:0] pix_y;
//vga行场同步控制模块
vga_ctrl  vga_ctrl_inst (
    .vga_clk        (sys_clk        ),
    .sys_rst_n      (rstn_out       ),
    .pix_data       (pix_data       ),
    .pix_x          (pix_x          ),
    .pix_y          (pix_y          ),
    .hsync          (hs_out         ),
    .vsync          (vs_out         ),
    .rgb_valid      (de_out         ),
    .rgb            (rgb565         )
  );
//彩条数据生成模块
vga_pic  vga_pic_inst (
    .vga_clk        (sys_clk        ),
    .sys_rst_n      (rstn_out       ),
    .pix_x          (pix_x          ),
    .pix_y          (pix_y          ),
    .pix_data_out   (pix_data       )
  );
//RGB565转RGB888
    assign pixclk_out   =  sys_clk    ;//直接使用27M时钟，与25.175相差不大
    assign r_out = {rgb565[15:11],3'b0};
    assign g_out = {rgb565[10: 5],2'b0};
    assign b_out = {rgb565[ 4: 0],3'b0};
endmodule
