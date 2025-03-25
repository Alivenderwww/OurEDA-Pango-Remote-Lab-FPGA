module axi_bus #( //AXI顶层总线。支持主从机自设时钟域，内部设置FIFO。支持out-standing传输暂存，从机可选择性支持out-of-order乱序执行，目前不支持主机interleaving交织。
    parameter S0_START_ADDR = 32'h00_00_00_00,
    parameter S0_END_ADDR   = 32'h0F_FF_FF_FF,
    parameter S1_START_ADDR = 32'h10_00_00_00,
    parameter S1_END_ADDR   = 32'h1F_FF_FF_0F,
    parameter S2_START_ADDR = 32'h20_00_00_00,
    parameter S2_END_ADDR   = 32'h2F_FF_FF_0F,
    parameter S3_START_ADDR = 32'h30_00_00_00,
    parameter S3_END_ADDR   = 32'h3F_FF_FF_0F
)(
input  wire        BUS_CLK,
input  wire        BUS_RSTN,

//MASTER 0 以太网主机                   MASTER 1 主机                           MASTER 2 主机                           MASTER 3 主机
input  wire        M0_CLK          ,    input  wire        M1_CLK          ,    input  wire        M2_CLK          ,    input  wire        M3_CLK          ,
input  wire        M0_RSTN         ,    input  wire        M1_RSTN         ,    input  wire        M2_RSTN         ,    input  wire        M3_RSTN         ,
input  wire [ 1:0] M0_WR_ADDR_ID   ,    input  wire [ 1:0] M1_WR_ADDR_ID   ,    input  wire [ 1:0] M2_WR_ADDR_ID   ,    input  wire [ 1:0] M3_WR_ADDR_ID   ,
input  wire [31:0] M0_WR_ADDR      ,    input  wire [31:0] M1_WR_ADDR      ,    input  wire [31:0] M2_WR_ADDR      ,    input  wire [31:0] M3_WR_ADDR      ,
input  wire [ 7:0] M0_WR_ADDR_LEN  ,    input  wire [ 7:0] M1_WR_ADDR_LEN  ,    input  wire [ 7:0] M2_WR_ADDR_LEN  ,    input  wire [ 7:0] M3_WR_ADDR_LEN  ,
input  wire [ 1:0] M0_WR_ADDR_BURST,    input  wire [ 1:0] M1_WR_ADDR_BURST,    input  wire [ 1:0] M2_WR_ADDR_BURST,    input  wire [ 1:0] M3_WR_ADDR_BURST,
input  wire        M0_WR_ADDR_VALID,    input  wire        M1_WR_ADDR_VALID,    input  wire        M2_WR_ADDR_VALID,    input  wire        M3_WR_ADDR_VALID,
output wire        M0_WR_ADDR_READY,    output wire        M1_WR_ADDR_READY,    output wire        M2_WR_ADDR_READY,    output wire        M3_WR_ADDR_READY,

input  wire [31:0] M0_WR_DATA      ,    input  wire [31:0] M1_WR_DATA      ,    input  wire [31:0] M2_WR_DATA      ,    input  wire [31:0] M3_WR_DATA      ,
input  wire [ 3:0] M0_WR_STRB      ,    input  wire [ 3:0] M1_WR_STRB      ,    input  wire [ 3:0] M2_WR_STRB      ,    input  wire [ 3:0] M3_WR_STRB      ,
input  wire        M0_WR_DATA_LAST ,    input  wire        M1_WR_DATA_LAST ,    input  wire        M2_WR_DATA_LAST ,    input  wire        M3_WR_DATA_LAST ,
input  wire        M0_WR_DATA_VALID,    input  wire        M1_WR_DATA_VALID,    input  wire        M2_WR_DATA_VALID,    input  wire        M3_WR_DATA_VALID,
output wire        M0_WR_DATA_READY,    output wire        M1_WR_DATA_READY,    output wire        M2_WR_DATA_READY,    output wire        M3_WR_DATA_READY,

output wire [ 1:0] M0_WR_BACK_ID   ,    output wire [ 1:0] M1_WR_BACK_ID   ,    output wire [ 1:0] M2_WR_BACK_ID   ,    output wire [ 1:0] M3_WR_BACK_ID   ,
output wire [ 1:0] M0_WR_BACK_RESP ,    output wire [ 1:0] M1_WR_BACK_RESP ,    output wire [ 1:0] M2_WR_BACK_RESP ,    output wire [ 1:0] M3_WR_BACK_RESP ,
output wire        M0_WR_BACK_VALID,    output wire        M1_WR_BACK_VALID,    output wire        M2_WR_BACK_VALID,    output wire        M3_WR_BACK_VALID,
input  wire        M0_WR_BACK_READY,    input  wire        M1_WR_BACK_READY,    input  wire        M2_WR_BACK_READY,    input  wire        M3_WR_BACK_READY,

input  wire [ 1:0] M0_RD_ADDR_ID   ,    input  wire [ 1:0] M1_RD_ADDR_ID   ,    input  wire [ 1:0] M2_RD_ADDR_ID   ,    input  wire [ 1:0] M3_RD_ADDR_ID   ,
input  wire [31:0] M0_RD_ADDR      ,    input  wire [31:0] M1_RD_ADDR      ,    input  wire [31:0] M2_RD_ADDR      ,    input  wire [31:0] M3_RD_ADDR      ,
input  wire [ 7:0] M0_RD_ADDR_LEN  ,    input  wire [ 7:0] M1_RD_ADDR_LEN  ,    input  wire [ 7:0] M2_RD_ADDR_LEN  ,    input  wire [ 7:0] M3_RD_ADDR_LEN  ,
input  wire [ 1:0] M0_RD_ADDR_BURST,    input  wire [ 1:0] M1_RD_ADDR_BURST,    input  wire [ 1:0] M2_RD_ADDR_BURST,    input  wire [ 1:0] M3_RD_ADDR_BURST,
input  wire        M0_RD_ADDR_VALID,    input  wire        M1_RD_ADDR_VALID,    input  wire        M2_RD_ADDR_VALID,    input  wire        M3_RD_ADDR_VALID,
output wire        M0_RD_ADDR_READY,    output wire        M1_RD_ADDR_READY,    output wire        M2_RD_ADDR_READY,    output wire        M3_RD_ADDR_READY,

output wire [ 1:0] M0_RD_BACK_ID   ,    output wire [ 1:0] M1_RD_BACK_ID   ,    output wire [ 1:0] M2_RD_BACK_ID   ,    output wire [ 1:0] M3_RD_BACK_ID   ,
output wire [31:0] M0_RD_DATA      ,    output wire [31:0] M1_RD_DATA      ,    output wire [31:0] M2_RD_DATA      ,    output wire [31:0] M3_RD_DATA      ,
output wire [ 1:0] M0_RD_DATA_RESP ,    output wire [ 1:0] M1_RD_DATA_RESP ,    output wire [ 1:0] M2_RD_DATA_RESP ,    output wire [ 1:0] M3_RD_DATA_RESP ,
output wire        M0_RD_DATA_LAST ,    output wire        M1_RD_DATA_LAST ,    output wire        M2_RD_DATA_LAST ,    output wire        M3_RD_DATA_LAST ,
output wire        M0_RD_DATA_VALID,    output wire        M1_RD_DATA_VALID,    output wire        M2_RD_DATA_VALID,    output wire        M3_RD_DATA_VALID,
input  wire        M0_RD_DATA_READY,    input  wire        M1_RD_DATA_READY,    input  wire        M2_RD_DATA_READY,    input  wire        M3_RD_DATA_READY,

//SLAVE 0 DDR从机                       //SLAVE 1 JTAG从机                   //SLAVE 2 从机                  //SLAVE 3 从机
input  wire        S0_CLK          ,    input  wire        S1_CLK          ,    input  wire        S2_CLK          ,    input  wire        S3_CLK          ,
input  wire        S0_RSTN         ,    input  wire        S1_RSTN         ,    input  wire        S2_RSTN         ,    input  wire        S3_RSTN         ,
output wire [ 3:0] S0_WR_ADDR_ID   ,    output wire [ 3:0] S1_WR_ADDR_ID   ,    output wire [ 3:0] S2_WR_ADDR_ID   ,    output wire [ 3:0] S3_WR_ADDR_ID   ,
output wire [31:0] S0_WR_ADDR      ,    output wire [31:0] S1_WR_ADDR      ,    output wire [31:0] S2_WR_ADDR      ,    output wire [31:0] S3_WR_ADDR      ,
output wire [ 7:0] S0_WR_ADDR_LEN  ,    output wire [ 7:0] S1_WR_ADDR_LEN  ,    output wire [ 7:0] S2_WR_ADDR_LEN  ,    output wire [ 7:0] S3_WR_ADDR_LEN  ,
output wire [ 1:0] S0_WR_ADDR_BURST,    output wire [ 1:0] S1_WR_ADDR_BURST,    output wire [ 1:0] S2_WR_ADDR_BURST,    output wire [ 1:0] S3_WR_ADDR_BURST,
output wire        S0_WR_ADDR_VALID,    output wire        S1_WR_ADDR_VALID,    output wire        S2_WR_ADDR_VALID,    output wire        S3_WR_ADDR_VALID,
input  wire        S0_WR_ADDR_READY,    input  wire        S1_WR_ADDR_READY,    input  wire        S2_WR_ADDR_READY,    input  wire        S3_WR_ADDR_READY,

output wire [31:0] S0_WR_DATA      ,    output wire [31:0] S1_WR_DATA      ,    output wire [31:0] S2_WR_DATA      ,    output wire [31:0] S3_WR_DATA      ,
output wire [ 3:0] S0_WR_STRB      ,    output wire [ 3:0] S1_WR_STRB      ,    output wire [ 3:0] S2_WR_STRB      ,    output wire [ 3:0] S3_WR_STRB      ,
output wire        S0_WR_DATA_LAST ,    output wire        S1_WR_DATA_LAST ,    output wire        S2_WR_DATA_LAST ,    output wire        S3_WR_DATA_LAST ,
output wire        S0_WR_DATA_VALID,    output wire        S1_WR_DATA_VALID,    output wire        S2_WR_DATA_VALID,    output wire        S3_WR_DATA_VALID,
input  wire        S0_WR_DATA_READY,    input  wire        S1_WR_DATA_READY,    input  wire        S2_WR_DATA_READY,    input  wire        S3_WR_DATA_READY,

input  wire [ 3:0] S0_WR_BACK_ID   ,    input  wire [ 3:0] S1_WR_BACK_ID   ,    input  wire [ 3:0] S2_WR_BACK_ID   ,    input  wire [ 3:0] S3_WR_BACK_ID   ,
input  wire [ 1:0] S0_WR_BACK_RESP ,    input  wire [ 1:0] S1_WR_BACK_RESP ,    input  wire [ 1:0] S2_WR_BACK_RESP ,    input  wire [ 1:0] S3_WR_BACK_RESP ,
input  wire        S0_WR_BACK_VALID,    input  wire        S1_WR_BACK_VALID,    input  wire        S2_WR_BACK_VALID,    input  wire        S3_WR_BACK_VALID,
output wire        S0_WR_BACK_READY,    output wire        S1_WR_BACK_READY,    output wire        S2_WR_BACK_READY,    output wire        S3_WR_BACK_READY,

output wire [ 3:0] S0_RD_ADDR_ID   ,    output wire [ 3:0] S1_RD_ADDR_ID   ,    output wire [ 3:0] S2_RD_ADDR_ID   ,    output wire [ 3:0] S3_RD_ADDR_ID   ,
output wire [31:0] S0_RD_ADDR      ,    output wire [31:0] S1_RD_ADDR      ,    output wire [31:0] S2_RD_ADDR      ,    output wire [31:0] S3_RD_ADDR      ,
output wire [ 7:0] S0_RD_ADDR_LEN  ,    output wire [ 7:0] S1_RD_ADDR_LEN  ,    output wire [ 7:0] S2_RD_ADDR_LEN  ,    output wire [ 7:0] S3_RD_ADDR_LEN  ,
output wire [ 1:0] S0_RD_ADDR_BURST,    output wire [ 1:0] S1_RD_ADDR_BURST,    output wire [ 1:0] S2_RD_ADDR_BURST,    output wire [ 1:0] S3_RD_ADDR_BURST,
output wire        S0_RD_ADDR_VALID,    output wire        S1_RD_ADDR_VALID,    output wire        S2_RD_ADDR_VALID,    output wire        S3_RD_ADDR_VALID,
input  wire        S0_RD_ADDR_READY,    input  wire        S1_RD_ADDR_READY,    input  wire        S2_RD_ADDR_READY,    input  wire        S3_RD_ADDR_READY,

input  wire [ 3:0] S0_RD_BACK_ID   ,    input  wire [ 3:0] S1_RD_BACK_ID   ,    input  wire [ 3:0] S2_RD_BACK_ID   ,    input  wire [ 3:0] S3_RD_BACK_ID   ,
input  wire [31:0] S0_RD_DATA      ,    input  wire [31:0] S1_RD_DATA      ,    input  wire [31:0] S2_RD_DATA      ,    input  wire [31:0] S3_RD_DATA      ,
input  wire [ 1:0] S0_RD_DATA_RESP ,    input  wire [ 1:0] S1_RD_DATA_RESP ,    input  wire [ 1:0] S2_RD_DATA_RESP ,    input  wire [ 1:0] S3_RD_DATA_RESP ,
input  wire        S0_RD_DATA_LAST ,    input  wire        S1_RD_DATA_LAST ,    input  wire        S2_RD_DATA_LAST ,    input  wire        S3_RD_DATA_LAST ,
input  wire        S0_RD_DATA_VALID,    input  wire        S1_RD_DATA_VALID,    input  wire        S2_RD_DATA_VALID,    input  wire        S3_RD_DATA_VALID,
output wire        S0_RD_DATA_READY,    output wire        S1_RD_DATA_READY,    output wire        S2_RD_DATA_READY,    output wire        S3_RD_DATA_READY
);

wire [ 1:0] M0_BUS_WR_ADDR_ID   ;     wire [ 1:0] M1_BUS_WR_ADDR_ID   ;     wire [ 1:0] M2_BUS_WR_ADDR_ID   ;     wire [ 1:0] M3_BUS_WR_ADDR_ID   ; wire [ 3:0] S0_BUS_WR_ADDR_ID   ;     wire [ 3:0] S1_BUS_WR_ADDR_ID   ;     wire [ 3:0] S2_BUS_WR_ADDR_ID   ;     wire [ 3:0] S3_BUS_WR_ADDR_ID   ;
wire [31:0] M0_BUS_WR_ADDR      ;     wire [31:0] M1_BUS_WR_ADDR      ;     wire [31:0] M2_BUS_WR_ADDR      ;     wire [31:0] M3_BUS_WR_ADDR      ; wire [31:0] S0_BUS_WR_ADDR      ;     wire [31:0] S1_BUS_WR_ADDR      ;     wire [31:0] S2_BUS_WR_ADDR      ;     wire [31:0] S3_BUS_WR_ADDR      ;
wire [ 7:0] M0_BUS_WR_ADDR_LEN  ;     wire [ 7:0] M1_BUS_WR_ADDR_LEN  ;     wire [ 7:0] M2_BUS_WR_ADDR_LEN  ;     wire [ 7:0] M3_BUS_WR_ADDR_LEN  ; wire [ 7:0] S0_BUS_WR_ADDR_LEN  ;     wire [ 7:0] S1_BUS_WR_ADDR_LEN  ;     wire [ 7:0] S2_BUS_WR_ADDR_LEN  ;     wire [ 7:0] S3_BUS_WR_ADDR_LEN  ;
wire [ 1:0] M0_BUS_WR_ADDR_BURST;     wire [ 1:0] M1_BUS_WR_ADDR_BURST;     wire [ 1:0] M2_BUS_WR_ADDR_BURST;     wire [ 1:0] M3_BUS_WR_ADDR_BURST; wire [ 1:0] S0_BUS_WR_ADDR_BURST;     wire [ 1:0] S1_BUS_WR_ADDR_BURST;     wire [ 1:0] S2_BUS_WR_ADDR_BURST;     wire [ 1:0] S3_BUS_WR_ADDR_BURST;
wire        M0_BUS_WR_ADDR_VALID;     wire        M1_BUS_WR_ADDR_VALID;     wire        M2_BUS_WR_ADDR_VALID;     wire        M3_BUS_WR_ADDR_VALID; wire        S0_BUS_WR_ADDR_VALID;     wire        S1_BUS_WR_ADDR_VALID;     wire        S2_BUS_WR_ADDR_VALID;     wire        S3_BUS_WR_ADDR_VALID;
wire        M0_BUS_WR_ADDR_READY;     wire        M1_BUS_WR_ADDR_READY;     wire        M2_BUS_WR_ADDR_READY;     wire        M3_BUS_WR_ADDR_READY; wire        S0_BUS_WR_ADDR_READY;     wire        S1_BUS_WR_ADDR_READY;     wire        S2_BUS_WR_ADDR_READY;     wire        S3_BUS_WR_ADDR_READY;

wire [31:0] M0_BUS_WR_DATA      ;     wire [31:0] M1_BUS_WR_DATA      ;     wire [31:0] M2_BUS_WR_DATA      ;     wire [31:0] M3_BUS_WR_DATA      ; wire [31:0] S0_BUS_WR_DATA      ;     wire [31:0] S1_BUS_WR_DATA      ;     wire [31:0] S2_BUS_WR_DATA      ;     wire [31:0] S3_BUS_WR_DATA      ;
wire [ 3:0] M0_BUS_WR_STRB      ;     wire [ 3:0] M1_BUS_WR_STRB      ;     wire [ 3:0] M2_BUS_WR_STRB      ;     wire [ 3:0] M3_BUS_WR_STRB      ; wire [ 3:0] S0_BUS_WR_STRB      ;     wire [ 3:0] S1_BUS_WR_STRB      ;     wire [ 3:0] S2_BUS_WR_STRB      ;     wire [ 3:0] S3_BUS_WR_STRB      ;
wire        M0_BUS_WR_DATA_LAST ;     wire        M1_BUS_WR_DATA_LAST ;     wire        M2_BUS_WR_DATA_LAST ;     wire        M3_BUS_WR_DATA_LAST ; wire        S0_BUS_WR_DATA_LAST ;     wire        S1_BUS_WR_DATA_LAST ;     wire        S2_BUS_WR_DATA_LAST ;     wire        S3_BUS_WR_DATA_LAST ;
wire        M0_BUS_WR_DATA_VALID;     wire        M1_BUS_WR_DATA_VALID;     wire        M2_BUS_WR_DATA_VALID;     wire        M3_BUS_WR_DATA_VALID; wire        S0_BUS_WR_DATA_VALID;     wire        S1_BUS_WR_DATA_VALID;     wire        S2_BUS_WR_DATA_VALID;     wire        S3_BUS_WR_DATA_VALID;
wire        M0_BUS_WR_DATA_READY;     wire        M1_BUS_WR_DATA_READY;     wire        M2_BUS_WR_DATA_READY;     wire        M3_BUS_WR_DATA_READY; wire        S0_BUS_WR_DATA_READY;     wire        S1_BUS_WR_DATA_READY;     wire        S2_BUS_WR_DATA_READY;     wire        S3_BUS_WR_DATA_READY;

wire [ 1:0] M0_BUS_WR_BACK_ID   ;     wire [ 1:0] M1_BUS_WR_BACK_ID   ;     wire [ 1:0] M2_BUS_WR_BACK_ID   ;     wire [ 1:0] M3_BUS_WR_BACK_ID   ; wire [ 3:0] S0_BUS_WR_BACK_ID   ;     wire [ 3:0] S1_BUS_WR_BACK_ID   ;     wire [ 3:0] S2_BUS_WR_BACK_ID   ;     wire [ 3:0] S3_BUS_WR_BACK_ID   ;
wire [ 1:0] M0_BUS_WR_BACK_RESP ;     wire [ 1:0] M1_BUS_WR_BACK_RESP ;     wire [ 1:0] M2_BUS_WR_BACK_RESP ;     wire [ 1:0] M3_BUS_WR_BACK_RESP ; wire [ 1:0] S0_BUS_WR_BACK_RESP ;     wire [ 1:0] S1_BUS_WR_BACK_RESP ;     wire [ 1:0] S2_BUS_WR_BACK_RESP ;     wire [ 1:0] S3_BUS_WR_BACK_RESP ;
wire        M0_BUS_WR_BACK_VALID;     wire        M1_BUS_WR_BACK_VALID;     wire        M2_BUS_WR_BACK_VALID;     wire        M3_BUS_WR_BACK_VALID; wire        S0_BUS_WR_BACK_VALID;     wire        S1_BUS_WR_BACK_VALID;     wire        S2_BUS_WR_BACK_VALID;     wire        S3_BUS_WR_BACK_VALID;
wire        M0_BUS_WR_BACK_READY;     wire        M1_BUS_WR_BACK_READY;     wire        M2_BUS_WR_BACK_READY;     wire        M3_BUS_WR_BACK_READY; wire        S0_BUS_WR_BACK_READY;     wire        S1_BUS_WR_BACK_READY;     wire        S2_BUS_WR_BACK_READY;     wire        S3_BUS_WR_BACK_READY;

wire [ 1:0] M0_BUS_RD_ADDR_ID   ;     wire [ 1:0] M1_BUS_RD_ADDR_ID   ;     wire [ 1:0] M2_BUS_RD_ADDR_ID   ;     wire [ 1:0] M3_BUS_RD_ADDR_ID   ; wire [ 3:0] S0_BUS_RD_ADDR_ID   ;     wire [ 3:0] S1_BUS_RD_ADDR_ID   ;     wire [ 3:0] S2_BUS_RD_ADDR_ID   ;     wire [ 3:0] S3_BUS_RD_ADDR_ID   ;
wire [31:0] M0_BUS_RD_ADDR      ;     wire [31:0] M1_BUS_RD_ADDR      ;     wire [31:0] M2_BUS_RD_ADDR      ;     wire [31:0] M3_BUS_RD_ADDR      ; wire [31:0] S0_BUS_RD_ADDR      ;     wire [31:0] S1_BUS_RD_ADDR      ;     wire [31:0] S2_BUS_RD_ADDR      ;     wire [31:0] S3_BUS_RD_ADDR      ;
wire [ 7:0] M0_BUS_RD_ADDR_LEN  ;     wire [ 7:0] M1_BUS_RD_ADDR_LEN  ;     wire [ 7:0] M2_BUS_RD_ADDR_LEN  ;     wire [ 7:0] M3_BUS_RD_ADDR_LEN  ; wire [ 7:0] S0_BUS_RD_ADDR_LEN  ;     wire [ 7:0] S1_BUS_RD_ADDR_LEN  ;     wire [ 7:0] S2_BUS_RD_ADDR_LEN  ;     wire [ 7:0] S3_BUS_RD_ADDR_LEN  ;
wire [ 1:0] M0_BUS_RD_ADDR_BURST;     wire [ 1:0] M1_BUS_RD_ADDR_BURST;     wire [ 1:0] M2_BUS_RD_ADDR_BURST;     wire [ 1:0] M3_BUS_RD_ADDR_BURST; wire [ 1:0] S0_BUS_RD_ADDR_BURST;     wire [ 1:0] S1_BUS_RD_ADDR_BURST;     wire [ 1:0] S2_BUS_RD_ADDR_BURST;     wire [ 1:0] S3_BUS_RD_ADDR_BURST;
wire        M0_BUS_RD_ADDR_VALID;     wire        M1_BUS_RD_ADDR_VALID;     wire        M2_BUS_RD_ADDR_VALID;     wire        M3_BUS_RD_ADDR_VALID; wire        S0_BUS_RD_ADDR_VALID;     wire        S1_BUS_RD_ADDR_VALID;     wire        S2_BUS_RD_ADDR_VALID;     wire        S3_BUS_RD_ADDR_VALID;
wire        M0_BUS_RD_ADDR_READY;     wire        M1_BUS_RD_ADDR_READY;     wire        M2_BUS_RD_ADDR_READY;     wire        M3_BUS_RD_ADDR_READY; wire        S0_BUS_RD_ADDR_READY;     wire        S1_BUS_RD_ADDR_READY;     wire        S2_BUS_RD_ADDR_READY;     wire        S3_BUS_RD_ADDR_READY;

wire [ 1:0] M0_BUS_RD_BACK_ID   ;     wire [ 1:0] M1_BUS_RD_BACK_ID   ;     wire [ 1:0] M2_BUS_RD_BACK_ID   ;     wire [ 1:0] M3_BUS_RD_BACK_ID   ; wire [ 3:0] S0_BUS_RD_BACK_ID   ;     wire [ 3:0] S1_BUS_RD_BACK_ID   ;     wire [ 3:0] S2_BUS_RD_BACK_ID   ;     wire [ 3:0] S3_BUS_RD_BACK_ID   ;
wire [31:0] M0_BUS_RD_DATA      ;     wire [31:0] M1_BUS_RD_DATA      ;     wire [31:0] M2_BUS_RD_DATA      ;     wire [31:0] M3_BUS_RD_DATA      ; wire [31:0] S0_BUS_RD_DATA      ;     wire [31:0] S1_BUS_RD_DATA      ;     wire [31:0] S2_BUS_RD_DATA      ;     wire [31:0] S3_BUS_RD_DATA      ;
wire [ 1:0] M0_BUS_RD_DATA_RESP ;     wire [ 1:0] M1_BUS_RD_DATA_RESP ;     wire [ 1:0] M2_BUS_RD_DATA_RESP ;     wire [ 1:0] M3_BUS_RD_DATA_RESP ; wire [ 1:0] S0_BUS_RD_DATA_RESP ;     wire [ 1:0] S1_BUS_RD_DATA_RESP ;     wire [ 1:0] S2_BUS_RD_DATA_RESP ;     wire [ 1:0] S3_BUS_RD_DATA_RESP ;
wire        M0_BUS_RD_DATA_LAST ;     wire        M1_BUS_RD_DATA_LAST ;     wire        M2_BUS_RD_DATA_LAST ;     wire        M3_BUS_RD_DATA_LAST ; wire        S0_BUS_RD_DATA_LAST ;     wire        S1_BUS_RD_DATA_LAST ;     wire        S2_BUS_RD_DATA_LAST ;     wire        S3_BUS_RD_DATA_LAST ;
wire        M0_BUS_RD_DATA_VALID;     wire        M1_BUS_RD_DATA_VALID;     wire        M2_BUS_RD_DATA_VALID;     wire        M3_BUS_RD_DATA_VALID; wire        S0_BUS_RD_DATA_VALID;     wire        S1_BUS_RD_DATA_VALID;     wire        S2_BUS_RD_DATA_VALID;     wire        S3_BUS_RD_DATA_VALID;
wire        M0_BUS_RD_DATA_READY;     wire        M1_BUS_RD_DATA_READY;     wire        M2_BUS_RD_DATA_READY;     wire        M3_BUS_RD_DATA_READY; wire        S0_BUS_RD_DATA_READY;     wire        S1_BUS_RD_DATA_READY;     wire        S2_BUS_RD_DATA_READY;     wire        S3_BUS_RD_DATA_READY;

axi_clock_converter axi_clock_converter_inst(
    .BUS_CLK              (BUS_CLK              ),
    .BUS_RSTN             (BUS_RSTN             ),
    .M0_BUS_WR_ADDR_ID    (M0_BUS_WR_ADDR_ID    ),    .M1_BUS_WR_ADDR_ID    (M1_BUS_WR_ADDR_ID    ),    .M2_BUS_WR_ADDR_ID    (M2_BUS_WR_ADDR_ID    ),    .M3_BUS_WR_ADDR_ID    (M3_BUS_WR_ADDR_ID    ),
    .M0_BUS_WR_ADDR       (M0_BUS_WR_ADDR       ),    .M1_BUS_WR_ADDR       (M1_BUS_WR_ADDR       ),    .M2_BUS_WR_ADDR       (M2_BUS_WR_ADDR       ),    .M3_BUS_WR_ADDR       (M3_BUS_WR_ADDR       ),
    .M0_BUS_WR_ADDR_LEN   (M0_BUS_WR_ADDR_LEN   ),    .M1_BUS_WR_ADDR_LEN   (M1_BUS_WR_ADDR_LEN   ),    .M2_BUS_WR_ADDR_LEN   (M2_BUS_WR_ADDR_LEN   ),    .M3_BUS_WR_ADDR_LEN   (M3_BUS_WR_ADDR_LEN   ),
    .M0_BUS_WR_ADDR_BURST (M0_BUS_WR_ADDR_BURST ),    .M1_BUS_WR_ADDR_BURST (M1_BUS_WR_ADDR_BURST ),    .M2_BUS_WR_ADDR_BURST (M2_BUS_WR_ADDR_BURST ),    .M3_BUS_WR_ADDR_BURST (M3_BUS_WR_ADDR_BURST ),
    .M0_BUS_WR_ADDR_VALID (M0_BUS_WR_ADDR_VALID ),    .M1_BUS_WR_ADDR_VALID (M1_BUS_WR_ADDR_VALID ),    .M2_BUS_WR_ADDR_VALID (M2_BUS_WR_ADDR_VALID ),    .M3_BUS_WR_ADDR_VALID (M3_BUS_WR_ADDR_VALID ),
    .M0_BUS_WR_ADDR_READY (M0_BUS_WR_ADDR_READY ),    .M1_BUS_WR_ADDR_READY (M1_BUS_WR_ADDR_READY ),    .M2_BUS_WR_ADDR_READY (M2_BUS_WR_ADDR_READY ),    .M3_BUS_WR_ADDR_READY (M3_BUS_WR_ADDR_READY ),
    .M0_BUS_WR_DATA       (M0_BUS_WR_DATA       ),    .M1_BUS_WR_DATA       (M1_BUS_WR_DATA       ),    .M2_BUS_WR_DATA       (M2_BUS_WR_DATA       ),    .M3_BUS_WR_DATA       (M3_BUS_WR_DATA       ),
    .M0_BUS_WR_STRB       (M0_BUS_WR_STRB       ),    .M1_BUS_WR_STRB       (M1_BUS_WR_STRB       ),    .M2_BUS_WR_STRB       (M2_BUS_WR_STRB       ),    .M3_BUS_WR_STRB       (M3_BUS_WR_STRB       ),
    .M0_BUS_WR_DATA_LAST  (M0_BUS_WR_DATA_LAST  ),    .M1_BUS_WR_DATA_LAST  (M1_BUS_WR_DATA_LAST  ),    .M2_BUS_WR_DATA_LAST  (M2_BUS_WR_DATA_LAST  ),    .M3_BUS_WR_DATA_LAST  (M3_BUS_WR_DATA_LAST  ),
    .M0_BUS_WR_DATA_VALID (M0_BUS_WR_DATA_VALID ),    .M1_BUS_WR_DATA_VALID (M1_BUS_WR_DATA_VALID ),    .M2_BUS_WR_DATA_VALID (M2_BUS_WR_DATA_VALID ),    .M3_BUS_WR_DATA_VALID (M3_BUS_WR_DATA_VALID ),
    .M0_BUS_WR_DATA_READY (M0_BUS_WR_DATA_READY ),    .M1_BUS_WR_DATA_READY (M1_BUS_WR_DATA_READY ),    .M2_BUS_WR_DATA_READY (M2_BUS_WR_DATA_READY ),    .M3_BUS_WR_DATA_READY (M3_BUS_WR_DATA_READY ),
    .M0_BUS_WR_BACK_ID    (M0_BUS_WR_BACK_ID    ),    .M1_BUS_WR_BACK_ID    (M1_BUS_WR_BACK_ID    ),    .M2_BUS_WR_BACK_ID    (M2_BUS_WR_BACK_ID    ),    .M3_BUS_WR_BACK_ID    (M3_BUS_WR_BACK_ID    ),
    .M0_BUS_WR_BACK_RESP  (M0_BUS_WR_BACK_RESP  ),    .M1_BUS_WR_BACK_RESP  (M1_BUS_WR_BACK_RESP  ),    .M2_BUS_WR_BACK_RESP  (M2_BUS_WR_BACK_RESP  ),    .M3_BUS_WR_BACK_RESP  (M3_BUS_WR_BACK_RESP  ),
    .M0_BUS_WR_BACK_VALID (M0_BUS_WR_BACK_VALID ),    .M1_BUS_WR_BACK_VALID (M1_BUS_WR_BACK_VALID ),    .M2_BUS_WR_BACK_VALID (M2_BUS_WR_BACK_VALID ),    .M3_BUS_WR_BACK_VALID (M3_BUS_WR_BACK_VALID ),
    .M0_BUS_WR_BACK_READY (M0_BUS_WR_BACK_READY ),    .M1_BUS_WR_BACK_READY (M1_BUS_WR_BACK_READY ),    .M2_BUS_WR_BACK_READY (M2_BUS_WR_BACK_READY ),    .M3_BUS_WR_BACK_READY (M3_BUS_WR_BACK_READY ),
    .M0_BUS_RD_ADDR_ID    (M0_BUS_RD_ADDR_ID    ),    .M1_BUS_RD_ADDR_ID    (M1_BUS_RD_ADDR_ID    ),    .M2_BUS_RD_ADDR_ID    (M2_BUS_RD_ADDR_ID    ),    .M3_BUS_RD_ADDR_ID    (M3_BUS_RD_ADDR_ID    ),
    .M0_BUS_RD_ADDR       (M0_BUS_RD_ADDR       ),    .M1_BUS_RD_ADDR       (M1_BUS_RD_ADDR       ),    .M2_BUS_RD_ADDR       (M2_BUS_RD_ADDR       ),    .M3_BUS_RD_ADDR       (M3_BUS_RD_ADDR       ),
    .M0_BUS_RD_ADDR_LEN   (M0_BUS_RD_ADDR_LEN   ),    .M1_BUS_RD_ADDR_LEN   (M1_BUS_RD_ADDR_LEN   ),    .M2_BUS_RD_ADDR_LEN   (M2_BUS_RD_ADDR_LEN   ),    .M3_BUS_RD_ADDR_LEN   (M3_BUS_RD_ADDR_LEN   ),
    .M0_BUS_RD_ADDR_BURST (M0_BUS_RD_ADDR_BURST ),    .M1_BUS_RD_ADDR_BURST (M1_BUS_RD_ADDR_BURST ),    .M2_BUS_RD_ADDR_BURST (M2_BUS_RD_ADDR_BURST ),    .M3_BUS_RD_ADDR_BURST (M3_BUS_RD_ADDR_BURST ),
    .M0_BUS_RD_ADDR_VALID (M0_BUS_RD_ADDR_VALID ),    .M1_BUS_RD_ADDR_VALID (M1_BUS_RD_ADDR_VALID ),    .M2_BUS_RD_ADDR_VALID (M2_BUS_RD_ADDR_VALID ),    .M3_BUS_RD_ADDR_VALID (M3_BUS_RD_ADDR_VALID ),
    .M0_BUS_RD_ADDR_READY (M0_BUS_RD_ADDR_READY ),    .M1_BUS_RD_ADDR_READY (M1_BUS_RD_ADDR_READY ),    .M2_BUS_RD_ADDR_READY (M2_BUS_RD_ADDR_READY ),    .M3_BUS_RD_ADDR_READY (M3_BUS_RD_ADDR_READY ),
    .M0_BUS_RD_BACK_ID    (M0_BUS_RD_BACK_ID    ),    .M1_BUS_RD_BACK_ID    (M1_BUS_RD_BACK_ID    ),    .M2_BUS_RD_BACK_ID    (M2_BUS_RD_BACK_ID    ),    .M3_BUS_RD_BACK_ID    (M3_BUS_RD_BACK_ID    ),
    .M0_BUS_RD_DATA       (M0_BUS_RD_DATA       ),    .M1_BUS_RD_DATA       (M1_BUS_RD_DATA       ),    .M2_BUS_RD_DATA       (M2_BUS_RD_DATA       ),    .M3_BUS_RD_DATA       (M3_BUS_RD_DATA       ),
    .M0_BUS_RD_DATA_RESP  (M0_BUS_RD_DATA_RESP  ),    .M1_BUS_RD_DATA_RESP  (M1_BUS_RD_DATA_RESP  ),    .M2_BUS_RD_DATA_RESP  (M2_BUS_RD_DATA_RESP  ),    .M3_BUS_RD_DATA_RESP  (M3_BUS_RD_DATA_RESP  ),
    .M0_BUS_RD_DATA_LAST  (M0_BUS_RD_DATA_LAST  ),    .M1_BUS_RD_DATA_LAST  (M1_BUS_RD_DATA_LAST  ),    .M2_BUS_RD_DATA_LAST  (M2_BUS_RD_DATA_LAST  ),    .M3_BUS_RD_DATA_LAST  (M3_BUS_RD_DATA_LAST  ),
    .M0_BUS_RD_DATA_VALID (M0_BUS_RD_DATA_VALID ),    .M1_BUS_RD_DATA_VALID (M1_BUS_RD_DATA_VALID ),    .M2_BUS_RD_DATA_VALID (M2_BUS_RD_DATA_VALID ),    .M3_BUS_RD_DATA_VALID (M3_BUS_RD_DATA_VALID ),
    .M0_BUS_RD_DATA_READY (M0_BUS_RD_DATA_READY ),    .M1_BUS_RD_DATA_READY (M1_BUS_RD_DATA_READY ),    .M2_BUS_RD_DATA_READY (M2_BUS_RD_DATA_READY ),    .M3_BUS_RD_DATA_READY (M3_BUS_RD_DATA_READY ),

    .S0_BUS_WR_ADDR_ID    (S0_BUS_WR_ADDR_ID    ),    .S1_BUS_WR_ADDR_ID    (S1_BUS_WR_ADDR_ID    ),    .S2_BUS_WR_ADDR_ID    (S2_BUS_WR_ADDR_ID    ),    .S3_BUS_WR_ADDR_ID    (S3_BUS_WR_ADDR_ID    ),
    .S0_BUS_WR_ADDR       (S0_BUS_WR_ADDR       ),    .S1_BUS_WR_ADDR       (S1_BUS_WR_ADDR       ),    .S2_BUS_WR_ADDR       (S2_BUS_WR_ADDR       ),    .S3_BUS_WR_ADDR       (S3_BUS_WR_ADDR       ),
    .S0_BUS_WR_ADDR_LEN   (S0_BUS_WR_ADDR_LEN   ),    .S1_BUS_WR_ADDR_LEN   (S1_BUS_WR_ADDR_LEN   ),    .S2_BUS_WR_ADDR_LEN   (S2_BUS_WR_ADDR_LEN   ),    .S3_BUS_WR_ADDR_LEN   (S3_BUS_WR_ADDR_LEN   ),
    .S0_BUS_WR_ADDR_BURST (S0_BUS_WR_ADDR_BURST ),    .S1_BUS_WR_ADDR_BURST (S1_BUS_WR_ADDR_BURST ),    .S2_BUS_WR_ADDR_BURST (S2_BUS_WR_ADDR_BURST ),    .S3_BUS_WR_ADDR_BURST (S3_BUS_WR_ADDR_BURST ),
    .S0_BUS_WR_ADDR_VALID (S0_BUS_WR_ADDR_VALID ),    .S1_BUS_WR_ADDR_VALID (S1_BUS_WR_ADDR_VALID ),    .S2_BUS_WR_ADDR_VALID (S2_BUS_WR_ADDR_VALID ),    .S3_BUS_WR_ADDR_VALID (S3_BUS_WR_ADDR_VALID ),
    .S0_BUS_WR_ADDR_READY (S0_BUS_WR_ADDR_READY ),    .S1_BUS_WR_ADDR_READY (S1_BUS_WR_ADDR_READY ),    .S2_BUS_WR_ADDR_READY (S2_BUS_WR_ADDR_READY ),    .S3_BUS_WR_ADDR_READY (S3_BUS_WR_ADDR_READY ),
    .S0_BUS_WR_DATA       (S0_BUS_WR_DATA       ),    .S1_BUS_WR_DATA       (S1_BUS_WR_DATA       ),    .S2_BUS_WR_DATA       (S2_BUS_WR_DATA       ),    .S3_BUS_WR_DATA       (S3_BUS_WR_DATA       ),
    .S0_BUS_WR_STRB       (S0_BUS_WR_STRB       ),    .S1_BUS_WR_STRB       (S1_BUS_WR_STRB       ),    .S2_BUS_WR_STRB       (S2_BUS_WR_STRB       ),    .S3_BUS_WR_STRB       (S3_BUS_WR_STRB       ),
    .S0_BUS_WR_DATA_LAST  (S0_BUS_WR_DATA_LAST  ),    .S1_BUS_WR_DATA_LAST  (S1_BUS_WR_DATA_LAST  ),    .S2_BUS_WR_DATA_LAST  (S2_BUS_WR_DATA_LAST  ),    .S3_BUS_WR_DATA_LAST  (S3_BUS_WR_DATA_LAST  ),
    .S0_BUS_WR_DATA_VALID (S0_BUS_WR_DATA_VALID ),    .S1_BUS_WR_DATA_VALID (S1_BUS_WR_DATA_VALID ),    .S2_BUS_WR_DATA_VALID (S2_BUS_WR_DATA_VALID ),    .S3_BUS_WR_DATA_VALID (S3_BUS_WR_DATA_VALID ),
    .S0_BUS_WR_DATA_READY (S0_BUS_WR_DATA_READY ),    .S1_BUS_WR_DATA_READY (S1_BUS_WR_DATA_READY ),    .S2_BUS_WR_DATA_READY (S2_BUS_WR_DATA_READY ),    .S3_BUS_WR_DATA_READY (S3_BUS_WR_DATA_READY ),
    .S0_BUS_WR_BACK_ID    (S0_BUS_WR_BACK_ID    ),    .S1_BUS_WR_BACK_ID    (S1_BUS_WR_BACK_ID    ),    .S2_BUS_WR_BACK_ID    (S2_BUS_WR_BACK_ID    ),    .S3_BUS_WR_BACK_ID    (S3_BUS_WR_BACK_ID    ),
    .S0_BUS_WR_BACK_RESP  (S0_BUS_WR_BACK_RESP  ),    .S1_BUS_WR_BACK_RESP  (S1_BUS_WR_BACK_RESP  ),    .S2_BUS_WR_BACK_RESP  (S2_BUS_WR_BACK_RESP  ),    .S3_BUS_WR_BACK_RESP  (S3_BUS_WR_BACK_RESP  ),
    .S0_BUS_WR_BACK_VALID (S0_BUS_WR_BACK_VALID ),    .S1_BUS_WR_BACK_VALID (S1_BUS_WR_BACK_VALID ),    .S2_BUS_WR_BACK_VALID (S2_BUS_WR_BACK_VALID ),    .S3_BUS_WR_BACK_VALID (S3_BUS_WR_BACK_VALID ),
    .S0_BUS_WR_BACK_READY (S0_BUS_WR_BACK_READY ),    .S1_BUS_WR_BACK_READY (S1_BUS_WR_BACK_READY ),    .S2_BUS_WR_BACK_READY (S2_BUS_WR_BACK_READY ),    .S3_BUS_WR_BACK_READY (S3_BUS_WR_BACK_READY ),
    .S0_BUS_RD_ADDR_ID    (S0_BUS_RD_ADDR_ID    ),    .S1_BUS_RD_ADDR_ID    (S1_BUS_RD_ADDR_ID    ),    .S2_BUS_RD_ADDR_ID    (S2_BUS_RD_ADDR_ID    ),    .S3_BUS_RD_ADDR_ID    (S3_BUS_RD_ADDR_ID    ),
    .S0_BUS_RD_ADDR       (S0_BUS_RD_ADDR       ),    .S1_BUS_RD_ADDR       (S1_BUS_RD_ADDR       ),    .S2_BUS_RD_ADDR       (S2_BUS_RD_ADDR       ),    .S3_BUS_RD_ADDR       (S3_BUS_RD_ADDR       ),
    .S0_BUS_RD_ADDR_LEN   (S0_BUS_RD_ADDR_LEN   ),    .S1_BUS_RD_ADDR_LEN   (S1_BUS_RD_ADDR_LEN   ),    .S2_BUS_RD_ADDR_LEN   (S2_BUS_RD_ADDR_LEN   ),    .S3_BUS_RD_ADDR_LEN   (S3_BUS_RD_ADDR_LEN   ),
    .S0_BUS_RD_ADDR_BURST (S0_BUS_RD_ADDR_BURST ),    .S1_BUS_RD_ADDR_BURST (S1_BUS_RD_ADDR_BURST ),    .S2_BUS_RD_ADDR_BURST (S2_BUS_RD_ADDR_BURST ),    .S3_BUS_RD_ADDR_BURST (S3_BUS_RD_ADDR_BURST ),
    .S0_BUS_RD_ADDR_VALID (S0_BUS_RD_ADDR_VALID ),    .S1_BUS_RD_ADDR_VALID (S1_BUS_RD_ADDR_VALID ),    .S2_BUS_RD_ADDR_VALID (S2_BUS_RD_ADDR_VALID ),    .S3_BUS_RD_ADDR_VALID (S3_BUS_RD_ADDR_VALID ),
    .S0_BUS_RD_ADDR_READY (S0_BUS_RD_ADDR_READY ),    .S1_BUS_RD_ADDR_READY (S1_BUS_RD_ADDR_READY ),    .S2_BUS_RD_ADDR_READY (S2_BUS_RD_ADDR_READY ),    .S3_BUS_RD_ADDR_READY (S3_BUS_RD_ADDR_READY ),
    .S0_BUS_RD_BACK_ID    (S0_BUS_RD_BACK_ID    ),    .S1_BUS_RD_BACK_ID    (S1_BUS_RD_BACK_ID    ),    .S2_BUS_RD_BACK_ID    (S2_BUS_RD_BACK_ID    ),    .S3_BUS_RD_BACK_ID    (S3_BUS_RD_BACK_ID    ),
    .S0_BUS_RD_DATA       (S0_BUS_RD_DATA       ),    .S1_BUS_RD_DATA       (S1_BUS_RD_DATA       ),    .S2_BUS_RD_DATA       (S2_BUS_RD_DATA       ),    .S3_BUS_RD_DATA       (S3_BUS_RD_DATA       ),
    .S0_BUS_RD_DATA_RESP  (S0_BUS_RD_DATA_RESP  ),    .S1_BUS_RD_DATA_RESP  (S1_BUS_RD_DATA_RESP  ),    .S2_BUS_RD_DATA_RESP  (S2_BUS_RD_DATA_RESP  ),    .S3_BUS_RD_DATA_RESP  (S3_BUS_RD_DATA_RESP  ),
    .S0_BUS_RD_DATA_LAST  (S0_BUS_RD_DATA_LAST  ),    .S1_BUS_RD_DATA_LAST  (S1_BUS_RD_DATA_LAST  ),    .S2_BUS_RD_DATA_LAST  (S2_BUS_RD_DATA_LAST  ),    .S3_BUS_RD_DATA_LAST  (S3_BUS_RD_DATA_LAST  ),
    .S0_BUS_RD_DATA_VALID (S0_BUS_RD_DATA_VALID ),    .S1_BUS_RD_DATA_VALID (S1_BUS_RD_DATA_VALID ),    .S2_BUS_RD_DATA_VALID (S2_BUS_RD_DATA_VALID ),    .S3_BUS_RD_DATA_VALID (S3_BUS_RD_DATA_VALID ),
    .S0_BUS_RD_DATA_READY (S0_BUS_RD_DATA_READY ),    .S1_BUS_RD_DATA_READY (S1_BUS_RD_DATA_READY ),    .S2_BUS_RD_DATA_READY (S2_BUS_RD_DATA_READY ),    .S3_BUS_RD_DATA_READY (S3_BUS_RD_DATA_READY ),

    .M0_CLK               (M0_CLK               ),    .M1_CLK               (M1_CLK               ),    .M2_CLK               (M2_CLK               ),    .M3_CLK               (M3_CLK               ),
    .M0_RSTN              (M0_RSTN              ),    .M1_RSTN              (M1_RSTN              ),    .M2_RSTN              (M2_RSTN              ),    .M3_RSTN              (M3_RSTN              ),
    .M0_WR_ADDR_ID        (M0_WR_ADDR_ID        ),    .M1_WR_ADDR_ID        (M1_WR_ADDR_ID        ),    .M2_WR_ADDR_ID        (M2_WR_ADDR_ID        ),    .M3_WR_ADDR_ID        (M3_WR_ADDR_ID        ),
    .M0_WR_ADDR           (M0_WR_ADDR           ),    .M1_WR_ADDR           (M1_WR_ADDR           ),    .M2_WR_ADDR           (M2_WR_ADDR           ),    .M3_WR_ADDR           (M3_WR_ADDR           ),
    .M0_WR_ADDR_LEN       (M0_WR_ADDR_LEN       ),    .M1_WR_ADDR_LEN       (M1_WR_ADDR_LEN       ),    .M2_WR_ADDR_LEN       (M2_WR_ADDR_LEN       ),    .M3_WR_ADDR_LEN       (M3_WR_ADDR_LEN       ),
    .M0_WR_ADDR_BURST     (M0_WR_ADDR_BURST     ),    .M1_WR_ADDR_BURST     (M1_WR_ADDR_BURST     ),    .M2_WR_ADDR_BURST     (M2_WR_ADDR_BURST     ),    .M3_WR_ADDR_BURST     (M3_WR_ADDR_BURST     ),
    .M0_WR_ADDR_VALID     (M0_WR_ADDR_VALID     ),    .M1_WR_ADDR_VALID     (M1_WR_ADDR_VALID     ),    .M2_WR_ADDR_VALID     (M2_WR_ADDR_VALID     ),    .M3_WR_ADDR_VALID     (M3_WR_ADDR_VALID     ),
    .M0_WR_ADDR_READY     (M0_WR_ADDR_READY     ),    .M1_WR_ADDR_READY     (M1_WR_ADDR_READY     ),    .M2_WR_ADDR_READY     (M2_WR_ADDR_READY     ),    .M3_WR_ADDR_READY     (M3_WR_ADDR_READY     ),
    .M0_WR_DATA           (M0_WR_DATA           ),    .M1_WR_DATA           (M1_WR_DATA           ),    .M2_WR_DATA           (M2_WR_DATA           ),    .M3_WR_DATA           (M3_WR_DATA           ),
    .M0_WR_STRB           (M0_WR_STRB           ),    .M1_WR_STRB           (M1_WR_STRB           ),    .M2_WR_STRB           (M2_WR_STRB           ),    .M3_WR_STRB           (M3_WR_STRB           ),
    .M0_WR_DATA_LAST      (M0_WR_DATA_LAST      ),    .M1_WR_DATA_LAST      (M1_WR_DATA_LAST      ),    .M2_WR_DATA_LAST      (M2_WR_DATA_LAST      ),    .M3_WR_DATA_LAST      (M3_WR_DATA_LAST      ),
    .M0_WR_DATA_VALID     (M0_WR_DATA_VALID     ),    .M1_WR_DATA_VALID     (M1_WR_DATA_VALID     ),    .M2_WR_DATA_VALID     (M2_WR_DATA_VALID     ),    .M3_WR_DATA_VALID     (M3_WR_DATA_VALID     ),
    .M0_WR_DATA_READY     (M0_WR_DATA_READY     ),    .M1_WR_DATA_READY     (M1_WR_DATA_READY     ),    .M2_WR_DATA_READY     (M2_WR_DATA_READY     ),    .M3_WR_DATA_READY     (M3_WR_DATA_READY     ),
    .M0_WR_BACK_ID        (M0_WR_BACK_ID        ),    .M1_WR_BACK_ID        (M1_WR_BACK_ID        ),    .M2_WR_BACK_ID        (M2_WR_BACK_ID        ),    .M3_WR_BACK_ID        (M3_WR_BACK_ID        ),
    .M0_WR_BACK_RESP      (M0_WR_BACK_RESP      ),    .M1_WR_BACK_RESP      (M1_WR_BACK_RESP      ),    .M2_WR_BACK_RESP      (M2_WR_BACK_RESP      ),    .M3_WR_BACK_RESP      (M3_WR_BACK_RESP      ),
    .M0_WR_BACK_VALID     (M0_WR_BACK_VALID     ),    .M1_WR_BACK_VALID     (M1_WR_BACK_VALID     ),    .M2_WR_BACK_VALID     (M2_WR_BACK_VALID     ),    .M3_WR_BACK_VALID     (M3_WR_BACK_VALID     ),
    .M0_WR_BACK_READY     (M0_WR_BACK_READY     ),    .M1_WR_BACK_READY     (M1_WR_BACK_READY     ),    .M2_WR_BACK_READY     (M2_WR_BACK_READY     ),    .M3_WR_BACK_READY     (M3_WR_BACK_READY     ),
    .M0_RD_ADDR_ID        (M0_RD_ADDR_ID        ),    .M1_RD_ADDR_ID        (M1_RD_ADDR_ID        ),    .M2_RD_ADDR_ID        (M2_RD_ADDR_ID        ),    .M3_RD_ADDR_ID        (M3_RD_ADDR_ID        ),
    .M0_RD_ADDR           (M0_RD_ADDR           ),    .M1_RD_ADDR           (M1_RD_ADDR           ),    .M2_RD_ADDR           (M2_RD_ADDR           ),    .M3_RD_ADDR           (M3_RD_ADDR           ),
    .M0_RD_ADDR_LEN       (M0_RD_ADDR_LEN       ),    .M1_RD_ADDR_LEN       (M1_RD_ADDR_LEN       ),    .M2_RD_ADDR_LEN       (M2_RD_ADDR_LEN       ),    .M3_RD_ADDR_LEN       (M3_RD_ADDR_LEN       ),
    .M0_RD_ADDR_BURST     (M0_RD_ADDR_BURST     ),    .M1_RD_ADDR_BURST     (M1_RD_ADDR_BURST     ),    .M2_RD_ADDR_BURST     (M2_RD_ADDR_BURST     ),    .M3_RD_ADDR_BURST     (M3_RD_ADDR_BURST     ),
    .M0_RD_ADDR_VALID     (M0_RD_ADDR_VALID     ),    .M1_RD_ADDR_VALID     (M1_RD_ADDR_VALID     ),    .M2_RD_ADDR_VALID     (M2_RD_ADDR_VALID     ),    .M3_RD_ADDR_VALID     (M3_RD_ADDR_VALID     ),
    .M0_RD_ADDR_READY     (M0_RD_ADDR_READY     ),    .M1_RD_ADDR_READY     (M1_RD_ADDR_READY     ),    .M2_RD_ADDR_READY     (M2_RD_ADDR_READY     ),    .M3_RD_ADDR_READY     (M3_RD_ADDR_READY     ),
    .M0_RD_BACK_ID        (M0_RD_BACK_ID        ),    .M1_RD_BACK_ID        (M1_RD_BACK_ID        ),    .M2_RD_BACK_ID        (M2_RD_BACK_ID        ),    .M3_RD_BACK_ID        (M3_RD_BACK_ID        ),
    .M0_RD_DATA           (M0_RD_DATA           ),    .M1_RD_DATA           (M1_RD_DATA           ),    .M2_RD_DATA           (M2_RD_DATA           ),    .M3_RD_DATA           (M3_RD_DATA           ),
    .M0_RD_DATA_RESP      (M0_RD_DATA_RESP      ),    .M1_RD_DATA_RESP      (M1_RD_DATA_RESP      ),    .M2_RD_DATA_RESP      (M2_RD_DATA_RESP      ),    .M3_RD_DATA_RESP      (M3_RD_DATA_RESP      ),
    .M0_RD_DATA_LAST      (M0_RD_DATA_LAST      ),    .M1_RD_DATA_LAST      (M1_RD_DATA_LAST      ),    .M2_RD_DATA_LAST      (M2_RD_DATA_LAST      ),    .M3_RD_DATA_LAST      (M3_RD_DATA_LAST      ),
    .M0_RD_DATA_VALID     (M0_RD_DATA_VALID     ),    .M1_RD_DATA_VALID     (M1_RD_DATA_VALID     ),    .M2_RD_DATA_VALID     (M2_RD_DATA_VALID     ),    .M3_RD_DATA_VALID     (M3_RD_DATA_VALID     ),
    .M0_RD_DATA_READY     (M0_RD_DATA_READY     ),    .M1_RD_DATA_READY     (M1_RD_DATA_READY     ),    .M2_RD_DATA_READY     (M2_RD_DATA_READY     ),    .M3_RD_DATA_READY     (M3_RD_DATA_READY     ),

    .S0_CLK               (S0_CLK               ),    .S1_CLK               (S1_CLK               ),    .S2_CLK               (S2_CLK               ),    .S3_CLK               (S3_CLK               ),
    .S0_RSTN              (S0_RSTN              ),    .S1_RSTN              (S1_RSTN              ),    .S2_RSTN              (S2_RSTN              ),    .S3_RSTN              (S3_RSTN              ),
    .S0_WR_ADDR_ID        (S0_WR_ADDR_ID        ),    .S1_WR_ADDR_ID        (S1_WR_ADDR_ID        ),    .S2_WR_ADDR_ID        (S2_WR_ADDR_ID        ),    .S3_WR_ADDR_ID        (S3_WR_ADDR_ID        ),
    .S0_WR_ADDR           (S0_WR_ADDR           ),    .S1_WR_ADDR           (S1_WR_ADDR           ),    .S2_WR_ADDR           (S2_WR_ADDR           ),    .S3_WR_ADDR           (S3_WR_ADDR           ),
    .S0_WR_ADDR_LEN       (S0_WR_ADDR_LEN       ),    .S1_WR_ADDR_LEN       (S1_WR_ADDR_LEN       ),    .S2_WR_ADDR_LEN       (S2_WR_ADDR_LEN       ),    .S3_WR_ADDR_LEN       (S3_WR_ADDR_LEN       ),
    .S0_WR_ADDR_BURST     (S0_WR_ADDR_BURST     ),    .S1_WR_ADDR_BURST     (S1_WR_ADDR_BURST     ),    .S2_WR_ADDR_BURST     (S2_WR_ADDR_BURST     ),    .S3_WR_ADDR_BURST     (S3_WR_ADDR_BURST     ),
    .S0_WR_ADDR_VALID     (S0_WR_ADDR_VALID     ),    .S1_WR_ADDR_VALID     (S1_WR_ADDR_VALID     ),    .S2_WR_ADDR_VALID     (S2_WR_ADDR_VALID     ),    .S3_WR_ADDR_VALID     (S3_WR_ADDR_VALID     ),
    .S0_WR_ADDR_READY     (S0_WR_ADDR_READY     ),    .S1_WR_ADDR_READY     (S1_WR_ADDR_READY     ),    .S2_WR_ADDR_READY     (S2_WR_ADDR_READY     ),    .S3_WR_ADDR_READY     (S3_WR_ADDR_READY     ),
    .S0_WR_DATA           (S0_WR_DATA           ),    .S1_WR_DATA           (S1_WR_DATA           ),    .S2_WR_DATA           (S2_WR_DATA           ),    .S3_WR_DATA           (S3_WR_DATA           ),
    .S0_WR_STRB           (S0_WR_STRB           ),    .S1_WR_STRB           (S1_WR_STRB           ),    .S2_WR_STRB           (S2_WR_STRB           ),    .S3_WR_STRB           (S3_WR_STRB           ),
    .S0_WR_DATA_LAST      (S0_WR_DATA_LAST      ),    .S1_WR_DATA_LAST      (S1_WR_DATA_LAST      ),    .S2_WR_DATA_LAST      (S2_WR_DATA_LAST      ),    .S3_WR_DATA_LAST      (S3_WR_DATA_LAST      ),
    .S0_WR_DATA_VALID     (S0_WR_DATA_VALID     ),    .S1_WR_DATA_VALID     (S1_WR_DATA_VALID     ),    .S2_WR_DATA_VALID     (S2_WR_DATA_VALID     ),    .S3_WR_DATA_VALID     (S3_WR_DATA_VALID     ),
    .S0_WR_DATA_READY     (S0_WR_DATA_READY     ),    .S1_WR_DATA_READY     (S1_WR_DATA_READY     ),    .S2_WR_DATA_READY     (S2_WR_DATA_READY     ),    .S3_WR_DATA_READY     (S3_WR_DATA_READY     ),
    .S0_WR_BACK_ID        (S0_WR_BACK_ID        ),    .S1_WR_BACK_ID        (S1_WR_BACK_ID        ),    .S2_WR_BACK_ID        (S2_WR_BACK_ID        ),    .S3_WR_BACK_ID        (S3_WR_BACK_ID        ),
    .S0_WR_BACK_RESP      (S0_WR_BACK_RESP      ),    .S1_WR_BACK_RESP      (S1_WR_BACK_RESP      ),    .S2_WR_BACK_RESP      (S2_WR_BACK_RESP      ),    .S3_WR_BACK_RESP      (S3_WR_BACK_RESP      ),
    .S0_WR_BACK_VALID     (S0_WR_BACK_VALID     ),    .S1_WR_BACK_VALID     (S1_WR_BACK_VALID     ),    .S2_WR_BACK_VALID     (S2_WR_BACK_VALID     ),    .S3_WR_BACK_VALID     (S3_WR_BACK_VALID     ),
    .S0_WR_BACK_READY     (S0_WR_BACK_READY     ),    .S1_WR_BACK_READY     (S1_WR_BACK_READY     ),    .S2_WR_BACK_READY     (S2_WR_BACK_READY     ),    .S3_WR_BACK_READY     (S3_WR_BACK_READY     ),
    .S0_RD_ADDR_ID        (S0_RD_ADDR_ID        ),    .S1_RD_ADDR_ID        (S1_RD_ADDR_ID        ),    .S2_RD_ADDR_ID        (S2_RD_ADDR_ID        ),    .S3_RD_ADDR_ID        (S3_RD_ADDR_ID        ),
    .S0_RD_ADDR           (S0_RD_ADDR           ),    .S1_RD_ADDR           (S1_RD_ADDR           ),    .S2_RD_ADDR           (S2_RD_ADDR           ),    .S3_RD_ADDR           (S3_RD_ADDR           ),
    .S0_RD_ADDR_LEN       (S0_RD_ADDR_LEN       ),    .S1_RD_ADDR_LEN       (S1_RD_ADDR_LEN       ),    .S2_RD_ADDR_LEN       (S2_RD_ADDR_LEN       ),    .S3_RD_ADDR_LEN       (S3_RD_ADDR_LEN       ),
    .S0_RD_ADDR_BURST     (S0_RD_ADDR_BURST     ),    .S1_RD_ADDR_BURST     (S1_RD_ADDR_BURST     ),    .S2_RD_ADDR_BURST     (S2_RD_ADDR_BURST     ),    .S3_RD_ADDR_BURST     (S3_RD_ADDR_BURST     ),
    .S0_RD_ADDR_VALID     (S0_RD_ADDR_VALID     ),    .S1_RD_ADDR_VALID     (S1_RD_ADDR_VALID     ),    .S2_RD_ADDR_VALID     (S2_RD_ADDR_VALID     ),    .S3_RD_ADDR_VALID     (S3_RD_ADDR_VALID     ),
    .S0_RD_ADDR_READY     (S0_RD_ADDR_READY     ),    .S1_RD_ADDR_READY     (S1_RD_ADDR_READY     ),    .S2_RD_ADDR_READY     (S2_RD_ADDR_READY     ),    .S3_RD_ADDR_READY     (S3_RD_ADDR_READY     ),
    .S0_RD_BACK_ID        (S0_RD_BACK_ID        ),    .S1_RD_BACK_ID        (S1_RD_BACK_ID        ),    .S2_RD_BACK_ID        (S2_RD_BACK_ID        ),    .S3_RD_BACK_ID        (S3_RD_BACK_ID        ),
    .S0_RD_DATA           (S0_RD_DATA           ),    .S1_RD_DATA           (S1_RD_DATA           ),    .S2_RD_DATA           (S2_RD_DATA           ),    .S3_RD_DATA           (S3_RD_DATA           ),
    .S0_RD_DATA_RESP      (S0_RD_DATA_RESP      ),    .S1_RD_DATA_RESP      (S1_RD_DATA_RESP      ),    .S2_RD_DATA_RESP      (S2_RD_DATA_RESP      ),    .S3_RD_DATA_RESP      (S3_RD_DATA_RESP      ),
    .S0_RD_DATA_LAST      (S0_RD_DATA_LAST      ),    .S1_RD_DATA_LAST      (S1_RD_DATA_LAST      ),    .S2_RD_DATA_LAST      (S2_RD_DATA_LAST      ),    .S3_RD_DATA_LAST      (S3_RD_DATA_LAST      ),
    .S0_RD_DATA_VALID     (S0_RD_DATA_VALID     ),    .S1_RD_DATA_VALID     (S1_RD_DATA_VALID     ),    .S2_RD_DATA_VALID     (S2_RD_DATA_VALID     ),    .S3_RD_DATA_VALID     (S3_RD_DATA_VALID     ),
    .S0_RD_DATA_READY     (S0_RD_DATA_READY     ),    .S1_RD_DATA_READY     (S1_RD_DATA_READY     ),    .S2_RD_DATA_READY     (S2_RD_DATA_READY     ),    .S3_RD_DATA_READY     (S3_RD_DATA_READY     )
);

axi_interconnect  #(
    .S0_START_ADDR  (S0_START_ADDR),
    .S0_END_ADDR    (S0_END_ADDR  ),
    .S1_START_ADDR  (S1_START_ADDR),
    .S1_END_ADDR    (S1_END_ADDR  ),
    .S2_START_ADDR  (S2_START_ADDR),
    .S2_END_ADDR    (S2_END_ADDR  ),
    .S3_START_ADDR  (S3_START_ADDR),
    .S3_END_ADDR    (S3_END_ADDR  )
)axi_interconnect_inst(
    .BUS_CLK          (BUS_CLK              ),
    .BUS_RSTN         (BUS_RSTN             ),
    .M0_WR_ADDR_ID    (M0_BUS_WR_ADDR_ID    ),    .M1_WR_ADDR_ID    (M1_BUS_WR_ADDR_ID    ),    .M2_WR_ADDR_ID    (M2_BUS_WR_ADDR_ID    ),    .M3_WR_ADDR_ID    (M3_BUS_WR_ADDR_ID    ),
    .M0_WR_ADDR       (M0_BUS_WR_ADDR       ),    .M1_WR_ADDR       (M1_BUS_WR_ADDR       ),    .M2_WR_ADDR       (M2_BUS_WR_ADDR       ),    .M3_WR_ADDR       (M3_BUS_WR_ADDR       ),
    .M0_WR_ADDR_LEN   (M0_BUS_WR_ADDR_LEN   ),    .M1_WR_ADDR_LEN   (M1_BUS_WR_ADDR_LEN   ),    .M2_WR_ADDR_LEN   (M2_BUS_WR_ADDR_LEN   ),    .M3_WR_ADDR_LEN   (M3_BUS_WR_ADDR_LEN   ),
    .M0_WR_ADDR_BURST (M0_BUS_WR_ADDR_BURST ),    .M1_WR_ADDR_BURST (M1_BUS_WR_ADDR_BURST ),    .M2_WR_ADDR_BURST (M2_BUS_WR_ADDR_BURST ),    .M3_WR_ADDR_BURST (M3_BUS_WR_ADDR_BURST ),
    .M0_WR_ADDR_VALID (M0_BUS_WR_ADDR_VALID ),    .M1_WR_ADDR_VALID (M1_BUS_WR_ADDR_VALID ),    .M2_WR_ADDR_VALID (M2_BUS_WR_ADDR_VALID ),    .M3_WR_ADDR_VALID (M3_BUS_WR_ADDR_VALID ),
    .M0_WR_ADDR_READY (M0_BUS_WR_ADDR_READY ),    .M1_WR_ADDR_READY (M1_BUS_WR_ADDR_READY ),    .M2_WR_ADDR_READY (M2_BUS_WR_ADDR_READY ),    .M3_WR_ADDR_READY (M3_BUS_WR_ADDR_READY ),
    .M0_WR_DATA       (M0_BUS_WR_DATA       ),    .M1_WR_DATA       (M1_BUS_WR_DATA       ),    .M2_WR_DATA       (M2_BUS_WR_DATA       ),    .M3_WR_DATA       (M3_BUS_WR_DATA       ),
    .M0_WR_STRB       (M0_BUS_WR_STRB       ),    .M1_WR_STRB       (M1_BUS_WR_STRB       ),    .M2_WR_STRB       (M2_BUS_WR_STRB       ),    .M3_WR_STRB       (M3_BUS_WR_STRB       ),
    .M0_WR_DATA_LAST  (M0_BUS_WR_DATA_LAST  ),    .M1_WR_DATA_LAST  (M1_BUS_WR_DATA_LAST  ),    .M2_WR_DATA_LAST  (M2_BUS_WR_DATA_LAST  ),    .M3_WR_DATA_LAST  (M3_BUS_WR_DATA_LAST  ),
    .M0_WR_DATA_VALID (M0_BUS_WR_DATA_VALID ),    .M1_WR_DATA_VALID (M1_BUS_WR_DATA_VALID ),    .M2_WR_DATA_VALID (M2_BUS_WR_DATA_VALID ),    .M3_WR_DATA_VALID (M3_BUS_WR_DATA_VALID ),
    .M0_WR_DATA_READY (M0_BUS_WR_DATA_READY ),    .M1_WR_DATA_READY (M1_BUS_WR_DATA_READY ),    .M2_WR_DATA_READY (M2_BUS_WR_DATA_READY ),    .M3_WR_DATA_READY (M3_BUS_WR_DATA_READY ),
    .M0_WR_BACK_ID    (M0_BUS_WR_BACK_ID    ),    .M1_WR_BACK_ID    (M1_BUS_WR_BACK_ID    ),    .M2_WR_BACK_ID    (M2_BUS_WR_BACK_ID    ),    .M3_WR_BACK_ID    (M3_BUS_WR_BACK_ID    ),
    .M0_WR_BACK_RESP  (M0_BUS_WR_BACK_RESP  ),    .M1_WR_BACK_RESP  (M1_BUS_WR_BACK_RESP  ),    .M2_WR_BACK_RESP  (M2_BUS_WR_BACK_RESP  ),    .M3_WR_BACK_RESP  (M3_BUS_WR_BACK_RESP  ),
    .M0_WR_BACK_VALID (M0_BUS_WR_BACK_VALID ),    .M1_WR_BACK_VALID (M1_BUS_WR_BACK_VALID ),    .M2_WR_BACK_VALID (M2_BUS_WR_BACK_VALID ),    .M3_WR_BACK_VALID (M3_BUS_WR_BACK_VALID ),
    .M0_WR_BACK_READY (M0_BUS_WR_BACK_READY ),    .M1_WR_BACK_READY (M1_BUS_WR_BACK_READY ),    .M2_WR_BACK_READY (M2_BUS_WR_BACK_READY ),    .M3_WR_BACK_READY (M3_BUS_WR_BACK_READY ),
    .M0_RD_ADDR_ID    (M0_BUS_RD_ADDR_ID    ),    .M1_RD_ADDR_ID    (M1_BUS_RD_ADDR_ID    ),    .M2_RD_ADDR_ID    (M2_BUS_RD_ADDR_ID    ),    .M3_RD_ADDR_ID    (M3_BUS_RD_ADDR_ID    ),
    .M0_RD_ADDR       (M0_BUS_RD_ADDR       ),    .M1_RD_ADDR       (M1_BUS_RD_ADDR       ),    .M2_RD_ADDR       (M2_BUS_RD_ADDR       ),    .M3_RD_ADDR       (M3_BUS_RD_ADDR       ),
    .M0_RD_ADDR_LEN   (M0_BUS_RD_ADDR_LEN   ),    .M1_RD_ADDR_LEN   (M1_BUS_RD_ADDR_LEN   ),    .M2_RD_ADDR_LEN   (M2_BUS_RD_ADDR_LEN   ),    .M3_RD_ADDR_LEN   (M3_BUS_RD_ADDR_LEN   ),
    .M0_RD_ADDR_BURST (M0_BUS_RD_ADDR_BURST ),    .M1_RD_ADDR_BURST (M1_BUS_RD_ADDR_BURST ),    .M2_RD_ADDR_BURST (M2_BUS_RD_ADDR_BURST ),    .M3_RD_ADDR_BURST (M3_BUS_RD_ADDR_BURST ),
    .M0_RD_ADDR_VALID (M0_BUS_RD_ADDR_VALID ),    .M1_RD_ADDR_VALID (M1_BUS_RD_ADDR_VALID ),    .M2_RD_ADDR_VALID (M2_BUS_RD_ADDR_VALID ),    .M3_RD_ADDR_VALID (M3_BUS_RD_ADDR_VALID ),
    .M0_RD_ADDR_READY (M0_BUS_RD_ADDR_READY ),    .M1_RD_ADDR_READY (M1_BUS_RD_ADDR_READY ),    .M2_RD_ADDR_READY (M2_BUS_RD_ADDR_READY ),    .M3_RD_ADDR_READY (M3_BUS_RD_ADDR_READY ),
    .M0_RD_BACK_ID    (M0_BUS_RD_BACK_ID    ),    .M1_RD_BACK_ID    (M1_BUS_RD_BACK_ID    ),    .M2_RD_BACK_ID    (M2_BUS_RD_BACK_ID    ),    .M3_RD_BACK_ID    (M3_BUS_RD_BACK_ID    ),
    .M0_RD_DATA       (M0_BUS_RD_DATA       ),    .M1_RD_DATA       (M1_BUS_RD_DATA       ),    .M2_RD_DATA       (M2_BUS_RD_DATA       ),    .M3_RD_DATA       (M3_BUS_RD_DATA       ),
    .M0_RD_DATA_RESP  (M0_BUS_RD_DATA_RESP  ),    .M1_RD_DATA_RESP  (M1_BUS_RD_DATA_RESP  ),    .M2_RD_DATA_RESP  (M2_BUS_RD_DATA_RESP  ),    .M3_RD_DATA_RESP  (M3_BUS_RD_DATA_RESP  ),
    .M0_RD_DATA_LAST  (M0_BUS_RD_DATA_LAST  ),    .M1_RD_DATA_LAST  (M1_BUS_RD_DATA_LAST  ),    .M2_RD_DATA_LAST  (M2_BUS_RD_DATA_LAST  ),    .M3_RD_DATA_LAST  (M3_BUS_RD_DATA_LAST  ),
    .M0_RD_DATA_VALID (M0_BUS_RD_DATA_VALID ),    .M1_RD_DATA_VALID (M1_BUS_RD_DATA_VALID ),    .M2_RD_DATA_VALID (M2_BUS_RD_DATA_VALID ),    .M3_RD_DATA_VALID (M3_BUS_RD_DATA_VALID ),
    .M0_RD_DATA_READY (M0_BUS_RD_DATA_READY ),    .M1_RD_DATA_READY (M1_BUS_RD_DATA_READY ),    .M2_RD_DATA_READY (M2_BUS_RD_DATA_READY ),    .M3_RD_DATA_READY (M3_BUS_RD_DATA_READY ),

    .S0_WR_ADDR_ID    (S0_BUS_WR_ADDR_ID    ),    .S1_WR_ADDR_ID    (S1_BUS_WR_ADDR_ID    ),    .S2_WR_ADDR_ID    (S2_BUS_WR_ADDR_ID    ),    .S3_WR_ADDR_ID    (S3_BUS_WR_ADDR_ID    ),
    .S0_WR_ADDR       (S0_BUS_WR_ADDR       ),    .S1_WR_ADDR       (S1_BUS_WR_ADDR       ),    .S2_WR_ADDR       (S2_BUS_WR_ADDR       ),    .S3_WR_ADDR       (S3_BUS_WR_ADDR       ),
    .S0_WR_ADDR_LEN   (S0_BUS_WR_ADDR_LEN   ),    .S1_WR_ADDR_LEN   (S1_BUS_WR_ADDR_LEN   ),    .S2_WR_ADDR_LEN   (S2_BUS_WR_ADDR_LEN   ),    .S3_WR_ADDR_LEN   (S3_BUS_WR_ADDR_LEN   ),
    .S0_WR_ADDR_BURST (S0_BUS_WR_ADDR_BURST ),    .S1_WR_ADDR_BURST (S1_BUS_WR_ADDR_BURST ),    .S2_WR_ADDR_BURST (S2_BUS_WR_ADDR_BURST ),    .S3_WR_ADDR_BURST (S3_BUS_WR_ADDR_BURST ),
    .S0_WR_ADDR_VALID (S0_BUS_WR_ADDR_VALID ),    .S1_WR_ADDR_VALID (S1_BUS_WR_ADDR_VALID ),    .S2_WR_ADDR_VALID (S2_BUS_WR_ADDR_VALID ),    .S3_WR_ADDR_VALID (S3_BUS_WR_ADDR_VALID ),
    .S0_WR_ADDR_READY (S0_BUS_WR_ADDR_READY ),    .S1_WR_ADDR_READY (S1_BUS_WR_ADDR_READY ),    .S2_WR_ADDR_READY (S2_BUS_WR_ADDR_READY ),    .S3_WR_ADDR_READY (S3_BUS_WR_ADDR_READY ),
    .S0_WR_DATA       (S0_BUS_WR_DATA       ),    .S1_WR_DATA       (S1_BUS_WR_DATA       ),    .S2_WR_DATA       (S2_BUS_WR_DATA       ),    .S3_WR_DATA       (S3_BUS_WR_DATA       ),
    .S0_WR_STRB       (S0_BUS_WR_STRB       ),    .S1_WR_STRB       (S1_BUS_WR_STRB       ),    .S2_WR_STRB       (S2_BUS_WR_STRB       ),    .S3_WR_STRB       (S3_BUS_WR_STRB       ),
    .S0_WR_DATA_LAST  (S0_BUS_WR_DATA_LAST  ),    .S1_WR_DATA_LAST  (S1_BUS_WR_DATA_LAST  ),    .S2_WR_DATA_LAST  (S2_BUS_WR_DATA_LAST  ),    .S3_WR_DATA_LAST  (S3_BUS_WR_DATA_LAST  ),
    .S0_WR_DATA_VALID (S0_BUS_WR_DATA_VALID ),    .S1_WR_DATA_VALID (S1_BUS_WR_DATA_VALID ),    .S2_WR_DATA_VALID (S2_BUS_WR_DATA_VALID ),    .S3_WR_DATA_VALID (S3_BUS_WR_DATA_VALID ),
    .S0_WR_DATA_READY (S0_BUS_WR_DATA_READY ),    .S1_WR_DATA_READY (S1_BUS_WR_DATA_READY ),    .S2_WR_DATA_READY (S2_BUS_WR_DATA_READY ),    .S3_WR_DATA_READY (S3_BUS_WR_DATA_READY ),
    .S0_WR_BACK_ID    (S0_BUS_WR_BACK_ID    ),    .S1_WR_BACK_ID    (S1_BUS_WR_BACK_ID    ),    .S2_WR_BACK_ID    (S2_BUS_WR_BACK_ID    ),    .S3_WR_BACK_ID    (S3_BUS_WR_BACK_ID    ),
    .S0_WR_BACK_RESP  (S0_BUS_WR_BACK_RESP  ),    .S1_WR_BACK_RESP  (S1_BUS_WR_BACK_RESP  ),    .S2_WR_BACK_RESP  (S2_BUS_WR_BACK_RESP  ),    .S3_WR_BACK_RESP  (S3_BUS_WR_BACK_RESP  ),
    .S0_WR_BACK_VALID (S0_BUS_WR_BACK_VALID ),    .S1_WR_BACK_VALID (S1_BUS_WR_BACK_VALID ),    .S2_WR_BACK_VALID (S2_BUS_WR_BACK_VALID ),    .S3_WR_BACK_VALID (S3_BUS_WR_BACK_VALID ),
    .S0_WR_BACK_READY (S0_BUS_WR_BACK_READY ),    .S1_WR_BACK_READY (S1_BUS_WR_BACK_READY ),    .S2_WR_BACK_READY (S2_BUS_WR_BACK_READY ),    .S3_WR_BACK_READY (S3_BUS_WR_BACK_READY ),
    .S0_RD_ADDR_ID    (S0_BUS_RD_ADDR_ID    ),    .S1_RD_ADDR_ID    (S1_BUS_RD_ADDR_ID    ),    .S2_RD_ADDR_ID    (S2_BUS_RD_ADDR_ID    ),    .S3_RD_ADDR_ID    (S3_BUS_RD_ADDR_ID    ),
    .S0_RD_ADDR       (S0_BUS_RD_ADDR       ),    .S1_RD_ADDR       (S1_BUS_RD_ADDR       ),    .S2_RD_ADDR       (S2_BUS_RD_ADDR       ),    .S3_RD_ADDR       (S3_BUS_RD_ADDR       ),
    .S0_RD_ADDR_LEN   (S0_BUS_RD_ADDR_LEN   ),    .S1_RD_ADDR_LEN   (S1_BUS_RD_ADDR_LEN   ),    .S2_RD_ADDR_LEN   (S2_BUS_RD_ADDR_LEN   ),    .S3_RD_ADDR_LEN   (S3_BUS_RD_ADDR_LEN   ),
    .S0_RD_ADDR_BURST (S0_BUS_RD_ADDR_BURST ),    .S1_RD_ADDR_BURST (S1_BUS_RD_ADDR_BURST ),    .S2_RD_ADDR_BURST (S2_BUS_RD_ADDR_BURST ),    .S3_RD_ADDR_BURST (S3_BUS_RD_ADDR_BURST ),
    .S0_RD_ADDR_VALID (S0_BUS_RD_ADDR_VALID ),    .S1_RD_ADDR_VALID (S1_BUS_RD_ADDR_VALID ),    .S2_RD_ADDR_VALID (S2_BUS_RD_ADDR_VALID ),    .S3_RD_ADDR_VALID (S3_BUS_RD_ADDR_VALID ),
    .S0_RD_ADDR_READY (S0_BUS_RD_ADDR_READY ),    .S1_RD_ADDR_READY (S1_BUS_RD_ADDR_READY ),    .S2_RD_ADDR_READY (S2_BUS_RD_ADDR_READY ),    .S3_RD_ADDR_READY (S3_BUS_RD_ADDR_READY ),
    .S0_RD_BACK_ID    (S0_BUS_RD_BACK_ID    ),    .S1_RD_BACK_ID    (S1_BUS_RD_BACK_ID    ),    .S2_RD_BACK_ID    (S2_BUS_RD_BACK_ID    ),    .S3_RD_BACK_ID    (S3_BUS_RD_BACK_ID    ),
    .S0_RD_DATA       (S0_BUS_RD_DATA       ),    .S1_RD_DATA       (S1_BUS_RD_DATA       ),    .S2_RD_DATA       (S2_BUS_RD_DATA       ),    .S3_RD_DATA       (S3_BUS_RD_DATA       ),
    .S0_RD_DATA_RESP  (S0_BUS_RD_DATA_RESP  ),    .S1_RD_DATA_RESP  (S1_BUS_RD_DATA_RESP  ),    .S2_RD_DATA_RESP  (S2_BUS_RD_DATA_RESP  ),    .S3_RD_DATA_RESP  (S3_BUS_RD_DATA_RESP  ),
    .S0_RD_DATA_LAST  (S0_BUS_RD_DATA_LAST  ),    .S1_RD_DATA_LAST  (S1_BUS_RD_DATA_LAST  ),    .S2_RD_DATA_LAST  (S2_BUS_RD_DATA_LAST  ),    .S3_RD_DATA_LAST  (S3_BUS_RD_DATA_LAST  ),
    .S0_RD_DATA_VALID (S0_BUS_RD_DATA_VALID ),    .S1_RD_DATA_VALID (S1_BUS_RD_DATA_VALID ),    .S2_RD_DATA_VALID (S2_BUS_RD_DATA_VALID ),    .S3_RD_DATA_VALID (S3_BUS_RD_DATA_VALID ),
    .S0_RD_DATA_READY (S0_BUS_RD_DATA_READY ),    .S1_RD_DATA_READY (S1_BUS_RD_DATA_READY ),    .S2_RD_DATA_READY (S2_BUS_RD_DATA_READY ),    .S3_RD_DATA_READY (S3_BUS_RD_DATA_READY )
);





endmodule