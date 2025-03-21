`include "JTAG_CMD.v"
module JTAG_test_top (
    input wire clk,
    input wire rst,

    output wire tck,
    output wire tms,
    output wire tdi,
    input wire tdo
);

reg [3:0] cmd;
wire shift_in_bits;
reg [31:0] cycle_num;
wire cmd_ready;
wire cmd_valid;
wire cmd_done;
wire shift_out_bits;

tap_FSM tap_FSM_inst(
.clk                (clk           ),
.rst                (rst           ),
.tck                (tck           ),
.tms                (tms           ),
.tdi                (tdi           ),
.tdo                (tdo           ),
.cmd                (cmd           ),
.shift_in_bits      (shift_in_bits ),
.cycle_num          (cycle_num     ),
.shift_out_bits     (shift_out_bits),
.tap_shift          (tap_shift     ),
.cmd_done           (cmd_done      ),
.cmd_ready          (cmd_ready     ),
.cmd_valid          (cmd_valid     )
);

/*
装载比特流的顺序：
0. CMD_JTAG_CLOSE_TEST                  0
1. CMD_JTAG_RUN_TEST                    0
2. CMD_JTAG_LOAD_IR    `JTAG_DR_JRST    10
3. CMD_JTAG_RUN_TEST                    0
4. CMD_JTAG_LOAD_IR    `JTAG_DR_CFGI    10
5. CMD_JTAG_IDLE_DELAY                  75000
6. CMD_JTAG_LOAD_DR    "BITSTREAM"      取决于比特流大小
7. CMD_JTAG_CLOSE_TEST                  0
8. CMD_JTAG_RUN_TEST                    0
9. CMD_JTAG_LOAD_IR    `JTAG_DR_JWAKEUP 10
A. CMD_JTAG_IDLE_DELAY                  1000
B. CMD_JTAG_CLOSE_TEST                  0
*/

reg [4:0] cmd_store_st;
always @(posedge clk) begin
    if(rst) cmd_store_st <= 0;
    else if(cmd_ready && cmd_valid) cmd_store_st <= cmd_store_st + 1;
    else cmd_store_st <= cmd_store_st;
end

assign cmd_ready = (rst == 0) && (cmd_store_st <= 4'hB);
always @(*) begin
    case (cmd_store_st)
        4'h0:    begin cmd <= `CMD_JTAG_CLOSE_TEST; cycle_num <= 0;     end
        4'h1:    begin cmd <= `CMD_JTAG_RUN_TEST  ; cycle_num <= 0;     end
        4'h2:    begin cmd <= `CMD_JTAG_LOAD_IR   ; cycle_num <= 10;    end
        4'h3:    begin cmd <= `CMD_JTAG_RUN_TEST  ; cycle_num <= 0;     end
        4'h4:    begin cmd <= `CMD_JTAG_LOAD_IR   ; cycle_num <= 10;    end
        4'h5:    begin cmd <= `CMD_JTAG_IDLE_DELAY; cycle_num <= 75000; end
        4'h6:    begin cmd <= `CMD_JTAG_LOAD_DR   ; cycle_num <= 10;    end
        4'h7:    begin cmd <= `CMD_JTAG_CLOSE_TEST; cycle_num <= 0;     end
        4'h8:    begin cmd <= `CMD_JTAG_RUN_TEST  ; cycle_num <= 0;     end
        4'h9:    begin cmd <= `CMD_JTAG_LOAD_IR   ; cycle_num <= 10;    end
        4'hA:    begin cmd <= `CMD_JTAG_IDLE_DELAY; cycle_num <= 1000;  end
        4'hB:    begin cmd <= `CMD_JTAG_CLOSE_TEST; cycle_num <= 0;     end
        default: begin cmd <= `CMD_JTAG_CLOSE_TEST; cycle_num <= 0;     end
    endcase
end

reg [31:0] wwwww_cnt;
reg [10+10+10+10-1:0] wr_data_fifo;
wire wr_data;
reg wr_en;
assign wr_data = wr_data_fifo[0];

always @(posedge clk) begin
    if(rst) begin
        wr_en <= 0;
        wwwww_cnt <= 0;
        wr_data_fifo <= {{`JTAG_DR_JWAKEUP},{`BITSTREAM},{`JTAG_DR_CFGI},{`JTAG_DR_JRST}};
    end else if(wwwww_cnt < 10+10+10+10) begin
        wr_en <= 1;
        wwwww_cnt <= wwwww_cnt + 1;
        wr_data_fifo <= (wr_en)?(wr_data_fifo >> 1):(wr_data_fifo);
    end
    else begin
        wr_en <= 0;
        wwwww_cnt <= wwwww_cnt;
        wr_data_fifo <= wr_data_fifo;
    end
end

wire rd_en, rd_data;
assign rd_en = tap_shift;
assign shift_in_bits = rd_data;

cmd_data_fifo cmd_data_fifo_inst( //12bit addr
    .clk             (clk        ),  // sync fifo clock in
    .rst             (rst        ),  // sync fifo reset in
    
    .wr_en           (wr_en      ),  // input write enable 1 active
    .wr_data         (wr_data    ),  // input write data
    .full            (           ),  // output write full  flag 1 active
    
    .rd_en           (rd_en      ),  // input read enable
    .rd_data         (rd_data    ),  // output read data
    
    .almost_full     (           ),  // output write almost full
    .empty           (           ),  // output read empty
    
    .almost_empty    (           )   // output write almost empty
);

endmodule