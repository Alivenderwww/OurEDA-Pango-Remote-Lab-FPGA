module data_store #(
    parameter HORIZONTAL  = 1024, //水平采样点数
    parameter ADDR_WIDTH  = 10
)(
    input                        rstn,      // 复位信号

    input       [7:0]            trig_level, // 触发电平
    input                        trig_edge,  // 触发边沿
    input                        wave_run/* synthesis PAP_MARK_DEBUG="true" */,   // 波形采集启动/停止

    input                        ad_clk,     // AD时钟
    input       [7:0]            ad_data,    // AD输入数据
    input                        deci_valid/* synthesis PAP_MARK_DEBUG="true" */, // 抽样有效信号
    
    input                        ram_rd_clk,
    
    input                        ram_refresh,
    input       [ADDR_WIDTH-1:0] wave_rd_addr,
    output      [7:0]            wave_rd_data,
    output                       wave_ready,
    output      [ADDR_WIDTH-1:0] wave_trig_addr
);

//reg define
reg [ADDR_WIDTH-1:0] wr_addr;      //RAM写地址

reg                  trig_flag;    //触发标志 
reg                  trig_en;      //触发使能
reg [ADDR_WIDTH-1:0] trig_addr0;    //触发地址
reg [ADDR_WIDTH-1:0] trig_addr1;    //触发地址

reg [7:0]            pre_data;
reg [7:0]            pre_data1;
reg [7:0]            pre_data2;
reg [7:0]            pre_data3;
reg [ADDR_WIDTH-1:0] data_cnt;
reg [1:0]            wr_pp_ptr;
reg [1:0]            rd_pp_ptr;
reg                  ram_refresh_d;

wire pingpang_full = (wr_pp_ptr[0] == rd_pp_ptr[0]) && (wr_pp_ptr[1] != rd_pp_ptr[1]);
wire pingpang_empty = (wr_pp_ptr == rd_pp_ptr);

//wire define
wire                      wr_en/* synthesis PAP_MARK_DEBUG="true" */;       //RAM写使能
wire [ADDR_WIDTH-1+1:0]   rd_addr;     //RAM地址
wire [ADDR_WIDTH-1+1:0]   rel_addr;    //相对触发地址
wire                      trig_pulse;  //满足触发条件时产生脉冲
wire                      ram_refresh_pos;


assign wr_en = deci_valid && (data_cnt <= HORIZONTAL-1) && wave_run && (~pingpang_full);

//满足触发条件时输出脉冲信号
assign trig_pulse = trig_edge ? ((pre_data3<trig_level) && (pre_data2<trig_level) && (pre_data1>=trig_level) && (pre_data>trig_level)) :
                                ((pre_data3>trig_level) && (pre_data2>trig_level) && (pre_data1<=trig_level) && (pre_data<trig_level));        

//写RAM地址累加
always @(posedge ad_clk or negedge rstn)begin
    if(!rstn) wr_addr  <= 0;
    else if(~wave_run) wr_addr <= 1'b0;
    else if(deci_valid) begin
        if(wr_addr < HORIZONTAL-1) wr_addr <= wr_addr + 1;
        else wr_addr <= 0;
    end else wr_addr <= wr_addr;
end

//触发使能
always @(posedge ad_clk or negedge rstn)begin
    if(!rstn) data_cnt <= 0;
    else if(~wave_run) data_cnt <= 1'b0;
    else if(data_cnt == HORIZONTAL) data_cnt <= 0;
    else if(deci_valid && (~pingpang_full)) begin
        if(data_cnt < HORIZONTAL/2-1)
             data_cnt <= data_cnt + 1;
        else if((trig_flag) && (data_cnt < HORIZONTAL))
             data_cnt <= data_cnt + 1;
        else data_cnt <= data_cnt;
    end else data_cnt <= data_cnt;
end

always @(posedge ad_clk or negedge rstn)begin
    if(!rstn) trig_en  <= 1'b0;
    else if(~wave_run) trig_en <= 1'b0;
    else if(deci_valid) begin
        if(data_cnt < HORIZONTAL/2-1) trig_en <= 1'b0;
        else if(trig_flag) trig_en <= 1'b0;
        else trig_en <= 1'b1;
    end else trig_en <= trig_en;
end

always @(posedge ad_clk or negedge rstn)begin
    if(!rstn) begin
        pre_data  <= 8'd0;
        pre_data1 <= 8'd0;
        pre_data2 <= 8'd0;
        pre_data3 <= 8'd0;
    end else if(~wave_run) begin
        pre_data  <= 8'd0;
        pre_data1 <= 8'd0;
        pre_data2 <= 8'd0;
        pre_data3 <= 8'd0;
    end else if(deci_valid) begin
        pre_data  <= ad_data;
        pre_data1 <= pre_data;
        pre_data2 <= pre_data1;
        pre_data3 <= pre_data2;
    end
end

always @(posedge ad_clk or negedge rstn)begin
    if(!rstn) trig_addr0 <= 0;
    else if(~wave_run) trig_addr0 <= 0;
    else if((wr_pp_ptr[0] == 0) && deci_valid && trig_en && trig_pulse)    
         trig_addr0 <= wr_addr + 2;
    else trig_addr0 <= trig_addr0;
end

always @(posedge ad_clk or negedge rstn)begin
    if(!rstn) trig_addr1 <= 0;
    else if(~wave_run) trig_addr1 <= 0;
    else if((wr_pp_ptr[0] == 1) && deci_valid && trig_en && trig_pulse)    
         trig_addr1 <= wr_addr + 2;
    else trig_addr1 <= trig_addr1;
end

always @(posedge ad_clk or negedge rstn)begin
    if(!rstn) trig_flag <= 1'b0;
    else if(~wave_run) trig_flag <= 0;
    else if((trig_flag == 0) && deci_valid && trig_en && trig_pulse)    
         trig_flag <= 1'b1;
    else if(trig_flag && (data_cnt == HORIZONTAL))
         trig_flag <= 1'b0;
    else trig_flag <= trig_flag;
end

always @(posedge ad_clk or negedge rstn)begin
    if(!rstn) wr_pp_ptr <= 0;
    else if(~wave_run) wr_pp_ptr <= 0;
    else if(data_cnt == HORIZONTAL) wr_pp_ptr <= wr_pp_ptr + 1;
end

assign ram_refresh_pos = (!ram_refresh_d) && (ram_refresh);
always @(posedge ram_rd_clk or negedge rstn) begin
    if(!rstn) ram_refresh_d <= 1'b0;
    else ram_refresh_d <= ram_refresh;
end

always @(posedge ram_rd_clk or negedge rstn)begin
    if(!rstn) rd_pp_ptr <= 0;
    else if(~wave_run) rd_pp_ptr <= 0;
    else if(pingpang_empty) rd_pp_ptr <= rd_pp_ptr;
    else if(ram_refresh_pos) rd_pp_ptr <= rd_pp_ptr + 1;
end

assign wave_ready = (~pingpang_empty);
assign wave_trig_addr = (rd_pp_ptr[0] == 0) ? trig_addr0 : trig_addr1;

dso_ram_2port u_dso_ram_2port ( //addr width is ADDR_WIDTH+1()pingpong
  .wr_clk   (ad_clk                  ),    // input
  .wr_rst   (~rstn                   ),    // input
  .wr_en    (wr_en                   ),    // input
  .wr_addr  ({wr_pp_ptr[0],wr_addr[0+:ADDR_WIDTH]}   ),    // input [10:0]
  .wr_data  (ad_data                 ),    // input [7:0]
  .rd_clk   (ram_rd_clk              ),    // input
  .rd_rst   (~rstn                   ),    // input
  .rd_addr  ({rd_pp_ptr[0],wave_rd_addr[0+:ADDR_WIDTH]}),    // input  [10:0]
  .rd_data  (wave_rd_data            )     // output [7:0]
);

endmodule 