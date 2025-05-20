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
    output wire        spi_clk      ,
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
wire spi_clk_en;
//写入比特流-控制接口
wire          flash_wr_en            ;
wire  [11:0]  start_wr_sector    ;
wire  [15:0]  wr_sector_num          ;
wire          flash_wr_done          ;
wire          flash_clear_done       ;
//写入比特流-数据接口
wire        bitstream_fifo_rd_rdy   ;
wire        bitstream_fifo_rd_req   ;
wire        bitstream_valid         ;
wire [7:0]  bitstream_data          ;
wire        bitstream_eop           ;
//读出比特流-控制接口1
wire          flash_rd_en            ;
wire  [11:0]  start_rd_sub_sector    ;
wire  [15:0]  rd_sector_num          ;
wire          flash_rd_done          ;
//读出比特流-控制接口2
wire        bs_readback_crc_valid   ;
wire [31:0] bs_readback_crc         ;
//读出比特流-控制接口3
wire        crc_check_en            ;
wire [1:0]  bs_crc32_ok             ;//[1]:valid   [0]:1'b0,OK  1'b1,error
//读出比特流-回读接口
wire        bitstream_up2cpu_en     ;
wire        flash_rd_data_fifo_afull;
wire [7:0]  flash_rd_data           ;
wire        flash_rd_valid          ;
//热启动接口
wire        hotreset_en             ;
wire [23:0] hotreset_addr           ;
//未知用途
wire        ipal_busy               ;
wire        time_out_reg            ;
//弃用
wire [15:0] flash_flag_status       ;
wire        flash_cfg_cmd_en        ;
wire [7:0]  flash_cfg_cmd           ;
wire [15:0] flash_cfg_reg_wrdata    ;
wire        flash_cfg_reg_rd_en     ;
wire [15:0] flash_cfg_reg_rddata    ;

assign spi_clk = clk;

wire RU_RSTN_SYNC;
rstn_sync ru_top_rstn_sync(clk,rstn,RU_RSTN_SYNC);

//--------------------------------------------------------------------------
// clear is 4KB align , so the bitstream write data is 4KB align 
//--------------------------------------------------------------------------
data_ctrl_slave
#(
    .OFFSET_ADDR                (OFFSET_ADDR                ),
    .FPGA_VERSION               (FPGA_VERSION               )
)data_ctrl_master_inst(
    .clk                        (clk                    ),
    .rstn                       (RU_RSTN_SYNC           ),

    .flash_wr_en                (flash_wr_en            ),
    .start_wr_sector            (start_wr_sector        ),
    .wr_sector_num              (wr_sector_num          ),
    .flash_wr_done              (flash_wr_done          ),
    .flash_clear_done           (flash_clear_done       ),

    .bitstream_fifo_rd_req      (bitstream_fifo_rd_req  ),
    .bitstream_data             (bitstream_data         ),
    .bitstream_valid            (bitstream_valid        ),
    .bitstream_eop              (bitstream_eop          ),
    .bitstream_fifo_rd_rdy      (bitstream_fifo_rd_rdy  ),

    .flash_rd_en                (flash_rd_en            ),
    .start_rd_sub_sector        (start_rd_sub_sector    ),
    .rd_sector_num              (rd_sector_num          ),
    .flash_rd_done              (flash_rd_done          ),

    .bs_readback_crc_valid      (bs_readback_crc_valid  ),
    .bs_readback_crc            (bs_readback_crc        ),

    .crc_check_en               (crc_check_en           ),
    .bs_crc32_ok                (bs_crc32_ok            ),

    .bitstream_up2cpu_en        (bitstream_up2cpu_en        ),
    .flash_rd_data              (flash_rd_data              ),
    .flash_rd_valid             (flash_rd_valid             ),
    .flash_rd_data_fifo_afull   (flash_rd_data_fifo_afull   ),

    .hotreset_en                (hotreset_en                ),
    .hotreset_addr              (hotreset_addr                ),

    .flash_flag_status          (flash_flag_status          ),
    .time_out_reg               (time_out_reg               ),
    
    .ipal_busy                  (ipal_busy                  ),
    .flash_cfg_cmd_en           (flash_cfg_cmd_en           ),
    .flash_cfg_cmd              (flash_cfg_cmd              ),
    .flash_cfg_reg_wrdata       (flash_cfg_reg_wrdata       ),
    .flash_cfg_reg_rd_en        (flash_cfg_reg_rd_en        ),
    .flash_cfg_reg_rddata       (flash_cfg_reg_rddata       ),

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
spi_top u_spi_top(
    .sys_clk                    (clk                    ),
    .sys_rst_n                  (RU_RSTN_SYNC           ),
 
    .spi_cs                     (spi_cs                     ),
    .spi_clk_en                 (spi_clk_en                 ),
    .spi_dq1                    (spi_dq1                    ),
    .spi_dq0                    (spi_dq0                    ),
// ctrl 使能控制信号
    .flash_wr_en                (flash_wr_en                ), //写位流数据使能，上升沿有效
    .start_wr_sector            (start_wr_sector            ),
    .wr_sector_num              (wr_sector_num              ),
    .flash_wr_done              (flash_wr_done              ),
    .flash_clear_done           (flash_clear_done           ), //擦除应用位流完成指示，高有效

    .flash_rd_en                (flash_rd_en                ), //读位流数据使能，上升沿有效
    .start_rd_sub_sector        (start_rd_sub_sector        ),
    .rd_sector_num              (rd_sector_num              ),
    .flash_rd_done              (flash_rd_done              ),
    
    .bitstream_up2cpu_en        (bitstream_up2cpu_en        ), //位流上传上位机使能，高有效。使能后，回读校验时上传位流
    .crc_check_en               (crc_check_en               ), //CRC32 校验使能，高有效。若不使能，则不进行回读校验
    .bs_crc32_ok                (bs_crc32_ok                ), //[1]:为 1 则表示校验结果有效；[0]:校验结果，1’b0:校验正确，1’b1:校验错误
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
    .time_out_reg               (time_out_reg               ), //擦除 flash 超时指示，高有效

// write bitstream 写 flash 数据接口(前级数据缓存需要用包 FIFO)
    .bitstream_fifo_rd_req      (bitstream_fifo_rd_req      ), //写入 flash 位流文件缓存 FIFO 读请求
    .bitstream_data             (bitstream_data             ), //写入 flash 位流文件缓存 FIFO 读出数据
    .bitstream_valid            (bitstream_valid            ), //写入 flash 位流文件缓存 FIFO 读出数据有效
    .bitstream_eop              (bitstream_eop              ), //写入 flash 位流文件缓存 FIFO 数据包尾标识。每个数据包256字节(1 个 page)，方便后续处理
    .bitstream_fifo_rd_rdy      (bitstream_fifo_rd_rdy      )  //写入 flash 位流文件缓存 FIFO 非空
);


ipal_ctrl u_ipal_ctrl(
    .sys_clk                    (clk                    ),
    .sys_rst_n                  (RU_RSTN_SYNC           ),

    .hotreset_addr              (hotreset_addr          ),
    .ipal_busy                  (ipal_busy              ),
    .crc_check_en               (crc_check_en           ),
    .bs_crc32_ok                (bs_crc32_ok            ),
    .hotreset_en                (hotreset_en            )
);

////-----------------------------------------------------------

GTP_CFGCLK u_gtp_cfgclk (
    .CE_N                       (spi_clk_en             ),   
    .CLKIN                      (clk                    )  
);
//-----------------------------------------------------------------------------------------------------

/*
上位机修改start_wr_sector为想要写入的Flash首扇区号，wr_sector_num为写入的扇区个数，同时拉高flash_wr_en。
等待flash_clear_done拉高，擦除完成，可以写入。
往写比特流入口写入数据。32bit需做翻转。
写完后，等待flash_wr_done拉高，表示写入完成。

上位机配置读出控制bs_crc32_ok，crc_check_en，bitstream_up2cpu_en。
上位机修改start_rd_sector为想要读出的Flash首扇区号，rd_sector_num为读出的扇区个数，同时拉高flash_rd_en。
如果设置了bitstream_up2cpu_en，需要从读比特流入口读出数据。
直到flash_rd_done拉高，表示读出完成。可完成CRC校验。

热启动需配置hotreset_addr，拉高hotreset_en。
*/



endmodule //remote_update_axi_slave




