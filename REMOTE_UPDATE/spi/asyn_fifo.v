
`timescale 1 ns / 1 ns
module asyn_fifo #(
parameter                           U_DLY       = 1  ,
parameter                           DATA_WIDTH  = 263 ,
parameter                           DATA_DEEPTH = 256 ,
parameter                           ADDR_WIDTH  = 8  
)
(
input                               wr_clk           ,    
input                               wr_rst_n         ,
input                               rd_clk           ,
input                               rd_rst_n         ,
input      [DATA_WIDTH-1:0]         din              ,
input                               wr_en            ,
input                               rd_en            ,
output reg [DATA_WIDTH-1:0]         dout             ,
output wire                         full             ,
output reg                          prog_full        ,
output reg                          empty            ,
output reg                          prog_empty       ,
input      [ADDR_WIDTH-1:0]         prog_full_thresh ,
input      [ADDR_WIDTH-1:0]         prog_empty_thresh 
);
// Parameter Define 




reg        [DATA_WIDTH-1:0]         mem [DATA_DEEPTH-1:0]/* synthesis syn_ramstyle="block_ram" */;

reg        [ADDR_WIDTH-1:0]         wptr;
reg        [ADDR_WIDTH-1:0]         wq1_rptr;
reg        [ADDR_WIDTH-1:0]         wq2_rptr;
reg        [ADDR_WIDTH-1:0]         rptr; 
reg        [ADDR_WIDTH-1:0]         rq2_wptr;
reg        [ADDR_WIDTH-1:0]         rq1_wptr;
reg        [ADDR_WIDTH-1:0]         rbin; 
reg        [ADDR_WIDTH-1:0]         wbin;
// Wire Define
wire       [ADDR_WIDTH-1:0]         rgraynext;
wire       [ADDR_WIDTH-1:0]         rbinnext;
wire       [ADDR_WIDTH-1:0]         wgraynext;
wire       [ADDR_WIDTH-1:0]         wbinnext;
wire                                empty_x;
wire                                full_x;

wire       [ADDR_WIDTH-1:0]         wbin_syn;
wire       [ADDR_WIDTH-1:0]         rbin_syn;
wire       [ADDR_WIDTH-1:0]         r_data_count;
wire       [ADDR_WIDTH-1:0]         w_data_count;

`ifdef SIM_FIFO
integer i;
initial
begin
    for( i=0;i<=DATA_DEEPTH-1;i=i+1)
      begin
         mem[i] = {(DATA_WIDTH){1'b0}};        
      end
end  
`endif
//---------------------------------------------------------------------------
// dual port ram
//---------------------------------------------------------------------------
always @ (posedge wr_clk)
begin
    if(wr_en == 1'b1)     
        mem[wbin] <= #U_DLY din;    
end
                    
always @ (posedge rd_clk)
begin                                        
    dout <= #U_DLY mem[rbinnext];        
end                                                                                                        
//---------------------------------------------------------------------------
// WRITE
//---------------------------------------------------------------------------
always @ (posedge wr_clk or negedge wr_rst_n)
begin
    if(wr_rst_n == 1'b0)     
        begin
            wq1_rptr <= #U_DLY {(ADDR_WIDTH){1'b0}};
            wq2_rptr <= #U_DLY {(ADDR_WIDTH){1'b0}};
        end       
    else    
        begin
            wq1_rptr <= #U_DLY rptr;
            wq2_rptr <= #U_DLY wq1_rptr;
        end       
end


assign wbinnext  = (wr_en == 1'b1) ?  wbin + {{(ADDR_WIDTH){1'b0}},1'b1} : wbin;

assign wgraynext = (wbinnext>>1) ^ wbinnext;
 
assign full_x =  ((wbin - rbin_syn) == {(ADDR_WIDTH){1'b1}}) ? 1'b1 : 1'b0; 

always @ (posedge wr_clk or negedge wr_rst_n)
begin
    if(wr_rst_n == 1'b0)
        begin     
            wbin <= #U_DLY {(ADDR_WIDTH){1'b0}};
            wptr <= #U_DLY {(ADDR_WIDTH){1'b0}}; 
        end          
    else  
        begin
            wbin <= #U_DLY wbinnext;
            wptr <= #U_DLY wgraynext;         
        end  
end

assign full =   full_x;
//---------------------------------------------------------------------------
// READ
//---------------------------------------------------------------------------
always @ (posedge rd_clk or negedge rd_rst_n)
begin
    if(rd_rst_n == 1'b0)     
        begin
            rq1_wptr <= #U_DLY {(ADDR_WIDTH){1'b0}};
            rq2_wptr <= #U_DLY {(ADDR_WIDTH){1'b0}};
        end       
    else    
        begin
            rq1_wptr <= #U_DLY wptr;
            rq2_wptr <= #U_DLY rq1_wptr;
        end
end  

assign rbinnext = (rd_en == 1'b1) ? rbin + {{(ADDR_WIDTH){1'b0}},1'b1} : rbin;  

assign rgraynext = (rbinnext>>1) ^ rbinnext;

assign empty_x = (rbinnext == wbin_syn);

always @ (posedge rd_clk or negedge rd_rst_n)
begin
    if(rd_rst_n == 1'b0)     
        begin
            rbin <= #U_DLY {(ADDR_WIDTH){1'b0}};
            rptr <= #U_DLY {(ADDR_WIDTH){1'b0}}; 
        end       
    else    
        begin
            rbin <= #U_DLY rbinnext;
            rptr <= #U_DLY rgraynext; 
        end               
end

always @ (posedge rd_clk or negedge rd_rst_n)
begin
    if(rd_rst_n == 1'b0)     
        empty <= #U_DLY 1'b1;        
    else    
        empty <= #U_DLY empty_x;
end
//---------------------------------------------------------------------------
// gray_to_bin
//---------------------------------------------------------------------------
function [ADDR_WIDTH:0] gray_to_bin;
    input [ADDR_WIDTH:0] data;
    integer                i;
	begin
        gray_to_bin[ADDR_WIDTH]=data[ADDR_WIDTH];
		for(i=ADDR_WIDTH-1;i>=0;i=i-1) 
	    gray_to_bin[i]=gray_to_bin[i+1]^data[i];
	end 	
endfunction
//---------------------------------------------------------------------------
// prog_empty
//---------------------------------------------------------------------------

assign wbin_syn = gray_to_bin(rq2_wptr);

assign  r_data_count = (wbin_syn - rbin); 

always @ (posedge rd_clk or negedge rd_rst_n)
begin
    if(rd_rst_n == 1'b0)     
        prog_empty <= #U_DLY 1'b1;         
    else if( r_data_count >= {1'b0,prog_empty_thresh} )  
        prog_empty <= #U_DLY 1'b0;
    else
        prog_empty <= #U_DLY 1'b1;
end
//---------------------------------------------------------------------------
// prog_full
//---------------------------------------------------------------------------
assign rbin_syn = gray_to_bin(wq2_rptr); 

assign w_data_count = (wbin - rbin_syn); 

always @ (posedge wr_clk or negedge wr_rst_n)
begin
    if(wr_rst_n == 1'b0)     
        prog_full <= #U_DLY 1'b0;         
    else if( w_data_count >= {1'b0,prog_full_thresh} )  
        prog_full <= #U_DLY 1'b1;
    else
        prog_full <= #U_DLY 1'b0;
end
//-----------------------------------------------------------------------------------//
//
//-----------------------------------------------------------------------------------//
endmodule
