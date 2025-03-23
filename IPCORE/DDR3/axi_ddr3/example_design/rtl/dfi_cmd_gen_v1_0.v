////////////////////////////////////////////////////////////////
// Copyright (c) 2021 PANGO MICROSYSTEMS, INC
// ALL RIGHTS REVERVED.
////////////////////////////////////////////////////////////////
//Description:
//Author:  
//History: v1.0
////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
module dfi_cmd_gen_v1_0 #(
    parameter          TRFC                 = 16,      //tRFC/4 + 1
    parameter          TRCD                 = 2 ,      //tRCD/4 + 1
    parameter          TREFI                = 580,     //tREFI/4 + 1
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
    parameter          TOTAL_ADDR_WIDTH     = 16   ,
    parameter          MEM_BANKADDR_WIDTH   = 3    ,
    parameter          MEM_BANKGROUP_WIDTH  = 0    ,
    parameter          MEM_DQS_WIDTH        = 2    ,
    parameter          MEM_DM_WIDTH         = 2    ,
    parameter          MEM_DQ_WIDTH         = 16   ,
    parameter          GATE_ACT_PRE_EN      = 1 ,
    parameter          MEM_SPACE_AW         = 18
)(
   input                                   clk                ,
   input                                   rst_n              , 
   input [5:0]                             mc_wl              ,  
   input                                   init_start         ,
   input                                   write_en           ,
   input                                   read_en            ,
   input                                   insert_err         ,
   output reg                              write_done_p       ,
   output reg                              read_done_p        ,
   input                                   read_finished      ,
   output reg                              init_done          ,
                                           
   input                                   pattern_en         ,
   input                                   random_data_en     ,
   input                                   stress_test        ,
   input                                   write_to_read      ,
   input                                   read_repeat_en     ,
   input                                   data_order         ,
   input [7:0]                             dq_inversion       ,
   input [3:0]                             read_repeat_num    ,
                                           
   input [CTRL_ADDR_WIDTH-1:0]             random_rw_addr     ,     
   input [3:0]                             random_len         ,
   input                                   dfi_phyupd_req     ,
   output  reg                             dfi_phyupd_ack     ,
   input                                   ddrphy_update_done ,
   output reg [2:0]                        state              ,
   output reg                              cmd_rd_start       ,
   
   output wire                             dfi_reset_n     ,    
   output reg [4*TOTAL_ADDR_WIDTH-1:0]     dfi_address     ,
   output reg [4*MEM_BANKADDR_WIDTH-1:0]    dfi_bank        ,
   output reg [4-1:0]                      dfi_cs_n        ,
   `ifdef IPS2T_DDR4                             
   output reg [4*MEM_BANKGROUP_WIDTH-1:0]    dfi_bg          , 
   output reg [4-1:0]                      dfi_act_n       ,
   `else                                   
   output reg [4-1:0]                      dfi_ras_n       ,
   output reg [4-1:0]                      dfi_cas_n       ,
   output reg [4-1:0]                      dfi_we_n        ,
   `endif                                  
   output reg [4-1:0]                      dfi_cke         ,
   output reg [4-1:0]                      dfi_odt         ,
   output [2*4*MEM_DQ_WIDTH-1:0]           dfi_wrdata      ,
   output [4-1:0]                          dfi_wrdata_en   ,
   output [2*4*MEM_DQ_WIDTH/8-1:0]         dfi_wrdata_mask 
   `ifdef IPS2T_DDR4
   ,
   output [MEM_BANKADDR_WIDTH-1:0]         upd_act_ba      ,
   output [MEM_BANKGROUP_WIDTH-1:0]        upd_act_bg 
   `endif
);
  localparam DQ_NUM = MEM_DQ_WIDTH/8;

  localparam [CTRL_ADDR_WIDTH:0] ADDR_MAX = (1'b1<<MEM_SPACE_AW);
  
  localparam E_IDLE = 3'd0;
  localparam E_WR   = 3'd1;
  localparam E_RD   = 3'd2;
  localparam E_END  = 3'd3;

  function integer clogb2 (input integer size);                    
     begin                                                         
     //  size = size - 1;                                            
     // increment clogb2 from 1 for each bit in size               
     for (clogb2 = 1; size > 1; clogb2 = clogb2 + 1)               
       size = size >> 1;                                           
     end                                                           
   endfunction // clogb2 

  localparam CMD_IDLE           = 4'd0;
  localparam CMD_ACT            = 4'd1;
  localparam CMD_WR             = 4'd2;
  localparam CMD_RD             = 4'd3;
  localparam CMD_REFRESH        = 4'd4;
  localparam CMD_WR2PRE         = 4'd5;
  localparam CMD_PREALL         = 4'd6;
  
  localparam TREFI_WIDTH = clogb2(TREFI);
  localparam TRFC_WIDTH = clogb2(TRFC);
  
reg [3:0] cmd_gen_state;
reg [3:0] wr_cnt;
reg [3:0] rd_cnt;
reg [3:0] req_wr_cnt;
reg [3:0] ref_cnt;
reg read_finished_d1;
reg read_finished_d2;
wire read_finished_pos;
reg wr_finished;
wire state_wr_en;
wire state_rd_en;
wire cmd_wr_en;
wire cmd_rd_en;
wire cmd_prea;
wire cmd_idle;
wire cmd_act;
wire [TREFI_WIDTH+2:0] cnt_trefi_max;
reg [TREFI_WIDTH+2:0] cnt_trefi;
reg ref_time_out;
reg [7:0] cmd_cnt;
reg [CTRL_ADDR_WIDTH:0] init_addr;
reg [CTRL_ADDR_WIDTH-1:0] cmd_wr_addr;
reg [CTRL_ADDR_WIDTH-1:0] normal_wr_addr;
wire in_wr_state;
wire [15:0] wr_data_addr;
wire [MEM_BANKADDR_WIDTH-1:0] ba_addr;
wire [10:0] col_addr;
wire [MEM_ROW_ADDR_WIDTH-1:0] row_addr;
`ifdef IPS2T_DDR4
wire [MEM_BANKGROUP_WIDTH-1:0] bg_addr;
`endif
reg [10:0] wr_dly;
reg wr_enable;
reg wr_enable_d1;
reg wr_enable_d2;
wire [3:0] bus_wr_enable;
wire [3:0] bus_wr_enable_d;
reg [3:0] bist_wrdata_en;
reg [8*MEM_DQ_WIDTH-1:0] bus_wr_data;
reg [8*MEM_DQ_WIDTH-1:0] bus_wr_data_d;
reg [8*MEM_DQ_WIDTH-1:0] bist_wrdata;
reg [TOTAL_ADDR_WIDTH-1:0]     bist_address    ;
reg [MEM_BANKADDR_WIDTH-1:0]   bist_ba         ;
reg                            bist_cs_n       ;
`ifdef IPS2T_DDR4
reg [MEM_BANKGROUP_WIDTH-1:0]  bist_bg         ;
reg                            bist_act_n      ;
`else
reg                            bist_ras_n      ;
reg                            bist_cas_n      ;
reg                            bist_we_n       ;
`endif
reg                            bist_cke        ;
reg                            bist_odt        ;

reg [TOTAL_ADDR_WIDTH-1:0]     bist_address_d  ;
reg [MEM_BANKADDR_WIDTH-1:0]   bist_ba_d       ;
reg                            bist_cs_n_d     ;
`ifdef IPS2T_DDR4
reg [MEM_BANKGROUP_WIDTH-1:0]  bist_bg_d       ;
reg                            bist_act_n_d    ;
`else
reg                            bist_ras_n_d    ;
reg                            bist_cas_n_d    ;
reg                            bist_we_n_d     ;
`endif
reg                            bist_cke_d      ;
reg                            bist_odt_d      ;

reg [8*MEM_DQ_WIDTH-1:0]    wrdata_reorder;
wire[8*MEM_DQ_WIDTH-1:0]    wrdata_pre;

wire[7:0]   wr_data_random_0;
wire[7:0]   wr_data_random_1;
wire[7:0]   wr_data_random_2;
wire[7:0]   wr_data_random_3;
wire[7:0]   wr_data_random_4;
wire[7:0]   wr_data_random_5;
wire[7:0]   wr_data_random_6;
wire[7:0]   wr_data_random_7;

wire [9:0] wr_data_addr0;
wire [9:0] wr_data_addr1;
wire [9:0] wr_data_addr2;
wire [9:0] wr_data_addr3;
wire [9:0] wr_data_addr4;
wire [9:0] wr_data_addr5;
wire [9:0] wr_data_addr6;
wire [9:0] wr_data_addr7;

wire [7:0]   wr_data_r0;
wire [7:0]   wr_data_r1;
wire [7:0]   wr_data_r2;
wire [7:0]   wr_data_r3;
wire [7:0]   wr_data_r4;
wire [7:0]   wr_data_r5;
wire [7:0]   wr_data_r6;
wire [7:0]   wr_data_r7;

wire [7:0]   wr_data_0;
wire [7:0]   wr_data_1;
wire [7:0]   wr_data_2;
wire [7:0]   wr_data_3;
wire [7:0]   wr_data_4;
wire [7:0]   wr_data_5;
wire [7:0]   wr_data_6;
wire [7:0]   wr_data_7;

wire [7:0]   wr_data_mask;
wire [15:0]  prbs_din;
wire [63:0]  prbs_dout;
wire         prbs_en;
reg          prbs_din_en;        

wire [8*MEM_DQ_WIDTH-1:0]       wrdata_ch ;
reg insert_err_d1,insert_err_d2;
wire insert_err_pos;
reg insert_err_valid;
reg cmd_wr_start;

always @(posedge clk or negedge rst_n)
begin
   if (!rst_n)
   state  <= E_IDLE;
   else begin      
    case (state)
      E_IDLE: begin
        if(!dfi_phyupd_req)begin
        	if(init_start)
        	state <= E_WR;
        	else if(write_en)
          state <= E_WR;
          else if(read_en)
          state <= E_RD;
        end
       end
      E_WR: begin
      	if(cmd_prea)
      	state <= E_END;
      end
      E_RD: begin    
      	if(cmd_prea)
        state <= E_END;
      end
      E_END: begin
        if (wr_finished)
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
   if (!rst_n)
   cmd_rd_start <= 0;
   else if(state == E_IDLE)begin
   	if((!dfi_phyupd_req)&(read_en))
   	cmd_rd_start <= 1;
   	else
   	cmd_rd_start <= 0;
   end
   else 
   cmd_rd_start <= 0;
end   

always @(posedge clk or negedge rst_n)
begin
   if (!rst_n)
   cmd_wr_start <= 0;
   else if(state == E_IDLE)begin
   	if((!dfi_phyupd_req)&(write_en))
   	cmd_wr_start <= 1;
   	else
   	cmd_wr_start <= 0;
   end
   else 
   cmd_wr_start <= 0;
end  

always @(posedge clk or negedge rst_n)
begin
   if (!rst_n)begin
   	read_finished_d1 <= 0;
   	read_finished_d2 <= 0;
   end
   else begin
   	read_finished_d1 <= read_finished;
   	read_finished_d2 <= read_finished_d1;
  end
end 
assign read_finished_pos = ~read_finished_d2 & read_finished_d1;
  
always @(posedge clk or negedge rst_n)
begin
   if (!rst_n)
   wr_finished <= 0;
   else if(state == E_IDLE)
   wr_finished <= 0;
   else if(write_done_p | read_finished_pos)
   wr_finished <= 1;
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
	dfi_phyupd_ack <= 1'b0 ;
  else if(ddrphy_update_done)
  dfi_phyupd_ack <= 1'b0 ;
  else if(dfi_phyupd_req & cmd_idle)
  dfi_phyupd_ack <= 1'b1 ;
end

assign state_wr_en = state == E_WR;
assign state_rd_en = state == E_RD;
assign cmd_prea  = (cmd_gen_state == CMD_PREALL) & cmd_cnt[4];
assign cmd_idle  = cmd_gen_state == CMD_IDLE;
assign cmd_act   = cmd_gen_state == CMD_ACT;
//assign cmd_prea  = (cmd_gen_state == CMD_PREALL) & cmd_cnt[4];

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
  cmd_gen_state <= CMD_IDLE;
  else begin
  	case(cmd_gen_state)
  		CMD_IDLE:begin 		
  			if(!dfi_phyupd_req)begin  				
  			  if((ref_time_out))
  			  cmd_gen_state <= CMD_REFRESH;
  			  else if(state_wr_en | state_rd_en)
  			  cmd_gen_state <= CMD_ACT; 
  		  end			
  		end
  		CMD_ACT:begin
  			if(cmd_cnt == TRCD)begin
  				if(state_wr_en)
  				cmd_gen_state <= CMD_WR;
  				else if(state_rd_en)
  				cmd_gen_state <= CMD_RD;
  			end
  		end
  		CMD_WR:begin
  			if(wr_cnt == req_wr_cnt)
  			cmd_gen_state <= CMD_WR2PRE; 
  		end
  		CMD_RD:begin
  			if(wr_cnt == req_wr_cnt)
  			cmd_gen_state <= CMD_WR2PRE;
  		end  		   		
  		CMD_REFRESH:begin
  			if(ref_cnt == 4'd8)
  			cmd_gen_state <= CMD_IDLE;
  		end
  		CMD_WR2PRE:begin
  			if(cmd_cnt[4])
  			cmd_gen_state <= CMD_PREALL;
  		end
  		CMD_PREALL:begin
  			if(cmd_cnt[4])
  			cmd_gen_state <= CMD_IDLE;
  		end 		
  		default:
  		cmd_gen_state <= CMD_IDLE;
  endcase   	
  end
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
	cmd_cnt <= 8'd0;
	else begin
		  case(cmd_gen_state)
  		CMD_IDLE:begin
  			cmd_cnt <= 8'd0; 			
  		end
  		CMD_ACT:begin
  			if(cmd_cnt == TRCD)
  			cmd_cnt <= 8'd0;
  			else
  			cmd_cnt <= cmd_cnt + 8'd1;
  		end
  		CMD_WR:begin
  			if(wr_cnt == req_wr_cnt)
  			cmd_cnt <= 8'd0;
  			else
  			cmd_cnt <= cmd_cnt + 8'd1;
  		end
  		CMD_RD:begin
  			if(wr_cnt == req_wr_cnt)
  			cmd_cnt <= 8'd0;
  			else
  			cmd_cnt <= cmd_cnt + 8'd1;
  		end  		   		
  		CMD_REFRESH:begin
  			if(cmd_cnt == TRFC)
  			cmd_cnt <= 8'd0;
  			else
  			cmd_cnt <= cmd_cnt + 8'd1;
  		end
  		CMD_WR2PRE:begin
  			if(cmd_cnt[4])
  			cmd_cnt <= 8'd0;
  			else
  			cmd_cnt <= cmd_cnt + 8'd1;
  		end
  		CMD_PREALL:begin
  			if(cmd_cnt[4])
  			cmd_cnt <= 8'd0;
  			else
  			cmd_cnt <= cmd_cnt + 8'd1;
  		end 		
  		default:cmd_cnt <= 8'd0;
  endcase
	end
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
	wr_cnt <= 4'd0;
	else if((cmd_gen_state == CMD_WR) || (cmd_gen_state == CMD_RD))begin
		`ifdef IPS2T_DDR4
		if(cmd_cnt[0])
		wr_cnt <= wr_cnt + 4'd1;
		`else
		wr_cnt <= wr_cnt + 4'd1;
		`endif
	end
	else
	wr_cnt <= 4'd0;
end

//****************************************************************************************************
assign cnt_trefi_max = {TREFI, 3'd0} - 128; //tREFI x 8
always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
	cnt_trefi    <= {(TREFI_WIDTH+3){1'b0}};
	else if(cmd_gen_state == CMD_REFRESH)
	cnt_trefi    <= {(TREFI_WIDTH+3){1'b0}};
	else if(cnt_trefi < cnt_trefi_max)
	cnt_trefi    <= cnt_trefi + 1;
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
	ref_time_out <= 1'b0;
	else if(cnt_trefi == cnt_trefi_max)
	ref_time_out <= 1'b1;
	else
	ref_time_out <= 1'b0;
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
  ref_cnt <= 4'd0;
  else if(cmd_gen_state == CMD_REFRESH)
  begin
  	if(cmd_cnt == TRFC)
    ref_cnt <= ref_cnt + 4'd1;
  end
  else
  ref_cnt <= 4'd0;
end
  
//****************************************************************************************************
always @(posedge clk or negedge rst_n)
begin
   if (!rst_n)
      bist_odt   <= 1'b0;
   else if (cmd_gen_state == CMD_WR)
      bist_odt   <= 1'b1;
   else if (cmd_gen_state == CMD_RD)
      bist_odt   <= 1'b0;
   else
      bist_odt   <= bist_odt;
end

  always @(posedge clk or negedge rst_n)
  begin
     if (!rst_n)
        bist_cke   <= 1'b0;
     else
        bist_cke   <= 1'b1;
  end

`ifdef IPS2T_DDR4
assign in_wr_state  = (cmd_gen_state == CMD_WR) && (cmd_cnt[0] == 1'b0);
`else
assign in_wr_state  = (cmd_gen_state == CMD_WR);
`endif

always @(posedge clk or negedge rst_n)
   if (!rst_n) begin
   	  wr_dly  <= 11'b0;
   end
   else begin
   	  wr_dly  <= {wr_dly[9:0],in_wr_state};
   end

always @(*)
begin
   	case(mc_wl[5:2])
        4'd0  :  wr_enable  = wr_dly[0];
        4'd1  :  wr_enable  = wr_dly[1];
        4'd2  :  wr_enable  = wr_dly[2];
        4'd3  :  wr_enable  = wr_dly[3];
        4'd4  :  wr_enable  = wr_dly[4];
        4'd5  :  wr_enable  = wr_dly[5];
        4'd6  :  wr_enable  = wr_dly[6];
        4'd7  :  wr_enable  = wr_dly[7];
        4'd8  :  wr_enable  = wr_dly[8];
        4'd9  :  wr_enable  = wr_dly[9];
        4'd10 :  wr_enable  = wr_dly[10];
   	    default: wr_enable  = 1'b0;
   	endcase
end

 always @(posedge clk or negedge rst_n)
 begin
    if (!rst_n) begin
         wr_enable_d1 <= 1'b0;
         wr_enable_d2 <= 1'b0;
    end
    else begin
         wr_enable_d1 <= wr_enable;
         wr_enable_d2 <= wr_enable_d1;
    end
 end

  assign bus_wr_enable   = {4{wr_enable_d1}};
  assign bus_wr_enable_d = {4{wr_enable_d2}};

  always @(posedge clk or negedge rst_n)
  begin
     if(!rst_n)
        bist_wrdata_en  <= 4'b0000;
     else begin
        case (mc_wl[1:0])
            2'b00: bist_wrdata_en <= bus_wr_enable;
            2'b01: bist_wrdata_en <= {bus_wr_enable[2:0], bus_wr_enable_d[3]};
            2'b10: bist_wrdata_en <= {bus_wr_enable[1:0], bus_wr_enable_d[3:2]};
            2'b11: bist_wrdata_en <= {bus_wr_enable[0],bus_wr_enable_d[3:1]};
            default: bist_wrdata_en <= 4'b0000;
        endcase
     end
  end

always @(posedge clk or negedge rst_n) 
begin
   if (!rst_n) begin
     init_addr <= {(CTRL_ADDR_WIDTH+1){1'b0}};
     normal_wr_addr <= {CTRL_ADDR_WIDTH{1'b0}};  
   end
   else begin
    if(init_start) begin
      if(init_addr < ADDR_MAX)begin 
        if(wr_enable)
        init_addr <= init_addr + 8;     
      end
    end
    else begin
        if(state_wr_en & cmd_act)begin 
        normal_wr_addr <= random_rw_addr;
        end
        else if(state_wr_en) begin
        if(wr_enable) begin
        normal_wr_addr[MEM_COL_ADDR_WIDTH-1:0] <= normal_wr_addr[MEM_COL_ADDR_WIDTH-1:0] + 8;
        end
        end   
    end
   end
end

always @(posedge clk or negedge rst_n) 
begin
   if (!rst_n)
   cmd_wr_addr <= {CTRL_ADDR_WIDTH{1'b0}};
   else if(init_start)
   begin
   	if((cmd_gen_state == CMD_WR) || (cmd_gen_state == CMD_RD))begin
   	`ifdef IPS2T_DDR4
		if(~cmd_cnt[0])
		cmd_wr_addr <= cmd_wr_addr + 8;
		`else
		cmd_wr_addr <= cmd_wr_addr + 8;
		`endif
    end
   end
   else begin
   	if(cmd_idle & (state_wr_en | state_rd_en))
   	cmd_wr_addr <= random_rw_addr;
   	else if((cmd_gen_state == CMD_WR) || (cmd_gen_state == CMD_RD))begin
   	`ifdef IPS2T_DDR4
		if(~cmd_cnt[0])
		cmd_wr_addr[MEM_COL_ADDR_WIDTH-1:0] <= cmd_wr_addr[MEM_COL_ADDR_WIDTH-1:0] + 8;
		`else
		cmd_wr_addr[MEM_COL_ADDR_WIDTH-1:0] <= cmd_wr_addr[MEM_COL_ADDR_WIDTH-1:0] + 8;
		`endif
    end
   end
end

`ifdef IPS2T_DDR4
assign bg_addr = cmd_wr_addr[MEM_BANKADDR_WIDTH + MEM_COL_ADDR_WIDTH + MEM_BANKGROUP_WIDTH -1:MEM_BANKADDR_WIDTH + MEM_COL_ADDR_WIDTH];
`else
`endif
assign ba_addr = cmd_wr_addr[MEM_BANKADDR_WIDTH + MEM_COL_ADDR_WIDTH-1:MEM_COL_ADDR_WIDTH];
assign col_addr = {{(10-MEM_COL_ADDR_WIDTH){1'b0}},cmd_wr_addr[MEM_COL_ADDR_WIDTH-1:0]};
assign row_addr = cmd_wr_addr[CTRL_ADDR_WIDTH-1:CTRL_ADDR_WIDTH-MEM_ROW_ADDR_WIDTH];

always @(posedge clk or negedge rst_n) 
begin
   if (!rst_n)
   req_wr_cnt <= 4'd0;
   else begin
   	if(init_start)
   	req_wr_cnt <= 4'd15;
   	else if((write_en)|(read_en))
   	req_wr_cnt <= random_len;
  end
end

always @(posedge clk or negedge rst_n) 
begin
   if (!rst_n)
   write_done_p <= 0;
   else if((cmd_gen_state == CMD_WR) & (wr_cnt == req_wr_cnt))
   write_done_p <= 1;
   else
   write_done_p <= 0;
end

always @(posedge clk or negedge rst_n)
begin
   if (!rst_n)
   rd_cnt <= 4'd0;
   else if((cmd_gen_state == CMD_RD) & (wr_cnt == req_wr_cnt))
   begin
    if(read_repeat_en) begin
   	  if(rd_cnt==read_repeat_num)
      rd_cnt <= 4'd0;
      else 
      rd_cnt <= rd_cnt + 4'd1;
    end
    else 
    rd_cnt <= 4'd0;
   end
end

always @(posedge clk or negedge rst_n)
begin
   if (!rst_n)
   read_done_p <= 0;
   else if((cmd_gen_state == CMD_RD) & (wr_cnt == req_wr_cnt))
   begin
   	if(read_repeat_en) begin
   		if(rd_cnt==read_repeat_num)
   		read_done_p <= 1;
   		else
   		read_done_p <= 0;
   	end
   	else
   	read_done_p <= 1;
   end
   else
   read_done_p <= 0;
end

//always @(posedge clk or negedge rst_n) 
//begin
//   if (!rst_n)
//   read_done_p <= 0;
//   else if((read_en) & (cmd_gen_state == CMD_RD) & (wr_cnt == req_wr_cnt))
//   read_done_p <= 1;
//   else
//   read_done_p <= 0;
//end

  always @(posedge clk or negedge rst_n)
  begin
  	if(!rst_n)
    	bus_wr_data <= {MEM_DQ_WIDTH * 8{1'b0}};
    else
      bus_wr_data <= wrdata_ch;
  end

  always @(posedge clk or negedge rst_n)
  begin
  	if(!rst_n)
    	bus_wr_data_d <= {MEM_DQ_WIDTH * 8{1'b0}};
    else
      bus_wr_data_d <= bus_wr_data;
  end

  always @(posedge clk or negedge rst_n)
  begin
  	if(!rst_n)
  	bist_wrdata    <= {MEM_DQ_WIDTH * 8{1'b0}};
  	else begin
      case (mc_wl[1:0])
          2'b00: bist_wrdata    <= bus_wr_data;
          2'b01: bist_wrdata    <= {bus_wr_data[MEM_DQ_WIDTH * 8*3/4-1 : 0], bus_wr_data_d[MEM_DQ_WIDTH * 8-1: MEM_DQ_WIDTH * 8*3/4]};
          2'b10: bist_wrdata    <= {bus_wr_data[MEM_DQ_WIDTH * 8*2/4-1 : 0], bus_wr_data_d[MEM_DQ_WIDTH * 8-1: MEM_DQ_WIDTH * 8*2/4]};
          2'b11: bist_wrdata    <= {bus_wr_data[MEM_DQ_WIDTH * 8*1/4-1 : 0], bus_wr_data_d[MEM_DQ_WIDTH * 8-1: MEM_DQ_WIDTH * 8*1/4]};
          default: bist_wrdata    <= {MEM_DQ_WIDTH * 8{1'b0}};
      endcase
    end
  end
  

//****************************************************************************************************
  always @(posedge clk or negedge rst_n)
  begin
     if (!rst_n) begin
        bist_cs_n       <= 1'b1;
        bist_address    <= {TOTAL_ADDR_WIDTH{1'b1}};
        bist_ba         <= {MEM_BANKADDR_WIDTH{1'b0}};
        `ifdef IPS2T_DDR4
        bist_act_n      <= 1'b1;
        bist_bg         <= {MEM_BANKGROUP_WIDTH{1'b0}};
        `else
        bist_ras_n      <= 1'b1;
        bist_cas_n      <= 1'b1;
        bist_we_n       <= 1'b1;        
        `endif
     end
     else begin     	
        bist_cs_n       <= 1'b1;
        bist_address    <= {TOTAL_ADDR_WIDTH{1'b1}};
        bist_ba         <= {MEM_BANKADDR_WIDTH{1'b0}};
        `ifdef IPS2T_DDR4
        bist_act_n      <= 1'b1;
        bist_bg         <= {MEM_BANKGROUP_WIDTH{1'b0}};
        `else
        bist_ras_n      <= 1'b1;
        bist_cas_n      <= 1'b1;
        bist_we_n       <= 1'b1;        
        `endif     	
        case(cmd_gen_state)
           CMD_ACT: begin
              if (cmd_cnt == 8'd0) begin
                  bist_cs_n       <= 1'b0;
                  bist_address    <= {{(TOTAL_ADDR_WIDTH-MEM_ROW_ADDR_WIDTH){1'b0}},row_addr};
                  bist_ba         <= ba_addr;
                  `ifdef IPS2T_DDR4
                  bist_act_n      <= 1'b0;
                  bist_bg         <= bg_addr;
                  `else
                  bist_ras_n      <= 1'b0;
                  bist_cas_n      <= 1'b1;
                  bist_we_n       <= 1'b1;        
                  `endif
              end
           end
           CMD_WR: begin
           	  bist_address   <= {{(TOTAL_ADDR_WIDTH-12){1'b0}},col_addr[10],1'b0,col_addr[9:0]};
           	  bist_ba        <= ba_addr;           	  
           	  `ifdef IPS2T_DDR4
           	  bist_act_n     <= 1'b1;
           	  bist_cs_n      <= cmd_cnt[0];
           	  bist_bg        <= bg_addr;
           	  bist_address[16:14] <= {1'b1,cmd_cnt[0],cmd_cnt[0]};
           	  `else
           	  bist_cs_n      <= 1'b0;
           	  bist_ras_n     <= 1'b1;
              bist_cas_n     <= 1'b0;
              bist_we_n      <= 1'b0;
           	  `endif
           end
           CMD_RD: begin
           	  bist_address   <= {{(TOTAL_ADDR_WIDTH-12){1'b0}},col_addr[10],1'b0,col_addr[9:0]};
           	  bist_ba        <= ba_addr;           	  
           	  `ifdef IPS2T_DDR4
           	  bist_act_n     <= 1'b1;
           	  bist_cs_n      <= cmd_cnt[0];
           	  bist_bg        <= bg_addr;
           	  bist_address[16:14] <= {1'b1,cmd_cnt[0],1'b1};
           	  `else
           	  bist_cs_n      <= 1'b0;
           	  bist_ras_n     <= 1'b1;
              bist_cas_n     <= 1'b0;
              bist_we_n      <= 1'b1;
           	  `endif
           end
           CMD_PREALL: begin
              if (cmd_cnt== 8'd0) begin
                 `ifdef IPS2T_DDR4
           	     bist_act_n     <= 1'b1;
           	     bist_cs_n      <= 1'b0;
           	     bist_address[16:14] <= {1'b0,1'b1,1'b0};
           	     `else
           	     bist_cs_n      <= 1'b0;
           	     bist_ras_n     <= 1'b0;
                 bist_cas_n     <= 1'b1;
                 bist_we_n      <= 1'b0;
           	     `endif
           	     bist_address[10] <= 1'b1;
              end
           end
           CMD_REFRESH : begin //ref
           	  if (ref_cnt < 4'd8) begin
                if (cmd_cnt== 8'd0) begin           	  
           	     `ifdef IPS2T_DDR4
           	     bist_act_n     <= 1'b1;
           	     bist_cs_n      <= cmd_cnt[0];
           	     bist_address[16:14] <= {1'b0,1'b0,1'b1};
           	     `else
           	     bist_cs_n      <= 1'b0;
           	     bist_ras_n     <= 1'b0;
                 bist_cas_n     <= 1'b0;
                 bist_we_n      <= 1'b1;
           	     `endif
                end
              end
           end
           default: begin
                 bist_cs_n       <= 1'b1;
                 bist_address    <= {TOTAL_ADDR_WIDTH{1'b1}};
                 bist_ba         <= {MEM_BANKADDR_WIDTH{1'b0}};
                 `ifdef IPS2T_DDR4
                 bist_act_n      <= 1'b1;
                 bist_bg         <= {MEM_BANKGROUP_WIDTH{1'b0}};
                 `else
                 bist_ras_n      <= 1'b1;
                 bist_cas_n      <= 1'b1;
                 bist_we_n       <= 1'b1;        
                 `endif
           end
        endcase
     end
  end

  always @(posedge clk or negedge rst_n)
  begin
     if (!rst_n) begin
        bist_cs_n_d       <= 1'b1;
        bist_address_d    <= {TOTAL_ADDR_WIDTH{1'b1}};
        bist_ba_d         <= {MEM_BANKADDR_WIDTH{1'b0}};
        `ifdef IPS2T_DDR4
        bist_act_n_d      <= 1'b1;
        bist_bg_d         <= {MEM_BANKGROUP_WIDTH{1'b0}};
        `else
        bist_ras_n_d      <= 1'b1;
        bist_cas_n_d      <= 1'b1;
        bist_we_n_d       <= 1'b1;        
        `endif
        bist_cke_d        <= 1'b0;
        bist_odt_d        <= 1'b0;
     end
     else begin
     	  bist_cs_n_d       <= bist_cs_n;
        bist_address_d    <= bist_address;
        bist_ba_d         <= bist_ba;
        `ifdef IPS2T_DDR4
        bist_act_n_d      <= bist_act_n;
        bist_bg_d         <= bist_bg;
        `else
        bist_ras_n_d      <= bist_ras_n;
        bist_cas_n_d      <= bist_cas_n;
        bist_we_n_d       <= bist_we_n;        
        `endif
        bist_cke_d        <= bist_cke;
        bist_odt_d        <= bist_odt & (~dfi_phyupd_ack);
     end
  end

  always @(posedge clk or negedge rst_n)
  begin
     if (!rst_n) begin
        dfi_cs_n       <= {4{1'b1}};
        dfi_address    <= {4*TOTAL_ADDR_WIDTH{1'b1}};
        dfi_bank       <= {4*MEM_BANKADDR_WIDTH{1'b0}};
        `ifdef IPS2T_DDR4
        dfi_act_n      <= {4{1'b1}};
        dfi_bg         <= {4*MEM_BANKGROUP_WIDTH{1'b0}};
        `else
        dfi_ras_n      <= {4{1'b1}};
        dfi_cas_n      <= {4{1'b1}};
        dfi_we_n       <= {4{1'b1}};        
        `endif
        dfi_cke        <= {4{1'b0}};
        dfi_odt        <= {4{1'b0}};
     end 
     else begin
     	  dfi_cs_n       <= {3'b111,bist_cs_n_d};
        dfi_address    <= {{3*TOTAL_ADDR_WIDTH{1'b1}},bist_address_d};
        dfi_bank       <= {{3*MEM_BANKADDR_WIDTH{1'b0}},bist_ba_d};
        `ifdef IPS2T_DDR4
        dfi_act_n      <= {3'b111,bist_act_n_d};
        dfi_bg         <= {{3*MEM_BANKGROUP_WIDTH{1'b0}},bist_bg_d};
        `else
        dfi_ras_n      <= {3'b111,bist_ras_n_d};
        dfi_cas_n      <= {3'b111,bist_cas_n_d};
        dfi_we_n       <= {3'b111,bist_we_n_d};        
        `endif
        dfi_cke        <= {4{bist_cke_d}};
        dfi_odt        <= {4{bist_odt_d}};
    end 	
  end  

assign dfi_reset_n     = 1;
assign dfi_wrdata      = bist_wrdata  ;
assign dfi_wrdata_en   = bist_wrdata_en  ;
`ifdef IPS2T_DDR4
assign dfi_wrdata_mask = {MEM_DM_WIDTH{8'hff}}; 
`else
assign dfi_wrdata_mask = {MEM_DM_WIDTH{8'h00}}; 
`endif

always @(posedge clk or negedge rst_n) 
begin
	if (!rst_n)
	init_done <= 0;
	else if((init_start==1)&&(init_addr >= ADDR_MAX))
	init_done <= 1;
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n) begin
		insert_err_d1 <= 0;
		insert_err_d2 <= 0;
	end
	else begin
		insert_err_d1 <= insert_err;
		insert_err_d2 <= insert_err_d1;
	end
end

assign insert_err_pos = insert_err_d1 & ~insert_err_d2;

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
	insert_err_valid <= 0;
	else if(insert_err_pos)
	insert_err_valid <= 1;
	else if(wr_enable)
	insert_err_valid <= 0;
end

assign wr_data_random_0 = random_data_en ? prbs_dout[7:0]   : prbs_dout[7:0] + 8'd0; 
assign wr_data_random_1 = random_data_en ? prbs_dout[15:8]  : prbs_dout[7:0] + 8'd1; 
assign wr_data_random_2 = random_data_en ? prbs_dout[23:16] : prbs_dout[7:0] + 8'd2; 
assign wr_data_random_3 = random_data_en ? prbs_dout[31:24] : prbs_dout[7:0] + 8'd3; 
assign wr_data_random_4 = random_data_en ? prbs_dout[39:32] : prbs_dout[7:0] + 8'd4; 
assign wr_data_random_5 = random_data_en ? prbs_dout[47:40] : prbs_dout[7:0] + 8'd5; 
assign wr_data_random_6 = random_data_en ? prbs_dout[55:48] : prbs_dout[7:0] + 8'd6; 
assign wr_data_random_7 = random_data_en ? prbs_dout[63:56] : prbs_dout[7:0] + 8'd7; 

assign wr_data_r0 = pattern_en ? DATA_PATTERN0 : stress_test ? wr_data_random_0 : wr_data_random_0 ;
assign wr_data_r1 = pattern_en ? DATA_PATTERN1 : stress_test ? wr_data_random_0 : wr_data_random_1 ;
assign wr_data_r2 = pattern_en ? DATA_PATTERN2 : stress_test ? wr_data_random_0 : wr_data_random_2 ;
assign wr_data_r3 = pattern_en ? DATA_PATTERN3 : stress_test ? wr_data_random_0 : wr_data_random_3 ;
assign wr_data_r4 = pattern_en ? DATA_PATTERN4 : stress_test ? wr_data_random_0 : wr_data_random_4 ;
assign wr_data_r5 = pattern_en ? DATA_PATTERN5 : stress_test ? wr_data_random_0 : wr_data_random_5 ;
assign wr_data_r6 = pattern_en ? DATA_PATTERN6 : stress_test ? wr_data_random_0 : wr_data_random_6 ;
assign wr_data_r7 = pattern_en ? DATA_PATTERN7 : stress_test ? wr_data_random_0 : wr_data_random_7 ;

assign wr_data_0 = (dq_inversion[0] ^ insert_err_valid) ? (~wr_data_r0) : wr_data_r0;
assign wr_data_1 = dq_inversion[1] ? (~wr_data_r1) : wr_data_r1;
assign wr_data_2 = dq_inversion[2] ? (~wr_data_r2) : wr_data_r2;
assign wr_data_3 = dq_inversion[3] ? (~wr_data_r3) : wr_data_r3;
assign wr_data_4 = dq_inversion[4] ? (~wr_data_r4) : wr_data_r4;
assign wr_data_5 = dq_inversion[5] ? (~wr_data_r5) : wr_data_r5;
assign wr_data_6 = dq_inversion[6] ? (~wr_data_r6) : wr_data_r6;
assign wr_data_7 = dq_inversion[7] ? (~wr_data_r7) : wr_data_r7;

assign wrdata_pre = {{DQ_NUM{wr_data_7}},{DQ_NUM{wr_data_6}},{DQ_NUM{wr_data_5}},{DQ_NUM{wr_data_4}},{DQ_NUM{wr_data_3}},{DQ_NUM{wr_data_2}},{DQ_NUM{wr_data_1}},{DQ_NUM{wr_data_0}}};

assign wrdata_ch = (stress_test | data_order) ?  wrdata_reorder : wrdata_pre  ;

integer i,j,k;
always @(*) begin
      for (i=0; i<8; i=i+1)
         for (j=0; j<DQ_NUM; j=j+1)
             for (k=0; k<8; k=k+1)        
               wrdata_reorder[i*8*DQ_NUM+j*8+k] = wrdata_pre[k*8*DQ_NUM+j*8+i];
end
assign wr_data_addr = (init_start==1) ? init_addr[15:0] : normal_wr_addr[15:0];
assign prbs_din = wr_data_addr;
assign prbs_en = (write_to_read == 0) ? 0 : wr_enable;

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
	prbs_din_en <= 0;
	else if(write_to_read == 0)
	prbs_din_en <= 1;
	else begin
		if(read_repeat_en==0)
		prbs_din_en <= 0;
		else if(cmd_wr_start)
		prbs_din_en <= 1;
	  else if(wr_enable)
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

//assign wr_data_mask = (DATA_MASK_EN == 1) ? prbs_dout[7:0] : 8'hff;
`ifdef IPS2T_DDR4
assign upd_act_ba      = {MEM_BANKADDR_WIDTH{1'b0}};
assign upd_act_bg      = {MEM_BANKGROUP_WIDTH{1'b0}};
`endif
endmodule
