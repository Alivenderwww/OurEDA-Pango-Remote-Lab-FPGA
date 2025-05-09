`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:Meyesemi 
// Engineer: bill
// 
// Create Date: 2024-06-17 16:05  
// Design Name:  
// Module Name: 
// Project Name: 
// Target Devices: Pango
// Tool Versions: 
// Description: 
//      
// Dependencies: 
// 
// Revision:
// Revision 1.0 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`define UD #1

module hdmi_top(
    input wire          sys_clk       ,// input system clock 50MHz   
    input               rstn_in, 
    output              rstn_out      ,
    output              hd_scl        ,
    inout               hd_sda        ,
    output              led_int       ,
//dso_rd_ram  
    output              ram_rd_clk    ,
    output              ram_rd_over   ,
    output              ram_rd_en     , 
    output  [8:0]       wave_rd_addr  , // RAM读地址 0-299
    input   [7:0]       wave_rd_data  , // RAM读数据

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
//**********************************************//
assign ram_rd_clk = sys_clk;

//**********************************************//
//**********************************************//
//初始化成功标志
assign    led_int    =     init_over;
// //生成10M IIC时钟
// PLL u_pll (
//   .clkout0(cfg_clk),    // output
//   .lock(locked),          // output
//   .clkin1(sys_clk)       // input
// );
// //ms7210初始化模块
// ms7210_ctrl_iic_top ms7210_ctrl_iic_top_inst(
//     .clk         (  cfg_clk    ), //input       clk,
//     .rst_n       (  rstn_out   ), //input       rstn,
                        
//     .init_over   (  init_over  ), //output      init_over,
//     .iic_scl     (  hd_scl    ), //output      iic_scl,
//     .iic_sda     (  hd_sda    )  //inout       iic_sda
// );
// //延迟复位
// always @(posedge cfg_clk)
// begin
// 	if(!locked)
// 	    rstn_1ms <= 16'd0;
// 	else
// 	begin
// 		if(rstn_1ms == 16'h2710)
// 		    rstn_1ms <= rstn_1ms;
// 		else
// 		    rstn_1ms <= rstn_1ms + 1'b1;
// 	end
// end
assign rstn_out = rstn_in;
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
    .ram_rd_en      (ram_rd_en      ),
    .wave_rd_addr   (wave_rd_addr   ),
    .ram_rd_over    (ram_rd_over    ),
    .rgb            (rgb565         )
  );
//彩条数据生成模块
vga_pic  vga_pic_inst (
    .vga_clk        (sys_clk        ),
    .sys_rst_n      (rstn_out       ),
    .pix_x          (pix_x          ),
    .pix_y          (pix_y          ),
    .wave_rd_data   (wave_rd_data   ),
    .pix_data_out   (pix_data       )
  );
//HDMI_OUT  =  HDMI_IN 
    assign pixclk_out   =  sys_clk    ;
    assign r_out = {rgb565[15:11],3'b0};
    assign g_out = {rgb565[10: 5],2'b0};
    assign b_out = {rgb565[ 4: 0],3'b0};
endmodule
