`include "JTAG_CMD.v"
module JTAG_test_IDCODE_top (
    input wire clk,
    input wire rst_n,

    output wire tck,
    output wire tms,
    output wire tdi,
    input wire tdo,

    output wire [5:0] seg_sel, //数码管位选，最左侧数码管为最高位
    output wire [7:0] seg_led, //数码管段选
    output reg init_done
);

wire rst;
wire pll_lock;
assign rst = ~(rst_n && pll_lock);
reg [3:0] cmd;
wire shift_in;
wire shift_ready;
reg [31:0] cycle_num;
wire cmd_ready;
wire cmd_valid;
wire cmd_done;
wire shift_out     ;
wire clk_sys, clk_jtag;

clk_gen clk_gen_inst (
  .clkin1(clk),        // input
  .pll_lock(pll_lock),    // output
  .clkout0(clk_jtag),      // output
  .clkout1(clk_sys)       // output
);

tap_FSM tap_FSM_inst(
.clk                (clk_jtag      ),
.rst                (rst           ),

.tck                (tck           ),
.tms                (tms           ),
.tdi                (tdi           ),
.tdo                (tdo           ),

.cmd                (cmd           ), //传入的指令
.cycle_num          (cycle_num     ), //指令循环的次数，包括shift_in的比特流大小，以及IDLE时间。部分指令支持。
.cmd_ready          (cmd_ready     ), //准备信号
.cmd_valid          (cmd_valid     ), //有效信号，与准备信号都为高电平时握手成功

.shift_in           (shift_in      ), //传入的比特流
.shift_ready        (shift_ready   ), //比特流数据是否有效。只有shift_ready为高电平时内部逻辑会更新比特流
.shift_out          (shift_out     ), //传出的比特流
.tap_shift          (tap_shift     ), //比特流更新使能

.cmd_done           (cmd_done      )  //CMD指令已经全部执行完毕
);

reg [31:0] idcode;
always @(posedge tck) begin
    if(rst) idcode <= 0;
    else if(tap_shift) idcode <= {shift_out     ,idcode[31:1]};
    else idcode <= idcode;
end
// always @(posedge tck) begin
//     if(rst) idcode <= 0;
//     else if(tap_shift) idcode[9:0] <= {tdi,idcode[9:1]};
//     else idcode <= idcode;
// end
always @(posedge tck) begin
    if(rst) init_done <= 0;
    else if(idcode[27:0] == 28'h0602899) init_done <= 1;
    else init_done <= init_done;
end

seg_led seg_led_inst(
    .clk    (clk    ),   //时钟信号
    .rst_n  (rst_n  ),   //复位信号
       
    .data   (idcode[19:0]),   //6位数码管要显示的数值
    .point  (0      ),   //小数点具体显示的位置,从高到低,高电平有效
    .en     (1      ),   //数码管使能信号
    .sign   (0      ),   //符号位（高电平显示"-"号）
       
    .seg_sel(seg_sel),   //数码管位选，最左侧数码管为最高位
    .seg_led(seg_led)    //数码管段选
);

/*
获取IDCODE的顺序：
0. CMD_JTAG_CLOSE_TEST                  0
1. CMD_JTAG_RUN_TEST                    0
2. CMD_JTAG_LOAD_IR    `JTAG_DR_IDCODE  10
3. CMD_JTAG_RUN_TEST                    0
4. CMD_JTAG_LOAD_DR    NOTCARE          32
5. CMD_JTAG_CLOSE_TEST                  0
*/

reg [4:0] cmd_store_st;
always @(posedge clk_jtag) begin
    if(rst) cmd_store_st <= 0;
    else if(cmd_ready && cmd_valid) cmd_store_st <= cmd_store_st + 1;
    else cmd_store_st <= cmd_store_st;
end

assign cmd_valid = (rst == 0) && (cmd_store_st <= 4'h5);
always @(*) begin
    case (cmd_store_st)
        4'h0:    begin cmd <= `CMD_JTAG_CLOSE_TEST; cycle_num <= 0;     end
        4'h1:    begin cmd <= `CMD_JTAG_RUN_TEST  ; cycle_num <= 0;     end
        4'h2:    begin cmd <= `CMD_JTAG_LOAD_IR   ; cycle_num <= 10;    end
        4'h3:    begin cmd <= `CMD_JTAG_RUN_TEST  ; cycle_num <= 0;     end
        4'h4:    begin cmd <= `CMD_JTAG_LOAD_DR   ; cycle_num <= 32;    end
        4'h5:    begin cmd <= `CMD_JTAG_CLOSE_TEST; cycle_num <= 0;     end
        default: begin cmd <= `CMD_JTAG_CLOSE_TEST; cycle_num <= 0;     end
    endcase
end

reg [31:0] wwwww_cnt;
reg [10+32-1:0] wr_data_fifo;
wire wr_bit;
reg wr_en;
assign wr_bit = wr_data_fifo[0];
reg [31:0] en_cnt;
always @(posedge clk_jtag) begin
    if(rst) en_cnt <= 0;
    else en_cnt <= en_cnt + 1;
end
always @(posedge clk_jtag) begin
    if(rst) wr_en <= 1;
    else if((wwwww_cnt < 10+32) && ((en_cnt < 3) || (en_cnt > 1000)))
        wr_en <= 1;
    else wr_en <= 0;
end

always @(posedge clk_jtag) begin
    if(rst) begin
        wwwww_cnt <= 0;
        wr_data_fifo <= {{32'b0},{`JTAG_DR_IDCODE}};
    end else if((wr_en == 1) && (wwwww_cnt < 10+32)) begin
        wwwww_cnt <= wwwww_cnt + 1;
        wr_data_fifo <= (wr_en)?(wr_data_fifo >> 1):(wr_data_fifo);
    end
    else begin
        wwwww_cnt <= wwwww_cnt;
        wr_data_fifo <= wr_data_fifo;
    end
end

wire rd_en, rd_bit, almost_empty;
assign rd_en = tap_shift;
assign shift_in = rd_bit;
assign shift_ready = ~almost_empty;

cmd_bit_fifo cmd_bit_fifo_inst(
    .clk         (clk_jtag    ),
    .rst         (rst         ),

    .wr_en       (wr_en       ),
    .wr_bit      (wr_bit      ),

    .rd_en       (rd_en       ),
    .rd_bit      (rd_bit      ),

    .full        (            ),
    .empty       (            ),
    .almost_full (            ),
    .almost_empty(almost_empty)
);

endmodule