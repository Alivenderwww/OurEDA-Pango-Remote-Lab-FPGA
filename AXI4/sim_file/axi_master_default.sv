module axi_master_default (
output         MASTER_CLK          ,
output         MASTER_RSTN         ,
output [2-1:0] MASTER_WR_ADDR_ID   ,
output [31:0]  MASTER_WR_ADDR      ,
output [ 7:0]  MASTER_WR_ADDR_LEN  ,
output [ 1:0]  MASTER_WR_ADDR_BURST,
output         MASTER_WR_ADDR_VALID,
input          MASTER_WR_ADDR_READY,
output [31:0]  MASTER_WR_DATA      ,
output [ 3:0]  MASTER_WR_STRB      ,
output         MASTER_WR_DATA_LAST ,
output         MASTER_WR_DATA_VALID,
input          MASTER_WR_DATA_READY,
input  [2-1:0] MASTER_WR_BACK_ID   ,
input  [ 1:0]  MASTER_WR_BACK_RESP ,
input          MASTER_WR_BACK_VALID,
output         MASTER_WR_BACK_READY,
output [2-1:0] MASTER_RD_ADDR_ID   ,
output [31:0]  MASTER_RD_ADDR      ,
output [ 7:0]  MASTER_RD_ADDR_LEN  ,
output [ 1:0]  MASTER_RD_ADDR_BURST,
output         MASTER_RD_ADDR_VALID,
input          MASTER_RD_ADDR_READY,
input  [2-1:0] MASTER_RD_BACK_ID   ,
input  [31:0]  MASTER_RD_DATA      ,
input  [ 1:0]  MASTER_RD_DATA_RESP ,
input          MASTER_RD_DATA_LAST ,
input          MASTER_RD_DATA_VALID,
output         MASTER_RD_DATA_READY );
//如果AXI总线某一个模块暂时不需要连接，用default模块代替。

assign MASTER_WR_ADDR_ID    = 0;
assign MASTER_WR_ADDR       = 0;
assign MASTER_WR_ADDR_LEN   = 0;
assign MASTER_WR_ADDR_BURST = 0;
assign MASTER_WR_ADDR_VALID = 0;
assign MASTER_WR_DATA       = 0;
assign MASTER_WR_STRB       = 0;
assign MASTER_WR_DATA_LAST  = 0;
assign MASTER_WR_DATA_VALID = 0;
assign MASTER_WR_BACK_READY = 0;
assign MASTER_RD_ADDR_ID    = 0;
assign MASTER_RD_ADDR       = 0;
assign MASTER_RD_ADDR_LEN   = 0;
assign MASTER_RD_ADDR_BURST = 0;
assign MASTER_RD_ADDR_VALID = 0;
assign MASTER_RD_DATA_READY = 0;

endmodule