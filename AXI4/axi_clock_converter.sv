module axi_clock_converter #(
    parameter M_WIDTH = 2,
    parameter S_WIDTH = 2
)(
    input wire BUS_CLK ,        
    input wire BUS_RSTN,        
    input  wire M_CLK  [0:(2**M_WIDTH-1)],
    input  wire M_RSTN [0:(2**M_WIDTH-1)],
    input  wire S_CLK  [0:(2**S_WIDTH-1)],
    input  wire S_RSTN [0:(2**S_WIDTH-1)],
    AXI_INF.M AXI_M_BUS[0:(2**M_WIDTH-1)],
    AXI_INF.S AXI_S_BUS[0:(2**S_WIDTH-1)],
    AXI_INF.S     AXI_M[0:(2**M_WIDTH-1)],
    AXI_INF.M     AXI_S[0:(2**S_WIDTH-1)],
        
    output wire [4:0] M_fifo_empty_flag[0:(2**M_WIDTH-1)],
    output wire [4:0] S_fifo_empty_flag[0:(2**S_WIDTH-1)]
);
/*
AXI CLOCK CONVERTER模块，集中处理各个模块的时钟域转换
fifo的引入同时使主从模块支持了outstanding功能
*/

// 主设备异步桥接模块批量例化
generate
for (genvar i = 0; i < 2**M_WIDTH; i++) begin : gen_master_async
    master_axi_async u_m_axi_async(
        .B_CLK            (BUS_CLK            ),
        .B_RSTN           (BUS_RSTN           ),
        .M_CLK            (M_CLK [i]          ),
        .M_RSTN           (M_RSTN[i]          ),
        .AXI_B            (AXI_M_BUS.M[i]     ),
        .AXI_M            (AXI_M.S[i]         ),
        .fifo_empty_flag  (M_fifo_empty_flag[i])
    );
end
endgenerate


// 从设备异步桥接模块批量例化
generate
for (genvar i = 0; i < 2**M_WIDTH; i++) begin : gen_slave_async
    slave_axi_async u_s_axi_async(
        .B_CLK            (BUS_CLK            ),
        .B_RSTN           (BUS_RSTN           ),
        .S_CLK            (S_CLK [i]          ),
        .S_RSTN           (S_RSTN[i]          ),
        .AXI_B            (AXI_S_BUS.S[i]     ),
        .AXI_S            (AXI_S.M[i]         ),
        .fifo_empty_flag  (S_fifo_empty_flag[i])
    );
end
endgenerate

endmodule