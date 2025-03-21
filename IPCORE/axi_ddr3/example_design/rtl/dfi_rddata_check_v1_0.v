////////////////////////////////////////////////////////////////
// Copyright (c) 2021 PANGO MICROSYSTEMS, INC
// ALL RIGHTS REVERVED.
////////////////////////////////////////////////////////////////
//Description:
//Author:
//History: v1.0
////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
module dfi_rddata_check_v1_0 #(
    parameter          DATA_PATTERN0        = 8'h55,
    parameter          DATA_PATTERN1        = 8'haa,
    parameter          DATA_PATTERN2        = 8'h7f,
    parameter          DATA_PATTERN3        = 8'h80,
    parameter          DATA_PATTERN4        = 8'h55,
    parameter          DATA_PATTERN5        = 8'haa,
    parameter          DATA_PATTERN6        = 8'h7f,
    parameter          DATA_PATTERN7        = 8'h80,
    parameter          DATA_MASK_EN         = 0,
    parameter          CTRL_ADDR_WIDTH      = 27,
    parameter          MEM_ROW_ADDR_WIDTH   = 14   ,
    parameter          MEM_COL_ADDR_WIDTH   = 10   ,
    parameter          MEM_BANKADDR_WIDTH   = 3    ,
    parameter          MEM_BANKGROUP_WIDTH  = 0    ,
    parameter          MEM_DQS_WIDTH        = 2    ,
    parameter          MEM_DM_WIDTH         = 2    ,
    parameter          MEM_DQ_WIDTH         = 16
)(
   input                                clk                ,
   input                                rst_n              ,
   input                                cmd_rd_start       ,
   output                               read_finished      ,

   input                                pattern_en         ,
   input                                random_data_en     ,
   input                                stress_test        ,
   input                                write_to_read      ,
   input                                read_repeat_en     ,
   input                                data_order         ,
   input [7:0]                          dq_inversion       ,
   input [3:0]                          read_repeat_num    ,

   input [CTRL_ADDR_WIDTH-1:0]          random_rw_addr     ,
   input [3:0]                          random_len         ,
   input  [2*4*MEM_DQ_WIDTH-1:0]        dfi_rddata         ,
   input                                dfi_rddata_valid   ,
   output reg [7:0]                     err_cnt            ,
   output reg                           err_flag_led       ,
   output reg [MEM_DQ_WIDTH*8-1:0]      err_data_out       ,
   output reg [MEM_DQ_WIDTH*8-1:0]      err_flag_out       ,
   output reg [MEM_DQ_WIDTH*8-1:0]      exp_data_out       ,
   output reg [MEM_DQS_WIDTH-1:0]       err_flag_out_group ,
   input                                manu_clear         ,
   output reg                           next_err_flag      ,
   output reg [15:0]                    result_bit_out     ,
   output reg [2:0]                     state              ,
   output reg [MEM_DQ_WIDTH*8-1:0]      next_err_data      ,
   output reg [MEM_DQ_WIDTH*8-1:0]      err_data_pre       ,
   output reg [MEM_DQ_WIDTH*8-1:0]      err_data_aft

);

localparam E_IDLE = 3'd0;
localparam E_RD   = 3'd1;
localparam E_END  = 3'd2;
localparam DQ_NUM = MEM_DQ_WIDTH/8;

reg [15:0] req_rd_cnt;
reg [15:0] execute_rd_cnt;
//wire  read_finished;

wire [15:0] rd_data_addr;
wire [9:0] rd_data_addr0;
wire [9:0] rd_data_addr1;
wire [9:0] rd_data_addr2;
wire [9:0] rd_data_addr3;
wire [9:0] rd_data_addr4;
wire [9:0] rd_data_addr5;
wire [9:0] rd_data_addr6;
wire [9:0] rd_data_addr7;
wire [7:0] rd_data_random_0;
wire [7:0] rd_data_random_1;
wire [7:0] rd_data_random_2;
wire [7:0] rd_data_random_3;
wire [7:0] rd_data_random_4;
wire [7:0] rd_data_random_5;
wire [7:0] rd_data_random_6;
wire [7:0] rd_data_random_7;
wire [7:0] rd_data_r0;
wire [7:0] rd_data_r1;
wire [7:0] rd_data_r2;
wire [7:0] rd_data_r3;
wire [7:0] rd_data_r4;
wire [7:0] rd_data_r5;
wire [7:0] rd_data_r6;
wire [7:0] rd_data_r7;
wire [7:0] rd_data_0;
wire [7:0] rd_data_1;
wire [7:0] rd_data_2;
wire [7:0] rd_data_3;
wire [7:0] rd_data_4;
wire [7:0] rd_data_5;
wire [7:0] rd_data_6;
wire [7:0] rd_data_7;
wire [MEM_DQ_WIDTH*8-1:0] rddata_exp_pre;
wire [MEM_DQ_WIDTH*8-1:0] rddata_exp;
reg  [MEM_DQ_WIDTH*8-1:0]  rddata_exp_reorder;

reg [MEM_DQ_WIDTH*8-1:0] rddata_exp_d1;
reg [MEM_DQ_WIDTH*8-1:0] rddata_exp_d2;

reg [MEM_DQ_WIDTH*8-1:0] data_err ;
reg err;
reg [MEM_DQ_WIDTH*8-1:0] rddata_mask   /* synthesis syn_preserve = 1 */;
reg [MEM_DQ_WIDTH*8-1:0] rddata_mask_d1;
wire [15:0]  prbs_din;
wire [63:0]  prbs_dout;
wire         prbs_en;
reg          prbs_din_en;

reg         dfi_rddata_valid_d1;
reg         dfi_rddata_valid_d2;
reg [CTRL_ADDR_WIDTH-1:0] normal_rd_addr;
reg [3:0] cnt_len;
reg [3:0] rd_cnt;
reg [MEM_DQ_WIDTH*8-1:0]      dfi_rdata_d1 ;
reg [MEM_DQ_WIDTH*8-1:0]      dfi_rdata_d2 ;
reg [MEM_DQ_WIDTH*8-1:0]      dfi_rdata_d3 ;
reg manu_clear_d1,manu_clear_d2;
reg read_finished_d0;
reg read_finished_d1;
wire read_finished_pos;
reg [3:0] result_cnt;
reg result_bit_lock;
wire [7:0] rd_data_mask;

wire [MEM_DQ_WIDTH-1:0] err_flag_out_bit;
wire [MEM_DQ_WIDTH-1:0] err_flag_out_dq;

always @(posedge clk or negedge rst_n)
begin
   if (!rst_n)
   state <= E_IDLE;
   else begin
   	case(state)
   		E_IDLE:begin
   			if(cmd_rd_start)
   			state <= E_RD;
   		end
   		E_RD:begin
   			if(read_finished)
   			state <= E_END;
   		end
   		E_END:begin
   			state <= E_IDLE;
   		end
   		default: begin
   			state <= E_IDLE;
   		end
  endcase
  end
end

always @(posedge clk or negedge rst_n)
begin
   if (!rst_n) begin
   	  req_rd_cnt     <= 16'd0;
   	  execute_rd_cnt <= 16'd0;
   end
   else begin
   	  if ((state == E_IDLE) & cmd_rd_start) begin
   	  	 req_rd_cnt <= req_rd_cnt + {12'd0,random_len} + 1;
   	  end
   	  if (dfi_rddata_valid) begin
   	     execute_rd_cnt <= execute_rd_cnt + 1;
   	  end
   end
end
assign  read_finished = (req_rd_cnt == execute_rd_cnt);

always @(posedge clk or negedge rst_n)
begin
	if(~rst_n)
	normal_rd_addr <= {CTRL_ADDR_WIDTH{1'b0}};
	else if((state == E_IDLE) & cmd_rd_start)
	normal_rd_addr <= random_rw_addr;
	else if(dfi_rddata_valid)
	normal_rd_addr[MEM_COL_ADDR_WIDTH-1:0] <= normal_rd_addr[MEM_COL_ADDR_WIDTH-1:0] + 8;
end

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        dfi_rddata_valid_d1 <= 1'b0;
        dfi_rddata_valid_d2 <= 1'b0;
    end
    else
    begin
        dfi_rddata_valid_d1 <= dfi_rddata_valid;
        dfi_rddata_valid_d2 <= dfi_rddata_valid_d1;
    end
end

assign rd_data_addr = normal_rd_addr[15:0];

assign rd_data_random_0 = random_data_en ?  prbs_dout[7:0]   : prbs_dout[7:0] + 8'd0;
assign rd_data_random_1 = random_data_en ?  prbs_dout[15:8]  : prbs_dout[7:0] + 8'd1;
assign rd_data_random_2 = random_data_en ?  prbs_dout[23:16] : prbs_dout[7:0] + 8'd2;
assign rd_data_random_3 = random_data_en ?  prbs_dout[31:24] : prbs_dout[7:0] + 8'd3;
assign rd_data_random_4 = random_data_en ?  prbs_dout[39:32] : prbs_dout[7:0] + 8'd4;
assign rd_data_random_5 = random_data_en ?  prbs_dout[47:40] : prbs_dout[7:0] + 8'd5;
assign rd_data_random_6 = random_data_en ?  prbs_dout[55:48] : prbs_dout[7:0] + 8'd6;
assign rd_data_random_7 = random_data_en ?  prbs_dout[63:56] : prbs_dout[7:0] + 8'd7;

assign rd_data_r0 = pattern_en ? DATA_PATTERN0 : stress_test ? rd_data_random_0 : rd_data_random_0 ;
assign rd_data_r1 = pattern_en ? DATA_PATTERN1 : stress_test ? rd_data_random_0 : rd_data_random_1 ;
assign rd_data_r2 = pattern_en ? DATA_PATTERN2 : stress_test ? rd_data_random_0 : rd_data_random_2 ;
assign rd_data_r3 = pattern_en ? DATA_PATTERN3 : stress_test ? rd_data_random_0 : rd_data_random_3 ;
assign rd_data_r4 = pattern_en ? DATA_PATTERN4 : stress_test ? rd_data_random_0 : rd_data_random_4 ;
assign rd_data_r5 = pattern_en ? DATA_PATTERN5 : stress_test ? rd_data_random_0 : rd_data_random_5 ;
assign rd_data_r6 = pattern_en ? DATA_PATTERN6 : stress_test ? rd_data_random_0 : rd_data_random_6 ;
assign rd_data_r7 = pattern_en ? DATA_PATTERN7 : stress_test ? rd_data_random_0 : rd_data_random_7 ;

assign rd_data_0 = dq_inversion[0] ? (~rd_data_r0) : rd_data_r0;
assign rd_data_1 = dq_inversion[1] ? (~rd_data_r1) : rd_data_r1;
assign rd_data_2 = dq_inversion[2] ? (~rd_data_r2) : rd_data_r2;
assign rd_data_3 = dq_inversion[3] ? (~rd_data_r3) : rd_data_r3;
assign rd_data_4 = dq_inversion[4] ? (~rd_data_r4) : rd_data_r4;
assign rd_data_5 = dq_inversion[5] ? (~rd_data_r5) : rd_data_r5;
assign rd_data_6 = dq_inversion[6] ? (~rd_data_r6) : rd_data_r6;
assign rd_data_7 = dq_inversion[7] ? (~rd_data_r7) : rd_data_r7;

assign rddata_exp_pre = {{DQ_NUM{rd_data_7}},{DQ_NUM{rd_data_6}},{DQ_NUM{rd_data_5}},{DQ_NUM{rd_data_4}},{DQ_NUM{rd_data_3}},{DQ_NUM{rd_data_2}},{DQ_NUM{rd_data_1}},{DQ_NUM{rd_data_0}}};

assign rddata_exp = (stress_test | data_order) ?  rddata_exp_reorder : rddata_exp_pre  ;

integer i,j,k;
always @(*) begin
      for (i=0; i<8; i=i+1)
         for (j=0; j<DQ_NUM; j=j+1)
             for (k=0; k<8; k=k+1)
               rddata_exp_reorder[i*8*DQ_NUM+j*8+k] = rddata_exp_pre[k*8*DQ_NUM+j*8+i];
end

assign prbs_din = rd_data_addr;
assign prbs_en = (write_to_read == 0) ? 0 : dfi_rddata_valid;

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
	prbs_din_en <= 0;
	else if(write_to_read == 0)
	prbs_din_en <= 1;
	else begin
		if(read_repeat_en==0)
		prbs_din_en <= 0;
		else if((state == E_IDLE) & cmd_rd_start)
		prbs_din_en <= 1;
	  else if(dfi_rddata_valid)
	  prbs_din_en <= 0;
  end
end

prbs15_64bit_v1_0 #(
 .PRBS_INIT (16'h0)
)
u_prbs15_64bit
(
 .clk            (clk    ),
 .rst_n          (rst_n  ),
 .prbs_en        (prbs_en ),
 .din_en         (prbs_din_en),
 .din            (prbs_din),
 .dout           (prbs_dout)
);

assign rd_data_mask = (DATA_MASK_EN == 1) ? prbs_dout[7:0] : 8'hff;
always @(posedge clk or negedge rst_n)
begin
	if(~rst_n)
  dfi_rdata_d1  <= {MEM_DQ_WIDTH{8'h0}} ;
  else if(dfi_rddata_valid)
  dfi_rdata_d1 <= dfi_rddata;
  else
  dfi_rdata_d1 <=  dfi_rdata_d1 ;
end

always @(posedge clk or negedge rst_n)
begin
	if(~rst_n)
  dfi_rdata_d2  <= {MEM_DQ_WIDTH{8'h0}} ;
  else
  dfi_rdata_d2 <= dfi_rdata_d1;
end

always @(posedge clk or negedge rst_n)
begin
	if(~rst_n)
  dfi_rdata_d3  <= {MEM_DQ_WIDTH{8'h0}} ;
  else
  dfi_rdata_d3 <= dfi_rdata_d2;
end

always @(posedge clk or negedge rst_n)
begin
	if(~rst_n)
  rddata_exp_d1  <= {MEM_DQ_WIDTH{8'h0}} ;
  else if( dfi_rddata_valid )
  rddata_exp_d1 <= rddata_exp;
  else
  rddata_exp_d1 <=  rddata_exp_d1;
end

always @(posedge clk or negedge rst_n)
begin
	if(~rst_n)
  rddata_exp_d2  <= {MEM_DQ_WIDTH{8'h0}} ;
  else
  rddata_exp_d2 <= rddata_exp_d1;
end

always @(posedge clk or negedge rst_n)
begin
	if(~rst_n)
  rddata_mask  <= {MEM_DQ_WIDTH{8'h0}} ;
  else if( dfi_rddata_valid )
  rddata_mask <= {{(DQ_NUM*8){rd_data_mask[7]}},{(DQ_NUM*8){rd_data_mask[6]}},{(DQ_NUM*8){rd_data_mask[5]}},{(DQ_NUM*8){rd_data_mask[4]}},
                  {(DQ_NUM*8){rd_data_mask[3]}},{(DQ_NUM*8){rd_data_mask[2]}},{(DQ_NUM*8){rd_data_mask[1]}},{(DQ_NUM*8){rd_data_mask[0]}}};  //0:mask
  else
  rddata_mask <=  rddata_mask;
end

always @(posedge clk or negedge rst_n)
begin
	if(~rst_n)
  rddata_mask_d1  <= {MEM_DQ_WIDTH{8'h0}} ;
  else
  rddata_mask_d1 <= rddata_mask;
end

always @(posedge clk or negedge rst_n)
begin
	if(~rst_n)
	data_err <= {MEM_DQ_WIDTH{8'h0}};
	else
	data_err <= (dfi_rdata_d1 ^ rddata_exp_d1) & rddata_mask;
end

always @(posedge clk or negedge rst_n)
begin
	if(~rst_n)
	err <= 0;
	else
	err <= |((dfi_rdata_d1 ^ rddata_exp_d1) & rddata_mask);
end


always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        err_cnt <= 8'b0;
        err_flag_led <= 1'b0;
    end
    else if(manu_clear_d2)
    begin
        err_cnt <= 8'b0;
        err_flag_led <= 1'b0;
    end
    else if(err && dfi_rddata_valid_d2)
    begin
        if(err_cnt == 8'hff)
            err_cnt <= err_cnt;
        else
        err_cnt <= err_cnt + 8'b1;
        err_flag_led <= 1'b1;
    end
end

always @(posedge clk or negedge rst_n)
begin
	if(~rst_n)begin
		read_finished_d0 <= 0;
		read_finished_d1 <= 0;
	end
	else begin
		read_finished_d0 <= read_finished;
		read_finished_d1 <= read_finished_d0;
	end
end
assign read_finished_pos = read_finished_d0 & ~read_finished_d1;

always @(posedge clk or negedge rst_n)
begin
	if(~rst_n)
	result_cnt <= 4'd0;
	else if(read_repeat_en) begin
		if(read_finished_pos)begin
			if(result_cnt==read_repeat_num)
			result_cnt <= 4'd0;
			else
			result_cnt <= result_cnt + 4'd1;
		end
	end
	else
	result_cnt <= 4'd0;
end

always @(posedge clk or negedge rst_n)
begin
	if(~rst_n)
	result_bit_lock <= 0;
	else if(manu_clear_d2)
	result_bit_lock <= 0;
	else if(read_repeat_en) begin
		if(read_finished_pos & (result_cnt==read_repeat_num) & err_flag_led)
		result_bit_lock <= 1;
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(~rst_n)
	result_bit_out <= 16'h0;
	else if(manu_clear_d2)
	result_bit_out <= 16'h0;
	else if(err & dfi_rddata_valid_d2 & ~result_bit_lock)
	begin
		for(i=0;i<16;i=i+1)
		if(i == result_cnt)
		result_bit_out[i] <= 1;
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(~rst_n)begin
		manu_clear_d2 <= 0;
		manu_clear_d1 <= 0;
	end
	else begin
		manu_clear_d2 <= manu_clear_d1;
		manu_clear_d1 <= manu_clear;
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(~rst_n)begin
		err_data_out <= {MEM_DQ_WIDTH{8'h0}} ;
		err_flag_out <= {MEM_DQ_WIDTH{8'h0}} ;
		exp_data_out <= {MEM_DQ_WIDTH{8'h0}} ;
	end
	else if(err & dfi_rddata_valid_d2 & ~err_flag_led)begin
		err_data_out <= dfi_rdata_d2;
	  err_flag_out <= data_err;
	  exp_data_out <= rddata_exp_d2 & rddata_mask_d1;
	end
end

genvar m;
generate
begin
  for(m=0; m<MEM_DQ_WIDTH; m=m+1)

    assign err_flag_out_bit[m] = |(data_err[8*m+7:8*m]);

end
endgenerate

genvar p,q;
generate
begin
  for(p=0; p<MEM_DQS_WIDTH; p=p+1)
    for(q=0; q<8; q=q+1)
      assign err_flag_out_dq[8*p+q] = err_flag_out_bit[q*MEM_DQS_WIDTH+p];
end
endgenerate

genvar n;
generate
begin
  for(n=0; n<MEM_DQS_WIDTH; n=n+1)
    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            err_flag_out_group[n] <= 1'b0;
        else if(manu_clear_d2)
            err_flag_out_group[n] <= 1'b0;
        else if((|(err_flag_out_dq[8*n+7:8*n])) && dfi_rddata_valid_d2)
            err_flag_out_group[n] <= 1'b1;
    end
end
endgenerate

always @(posedge clk or negedge rst_n)
begin
	if(~rst_n)
	err_data_pre <= {MEM_DQ_WIDTH{8'h0}};
	else if(err_flag_led == 0)
	err_data_pre <= dfi_rdata_d3;
end

always @(posedge clk or negedge rst_n)
begin
	if(~rst_n)
	err_data_aft <= {MEM_DQ_WIDTH{8'h0}};
	else if(err_flag_led == 0)
	err_data_aft <= dfi_rdata_d1;
end

always @(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    next_err_flag <= 1'b0;
    else if(manu_clear_d2)
    next_err_flag <= 1'b0;
    else if(err & dfi_rddata_valid_d2 & err_flag_led)
    next_err_flag <= 1'b1;
end

always @(posedge clk or negedge rst_n)
begin
	if(~rst_n)begin
		next_err_data <= {MEM_DQ_WIDTH{8'h0}} ;
	end
	else if(err & dfi_rddata_valid_d2 & err_flag_led & ~next_err_flag)begin
		next_err_data <= dfi_rdata_d2;
	end
end

endmodule
