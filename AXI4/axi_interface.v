module axi_interface (
    input wire BUS_CLK,
    input wire BUS_RST,

    //MASTER 0 以太网主机
    input wire [27:0]  M0_WR_ADDR      ,
    input wire [ 7:0]  M0_WR_LEN       ,
    input wire         M0_WR_ADDR_VALID,
    output wire        M0_WR_ADDR_READY,

    input wire [ 31:0] M0_WR_DATA      ,
    input wire [  3:0] M0_WR_STRB      ,
    input  wire        M0_WR_DATA_VALID,
    output wire        M0_WR_DATA_READY,
    input  wire        M0_WR_DATA_LAST ,

    input wire [27:0]  M0_RD_ADDR      ,
    input wire [ 7:0]  M0_RD_LEN       ,
    input wire         M0_RD_ADDR_VALID,
    output wire        M0_RD_ADDR_READY,

    output wire [31:0] M0_RD_DATA      ,
    output wire        M0_RD_DATA_LAST ,
    input  wire        M0_RD_DATA_READY,
    output wire        M0_RD_DATA_VALID,

    //SLAVE 0 DDR从机
    input wire [27:0]  S0_WR_ADDR      ,
    input wire [ 7:0]  S0_WR_LEN       ,
    input wire         S0_WR_ADDR_VALID,
    output wire        S0_WR_ADDR_READY,

    input wire [ 31:0] S0_WR_DATA      ,
    input wire [  3:0] S0_WR_STRB      ,
    input  wire        S0_WR_DATA_VALID,
    output wire        S0_WR_DATA_READY,
    input  wire        S0_WR_DATA_LAST ,

    input wire [27:0]  S0_RD_ADDR      ,
    input wire [ 7:0]  S0_RD_LEN       ,
    input wire         S0_RD_ADDR_VALID,
    output wire        S0_RD_ADDR_READY,

    output wire [31:0] S0_RD_DATA      ,
    output wire        S0_RD_DATA_LAST ,
    input  wire        S0_RD_DATA_READY,
    output wire        S0_RD_DATA_VALID,

    //SLAVE 1 JTAG从机
    input wire [27:0]  S1_WR_ADDR      ,
    input wire [ 7:0]  S1_WR_LEN       ,
    input wire         S1_WR_ADDR_VALID,
    output wire        S1_WR_ADDR_READY,

    input wire [ 31:0] S1_WR_DATA      ,
    input wire [  3:0] S1_WR_STRB      ,
    input  wire        S1_WR_DATA_VALID,
    output wire        S1_WR_DATA_READY,
    input  wire        S1_WR_DATA_LAST ,

    input wire [27:0]  S1_RD_ADDR      ,
    input wire [ 7:0]  S1_RD_LEN       ,
    input wire         S1_RD_ADDR_VALID,
    output wire        S1_RD_ADDR_READY,

    output wire [31:0] S1_RD_DATA      ,
    output wire        S1_RD_DATA_LAST ,
    input  wire        S1_RD_DATA_READY,
    output wire        S1_RD_DATA_VALID,
);







endmodule