`timescale  1ns/1ns
////////////////////////////////////////////////////////////////////////
// Author        : EmbedFire
// 实验平台: 野火FPGA系列开发板
// 公司    : http://www.embedfire.com
// 论坛    : http://www.firebbs.cn
// 淘宝    : https://fire-stm32.taobao.com
////////////////////////////////////////////////////////////////////////

module  hdmi_loop
(
    input   wire            sys_clk     ,   //输入工作时钟,频率50MHz
    input   wire            sys_rst_n   ,   //输入复位信号,低电平有效

    output  wire            ddc_scl     ,
    inout   wire            ddc_sda     ,
    
    input  wire            hdmi_in_clk   /* synthesis PAP_MARK_DEBUG=”true” */,
    output wire            hdmi_in_rst_n /* synthesis PAP_MARK_DEBUG=”true” */,
    input  wire            hdmi_in_hsync /* synthesis PAP_MARK_DEBUG=”true” */,   //输出行同步信号
    input  wire            hdmi_in_vsync /* synthesis PAP_MARK_DEBUG=”true” */,   //输出场同步信号
    input  wire    [23:0]  hdmi_in_rgb   /* synthesis PAP_MARK_DEBUG=”true” */,   //输出像素信息
    input  wire            hdmi_in_de    /* synthesis PAP_MARK_DEBUG=”true” */,
    
    output  wire            hdmi_out_clk   /* synthesis PAP_MARK_DEBUG=”true” */,
    output  wire            hdmi_out_rst_n /* synthesis PAP_MARK_DEBUG=”true” */,
    output  wire            hdmi_out_hsync /* synthesis PAP_MARK_DEBUG=”true” */,   //输出行同步信号
    output  wire            hdmi_out_vsync /* synthesis PAP_MARK_DEBUG=”true” */,   //输出场同步信号
    output  wire    [23:0]  hdmi_out_rgb/* synthesis PAP_MARK_DEBUG=”true” */,   //输出像素信息
    output  wire            hdmi_out_de/* synthesis PAP_MARK_DEBUG=”true” */
);

//********************************************************************//
//****************** Parameter and Internal Signal *******************//
//********************************************************************//
assign  hdmi_out_clk   = hdmi_in_clk;
assign  hdmi_out_hsync = hdmi_in_hsync;
assign  hdmi_out_vsync = hdmi_in_vsync;
assign  hdmi_out_rgb   = hdmi_in_rgb;
assign  hdmi_out_de    = hdmi_in_de;
assign  hdmi_in_rst_n  = sys_rst_n;
assign  hdmi_out_rst_n = sys_rst_n;

//wire    clkout0/* synthesis PAP_MARK_DEBUG=”true” */;

/* always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)begin
        hdmi_out_clk    <=  1'b0;
        hdmi_out_hsync  <=  1'b0;
        hdmi_out_vsync  <=  1'b0;
        hdmi_out_rgb  <=  1'b0;
        hdmi_out_de  <=  1'b0;end
    else begin
        hdmi_out_clk    <=  hdmi_in_clk;
        hdmi_out_hsync  <=  hdmi_in_hsync;
        hdmi_out_vsync  <=  hdmi_in_vsync;
        hdmi_out_rgb  <=  hdmi_in_rgb;
        hdmi_out_de  <=  hdmi_in_de;end */

//********************************************************************//
//*************************** Instantiation **************************//
//********************************************************************//

/* pll the_instance_name (
  .clkout0(clkout0),    // output
  .lock(lock),          // output
  .clkin1(sys_clk)       // input
); */
hdmi_i2c hdmi_i2c_inst(
 .sys_clk   (sys_clk    )   ,   //系统时钟
 .sys_rst_n (sys_rst_n  )   ,   //复位信号
 .cfg_done  (           )   ,   //寄存器配置完成
 .sccb_scl  (ddc_scl    )   ,   //SCL
 .sccb_sda  (ddc_sda    )       //SDA

);



endmodule
