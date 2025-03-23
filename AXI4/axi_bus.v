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
input  wire        BUS_RST,

//MASTER 0 以太网主机                    MASTER 1 主机                             MASTER 2 主机                        MASTER 3 主机
input  wire        M0_CLK          ,    input  wire        M1_CLK          ,    input  wire        M2_CLK          ,    input  wire        M3_CLK          ,
input  wire        M0_RST          ,    input  wire        M1_RST          ,    input  wire        M2_RST          ,    input  wire        M3_RST          ,
input  wire [31:0] M0_WR_ADDR      ,    input  wire [31:0] M1_WR_ADDR      ,    input  wire [31:0] M2_WR_ADDR      ,    input  wire [31:0] M3_WR_ADDR      ,
input  wire [ 7:0] M0_WR_LEN       ,    input  wire [ 7:0] M1_WR_LEN       ,    input  wire [ 7:0] M2_WR_LEN       ,    input  wire [ 7:0] M3_WR_LEN       ,
input  wire [ 1:0] M0_WR_ID        ,    input  wire [ 1:0] M1_WR_ID        ,    input  wire [ 1:0] M2_WR_ID        ,    input  wire [ 1:0] M3_WR_ID        ,
input  wire        M0_WR_ADDR_VALID,    input  wire        M1_WR_ADDR_VALID,    input  wire        M2_WR_ADDR_VALID,    input  wire        M3_WR_ADDR_VALID,
output wire        M0_WR_ADDR_READY,    output wire        M1_WR_ADDR_READY,    output wire        M2_WR_ADDR_READY,    output wire        M3_WR_ADDR_READY,

input  wire [31:0] M0_WR_DATA      ,    input  wire [31:0] M1_WR_DATA      ,    input  wire [31:0] M2_WR_DATA      ,    input  wire [31:0] M3_WR_DATA      ,
input  wire [ 3:0] M0_WR_STRB      ,    input  wire [ 3:0] M1_WR_STRB      ,    input  wire [ 3:0] M2_WR_STRB      ,    input  wire [ 3:0] M3_WR_STRB      ,
output wire [ 1:0] M0_WR_BACK_ID   ,    output wire [ 1:0] M1_WR_BACK_ID   ,    output wire [ 1:0] M2_WR_BACK_ID   ,    output wire [ 1:0] M3_WR_BACK_ID   ,
input  wire        M0_WR_DATA_VALID,    input  wire        M1_WR_DATA_VALID,    input  wire        M2_WR_DATA_VALID,    input  wire        M3_WR_DATA_VALID,
output wire        M0_WR_DATA_READY,    output wire        M1_WR_DATA_READY,    output wire        M2_WR_DATA_READY,    output wire        M3_WR_DATA_READY,
input  wire        M0_WR_DATA_LAST ,    input  wire        M1_WR_DATA_LAST ,    input  wire        M2_WR_DATA_LAST ,    input  wire        M3_WR_DATA_LAST ,

input  wire [31:0] M0_RD_ADDR      ,    input  wire [31:0] M1_RD_ADDR      ,    input  wire [31:0] M2_RD_ADDR      ,    input  wire [31:0] M3_RD_ADDR      ,
input  wire [ 7:0] M0_RD_LEN       ,    input  wire [ 7:0] M1_RD_LEN       ,    input  wire [ 7:0] M2_RD_LEN       ,    input  wire [ 7:0] M3_RD_LEN       ,
input  wire [ 1:0] M0_RD_ID        ,    input  wire [ 1:0] M1_RD_ID        ,    input  wire [ 1:0] M2_RD_ID        ,    input  wire [ 1:0] M3_RD_ID        ,
input  wire        M0_RD_ADDR_VALID,    input  wire        M1_RD_ADDR_VALID,    input  wire        M2_RD_ADDR_VALID,    input  wire        M3_RD_ADDR_VALID,
output wire        M0_RD_ADDR_READY,    output wire        M1_RD_ADDR_READY,    output wire        M2_RD_ADDR_READY,    output wire        M3_RD_ADDR_READY,
  
output wire [31:0] M0_RD_DATA      ,    output wire [31:0] M1_RD_DATA      ,    output wire [31:0] M2_RD_DATA      ,    output wire [31:0] M3_RD_DATA      ,
output wire        M0_RD_DATA_LAST ,    output wire        M1_RD_DATA_LAST ,    output wire        M2_RD_DATA_LAST ,    output wire        M3_RD_DATA_LAST ,
output wire [ 1:0] M0_RD_BACK_ID   ,    output wire [ 1:0] M1_RD_BACK_ID   ,    output wire [ 1:0] M2_RD_BACK_ID   ,    output wire [ 1:0] M3_RD_BACK_ID   ,
input  wire        M0_RD_DATA_READY,    input  wire        M1_RD_DATA_READY,    input  wire        M2_RD_DATA_READY,    input  wire        M3_RD_DATA_READY,
output wire        M0_RD_DATA_VALID,    output wire        M1_RD_DATA_VALID,    output wire        M2_RD_DATA_VALID,    output wire        M3_RD_DATA_VALID,

//SLAVE 0 DDR从机                       //SLAVE 1 JTAG从机                      //SLAVE 2 从机                          //SLAVE 3 从机
input  wire        S0_CLK          ,    input  wire        S1_CLK          ,    input  wire        S2_CLK          ,    input  wire        S3_CLK          ,
input  wire        S0_RST          ,    input  wire        S1_RST          ,    input  wire        S2_RST          ,    input  wire        S3_RST          ,
output wire [31:0] S0_WR_ADDR      ,    output wire [31:0] S1_WR_ADDR      ,    output wire [31:0] S2_WR_ADDR      ,    output wire [31:0] S3_WR_ADDR      ,
output wire [ 7:0] S0_WR_LEN       ,    output wire [ 7:0] S1_WR_LEN       ,    output wire [ 7:0] S2_WR_LEN       ,    output wire [ 7:0] S3_WR_LEN       ,
output wire [ 3:0] S0_WR_ID        ,    output wire [ 3:0] S1_WR_ID        ,    output wire [ 3:0] S2_WR_ID        ,    output wire [ 3:0] S3_WR_ID        ,
output wire        S0_WR_ADDR_VALID,    output wire        S1_WR_ADDR_VALID,    output wire        S2_WR_ADDR_VALID,    output wire        S3_WR_ADDR_VALID,
input  wire        S0_WR_ADDR_READY,    input  wire        S1_WR_ADDR_READY,    input  wire        S2_WR_ADDR_READY,    input  wire        S3_WR_ADDR_READY,

output wire [31:0] S0_WR_DATA      ,    output wire [31:0] S1_WR_DATA      ,    output wire [31:0] S2_WR_DATA      ,    output wire [31:0] S3_WR_DATA      ,
output wire [ 3:0] S0_WR_STRB      ,    output wire [ 3:0] S1_WR_STRB      ,    output wire [ 3:0] S2_WR_STRB      ,    output wire [ 3:0] S3_WR_STRB      ,
input  wire [ 3:0] S0_WR_BACK_ID   ,    input  wire [ 3:0] S1_WR_BACK_ID   ,    input  wire [ 3:0] S2_WR_BACK_ID   ,    input  wire [ 3:0] S3_WR_BACK_ID   ,
output wire        S0_WR_DATA_VALID,    output wire        S1_WR_DATA_VALID,    output wire        S2_WR_DATA_VALID,    output wire        S3_WR_DATA_VALID,
input  wire        S0_WR_DATA_READY,    input  wire        S1_WR_DATA_READY,    input  wire        S2_WR_DATA_READY,    input  wire        S3_WR_DATA_READY,
output wire        S0_WR_DATA_LAST ,    output wire        S1_WR_DATA_LAST ,    output wire        S2_WR_DATA_LAST ,    output wire        S3_WR_DATA_LAST ,

output wire [27:0] S0_RD_ADDR      ,    output wire [ 3:0] S1_RD_ADDR      ,    output wire [27:0] S2_RD_ADDR      ,    output wire [ 3:0] S3_RD_ADDR      ,
output wire [ 7:0] S0_RD_LEN       ,    output wire [ 7:0] S1_RD_LEN       ,    output wire [ 7:0] S2_RD_LEN       ,    output wire [ 7:0] S3_RD_LEN       ,
output wire [ 3:0] S0_RD_ID        ,    output wire [ 3:0] S1_RD_ID        ,    output wire [ 3:0] S2_RD_ID        ,    output wire [ 3:0] S3_RD_ID        ,
output wire        S0_RD_ADDR_VALID,    output wire        S1_RD_ADDR_VALID,    output wire        S2_RD_ADDR_VALID,    output wire        S3_RD_ADDR_VALID,
input  wire        S0_RD_ADDR_READY,    input  wire        S1_RD_ADDR_READY,    input  wire        S2_RD_ADDR_READY,    input  wire        S3_RD_ADDR_READY,

input  wire [31:0] S0_RD_DATA      ,    input  wire [31:0] S1_RD_DATA      ,    input  wire [31:0] S2_RD_DATA      ,    input  wire [31:0] S3_RD_DATA      ,
input  wire        S0_RD_DATA_LAST ,    input  wire        S1_RD_DATA_LAST ,    input  wire        S2_RD_DATA_LAST ,    input  wire        S3_RD_DATA_LAST ,
input  wire [ 3:0] S0_RD_BACK_ID   ,    input  wire [ 3:0] S1_RD_BACK_ID   ,    input  wire [ 3:0] S2_RD_BACK_ID   ,    input  wire [ 3:0] S3_RD_BACK_ID   ,
output wire        S0_RD_DATA_READY,    output wire        S1_RD_DATA_READY,    output wire        S2_RD_DATA_READY,    output wire        S3_RD_DATA_READY,
input  wire        S0_RD_DATA_VALID,    input  wire        S1_RD_DATA_VALID,    input  wire        S2_RD_DATA_VALID,    input  wire        S3_RD_DATA_VALID
);

wire [31:0] M0_BUS_WR_ADDR      ; wire [31:0] M1_BUS_WR_ADDR      ; wire [31:0] M2_BUS_WR_ADDR      ; wire [31:0] M3_BUS_WR_ADDR      ;
wire [ 7:0] M0_BUS_WR_LEN       ; wire [ 7:0] M1_BUS_WR_LEN       ; wire [ 7:0] M2_BUS_WR_LEN       ; wire [ 7:0] M3_BUS_WR_LEN       ;
wire [ 1:0] M0_BUS_WR_ID        ; wire [ 1:0] M1_BUS_WR_ID        ; wire [ 1:0] M2_BUS_WR_ID        ; wire [ 1:0] M3_BUS_WR_ID        ;
wire        M0_BUS_WR_ADDR_VALID; wire        M1_BUS_WR_ADDR_VALID; wire        M2_BUS_WR_ADDR_VALID; wire        M3_BUS_WR_ADDR_VALID;
wire        M0_BUS_WR_ADDR_READY; wire        M1_BUS_WR_ADDR_READY; wire        M2_BUS_WR_ADDR_READY; wire        M3_BUS_WR_ADDR_READY;
wire [31:0] M0_BUS_WR_DATA      ; wire [31:0] M1_BUS_WR_DATA      ; wire [31:0] M2_BUS_WR_DATA      ; wire [31:0] M3_BUS_WR_DATA      ;
wire [ 3:0] M0_BUS_WR_STRB      ; wire [ 3:0] M1_BUS_WR_STRB      ; wire [ 3:0] M2_BUS_WR_STRB      ; wire [ 3:0] M3_BUS_WR_STRB      ;
wire [ 1:0] M0_BUS_WR_BACK_ID   ; wire [ 1:0] M1_BUS_WR_BACK_ID   ; wire [ 1:0] M2_BUS_WR_BACK_ID   ; wire [ 1:0] M3_BUS_WR_BACK_ID   ;
wire        M0_BUS_WR_DATA_VALID; wire        M1_BUS_WR_DATA_VALID; wire        M2_BUS_WR_DATA_VALID; wire        M3_BUS_WR_DATA_VALID;
wire        M0_BUS_WR_DATA_READY; wire        M1_BUS_WR_DATA_READY; wire        M2_BUS_WR_DATA_READY; wire        M3_BUS_WR_DATA_READY;
wire        M0_BUS_WR_DATA_LAST ; wire        M1_BUS_WR_DATA_LAST ; wire        M2_BUS_WR_DATA_LAST ; wire        M3_BUS_WR_DATA_LAST ;
wire [31:0] M0_BUS_RD_ADDR      ; wire [31:0] M1_BUS_RD_ADDR      ; wire [31:0] M2_BUS_RD_ADDR      ; wire [31:0] M3_BUS_RD_ADDR      ;
wire [ 7:0] M0_BUS_RD_LEN       ; wire [ 7:0] M1_BUS_RD_LEN       ; wire [ 7:0] M2_BUS_RD_LEN       ; wire [ 7:0] M3_BUS_RD_LEN       ;
wire [ 1:0] M0_BUS_RD_ID        ; wire [ 1:0] M1_BUS_RD_ID        ; wire [ 1:0] M2_BUS_RD_ID        ; wire [ 1:0] M3_BUS_RD_ID        ;
wire        M0_BUS_RD_ADDR_VALID; wire        M1_BUS_RD_ADDR_VALID; wire        M2_BUS_RD_ADDR_VALID; wire        M3_BUS_RD_ADDR_VALID;
wire        M0_BUS_RD_ADDR_READY; wire        M1_BUS_RD_ADDR_READY; wire        M2_BUS_RD_ADDR_READY; wire        M3_BUS_RD_ADDR_READY;
wire [31:0] M0_BUS_RD_DATA      ; wire [31:0] M1_BUS_RD_DATA      ; wire [31:0] M2_BUS_RD_DATA      ; wire [31:0] M3_BUS_RD_DATA      ;
wire        M0_BUS_RD_DATA_LAST ; wire        M1_BUS_RD_DATA_LAST ; wire        M2_BUS_RD_DATA_LAST ; wire        M3_BUS_RD_DATA_LAST ;
wire [ 1:0] M0_BUS_RD_BACK_ID   ; wire [ 1:0] M1_BUS_RD_BACK_ID   ; wire [ 1:0] M2_BUS_RD_BACK_ID   ; wire [ 1:0] M3_BUS_RD_BACK_ID   ;
wire        M0_BUS_RD_DATA_READY; wire        M1_BUS_RD_DATA_READY; wire        M2_BUS_RD_DATA_READY; wire        M3_BUS_RD_DATA_READY;
wire        M0_BUS_RD_DATA_VALID; wire        M1_BUS_RD_DATA_VALID; wire        M2_BUS_RD_DATA_VALID; wire        M3_BUS_RD_DATA_VALID;

wire [31:0] S0_BUS_WR_ADDR      ; wire [31:0] S1_BUS_WR_ADDR      ; wire [31:0] S2_BUS_WR_ADDR      ; wire [31:0] S3_BUS_WR_ADDR      ;
wire [ 7:0] S0_BUS_WR_LEN       ; wire [ 7:0] S1_BUS_WR_LEN       ; wire [ 7:0] S2_BUS_WR_LEN       ; wire [ 7:0] S3_BUS_WR_LEN       ;
wire [ 3:0] S0_BUS_WR_ID        ; wire [ 3:0] S1_BUS_WR_ID        ; wire [ 3:0] S2_BUS_WR_ID        ; wire [ 3:0] S3_BUS_WR_ID        ;
wire        S0_BUS_WR_ADDR_VALID; wire        S1_BUS_WR_ADDR_VALID; wire        S2_BUS_WR_ADDR_VALID; wire        S3_BUS_WR_ADDR_VALID;
wire        S0_BUS_WR_ADDR_READY; wire        S1_BUS_WR_ADDR_READY; wire        S2_BUS_WR_ADDR_READY; wire        S3_BUS_WR_ADDR_READY;
wire [31:0] S0_BUS_WR_DATA      ; wire [31:0] S1_BUS_WR_DATA      ; wire [31:0] S2_BUS_WR_DATA      ; wire [31:0] S3_BUS_WR_DATA      ;
wire [ 3:0] S0_BUS_WR_STRB      ; wire [ 3:0] S1_BUS_WR_STRB      ; wire [ 3:0] S2_BUS_WR_STRB      ; wire [ 3:0] S3_BUS_WR_STRB      ;
wire [ 3:0] S0_BUS_WR_BACK_ID   ; wire [ 3:0] S1_BUS_WR_BACK_ID   ; wire [ 3:0] S2_BUS_WR_BACK_ID   ; wire [ 3:0] S3_BUS_WR_BACK_ID   ;
wire        S0_BUS_WR_DATA_VALID; wire        S1_BUS_WR_DATA_VALID; wire        S2_BUS_WR_DATA_VALID; wire        S3_BUS_WR_DATA_VALID;
wire        S0_BUS_WR_DATA_READY; wire        S1_BUS_WR_DATA_READY; wire        S2_BUS_WR_DATA_READY; wire        S3_BUS_WR_DATA_READY;
wire        S0_BUS_WR_DATA_LAST ; wire        S1_BUS_WR_DATA_LAST ; wire        S2_BUS_WR_DATA_LAST ; wire        S3_BUS_WR_DATA_LAST ;
wire [27:0] S0_BUS_RD_ADDR      ; wire [ 3:0] S1_BUS_RD_ADDR      ; wire [27:0] S2_BUS_RD_ADDR      ; wire [ 3:0] S3_BUS_RD_ADDR      ;
wire [ 7:0] S0_BUS_RD_LEN       ; wire [ 7:0] S1_BUS_RD_LEN       ; wire [ 7:0] S2_BUS_RD_LEN       ; wire [ 7:0] S3_BUS_RD_LEN       ;
wire [ 3:0] S0_BUS_RD_ID        ; wire [ 3:0] S1_BUS_RD_ID        ; wire [ 3:0] S2_BUS_RD_ID        ; wire [ 3:0] S3_BUS_RD_ID        ;
wire        S0_BUS_RD_ADDR_VALID; wire        S1_BUS_RD_ADDR_VALID; wire        S2_BUS_RD_ADDR_VALID; wire        S3_BUS_RD_ADDR_VALID;
wire        S0_BUS_RD_ADDR_READY; wire        S1_BUS_RD_ADDR_READY; wire        S2_BUS_RD_ADDR_READY; wire        S3_BUS_RD_ADDR_READY;
wire [31:0] S0_BUS_RD_DATA      ; wire [31:0] S1_BUS_RD_DATA      ; wire [31:0] S2_BUS_RD_DATA      ; wire [31:0] S3_BUS_RD_DATA      ;
wire        S0_BUS_RD_DATA_LAST ; wire        S1_BUS_RD_DATA_LAST ; wire        S2_BUS_RD_DATA_LAST ; wire        S3_BUS_RD_DATA_LAST ;
wire [ 3:0] S0_BUS_RD_BACK_ID   ; wire [ 3:0] S1_BUS_RD_BACK_ID   ; wire [ 3:0] S2_BUS_RD_BACK_ID   ; wire [ 3:0] S3_BUS_RD_BACK_ID   ;
wire        S0_BUS_RD_DATA_READY; wire        S1_BUS_RD_DATA_READY; wire        S2_BUS_RD_DATA_READY; wire        S3_BUS_RD_DATA_READY;
wire        S0_BUS_RD_DATA_VALID; wire        S1_BUS_RD_DATA_VALID; wire        S2_BUS_RD_DATA_VALID; wire        S3_BUS_RD_DATA_VALID;

//CLOCK跨时钟域转换
axi_clock_converter axi_clock_converter_inst(
    .BUS_CLK (BUS_CLK),
    .BUS_RST (BUS_RST),

    .M0_BUS_WR_ADDR      (M0_BUS_WR_ADDR      ),    .M1_BUS_WR_ADDR      (M1_BUS_WR_ADDR      ),    .M2_BUS_WR_ADDR      (M2_BUS_WR_ADDR      ),    .M3_BUS_WR_ADDR      (M3_BUS_WR_ADDR      ),
    .M0_BUS_WR_LEN       (M0_BUS_WR_LEN       ),    .M1_BUS_WR_LEN       (M1_BUS_WR_LEN       ),    .M2_BUS_WR_LEN       (M2_BUS_WR_LEN       ),    .M3_BUS_WR_LEN       (M3_BUS_WR_LEN       ),
    .M0_BUS_WR_ID        (M0_BUS_WR_ID        ),    .M1_BUS_WR_ID        (M1_BUS_WR_ID        ),    .M2_BUS_WR_ID        (M2_BUS_WR_ID        ),    .M3_BUS_WR_ID        (M3_BUS_WR_ID        ),
    .M0_BUS_WR_ADDR_VALID(M0_BUS_WR_ADDR_VALID),    .M1_BUS_WR_ADDR_VALID(M1_BUS_WR_ADDR_VALID),    .M2_BUS_WR_ADDR_VALID(M2_BUS_WR_ADDR_VALID),    .M3_BUS_WR_ADDR_VALID(M3_BUS_WR_ADDR_VALID),
    .M0_BUS_WR_ADDR_READY(M0_BUS_WR_ADDR_READY),    .M1_BUS_WR_ADDR_READY(M1_BUS_WR_ADDR_READY),    .M2_BUS_WR_ADDR_READY(M2_BUS_WR_ADDR_READY),    .M3_BUS_WR_ADDR_READY(M3_BUS_WR_ADDR_READY),

    .M0_BUS_WR_DATA      (M0_BUS_WR_DATA      ),    .M1_BUS_WR_DATA      (M1_BUS_WR_DATA      ),    .M2_BUS_WR_DATA      (M2_BUS_WR_DATA      ),    .M3_BUS_WR_DATA      (M3_BUS_WR_DATA      ),
    .M0_BUS_WR_STRB      (M0_BUS_WR_STRB      ),    .M1_BUS_WR_STRB      (M1_BUS_WR_STRB      ),    .M2_BUS_WR_STRB      (M2_BUS_WR_STRB      ),    .M3_BUS_WR_STRB      (M3_BUS_WR_STRB      ),
    .M0_BUS_WR_BACK_ID   (M0_BUS_WR_BACK_ID   ),    .M1_BUS_WR_BACK_ID   (M1_BUS_WR_BACK_ID   ),    .M2_BUS_WR_BACK_ID   (M2_BUS_WR_BACK_ID   ),    .M3_BUS_WR_BACK_ID   (M3_BUS_WR_BACK_ID   ),
    .M0_BUS_WR_DATA_VALID(M0_BUS_WR_DATA_VALID),    .M1_BUS_WR_DATA_VALID(M1_BUS_WR_DATA_VALID),    .M2_BUS_WR_DATA_VALID(M2_BUS_WR_DATA_VALID),    .M3_BUS_WR_DATA_VALID(M3_BUS_WR_DATA_VALID),
    .M0_BUS_WR_DATA_READY(M0_BUS_WR_DATA_READY),    .M1_BUS_WR_DATA_READY(M1_BUS_WR_DATA_READY),    .M2_BUS_WR_DATA_READY(M2_BUS_WR_DATA_READY),    .M3_BUS_WR_DATA_READY(M3_BUS_WR_DATA_READY),
    .M0_BUS_WR_DATA_LAST (M0_BUS_WR_DATA_LAST ),    .M1_BUS_WR_DATA_LAST (M1_BUS_WR_DATA_LAST ),    .M2_BUS_WR_DATA_LAST (M2_BUS_WR_DATA_LAST ),    .M3_BUS_WR_DATA_LAST (M3_BUS_WR_DATA_LAST ),

    .M0_BUS_RD_ADDR      (M0_BUS_RD_ADDR      ),    .M1_BUS_RD_ADDR      (M1_BUS_RD_ADDR      ),    .M2_BUS_RD_ADDR      (M2_BUS_RD_ADDR      ),    .M3_BUS_RD_ADDR      (M3_BUS_RD_ADDR      ),
    .M0_BUS_RD_LEN       (M0_BUS_RD_LEN       ),    .M1_BUS_RD_LEN       (M1_BUS_RD_LEN       ),    .M2_BUS_RD_LEN       (M2_BUS_RD_LEN       ),    .M3_BUS_RD_LEN       (M3_BUS_RD_LEN       ),
    .M0_BUS_RD_ID        (M0_BUS_RD_ID        ),    .M1_BUS_RD_ID        (M1_BUS_RD_ID        ),    .M2_BUS_RD_ID        (M2_BUS_RD_ID        ),    .M3_BUS_RD_ID        (M3_BUS_RD_ID        ),
    .M0_BUS_RD_ADDR_VALID(M0_BUS_RD_ADDR_VALID),    .M1_BUS_RD_ADDR_VALID(M1_BUS_RD_ADDR_VALID),    .M2_BUS_RD_ADDR_VALID(M2_BUS_RD_ADDR_VALID),    .M3_BUS_RD_ADDR_VALID(M3_BUS_RD_ADDR_VALID),
    .M0_BUS_RD_ADDR_READY(M0_BUS_RD_ADDR_READY),    .M1_BUS_RD_ADDR_READY(M1_BUS_RD_ADDR_READY),    .M2_BUS_RD_ADDR_READY(M2_BUS_RD_ADDR_READY),    .M3_BUS_RD_ADDR_READY(M3_BUS_RD_ADDR_READY),

    .M0_BUS_RD_DATA      (M0_BUS_RD_DATA      ),    .M1_BUS_RD_DATA      (M1_BUS_RD_DATA      ),    .M2_BUS_RD_DATA      (M2_BUS_RD_DATA      ),    .M3_BUS_RD_DATA      (M3_BUS_RD_DATA      ),
    .M0_BUS_RD_DATA_LAST (M0_BUS_RD_DATA_LAST ),    .M1_BUS_RD_DATA_LAST (M1_BUS_RD_DATA_LAST ),    .M2_BUS_RD_DATA_LAST (M2_BUS_RD_DATA_LAST ),    .M3_BUS_RD_DATA_LAST (M3_BUS_RD_DATA_LAST ),
    .M0_BUS_RD_BACK_ID   (M0_BUS_RD_BACK_ID   ),    .M1_BUS_RD_BACK_ID   (M1_BUS_RD_BACK_ID   ),    .M2_BUS_RD_BACK_ID   (M2_BUS_RD_BACK_ID   ),    .M3_BUS_RD_BACK_ID   (M3_BUS_RD_BACK_ID   ),
    .M0_BUS_RD_DATA_READY(M0_BUS_RD_DATA_READY),    .M1_BUS_RD_DATA_READY(M1_BUS_RD_DATA_READY),    .M2_BUS_RD_DATA_READY(M2_BUS_RD_DATA_READY),    .M3_BUS_RD_DATA_READY(M3_BUS_RD_DATA_READY),
    .M0_BUS_RD_DATA_VALID(M0_BUS_RD_DATA_VALID),    .M1_BUS_RD_DATA_VALID(M1_BUS_RD_DATA_VALID),    .M2_BUS_RD_DATA_VALID(M2_BUS_RD_DATA_VALID),    .M3_BUS_RD_DATA_VALID(M3_BUS_RD_DATA_VALID),

    .S0_BUS_WR_ADDR      (S0_BUS_WR_ADDR      ),    .S1_BUS_WR_ADDR      (S1_BUS_WR_ADDR      ),    .S2_BUS_WR_ADDR      (S2_BUS_WR_ADDR      ),    .S3_BUS_WR_ADDR      (S3_BUS_WR_ADDR      ),
    .S0_BUS_WR_LEN       (S0_BUS_WR_LEN       ),    .S1_BUS_WR_LEN       (S1_BUS_WR_LEN       ),    .S2_BUS_WR_LEN       (S2_BUS_WR_LEN       ),    .S3_BUS_WR_LEN       (S3_BUS_WR_LEN       ),
    .S0_BUS_WR_ID        (S0_BUS_WR_ID        ),    .S1_BUS_WR_ID        (S1_BUS_WR_ID        ),    .S2_BUS_WR_ID        (S2_BUS_WR_ID        ),    .S3_BUS_WR_ID        (S3_BUS_WR_ID        ),
    .S0_BUS_WR_ADDR_VALID(S0_BUS_WR_ADDR_VALID),    .S1_BUS_WR_ADDR_VALID(S1_BUS_WR_ADDR_VALID),    .S2_BUS_WR_ADDR_VALID(S2_BUS_WR_ADDR_VALID),    .S3_BUS_WR_ADDR_VALID(S3_BUS_WR_ADDR_VALID),
    .S0_BUS_WR_ADDR_READY(S0_BUS_WR_ADDR_READY),    .S1_BUS_WR_ADDR_READY(S1_BUS_WR_ADDR_READY),    .S2_BUS_WR_ADDR_READY(S2_BUS_WR_ADDR_READY),    .S3_BUS_WR_ADDR_READY(S3_BUS_WR_ADDR_READY),

    .S0_BUS_WR_DATA      (S0_BUS_WR_DATA      ),    .S1_BUS_WR_DATA      (S1_BUS_WR_DATA      ),    .S2_BUS_WR_DATA      (S2_BUS_WR_DATA      ),    .S3_BUS_WR_DATA      (S3_BUS_WR_DATA      ),
    .S0_BUS_WR_STRB      (S0_BUS_WR_STRB      ),    .S1_BUS_WR_STRB      (S1_BUS_WR_STRB      ),    .S2_BUS_WR_STRB      (S2_BUS_WR_STRB      ),    .S3_BUS_WR_STRB      (S3_BUS_WR_STRB      ),
    .S0_BUS_WR_BACK_ID   (S0_BUS_WR_BACK_ID   ),    .S1_BUS_WR_BACK_ID   (S1_BUS_WR_BACK_ID   ),    .S2_BUS_WR_BACK_ID   (S2_BUS_WR_BACK_ID   ),    .S3_BUS_WR_BACK_ID   (S3_BUS_WR_BACK_ID   ),
    .S0_BUS_WR_DATA_VALID(S0_BUS_WR_DATA_VALID),    .S1_BUS_WR_DATA_VALID(S1_BUS_WR_DATA_VALID),    .S2_BUS_WR_DATA_VALID(S2_BUS_WR_DATA_VALID),    .S3_BUS_WR_DATA_VALID(S3_BUS_WR_DATA_VALID),
    .S0_BUS_WR_DATA_READY(S0_BUS_WR_DATA_READY),    .S1_BUS_WR_DATA_READY(S1_BUS_WR_DATA_READY),    .S2_BUS_WR_DATA_READY(S2_BUS_WR_DATA_READY),    .S3_BUS_WR_DATA_READY(S3_BUS_WR_DATA_READY),
    .S0_BUS_WR_DATA_LAST (S0_BUS_WR_DATA_LAST ),    .S1_BUS_WR_DATA_LAST (S1_BUS_WR_DATA_LAST ),    .S2_BUS_WR_DATA_LAST (S2_BUS_WR_DATA_LAST ),    .S3_BUS_WR_DATA_LAST (S3_BUS_WR_DATA_LAST ),

    .S0_BUS_RD_ADDR      (S0_BUS_RD_ADDR      ),    .S1_BUS_RD_ADDR      (S1_BUS_RD_ADDR      ),    .S2_BUS_RD_ADDR      (S2_BUS_RD_ADDR      ),    .S3_BUS_RD_ADDR      (S3_BUS_RD_ADDR      ),
    .S0_BUS_RD_LEN       (S0_BUS_RD_LEN       ),    .S1_BUS_RD_LEN       (S1_BUS_RD_LEN       ),    .S2_BUS_RD_LEN       (S2_BUS_RD_LEN       ),    .S3_BUS_RD_LEN       (S3_BUS_RD_LEN       ),
    .S0_BUS_RD_ID        (S0_BUS_RD_ID        ),    .S1_BUS_RD_ID        (S1_BUS_RD_ID        ),    .S2_BUS_RD_ID        (S2_BUS_RD_ID        ),    .S3_BUS_RD_ID        (S3_BUS_RD_ID        ),
    .S0_BUS_RD_ADDR_VALID(S0_BUS_RD_ADDR_VALID),    .S1_BUS_RD_ADDR_VALID(S1_BUS_RD_ADDR_VALID),    .S2_BUS_RD_ADDR_VALID(S2_BUS_RD_ADDR_VALID),    .S3_BUS_RD_ADDR_VALID(S3_BUS_RD_ADDR_VALID),
    .S0_BUS_RD_ADDR_READY(S0_BUS_RD_ADDR_READY),    .S1_BUS_RD_ADDR_READY(S1_BUS_RD_ADDR_READY),    .S2_BUS_RD_ADDR_READY(S2_BUS_RD_ADDR_READY),    .S3_BUS_RD_ADDR_READY(S3_BUS_RD_ADDR_READY),

    .S0_BUS_RD_DATA      (S0_BUS_RD_DATA      ),    .S1_BUS_RD_DATA      (S1_BUS_RD_DATA      ),    .S2_BUS_RD_DATA      (S2_BUS_RD_DATA      ),    .S3_BUS_RD_DATA      (S3_BUS_RD_DATA      ),
    .S0_BUS_RD_DATA_LAST (S0_BUS_RD_DATA_LAST ),    .S1_BUS_RD_DATA_LAST (S1_BUS_RD_DATA_LAST ),    .S2_BUS_RD_DATA_LAST (S2_BUS_RD_DATA_LAST ),    .S3_BUS_RD_DATA_LAST (S3_BUS_RD_DATA_LAST ),
    .S0_BUS_RD_BACK_ID   (S0_BUS_RD_BACK_ID   ),    .S1_BUS_RD_BACK_ID   (S1_BUS_RD_BACK_ID   ),    .S2_BUS_RD_BACK_ID   (S2_BUS_RD_BACK_ID   ),    .S3_BUS_RD_BACK_ID   (S3_BUS_RD_BACK_ID   ),
    .S0_BUS_RD_DATA_READY(S0_BUS_RD_DATA_READY),    .S1_BUS_RD_DATA_READY(S1_BUS_RD_DATA_READY),    .S2_BUS_RD_DATA_READY(S2_BUS_RD_DATA_READY),    .S3_BUS_RD_DATA_READY(S3_BUS_RD_DATA_READY),
    .S0_BUS_RD_DATA_VALID(S0_BUS_RD_DATA_VALID),    .S1_BUS_RD_DATA_VALID(S1_BUS_RD_DATA_VALID),    .S2_BUS_RD_DATA_VALID(S2_BUS_RD_DATA_VALID),    .S3_BUS_RD_DATA_VALID(S3_BUS_RD_DATA_VALID),

    //_______________________________________________________________________________________________________________________________________________________//

    .M0_CLK          (M0_CLK          ),    .M1_CLK          (M1_CLK          ),    .M2_CLK          (M2_CLK          ),    .M3_CLK          (M3_CLK          ),
    .M0_RST          (M0_RST          ),    .M1_RST          (M1_RST          ),    .M2_RST          (M2_RST          ),    .M3_RST          (M3_RST          ),
    .M0_WR_ADDR      (M0_WR_ADDR      ),    .M1_WR_ADDR      (M1_WR_ADDR      ),    .M2_WR_ADDR      (M2_WR_ADDR      ),    .M3_WR_ADDR      (M3_WR_ADDR      ),
    .M0_WR_LEN       (M0_WR_LEN       ),    .M1_WR_LEN       (M1_WR_LEN       ),    .M2_WR_LEN       (M2_WR_LEN       ),    .M3_WR_LEN       (M3_WR_LEN       ),
    .M0_WR_ID        (M0_WR_ID        ),    .M1_WR_ID        (M1_WR_ID        ),    .M2_WR_ID        (M2_WR_ID        ),    .M3_WR_ID        (M3_WR_ID        ),
    .M0_WR_ADDR_VALID(M0_WR_ADDR_VALID),    .M1_WR_ADDR_VALID(M1_WR_ADDR_VALID),    .M2_WR_ADDR_VALID(M2_WR_ADDR_VALID),    .M3_WR_ADDR_VALID(M3_WR_ADDR_VALID),
    .M0_WR_ADDR_READY(M0_WR_ADDR_READY),    .M1_WR_ADDR_READY(M1_WR_ADDR_READY),    .M2_WR_ADDR_READY(M2_WR_ADDR_READY),    .M3_WR_ADDR_READY(M3_WR_ADDR_READY),

    .M0_WR_DATA      (M0_WR_DATA      ),    .M1_WR_DATA      (M1_WR_DATA      ),    .M2_WR_DATA      (M2_WR_DATA      ),    .M3_WR_DATA      (M3_WR_DATA      ),
    .M0_WR_STRB      (M0_WR_STRB      ),    .M1_WR_STRB      (M1_WR_STRB      ),    .M2_WR_STRB      (M2_WR_STRB      ),    .M3_WR_STRB      (M3_WR_STRB      ),
    .M0_WR_BACK_ID   (M0_WR_BACK_ID   ),    .M1_WR_BACK_ID   (M1_WR_BACK_ID   ),    .M2_WR_BACK_ID   (M2_WR_BACK_ID   ),    .M3_WR_BACK_ID   (M3_WR_BACK_ID   ),
    .M0_WR_DATA_VALID(M0_WR_DATA_VALID),    .M1_WR_DATA_VALID(M1_WR_DATA_VALID),    .M2_WR_DATA_VALID(M2_WR_DATA_VALID),    .M3_WR_DATA_VALID(M3_WR_DATA_VALID),
    .M0_WR_DATA_READY(M0_WR_DATA_READY),    .M1_WR_DATA_READY(M1_WR_DATA_READY),    .M2_WR_DATA_READY(M2_WR_DATA_READY),    .M3_WR_DATA_READY(M3_WR_DATA_READY),
    .M0_WR_DATA_LAST (M0_WR_DATA_LAST ),    .M1_WR_DATA_LAST (M1_WR_DATA_LAST ),    .M2_WR_DATA_LAST (M2_WR_DATA_LAST ),    .M3_WR_DATA_LAST (M3_WR_DATA_LAST ),

    .M0_RD_ADDR      (M0_RD_ADDR      ),    .M1_RD_ADDR      (M1_RD_ADDR      ),    .M2_RD_ADDR      (M2_RD_ADDR      ),    .M3_RD_ADDR      (M3_RD_ADDR      ),
    .M0_RD_LEN       (M0_RD_LEN       ),    .M1_RD_LEN       (M1_RD_LEN       ),    .M2_RD_LEN       (M2_RD_LEN       ),    .M3_RD_LEN       (M3_RD_LEN       ),
    .M0_RD_ID        (M0_RD_ID        ),    .M1_RD_ID        (M1_RD_ID        ),    .M2_RD_ID        (M2_RD_ID        ),    .M3_RD_ID        (M3_RD_ID        ),
    .M0_RD_ADDR_VALID(M0_RD_ADDR_VALID),    .M1_RD_ADDR_VALID(M1_RD_ADDR_VALID),    .M2_RD_ADDR_VALID(M2_RD_ADDR_VALID),    .M3_RD_ADDR_VALID(M3_RD_ADDR_VALID),
    .M0_RD_ADDR_READY(M0_RD_ADDR_READY),    .M1_RD_ADDR_READY(M1_RD_ADDR_READY),    .M2_RD_ADDR_READY(M2_RD_ADDR_READY),    .M3_RD_ADDR_READY(M3_RD_ADDR_READY),

    .M0_RD_DATA      (M0_RD_DATA      ),    .M1_RD_DATA      (M1_RD_DATA      ),    .M2_RD_DATA      (M2_RD_DATA      ),    .M3_RD_DATA      (M3_RD_DATA      ),
    .M0_RD_DATA_LAST (M0_RD_DATA_LAST ),    .M1_RD_DATA_LAST (M1_RD_DATA_LAST ),    .M2_RD_DATA_LAST (M2_RD_DATA_LAST ),    .M3_RD_DATA_LAST (M3_RD_DATA_LAST ),
    .M0_RD_BACK_ID   (M0_RD_BACK_ID   ),    .M1_RD_BACK_ID   (M1_RD_BACK_ID   ),    .M2_RD_BACK_ID   (M2_RD_BACK_ID   ),    .M3_RD_BACK_ID   (M3_RD_BACK_ID   ),
    .M0_RD_DATA_READY(M0_RD_DATA_READY),    .M1_RD_DATA_READY(M1_RD_DATA_READY),    .M2_RD_DATA_READY(M2_RD_DATA_READY),    .M3_RD_DATA_READY(M3_RD_DATA_READY),
    .M0_RD_DATA_VALID(M0_RD_DATA_VALID),    .M1_RD_DATA_VALID(M1_RD_DATA_VALID),    .M2_RD_DATA_VALID(M2_RD_DATA_VALID),    .M3_RD_DATA_VALID(M3_RD_DATA_VALID),

    .S0_CLK          (S0_CLK          ),    .S1_CLK          (S1_CLK          ),    .S2_CLK          (S2_CLK          ),    .S3_CLK          (S3_CLK          ),
    .S0_RST          (S0_RST          ),    .S1_RST          (S1_RST          ),    .S2_RST          (S2_RST          ),    .S3_RST          (S3_RST          ),
    .S0_WR_ADDR      (S0_WR_ADDR      ),    .S1_WR_ADDR      (S1_WR_ADDR      ),    .S2_WR_ADDR      (S2_WR_ADDR      ),    .S3_WR_ADDR      (S3_WR_ADDR      ),
    .S0_WR_LEN       (S0_WR_LEN       ),    .S1_WR_LEN       (S1_WR_LEN       ),    .S2_WR_LEN       (S2_WR_LEN       ),    .S3_WR_LEN       (S3_WR_LEN       ),
    .S0_WR_ID        (S0_WR_ID        ),    .S1_WR_ID        (S1_WR_ID        ),    .S2_WR_ID        (S2_WR_ID        ),    .S3_WR_ID        (S3_WR_ID        ),
    .S0_WR_ADDR_VALID(S0_WR_ADDR_VALID),    .S1_WR_ADDR_VALID(S1_WR_ADDR_VALID),    .S2_WR_ADDR_VALID(S2_WR_ADDR_VALID),    .S3_WR_ADDR_VALID(S3_WR_ADDR_VALID),
    .S0_WR_ADDR_READY(S0_WR_ADDR_READY),    .S1_WR_ADDR_READY(S1_WR_ADDR_READY),    .S2_WR_ADDR_READY(S2_WR_ADDR_READY),    .S3_WR_ADDR_READY(S3_WR_ADDR_READY),

    .S0_WR_DATA      (S0_WR_DATA      ),    .S1_WR_DATA      (S1_WR_DATA      ),    .S2_WR_DATA      (S2_WR_DATA      ),    .S3_WR_DATA      (S3_WR_DATA      ),
    .S0_WR_STRB      (S0_WR_STRB      ),    .S1_WR_STRB      (S1_WR_STRB      ),    .S2_WR_STRB      (S2_WR_STRB      ),    .S3_WR_STRB      (S3_WR_STRB      ),
    .S0_WR_BACK_ID   (S0_WR_BACK_ID   ),    .S1_WR_BACK_ID   (S1_WR_BACK_ID   ),    .S2_WR_BACK_ID   (S2_WR_BACK_ID   ),    .S3_WR_BACK_ID   (S3_WR_BACK_ID   ),
    .S0_WR_DATA_VALID(S0_WR_DATA_VALID),    .S1_WR_DATA_VALID(S1_WR_DATA_VALID),    .S2_WR_DATA_VALID(S2_WR_DATA_VALID),    .S3_WR_DATA_VALID(S3_WR_DATA_VALID),
    .S0_WR_DATA_READY(S0_WR_DATA_READY),    .S1_WR_DATA_READY(S1_WR_DATA_READY),    .S2_WR_DATA_READY(S2_WR_DATA_READY),    .S3_WR_DATA_READY(S3_WR_DATA_READY),
    .S0_WR_DATA_LAST (S0_WR_DATA_LAST ),    .S1_WR_DATA_LAST (S1_WR_DATA_LAST ),    .S2_WR_DATA_LAST (S2_WR_DATA_LAST ),    .S3_WR_DATA_LAST (S3_WR_DATA_LAST ),

    .S0_RD_ADDR      (S0_RD_ADDR      ),    .S1_RD_ADDR      (S1_RD_ADDR      ),    .S2_RD_ADDR      (S2_RD_ADDR      ),    .S3_RD_ADDR      (S3_RD_ADDR      ),
    .S0_RD_LEN       (S0_RD_LEN       ),    .S1_RD_LEN       (S1_RD_LEN       ),    .S2_RD_LEN       (S2_RD_LEN       ),    .S3_RD_LEN       (S3_RD_LEN       ),
    .S0_RD_ID        (S0_RD_ID        ),    .S1_RD_ID        (S1_RD_ID        ),    .S2_RD_ID        (S2_RD_ID        ),    .S3_RD_ID        (S3_RD_ID        ),
    .S0_RD_ADDR_VALID(S0_RD_ADDR_VALID),    .S1_RD_ADDR_VALID(S1_RD_ADDR_VALID),    .S2_RD_ADDR_VALID(S2_RD_ADDR_VALID),    .S3_RD_ADDR_VALID(S3_RD_ADDR_VALID),
    .S0_RD_ADDR_READY(S0_RD_ADDR_READY),    .S1_RD_ADDR_READY(S1_RD_ADDR_READY),    .S2_RD_ADDR_READY(S2_RD_ADDR_READY),    .S3_RD_ADDR_READY(S3_RD_ADDR_READY),

    .S0_RD_DATA      (S0_RD_DATA      ),    .S1_RD_DATA      (S1_RD_DATA      ),    .S2_RD_DATA      (S2_RD_DATA      ),    .S3_RD_DATA      (S3_RD_DATA      ),
    .S0_RD_DATA_LAST (S0_RD_DATA_LAST ),    .S1_RD_DATA_LAST (S1_RD_DATA_LAST ),    .S2_RD_DATA_LAST (S2_RD_DATA_LAST ),    .S3_RD_DATA_LAST (S3_RD_DATA_LAST ),
    .S0_RD_BACK_ID   (S0_RD_BACK_ID   ),    .S1_RD_BACK_ID   (S1_RD_BACK_ID   ),    .S2_RD_BACK_ID   (S2_RD_BACK_ID   ),    .S3_RD_BACK_ID   (S3_RD_BACK_ID   ),
    .S0_RD_DATA_READY(S0_RD_DATA_READY),    .S1_RD_DATA_READY(S1_RD_DATA_READY),    .S2_RD_DATA_READY(S2_RD_DATA_READY),    .S3_RD_DATA_READY(S3_RD_DATA_READY),
    .S0_RD_DATA_VALID(S0_RD_DATA_VALID),    .S1_RD_DATA_VALID(S1_RD_DATA_VALID),    .S2_RD_DATA_VALID(S2_RD_DATA_VALID),    .S3_RD_DATA_VALID(S3_RD_DATA_VALID)
);

axi_interconnect #(
    .S0_START_ADDR  (S0_START_ADDR),
    .S0_END_ADDR    (S0_END_ADDR  ),
    .S1_START_ADDR  (S1_START_ADDR),
    .S1_END_ADDR    (S1_END_ADDR  ),
    .S2_START_ADDR  (S2_START_ADDR),
    .S2_END_ADDR    (S2_END_ADDR  ),
    .S3_START_ADDR  (S3_START_ADDR),
    .S3_END_ADDR    (S3_END_ADDR  )
)axi_interconnect_inst(
    .BUS_CLK (BUS_CLK),
    .BUS_RST (BUS_RST),

    .M0_WR_ADDR      (M0_BUS_WR_ADDR      ),    .M1_WR_ADDR      (M1_BUS_WR_ADDR      ),    .M2_WR_ADDR      (M2_BUS_WR_ADDR      ),    .M3_WR_ADDR      (M3_BUS_WR_ADDR      ),
    .M0_WR_LEN       (M0_BUS_WR_LEN       ),    .M1_WR_LEN       (M1_BUS_WR_LEN       ),    .M2_WR_LEN       (M2_BUS_WR_LEN       ),    .M3_WR_LEN       (M3_BUS_WR_LEN       ),
    .M0_WR_ID        (M0_BUS_WR_ID        ),    .M1_WR_ID        (M1_BUS_WR_ID        ),    .M2_WR_ID        (M2_BUS_WR_ID        ),    .M3_WR_ID        (M3_BUS_WR_ID        ),
    .M0_WR_ADDR_VALID(M0_BUS_WR_ADDR_VALID),    .M1_WR_ADDR_VALID(M1_BUS_WR_ADDR_VALID),    .M2_WR_ADDR_VALID(M2_BUS_WR_ADDR_VALID),    .M3_WR_ADDR_VALID(M3_BUS_WR_ADDR_VALID),
    .M0_WR_ADDR_READY(M0_BUS_WR_ADDR_READY),    .M1_WR_ADDR_READY(M1_BUS_WR_ADDR_READY),    .M2_WR_ADDR_READY(M2_BUS_WR_ADDR_READY),    .M3_WR_ADDR_READY(M3_BUS_WR_ADDR_READY),

    .M0_WR_DATA      (M0_BUS_WR_DATA      ),    .M1_WR_DATA      (M1_BUS_WR_DATA      ),    .M2_WR_DATA      (M2_BUS_WR_DATA      ),    .M3_WR_DATA      (M3_BUS_WR_DATA      ),
    .M0_WR_STRB      (M0_BUS_WR_STRB      ),    .M1_WR_STRB      (M1_BUS_WR_STRB      ),    .M2_WR_STRB      (M2_BUS_WR_STRB      ),    .M3_WR_STRB      (M3_BUS_WR_STRB      ),
    .M0_WR_BACK_ID   (M0_BUS_WR_BACK_ID   ),    .M1_WR_BACK_ID   (M1_BUS_WR_BACK_ID   ),    .M2_WR_BACK_ID   (M2_BUS_WR_BACK_ID   ),    .M3_WR_BACK_ID   (M3_BUS_WR_BACK_ID   ),
    .M0_WR_DATA_VALID(M0_BUS_WR_DATA_VALID),    .M1_WR_DATA_VALID(M1_BUS_WR_DATA_VALID),    .M2_WR_DATA_VALID(M2_BUS_WR_DATA_VALID),    .M3_WR_DATA_VALID(M3_BUS_WR_DATA_VALID),
    .M0_WR_DATA_READY(M0_BUS_WR_DATA_READY),    .M1_WR_DATA_READY(M1_BUS_WR_DATA_READY),    .M2_WR_DATA_READY(M2_BUS_WR_DATA_READY),    .M3_WR_DATA_READY(M3_BUS_WR_DATA_READY),
    .M0_WR_DATA_LAST (M0_BUS_WR_DATA_LAST ),    .M1_WR_DATA_LAST (M1_BUS_WR_DATA_LAST ),    .M2_WR_DATA_LAST (M2_BUS_WR_DATA_LAST ),    .M3_WR_DATA_LAST (M3_BUS_WR_DATA_LAST ),

    .M0_RD_ADDR      (M0_BUS_RD_ADDR      ),    .M1_RD_ADDR      (M1_BUS_RD_ADDR      ),    .M2_RD_ADDR      (M2_BUS_RD_ADDR      ),    .M3_RD_ADDR      (M3_BUS_RD_ADDR      ),
    .M0_RD_LEN       (M0_BUS_RD_LEN       ),    .M1_RD_LEN       (M1_BUS_RD_LEN       ),    .M2_RD_LEN       (M2_BUS_RD_LEN       ),    .M3_RD_LEN       (M3_BUS_RD_LEN       ),
    .M0_RD_ID        (M0_BUS_RD_ID        ),    .M1_RD_ID        (M1_BUS_RD_ID        ),    .M2_RD_ID        (M2_BUS_RD_ID        ),    .M3_RD_ID        (M3_BUS_RD_ID        ),
    .M0_RD_ADDR_VALID(M0_BUS_RD_ADDR_VALID),    .M1_RD_ADDR_VALID(M1_BUS_RD_ADDR_VALID),    .M2_RD_ADDR_VALID(M2_BUS_RD_ADDR_VALID),    .M3_RD_ADDR_VALID(M3_BUS_RD_ADDR_VALID),
    .M0_RD_ADDR_READY(M0_BUS_RD_ADDR_READY),    .M1_RD_ADDR_READY(M1_BUS_RD_ADDR_READY),    .M2_RD_ADDR_READY(M2_BUS_RD_ADDR_READY),    .M3_RD_ADDR_READY(M3_BUS_RD_ADDR_READY),

    .M0_RD_DATA      (M0_BUS_RD_DATA      ),    .M1_RD_DATA      (M1_BUS_RD_DATA      ),    .M2_RD_DATA      (M2_BUS_RD_DATA      ),    .M3_RD_DATA      (M3_BUS_RD_DATA      ),
    .M0_RD_DATA_LAST (M0_BUS_RD_DATA_LAST ),    .M1_RD_DATA_LAST (M1_BUS_RD_DATA_LAST ),    .M2_RD_DATA_LAST (M2_BUS_RD_DATA_LAST ),    .M3_RD_DATA_LAST (M3_BUS_RD_DATA_LAST ),
    .M0_RD_BACK_ID   (M0_BUS_RD_BACK_ID   ),    .M1_RD_BACK_ID   (M1_BUS_RD_BACK_ID   ),    .M2_RD_BACK_ID   (M2_BUS_RD_BACK_ID   ),    .M3_RD_BACK_ID   (M3_BUS_RD_BACK_ID   ),
    .M0_RD_DATA_READY(M0_BUS_RD_DATA_READY),    .M1_RD_DATA_READY(M1_BUS_RD_DATA_READY),    .M2_RD_DATA_READY(M2_BUS_RD_DATA_READY),    .M3_RD_DATA_READY(M3_BUS_RD_DATA_READY),
    .M0_RD_DATA_VALID(M0_BUS_RD_DATA_VALID),    .M1_RD_DATA_VALID(M1_BUS_RD_DATA_VALID),    .M2_RD_DATA_VALID(M2_BUS_RD_DATA_VALID),    .M3_RD_DATA_VALID(M3_BUS_RD_DATA_VALID),

    .S0_WR_ADDR      (S0_BUS_WR_ADDR      ),    .S1_WR_ADDR      (S1_BUS_WR_ADDR      ),    .S2_WR_ADDR      (S2_BUS_WR_ADDR      ),    .S3_WR_ADDR      (S3_BUS_WR_ADDR      ),
    .S0_WR_LEN       (S0_BUS_WR_LEN       ),    .S1_WR_LEN       (S1_BUS_WR_LEN       ),    .S2_WR_LEN       (S2_BUS_WR_LEN       ),    .S3_WR_LEN       (S3_BUS_WR_LEN       ),
    .S0_WR_ID        (S0_BUS_WR_ID        ),    .S1_WR_ID        (S1_BUS_WR_ID        ),    .S2_WR_ID        (S2_BUS_WR_ID        ),    .S3_WR_ID        (S3_BUS_WR_ID        ),
    .S0_WR_ADDR_VALID(S0_BUS_WR_ADDR_VALID),    .S1_WR_ADDR_VALID(S1_BUS_WR_ADDR_VALID),    .S2_WR_ADDR_VALID(S2_BUS_WR_ADDR_VALID),    .S3_WR_ADDR_VALID(S3_BUS_WR_ADDR_VALID),
    .S0_WR_ADDR_READY(S0_BUS_WR_ADDR_READY),    .S1_WR_ADDR_READY(S1_BUS_WR_ADDR_READY),    .S2_WR_ADDR_READY(S2_BUS_WR_ADDR_READY),    .S3_WR_ADDR_READY(S3_BUS_WR_ADDR_READY),

    .S0_WR_DATA      (S0_BUS_WR_DATA      ),    .S1_WR_DATA      (S1_BUS_WR_DATA      ),    .S2_WR_DATA      (S2_BUS_WR_DATA      ),    .S3_WR_DATA      (S3_BUS_WR_DATA      ),
    .S0_WR_STRB      (S0_BUS_WR_STRB      ),    .S1_WR_STRB      (S1_BUS_WR_STRB      ),    .S2_WR_STRB      (S2_BUS_WR_STRB      ),    .S3_WR_STRB      (S3_BUS_WR_STRB      ),
    .S0_WR_BACK_ID   (S0_BUS_WR_BACK_ID   ),    .S1_WR_BACK_ID   (S1_BUS_WR_BACK_ID   ),    .S2_WR_BACK_ID   (S2_BUS_WR_BACK_ID   ),    .S3_WR_BACK_ID   (S3_BUS_WR_BACK_ID   ),
    .S0_WR_DATA_VALID(S0_BUS_WR_DATA_VALID),    .S1_WR_DATA_VALID(S1_BUS_WR_DATA_VALID),    .S2_WR_DATA_VALID(S2_BUS_WR_DATA_VALID),    .S3_WR_DATA_VALID(S3_BUS_WR_DATA_VALID),
    .S0_WR_DATA_READY(S0_BUS_WR_DATA_READY),    .S1_WR_DATA_READY(S1_BUS_WR_DATA_READY),    .S2_WR_DATA_READY(S2_BUS_WR_DATA_READY),    .S3_WR_DATA_READY(S3_BUS_WR_DATA_READY),
    .S0_WR_DATA_LAST (S0_BUS_WR_DATA_LAST ),    .S1_WR_DATA_LAST (S1_BUS_WR_DATA_LAST ),    .S2_WR_DATA_LAST (S2_BUS_WR_DATA_LAST ),    .S3_WR_DATA_LAST (S3_BUS_WR_DATA_LAST ),

    .S0_RD_ADDR      (S0_BUS_RD_ADDR      ),    .S1_RD_ADDR      (S1_BUS_RD_ADDR      ),    .S2_RD_ADDR      (S2_BUS_RD_ADDR      ),    .S3_RD_ADDR      (S3_BUS_RD_ADDR      ),
    .S0_RD_LEN       (S0_BUS_RD_LEN       ),    .S1_RD_LEN       (S1_BUS_RD_LEN       ),    .S2_RD_LEN       (S2_BUS_RD_LEN       ),    .S3_RD_LEN       (S3_BUS_RD_LEN       ),
    .S0_RD_ID        (S0_BUS_RD_ID        ),    .S1_RD_ID        (S1_BUS_RD_ID        ),    .S2_RD_ID        (S2_BUS_RD_ID        ),    .S3_RD_ID        (S3_BUS_RD_ID        ),
    .S0_RD_ADDR_VALID(S0_BUS_RD_ADDR_VALID),    .S1_RD_ADDR_VALID(S1_BUS_RD_ADDR_VALID),    .S2_RD_ADDR_VALID(S2_BUS_RD_ADDR_VALID),    .S3_RD_ADDR_VALID(S3_BUS_RD_ADDR_VALID),
    .S0_RD_ADDR_READY(S0_BUS_RD_ADDR_READY),    .S1_RD_ADDR_READY(S1_BUS_RD_ADDR_READY),    .S2_RD_ADDR_READY(S2_BUS_RD_ADDR_READY),    .S3_RD_ADDR_READY(S3_BUS_RD_ADDR_READY),

    .S0_RD_DATA      (S0_BUS_RD_DATA      ),    .S1_RD_DATA      (S1_BUS_RD_DATA      ),    .S2_RD_DATA      (S2_BUS_RD_DATA      ),    .S3_RD_DATA      (S3_BUS_RD_DATA      ),
    .S0_RD_DATA_LAST (S0_BUS_RD_DATA_LAST ),    .S1_RD_DATA_LAST (S1_BUS_RD_DATA_LAST ),    .S2_RD_DATA_LAST (S2_BUS_RD_DATA_LAST ),    .S3_RD_DATA_LAST (S3_BUS_RD_DATA_LAST ),
    .S0_RD_BACK_ID   (S0_BUS_RD_BACK_ID   ),    .S1_RD_BACK_ID   (S1_BUS_RD_BACK_ID   ),    .S2_RD_BACK_ID   (S2_BUS_RD_BACK_ID   ),    .S3_RD_BACK_ID   (S3_BUS_RD_BACK_ID   ),
    .S0_RD_DATA_READY(S0_BUS_RD_DATA_READY),    .S1_RD_DATA_READY(S1_BUS_RD_DATA_READY),    .S2_RD_DATA_READY(S2_BUS_RD_DATA_READY),    .S3_RD_DATA_READY(S3_BUS_RD_DATA_READY),
    .S0_RD_DATA_VALID(S0_BUS_RD_DATA_VALID),    .S1_RD_DATA_VALID(S1_BUS_RD_DATA_VALID),    .S2_RD_DATA_VALID(S2_BUS_RD_DATA_VALID),    .S3_RD_DATA_VALID(S3_BUS_RD_DATA_VALID)
);




endmodule