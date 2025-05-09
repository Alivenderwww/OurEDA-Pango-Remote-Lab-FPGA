module data_store #(
    parameter HORIZONTAL = 640 //水平采样点数 最大1023
)(
    input               rstn,      // 复位信号

    input       [7:0]   trig_level, // 触发电平
    input               trig_edge,  // 触发边沿
    input               wave_run,   // 波形采集启动/停止
    input       [9:0]   h_shift,    // 波形水平偏移量

    input               ad_clk,     // AD时钟
    input       [7:0]   ad_data,    // AD输入数据
    input               deci_valid, // 抽样有效信号
    
    input               ram_rd_clk,
    input               ram_rd_over,
    input               ram_rd_en,
    input       [8:0]   wave_rd_addr,
    output      [7:0]   wave_rd_data,
    output reg          outrange    //水平偏移超出范围
);

//reg define
reg [9:0] wr_addr;      //RAM写地址

reg       trig_flag;    //触发标志 
reg       trig_en;      //触发使能
reg [9:0] trig_addr;    //触发地址

reg [7:0] pre_data;
reg [7:0] pre_data1;
reg [7:0] pre_data2;
reg [9:0] data_cnt;

//wire define
wire       wr_en;       //RAM写使能
wire [9:0] rd_addr;     //RAM地址
wire [9:0] rel_addr;    //相对触发地址
wire [9:0] shift_addr;  //偏移后的地址
wire       trig_pulse;  //满足触发条件时产生脉冲
wire [7:0] ram_rd_data;

//*****************************************************
//**                    main code
//*****************************************************
assign wr_en    = deci_valid && (data_cnt <= HORIZONTAL-1) && wave_run;

//计算波形水平偏移后的RAM数据地址
assign shift_addr = h_shift[9] ? (wave_rd_addr-h_shift[8:0]) : //右移
                    (wave_rd_addr+h_shift[8:0]);               //左移

//根据触发地址，计算像素横坐标所映射的RAM地址
assign rel_addr = trig_addr + shift_addr;
assign rd_addr = (rel_addr<HORIZONTAL/2) ? (rel_addr+HORIZONTAL/2) : 
                    (rel_addr>HORIZONTAL/2+HORIZONTAL-1) ? (rel_addr-(HORIZONTAL/2+HORIZONTAL)) :
                        (rel_addr-HORIZONTAL/2);

//满足触发条件时输出脉冲信号
assign trig_pulse = trig_edge ? 
                    ((pre_data2<trig_level) && (pre_data1<trig_level) 
                        && (pre_data>=trig_level) && (ad_data>trig_level)) :
                    ((pre_data2>trig_level) && (pre_data1>trig_level) 
                        && (pre_data<=trig_level) && (ad_data<trig_level));        

//读出的数据为255时超出波形显示范围
assign wave_rd_data = outrange ? 8'd255 : (ram_rd_data); 

//判断水平偏移后地址范围
always @(posedge ram_rd_clk or negedge rstn)begin
    if(!rstn) outrange <= 1'b0;
    else if(h_shift[9] && (wave_rd_addr<h_shift[8:0]))//右移时判断左边界
            outrange <= 1'b1;          
    else if((~h_shift[9]) && (wave_rd_addr+h_shift[8:0]>HORIZONTAL-1)) //左移时判断右边界
        outrange <= 1'b1; 
    else outrange <= 1'b0;
end

//写RAM地址累加
always @(posedge ad_clk or negedge rstn)begin
    if(!rstn) wr_addr  <= 0;
    else if(deci_valid) begin
        if(wr_addr < HORIZONTAL-1) wr_addr <= wr_addr + 1;
        else wr_addr  <= 0;
    end
end

//触发使能
always @(posedge ad_clk or negedge rstn)begin
    if(!rstn) begin
        data_cnt <= 0;
        trig_en  <= 1'b0;
    end
    else begin
        if(deci_valid) begin
            if(data_cnt < HORIZONTAL/2-1) begin    //触发前至少接收150个数据
                data_cnt <= data_cnt + 1;
                trig_en  <= 1'b0;
            end else begin
                trig_en <= 1'b1;        //打开触发使能
                if(trig_flag) begin     //检测到触发信号
                    trig_en <= 1'b0;
                    if(data_cnt < HORIZONTAL)  //继续接收150个数据
                        data_cnt <= data_cnt + 1;
                end
            end

        end
                                        //波形绘制完成后重新计数
        if((data_cnt == HORIZONTAL) && ram_rd_over & wave_run)
            data_cnt <= 0;
    end
end

//寄存AD数据，用于判断触发条件
always @(posedge ad_clk or negedge rstn)begin
    if(!rstn) begin
        pre_data  <= 8'd0;
        pre_data1 <= 8'd0;
        pre_data2 <= 8'd0;
    end else if(deci_valid) begin
        pre_data  <= ad_data;
        pre_data1 <= pre_data;
        pre_data2 <= pre_data1;
    end
end

//触发检测
always @(posedge ad_clk or negedge rstn)begin
    if(!rstn) begin
        trig_addr <= 0;
        trig_flag <= 1'b0;
    end
    else begin
        if(deci_valid && trig_en && trig_pulse) begin       
            trig_flag <= 1'b1;
            trig_addr <= wr_addr + 2;
        end
        if(trig_flag && (data_cnt == HORIZONTAL) && ram_rd_over && wave_run)
            trig_flag <= 1'b0;
    end
end

dso_ram_2port u_dso_ram_2port (
  .wr_clk   (ad_clk     ),    // input
  .wr_rst   (~rstn      ),    // input
  .wr_en    (wr_en      ),    // input
  .wr_addr  (wr_addr    ),    // input [9:0]
  .wr_data  (ad_data    ),    // input [7:0]
  .rd_clk   (ram_rd_clk ),    // input
  .rd_rst   (~rstn      ),    // input
  .rd_addr  (rd_addr    ),    // input [9:0]
  .rd_data  (ram_rd_data)     // output [7:0]
);

endmodule 