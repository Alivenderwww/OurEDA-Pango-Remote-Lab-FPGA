module JTAG_SALVE #(
    parameter ADDR_LEN = 4;
)(
    input wire clk,
    input wire rst,

    output wire tck,
    output wire tdi,
    output wire tms,
    input  wire tdo,

    input  wire [ADDR_LEN-1:0] WR_ADDR      , //写地址
    input  wire         [ 7:0] WR_LEN       , //写突发长度，实际长度为WR_LEN+1
    input  wire                WR_BURST     , //写突发类型，1为增量突发，0为固定突发
    input  wire                WR_ADDR_VALID, //写地址通道有效
    output wire                WR_ADDR_READY, //写地址通道准备
     
    input  wire        [ 31:0] WR_DATA      , //写数据
    input  wire        [  3:0] WR_STRB      , //写数据掩码
    input  wire                WR_DATA_VALID, //写数据有效
    output reg                 WR_DATA_READY, //写数据准备
    input  wire                WR_DATA_LAST , //最后一个写数据标志位
     
    input  wire         [27:0] RD_ADDR      , //读地址
    input  wire         [ 7:0] RD_LEN       , //读突发长度，实际长度为WR_LEN+1
    input  wire                RD_BURST     , //读突发类型，1为增量突发，0为固定突发
    input  wire                RD_ADDR_VALID, //读地址通道有效
    output wire                RD_ADDR_READY, //读地址通道准备
     
    output wire        [31:0] RD_DATA      , //读数据
    output wire               RD_DATA_LAST , //最后一个读数据标志位
    input  reg                RD_DATA_READY, //读数据准备
    output wire               RD_DATA_VALID, //读数据有效
);

/*
将JTAG控制器做成AXI-SLAVE:
有一个地址是fifo_shift_data写入口，只写，一次进32bit数据。
有一个地址是fifo_shift_cmd写入口，只写，一次进32bit数据，格式为{CMD,CMD_CYCLE_LEN}
因此需要在AXI信号中加入AWBURST和ARBURST，做出修改如下：
AXBURST = 1'b0 固定突发，仅对ADDR当前地址做LEN突发长度的读写。适合对FIFO的读写。
AXBURST = 1'b1 增量突发，突发长度+1，ADDR也+1。适合对存储器的读写。
接下来设定32位的标志位地址，标志JTAG运行逻辑。
其中有一位是CMD_DONE，即JTAG空闲标志
其中有一位是CMD_FIFO_DATA_RESET，若其置1则强制fifo_shift_data清空，清空后自动置0。
其中有一位是CMD_FIFO_CMD_RESET，若其置1则强制fifo_shift_cmd清空，清空后自动置0。
其他的可以先空出来备用。
shift_out_data怎么办？鉴于移出的数据与TAP内部寄存器一一对应，因此完全可以做一个寄存器映射
，存储着Lab_FPGA的移位寄存器。
因此需要设置一个IDCODE寄存器地址
因此需要设置3个UID寄存器地址(UID是96位)
需要设置n个（n根据芯片类型固定）边界扫描寄存器地址
*/

reg [31:0] SU_reg;
wire tap_shift;
wire [3:0] cmd;
wire [27:0] cycle_num;
wire shift_out;
wire cmd_ready;
wire [9:0] IR_reg;
wire cmd_done;


//________________写地址逻辑________________//
reg [1:0] cu_wr_cnt, nt_wr_cnt;
localparam WR_ST_IDLE  = 2'b00,
           WR_ST_TRANS = 2'b01,
           WR_ST_IDLE  = 2'b00,
           WR_ST_IDLE  = 2'b00;
always @(*) begin
    if(rst)  nt_wr_cnt <= 0;
    else case (cu_wr_cnt)
        WR_ST_IDLE : nt_wr_cnt <= (WR_ADDR_VALID && WR_ADDR_READY)?(WR_ST_TRANS):(WR_ST_IDLE);
        WR_ST_TRANS: nt_wr_cnt <= (WR_DATA_VALID && WR_DATA_READY && WR_DATA_LAST)?(WR_ST_IDLE):(WR_ST_TRANS);
        default    : nt_wr_cnt <= WR_ST_IDLE;
    endcase
end
always @(posedge clk) cu_wr_cnt <= nt_wr_cnt;

reg [ADDR_LEN-1:0] wr_addr_load;
reg wr_burst_load;
always @(posedge clk) begin
    if(rst) wr_addr_load <= 0;
    else if(cu_wr_cnt == WR_ST_IDLE && nt_wr_cnt == WR_ST_TRANS) wr_addr_load <= WR_ADDR;
    else if(WR_DATA_VALID && WR_DATA_READY && wr_burst_load == 1'b1) wr_addr_load <= wr_addr_load + 1;
    else wr_addr_load <= wr_addr_load;
end
always @(posedge clk) begin
    if(rst) wr_burst_load <= 0;
    else if(cu_wr_cnt == WR_ST_IDLE && nt_wr_cnt == WR_ST_TRANS) wr_burst_load <= WR_BURST;
    else wr_burst_load <= wr_burst_load;
end
//________________读地址逻辑________________//
reg [1:0] cu_rd_cnt, nt_rd_cnt;
localparam RD_ST_IDLE  = 2'b00,
           RD_ST_TRANS = 2'b01,
           RD_ST_IDLE  = 2'b00,
           RD_ST_IDLE  = 2'b00;
always @(*) begin
    if(rst)  nt_rd_cnt <= 0;
    else case (cu_rd_cnt)
        RD_ST_IDLE : nt_rd_cnt <= (RD_ADDR_VALID && RD_ADDR_READY)?(RD_ST_TRANS):(RD_ST_IDLE);
        RD_ST_TRANS: nt_rd_cnt <= (RD_DATA_VALID && RD_DATA_READY && RD_DATA_LAST)?(RD_ST_IDLE):(RD_ST_TRANS);
        default    : nt_rd_cnt <= RD_ST_IDLE;
    endcase
end
always @(posedge clk) cu_rd_cnt <= nt_rd_cnt;

reg [ADDR_LEN-1:0] rd_addr_load;
reg rd_burst_load;
reg [7:0] rd_len_load;
assign RD_DATA_LAST = (RD_DATA_READY) && (rd_len_load == 0);
always @(posedge clk) begin
    if(rst) rd_addr_load <= 0;
    else if(cu_rd_cnt == RD_ST_IDLE && nt_rd_cnt == RD_ST_TRANS) rd_addr_load <= RD_ADDR;
    else if(RD_DATA_VALID && RD_DATA_READY && rd_burst_load == 1'b1) rd_addr_load <= rd_addr_load + 1;
    else rd_addr_load <= rd_addr_load;
end
always @(posedge clk) begin
    if(rst) rd_len_load <= 0;
    else if(cu_rd_cnt == RD_ST_IDLE && nt_rd_cnt == RD_ST_TRANS) rd_len_load <= RD_LEN;
    else if(RD_DATA_VALID && RD_DATA_READY && (~RD_DATA_LAST)) rd_len_load <= rd_len_load - 1;
    else rd_len_load <= rd_len_load;
end
always @(posedge clk) begin
    if(rst) rd_burst_load <= 0;
    else if(cu_rd_cnt == RD_ST_IDLE && nt_rd_cnt == RD_ST_TRANS) rd_burst_load <= RD_BURST;
    else rd_burst_load <= rd_burst_load;
end
//______________写数据逻辑______________//
/*
目前暂时规定
0x0为状态寄存器，先空出来不用
0x1为IDCODE
0x2为fifo_shift_data写入口
0x3为fifo_shift_cmd写入口
其余的都是空
*/

reg        fifo_shift_data_wr_en    ;
reg [31:0] fifo_shift_data_wr_data  ;
wire        fifo_shift_data_rd_en   ;
wire [31:0] fifo_shift_data_rd_data ;
wire        fifo_shift_data_full    ;
wire        fifo_shift_data_empty   ;
reg         fifo_shift_data_out_valid;
wire        fifo_shift_data_last;
always @(posedge clk) begin
    if(rst) 
         fifo_shift_data_out_valid <= 0;
    else if(fifo_shift_data_empty && tap_shift && fifo_shift_data_out_valid)
         fifo_shift_data_out_valid <= 0;
    else if((~fifo_shift_data_out_valid) && (~fifo_shift_data_empty) && (fifo_shift_data_rd_en))
         fifo_shift_data_out_valid <= 1;
    else fifo_shift_data_out_valid <= fifo_shift_data_out_valid;
end
assign fifo_shift_data_rd_en = (tap_shift);
//fifo_shift_data_out_valid标志着当前的rd_data有没有被读过
//fifo_shift_data_empty标志着当前fifo是不是空
//因此标志着当前rd_data是不是最后一个data的fifo_shift_data_last的逻辑为：
assign fifo_shift_data_last = (fifo_shift_data_empty);

always @(*) begin
    if(cu_wr_cnt == WR_ST_TRANS && wr_addr_load == 4'h2) begin
        fifo_shift_data_wr_en = (WR_DATA_READY && WR_DATA_VALID);
        fifo_shift_data_wr_data = WR_DATA;
    end else begin
        fifo_shift_data_wr_en = 0;
        fifo_shift_data_wr_data = 0;
    end
end

fifo_shift_data fifo_shift_data_inst(
    .clk        (clk                     ),
    .rst        (rst                     ),
    .wr_en      (fifo_shift_data_wr_en   ),
    .wr_data    (fifo_shift_data_wr_data ),
    .rd_en      (fifo_shift_data_rd_en   ),
    .rd_data    (fifo_shift_data_rd_data ),
    .wr_full    (fifo_shift_data_full    ),
    .rd_empty   (fifo_shift_data_empty   )
);


reg         fifo_shift_cmd_wr_en   ;
reg  [31:0] fifo_shift_cmd_wr_data ;
wire        fifo_shift_cmd_rd_en   ;
wire [31:0] fifo_shift_cmd_rd_data ;
wire        fifo_shift_cmd_full    ;
wire        fifo_shift_cmd_empty   ;
reg         fifo_shift_cmd_out_valid;
always @(posedge clk) begin
    if(rst) 
         fifo_shift_cmd_out_valid <= 0;
    else if(fifo_shift_cmd_empty && tap_shift && fifo_shift_cmd_out_valid)
         fifo_shift_cmd_out_valid <= 0;
    else if((~fifo_shift_cmd_out_valid) && (~fifo_shift_cmd_empty) && (fifo_shift_cmd_rd_en))
         fifo_shift_cmd_out_valid <= 1;
    else fifo_shift_cmd_out_valid <= fifo_shift_cmd_out_valid;
end
assign fifo_shift_cmd_rd_en = (fifo_shift_cmd_out_valid) && (cmd_ready);

always @(*) begin
    if(cu_wr_cnt == WR_ST_TRANS && wr_addr_load == 4'h3) begin
        fifo_shift_cmd_wr_en = (WR_DATA_READY && WR_DATA_VALID);
        fifo_shift_cmd_wr_data = WR_DATA;
    end else begin
        fifo_shift_cmd_wr_en = 0;
        fifo_shift_cmd_wr_data = 0;
    end
end

fifo_shift_cmd fifo_shift_cmd_inst(
    .clk        (clk                    ),
    .rst        (rst                    ),
    .wr_en      (fifo_shift_cmd_wr_en   ),
    .wr_data    (fifo_shift_cmd_wr_data ),
    .rd_en      (fifo_shift_cmd_rd_en   ),
    .rd_data    ({cmd,cycle_num}        ),
    .wr_full    (fifo_shift_cmd_full    ),
    .rd_empty   (fifo_shift_cmd_empty   )
);

//TAP FSM implementation
tap_FSM #(
    .CMD_STORE(3),  //2^n
    .CMD_LEN  (4),
    .CYCLE_LEN(28)
)tap_FSM_inst(
.clk        (clk                     ),
.rst        (rst                     ),

.tck        (tck                     ),
.tms        (tms                     ), //TMS在TCK上升沿被芯片读取，需要在下降沿改变值
.tdi        (tdi                     ), //TDI在TCK上升沿被芯片读取，需要在下降沿改变值
.tdo        (tdo                     ), //TDO在TCK下降沿被芯片改变值，需要在上升沿读取

.cmd        (cmd                     ), //自定义CMD命令
.cycle_num  (cycle_num               ), //循环次数
.shift_in   (fifo_shift_data_rd_data ), //移位比特流，低位先入
.shift_ready(fifo_shift_data_last    ), //拉低表示shift_in是上级fifo中最后一个bit. 会使JTAG进入PAUSE态
.shift_out  (shift_out               ), //从TDO读出的移位比特流

.cmd_valid  (fifo_shift_cmd_out_valid), //cmd, cycle_num有效信号
.cmd_ready  (cmd_ready               ), //准备信号
.tap_shift  (tap_shift               ), //表示当前TAP状态为SHIFT_XR
.ir_reg     (IR_regs                 ), //当前TAP的IR寄存器是什么寄存器，方便上级模块处理shift_out
.cmd_done   (cmd_done                )  //暂存列全空标志位
);


assign WR_ADDR_READY = (cu_wr_cnt == WR_ST_TRANS);
always @(*) begin
    if(cu_wr_cnt == WR_ST_IDLE) WR_DATA_READY <= 0;
    else case (wr_addr_load)
        4'h0: WR_DATA_READY <= 1;
        4'h1: WR_DATA_READY <= 1;
        4'h2: WR_DATA_READY <= ~fifo_shift_data_full;
        4'h3: WR_DATA_READY <= ~fifo_shift_cmd_full;
    endcase
end
assign RD_ADDR_READY = (cu_rd_cnt == RD_ST_IDLE);
assign RD_DATA_VALID = (cu_rd_cnt == RD_ST_TRANS);
always @(*) begin
    if(cu_rd_cnt == RD_ST_IDLE) begin
        RD_DATA <= 0;
        RD_DATA_VALID <= 1;
    end else case (rd_addr_load)
        4'h0: begin RD_DATA <= SU_reg; RD_DATA_VALID <= 1;end
        4'h1: begin RD_DATA <= IR_reg; RD_DATA_VALID <= 1;end
        4'h2: begin RD_DATA <= 0     ; RD_DATA_VALID <= 1;end//禁止读，因此直接跳过，默认读到的值为0
        4'h3: begin RD_DATA <= 0     ; RD_DATA_VALID <= 1;end//禁止读，因此直接跳过，默认读到的值为0
    endcase
end



endmodule