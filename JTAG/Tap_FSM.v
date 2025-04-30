`include "JTAG_CMD.vh"

//TAP FSM implementation
module tap_FSM #(
    parameter CMD_STORE = 3,  //2^n
    parameter CMD_LEN   = 4,
    parameter CYCLE_LEN = 28
)(
input  wire                clk           ,
input  wire                rstn          ,

input  wire                jtag_rd_en    ,
input  wire                jtag_wr_en    ,
output reg                 tms           , //TMS在TCK上升沿被芯片读取，需要在下降沿改变值
output reg                 tdi           , //TDI在TCK上升沿被芯片读取，需要在下降沿改变值
input  wire                tdo           , //TDO在TCK下降沿被芯片改变值，需要在上升沿读取

input  wire [  CMD_LEN-1:0] cmd          , //自定义CMD命令
input  wire [CYCLE_LEN-1:0] cycle_num    , //循环次数
input  wire                 shift_in     , //移位比特流，低位先入
output wire                 shift_in_rd  , //移位入使能
input  wire                 shift_in_last, //拉高表示shift_in是上级fifo中最后一个bit. 会使JTAG进入PAUSE态
output wire                 shift_out    , //从TDO读出的移位比特流
input  wire                 shift_out_last,//拉高表示当前shift_out再存就会满. 会使JTAG进入PAUSE态
output wire                 shift_out_wr , //移位出使能

input  wire                 cmd_valid    , //cmd, cycle_num有效信号
output wire                 cmd_ready    , //准备信号
output wire   [15:0]        tap_state    , //当前TAP状态
output wire                 cmd_done       //暂存列全空标志位
);

wire tap_rstn_sync;
rstn_sync rstn_sync_tap(clk, rstn, tap_rstn_sync);
/*
CMD指令(cmd, cycle_num)在模块内有暂存列，最多可存8条CMD, 与FIFO一样执行完毕后自动向前补。
当cmd_valid == 1且cmd_ready == 1时cmd被写入模块内。
shift_out在tap_shift为高电平时开始输入，因此要求上级模块将要输入的shift流排成FIFO等待输入。
*/
localparam CMD_STORE_NUM = 2**CMD_STORE;

reg [15:0] cu_tap_state; //TAP状态机，由TMS驱动，与芯片内部TAP状态机同步
reg [15:0] nt_tap_state; //TAP状态机，由TMS驱动，与芯片内部TAP状态机同步
reg        tlr_or_rti; ////上级模块需通过指令CMD_JTAG_CLOSE_TEST或CMD_JTAG_RUN_TEST改变Tap_FSM的状态，分别为默认TLR和默认RTI状态
reg [CYCLE_LEN-1:0] cnt_cycle;//循环计数器, 为n代表当前时钟周期为第n次循环
wire  tdi_reg;
reg   tms_reg;
reg flag_cmd_one_done;
reg [CMD_LEN-1:0] cmd_load [0:CMD_STORE_NUM-1];
reg [CYCLE_LEN-1:0] cycle_num_load [0:CMD_STORE_NUM-1];
reg [CMD_STORE:0] cmd_running_wr_pointer;
reg [CMD_STORE:0] cmd_running_rd_pointer;
wire [CMD_LEN-1:0] cmd_running_now;
wire [CYCLE_LEN-1:0] cycle_num_running_now;
wire cycle_over;
assign cycle_over = (cnt_cycle >= cycle_num_running_now);
assign tap_state = cu_tap_state;

//_____________与芯片内部完全同步的设计, 以上升沿为触发信号___________
always @(posedge clk or negedge tap_rstn_sync) begin
    if(~tap_rstn_sync) cnt_cycle <= 0;
    else if(~jtag_rd_en) cnt_cycle <= cnt_cycle;
    else if(cu_tap_state == `TAP_UNKNOWN) cnt_cycle <= (tms)?(cnt_cycle + 1):(1);
    else if(flag_cmd_one_done || cmd_done) cnt_cycle <= 0;
    else case (cmd_running_now)
        `CMD_JTAG_LOAD_IR      : cnt_cycle <= (nt_tap_state == `TAP_SHIFT_IR     )?(cnt_cycle + 1):(cnt_cycle);
        `CMD_JTAG_LOAD_DR_CAREI: cnt_cycle <= (nt_tap_state == `TAP_SHIFT_DR     )?(cnt_cycle + 1):(cnt_cycle);
        `CMD_JTAG_LOAD_DR_CAREO: cnt_cycle <= (nt_tap_state == `TAP_SHIFT_DR     )?(cnt_cycle + 1):(cnt_cycle);
        `CMD_JTAG_IDLE_DELAY   : cnt_cycle <= (nt_tap_state == `TAP_RUN_TEST_IDLE)?(cnt_cycle + 1):(cnt_cycle);
        default                : cnt_cycle <= cnt_cycle;
    endcase
end

always @(*) begin
    begin
        case (cu_tap_state)
            `TAP_UNKNOWN          : nt_tap_state <= (tms && cnt_cycle >= 5)?(`TAP_TEST_LOGIC_RESET):(`TAP_UNKNOWN      );
            `TAP_TEST_LOGIC_RESET : nt_tap_state <= (tms                  )?(`TAP_TEST_LOGIC_RESET):(`TAP_RUN_TEST_IDLE);
            `TAP_RUN_TEST_IDLE    : nt_tap_state <= (tms                  )?(`TAP_SELECT_DR_SCAN  ):(`TAP_RUN_TEST_IDLE);
            `TAP_SELECT_DR_SCAN   : nt_tap_state <= (tms                  )?(`TAP_SELECT_IR_SCAN  ):(`TAP_CAPTURE_DR   );
            `TAP_CAPTURE_DR       : nt_tap_state <= (tms                  )?(`TAP_EXIT1_DR        ):(`TAP_SHIFT_DR     );
            `TAP_SHIFT_DR         : nt_tap_state <= (tms                  )?(`TAP_EXIT1_DR        ):(`TAP_SHIFT_DR     );
            `TAP_EXIT1_DR         : nt_tap_state <= (tms                  )?(`TAP_UPDATE_DR       ):(`TAP_PAUSE_DR     );
            `TAP_PAUSE_DR         : nt_tap_state <= (tms                  )?(`TAP_EXIT2_DR        ):(`TAP_PAUSE_DR     );
            `TAP_EXIT2_DR         : nt_tap_state <= (tms                  )?(`TAP_UPDATE_DR       ):(`TAP_SHIFT_DR     );
            `TAP_UPDATE_DR        : nt_tap_state <= (tms                  )?(`TAP_SELECT_DR_SCAN  ):(`TAP_RUN_TEST_IDLE);
            `TAP_SELECT_IR_SCAN   : nt_tap_state <= (tms                  )?(`TAP_TEST_LOGIC_RESET):(`TAP_CAPTURE_IR   );
            `TAP_CAPTURE_IR       : nt_tap_state <= (tms                  )?(`TAP_EXIT1_IR        ):(`TAP_SHIFT_IR     );
            `TAP_SHIFT_IR         : nt_tap_state <= (tms                  )?(`TAP_EXIT1_IR        ):(`TAP_SHIFT_IR     );
            `TAP_EXIT1_IR         : nt_tap_state <= (tms                  )?(`TAP_UPDATE_IR       ):(`TAP_PAUSE_IR     );
            `TAP_PAUSE_IR         : nt_tap_state <= (tms                  )?(`TAP_EXIT2_IR        ):(`TAP_PAUSE_IR     );
            `TAP_EXIT2_IR         : nt_tap_state <= (tms                  )?(`TAP_UPDATE_IR       ):(`TAP_SHIFT_IR     );
            `TAP_UPDATE_IR        : nt_tap_state <= (tms                  )?(`TAP_SELECT_DR_SCAN  ):(`TAP_RUN_TEST_IDLE);
            default               : nt_tap_state <= `TAP_UNKNOWN;
        endcase
    end
end

always @(posedge clk or negedge tap_rstn_sync)begin
    if(~tap_rstn_sync) cu_tap_state <= `TAP_UNKNOWN;
    else if(jtag_rd_en) cu_tap_state <= nt_tap_state;
    else cu_tap_state <= cu_tap_state;
end

assign tdi_reg           = ((cu_tap_state == `TAP_SHIFT_DR) || (cu_tap_state == `TAP_SHIFT_IR))?(shift_in):(0);
assign shift_out         = ((cu_tap_state == `TAP_SHIFT_DR) || (cu_tap_state == `TAP_SHIFT_IR))?(tdo):(0);
assign shift_in_rd       = (((cu_tap_state == `TAP_SHIFT_DR) || (cu_tap_state == `TAP_SHIFT_IR)))?(cmd_running_now == `CMD_JTAG_LOAD_DR_CAREI || cmd_running_now == `CMD_JTAG_LOAD_IR):(0);
assign shift_out_wr      = (((cu_tap_state == `TAP_SHIFT_DR) || (cu_tap_state == `TAP_SHIFT_IR)))?(cmd_running_now == `CMD_JTAG_LOAD_DR_CAREO):(0);

//_______________CMD暂存列逻辑________________
assign cmd_running_now = cmd_load[cmd_running_rd_pointer[CMD_STORE-1:0]];
assign cycle_num_running_now = cycle_num_load[cmd_running_rd_pointer[CMD_STORE-1:0]];

assign cmd_done = (cmd_running_wr_pointer == cmd_running_rd_pointer);
assign cmd_ready = (tap_rstn_sync) && ((cmd_running_wr_pointer ^ cmd_running_rd_pointer) != {1'b1,{(CMD_STORE-1){1'b0}}});

integer i;
always @(posedge clk or negedge tap_rstn_sync) begin
    if(~tap_rstn_sync) cmd_running_wr_pointer <= 0;
    else if(jtag_rd_en && cmd_valid && cmd_ready) cmd_running_wr_pointer <= cmd_running_wr_pointer + 1;
    else cmd_running_wr_pointer <= cmd_running_wr_pointer;
end
always @(posedge clk or negedge tap_rstn_sync) begin
    if(~tap_rstn_sync) for(i=0;i<CMD_STORE_NUM;i=i+1) cmd_load[i] <= 0;
    else if(jtag_rd_en && cmd_valid && cmd_ready) cmd_load[cmd_running_wr_pointer[CMD_STORE-1:0]] <= cmd;
end
always @(posedge clk or negedge tap_rstn_sync) begin
    if(~tap_rstn_sync) for(i=0;i<CMD_STORE_NUM;i=i+1) cycle_num_load[i] <= 0;
    else if(jtag_rd_en && cmd_valid && cmd_ready) cycle_num_load[cmd_running_wr_pointer[CMD_STORE-1:0]] <= cycle_num;
end
always @(posedge clk or negedge tap_rstn_sync) begin
    if(~tap_rstn_sync);
    else if(jtag_rd_en && cmd_valid && cmd_ready)$display("%m: at time %0t INFO: Jtag recv a cmd-%b, cyclenum-%u.", $time, cmd, cycle_num);
end

always @(*) begin
    if(cmd_done == 0) case (cmd_running_now)
        `CMD_JTAG_CLOSE_TEST      : flag_cmd_one_done <= (nt_tap_state == `TAP_TEST_LOGIC_RESET)?(1):(0);
        `CMD_JTAG_RUN_TEST        : flag_cmd_one_done <= (nt_tap_state == `TAP_RUN_TEST_IDLE)?(1):(0);
        `CMD_JTAG_LOAD_IR         : flag_cmd_one_done <= (nt_tap_state == `TAP_UPDATE_IR)?(1):(0);
        `CMD_JTAG_LOAD_DR_CAREI   : flag_cmd_one_done <= (nt_tap_state == `TAP_UPDATE_DR)?(1):(0);
        `CMD_JTAG_LOAD_DR_CAREO   : flag_cmd_one_done <= (nt_tap_state == `TAP_UPDATE_DR)?(1):(0);
        `CMD_JTAG_IDLE_DELAY      : flag_cmd_one_done <= (cycle_over)?(1):(0);
        default                   : flag_cmd_one_done <= (nt_tap_state == `TAP_TEST_LOGIC_RESET)?(1):(0);
    endcase else flag_cmd_one_done <= 0;
end

always @(posedge clk or negedge tap_rstn_sync) begin
    if(~tap_rstn_sync) cmd_running_rd_pointer <= 0;
    else if(jtag_rd_en && flag_cmd_one_done) cmd_running_rd_pointer <= cmd_running_rd_pointer + 1;
    else cmd_running_rd_pointer <= cmd_running_rd_pointer;
end

//tlr_or_rti切换逻辑 0为TLR 1为RTI
always @(posedge clk or negedge tap_rstn_sync) begin
    if(~tap_rstn_sync) tlr_or_rti <= 0;
    else if(jtag_rd_en && flag_cmd_one_done) begin
        if(cmd_running_now == `CMD_JTAG_RUN_TEST) tlr_or_rti <= 1;
        else if(cmd_running_now == `CMD_JTAG_CLOSE_TEST) tlr_or_rti <= 0;
        else tlr_or_rti <= tlr_or_rti;
    end else tlr_or_rti <= tlr_or_rti;
end

//_______________TMS信号逻辑________________
always @(*) begin
    if(cmd_done) begin
        if(tlr_or_rti == 0) tms_reg <= 1;
        else case (cu_tap_state)
            `TAP_TEST_LOGIC_RESET: tms_reg <= 0;
            `TAP_RUN_TEST_IDLE   : tms_reg <= 0;
            `TAP_SELECT_DR_SCAN  : tms_reg <= 0;
            `TAP_UPDATE_DR       : tms_reg <= 0;
            `TAP_SELECT_IR_SCAN  : tms_reg <= 0;
            `TAP_UPDATE_IR       : tms_reg <= 0;
            default              : tms_reg <= 1;
        endcase
    end else case (cmd_running_now)
        `CMD_JTAG_CLOSE_TEST          : tms_reg <= 1;
        `CMD_JTAG_RUN_TEST  :begin
            case (cu_tap_state)
                `TAP_TEST_LOGIC_RESET : tms_reg <= 0;
                `TAP_RUN_TEST_IDLE    : tms_reg <= 0;
                `TAP_UPDATE_DR        : tms_reg <= 0;
                `TAP_UPDATE_IR        : tms_reg <= 0;
                default               : tms_reg <= 1;
            endcase
        end
        `CMD_JTAG_LOAD_IR   :begin
            case (cu_tap_state)
                `TAP_TEST_LOGIC_RESET : tms_reg <= 0;
                `TAP_SELECT_IR_SCAN   : tms_reg <= 0;
                `TAP_CAPTURE_IR       : tms_reg <= (shift_in_last)?(1):(0);
                `TAP_SHIFT_IR         : tms_reg <= ((cycle_over) || (shift_in_last))?(1):(0);
                `TAP_EXIT1_IR         : tms_reg <= (cycle_over)?(1):(0);
                `TAP_PAUSE_IR         : tms_reg <= (cycle_over)?(1):((~shift_in_last)?(1):(0));
                `TAP_EXIT2_IR         : tms_reg <= (cycle_over)?(1):(0);
                default               : tms_reg <= 1;
            endcase
        end
        `CMD_JTAG_LOAD_DR_CAREI:begin
            case (cu_tap_state)
                `TAP_TEST_LOGIC_RESET : tms_reg <= 0;
                `TAP_SELECT_DR_SCAN   : tms_reg <= 0;
                `TAP_CAPTURE_DR       : tms_reg <= (shift_in_last)?(1):(0);
                `TAP_SHIFT_DR         : tms_reg <= ((cycle_over) || (shift_in_last))?(1):(0);
                `TAP_EXIT1_DR         : tms_reg <= (cycle_over)?(1):(0);
                `TAP_PAUSE_DR         : tms_reg <= (cycle_over)?(1):((~shift_in_last)?(1):(0));
                `TAP_EXIT2_DR         : tms_reg <= (cycle_over)?(1):(0);
                default               : tms_reg <= 1;
            endcase
        end
        `CMD_JTAG_LOAD_DR_CAREO:begin
            case (cu_tap_state)
                `TAP_TEST_LOGIC_RESET : tms_reg <= 0;
                `TAP_SELECT_DR_SCAN   : tms_reg <= 0;
                `TAP_CAPTURE_DR       : tms_reg <= (shift_out_last)?(1):(0);
                `TAP_SHIFT_DR         : tms_reg <= ((cycle_over) || (shift_out_last))?(1):(0);
                `TAP_EXIT1_DR         : tms_reg <= (cycle_over)?(1):(0);
                `TAP_PAUSE_DR         : tms_reg <= (cycle_over)?(1):((~shift_out_last)?(1):(0));
                `TAP_EXIT2_DR         : tms_reg <= (cycle_over)?(1):(0);
                default               : tms_reg <= 1;
            endcase
        end
        `CMD_JTAG_IDLE_DELAY:begin
            case (cu_tap_state)
                `TAP_TEST_LOGIC_RESET : tms_reg <= 0;
                `TAP_RUN_TEST_IDLE    : tms_reg <= (cycle_over);
                `TAP_SELECT_DR_SCAN   : tms_reg <= 0;
                `TAP_UPDATE_DR        : tms_reg <= 0;
                `TAP_SELECT_IR_SCAN   : tms_reg <= 0;
                `TAP_UPDATE_IR        : tms_reg <= 0;
                default               : tms_reg <= 1;
            endcase
        end
        default                       : tms_reg <= 1;
    endcase
end

//_____________输出信号需要下降沿更新_________________
always @(posedge clk or negedge tap_rstn_sync) begin
    if(~tap_rstn_sync) begin
        tms <= 0;
        tdi <= 0;
    end else if(jtag_wr_en) begin
        tms <= tms_reg;
        tdi <= tdi_reg;
    end else begin
        tms <= tms;
        tdi <= tdi;
    end
end

endmodule