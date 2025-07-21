module dso_axi_slave #(
    parameter CLK_FS = 32'd50_000_000 // 基准时钟频率值
)(
    input  wire         clk,
    input  wire         rstn,

    //dso interface
    input  wire         ad_clk/* synthesis PAP_MARK_DEBUG="true" */,
    input  wire [7:0]   ad_data/* synthesis PAP_MARK_DEBUG="true" */,

    //axi slave interface
    output wire         DSO_SLAVE_CLK          /* synthesis PAP_MARK_DEBUG="true" */,
    output wire         DSO_SLAVE_RSTN         ,
    input  wire [4-1:0] DSO_SLAVE_WR_ADDR_ID   ,
    input  wire [31:0]  DSO_SLAVE_WR_ADDR      ,
    input  wire [ 7:0]  DSO_SLAVE_WR_ADDR_LEN  ,
    input  wire [ 1:0]  DSO_SLAVE_WR_ADDR_BURST,
    input  wire         DSO_SLAVE_WR_ADDR_VALID,
    output wire         DSO_SLAVE_WR_ADDR_READY,
    input  wire [31:0]  DSO_SLAVE_WR_DATA      ,
    input  wire [ 3:0]  DSO_SLAVE_WR_STRB      ,
    input  wire         DSO_SLAVE_WR_DATA_LAST ,
    input  wire         DSO_SLAVE_WR_DATA_VALID,
    output  reg         DSO_SLAVE_WR_DATA_READY,
    output wire [4-1:0] DSO_SLAVE_WR_BACK_ID   ,
    output wire [ 1:0]  DSO_SLAVE_WR_BACK_RESP ,
    output wire         DSO_SLAVE_WR_BACK_VALID,
    input  wire         DSO_SLAVE_WR_BACK_READY,
    input  wire [4-1:0] DSO_SLAVE_RD_ADDR_ID   ,
    input  wire [31:0]  DSO_SLAVE_RD_ADDR      /* synthesis PAP_MARK_DEBUG="true" */,
    input  wire [ 7:0]  DSO_SLAVE_RD_ADDR_LEN  /* synthesis PAP_MARK_DEBUG="true" */,
    input  wire [ 1:0]  DSO_SLAVE_RD_ADDR_BURST,
    input  wire         DSO_SLAVE_RD_ADDR_VALID,
    output wire         DSO_SLAVE_RD_ADDR_READY,
    output wire [4-1:0] DSO_SLAVE_RD_BACK_ID   ,
    output  reg [31:0]  DSO_SLAVE_RD_DATA      /* synthesis PAP_MARK_DEBUG="true" */,
    output wire [ 1:0]  DSO_SLAVE_RD_DATA_RESP /* synthesis PAP_MARK_DEBUG="true" */,
    output wire         DSO_SLAVE_RD_DATA_LAST /* synthesis PAP_MARK_DEBUG="true" */,
    output  reg         DSO_SLAVE_RD_DATA_VALID/* synthesis PAP_MARK_DEBUG="true" */,
    input  wire         DSO_SLAVE_RD_DATA_READY/* synthesis PAP_MARK_DEBUG="true" */
);

// 复位同步逻辑
wire DSO_SLAVE_RSTN_SYNC;
assign DSO_SLAVE_CLK = clk;
assign DSO_SLAVE_RSTN = DSO_SLAVE_RSTN_SYNC;
rstn_sync dso_rstn_sync(clk,rstn,DSO_SLAVE_RSTN_SYNC);

/*
0x0000_0000: R/W [0]    wave_run    启动捕获/关闭
0x0000_0001: R/W [7:0]  trig_level  触发电平
0x0000_0002: R/W [0]    trig_edge   触发边沿，0-下降沿，1-上升沿
0x0000_0003: R/W [9:0]  h_shift     水平偏移量
0x0000_0004: R/W [9:0]  deci_rate   抽样率，0-1023
0x0000_0005: R/W [0]    ram_refresh RAM刷新
0x0000_0006: R   [19:0] ad_freq     AD采样频率
0x0000_0007: R   [7:0]  ad_vpp      AD采样幅度
0x0000_0008: R   [7:0]  ad_max      AD采样最大值
0x0000_0009: R   [7:0]  ad_min      AD采样最小值

0x0000_1000-0x0000_13FF: R [7:0] wave_rd_data 共1024个字节
*/
localparam ADDR_WAVE_RUN   = 32'h0000_0000,
           ADDR_TRIG_LEVEL = 32'h0000_0001,
           ADDR_TRIG_EDGE  = 32'h0000_0002,
           ADDR_H_SHIFT    = 32'h0000_0003,
           ADDR_DECI_RATE  = 32'h0000_0004,
           ADDR_RAM_REFRESH= 32'h0000_0005,
           ADDR_AD_FREQ    = 32'h0000_0006,
           ADDR_AD_VPP     = 32'h0000_0007,
           ADDR_AD_MAX     = 32'h0000_0008,
           ADDR_AD_MIN     = 32'h0000_0009,
           ADDR_WAVE_RD_DATA_START = 32'h0000_1000,
           ADDR_WAVE_RD_DATA_END   = 32'h0000_13FF;

reg       wave_run;   // 波形采集启动/停止寄存器
reg [7:0] trig_level; // 触发电平寄存器
reg       trig_edge;  // 触发边沿寄存器
reg [9:0] h_shift;    // 波形水平偏移量寄存器
reg [9:0] deci_rate;  // 抽样率寄存器
reg       ram_refresh;// RAM刷新寄存器

wire [9:0] wave_rd_addr;

reg wave_rd_data_valid;

// outports wire
wire [7:0]  	wave_rd_data;
wire [19:0] 	ad_freq;
wire [7:0]  	ad_vpp;
wire [7:0]  	ad_max;
wire [7:0]  	ad_min;

//_________________写___通___道_________________//
reg [ 3:0] wr_addr_id;    // 写地址ID寄存器
reg [31:0] wr_addr;       // 写地址寄存器
reg [ 1:0] wr_addr_burst; // 写突发类型寄存器
reg        wr_transcript_error, wr_transcript_error_reg; // 写传输错误标志及其寄存器

// 写通道状态机定义
reg [ 1:0] cu_wrchannel_st, nt_wrchannel_st;  // 当前状态和下一状态
localparam ST_WR_IDLE = 2'b00, // 写通道空闲
           ST_WR_DATA = 2'b01, // 地址线握手成功，数据线通道开启
           ST_WR_RESP = 2'b10; // 写响应

//_________________读___通___道_________________//
reg [ 3:0] rd_addr_id;     // 读地址ID寄存器
reg [31:0] rd_addr;        // 读地址寄存器
reg [ 7:0] rd_addr_len;    // 读突发长度寄存器
reg [ 1:0] rd_addr_burst;  // 读突发类型寄存器
reg [ 7:0] rd_data_trans_num; // 读数据传输计数器
reg        rd_transcript_error, rd_transcript_error_reg; // 读传输错误标志及其寄存器

// 读通道状态机定义
reg [ 1:0] cu_rdchannel_st, nt_rdchannel_st;  // 当前状态和下一状态
localparam ST_RD_IDLE = 2'b00, // 发送完LAST和RESP，读通道空闲
           ST_RD_DATA = 2'b01; // 地址线握手成功，数据线通道开启

//_______________________________________________________________________________//
// 写通道状态机状态转换逻辑
always @(*) begin
    case (cu_wrchannel_st)
        ST_WR_IDLE: nt_wrchannel_st = (DSO_SLAVE_WR_ADDR_VALID && DSO_SLAVE_WR_ADDR_READY)?(ST_WR_DATA):(ST_WR_IDLE);
        ST_WR_DATA: nt_wrchannel_st = (DSO_SLAVE_WR_DATA_VALID && DSO_SLAVE_WR_DATA_READY && DSO_SLAVE_WR_DATA_LAST)?(ST_WR_RESP):(ST_WR_DATA);
        ST_WR_RESP: nt_wrchannel_st = (DSO_SLAVE_WR_BACK_VALID && DSO_SLAVE_WR_BACK_READY)?(ST_WR_IDLE):(ST_WR_RESP);
        default   : nt_wrchannel_st = ST_WR_IDLE;
    endcase
end

// 写通道状态机时序逻辑
always @(posedge clk or negedge DSO_SLAVE_RSTN_SYNC) begin
    if(~DSO_SLAVE_RSTN_SYNC) cu_wrchannel_st <= ST_WR_IDLE;
    else cu_wrchannel_st <= nt_wrchannel_st;
end

// 写通道控制信号生成
assign DSO_SLAVE_WR_ADDR_READY = (DSO_SLAVE_RSTN_SYNC) && (cu_wrchannel_st == ST_WR_IDLE);
assign DSO_SLAVE_WR_BACK_VALID = (DSO_SLAVE_RSTN_SYNC) && (cu_wrchannel_st == ST_WR_RESP);
assign DSO_SLAVE_WR_BACK_RESP  = ((DSO_SLAVE_RSTN_SYNC) && ((~wr_transcript_error) && (~wr_transcript_error_reg)))?(2'b00):(2'b10);
assign DSO_SLAVE_WR_BACK_ID    = wr_addr_id;

// 写通道地址和突发类型寄存
always @(posedge clk or negedge DSO_SLAVE_RSTN_SYNC) begin
    if(~DSO_SLAVE_RSTN_SYNC) begin
        wr_addr_id    <= 0;
        wr_addr_burst <= 0;
    end else if(DSO_SLAVE_WR_ADDR_VALID && DSO_SLAVE_WR_ADDR_READY) begin
        wr_addr_id    <= DSO_SLAVE_WR_ADDR_ID;
        wr_addr_burst <= DSO_SLAVE_WR_ADDR_BURST;
    end else begin
        wr_addr_id    <= wr_addr_id;
        wr_addr_burst <= wr_addr_burst;
    end
end

// 写地址计算逻辑
always @(posedge clk or negedge DSO_SLAVE_RSTN_SYNC) begin
    if(~DSO_SLAVE_RSTN_SYNC) wr_addr <= 0;
    else if(DSO_SLAVE_WR_ADDR_VALID && DSO_SLAVE_WR_ADDR_READY) wr_addr <= DSO_SLAVE_WR_ADDR;
    else if((wr_addr_burst == 2'b01) && DSO_SLAVE_WR_DATA_VALID && DSO_SLAVE_WR_DATA_READY) wr_addr <= wr_addr + 1;
    else wr_addr <= wr_addr;
end

// 写错误检测逻辑
always @(*) begin
    if((~DSO_SLAVE_RSTN_SYNC) || (cu_wrchannel_st == ST_WR_IDLE) || (cu_wrchannel_st == ST_WR_RESP)) wr_transcript_error = 0;
    else if((wr_addr_burst == 2'b10) || (wr_addr_burst == 2'b11)) wr_transcript_error = 1;
    else if((wr_addr < ADDR_WAVE_RUN) || (wr_addr > ADDR_RAM_REFRESH)) wr_transcript_error = 1;
    else wr_transcript_error = 0;
end

// 写错误状态寄存
always @(posedge clk or negedge DSO_SLAVE_RSTN_SYNC) begin
    if((~DSO_SLAVE_RSTN_SYNC) || (cu_wrchannel_st == ST_WR_IDLE)) wr_transcript_error_reg <= 0;
    else wr_transcript_error_reg <= (wr_transcript_error)?(1):(wr_transcript_error_reg);
end

// 写数据READY选通
always @(*) begin
    if(cu_wrchannel_st == ST_WR_DATA) begin
             DSO_SLAVE_WR_DATA_READY = 1;
    end else DSO_SLAVE_WR_DATA_READY = 0;
end

reg [31:0] ram_refresh_delay;
// 写数据处理逻辑
always @(posedge clk or negedge DSO_SLAVE_RSTN_SYNC) begin
    if(~DSO_SLAVE_RSTN_SYNC) begin
        wave_run    <= 0 ; //???
        trig_level  <= 8'd128; //???
        trig_edge   <= 0 ; //???
        h_shift     <= 0 ; //???
        deci_rate   <= 10'd2; //???
        ram_refresh <= 0 ; //???
        ram_refresh_delay <= 0;
    end else if(DSO_SLAVE_WR_DATA_VALID && DSO_SLAVE_WR_DATA_READY) begin
        case(wr_addr)
            ADDR_WAVE_RUN: begin
                if(DSO_SLAVE_WR_STRB[0]) wave_run <= DSO_SLAVE_WR_DATA[0];
            end
            ADDR_TRIG_LEVEL: begin
                if(DSO_SLAVE_WR_STRB[0]) trig_level <= DSO_SLAVE_WR_DATA[7:0];
            end
            ADDR_TRIG_EDGE: begin
                if(DSO_SLAVE_WR_STRB[0]) trig_edge <= DSO_SLAVE_WR_DATA[0];
            end
            ADDR_H_SHIFT: begin
                if(DSO_SLAVE_WR_STRB[1]) h_shift[9:8] <= DSO_SLAVE_WR_DATA[9:8];
                if(DSO_SLAVE_WR_STRB[0]) h_shift[7:0] <= DSO_SLAVE_WR_DATA[7:0];
            end
            ADDR_DECI_RATE: begin
                if(DSO_SLAVE_WR_STRB[1]) deci_rate[9:8] <= DSO_SLAVE_WR_DATA[9:8];
                if(DSO_SLAVE_WR_STRB[0]) deci_rate[7:0] <= DSO_SLAVE_WR_DATA[7:0];
            end
            ADDR_RAM_REFRESH: begin
                if(DSO_SLAVE_WR_STRB[0]) ram_refresh <= DSO_SLAVE_WR_DATA[0];
            end
            default: begin
            end
        endcase
    end else begin
        wave_run    <= wave_run   ;
        trig_level  <= trig_level ;
        trig_edge   <= trig_edge  ;
        h_shift     <= h_shift    ;
        deci_rate   <= deci_rate  ;
        ram_refresh <= (ram_refresh_delay >= 32'h0000_FFFF)?(0):(ram_refresh);
        ram_refresh_delay <= ((ram_refresh_delay >= 32'h0000_FFFF) || (~ram_refresh))?(0):(ram_refresh_delay + 1);
    end
end

//_______________________________________________________________________________//
// 读通道状态机状态转换逻辑
always @(*) begin
    case (cu_rdchannel_st)
        ST_RD_IDLE: nt_rdchannel_st = (DSO_SLAVE_RD_ADDR_VALID && DSO_SLAVE_RD_ADDR_READY)?(ST_RD_DATA):(ST_RD_IDLE);
        ST_RD_DATA: nt_rdchannel_st = (DSO_SLAVE_RD_DATA_VALID && DSO_SLAVE_RD_DATA_READY && DSO_SLAVE_RD_DATA_LAST)?(ST_RD_IDLE):(ST_RD_DATA);
        default   : nt_rdchannel_st = ST_RD_IDLE;
    endcase
end

// 读通道状态机时序逻辑
always @(posedge clk or negedge DSO_SLAVE_RSTN_SYNC) begin
    if(~DSO_SLAVE_RSTN_SYNC) cu_rdchannel_st <= ST_RD_IDLE;
    else cu_rdchannel_st <= nt_rdchannel_st;
end

// 读通道控制信号生成
assign DSO_SLAVE_RD_ADDR_READY = (DSO_SLAVE_RSTN_SYNC) && (cu_rdchannel_st == ST_RD_IDLE);
assign DSO_SLAVE_RD_BACK_ID = rd_addr_id;
assign DSO_SLAVE_RD_DATA_RESP = ((DSO_SLAVE_RSTN_SYNC) && ((~rd_transcript_error) && (~rd_transcript_error_reg)))?(2'b00):(2'b10);

// 读通道地址和突发参数寄存
always @(posedge clk or negedge DSO_SLAVE_RSTN_SYNC) begin
    if(~DSO_SLAVE_RSTN_SYNC) begin
        rd_addr_id <= 0;
        rd_addr_burst <= 0;
        rd_addr_len <= 0;
    end else if(DSO_SLAVE_RD_ADDR_VALID && DSO_SLAVE_RD_ADDR_READY) begin
        rd_addr_id <= DSO_SLAVE_RD_ADDR_ID;
        rd_addr_burst <= DSO_SLAVE_RD_ADDR_BURST;
        rd_addr_len <= DSO_SLAVE_RD_ADDR_LEN;
    end else begin
        rd_addr_id <= rd_addr_id;
        rd_addr_burst <= rd_addr_burst;
        rd_addr_len <= rd_addr_len;
    end
end

// 读地址计算逻辑
always @(posedge clk or negedge DSO_SLAVE_RSTN_SYNC) begin
    if(~DSO_SLAVE_RSTN_SYNC) rd_addr <= 0;
    else if(DSO_SLAVE_RD_ADDR_VALID && DSO_SLAVE_RD_ADDR_READY) rd_addr <= DSO_SLAVE_RD_ADDR;
    else if(DSO_SLAVE_RD_DATA_VALID && DSO_SLAVE_RD_DATA_READY) rd_addr <= rd_addr + 1;
    else rd_addr <= rd_addr;
end

// 读数据传输计数器
always @(posedge clk or negedge DSO_SLAVE_RSTN_SYNC) begin
    if(~DSO_SLAVE_RSTN_SYNC || (cu_rdchannel_st == ST_RD_IDLE)) rd_data_trans_num <= 0;
    else if(DSO_SLAVE_RD_DATA_VALID && DSO_SLAVE_RD_DATA_READY) rd_data_trans_num <= rd_data_trans_num + 1;
    else rd_data_trans_num <= rd_data_trans_num;
end

// 读通道控制信号生成
assign DSO_SLAVE_RD_DATA_LAST = (DSO_SLAVE_RD_DATA_VALID) && (rd_data_trans_num == rd_addr_len);

// 读错误检测逻辑
always @(*) begin
    if(cu_rdchannel_st == ST_RD_IDLE) rd_transcript_error = 0;
    else if((rd_addr_burst == 2'b10) || (rd_addr_burst == 2'b11)) rd_transcript_error = 1;
    else if((rd_addr >= ADDR_WAVE_RUN) && (rd_addr <= ADDR_AD_MIN)) rd_transcript_error = 0;
    else if((rd_addr >= ADDR_WAVE_RD_DATA_START) && (rd_addr <= ADDR_WAVE_RD_DATA_END)) rd_transcript_error = 0;
    else rd_transcript_error = 1;
end

// 读错误状态寄存
always @(posedge clk or negedge DSO_SLAVE_RSTN_SYNC) begin
    if((~DSO_SLAVE_RSTN_SYNC) || (cu_rdchannel_st == ST_RD_IDLE)) rd_transcript_error_reg <= 0;
    else rd_transcript_error_reg <= (rd_transcript_error)?(1):(rd_transcript_error_reg);
end

// 读数据VALID选通
always @(*) begin
    if(cu_rdchannel_st == ST_RD_DATA) begin
        if((rd_addr >= ADDR_WAVE_RD_DATA_START) && (rd_addr <= ADDR_WAVE_RD_DATA_END))
             DSO_SLAVE_RD_DATA_VALID = wave_rd_data_valid;
        else DSO_SLAVE_RD_DATA_VALID = 1;
    end else DSO_SLAVE_RD_DATA_VALID = 0;
end

// 读数据选通
always @(*) begin
    if(cu_rdchannel_st == ST_RD_DATA) begin
        if((rd_addr >= ADDR_WAVE_RD_DATA_START) && (rd_addr <= ADDR_WAVE_RD_DATA_END)) begin
            DSO_SLAVE_RD_DATA <= {24'b0, wave_rd_data};
        end else case(rd_addr)
            ADDR_WAVE_RUN           : DSO_SLAVE_RD_DATA <= {31'b0, wave_run};
            ADDR_TRIG_LEVEL         : DSO_SLAVE_RD_DATA <= {24'b0, trig_level};
            ADDR_TRIG_EDGE          : DSO_SLAVE_RD_DATA <= {31'b0, trig_edge};
            ADDR_H_SHIFT            : DSO_SLAVE_RD_DATA <= {22'b0, h_shift};
            ADDR_DECI_RATE          : DSO_SLAVE_RD_DATA <= {22'b0, deci_rate};
            ADDR_RAM_REFRESH        : DSO_SLAVE_RD_DATA <= {31'b0, ram_refresh};
            ADDR_AD_FREQ            : DSO_SLAVE_RD_DATA <= {12'b0, ad_freq};
            ADDR_AD_VPP             : DSO_SLAVE_RD_DATA <= {24'b0, ad_vpp};
            ADDR_AD_MAX             : DSO_SLAVE_RD_DATA <= {24'b0, ad_max};
            ADDR_AD_MIN             : DSO_SLAVE_RD_DATA <= {24'b0, ad_min};
            default                 : DSO_SLAVE_RD_DATA <= 32'hFFFFFFFF;
        endcase
    end else DSO_SLAVE_RD_DATA <= 32'hFFFFFFFF;
end

always @(posedge clk or negedge DSO_SLAVE_RSTN_SYNC) begin
    if(~DSO_SLAVE_RSTN_SYNC) wave_rd_data_valid <= 0;
    else if((cu_rdchannel_st == ST_RD_DATA) && (rd_addr >= ADDR_WAVE_RD_DATA_START) && (rd_addr <= ADDR_WAVE_RD_DATA_END)) begin
        if(wave_rd_data_valid == 0) wave_rd_data_valid <= 1;
        else if(DSO_SLAVE_RD_DATA_VALID && DSO_SLAVE_RD_DATA_READY) wave_rd_data_valid <= 0;
        else wave_rd_data_valid <= wave_rd_data_valid;
    end else wave_rd_data_valid <= 0;
end

assign wave_rd_addr = rd_addr[9:0];
dso_top #(
    .CLK_FS 	( CLK_FS  ) // 基准时钟频率值
)u_dso_top(
	.clk          	( clk           ),
	.rstn         	( DSO_SLAVE_RSTN_SYNC),
	.ad_clk       	( ad_clk        ),
	.ad_data      	( ad_data       ),
	.wave_run     	( wave_run      ),
	.trig_level   	( trig_level    ),
	.trig_edge    	( trig_edge     ),
	.h_shift      	( h_shift       ),
	.deci_rate    	( deci_rate     ),
	.ram_refresh  	( ram_refresh   ),
	.wave_rd_addr 	( wave_rd_addr  ),
	.wave_rd_data 	( wave_rd_data  ),
	.outrange     	(               ),
	.ad_pulse     	(               ),
	.ad_freq      	( ad_freq       ),
	.ad_vpp       	( ad_vpp        ),
	.ad_max       	( ad_max        ),
	.ad_min       	( ad_min        )
);

endmodule