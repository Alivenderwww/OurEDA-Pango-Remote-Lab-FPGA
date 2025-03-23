////////////////////////////////////////////////////////////////
// Copyright (c) 2021 PANGO MICROSYSTEMS, INC
// ALL RIGHTS REVERVED.
////////////////////////////////////////////////////////////////
//Description:
//Author:
//History: v1.0
////////////////////////////////////////////////////////////////
module apb_ctrl
(
   input                 apb_clk       ,
   input                 apb_rst_n     ,
   input                 apb_wr_en     ,
   input                 apb_cmd_en    ,
   input [7:0]           apb_wr_addr   ,
   input [15:0]          apb_wr_data   ,
   input                 apb_port      ,
   output reg            apb_sel       ,   
   output reg            apb_enable    ,
   output reg [7:0]      apb_addr      ,
   output reg            apb_write     ,
   input                 apb_ready     ,
   output reg [15:0]     apb_wdata     ,
   input [15:0]          apb_rdata     ,
   output reg            apb_1_sel     ,   
   output reg            apb_1_enable  ,
   output reg [7:0]      apb_1_addr    ,
   output reg            apb_1_write   ,
   input                 apb_1_ready   ,
   output reg [15:0]     apb_1_wdata   ,
   input [15:0]          apb_1_rdata   ,   
   output reg            apb_done      ,
   output reg [15:0]     apb_rd_data 
);

localparam APB_IDLE      = 4'd0;
localparam APB_STEUP     = 4'd1;
localparam APB_WR        = 4'd2;
localparam APB_RD        = 4'd3;
localparam APB_END       = 4'd4;

reg apb_wr_en_d1;
reg apb_wr_en_d2;
reg apb_cmd_en_d1;
reg apb_cmd_en_d2;
reg apb_cmd_en_d3;
wire apb_cmd_en_pos;
reg apb_port_d1;
reg apb_port_d2;
reg [7:0] apb_wr_addr_d1;
reg [7:0] apb_wr_addr_d2;
reg [15:0] apb_wr_data_d1;
reg [15:0] apb_wr_data_d2;
reg [7:0] apb_wr_addr_pre;
reg [15:0] apb_wr_data_pre;

reg [3:0] apb_state;
reg apb_wr_flag;
reg apb_port_sel;
wire apb_ready_sel;

assign apb_ready_sel = apb_port_sel ? apb_1_ready : apb_ready;

always @(posedge apb_clk or negedge apb_rst_n)
if (!apb_rst_n) begin
	apb_wr_en_d1 <= 0;
	apb_wr_en_d2 <= 0;
	apb_wr_addr_d1 <= 8'd0;
	apb_wr_addr_d2 <= 8'd0;
	apb_wr_data_d1 <= 16'd0;
	apb_wr_data_d2 <= 16'd0;
end
else begin
	apb_wr_en_d1 <= apb_wr_en;
	apb_wr_en_d2 <= apb_wr_en_d1;
  apb_wr_addr_d1 <= apb_wr_addr;
	apb_wr_addr_d2 <= apb_wr_addr_d1;
	apb_wr_data_d1 <= apb_wr_data;
	apb_wr_data_d2 <= apb_wr_data_d1;
end

always @(posedge apb_clk or negedge apb_rst_n)
if (!apb_rst_n) begin
	apb_cmd_en_d1 <= 0;
	apb_cmd_en_d2 <= 0;
	apb_cmd_en_d3 <= 0;
end
else begin
	apb_cmd_en_d1 <= apb_cmd_en;
	apb_cmd_en_d2 <= apb_cmd_en_d1;
	apb_cmd_en_d3 <= apb_cmd_en_d2;
end

assign apb_cmd_en_pos = ~apb_cmd_en_d3 & apb_cmd_en_d2;

always @(posedge apb_clk or negedge apb_rst_n)
if (!apb_rst_n)
apb_state <= APB_IDLE;
else begin
	case (apb_state)
		APB_IDLE:begin
			if(apb_cmd_en_pos)
			apb_state <= APB_STEUP;
		end
		APB_STEUP:begin
			if(apb_wr_flag)
			apb_state <= APB_WR;
			else
			apb_state <= APB_RD;
		end
		APB_WR:begin
			if(apb_ready_sel)
			apb_state <= APB_END;
		end
		APB_RD:begin
			if(apb_ready_sel)
			apb_state <= APB_END;			
		end
		APB_END:begin
			apb_state <= APB_IDLE;
		end
		default:
		apb_state <= APB_IDLE;
endcase
end
	
always @(posedge apb_clk or negedge apb_rst_n)
if (!apb_rst_n)
apb_wr_flag <= 0;
else if(apb_state == APB_IDLE)begin
	if(apb_cmd_en_pos)
	apb_wr_flag <= apb_wr_en_d2;
end

always @(posedge apb_clk or negedge apb_rst_n)
if (!apb_rst_n) begin
	apb_port_d1 <= 0;
	apb_port_d2 <= 0;
end
else begin
	apb_port_d1 <= apb_port;
	apb_port_d2 <= apb_port_d1;
end

always @(posedge apb_clk or negedge apb_rst_n)
if (!apb_rst_n)
apb_port_sel <= 0;
else if(apb_state == APB_IDLE)begin
	if(apb_cmd_en_pos)
	apb_port_sel <= apb_port_d2;
end

always @(posedge apb_clk or negedge apb_rst_n)
if (!apb_rst_n)begin
	apb_wr_addr_pre <= 8'd0;
	apb_wr_data_pre <= 8'd0;
end
else if(apb_state == APB_IDLE)begin
	if(apb_cmd_en_pos)begin
		apb_wr_addr_pre <= apb_wr_addr_d2;
		apb_wr_data_pre <= apb_wr_data_d2;
	end
end

always @(posedge apb_clk or negedge apb_rst_n)
if (!apb_rst_n)begin
	apb_sel      <= 0; 
  apb_enable   <= 0;
  apb_addr     <= 8'd0;
  apb_write    <= 0;
  apb_wdata    <= 16'd0;
end
else begin
	case (apb_state)
		APB_IDLE:begin
			apb_sel      <= 0; 
      apb_enable   <= 0;
      apb_addr     <= 8'd0;
      apb_write    <= 0;
      apb_wdata    <= 16'd0;
		end
		APB_STEUP:begin
			if(apb_port_sel==0)begin
				apb_sel      <= 1; 
        apb_enable   <= 0;
        apb_addr     <= apb_wr_addr_pre;
        apb_write    <= apb_wr_flag;
        apb_wdata    <= apb_wr_data_pre;
			end
		end
		APB_WR:begin
			if(apb_port_sel==0)begin
				apb_sel      <= 1; 
        apb_enable   <= 1;
        apb_addr     <= apb_wr_addr_pre;
        apb_write    <= 1;
        apb_wdata    <= apb_wr_data_pre;
			end
		end
		APB_RD:begin
			if(apb_port_sel==0)begin
				apb_sel      <= 1; 
        apb_enable   <= 1;
        apb_addr     <= apb_wr_addr_pre;
        apb_write    <= 0;
        apb_wdata    <= apb_wr_data_pre;
			end		
		end
		APB_END:begin
			apb_sel      <= 0; 
      apb_enable   <= 0;
      apb_addr     <= 8'd0;
      apb_write    <= 0;
      apb_wdata    <= 16'd0;			
		end
		default:begin
		  apb_sel      <= 0; 
      apb_enable   <= 0;
      apb_addr     <= 8'd0;
      apb_write    <= 0;
      apb_wdata    <= 16'd0;
		end	
	endcase
end

always @(posedge apb_clk or negedge apb_rst_n)
if (!apb_rst_n)begin
	apb_1_sel      <= 0; 
  apb_1_enable   <= 0;
  apb_1_addr     <= 8'd0;
  apb_1_write    <= 0;
  apb_1_wdata    <= 16'd0;
end
else begin
	case (apb_state)
		APB_IDLE:begin
			apb_1_sel      <= 0; 
      apb_1_enable   <= 0;
      apb_1_addr     <= 8'd0;
      apb_1_write    <= 0;
      apb_1_wdata    <= 16'd0;
		end
		APB_STEUP:begin
			if(apb_port_sel==1)begin
				apb_1_sel      <= 1; 
        apb_1_enable   <= 0;
        apb_1_addr     <= apb_wr_addr_pre;
        apb_1_write    <= apb_wr_flag;
        apb_1_wdata    <= apb_wr_data_pre;
			end
		end
		APB_WR:begin
			if(apb_port_sel==1)begin
				apb_1_sel      <= 1; 
        apb_1_enable   <= 1;
        apb_1_addr     <= apb_wr_addr_pre;
        apb_1_write    <= 1;
        apb_1_wdata    <= apb_wr_data_pre;
			end
		end
		APB_RD:begin
			if(apb_port_sel==1)begin
				apb_1_sel      <= 1; 
        apb_1_enable   <= 1;
        apb_1_addr     <= apb_wr_addr_pre;
        apb_1_write    <= 0;
        apb_1_wdata    <= apb_wr_data_pre;
			end		
		end
		APB_END:begin
			apb_1_sel      <= 0; 
      apb_1_enable   <= 0;
      apb_1_addr     <= 8'd0;
      apb_1_write    <= 0;
      apb_1_wdata    <= 16'd0;			
		end
		default:begin
		  apb_1_sel      <= 0; 
      apb_1_enable   <= 0;
      apb_1_addr     <= 8'd0;
      apb_1_write    <= 0;
      apb_1_wdata    <= 16'd0;
		end	
	endcase
end

always @(posedge apb_clk or negedge apb_rst_n)
if (!apb_rst_n)
apb_done <= 0;
else if(apb_state == APB_END)
apb_done <= 1;
else if((apb_state == APB_IDLE) & apb_cmd_en_pos)
apb_done <= 0;

always @(posedge apb_clk or negedge apb_rst_n)
if (!apb_rst_n)
apb_rd_data <= 16'd0;
else if((apb_state == APB_RD) & apb_ready_sel)begin
	if(apb_port_sel == 0)
	apb_rd_data <= apb_rdata;
	else if(apb_port_sel == 1)
	apb_rd_data <= apb_1_rdata;
end

endmodule
