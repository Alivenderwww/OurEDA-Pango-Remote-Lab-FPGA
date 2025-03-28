///////////////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2019 PANGO MICROSYSTEMS, INC
// ALL RIGHTS REVERVED.
//
// THE SOURCE CODE CONTAINED HEREIN IS PROPRIETARY TO PANGO MICROSYSTEMS, INC.
// IT SHALL NOT BE REPRODUCED OR DISCLOSED IN WHOLE OR IN PART OR USED BY
// PARTIES WITHOUT WRITTEN AUTHORIZATION FROM THE OWNER.
//
///////////////////////////////////////////////////////////////////////////////
//
// Library:
// Filename:
///////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns
module data_ctrl
#(
parameter FPGA_VESION           = 48'h2000_0101_1200,   // year,month,day,hour,minute;
parameter USER_BITSTREAM_CNT    = 2'd3              ,
parameter USER_BITSTREAM1_ADDR  = 24'h20_b000       ,   // user bitstream1 start address  ---> [6*4KB+2068KB(2065),32MB- 2068KB(2065)],4KB align  // 24'h20_b000
parameter USER_BITSTREAM2_ADDR  = 24'h41_0000       ,   // user bitstream2 start address  ---> 24'h41_0000 
parameter USER_BITSTREAM3_ADDR  = 24'h61_5000       ,   // user bitstream3 start address  ---> 24'h61_5000
parameter U_DLY                 = 1
)(
input               sys_clk                 ,
input               sys_rst_n               ,

input       [7:0]   rx_data                 ,
input               rx_valid                ,

output      [7:0]   tx_data                 ,
output              tx_valid                ,
input               tx_ready                ,

output              flash_wr_en             ,
output              flash_rd_en             ,
output      [1:0]   bitstream_wr_num        ,
output      [1:0]   bitstream_rd_num        ,
output      [1:0]   bs_crc32_ok             ,//[1]:valid   [0]:1'b0,OK  1'b1,error
output              write_sw_code_en        ,
output              bitstream_up2cpu_en_out ,
output              crc_check_en_out        ,
output              clear_sw_en_out         ,
output              hotreset_en             ,
output      [1:0]   open_sw_num_out         ,

output              spi_status_rd_en        ,
input       [7:0]   spi_status_erorr        ,
input       [15:0]  flash_flag_status       ,
input               time_out_reg            ,

output              flash_cfg_cmd_en        ,
output      [7:0]   flash_cfg_cmd           ,
output      [15:0]  flash_cfg_reg_wrdata    ,
input               flash_cfg_reg_rd_en     ,
input       [15:0]  flash_cfg_reg_rddata    ,


input       [7:0]   flash_rd_data           ,
input               flash_rd_valid          ,
output              flash_rd_data_fifo_afull,

input       [31:0]  bs_readback_crc         ,
input               bs_readback_crc_valid   ,

input               ipal_busy               ,
input               clear_sw_done           ,
input               clear_bs_done           ,
input               bitstream_wr_done       ,
input               bitstream_rd_done       ,
input               open_sw_code_done       ,

input               bitstream_fifo_rd_req   ,
output      [7:0]   bitstream_data          ,
output              bitstream_valid         ,
output              bitstream_eop           ,
output              bitstream_fifo_rd_rdy  
);
//--------------------------------------------------------------------------------
wire               status_rd_en             ;
wire               data_status_rd_en        ;
wire       [7:0]   data_status_erorr        ;
wire       [15:0]  status_erorr             ;// erorr info , uart read for debug


wire                crc_check_en            ;
wire                bitstream_up2cpu_en     ;
wire                open_sw_en              ;
wire        [1:0]   open_sw_num             ;


assign write_sw_code_en         = open_sw_en            ;
assign bitstream_up2cpu_en_out  = bitstream_up2cpu_en   ;
assign crc_check_en_out         = crc_check_en          ;
assign open_sw_num_out          = open_sw_num           ;

//-------------------------------------------------------------------------------
uart_reg_ctrl
#(
    .FPGA_VESION                (FPGA_VESION                ),
    .USER_BITSTREAM_CNT         (USER_BITSTREAM_CNT         ),
    .U_DLY                      (U_DLY                      )
)
u_uart_reg_ctrl(
    .sys_clk                    (sys_clk                    ),
    .sys_rst_n                  (sys_rst_n                  ),

    .rx_data                    (rx_data                    ),
    .rx_valid                   (rx_valid                   ),

    .tx_data                    (tx_data                    ),
    .tx_valid                   (tx_valid                   ),
    .tx_ready                   (tx_ready                   ),

    .status_rd_en               (status_rd_en               ),
    .status_erorr               (status_erorr               ),
    //debug
    .flash_flag_status          (flash_flag_status          ),
    .time_out_reg               (time_out_reg               ),

    .flash_rd_en                (flash_rd_en                ),
    .flash_wr_en                (flash_wr_en                ),
    .flash_rd_data              (flash_rd_data              ),
    .flash_rd_valid             (flash_rd_valid             ),
    .flash_rd_data_fifo_afull   (flash_rd_data_fifo_afull   ),

    .flash_cfg_cmd_en           (flash_cfg_cmd_en           ),
    .flash_cfg_cmd              (flash_cfg_cmd              ),
    .flash_cfg_reg_wrdata       (flash_cfg_reg_wrdata       ),
    .flash_cfg_reg_rd_en        (flash_cfg_reg_rd_en        ),
    .flash_cfg_reg_rddata       (flash_cfg_reg_rddata       ),

    .clear_sw_en_out            (clear_sw_en_out            ),
    .open_sw_en_out             (open_sw_en                 ),
    .open_sw_num_out            (open_sw_num                ),
    .bitstream_up2cpu_en_out    (bitstream_up2cpu_en        ),
    .crc_check_en_out           (crc_check_en               ),
    .bs_readback_crc            (bs_readback_crc            ),
    .bs_readback_crc_valid      (bs_readback_crc_valid      ),
    .bs_crc32_ok                (bs_crc32_ok                ),

    .ipal_busy                  (ipal_busy                  ),
    .hotreset_en_out            (hotreset_en                ),
    .open_sw_code_done          (open_sw_code_done          ),
    .clear_sw_done              (clear_sw_done              ),
    .clear_bs_done              (clear_bs_done              ),
    .bitstream_wr_done          (bitstream_wr_done          ),
    .bitstream_wr_num           (bitstream_wr_num           ),
    .bitstream_rd_num           (bitstream_rd_num           )
);

assign status_erorr     = {spi_status_erorr,data_status_erorr};
assign spi_status_rd_en = status_rd_en;

data_process
#(
    .USER_BITSTREAM_CNT         (USER_BITSTREAM_CNT         ),
    .U_DLY                      (U_DLY                      )
)
u_data_process(
    .sys_clk                    (sys_clk                    ),
    .sys_rst_n                  (sys_rst_n                  ),

    .rx_data                    (rx_data                    ),
    .rx_valid                   (rx_valid                   ),

    .flash_wr_en                (flash_wr_en                ),
    .flash_rd_en                (flash_rd_en                ),
    .bitstream_wr_num           (bitstream_wr_num           ),
    .bitstream_rd_num           (bitstream_rd_num           ),

    .clear_bs_done              (clear_bs_done              ),
    .bs_crc32_ok                (bs_crc32_ok                ),
    .crc_check_en               (crc_check_en               ),
    .write_sw_code_en           (write_sw_code_en           ),
    .write_sw_code_num          (open_sw_num                ),

    .data_status_rd_en          (status_rd_en               ),
    .data_status_erorr          (data_status_erorr          ),

    .bitstream_fifo_rd_req      (bitstream_fifo_rd_req      ),
    .bitstream_data             (bitstream_data             ),
    .bitstream_valid            (bitstream_valid            ),
    .bitstream_eop              (bitstream_eop              ),
    .bitstream_fifo_rd_rdy      (bitstream_fifo_rd_rdy      )
);




endmodule
