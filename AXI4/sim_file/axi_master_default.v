module axi_master_default (
    input  wire        clk          ,
    input  wire        rst          ,

    output wire [31:0] WR_ADDR      ,
    output wire [ 7:0] WR_LEN       ,
    output wire [ 1:0] WR_ID        ,
    output wire        WR_ADDR_VALID,
    input  wire        WR_ADDR_READY,
      
    output wire [31:0] WR_DATA      ,
    output wire [ 3:0] WR_STRB      ,
    input  wire [ 1:0] WR_BACK_ID   ,
    output wire        WR_DATA_VALID,
    input  wire        WR_DATA_READY,
    output wire        WR_DATA_LAST ,
      
    output wire [31:0] RD_ADDR      ,
    output wire [ 7:0] RD_LEN       ,
    output wire [ 1:0] RD_ID        ,
    output wire        RD_ADDR_VALID,
    input  wire        RD_ADDR_READY,

    input  wire [31:0] RD_DATA      ,
    input  wire        RD_DATA_LAST ,
    input  wire [ 1:0] RD_BACK_ID   ,
    output wire        RD_DATA_READY,
    input  wire        RD_DATA_VALID
);
//如果AXI总线某一个模块暂时不需要连接，用default模块代替。

assign WR_ADDR       = 0;
assign WR_LEN        = 0;
assign WR_ID         = 0;
assign WR_ADDR_VALID = 0;
assign WR_DATA       = 0;
assign WR_STRB       = 0;
assign WR_DATA_VALID = 0;
assign WR_DATA_LAST  = 0;
assign RD_ADDR       = 0;
assign RD_LEN        = 0;
assign RD_ID         = 0;
assign RD_ADDR_VALID = 0;
assign RD_DATA_READY = 0;

endmodule