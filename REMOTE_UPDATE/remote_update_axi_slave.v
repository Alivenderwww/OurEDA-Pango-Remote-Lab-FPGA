module remote_update_axi_slave #(
    parameter OFFSET_ADDR           = 32'h3000_0000     ,
    parameter FPGA_VERSION           = 48'h2024_1119_1943,   // year,month,day,hour,minute;
    parameter DEVICE                = "PG2L100H"        ,   // "PG2L200H":bitstream 8974KB;8c4_000 "PG2L100H":bitstream 3703KB;39e_000 "PG2L50H":bitstream 2065KB;204_400 "PG2L25H":bitstream 1168KB;124_000
    parameter USER_BITSTREAM_CNT    = 2'd1              ,   // user bitstream count,2'd1,2'd2,2'd3 ----> there are 1/2/3 user bitstream in the flash,at least 1 bitstream.
    parameter USER_BITSTREAM1_ADDR  = 24'h3a_0000       ,   // user bitstream1 start address  ---> [6*4KB+2068KB(2065),32MB- 2068KB(2065)],4KB align  // 24'h20_b000
    parameter USER_BITSTREAM2_ADDR  = 24'h41_0000       ,   // user bitstream2 start address  ---> 24'h41_0000 
    parameter USER_BITSTREAM3_ADDR  = 24'h61_5000           // user bitstream3 start address  ---> 24'h61_5000
)(
    //___________________其他接口_____________________//
    input  wire        clk          , //10Mhz need
    input  wire        rstn         ,
    
    output wire        spi_cs       ,
    input  wire        spi_dq1      ,
    output wire        spi_dq0      ,

    //___________________AXI接口_____________________//
    output wire        SLAVE_CLK          , //向AXI总线提供的本主机时钟信号
    output wire        SLAVE_RSTN         , //向AXI总线提供的本主机复位信号

    input  wire [ 3:0] SLAVE_WR_ADDR_ID   , //写地址通道-ID
    input  wire [31:0] SLAVE_WR_ADDR      , //写地址通道-地址
    input  wire [ 7:0] SLAVE_WR_ADDR_LEN  , //写地址通道-突发长度-最小为0（1突发），最大为255（256突发）
    input  wire [ 1:0] SLAVE_WR_ADDR_BURST, //写地址通道-突发类型
    input  wire        SLAVE_WR_ADDR_VALID, //写地址通道-握手信号-有效
    output wire        SLAVE_WR_ADDR_READY, //写地址通道-握手信号-准备

    input  wire [31:0] SLAVE_WR_DATA      , //写数据通道-数据
    input  wire [ 3:0] SLAVE_WR_STRB      , //写数据通道-选通
    input  wire        SLAVE_WR_DATA_LAST , //写数据通道-last信号
    input  wire        SLAVE_WR_DATA_VALID, //写数据通道-握手信号-有效
    output wire        SLAVE_WR_DATA_READY, //写数据通道-握手信号-准备

    output wire [ 3:0] SLAVE_WR_BACK_ID   , //写响应通道-ID
    output wire [ 1:0] SLAVE_WR_BACK_RESP , //写响应通道-响应 //SLAVE_WR_DATA_LAST拉高的同时或者之后 00 01正常 10写错误 11地址有问题找不到从机
    output wire        SLAVE_WR_BACK_VALID, //写响应通道-握手信号-有效
    input  wire        SLAVE_WR_BACK_READY, //写响应通道-握手信号-准备

    input  wire [ 3:0] SLAVE_RD_ADDR_ID   , //读地址通道-ID
    input  wire [31:0] SLAVE_RD_ADDR      , //读地址通道-地址
    input  wire [ 7:0] SLAVE_RD_ADDR_LEN  , //读地址通道-突发长度。最小为0（1突发），最大为255（256突发）
    input  wire [ 1:0] SLAVE_RD_ADDR_BURST, //读地址通道-突发类型。
    input  wire        SLAVE_RD_ADDR_VALID, //读地址通道-握手信号-有效
    output wire        SLAVE_RD_ADDR_READY, //读地址通道-握手信号-准备

    output wire [ 3:0] SLAVE_RD_BACK_ID   , //读数据通道-ID
    output wire [31:0] SLAVE_RD_DATA      , //读数据通道-数据
    output wire [ 1:0] SLAVE_RD_DATA_RESP , //读数据通道-响应
    output wire        SLAVE_RD_DATA_LAST , //读数据通道-last信号
    output wire        SLAVE_RD_DATA_VALID, //读数据通道-握手信号-有效
    input  wire        SLAVE_RD_DATA_READY  //读数据通道-握手信号-准备
);


//-----------------------------------------------------------
wire        flash_rd_en             ;
wire        flash_wr_en             ;

wire        flash_cfg_cmd_en        ;
wire [ 7:0] flash_cfg_cmd           ;
wire [15:0] flash_cfg_reg_wrdata    ;
wire        flash_cfg_reg_rd_en     ;
wire [15:0] flash_cfg_reg_rddata    ;

wire [ 7:0]  flash_rd_data           ;
wire         flash_rd_valid          ;
wire         flash_rd_data_fifo_afull;

wire [31:0] bs_readback_crc         ;
wire        bs_readback_crc_valid   ;

wire        open_sw_code_done       ;
wire        bitstream_wr_done       ;
wire        bitstream_rd_done       ;
wire [ 1:0] bitstream_wr_num        ;
wire [ 1:0] bitstream_rd_num        ;

wire        bitstream_fifo_rd_req   ;
wire [ 7:0] bitstream_data          ;
wire        bitstream_valid         ;
wire        bitstream_eop           ;
wire        bitstream_fifo_rd_rdy   ;

wire       clear_bs_done           ;
wire       clear_sw_done           ;

wire [ 1:0] bs_crc32_ok             ;//[1]:valid   [0]:1'b0,OK  1'b1,error
wire        write_sw_code_en        ;
wire        bitstream_up2cpu_en     ;
wire        crc_check_en            ;
wire        clear_sw_en             ;
wire        spi_clk_en              ;
wire        hotreset_en             ;
wire [ 1:0] open_sw_num             ;
wire        ipal_busy               ;

wire [15:0] flash_flag_status       ;
wire        time_out_reg            ;




//--------------------------------------------------------------------------
// clear is 4KB align , so the bitstream write data is 4KB align 
//--------------------------------------------------------------------------
data_ctrl_slave
#(
    .OFFSET_ADDR                (OFFSET_ADDR                ),
    .FPGA_VERSION                (FPGA_VERSION                ),  
    .USER_BITSTREAM_CNT         (USER_BITSTREAM_CNT         ),
    .USER_BITSTREAM1_ADDR       (USER_BITSTREAM1_ADDR       ),
    .USER_BITSTREAM2_ADDR       (USER_BITSTREAM2_ADDR       ),
    .USER_BITSTREAM3_ADDR       (USER_BITSTREAM3_ADDR       )
)data_ctrl_master_inst(
    .clk                        (clk                        ),
    .rstn                      (rstn                       ),

    .flash_rd_en                (flash_rd_en                ),
    .flash_wr_en                (flash_wr_en                ),
    .bitstream_wr_num           (bitstream_wr_num           ),
    .bitstream_rd_num           (bitstream_rd_num           ),
    .bs_crc32_ok                (bs_crc32_ok                ),
    .write_sw_code_en           (write_sw_code_en           ),
    .bitstream_up2cpu_en        (bitstream_up2cpu_en        ),
    .crc_check_en               (crc_check_en               ),
    .clear_sw_en                (clear_sw_en                ),
    .hotreset_en                (hotreset_en                ),
    .open_sw_num                (open_sw_num                ),

    .flash_flag_status          (flash_flag_status          ),
    .time_out_reg               (time_out_reg               ),

    .flash_cfg_cmd_en           (flash_cfg_cmd_en           ),
    .flash_cfg_cmd              (flash_cfg_cmd              ),
    .flash_cfg_reg_wrdata       (flash_cfg_reg_wrdata       ),
    .flash_cfg_reg_rd_en        (flash_cfg_reg_rd_en        ),
    .flash_cfg_reg_rddata       (flash_cfg_reg_rddata       ),

    .flash_rd_data              (flash_rd_data              ),
    .flash_rd_valid             (flash_rd_valid             ),
    .flash_rd_data_fifo_afull   (flash_rd_data_fifo_afull   ),

    .bs_readback_crc            (bs_readback_crc            ),
    .bs_readback_crc_valid      (bs_readback_crc_valid      ),
    
    .ipal_busy                  (ipal_busy                  ),
    .clear_sw_done              (clear_sw_done              ),
    .clear_bs_done              (clear_bs_done              ),
    .bitstream_wr_done          (bitstream_wr_done          ),
    .bitstream_rd_done          (bitstream_rd_done          ),
    .open_sw_code_done          (open_sw_code_done          ),

    .bitstream_fifo_rd_req      (bitstream_fifo_rd_req      ),
    .bitstream_data             (bitstream_data             ),
    .bitstream_valid            (bitstream_valid            ),
    .bitstream_eop              (bitstream_eop              ),
    .bitstream_fifo_rd_rdy      (bitstream_fifo_rd_rdy      ),

    .SLAVE_CLK                  (SLAVE_CLK                  ),
    .SLAVE_RSTN                 (SLAVE_RSTN                 ),
    .SLAVE_WR_ADDR_ID           (SLAVE_WR_ADDR_ID           ),
    .SLAVE_WR_ADDR              (SLAVE_WR_ADDR              ),
    .SLAVE_WR_ADDR_LEN          (SLAVE_WR_ADDR_LEN          ),
    .SLAVE_WR_ADDR_BURST        (SLAVE_WR_ADDR_BURST        ),
    .SLAVE_WR_ADDR_VALID        (SLAVE_WR_ADDR_VALID        ),
    .SLAVE_WR_ADDR_READY        (SLAVE_WR_ADDR_READY        ),
    .SLAVE_WR_DATA              (SLAVE_WR_DATA              ),
    .SLAVE_WR_STRB              (SLAVE_WR_STRB              ),
    .SLAVE_WR_DATA_LAST         (SLAVE_WR_DATA_LAST         ),
    .SLAVE_WR_DATA_VALID        (SLAVE_WR_DATA_VALID        ),
    .SLAVE_WR_DATA_READY        (SLAVE_WR_DATA_READY        ),
    .SLAVE_WR_BACK_ID           (SLAVE_WR_BACK_ID           ),
    .SLAVE_WR_BACK_RESP         (SLAVE_WR_BACK_RESP         ),
    .SLAVE_WR_BACK_VALID        (SLAVE_WR_BACK_VALID        ),
    .SLAVE_WR_BACK_READY        (SLAVE_WR_BACK_READY        ),
    .SLAVE_RD_ADDR_ID           (SLAVE_RD_ADDR_ID           ),
    .SLAVE_RD_ADDR              (SLAVE_RD_ADDR              ),
    .SLAVE_RD_ADDR_LEN          (SLAVE_RD_ADDR_LEN          ),
    .SLAVE_RD_ADDR_BURST        (SLAVE_RD_ADDR_BURST        ),
    .SLAVE_RD_ADDR_VALID        (SLAVE_RD_ADDR_VALID        ),
    .SLAVE_RD_ADDR_READY        (SLAVE_RD_ADDR_READY        ),
    .SLAVE_RD_BACK_ID           (SLAVE_RD_BACK_ID           ),
    .SLAVE_RD_DATA              (SLAVE_RD_DATA              ),
    .SLAVE_RD_DATA_RESP         (SLAVE_RD_DATA_RESP         ),
    .SLAVE_RD_DATA_LAST         (SLAVE_RD_DATA_LAST         ),
    .SLAVE_RD_DATA_VALID        (SLAVE_RD_DATA_VALID        ),
    .SLAVE_RD_DATA_READY        (SLAVE_RD_DATA_READY        )
);


//-----------------------------------------------------------
spi_top
#(
    .DEVICE                     (DEVICE                     ), 
    .USER_BITSTREAM_CNT         (USER_BITSTREAM_CNT         ),
    .USER_BITSTREAM1_ADDR       (USER_BITSTREAM1_ADDR       ),
    .USER_BITSTREAM2_ADDR       (USER_BITSTREAM2_ADDR       ),
    .USER_BITSTREAM3_ADDR       (USER_BITSTREAM3_ADDR       )                 
)
u_spi_top
(
    .sys_clk                    (clk                    ),
    .sys_rst_n                  (rstn                   ),
 
    .spi_cs                     (spi_cs                     ),
    .spi_clk_en                 (spi_clk_en                 ),
    .spi_dq1                    (spi_dq1                    ),
    .spi_dq0                    (spi_dq0                    ),
// ctrl 使能控制信号
    .flash_wr_en                (flash_wr_en                ), //写位流数据使能，上升沿有效
    .flash_rd_en                (flash_rd_en                ), //读位流数据使能，上升沿有效
    .bitstream_wr_num           (bitstream_wr_num           ), //写位流序号，用于指定更新的应用位流。可支持1/2/3 号应用位流，且不超过参数 USER_BITSTREAM_CNT
    .bitstream_rd_num           (bitstream_rd_num           ), //读位流序号，用于指定读取的应用位流。可支持1/2/3 号应用位流，且不超过参数 USER_BITSTREAM_CNT
    .bitstream_up2cpu_en        (bitstream_up2cpu_en        ), //位流上传上位机使能，高有效。使能后，回读校验时上传位流
    .crc_check_en               (crc_check_en               ), //CRC32 校验使能，高有效。若不使能，则不进行回读校验
    .clear_sw_en                (clear_sw_en                ), //单独擦除开关使能，上升沿有效
    .bs_crc32_ok                (bs_crc32_ok                ), //[1]:为 1 则表示校验结果有效；[0]:校验结果，1’b0:校验正确，1’b1:校验错误
    .write_sw_code_en           (write_sw_code_en           ), //写开关使能，上升沿有效
// debug 读/写FLASH芯片配置寄存器及状态指示信号。不使用输入接0，输出悬空
    .flash_flag_status          (flash_flag_status          ),

    .flash_cfg_cmd_en           (flash_cfg_cmd_en           ),
    .flash_cfg_cmd              (flash_cfg_cmd              ),
    .flash_cfg_reg_wrdata       (flash_cfg_reg_wrdata       ),
    .flash_cfg_reg_rd_en        (flash_cfg_reg_rd_en        ),
    .flash_cfg_reg_rddata       (flash_cfg_reg_rddata       ),
// read bitstream 回读数据接口
    .flash_rd_data_o            (flash_rd_data              ), //读位流数据
    .flash_rd_valid_o           (flash_rd_valid             ), //读位流数据有效
    .flash_rd_data_fifo_afull   (flash_rd_data_fifo_afull   ), //读位流数据缓存 FIFO 将满
// readback_crc & done 反馈指示信号
    .bs_readback_crc            (bs_readback_crc            ), //读位流校验 CRC 结果
    .bs_readback_crc_valid      (bs_readback_crc_valid      ), //为 1 表示读位流校验 CRC 结果有效
    
    .clear_sw_done              (clear_sw_done              ), //单独擦除开关完成指示，高有效
    .clear_bs_done              (clear_bs_done              ), //擦除应用位流完成指示，高有效
    .bitstream_wr_done          (bitstream_wr_done          ), //写位流文件完成，高有效
    .bitstream_rd_done          (bitstream_rd_done          ), //读位流文件完成，高有效
    .open_sw_code_done          (open_sw_code_done          ), //写开关程序完成，高有效
    .time_out_reg               (time_out_reg               ), //擦除 flash 超时指示，高有效
// write bitstream 写 flash 数据接口(前级数据缓存需要用包 FIFO)
    .bitstream_fifo_rd_req      (bitstream_fifo_rd_req      ), //写入 flash 位流文件缓存 FIFO 读请求
    .bitstream_data             (bitstream_data             ), //写入 flash 位流文件缓存 FIFO 读出数据
    .bitstream_valid            (bitstream_valid            ), //写入 flash 位流文件缓存 FIFO 读出数据有效
    .bitstream_eop              (bitstream_eop              ), //写入 flash 位流文件缓存 FIFO 数据包尾标识。每个数据包256字节(1 个 page)，方便后续处理
    .bitstream_fifo_rd_rdy      (bitstream_fifo_rd_rdy      )  //写入 flash 位流文件缓存 FIFO 非空
);


ipal_ctrl#(
    .USER_BITSTREAM_CNT         (USER_BITSTREAM_CNT         ),
    .USER_BITSTREAM1_ADDR       (USER_BITSTREAM1_ADDR       ),
    .USER_BITSTREAM2_ADDR       (USER_BITSTREAM2_ADDR       ),
    .USER_BITSTREAM3_ADDR       (USER_BITSTREAM3_ADDR       )
)
u_ipal_ctrl(
    .sys_clk                    (clk                    ),
    .sys_rst_n                  (rstn                   ),

    .open_sw_num                (open_sw_num                ),
    .ipal_busy                  (ipal_busy                  ),
    .crc_check_en               (crc_check_en               ),
    .bs_crc32_ok                (bs_crc32_ok                ),
    .hotreset_en                (hotreset_en                ),
    .open_sw_code_done          (open_sw_code_done          )
);

////-----------------------------------------------------------

GTP_CFGCLK u_gtp_cfgclk (
    .CE_N                       (spi_clk_en                 ),   
    .CLKIN                      (clk                    )  
);
//-----------------------------------------------------------------------------------------------------

/*
spi_top控制逻辑（sys_clk时钟域下）

写入比特流-控制流程：
0. 上位机将 bitstream_wr_num 修改为想要重新写的应用位流num号
1. 上位机将 flash_wr_en 置1，模块自动置0
2. 等待擦除开关程序和应用位流完成
3. 模块将 clear_bs_done 置1，标志擦除完成指示
4. 上位机发送比特流（详见写入比特流-数据流程）
5. 模块将 bitstream_wr_done 置1，标志写位流完成，写入比特流流程结束

写入比特流-数据流程：
bitstream_fifo_rd_rdy 非空（ >256字节 ）
收到 bitstream_fifo_rd_req ， bitstream_fifo_rd_valid立即拉高
发送完256字节的同时拉高一下eop。rdy拉低。


读出比特流-控制流程：
0. 上位机将 bitstream_rd_num 修改为想要读的应用位流num号
1. 上位机将 flash_rd_en 置1，模块自动置0
2. 等待读位流完成，如果 bitstream_up2cpu_en 为1，模块会同时把位流送进回读数据接口（详见读出比特流-数据流程）
3. 模块将 bitstream_rd_done 置1，标志读位流完成
4. 模块同时将 crc_valid 置1，修改 readback_crc 为读位流的CRC校验值，向上级模块提供本次读位流的CRC校验值
5. 若 crc_check_en 为1，上位机需修改 bs_crc32_ok 为CRC校验结果，模块会接收；否则直接置 bs_crc32_ok = 2'b10。读出比特流流程结束

读出比特流-数据流程：
flash_rd_data_fifo_afull 为0（至少预留出256字节空余）
flash_rd_valid 拉高，连续256周期写入数据
写入后若flash_rd_data_fifo_afull 为1，则等待直至拉低。若为0则继续写入。

单独擦除开关流程：
0. 上位机将 clear_sw_en 置1 
1. 等待擦除完毕
2. 模块将 clear_sw_done 置1，单独擦除开关流程结束

写开关流程：
0. 配置 open_sw_num
1. 上位机将 write_sw_code_en 置1 
2. 等待打开开关程序
3. 模块将 open_sw_code_done 置1，写开关流程结束

热启动流程：
0. 若 crc_check_en 为1，则会根据 bs_crc32_ok 选择启动哪一个位流。
1. 若 crc_check_en 为0，则会根据 open_sw_num 选择启动的位流。
2. 上位机将 hotreset_en 置1，开始热启动，系统复位。

上位机完成一次更新比特流的顺序：
1. 执行"写入比特流"流程
2. crc_valid 置0，无需读回。
3. 执行"读出比特流"流程，得到CRC校验值
4. 上位机判断CRC校验值是否正确，若正确则继续，否则重新写入比特流
5. 如果不想重新启动，到此结束。否则从"热启动顺序"开始。

上位机完成一次热启动的顺序：
1. 执行"单独擦除开关流程"流程
1. 执行"写开关流程"流程，打开想要启动的位流
2. 执行"热启动流程"流程

上位机完成一次回读比特流的顺序：
0. crc_valid 置1，设置读回。
1. 执行"读出比特流"流程，得到回读文件和校验值。

*/



endmodule //remote_update_axi_slave




