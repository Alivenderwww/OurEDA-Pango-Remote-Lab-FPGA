module dso_top(
    input         clk,
    input         rstn,       // 复位信号

    input         ad_clk,     // AD时钟
    input  [7:0]  ad_data,    // AD输入数据

    input         wave_run,   // 波形采集启动/停止
    input  [7:0]  trig_level, // 触发电平
    input         trig_edge,  // 触发边沿
    input  [9:0]  h_shift,    // 波形水平偏移量
    input  [9:0]  deci_rate,  // 抽样率

    input         ram_rd_clk,
    input         ram_rd_over,
    input         ram_rd_en,
    input  [9:0]  wave_rd_addr, // RAM读地址 0-299
    output [7:0]  wave_rd_data, // RAM读数据

    output        outrange,     //水平偏移超出范围
    output        ad_pulse,     //AD采样脉冲
    output [19:0] ad_freq,      //AD采样频率
    output [7:0]  ad_vpp,       //AD采样幅度
    output [7:0]  ad_max,       //AD采样最大值
    output [7:0]  ad_min        //AD采样最小值
);

wire       	deci_valid;

//参数测量模块
param_measure #(
	.CLK_FS 	( 32'd50_000_000  ))
u_param_measure(
	.clk        	( clk         ),
	.rstn       	( rstn        ),
	.trig_level 	( trig_level  ),
	.ad_clk     	( ad_clk      ),
	.ad_data    	( ad_data     ),
	.ad_pulse   	( ad_pulse    ),
	.ad_freq    	( ad_freq     ),
	.ad_vpp     	( ad_vpp      ),
	.ad_max     	( ad_max      ),
	.ad_min     	( ad_min      )
);

//数据存储模块
data_store u_data_store(
	.rstn         	( rstn           ),
	.trig_level    	( trig_level     ),
	.trig_edge     	( trig_edge      ),
	.wave_run      	( wave_run       ),
	.h_shift       	( h_shift        ),
	.ad_clk        	( ad_clk         ),
	.ad_data       	( ad_data        ),
	.deci_valid    	( deci_valid     ),
	.ram_rd_clk     ( ram_rd_clk     ),
	.ram_rd_over   	( ram_rd_over    ),
	.ram_rd_en 	    ( ram_rd_en      ),
	.wave_rd_addr  	( wave_rd_addr   ),
	.wave_rd_data  	( wave_rd_data   ),
	.outrange      	( outrange       )
);

//抽样模块
decimator u_decimator(
	.ad_clk     	( ad_clk      ),
	.rstn       	( rstn        ),
	.deci_rate  	( deci_rate   ),
	.deci_valid 	( deci_valid  )
);


endmodule //dso_top
