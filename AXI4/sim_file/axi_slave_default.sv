module axi_slave_default (
    input                clk,
    input                rstn,
    output logic         SLAVE_CLK          ,
    output logic         SLAVE_RSTN         ,
    input  logic [4-1:0] SLAVE_WR_ADDR_ID   ,
    input  logic [31:0]  SLAVE_WR_ADDR      ,
    input  logic [ 7:0]  SLAVE_WR_ADDR_LEN  ,
    input  logic [ 1:0]  SLAVE_WR_ADDR_BURST,
    input  logic         SLAVE_WR_ADDR_VALID,
    output logic         SLAVE_WR_ADDR_READY,
    input  logic [31:0]  SLAVE_WR_DATA      ,
    input  logic [ 3:0]  SLAVE_WR_STRB      ,
    input  logic         SLAVE_WR_DATA_LAST ,
    input  logic         SLAVE_WR_DATA_VALID,
    output logic         SLAVE_WR_DATA_READY,
    output logic [4-1:0] SLAVE_WR_BACK_ID   ,
    output logic [ 1:0]  SLAVE_WR_BACK_RESP ,
    output logic         SLAVE_WR_BACK_VALID,
    input  logic         SLAVE_WR_BACK_READY,
    input  logic [4-1:0] SLAVE_RD_ADDR_ID   ,
    input  logic [31:0]  SLAVE_RD_ADDR      ,
    input  logic [ 7:0]  SLAVE_RD_ADDR_LEN  ,
    input  logic [ 1:0]  SLAVE_RD_ADDR_BURST,
    input  logic         SLAVE_RD_ADDR_VALID,
    output logic         SLAVE_RD_ADDR_READY,
    output logic [4-1:0] SLAVE_RD_BACK_ID   ,
    output logic [31:0]  SLAVE_RD_DATA      ,
    output logic [ 1:0]  SLAVE_RD_DATA_RESP ,
    output logic         SLAVE_RD_DATA_LAST ,
    output logic         SLAVE_RD_DATA_VALID,
    input  logic         SLAVE_RD_DATA_READY
);
//如果AXI总线某一个模块暂时不需要连接，用default模块代替。
assign SLAVE_CLK = clk;
assign SLAVE_RSTN = rstn;
assign SLAVE_WR_ADDR_READY = 0;
assign SLAVE_WR_DATA_READY = 0;
assign SLAVE_WR_BACK_ID    = 0;
assign SLAVE_WR_BACK_RESP  = 0;
assign SLAVE_WR_BACK_VALID = 0;
assign SLAVE_RD_ADDR_READY = 0;
assign SLAVE_RD_BACK_ID    = 0;
assign SLAVE_RD_DATA       = 0;
assign SLAVE_RD_DATA_RESP  = 0;
assign SLAVE_RD_DATA_LAST  = 0;
assign SLAVE_RD_DATA_VALID = 0;

endmodule