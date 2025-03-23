module axi_slave_default (
    input  wire        clk          ,
    input  wire        rst          ,

    input  wire [31:0] WR_ADDR      ,
    input  wire [ 7:0] WR_LEN       ,
    input  wire [ 1:0] WR_ID        ,
    input  wire        WR_ADDR_VALID,
    output wire        WR_ADDR_READY,
      
    input  wire [31:0] WR_DATA      ,
    input  wire [ 3:0] WR_STRB      ,
    output wire [ 1:0] WR_BACK_ID   ,
    input  wire        WR_DATA_VALID,
    output wire        WR_DATA_READY,
    input  wire        WR_DATA_LAST ,
      
    input  wire [31:0] RD_ADDR      ,
    input  wire [ 7:0] RD_LEN       ,
    input  wire [ 3:0] RD_ID        ,
    input  wire        RD_ADDR_VALID,
    output wire        RD_ADDR_READY,

    output wire [31:0] RD_DATA      ,
    output wire        RD_DATA_LAST ,
    output wire [ 3:0] RD_BACK_ID   ,
    input  wire        RD_DATA_READY,
    output wire        RD_DATA_VALID
);
//如果AXI总线某一个模块暂时不需要连接，用default模块代替。

assign WR_ADDR_READY = 0;
assign WR_BACK_ID    = 0;
assign WR_DATA_READY = 0;
assign RD_ADDR_READY = 0;
assign RD_DATA       = 0;
assign RD_DATA_LAST  = 0;
assign RD_BACK_ID    = 0;
assign RD_DATA_VALID = 0;

endmodule