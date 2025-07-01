module Analazer(
    input  wire clk,
    input  wire rstn,
    input  wire [7:0] digital_in, // 输入数字信号

);

// inports wire
wire        trig;       // 触发信号，##高电平##触发
wire [11:0] wave_addr;  // 读存储地址
// outports wire
wire       busy;
wire       done;
wire [7:0] wave_out;

// outports wire
wire [7:0] multi_trig;
wire trig;
wire [5:0] op0, op1, op2, op3, op4, op5, op6, op7;
wire [1:0] global_trig_mode;

Basic_trigger#((1)) u_Basic_trigger0(clk, digital_in[0], op0, 0, multi_trig[0]);
Basic_trigger#((1)) u_Basic_trigger1(clk, digital_in[1], op1, 0, multi_trig[1]);
Basic_trigger#((1)) u_Basic_trigger2(clk, digital_in[2], op2, 0, multi_trig[2]);
Basic_trigger#((1)) u_Basic_trigger3(clk, digital_in[3], op3, 0, multi_trig[3]);
Basic_trigger#((1)) u_Basic_trigger4(clk, digital_in[4], op4, 0, multi_trig[4]);
Basic_trigger#((1)) u_Basic_trigger5(clk, digital_in[5], op5, 0, multi_trig[5]);
Basic_trigger#((1)) u_Basic_trigger6(clk, digital_in[6], op6, 0, multi_trig[6]);
Basic_trigger#((1)) u_Basic_trigger7(clk, digital_in[7], op7, 0, multi_trig[7]);

always @(*) begin
    case (global_trig_mode)
        GLOBAL_AND : trig = &multi_trig;
        GLOBAL_OR  : trig = |multi_trig;
        GLOBAL_NAND: trig = ~(&multi_trig);
        GLOBAL_NOR : trig = ~(|multi_trig);
    endcase
end

Analyzer_datastore #(
	.WAVE_ADDR_WIDTH 	(12)
)u_Analyzer_datastore(
	.clk        	( clk         ),
	.rstn       	( rstn        ),
	.digital_in 	( digital_in  ),
	.trig       	( trig        ),
	.busy       	( busy        ),
	.done       	( done        ),
	.wave_addr  	( wave_addr   ),
	.wave_out   	( wave_out    )
);


endmodule //Analazer