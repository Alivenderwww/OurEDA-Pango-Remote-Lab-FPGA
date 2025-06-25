module dds_slave#(
   parameter CHANNEL_NUM = 2, //共有2条输出通道，可并行输出2路波形。
   parameter VERTICAL_RESOLUTION = 8 
)(
   input wire clk,
   input wire rstn,

   output wire [CHANNEL_NUM*(VERTICAL_RESOLUTION)-1:0] wave_out,
   output logic             DDS_SLAVE_CLK          ,
   output logic             DDS_SLAVE_RSTN         ,
   input  logic [4-1:0]     DDS_SLAVE_WR_ADDR_ID   ,
   input  logic [31:0]      DDS_SLAVE_WR_ADDR      ,
   input  logic [ 7:0]      DDS_SLAVE_WR_ADDR_LEN  ,
   input  logic [ 1:0]      DDS_SLAVE_WR_ADDR_BURST,
   input  logic             DDS_SLAVE_WR_ADDR_VALID,
   output logic             DDS_SLAVE_WR_ADDR_READY,
   input  logic [31:0]      DDS_SLAVE_WR_DATA      ,
   input  logic [ 3:0]      DDS_SLAVE_WR_STRB      ,
   input  logic             DDS_SLAVE_WR_DATA_LAST ,
   input  logic             DDS_SLAVE_WR_DATA_VALID,
   output logic             DDS_SLAVE_WR_DATA_READY,
   output logic [4-1:0]     DDS_SLAVE_WR_BACK_ID   ,
   output logic [ 1:0]      DDS_SLAVE_WR_BACK_RESP ,
   output logic             DDS_SLAVE_WR_BACK_VALID,
   input  logic             DDS_SLAVE_WR_BACK_READY,
   input  logic [4-1:0]     DDS_SLAVE_RD_ADDR_ID   ,
   input  logic [31:0]      DDS_SLAVE_RD_ADDR      ,
   input  logic [ 7:0]      DDS_SLAVE_RD_ADDR_LEN  ,
   input  logic [ 1:0]      DDS_SLAVE_RD_ADDR_BURST,
   input  logic             DDS_SLAVE_RD_ADDR_VALID,
   output logic             DDS_SLAVE_RD_ADDR_READY,
   output logic [4-1:0]     DDS_SLAVE_RD_BACK_ID   ,
   output logic [31:0]      DDS_SLAVE_RD_DATA      ,
   output logic [ 1:0]      DDS_SLAVE_RD_DATA_RESP ,
   output logic             DDS_SLAVE_RD_DATA_LAST ,
   output logic             DDS_SLAVE_RD_DATA_VALID,
   input  logic             DDS_SLAVE_RD_DATA_READY
);
wire DDS_SLAVE_RSTN_SYNC;
assign DDS_SLAVE_CLK = clk;
assign DDS_SLAVE_RSTN = DDS_SLAVE_RSTN_SYNC;
rstn_sync dds_rstn_sync(clk,rstn,DDS_SLAVE_RSTN_SYNC);
/*地址定义：（以2路输出，4波形存储为例）
00    R/W   CHANNEL0        wave_sel   0-3
01    R/W   CHANNEL0 STORE0 freq_ctrl  0-32'FFFFFFFF
02    R/W   CHANNEL0 STORE1 freq_ctrl  0-32'FFFFFFFF
03    R/W   CHANNEL0 STORE2 freq_ctrl  0-32'FFFFFFFF
04    R/W   CHANNEL0 STORE3 freq_ctrl  0-32'FFFFFFFF
05    R/W   CHANNEL0 STORE0 phase_ctrl 0-2048
06    R/W   CHANNEL0 STORE1 phase_ctrl 0-2048
07    R/W   CHANNEL0 STORE2 phase_ctrl 0-2048
08    R/W   CHANNEL0 STORE3 phase_ctrl 0-2048
09    R/W   CHANNEL0        dds_wr_enable
0A     WO   CHANNEL0        data

10    R/W   CHANNEL1        wave_sel
11    R/W   CHANNEL1 STORE0 freq_ctrl
12    R/W   CHANNEL1 STORE1 freq_ctrl
13    R/W   CHANNEL1 STORE2 freq_ctrl
14    R/W   CHANNEL1 STORE3 freq_ctrl
15    R/W   CHANNEL1 STORE0 phase_ctrl
16    R/W   CHANNEL1 STORE1 phase_ctrl
17    R/W   CHANNEL1 STORE2 phase_ctrl
18    R/W   CHANNEL1 STORE3 phase_ctrl
19    R/W   CHANNEL1        dds_wr_enable
1A     WO   CHANNEL1        data
*/

localparam HORIZON_RESOLUTION  = 12;
localparam ADDER_LOWBIT        = 20;
localparam WAVE_STORE          = 2 ; //1个通道可本地存储4条波形用于快速切换。

reg [(WAVE_STORE-1):0]                                         wave_sel[(CHANNEL_NUM-1):0];
reg [(2**WAVE_STORE-1):0][HORIZON_RESOLUTION+ADDER_LOWBIT-1:0] freq_ctrl [(CHANNEL_NUM-1):0];
reg [(2**WAVE_STORE-1):0][HORIZON_RESOLUTION-1:0]              phase_ctrl[(CHANNEL_NUM-1):0];
wire[32-1:0]                              dds_wr_data;

reg  [CHANNEL_NUM-1:0] dds_wr_enable;
reg  [CHANNEL_NUM-1:0] dds_wr_valid;
integer wave_channel, wave_select;

reg  [ 3:0] wr_addr_id;   
reg  [31:0] wr_addr;
reg  [ 1:0] wr_addr_burst;
reg         wr_error_detect;
reg  [ 1:0] cu_wr_st, nt_wr_st;
localparam ST_WR_IDLE = 2'b01,
           ST_WR_DATA = 2'b10,
           ST_WR_RESP = 2'b11;

reg  [ 3:0] rd_addr_id;   
reg  [31:0] rd_addr;
reg  [ 7:0] rd_addr_len;
reg  [ 1:0] rd_addr_burst;
reg         rd_error_detect, rd_error_detect_reg;
reg  [ 7:0] trans_num;
reg         cu_rd_st, nt_rd_st;
localparam ST_RD_IDLE = 1'b0,
           ST_RD_DATA = 1'b1;

//___________________写通道___________________//
always @(*) begin
    case (cu_wr_st)
        ST_WR_IDLE: nt_wr_st <= (DDS_SLAVE_WR_ADDR_READY && DDS_SLAVE_WR_ADDR_VALID)?(ST_WR_DATA):(ST_WR_IDLE);
        ST_WR_DATA: nt_wr_st <= (DDS_SLAVE_WR_DATA_READY && DDS_SLAVE_WR_DATA_VALID && DDS_SLAVE_WR_DATA_LAST)?(ST_WR_RESP):(ST_WR_DATA);
        ST_WR_RESP: nt_wr_st <= (DDS_SLAVE_WR_BACK_READY && DDS_SLAVE_WR_BACK_VALID)?(ST_WR_IDLE):(ST_WR_RESP);
        default:    nt_wr_st <= ST_WR_IDLE;
    endcase
end
always @(posedge clk or negedge DDS_SLAVE_RSTN_SYNC) begin
   if(~DDS_SLAVE_RSTN_SYNC) cu_wr_st <= ST_WR_IDLE;
   else cu_wr_st <= nt_wr_st;
end

always @(posedge clk or negedge DDS_SLAVE_RSTN_SYNC) begin
    if(~DDS_SLAVE_RSTN_SYNC) begin
        wr_addr_id <= 0;
        wr_addr_burst <= 0;
    end else if(DDS_SLAVE_WR_ADDR_READY && DDS_SLAVE_WR_ADDR_VALID)begin
        wr_addr_id <= DDS_SLAVE_WR_ADDR_ID;
        wr_addr_burst <= DDS_SLAVE_WR_ADDR_BURST;
    end else begin
        wr_addr_id <= wr_addr_id;
        wr_addr_burst <= wr_addr_burst;
    end
end

always @(posedge clk or negedge DDS_SLAVE_RSTN_SYNC) begin
    if(~DDS_SLAVE_RSTN_SYNC) wr_addr <= 0;
    else if(DDS_SLAVE_WR_ADDR_READY && DDS_SLAVE_WR_ADDR_VALID) wr_addr <= DDS_SLAVE_WR_ADDR;
    else if((cu_wr_st == ST_WR_DATA) && DDS_SLAVE_WR_DATA_READY && DDS_SLAVE_WR_DATA_VALID && (wr_addr_burst == 2'b01)) wr_addr <= wr_addr + 1;
    else wr_addr <= wr_addr;
end

always @(posedge clk or negedge DDS_SLAVE_RSTN_SYNC) begin
   if(~DDS_SLAVE_RSTN_SYNC) wr_error_detect <= 0;
   else if(cu_wr_st == ST_WR_IDLE) wr_error_detect <= 0;
   else if(cu_wr_st == ST_WR_DATA)begin
      if((wr_addr_burst == 2'b10) || (wr_addr_burst == 2'b11)) wr_error_detect <= 1;
      else begin
         if(wr_addr[7:4] >= CHANNEL_NUM) wr_error_detect <= 1;
         else if(wr_addr[3:0] > 4'hA) wr_error_detect <= 1;
         else wr_error_detect <= 0;
      end
   end else wr_error_detect <= wr_error_detect;
end

assign DDS_SLAVE_WR_ADDR_READY = (cu_wr_st == ST_WR_IDLE);
assign DDS_SLAVE_WR_BACK_ID    = wr_addr_id;
assign DDS_SLAVE_WR_BACK_RESP  = (wr_error_detect)?(2'b10):(2'b00);
assign DDS_SLAVE_WR_BACK_VALID = (cu_wr_st == ST_WR_RESP);

//___________________读通道___________________//
always @(*) begin
    case (cu_rd_st)
        ST_RD_IDLE: nt_rd_st <= (DDS_SLAVE_RD_ADDR_READY && DDS_SLAVE_RD_ADDR_VALID)?(ST_RD_DATA):(ST_RD_IDLE);
        ST_RD_DATA: nt_rd_st <= (DDS_SLAVE_RD_DATA_READY && DDS_SLAVE_RD_DATA_VALID && DDS_SLAVE_RD_DATA_LAST)?(ST_RD_IDLE):(ST_RD_DATA);
    endcase
end
always @(posedge clk or negedge DDS_SLAVE_RSTN_SYNC) begin
    if(~DDS_SLAVE_RSTN_SYNC) cu_rd_st <= ST_RD_IDLE;
   else cu_rd_st <= nt_rd_st;
end 

always @(posedge clk or negedge DDS_SLAVE_RSTN_SYNC) begin
    if(~DDS_SLAVE_RSTN_SYNC) begin
        rd_addr_id <= 0;
        rd_addr_burst <= 0;
        rd_addr_len <= 0;
    end else if(DDS_SLAVE_RD_ADDR_READY && DDS_SLAVE_RD_ADDR_VALID)begin
        rd_addr_id <= DDS_SLAVE_RD_ADDR_ID;
        rd_addr_burst <= DDS_SLAVE_RD_ADDR_BURST;
        rd_addr_len <= DDS_SLAVE_RD_ADDR_LEN;
    end else begin
        rd_addr_id <= rd_addr_id;
        rd_addr_burst <= rd_addr_burst;
        rd_addr_len <= rd_addr_len;
    end
end

always @(posedge clk or negedge DDS_SLAVE_RSTN_SYNC) begin
    if(~DDS_SLAVE_RSTN_SYNC) rd_addr <= 0;
    else if(DDS_SLAVE_RD_ADDR_READY && DDS_SLAVE_RD_ADDR_VALID) rd_addr <= DDS_SLAVE_RD_ADDR;
    else if((cu_rd_st == ST_RD_DATA) && DDS_SLAVE_RD_DATA_READY && DDS_SLAVE_RD_DATA_VALID && (rd_addr_burst == 2'b01)) rd_addr <= rd_addr + 1;
    else rd_addr <= rd_addr;
end

always @(posedge clk or negedge DDS_SLAVE_RSTN_SYNC) begin
    if(~DDS_SLAVE_RSTN_SYNC) trans_num <= 0;
    else if(cu_rd_st == ST_RD_IDLE) trans_num <= 0;
    else if(DDS_SLAVE_RD_DATA_READY && DDS_SLAVE_RD_DATA_VALID) trans_num <= trans_num + 1;
    else trans_num <= trans_num;
end

always @(*) begin
   if((~DDS_SLAVE_RSTN_SYNC) || (cu_rd_st == ST_RD_IDLE)) rd_error_detect <= 0;
   else if(cu_rd_st == ST_RD_DATA)begin
      if((rd_addr_burst == 2'b10) || (rd_addr_burst == 2'b11)) rd_error_detect <= 1;
      else begin
         if(rd_addr[7:4] >= CHANNEL_NUM) rd_error_detect <= 1;
         else if(rd_addr[3:0] > 4'h9) rd_error_detect <= 1;
         else rd_error_detect <= 0;
      end
   end else rd_error_detect <= 0;
end
always @(posedge clk or negedge DDS_SLAVE_RSTN_SYNC) begin
    if(~DDS_SLAVE_RSTN_SYNC) rd_error_detect_reg <= 0;
    else if(cu_rd_st == ST_RD_IDLE) rd_error_detect_reg <= 0;
    else rd_error_detect_reg <= rd_error_detect;
end

assign DDS_SLAVE_RD_ADDR_READY = (cu_rd_st == ST_RD_IDLE);
assign DDS_SLAVE_RD_BACK_ID    = rd_addr_id;
assign DDS_SLAVE_RD_DATA_RESP  = (rd_error_detect || rd_error_detect_reg)?(2'b10):(2'b00);
assign DDS_SLAVE_RD_DATA_LAST  = (DDS_SLAVE_RD_DATA_VALID && (trans_num == rd_addr_len));

//写通道的READY信号
always @(*) begin
    if((~DDS_SLAVE_RSTN_SYNC) || (cu_wr_st == ST_WR_IDLE) || (cu_wr_st == ST_WR_RESP)) DDS_SLAVE_WR_DATA_READY <= 0;
    else if(cu_wr_st == ST_WR_DATA)begin
      if(wr_addr[7:4] < CHANNEL_NUM) DDS_SLAVE_WR_DATA_READY <= 1;
      else if(wr_addr[3:0] == 4'hA) DDS_SLAVE_WR_DATA_READY <= 1;
      else DDS_SLAVE_WR_DATA_READY <= 1;
    end else DDS_SLAVE_WR_DATA_READY <= 0;
end

//读通道的VALID信号
always @(*) begin
    if((~DDS_SLAVE_RSTN_SYNC) || (cu_rd_st == ST_RD_IDLE)) DDS_SLAVE_RD_DATA_VALID <= 0;
    else if(cu_rd_st == ST_RD_DATA) DDS_SLAVE_RD_DATA_VALID <= 1;
    else DDS_SLAVE_RD_DATA_VALID <= 0;
end

//读通道的DATA选通
always @(*) begin
   if((~DDS_SLAVE_RSTN_SYNC) || (cu_rd_st == ST_RD_IDLE)) DDS_SLAVE_RD_DATA <= 0;
   else if(cu_rd_st == ST_RD_DATA)begin
      if(rd_addr[7:4] >= CHANNEL_NUM) DDS_SLAVE_RD_DATA <= 32'hFFFF_FFFF;
      else case (rd_addr[3:0])
            4'h0: DDS_SLAVE_RD_DATA <= wave_sel[rd_addr[7:4]];
            4'h1: DDS_SLAVE_RD_DATA <= freq_ctrl[rd_addr[7:4]][0];
            4'h2: DDS_SLAVE_RD_DATA <= freq_ctrl[rd_addr[7:4]][1];
            4'h3: DDS_SLAVE_RD_DATA <= freq_ctrl[rd_addr[7:4]][2];
            4'h4: DDS_SLAVE_RD_DATA <= freq_ctrl[rd_addr[7:4]][3];
            4'h5: DDS_SLAVE_RD_DATA <= phase_ctrl[rd_addr[7:4]][0];
            4'h6: DDS_SLAVE_RD_DATA <= phase_ctrl[rd_addr[7:4]][1];
            4'h7: DDS_SLAVE_RD_DATA <= phase_ctrl[rd_addr[7:4]][2];
            4'h8: DDS_SLAVE_RD_DATA <= phase_ctrl[rd_addr[7:4]][3];
            4'h9: DDS_SLAVE_RD_DATA <= {7'b0,dds_wr_enable[rd_addr[7:4]]};
         default: DDS_SLAVE_RD_DATA <= 32'hFFFF_FFFF;
      endcase
   end else DDS_SLAVE_RD_DATA <= 32'hFFFF_FFFF;
end
///__________输出信号___________///

always @(posedge clk or negedge DDS_SLAVE_RSTN_SYNC) begin
   if(~DDS_SLAVE_RSTN_SYNC)
      for(wave_channel=0;wave_channel<CHANNEL_NUM;wave_channel=wave_channel+1)
         wave_sel[wave_channel] <= 0;
   else if(DDS_SLAVE_WR_DATA_VALID && DDS_SLAVE_WR_DATA_READY && (wr_addr[7:4] < CHANNEL_NUM) && (wr_addr[3:0] == 4'h0))
         wave_sel[wr_addr[7:4]] <= DDS_SLAVE_WR_DATA;
   else
      for(wave_channel=0;wave_channel<CHANNEL_NUM;wave_channel=wave_channel+1)
         wave_sel[wave_channel] <= wave_sel[wave_channel];
end

always @(posedge clk or negedge DDS_SLAVE_RSTN_SYNC) begin
   if(~DDS_SLAVE_RSTN_SYNC)
      for(wave_channel=0;wave_channel<CHANNEL_NUM;wave_channel=wave_channel+1)
         for(wave_select=0;wave_select<(2**WAVE_STORE);wave_select=wave_select+1)
            freq_ctrl[wave_channel][wave_select] <= 0;
   else if(DDS_SLAVE_WR_DATA_VALID && DDS_SLAVE_WR_DATA_READY && (wr_addr[7:4] < CHANNEL_NUM) && ((wr_addr[3:0] >= 4'h1) && (wr_addr[3:0] <= 4'h4)))
      case(wr_addr[3:0])
         4'h1:    freq_ctrl[wr_addr[7:4]][0] <= DDS_SLAVE_WR_DATA;
         4'h2:    freq_ctrl[wr_addr[7:4]][1] <= DDS_SLAVE_WR_DATA;
         4'h3:    freq_ctrl[wr_addr[7:4]][2] <= DDS_SLAVE_WR_DATA;
         4'h4:    freq_ctrl[wr_addr[7:4]][3] <= DDS_SLAVE_WR_DATA;
         default: freq_ctrl[wr_addr[7:4]][0] <= freq_ctrl[wr_addr[7:4]][0];
      endcase
   else 
      for(wave_channel=0;wave_channel<CHANNEL_NUM;wave_channel=wave_channel+1)
         for(wave_select=0;wave_select<(2**WAVE_STORE);wave_select=wave_select+1)
            freq_ctrl[wave_channel][wave_select] <= freq_ctrl[wave_channel][wave_select];
end

always @(posedge clk or negedge DDS_SLAVE_RSTN_SYNC) begin
   if(~DDS_SLAVE_RSTN_SYNC)
      for(wave_channel=0;wave_channel<CHANNEL_NUM;wave_channel=wave_channel+1)
         for(wave_select=0;wave_select<(2**WAVE_STORE);wave_select=wave_select+1)
            phase_ctrl[wave_channel][wave_select] <= 0;
   else if(DDS_SLAVE_WR_DATA_VALID && DDS_SLAVE_WR_DATA_READY && (wr_addr[7:4] < CHANNEL_NUM) && ((wr_addr[3:0] >= 4'h5) && (wr_addr[3:0] <= 4'h8)))
      case(wr_addr[3:0])
         4'h5:    phase_ctrl[wr_addr[7:4]][0] <= DDS_SLAVE_WR_DATA;
         4'h6:    phase_ctrl[wr_addr[7:4]][1] <= DDS_SLAVE_WR_DATA;
         4'h7:    phase_ctrl[wr_addr[7:4]][2] <= DDS_SLAVE_WR_DATA;
         4'h8:    phase_ctrl[wr_addr[7:4]][3] <= DDS_SLAVE_WR_DATA;
         default: phase_ctrl[wr_addr[7:4]][0] <= phase_ctrl[wr_addr[7:4]][0];
      endcase
   else 
      for(wave_channel=0;wave_channel<CHANNEL_NUM;wave_channel=wave_channel+1)
         for(wave_select=0;wave_select<(2**WAVE_STORE);wave_select=wave_select+1)
            phase_ctrl[wave_channel][wave_select] <= phase_ctrl[wave_channel][wave_select];
end

always @(posedge clk or negedge DDS_SLAVE_RSTN_SYNC) begin
   if(~DDS_SLAVE_RSTN_SYNC)
      dds_wr_enable <= 0;
   else if(DDS_SLAVE_WR_DATA_VALID && DDS_SLAVE_WR_DATA_READY && (wr_addr[7:4] < CHANNEL_NUM) && (wr_addr[3:0] == 4'h9))
         dds_wr_enable[wr_addr[7:4]] <= DDS_SLAVE_WR_DATA[0];
   else
      dds_wr_enable <= dds_wr_enable;
end

always @(*) begin
   if(~DDS_SLAVE_RSTN_SYNC)
      dds_wr_valid <= 0;
   else if(DDS_SLAVE_WR_DATA_VALID && DDS_SLAVE_WR_DATA_READY && (wr_addr[7:4] < CHANNEL_NUM) && (wr_addr[3:0] == 4'hA))
         dds_wr_valid <= dds_wr_enable;
   else dds_wr_valid <= 0;
end
assign dds_wr_data = DDS_SLAVE_WR_DATA;

genvar dds_channel;
generate
   for(dds_channel=0; dds_channel<CHANNEL_NUM; dds_channel=dds_channel+1) //例化CHANNEL_NUM个DDS模块
   begin:dds_inst
      dds #(
         .HORIZON_RESOLUTION  (HORIZON_RESOLUTION  ), //水平分辨率
         .VERTICAL_RESOLUTION (VERTICAL_RESOLUTION ), //垂直分辨率
         .ADDER_LOWBIT        (ADDER_LOWBIT        ), //相位累加器低位宽度
         .WAVE_STORE          (WAVE_STORE          )  //波形存储数目
      )dds_inst (
         .clk       (clk                     ), //系统时钟,50MHz
         .rstn      (DDS_SLAVE_RSTN_SYNC     ), //复位信号,低电平有效
         .wave_sel  (wave_sel   [dds_channel]), //波形选通，共WAVE_STORE组
         .freq_ctrl (freq_ctrl  [dds_channel]), //频率控制，位宽与相位累加器位宽相同，共WAVE_STORE组
         .phase_ctrl(phase_ctrl [dds_channel]), //相位控制，位宽与一个周期的地址位相同，共WAVE_STORE组
         .wave_out  (wave_out[(dds_channel*VERTICAL_RESOLUTION) +: VERTICAL_RESOLUTION]), //输出wave_sel选中的波形
         .wr_enable (dds_wr_enable[dds_channel]), //对wave_sel选中的波形对应的地址写
         .wr_valid  (dds_wr_valid [dds_channel]), //对wave_sel选中的波形对应的地址写
         .wr_data   (dds_wr_data             )  //对wave_sel选中的波形对应的地址写
      );
   end
endgenerate

endmodule