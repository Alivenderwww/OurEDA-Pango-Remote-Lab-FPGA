module slave_ddr3 (
    input wire         ddr_ref_clk      ,
    input wire         rst_n            ,
    output wire        ddr_init_done    ,
    
    input  wire        BUS_CLK          ,
    input  wire        BUS_RST          ,

    input wire [27:0]  BUS_WR_ADDR      , //写地址
    input wire [ 7:0]  BUS_WR_LEN       , //写突发长度，实际长度为WR_LEN+1
    input wire         BUS_WR_ADDR_VALID, //写地址通道有效
    output wire        BUS_WR_ADDR_READY, //写地址通道准备
     
    input wire [ 31:0] BUS_WR_DATA      , //写数据
    input wire [  3:0] BUS_WR_STRB      , //写数据掩码
    input  wire        BUS_WR_DATA_VALID, //写数据有效
    output wire        BUS_WR_DATA_READY, //写数据准备
    input  wire        BUS_WR_DATA_LAST , //最后一个写数据标志位
     
    input wire [27:0]  BUS_RD_ADDR      , //读地址
    input wire [ 7:0]  BUS_RD_LEN       , //读突发长度，实际长度为WR_LEN+1
    input wire         BUS_RD_ADDR_VALID, //读地址通道有效
    output wire        BUS_RD_ADDR_READY, //读地址通道准备
     
    output wire [31:0] BUS_RD_DATA      , //读数据
    output wire        BUS_RD_DATA_LAST , //最后一个读数据标志位
    input  wire        BUS_RD_DATA_READY, //读数据准备
    output wire        BUS_RD_DATA_VALID, //读数据有效
    
    output wire         mem_rst_n    , //Memory复位
    output wire         mem_ck       , //Memory差分时钟正端
    output wire         mem_ck_n     , //Memory差分时钟负端
    output wire         mem_cs_n     , //Memory片选
    output wire [14:0]  mem_a        , //Memory地址总线
    inout  wire [31:0]  mem_dq       , //数据总线
    inout  wire [ 3:0]  mem_dqs      , //数据时钟正端
    inout  wire [ 3:0]  mem_dqs_n    , //数据时钟负端
    output wire [ 3:0]  mem_dm       , //数据Mask
    output wire         mem_cke      , //Memory差分时钟使能
    output wire         mem_odt      , //On Die Termination
    output wire         mem_ras_n    , //行地址strobe
    output wire         mem_cas_n    , //列地址strobe
    output wire         mem_we_n     , //写使能
    output wire [ 2:0]  mem_ba         //Bank地址总线
);
wire         ddr_core_clk ;
wire [27:0]  WRITE_ADDR      ; //写地址
wire [ 3:0]  WRITE_LEN       ; //写长度，实际长度为WR_LEN+1
wire         WRITE_ADDR_VALID; //写地址通道有效
wire         WRITE_ADDR_READY; //写地址通道准备

wire [255:0] WRITE_DATA      ; //写数据
wire [ 31:0] WRITE_STRB      ; //写数据掩码
wire         WRITE_DATA_READY; //写数据准备
wire         WRITE_DATA_LAST ; //最后一个写数据标志位

wire [27:0]  READ_ADDR      ; //读地址
wire [ 3:0]  READ_LEN       ; //读长度，实际长度为WR_LEN+1
wire         READ_ADDR_VALID; //读地址通道有效
wire         READ_ADDR_READY; //读地址通道准备

wire [255:0] READ_DATA      ; //读数据
wire         READ_DATA_LAST ; //最后一个读数据标志位
wire         READ_DATA_VALID; //读数据有效

wire [27:0] SLAVE_WR_ADDR      ;
wire [ 7:0] SLAVE_WR_LEN       ;
wire        SLAVE_WR_ADDR_VALID;
wire        SLAVE_WR_ADDR_READY;

wire [31:0] SLAVE_WR_DATA      ;
wire [ 3:0] SLAVE_WR_STRB      ;
wire        SLAVE_WR_DATA_VALID;
wire        SLAVE_WR_DATA_READY;
wire        SLAVE_WR_DATA_LAST ;

wire [27:0] SLAVE_RD_ADDR      ;
wire [ 7:0] SLAVE_RD_LEN       ;
wire        SLAVE_RD_ADDR_VALID;
wire        SLAVE_RD_ADDR_READY;

wire [31:0] SLAVE_RD_DATA      ;
wire        SLAVE_RD_DATA_LAST ;
wire        SLAVE_RD_DATA_READY;
wire        SLAVE_RD_DATA_VALID;

/*
首先地址要对齐，低3位始终为0
如果要读写中间的，需要转换一下STRB
为了效率需要处理一下LEN.
原先一个LEN可以读写8条地址，LEN位宽为4，共可突发读写32x8=256条地址
现在一个LEN可以读写1条地址，LEN需要位宽为8.

内部设置一个fifo, 用于处理数据通道无握手的构式设计
写DDR 只有内部fifo存好一定量的数据后，或者剩余的数据就是全部数据了，才会向ddr3发送一定长度的突发传输请求
读DDR 一次不会请求读大于FIFO存储量的突发量。
*/
wire SLAVE_CLK = ddr_core_clk;

slave_axi_async u_slave_axi_async(
    .BUS_CLK             (BUS_CLK             ),
    .SLAVE_CLK           (SLAVE_CLK           ),
    .rst                 (BUS_RST             ),
    .BUS_WR_ADDR         (BUS_WR_ADDR         ),
    .BUS_WR_LEN          (BUS_WR_LEN          ),
    .BUS_WR_ADDR_VALID   (BUS_WR_ADDR_VALID   ),
    .BUS_WR_ADDR_READY   (BUS_WR_ADDR_READY   ),
    .BUS_WR_DATA         (BUS_WR_DATA         ),
    .BUS_WR_STRB         (BUS_WR_STRB         ),
    .BUS_WR_DATA_VALID   (BUS_WR_DATA_VALID   ),
    .BUS_WR_DATA_READY   (BUS_WR_DATA_READY   ),
    .BUS_WR_DATA_LAST    (BUS_WR_DATA_LAST    ),
    .BUS_RD_ADDR         (BUS_RD_ADDR         ),
    .BUS_RD_LEN          (BUS_RD_LEN          ),
    .BUS_RD_ADDR_VALID   (BUS_RD_ADDR_VALID   ),
    .BUS_RD_ADDR_READY   (BUS_RD_ADDR_READY   ),
    .BUS_RD_DATA         (BUS_RD_DATA         ),
    .BUS_RD_DATA_LAST    (BUS_RD_DATA_LAST    ),
    .BUS_RD_DATA_READY   (BUS_RD_DATA_READY   ),
    .BUS_RD_DATA_VALID   (BUS_RD_DATA_VALID   ),
    .SLAVE_WR_ADDR       (SLAVE_WR_ADDR       ),
    .SLAVE_WR_LEN        (SLAVE_WR_LEN        ),
    .SLAVE_WR_ADDR_VALID (SLAVE_WR_ADDR_VALID ),
    .SLAVE_WR_ADDR_READY (SLAVE_WR_ADDR_READY ),
    .SLAVE_WR_DATA       (SLAVE_WR_DATA       ),
    .SLAVE_WR_STRB       (SLAVE_WR_STRB       ),
    .SLAVE_WR_DATA_VALID (SLAVE_WR_DATA_VALID ),
    .SLAVE_WR_DATA_READY (SLAVE_WR_DATA_READY ),
    .SLAVE_WR_DATA_LAST  (SLAVE_WR_DATA_LAST  ),
    .SLAVE_RD_ADDR       (SLAVE_RD_ADDR       ),
    .SLAVE_RD_LEN        (SLAVE_RD_LEN        ),
    .SLAVE_RD_ADDR_VALID (SLAVE_RD_ADDR_VALID ),
    .SLAVE_RD_ADDR_READY (SLAVE_RD_ADDR_READY ),
    .SLAVE_RD_DATA       (SLAVE_RD_DATA       ),
    .SLAVE_RD_DATA_LAST  (SLAVE_RD_DATA_LAST  ),
    .SLAVE_RD_DATA_READY (SLAVE_RD_DATA_READY ),
    .SLAVE_RD_DATA_VALID (SLAVE_RD_DATA_VALID )
);


ddr3_read ddr3_read_inst(
    .clk                (SLAVE_CLK            ),
    .rst                (BUS_RST              ),
    .ddr_init_done      (ddr_init_done        ),

    .RD_ADDR            (SLAVE_RD_ADDR        ),
    .RD_LEN             (SLAVE_RD_LEN         ),
    .RD_ADDR_VALID      (SLAVE_RD_ADDR_VALID  ),
    .RD_ADDR_READY      (SLAVE_RD_ADDR_READY  ),
    
    .RD_DATA            (SLAVE_RD_DATA        ),
    .RD_DATA_LAST       (SLAVE_RD_DATA_LAST   ),
    .RD_DATA_VALID      (SLAVE_RD_DATA_VALID  ),
    .RD_DATA_READY      (SLAVE_RD_DATA_READY  ),

    .READ_ADDR          (READ_ADDR            ),
    .READ_LEN           (READ_LEN             ),
    .READ_ADDR_VALID    (READ_ADDR_VALID      ),
    .READ_ADDR_READY    (READ_ADDR_READY      ),

    .READ_DATA          (READ_DATA            ),
    .READ_DATA_LAST     (READ_DATA_LAST       ),
    .READ_DATA_VALID    (READ_DATA_VALID      )
);

ddr3_write ddr3_write_inst(
    .clk                (SLAVE_CLK            ),
    .rst                (BUS_RST              ),
    .ddr_init_done      (ddr_init_done        ),

    .WR_ADDR            (SLAVE_WR_ADDR        ),
    .WR_LEN             (SLAVE_WR_LEN         ),
    .WR_ADDR_VALID      (SLAVE_WR_ADDR_VALID  ),
    .WR_ADDR_READY      (SLAVE_WR_ADDR_READY  ),

    .WR_DATA            (SLAVE_WR_DATA        ),
    .WR_STRB            (SLAVE_WR_STRB        ),
    .WR_DATA_VALID      (SLAVE_WR_DATA_VALID  ),
    .WR_DATA_READY      (SLAVE_WR_DATA_READY  ),
    .WR_DATA_LAST       (SLAVE_WR_DATA_LAST   ),

    .WRITE_ADDR         (WRITE_ADDR      ),
    .WRITE_LEN          (WRITE_LEN       ),
    .WRITE_ADDR_VALID   (WRITE_ADDR_VALID),
    .WRITE_ADDR_READY   (WRITE_ADDR_READY),

    .WRITE_DATA         (WRITE_DATA      ),
    .WRITE_STRB         (WRITE_STRB      ),
    .WRITE_DATA_READY   (WRITE_DATA_READY),
    .WRITE_DATA_LAST    (WRITE_DATA_LAST )
);


ddr3_top ddr3_top_inst(
    .ddr_ref_clk  (ddr_ref_clk  ),
    .rst_n        (rst_n        ),
    .ddr_core_clk (ddr_core_clk ),
    .ddr_init_done(ddr_init_done),

    .WR_ADDR      (WRITE_ADDR      ),
    .WR_ID        (4'b0000         ),
    .WR_LEN       (WRITE_LEN       ),
    .WR_ADDR_VALID(WRITE_ADDR_VALID),
    .WR_ADDR_READY(WRITE_ADDR_READY),

    .WR_DATA      (WRITE_DATA      ),
    .WR_STRB      (WRITE_STRB      ),
    .WR_DATA_READY(WRITE_DATA_READY),
    .WR_BACK_ID   (                ),
    .WR_DATA_LAST (WRITE_DATA_LAST ),

    .RD_ADDR      (READ_ADDR      ),
    .RD_ID        (4'b0000        ),
    .RD_LEN       (READ_LEN       ),
    .RD_ADDR_VALID(READ_ADDR_VALID),
    .RD_ADDR_READY(READ_ADDR_READY),

    .RD_DATA      (READ_DATA      ),
    .RD_BACK_ID   (               ),
    .RD_DATA_LAST (READ_DATA_LAST ),
    .RD_DATA_VALID(READ_DATA_VALID),

    .mem_rst_n    (mem_rst_n    ),
    .mem_ck       (mem_ck       ),
    .mem_ck_n     (mem_ck_n     ),
    .mem_cs_n     (mem_cs_n     ),
    .mem_a        (mem_a        ),
    .mem_dq       (mem_dq       ),
    .mem_dqs      (mem_dqs      ),
    .mem_dqs_n    (mem_dqs_n    ),
    .mem_dm       (mem_dm       ),
    .mem_cke      (mem_cke      ),
    .mem_odt      (mem_odt      ),
    .mem_ras_n    (mem_ras_n    ),
    .mem_cas_n    (mem_cas_n    ),
    .mem_we_n     (mem_we_n     ),
    .mem_ba       (mem_ba       )
);


endmodule