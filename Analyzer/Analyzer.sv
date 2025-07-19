module Analazer #(
    parameter DIGITAL_IN_NUM = 8  // 数字输入引脚数量
)(
    input  wire clk,
    input  wire rstn,
    input  wire [DIGITAL_IN_NUM-1:0] digital_in, // 输入数字信号

    output logic             ANALYZER_SLAVE_CLK          ,
    output logic             ANALYZER_SLAVE_RSTN         ,
    input  logic [4-1:0]     ANALYZER_SLAVE_WR_ADDR_ID   ,
    input  logic [31:0]      ANALYZER_SLAVE_WR_ADDR      ,
    input  logic [ 7:0]      ANALYZER_SLAVE_WR_ADDR_LEN  ,
    input  logic [ 1:0]      ANALYZER_SLAVE_WR_ADDR_BURST,
    input  logic             ANALYZER_SLAVE_WR_ADDR_VALID,
    output logic             ANALYZER_SLAVE_WR_ADDR_READY,
    input  logic [31:0]      ANALYZER_SLAVE_WR_DATA      ,
    input  logic [ 3:0]      ANALYZER_SLAVE_WR_STRB      ,
    input  logic             ANALYZER_SLAVE_WR_DATA_LAST ,
    input  logic             ANALYZER_SLAVE_WR_DATA_VALID,
    output logic             ANALYZER_SLAVE_WR_DATA_READY,
    output logic [4-1:0]     ANALYZER_SLAVE_WR_BACK_ID   ,
    output logic [ 1:0]      ANALYZER_SLAVE_WR_BACK_RESP ,
    output logic             ANALYZER_SLAVE_WR_BACK_VALID,
    input  logic             ANALYZER_SLAVE_WR_BACK_READY,
    input  logic [4-1:0]     ANALYZER_SLAVE_RD_ADDR_ID   ,
    input  logic [31:0]      ANALYZER_SLAVE_RD_ADDR      ,
    input  logic [ 7:0]      ANALYZER_SLAVE_RD_ADDR_LEN  ,
    input  logic [ 1:0]      ANALYZER_SLAVE_RD_ADDR_BURST,
    input  logic             ANALYZER_SLAVE_RD_ADDR_VALID,
    output logic             ANALYZER_SLAVE_RD_ADDR_READY,
    output logic [4-1:0]     ANALYZER_SLAVE_RD_BACK_ID   ,
    output logic [31:0]      ANALYZER_SLAVE_RD_DATA      ,
    output logic [ 1:0]      ANALYZER_SLAVE_RD_DATA_RESP ,
    output logic             ANALYZER_SLAVE_RD_DATA_LAST ,
    output logic             ANALYZER_SLAVE_RD_DATA_VALID,
    input  logic             ANALYZER_SLAVE_RD_DATA_READY
);
/*
0x0000_0000    R/W [ 0]      capture on:    置1开始等待捕获，0停止捕获。捕获到信号后该位自动清零。 
                   [ 8]      capture force: 置1则强制捕获信号，自动置0。
                   [16]      capture busy:  1为逻辑分析仪正在捕获信号。
                   [24]      capture done:  1为逻辑分析仪内存完整存储了此次捕获的信号。
配置顺序：若[0]为0，则将其置1，随后不断获取[0]，若其变为0则表示触发成功。随后不断获取[24]，若其为1则表示捕获完成。
0x0000_0001    R/W [1:0] global trig mode:  00: 全局与  (&)
                                            01: 全局或  (|)
                                            10: 全局非与(~&)
                                            11: 全局非或(~|)
0x0000_0010 - 0x0000_0017 R/W [5:0] 信号M的触发操作符，共8路
                              [5:3] M's Operator: 000 ==
                                                  001 !=
                                                  010 <
                                                  011 <=
                                                  100 >
                                                  101 >=
                              [2:0] M's Value:    000 LOGIC 0
                                                  001 LOGIC 1
                                                  010 X(not care)
                                                  011 RISE
                                                  100 FALL
                                                  101 RISE OR FALL
                                                  110 NOCHANGE
                                                  111 SOME NUMBER
0x0100_0000 - 0x0100_03FF 只读 32位波形存储，得到的32位数据中低八位最先捕获，高八位最后捕获。
                               共1024个地址，每个地址存储4组，深度为4096。
*/
wire analyzer_rstn_sync;
rstn_sync rstn_sync_analyzer(clk, rstn, analyzer_rstn_sync);
assign ANALYZER_SLAVE_CLK  = clk;
assign ANALYZER_SLAVE_RSTN = analyzer_rstn_sync;

reg trig_force;
reg analyzer_on;
reg [1:0] global_trig_mode;

// inports wire
reg         trig;       // 触发信号，##高电平##触发
wire [11:0] wave_addr;  // 读存储地址
// outports wire
wire        busy;
wire        done;
wire [31:0] wave_out;
// outports wire
wire [DIGITAL_IN_NUM-1:0] multi_trig;
reg [5:0] op[0:DIGITAL_IN_NUM-1]; // 触发操作符

//_________________写___通___道_________________//
reg [ 3:0] wr_addr_id;
reg [31:0] wr_addr;
reg [ 3:0] wr_addr_burst;
reg        wr_transcript_error, wr_transcript_error_reg;
//ANALYZER作为SLAVE不接收WR_ADDR_LEN，其DATA线的结束以WR_DATA_LAST为参考。
reg [ 1:0] cu_wrchannel_st, nt_wrchannel_st;
localparam ST_WR_IDLE = 2'b00, //写通道空闲
           ST_WR_DATA = 2'b01, //地址线握手成功，数据线通道开启
           ST_WR_RESP = 2'b10; //写响应
localparam GLOBAL_AND = 2'b00, //全局与
           GLOBAL_OR  = 2'b01, //全局或
           GLOBAL_NAND= 2'b10, //全局非与
           GLOBAL_NOR = 2'b11; //全局非或
//_________________读___通___道_________________//
reg [ 3:0] rd_addr_id;
reg [31:0] rd_addr;
reg [ 7:0] rd_addr_len;
reg [ 3:0] rd_addr_burst;
reg [ 7:0] rd_data_trans_num;
reg        rd_transcript_error, rd_transcript_error_reg;
reg [ 1:0] cu_rdchannel_st, nt_rdchannel_st;
localparam ST_RD_IDLE = 2'b00, //发送完LAST和RESP，读通道空闲
           ST_RD_DATA = 2'b01; //地址线握手成功，数据线通道开启

//_______________________________________________________________________________//
always @(*) begin
    case (cu_wrchannel_st)
        ST_WR_IDLE: nt_wrchannel_st <= (ANALYZER_SLAVE_WR_ADDR_VALID && ANALYZER_SLAVE_WR_ADDR_READY)?(ST_WR_DATA):(ST_WR_IDLE);
        ST_WR_DATA: nt_wrchannel_st <= (ANALYZER_SLAVE_WR_DATA_VALID && ANALYZER_SLAVE_WR_DATA_READY && ANALYZER_SLAVE_WR_DATA_LAST)?(ST_WR_RESP):(ST_WR_DATA);
        ST_WR_RESP: nt_wrchannel_st <= (ANALYZER_SLAVE_WR_BACK_VALID && ANALYZER_SLAVE_WR_BACK_READY)?(ST_WR_IDLE):(ST_WR_RESP);
        default   : nt_wrchannel_st <= ST_WR_IDLE;
    endcase
end
always @(posedge clk or negedge analyzer_rstn_sync) begin
    if(~analyzer_rstn_sync) cu_wrchannel_st <= ST_WR_IDLE;
    else cu_wrchannel_st <= nt_wrchannel_st;
end
assign ANALYZER_SLAVE_WR_ADDR_READY = (analyzer_rstn_sync) && (cu_wrchannel_st == ST_WR_IDLE);
assign ANALYZER_SLAVE_WR_BACK_VALID = (analyzer_rstn_sync) && (cu_wrchannel_st == ST_WR_RESP);
assign ANALYZER_SLAVE_WR_BACK_RESP  = ((analyzer_rstn_sync) && ((~wr_transcript_error) && (~wr_transcript_error_reg)))?(2'b00):(2'b10);
assign ANALYZER_SLAVE_WR_BACK_ID    = wr_addr_id;
always @(posedge clk or negedge analyzer_rstn_sync) begin
    if(~analyzer_rstn_sync) begin
        wr_addr_id    <= 0;
        wr_addr_burst <= 0;
    end else if(ANALYZER_SLAVE_WR_ADDR_VALID && ANALYZER_SLAVE_WR_ADDR_READY) begin
        wr_addr_id    <= ANALYZER_SLAVE_WR_ADDR_ID;
        wr_addr_burst <= ANALYZER_SLAVE_WR_ADDR_BURST;
    end else begin
        wr_addr_id    <= wr_addr_id;
        wr_addr_burst <= wr_addr_burst;
    end
end
always @(posedge clk or negedge analyzer_rstn_sync) begin
    if(~analyzer_rstn_sync) wr_addr <= 0;
    else if(ANALYZER_SLAVE_WR_ADDR_VALID && ANALYZER_SLAVE_WR_ADDR_READY) wr_addr <= ANALYZER_SLAVE_WR_ADDR;
    else if((wr_addr_burst == 2'b01) && ANALYZER_SLAVE_WR_DATA_VALID && ANALYZER_SLAVE_WR_DATA_READY) wr_addr <= wr_addr + 1;
    else wr_addr <= wr_addr;
end
always @(*) begin
    if((~analyzer_rstn_sync) || (cu_wrchannel_st == ST_WR_IDLE) || (cu_wrchannel_st == ST_WR_RESP)) wr_transcript_error <= 0;
    else if((wr_addr_burst == 2'b10) || (wr_addr_burst == 2'b11)) wr_transcript_error <= 1;
    else if(wr_addr >= 32'h0100_0000 && wr_addr <= 32'h01FF_FFFF) wr_transcript_error <= 1;
    else wr_transcript_error <= 0;
end
always @(posedge clk or negedge analyzer_rstn_sync) begin
    if((~analyzer_rstn_sync) || (cu_wrchannel_st == ST_WR_IDLE)) wr_transcript_error_reg <= 0;
    else wr_transcript_error_reg <= (wr_transcript_error)?(1):(wr_transcript_error_reg);
end



//_______________________________________________________________________________//
always @(*) begin
    case (cu_rdchannel_st)
        ST_RD_IDLE: nt_rdchannel_st <= (ANALYZER_SLAVE_RD_ADDR_VALID && ANALYZER_SLAVE_RD_ADDR_READY)?(ST_RD_DATA):(ST_RD_IDLE);
        ST_RD_DATA: nt_rdchannel_st <= (ANALYZER_SLAVE_RD_DATA_VALID && ANALYZER_SLAVE_RD_DATA_READY && ANALYZER_SLAVE_RD_DATA_LAST)?(ST_RD_IDLE):(ST_RD_DATA);
        default   : nt_rdchannel_st <= ST_RD_IDLE;
    endcase
end
always @(posedge clk or negedge analyzer_rstn_sync)begin
    if(~analyzer_rstn_sync) cu_rdchannel_st <= ST_RD_IDLE;
    else cu_rdchannel_st <= nt_rdchannel_st;
end
assign ANALYZER_SLAVE_RD_ADDR_READY = (analyzer_rstn_sync) && (cu_rdchannel_st == ST_RD_IDLE);
always @(posedge clk or negedge analyzer_rstn_sync) begin
    if(~analyzer_rstn_sync) begin
        rd_addr_id    <= 0;
        rd_addr_burst <= 0;
        rd_addr_len   <= 0;
    end else if(ANALYZER_SLAVE_RD_ADDR_VALID && ANALYZER_SLAVE_RD_ADDR_READY) begin
        rd_addr_id    <= ANALYZER_SLAVE_RD_ADDR_ID;
        rd_addr_burst <= ANALYZER_SLAVE_RD_ADDR_BURST;
        rd_addr_len   <= ANALYZER_SLAVE_RD_ADDR_LEN;
    end else begin
        rd_addr_id    <= rd_addr_id;
        rd_addr_burst <= rd_addr_burst;
        rd_addr_len   <= rd_addr_len;
    end
end
reg addr_change;
always @(posedge clk or negedge analyzer_rstn_sync) begin
    if(~analyzer_rstn_sync) rd_addr <= 0;
    else if(ANALYZER_SLAVE_RD_ADDR_VALID && ANALYZER_SLAVE_RD_ADDR_READY) rd_addr <= ANALYZER_SLAVE_RD_ADDR;
    else if(ANALYZER_SLAVE_RD_DATA_VALID && ANALYZER_SLAVE_RD_DATA_READY) rd_addr <= rd_addr + 1;
    else rd_addr <= rd_addr;
end
always @(posedge clk or negedge analyzer_rstn_sync) begin
    if(~analyzer_rstn_sync) addr_change <= 0;
    else if(ANALYZER_SLAVE_RD_ADDR_VALID && ANALYZER_SLAVE_RD_ADDR_READY) addr_change <= 1;
    else if(ANALYZER_SLAVE_RD_DATA_VALID && ANALYZER_SLAVE_RD_DATA_READY) addr_change <= 1;
    else addr_change <= 0;
end
always @(posedge clk or negedge analyzer_rstn_sync) begin
    if(~analyzer_rstn_sync || (cu_rdchannel_st == ST_RD_IDLE)) rd_data_trans_num <= 0;
    else if(ANALYZER_SLAVE_RD_DATA_VALID && ANALYZER_SLAVE_RD_DATA_READY) rd_data_trans_num <= rd_data_trans_num + 1;
    else rd_data_trans_num <= rd_data_trans_num;
end
assign ANALYZER_SLAVE_RD_DATA_LAST = (analyzer_rstn_sync) && (cu_rdchannel_st == ST_RD_DATA) && (ANALYZER_SLAVE_RD_DATA_VALID) && (rd_data_trans_num == rd_addr_len);
assign ANALYZER_SLAVE_RD_BACK_ID = rd_addr_id;
assign ANALYZER_SLAVE_RD_DATA_RESP  = ((analyzer_rstn_sync) && (cu_rdchannel_st == ST_RD_DATA) && ((~rd_transcript_error) && (~rd_transcript_error_reg)))?(2'b00):(2'b10);

always @(*) begin
    //写数据READY选通
    if(~analyzer_rstn_sync) ANALYZER_SLAVE_WR_DATA_READY <= 0;
    else if(cu_wrchannel_st == ST_WR_DATA) begin
             ANALYZER_SLAVE_WR_DATA_READY <= 1;
    end else ANALYZER_SLAVE_WR_DATA_READY <= 0;
    //读数据VALID选通
    if(~analyzer_rstn_sync) ANALYZER_SLAVE_RD_DATA_VALID <= 0;
    else if(cu_rdchannel_st == ST_RD_DATA) begin
             if(rd_addr[31:24] == 8'h01) ANALYZER_SLAVE_RD_DATA_VALID <= (~addr_change); //延迟一个周期的读
        else ANALYZER_SLAVE_RD_DATA_VALID <= 1;
    end else ANALYZER_SLAVE_RD_DATA_VALID <= 0;
    //读数据DATA选通
    if(~analyzer_rstn_sync) ANALYZER_SLAVE_RD_DATA <= 0;
    else if(cu_rdchannel_st == ST_RD_DATA) begin
        if(rd_addr >= 32'h0100_0000 && rd_addr <= 32'h01FF_FFFF) ANALYZER_SLAVE_RD_DATA <= wave_out;
        else case(rd_addr)
            32'h0000_0000    : ANALYZER_SLAVE_RD_DATA <= {7'b0,done,7'b0,busy,7'b0,trig_force,7'b0,analyzer_on};
            32'h0000_0001    : ANALYZER_SLAVE_RD_DATA <= {30'b0,global_trig_mode};
            32'h0000_0010    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[0]};
            32'h0000_0011    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[1]};
            32'h0000_0012    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[2]};
            32'h0000_0013    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[3]};
            32'h0000_0014    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[4]};
            32'h0000_0015    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[5]};
            32'h0000_0016    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[6]};
            32'h0000_0017    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[7]};
            default          : ANALYZER_SLAVE_RD_DATA <= 32'hFFFFFFFF; //ERROR，直接跳过默认为全1
        endcase
    end else ANALYZER_SLAVE_RD_DATA <= 0;
end

always @(*) begin
    if((~analyzer_rstn_sync) || (cu_rdchannel_st == ST_RD_IDLE)) rd_transcript_error <= 0;
    else if((rd_addr_burst == 2'b10) || (rd_addr_burst == 2'b11)) rd_transcript_error <= 1;
    else rd_transcript_error <= 0;
end
always @(posedge clk or negedge analyzer_rstn_sync) begin
    if((~analyzer_rstn_sync) || (cu_rdchannel_st == ST_RD_IDLE)) rd_transcript_error_reg <= 0;
    else rd_transcript_error_reg <= (rd_transcript_error)?(1):(rd_transcript_error_reg);
end

//_______32'h00000000_______//
always @(posedge clk or negedge analyzer_rstn_sync) begin
    if(~analyzer_rstn_sync) begin
        analyzer_on <= 0;
        trig_force  <= 0;
    end else if(ANALYZER_SLAVE_WR_DATA_VALID && ANALYZER_SLAVE_WR_DATA_READY && (wr_addr == 32'h0000_0000))begin
        analyzer_on <= (ANALYZER_SLAVE_WR_STRB[0])?(ANALYZER_SLAVE_WR_DATA[0]):(analyzer_on);
        trig_force  <= (ANALYZER_SLAVE_WR_STRB[1])?(ANALYZER_SLAVE_WR_DATA[8]):(trig_force);
    end else begin
        analyzer_on <= (trig)?(0):(analyzer_on);
        trig_force  <= 0;
    end
end

//_______32'h00000001_______//
always @(posedge clk or negedge analyzer_rstn_sync) begin
    if(~analyzer_rstn_sync) global_trig_mode <= 0;
    else if(ANALYZER_SLAVE_WR_DATA_VALID && ANALYZER_SLAVE_WR_DATA_READY && (wr_addr == 32'h0000_0001))begin
        global_trig_mode <= (ANALYZER_SLAVE_WR_STRB[0])?(ANALYZER_SLAVE_WR_DATA[1:0]):(global_trig_mode);
    end else begin
        global_trig_mode  <= global_trig_mode;
    end
end

//_______32'h1000001X_______//
integer i;
always @(posedge clk or negedge analyzer_rstn_sync) begin
    if(~analyzer_rstn_sync) for(i=0;i<DIGITAL_IN_NUM;i=i+1) op[i] <= {3'b000,3'b010};
    else if(ANALYZER_SLAVE_WR_DATA_VALID && ANALYZER_SLAVE_WR_DATA_READY && (wr_addr[31:4] == 32'h0000_001))begin
        for(i=0;i<DIGITAL_IN_NUM;i=i+1) if(wr_addr[3:0] == i)
            op[i] <= (ANALYZER_SLAVE_WR_STRB[0])?(ANALYZER_SLAVE_WR_DATA[5:0]):(op[i]);
    end else for(i=0;i<DIGITAL_IN_NUM;i=i+1) op[i] <= op[i];
end

genvar gen_i;
generate
for (gen_i = 0; gen_i < DIGITAL_IN_NUM; gen_i++) begin : gen_Basic_trigger
    Basic_trigger#((1)) u_Basic_trigger(clk, digital_in[gen_i], op[gen_i], 0, multi_trig[gen_i]);
end
endgenerate


always @(*) begin
    if(~analyzer_on) trig = 0;
    else if(trig_force) trig = 1;
    else case (global_trig_mode)
        GLOBAL_AND : trig = &multi_trig;
        GLOBAL_OR  : trig = |multi_trig;
        GLOBAL_NAND: trig = ~(&multi_trig);
        GLOBAL_NOR : trig = ~(|multi_trig);
    endcase
end

assign wave_addr = (cu_rdchannel_st == ST_RD_DATA) ? rd_addr[11:0] : 12'h000;
Analyzer_datastore #(
	.WAVE_ADDR_WIDTH 	(12),
    .DIGITAL_IN_NUM 	(DIGITAL_IN_NUM)
)u_Analyzer_datastore(
	.clk        	( clk         ),
	.rstn       	( rstn        ),
	.digital_in 	( digital_in  ),
	.trig       	( trig        ),
    .start          ( analyzer_on ),
	.busy       	( busy        ),
	.done       	( done        ),
	.wave_addr  	( wave_addr   ),
	.wave_out   	( wave_out    )
);


endmodule //Analazer