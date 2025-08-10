module Analazer (
    input  wire clk,
    input  wire rstn,
    input  wire [32-1:0] digital_in, // 输入数字信号

    output logic             rd_data_ready,
    input  logic             rd_data_valid,
    output logic [31:0]      rd_data,

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
0x0000_0002    R/W           load_num:       逻辑分析仪捕获的总信号突发长度(32位单位，例：load_num=1，channel_div=0x2, 则总深度为(load_num+1)*(4)=8)
0x0000_0003    R/W           pre_load_num:   逻辑分析仪捕获的信号预存储突发长度(32位单位，例：pre_load_num=0，channel_div=0x2, 则预存储深度为4.)
                                             !!注意：pre_load_num的值必须小于load_num，否则会导致逻辑分析仪无法正常工作。
0x0000_0004    R/W           channel_div:    逻辑分析仪有效通道数，有效值为0x0(一路), 0x1(二路), 0x2(四路), 0x3(八路), 0x04(十六路), 0x05(三十二路)
                                             例：当通道数设置为0x2时，digital_in[0] ~ digital_in[3]存储至DDR内，32位数据宽度的DDR内存中每个数据存储8个时间单位的信号。
                                                 当通道数设置为0x3时，digital_in[0] ~ digital_in[7]存储至DDR内，32位数据宽度的DDR内存中每个数据存储4个时间单位的信号。
                                                 当通道数设置为0x5时，digital_in[0] ~ digital_in[31]存储至DDR内，32位数据宽度的DDR内存中每个数据存储1个时间单位的信号。
0x0000_0005    R/W           clock_div:     逻辑分析仪采样时钟分频系数，0x0表示不分频，0x1表示分频2，0x2表示分频4，0x3表示分频8，以此类推。
                                             例：当clock_div=0x2时，逻辑分析仪采样时钟为系统时钟/4。
0x0000_0010 - 0x0000_002F R/W [5:0] 信号M的触发操作符，共32路
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
*/
wire analyzer_rstn_sync;
rstn_sync rstn_sync_analyzer(clk, rstn, analyzer_rstn_sync);
assign ANALYZER_SLAVE_CLK  = clk;
assign ANALYZER_SLAVE_RSTN = analyzer_rstn_sync;

reg trig_force;
reg analyzer_on;
reg [1:0] global_trig_mode;
reg [7:0] channel_div;
reg [7:0] clock_div; // 逻辑分析仪采样时钟分频系数

// inports wire
reg         trig;       // 触发信号，##高电平##触发
// outports wire
wire        busy;
wire        done;
reg [31:0] load_num;
reg [31:0] pre_load_num;
// outports wire
wire [32-1:0] multi_trig;
reg [5:0] op[0:32-1]; // 触发操作符

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
always @(posedge clk or negedge analyzer_rstn_sync) begin
    if(~analyzer_rstn_sync) rd_addr <= 0;
    else if(ANALYZER_SLAVE_RD_ADDR_VALID && ANALYZER_SLAVE_RD_ADDR_READY) rd_addr <= ANALYZER_SLAVE_RD_ADDR;
    else if((rd_addr_burst == 2'b01) && ANALYZER_SLAVE_RD_DATA_VALID && ANALYZER_SLAVE_RD_DATA_READY) rd_addr <= rd_addr + 1;
    else rd_addr <= rd_addr;
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
    else if(cu_rdchannel_st == ST_RD_DATA) ANALYZER_SLAVE_RD_DATA_VALID <= 1;
    else ANALYZER_SLAVE_RD_DATA_VALID <= 0;
    //读数据DATA选通
    if(~analyzer_rstn_sync) ANALYZER_SLAVE_RD_DATA <= 0;
    else if(cu_rdchannel_st == ST_RD_DATA) begin
        case(rd_addr)
            32'h0000_0000    : ANALYZER_SLAVE_RD_DATA <= {7'b0,done,7'b0,busy,7'b0,trig_force,7'b0,analyzer_on};
            32'h0000_0001    : ANALYZER_SLAVE_RD_DATA <= {30'b0,global_trig_mode};
            32'h0000_0002    : ANALYZER_SLAVE_RD_DATA <= load_num;
            32'h0000_0003    : ANALYZER_SLAVE_RD_DATA <= pre_load_num;
            32'h0000_0004    : ANALYZER_SLAVE_RD_DATA <= {24'b0,channel_div};
            32'h0000_0005    : ANALYZER_SLAVE_RD_DATA <= {24'b0,clock_div};
            32'h0000_0010    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[0]};
            32'h0000_0011    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[1]};
            32'h0000_0012    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[2]};
            32'h0000_0013    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[3]};
            32'h0000_0014    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[4]};
            32'h0000_0015    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[5]};
            32'h0000_0016    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[6]};
            32'h0000_0017    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[7]};
            32'h0000_0018    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[8]};
            32'h0000_0019    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[9]};
            32'h0000_001A    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[10]};
            32'h0000_001B    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[11]};
            32'h0000_001C    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[12]};
            32'h0000_001D    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[13]};
            32'h0000_001E    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[14]};
            32'h0000_001F    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[15]};
            32'h0000_0020    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[16]};
            32'h0000_0021    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[17]};
            32'h0000_0022    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[18]};
            32'h0000_0023    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[19]};
            32'h0000_0024    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[20]};
            32'h0000_0025    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[21]};
            32'h0000_0026    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[22]};
            32'h0000_0027    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[23]};
            32'h0000_0028    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[24]};
            32'h0000_0029    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[25]};
            32'h0000_002A    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[26]};
            32'h0000_002B    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[27]};
            32'h0000_002C    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[28]};
            32'h0000_002D    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[29]};
            32'h0000_002E    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[30]};
            32'h0000_002F    : ANALYZER_SLAVE_RD_DATA <= {26'b0,op[31]};
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

integer i;
always @(posedge clk or negedge analyzer_rstn_sync) begin
    if(~analyzer_rstn_sync) begin
        analyzer_on <= 0;
        trig_force  <= 0;
        global_trig_mode <= 0;
        load_num <= 0;
        pre_load_num <= 0;
        channel_div <= 3;
        clock_div <= 0;
        for(i=0;i<32;i=i+1) op[i] <= {3'b000,3'b010};
    end else if(ANALYZER_SLAVE_WR_DATA_VALID && ANALYZER_SLAVE_WR_DATA_READY)begin
        case(wr_addr)
            32'h0000_0000: begin
                analyzer_on <= (ANALYZER_SLAVE_WR_STRB[0])?(ANALYZER_SLAVE_WR_DATA[0]):(analyzer_on);
                trig_force  <= (ANALYZER_SLAVE_WR_STRB[1])?(ANALYZER_SLAVE_WR_DATA[8]):(trig_force);
            end
            32'h0000_0001: begin
                global_trig_mode <= (ANALYZER_SLAVE_WR_STRB[0])?(ANALYZER_SLAVE_WR_DATA[1:0]):(global_trig_mode);
            end
            32'h0000_0002: begin
                load_num[31:24] <= (ANALYZER_SLAVE_WR_STRB[3])?(ANALYZER_SLAVE_WR_DATA[31:24]):(load_num[31:24]);
                load_num[23:16] <= (ANALYZER_SLAVE_WR_STRB[2])?(ANALYZER_SLAVE_WR_DATA[23:16]):(load_num[23:16]);
                load_num[15: 8] <= (ANALYZER_SLAVE_WR_STRB[1])?(ANALYZER_SLAVE_WR_DATA[15: 8]):(load_num[15: 8]);
                load_num[ 7: 0] <= (ANALYZER_SLAVE_WR_STRB[0])?(ANALYZER_SLAVE_WR_DATA[ 7: 0]):(load_num[ 7: 0]);
            end
            32'h0000_0003: begin
                pre_load_num[31:24] <= (ANALYZER_SLAVE_WR_STRB[3])?(ANALYZER_SLAVE_WR_DATA[31:24]):(pre_load_num[31:24]);
                pre_load_num[23:16] <= (ANALYZER_SLAVE_WR_STRB[2])?(ANALYZER_SLAVE_WR_DATA[23:16]):(pre_load_num[23:16]);
                pre_load_num[15: 8] <= (ANALYZER_SLAVE_WR_STRB[1])?(ANALYZER_SLAVE_WR_DATA[15: 8]):(pre_load_num[15: 8]);
                pre_load_num[ 7: 0] <= (ANALYZER_SLAVE_WR_STRB[0])?(ANALYZER_SLAVE_WR_DATA[ 7: 0]):(pre_load_num[ 7: 0]);
            end
            32'h0000_0004: begin
                channel_div <= (ANALYZER_SLAVE_WR_STRB[0])?(ANALYZER_SLAVE_WR_DATA[ 7: 0]):(channel_div);
            end
            32'h0000_0005: begin
                clock_div <= (ANALYZER_SLAVE_WR_STRB[0])?(ANALYZER_SLAVE_WR_DATA[ 7: 0]):(clock_div);
            end
            default: begin
                if(wr_addr[31:4] == 32'h0000_001 || wr_addr[31:4] == 32'h0000_002) begin
                    for(i=0;i<32;i=i+1) begin
                        if({wr_addr[7:4]-4'd1,wr_addr[3:0]} == i)
                            op[i] <= (ANALYZER_SLAVE_WR_STRB[0])?(ANALYZER_SLAVE_WR_DATA[5:0]):(op[i]);
                    end
                end
            end
        endcase
    end else begin
        analyzer_on <= (trig)?(0):(analyzer_on);
        trig_force  <= 0;
    end
end

genvar gen_i;
generate for (gen_i = 0; gen_i < 32; gen_i++) begin : gen_Basic_trigger
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

Analyzer_datastore u_Analyzer_datastore(
	.clk        	( clk         ),
	.rstn       	( rstn        ),
	.digital_in 	( digital_in  ),
	.trig       	( trig        ),
    .start          ( analyzer_on ),
	.busy       	( busy        ),
	.done       	( done        ),

    .load_num       ( load_num    ),
    .pre_load_num   ( pre_load_num),
    .channel_div    ( channel_div ),
    .clock_div      ( clock_div   ),

    .rd_data_ready  (rd_data_ready),
    .rd_data_valid  (rd_data_valid),
    .rd_data        (rd_data)
);


endmodule //Analazer