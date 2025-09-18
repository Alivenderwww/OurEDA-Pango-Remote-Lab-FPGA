`timescale 1ns / 1ns
module hdmi_top(
    input wire          sys_clk       ,// input system clock 27MHz   
    input               rstn_in       , 

    output              rstn_out      ,
    output              hd_scl        ,
    inout               hd_sda        ,
    output  wire [7:0]  led           ,
    //encoder
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
    output ser,

    //hsst
    input               i_p_refckn_1,
    input               i_p_refckp_1,
    //SD卡 
    input   wire            sd_miso     ,  //主输入从输出信号
    output  wire            sd_clk      ,  //SD卡时钟信号
    output  wire            sd_cs_n     ,  //片选信号
    output  wire            sd_mosi     ,  //主输出从输入信号
//hdmi_out 
    output              pixclk_out    ,//pixclk                           
    output  wire        vs_out        , 
    output  wire        hs_out        , 
    output  wire        de_out        ,
    output  wire [7:0]  r_out         , 
    output  wire [7:0]  g_out         , 
    output  wire [7:0]  b_out         ,
//DDR3接口
    output            mem_rst_n     , //Memory复位
    output            mem_ck        , //Memory差分时钟正端
    output            mem_ck_n      , //Memory差分时钟负端
    output            mem_cs_n      , //Memory片选
    output [14:0]     mem_a         , //Memory地址总线
    inout  [31:0]     mem_dq        , //数据总线
    inout  [3:0]      mem_dqs       , //数据时钟正端
    inout  [3:0]      mem_dqs_n     , //数据时钟负端
    output [3:0]      mem_dm        , //数据Mask
    output            mem_cke       , //Memory差分时钟使能
    output            mem_odt       , //On Die Termination
    output            mem_ras_n     , //行地址strobe
    output            mem_cas_n     , //列地址strobe
    output            mem_we_n      , //写使能
    output [2:0]      mem_ba          //Bank地址总线

);
wire                        cfg_clk    ;
wire                        locked     ;
wire                        rstn       ;
wire                        init_over  ;
reg  [15:0]                 rstn_1ms   ;

wire [19:0] cnt_1;
wire [19:0] cnt_2;
wire [19:0] cnt_3;
wire debugger_init;
//**********************************************//
//*****************MS7210初始化******************//
//**********************************************//
//**************仿真时不编译此部分***************//
`ifndef SIM
//初始化成功标志
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
wire [15:0] rgb565;
wire [15:0] pix_data ;
wire [11:0] pix_x;
wire [11:0] pix_y;
//**********************************************//
//parameter define
//水平方向像素个数,用于设置SDRAM缓存大小
parameter   H_PIXEL     =   24'd640 ;
//垂直方向像素个数,用于设置SDRAM缓存大小
parameter   V_PIXEL     =   24'd480 ;
//wire  define
wire      clk_25m       ;
wire      clk_25m_shift ;
wire      clk_50m       ;
wire      clk_50m_shift ;
wire locked_2;
wire      rst_n         ; //复位信号
wire      wr_en         ; //ddr写使能
wire[15:0]wr_data       ; //ddr写数据
wire      rd_en         ; //ddr读使能
wire[15:0]rd_data       ; //ddr读数据
wire            c3_calib_done; //系统初始化完成(ddr初始化+摄像头初始化)
wire     [15:0] rgb          ;
wire            rgb_valid    ;
wire            sd_rd_en     ; //开始写SD卡数据信号
wire    [31:0]  sd_rd_addr   ; //读数据扇区地址
wire            sd_rd_busy   ; //读忙信号
wire            sd_rd_data_en; //数据读取有效使能信号
wire    [15:0]  sd_rd_data   ; //读数据
wire            sd_init_end  ; //SD卡初始化完成信号
PLL_2 pll_inst (
  .clkout3(clk_50m_shift),    // output
  .clkout2(clk_50m),    // output
  .clkout1(clk_25m_shift),    // output
  .clkout0(clk_25m),    // output
  .lock(locked_2),          // output
  .clkin1(cfg_clk)       // input
);
//**********************************************//
assign  rst_n = rstn_in & c3_calib_done & locked_2;
assign  led   = {sd_init_end,c3_calib_done,locked_2,init_over,debugger_init,1'b0,1'b0,1'b1};
assign  r_out = {rgb[15:11],3'b0} + cnt_1[7:0];
assign  g_out = {rgb[10: 5],2'b0} + cnt_2[7:0];
assign  b_out = {rgb[ 4: 0],3'b0} + cnt_3[7:0];
assign  de_out     =   rd_en;

data_rd_ctrl    data_rd_ctrl_inst
(
    .sys_clk    (clk_25m                ),   //输入工作时钟,频率50MHz
    .sys_rst_n  (rst_n & sd_init_end    ),   //输入复位信号,低电平有效
    .rd_busy    (sd_rd_busy             ),   //读操作忙信号

    .rd_en      (sd_rd_en               ),   //数据读使能信号
    .rd_addr    (sd_rd_addr             )    //读数据扇区地址
);

//------------- sd_ctrl_inst -------------
sd_ctrl sd_ctrl_inst
(
    .sys_clk         (clk_25m       ),  //输入工作时钟,频率50MHz
    .sys_clk_shift   (clk_25m_shift ),  //输入工作时钟,频率50MHz
                                        //相位偏移180度
    .sys_rst_n       (rst_n         ),  //输入复位信号,低电平有效

    .sd_miso         (sd_miso       ),  //主输入从输出信号
    .sd_clk          (sd_clk        ),  //SD卡时钟信号
    .sd_cs_n         (sd_cs_n       ),  //片选信号
    .sd_mosi         (sd_mosi       ),  //主输出从输入信号

    .wr_en           (1'b0          ),  //数据写使能信号
    .wr_addr         (32'b0         ),  //写数据扇区地址
    .wr_data         (16'b0         ),  //写数据
    .wr_busy         (              ),  //写操作忙信号
    .wr_req          (              ),  //写数据请求信号

    .rd_en           (sd_rd_en      ),  //数据读使能信号
    .rd_addr         (sd_rd_addr    ),  //读数据扇区地址
    .rd_busy         (sd_rd_busy    ),  //读操作忙信号
    .rd_data_en      (sd_rd_data_en ),  //读数据标志信号
    .rd_data         (sd_rd_data    ),  //读数据

    .init_end        (sd_init_end   )   //SD卡初始化完成信号
);
//------------- ddr_rw_inst -------------
//DDR读写控制部分
axi_ddr_top
#(
.DDR_WR_LEN(16),//写突发长度 最大128个64bit
.DDR_RD_LEN(16) //读突发长度 最大128个64bit
)
ddr_rw_inst
(
  .sys_clk      (clk_50m        ),
  .sys_rst_n    (rstn_in       ),
  .pingpang     (0              ),
   //写用户接口
  .user_wr_clk  (clk_25m        ), //写时钟
  .data_wren    (sd_rd_data_en  ), //写使能，高电平有效
  .data_wr      (sd_rd_data     ), //写数据16位wr_data
  .wr_b_addr    (30'd0          ), //写起始地址
  .wr_e_addr    (H_PIXEL*V_PIXEL*2  ), //写结束地址,8位一字节对应一个地址，16位x2
  .wr_rst       (1'b0           ), //写地址复位 wr_rst
  //读用户接口
  .user_rd_clk  (clk_25m        ), //读时钟
  .data_rden    (rd_en          ), //读使能，高电平有效
  .data_rd      (rd_data        ), //读数据16位
  .rd_b_addr    (30'd0          ), //读起始地址
  .rd_e_addr    (H_PIXEL*V_PIXEL*2  ), //写结束地址,8位一字节对应一个地址,16位x2
  .rd_rst       (1'b0           ), //读地址复位 rd_rst
  .read_enable  (1'b1           ),

  .ui_clk       (               ), //ddr操作时钟100m
  .calib_done   (c3_calib_done  ), //代表ddr初始化完成

  //物理接口
  .mem_rst_n    (mem_rst_n      ),
  .mem_ck       (mem_ck         ),
  .mem_ck_n     (mem_ck_n       ),
  .mem_cs_n     (mem_cs_n       ),
  .mem_a        (mem_a          ),
  .mem_dq       (mem_dq         ),
  .mem_dqs      (mem_dqs        ),
  .mem_dqs_n    (mem_dqs_n      ),
  .mem_dm       (mem_dm         ),
  .mem_cke      (mem_cke        ),
  .mem_odt      (mem_odt        ),
  .mem_ras_n    (mem_ras_n      ),
  .mem_cas_n    (mem_cas_n      ),
  .mem_we_n     (mem_we_n       ),
  .mem_ba       (mem_ba         )

);
//**********************************************//
//vga行场同步控制模块
vga_ctrl  vga_ctrl_inst (
    .vga_clk        (clk_25m        ),
    .sys_rst_n      (rst_n       ),
    .pix_data       (rd_data        ),
    .pix_x          (pix_x          ),
    .pix_y          (pix_y          ),
    .hsync          (hs_out         ),
    .vsync          (vs_out         ),
    .rgb_valid      (rd_en          ),
    .rgb            (rgb         )
  );
//RGB565转RGB888
    assign pixclk_out   =  clk_25m    ;//直接使用27M时钟，与25.175相差不大
wire clk_125m;
PLL_debugger the_instance_name (
  .clkout0(clk_125m),    // output
  .lock(),          // output
  .clkin1(sys_clk)       // input
);
debugtest_top # (
   .PORT_NUM(3)
)
debugtest_top_inst (
  .clk(clk_25m),
  .clk_27M(sys_clk),
  .rstn(rst_n),
  .i_p_refckn_1(i_p_refckn_1),
  .i_p_refckp_1(i_p_refckp_1),
  .i_testport({{31'd0,vs_out},{31'd0,hs_out},{8'd0,r_out,g_out,b_out}}),
  .debugger_init(debugger_init),
  .o_pll_done_0         (       ),
  .o_txlane_done_2      (    ),
  .o_rxlane_done_2      (    ),
  .o_p_pll_lock_0       (     ),
  .o_p_rx_sigdet_sta_2  (),
  .o_p_lx_cdr_align_2   ( )
);

top  top_inst (
    .clk(clk_25m),
    .rstn(rstn),
    .A_1(A_1),
    .B_1(B_1),
    .A_2(A_2),
    .B_2(B_2),
    .A_3(A_3),
    .B_3(B_3),
    .encoder_keyin_1(encoder_keyin_1),
    .encoder_keyin_2(encoder_keyin_2),
    .sck(sck),
    .rck(rck),
    .ser(ser),
    .cnt_1(cnt_1),
    .cnt_2(cnt_2),
    .cnt_3(cnt_3)
  );
endmodule
