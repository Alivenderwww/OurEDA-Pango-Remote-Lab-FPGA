// *********************************************************************************/
// Project Name :
// File Name    : cellfifo_logic.v
// Module Name  : cellfifo_logic
// Called By    :
// Abstract     : 1. 支持同步/异步切片fifo，与包fifo兼容
//                2. 存储切片/包时可以背靠背
//                3. 浪费1个地址空间来避免出现既空又满的情况
//                4. 根据MAX_LEN的设置来自动丢弃超长切片/包
//                5. fifo溢出时自动丢弃切片/包
//                6. 丢弃用户打了err标记的切片/包
//                7. 利用RAM的clock enable来实现预读功能
//                8. RAM读口支持寄存、不寄存，甚至是寄存多拍再输出
//                9. 任何时候拉低rd_req都会停止从fifo中读数
//                10.读数据的相位与rd_req保持一致，无任何延时
//                11.当且仅当rd_rdy和rd_req同时为1时才能正确读出数据
//                12.MAX_LEN设置合理可以提升可靠性
//                13.时序不是瓶颈
//
//
// *********************************************************************************/
// Modification History:
// 1. initial
// *********************************************************************************/
// *************************
// MODULE DEFINITION
// *************************
`timescale 1 ns / 1 ns
module cellfifo_logic #(
parameter                           SYNC_NUM_W2R = 3,
parameter                           SYNC_NUM_R2W = 3,
parameter                           ASYNC_MODE   = 1,   // 1: asynchronous fifo, 0: synchronous fifo
parameter                           ADDR_SIZE    = 9,
parameter                           DATA_SIZE    = 36,
parameter                           MAX_LEN      = 16,  // maximum cell/packet length, very important refer to dead state
parameter                           AFULL_NUM    = 2**9-1-16,
parameter                           AEMPTY_NUM   = 1,
parameter                           RAM_LATENCY  = 2,   // delay from read address to read data
parameter                           U_DLY = 1
)
(
input                               rst_w_n,
input                               clk_w,
input                               wr_vld,
input           [DATA_SIZE-1:0]     wr_data,    // maybe include sop, eop, mod, data and so on
input                               wr_eoc,     // write end of cell/packet
input                               wr_drop,    // align with wr_eoc, active high
output wire                         wr_full,
output wire                         wr_afull,
output wire                         wr_over,    // overflow, wr_vld still assert when fifo full
output wire     [ADDR_SIZE-1:0]     wr_used,    // fifo number of write side based on bytes
input                               rst_r_n,
input                               clk_r,
output wire                         rd_rdy,     // indicate that fifo has at least one whole cell/packet
input                               rd_req,
output wire                         rd_vld,
output wire                         rd_eoc,
output wire     [DATA_SIZE-1:0]     rd_data,
output wire                         rd_empty,
output wire                         rd_aempty,
output wire     [ADDR_SIZE-1:0]     rd_used,
output wire                         ram_wen,
output wire     [ADDR_SIZE-1:0]     ram_waddr,
output wire     [DATA_SIZE:0]       ram_wdata,
output wire                         ram_rcken,  // clock enable for read port
output wire     [ADDR_SIZE-1:0]     ram_raddr,
input           [DATA_SIZE:0]       ram_rdata,
output wire                         fifo_err    // encount oversize cell/packet
);
// Parameter Define 

// Register Define 

// Wire Define 
wire            [ADDR_SIZE-1:0]     waddr2rd;
wire            [ADDR_SIZE-1:0]     raddr2wr;
wire                                waddr_togf;
wire                                waddr_togb;

// basic waveform(cell read side)
//             ___ ___________________________________________________________
// waddr2rd    ___X___________________________________________________________
//                |<-- waddr2rd refresh means that a completed cell
//                     is done, after a few clocks rd_rdy asserts
//                            ______________________________________
// rd_rdy(0)   ______________|                                      |_________
//                                 _________________________________
// rd_req(i)   ___________________|                                 |_________
//                                 _________________________________
// rd_vld(o)   ___________________|                                 |_________
//                                |<-- read data is prefetched, if rd_rdy is high,
//                                     each rd_req read a cell data without latency
//                                                              ____
// rd_eoc(o)   ________________________________________________|    |_________
//                                      a completed cell is done -->|
//

cellfifo_wr_logic #(
    .ADDR_SIZE                  (ADDR_SIZE                  ),
    .DATA_SIZE                  (DATA_SIZE                  ),
    .SYNC_NUM                   (SYNC_NUM_R2W               ),
    .MAX_LEN                    (MAX_LEN                    ),
    .AFULL_NUM                  (AFULL_NUM                  ),
    .ASYNC_MODE                 (ASYNC_MODE                 )
) u_wr_logic (
    .rst_n                      (rst_w_n                    ),
    .clk                        (clk_w                      ),
    .wr_vld                     (wr_vld                     ),
    .wr_data                    (wr_data                    ),
    .wr_eoc                     (wr_eoc                     ),
    .wr_drop                    (wr_drop                    ),
    .wr_full                    (wr_full                    ),
    .wr_afull                   (wr_afull                   ),
    .wr_over                    (wr_over                    ),
    .wr_used                    (wr_used                    ),
    .waddr2rd                   (waddr2rd                   ),
    .waddr_togf                 (waddr_togf                 ),
    .waddr_togb                 (waddr_togb                 ),
    .raddr2wr                   (raddr2wr                   ),
    .ram_wen                    (ram_wen                    ),
    .ram_waddr                  (ram_waddr                  ),
    .ram_wdata                  (ram_wdata                  ),
    .fifo_err                   (fifo_err                   )
);

cellfifo_rd_logic #(
    .ADDR_SIZE                  (ADDR_SIZE                  ),
    .DATA_SIZE                  (DATA_SIZE                  ),
    .SYNC_NUM                   (SYNC_NUM_W2R               ),
    .ASYNC_MODE                 (ASYNC_MODE                 ),
    .AEMPTY_NUM                 (AEMPTY_NUM                 ),
    .RAM_LATENCY                (RAM_LATENCY                )
) u_rd_logic (
    .rst_n                      (rst_r_n                    ),
    .clk                        (clk_r                      ),
    .rd_rdy                     (rd_rdy                     ),
    .rd_req                     (rd_req                     ),
    .rd_vld                     (rd_vld                     ),
    .rd_data                    (rd_data                    ),
    .rd_eoc                     (rd_eoc                     ),
    .rd_empty                   (rd_empty                   ),
    .rd_aempty                  (rd_aempty                  ),
    .rd_used                    (rd_used                    ),
    .waddr2rd                   (waddr2rd                   ),
    .waddr_togf                 (waddr_togf                 ),
    .waddr_togb                 (waddr_togb                 ),
    .raddr2wr                   (raddr2wr                   ),
    .ram_rcken                  (ram_rcken                  ),
    .ram_raddr                  (ram_raddr                  ),
    .ram_rdata                  (ram_rdata                  )
);

endmodule

