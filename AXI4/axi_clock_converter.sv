module axi_clock_converter #(
    parameter M_WIDTH = 2,
    parameter S_WIDTH = 2,
    parameter M_ID    = 2,
    parameter [0:(2**M_WIDTH-1)] M_ASYNC_ON = {1'b1, 1'b1, 1'b1, 1'b1},
    parameter [0:(2**S_WIDTH-1)] S_ASYNC_ON = {1'b1, 1'b1, 1'b1, 1'b1}
)(
    input wire BUS_CLK ,
    input wire BUS_RSTN,
    output [(2**M_WIDTH-1):0] [M_ID-1:0] M_B_WR_ADDR_ID   ,
    output [(2**M_WIDTH-1):0] [31:0]     M_B_WR_ADDR      ,
    output [(2**M_WIDTH-1):0] [ 7:0]     M_B_WR_ADDR_LEN  ,
    output [(2**M_WIDTH-1):0] [ 1:0]     M_B_WR_ADDR_BURST,
    output [(2**M_WIDTH-1):0]            M_B_WR_ADDR_VALID,
    input  [(2**M_WIDTH-1):0]            M_B_WR_ADDR_READY,
    output [(2**M_WIDTH-1):0] [31:0]     M_B_WR_DATA      ,
    output [(2**M_WIDTH-1):0] [ 3:0]     M_B_WR_STRB      ,
    output [(2**M_WIDTH-1):0]            M_B_WR_DATA_LAST ,
    output [(2**M_WIDTH-1):0]            M_B_WR_DATA_VALID,
    input  [(2**M_WIDTH-1):0]            M_B_WR_DATA_READY,
    input  [(2**M_WIDTH-1):0] [M_ID-1:0] M_B_WR_BACK_ID   ,
    input  [(2**M_WIDTH-1):0] [ 1:0]     M_B_WR_BACK_RESP ,
    input  [(2**M_WIDTH-1):0]            M_B_WR_BACK_VALID,
    output [(2**M_WIDTH-1):0]            M_B_WR_BACK_READY,
    output [(2**M_WIDTH-1):0] [M_ID-1:0] M_B_RD_ADDR_ID   ,
    output [(2**M_WIDTH-1):0] [31:0]     M_B_RD_ADDR      ,
    output [(2**M_WIDTH-1):0] [ 7:0]     M_B_RD_ADDR_LEN  ,
    output [(2**M_WIDTH-1):0] [ 1:0]     M_B_RD_ADDR_BURST,
    output [(2**M_WIDTH-1):0]            M_B_RD_ADDR_VALID,
    input  [(2**M_WIDTH-1):0]            M_B_RD_ADDR_READY,
    input  [(2**M_WIDTH-1):0] [M_ID-1:0] M_B_RD_BACK_ID   ,
    input  [(2**M_WIDTH-1):0] [31:0]     M_B_RD_DATA      ,
    input  [(2**M_WIDTH-1):0] [ 1:0]     M_B_RD_DATA_RESP ,
    input  [(2**M_WIDTH-1):0]            M_B_RD_DATA_LAST ,
    input  [(2**M_WIDTH-1):0]            M_B_RD_DATA_VALID,
    output [(2**M_WIDTH-1):0]            M_B_RD_DATA_READY,
     
    input  [(2**M_WIDTH-1):0]            M_CLK          ,
    input  [(2**M_WIDTH-1):0]            M_RSTN         ,
    input  [(2**M_WIDTH-1):0] [M_ID-1:0] M_WR_ADDR_ID   ,
    input  [(2**M_WIDTH-1):0] [31:0]     M_WR_ADDR      ,
    input  [(2**M_WIDTH-1):0] [ 7:0]     M_WR_ADDR_LEN  ,
    input  [(2**M_WIDTH-1):0] [ 1:0]     M_WR_ADDR_BURST,
    input  [(2**M_WIDTH-1):0]            M_WR_ADDR_VALID,
    output [(2**M_WIDTH-1):0]            M_WR_ADDR_READY,
    input  [(2**M_WIDTH-1):0] [31:0]     M_WR_DATA      ,
    input  [(2**M_WIDTH-1):0] [ 3:0]     M_WR_STRB      ,
    input  [(2**M_WIDTH-1):0]            M_WR_DATA_LAST ,
    input  [(2**M_WIDTH-1):0]            M_WR_DATA_VALID,
    output [(2**M_WIDTH-1):0]            M_WR_DATA_READY,
    output [(2**M_WIDTH-1):0] [M_ID-1:0] M_WR_BACK_ID   ,
    output [(2**M_WIDTH-1):0] [ 1:0]     M_WR_BACK_RESP ,
    output [(2**M_WIDTH-1):0]            M_WR_BACK_VALID,
    input  [(2**M_WIDTH-1):0]            M_WR_BACK_READY,
    input  [(2**M_WIDTH-1):0] [M_ID-1:0] M_RD_ADDR_ID   ,
    input  [(2**M_WIDTH-1):0] [31:0]     M_RD_ADDR      ,
    input  [(2**M_WIDTH-1):0] [ 7:0]     M_RD_ADDR_LEN  ,
    input  [(2**M_WIDTH-1):0] [ 1:0]     M_RD_ADDR_BURST,
    input  [(2**M_WIDTH-1):0]            M_RD_ADDR_VALID,
    output [(2**M_WIDTH-1):0]            M_RD_ADDR_READY,
    output [(2**M_WIDTH-1):0] [M_ID-1:0] M_RD_BACK_ID   ,
    output [(2**M_WIDTH-1):0] [31:0]     M_RD_DATA      ,
    output [(2**M_WIDTH-1):0] [ 1:0]     M_RD_DATA_RESP ,
    output [(2**M_WIDTH-1):0]            M_RD_DATA_LAST ,
    output [(2**M_WIDTH-1):0]            M_RD_DATA_VALID,
    input  [(2**M_WIDTH-1):0]            M_RD_DATA_READY,
     
    input  [(2**S_WIDTH-1):0] [M_ID+M_WIDTH-1:0]S_B_WR_ADDR_ID   ,
    input  [(2**S_WIDTH-1):0] [31:0]            S_B_WR_ADDR      ,
    input  [(2**S_WIDTH-1):0] [ 7:0]            S_B_WR_ADDR_LEN  ,
    input  [(2**S_WIDTH-1):0] [ 1:0]            S_B_WR_ADDR_BURST,
    input  [(2**S_WIDTH-1):0]                   S_B_WR_ADDR_VALID,
    output [(2**S_WIDTH-1):0]                   S_B_WR_ADDR_READY,
    input  [(2**S_WIDTH-1):0] [31:0]            S_B_WR_DATA      ,
    input  [(2**S_WIDTH-1):0] [ 3:0]            S_B_WR_STRB      ,
    input  [(2**S_WIDTH-1):0]                   S_B_WR_DATA_LAST ,
    input  [(2**S_WIDTH-1):0]                   S_B_WR_DATA_VALID,
    output [(2**S_WIDTH-1):0]                   S_B_WR_DATA_READY,
    output [(2**S_WIDTH-1):0] [M_ID+M_WIDTH-1:0]S_B_WR_BACK_ID   ,
    output [(2**S_WIDTH-1):0] [ 1:0]            S_B_WR_BACK_RESP ,
    output [(2**S_WIDTH-1):0]                   S_B_WR_BACK_VALID,
    input  [(2**S_WIDTH-1):0]                   S_B_WR_BACK_READY,
    input  [(2**S_WIDTH-1):0] [M_ID+M_WIDTH-1:0]S_B_RD_ADDR_ID   ,
    input  [(2**S_WIDTH-1):0] [31:0]            S_B_RD_ADDR      ,
    input  [(2**S_WIDTH-1):0] [ 7:0]            S_B_RD_ADDR_LEN  ,
    input  [(2**S_WIDTH-1):0] [ 1:0]            S_B_RD_ADDR_BURST,
    input  [(2**S_WIDTH-1):0]                   S_B_RD_ADDR_VALID,
    output [(2**S_WIDTH-1):0]                   S_B_RD_ADDR_READY,
    output [(2**S_WIDTH-1):0] [M_ID+M_WIDTH-1:0]S_B_RD_BACK_ID   ,
    output [(2**S_WIDTH-1):0] [31:0]            S_B_RD_DATA      ,
    output [(2**S_WIDTH-1):0] [ 1:0]            S_B_RD_DATA_RESP ,
    output [(2**S_WIDTH-1):0]                   S_B_RD_DATA_LAST ,
    output [(2**S_WIDTH-1):0]                   S_B_RD_DATA_VALID,
    input  [(2**S_WIDTH-1):0]                   S_B_RD_DATA_READY,

    input  [(2**S_WIDTH-1):0]                   S_CLK          ,
    input  [(2**S_WIDTH-1):0]                   S_RSTN         ,
    output [(2**S_WIDTH-1):0] [M_ID+M_WIDTH-1:0]S_WR_ADDR_ID   ,
    output [(2**S_WIDTH-1):0] [31:0]            S_WR_ADDR      ,
    output [(2**S_WIDTH-1):0] [ 7:0]            S_WR_ADDR_LEN  ,
    output [(2**S_WIDTH-1):0] [ 1:0]            S_WR_ADDR_BURST,
    output [(2**S_WIDTH-1):0]                   S_WR_ADDR_VALID,
    input  [(2**S_WIDTH-1):0]                   S_WR_ADDR_READY,
    output [(2**S_WIDTH-1):0] [31:0]            S_WR_DATA      ,
    output [(2**S_WIDTH-1):0] [ 3:0]            S_WR_STRB      ,
    output [(2**S_WIDTH-1):0]                   S_WR_DATA_LAST ,
    output [(2**S_WIDTH-1):0]                   S_WR_DATA_VALID,
    input  [(2**S_WIDTH-1):0]                   S_WR_DATA_READY,
    input  [(2**S_WIDTH-1):0] [M_ID+M_WIDTH-1:0]S_WR_BACK_ID   ,
    input  [(2**S_WIDTH-1):0] [ 1:0]            S_WR_BACK_RESP ,
    input  [(2**S_WIDTH-1):0]                   S_WR_BACK_VALID,
    output [(2**S_WIDTH-1):0]                   S_WR_BACK_READY,
    output [(2**S_WIDTH-1):0] [M_ID+M_WIDTH-1:0]S_RD_ADDR_ID   ,
    output [(2**S_WIDTH-1):0] [31:0]            S_RD_ADDR      ,
    output [(2**S_WIDTH-1):0] [ 7:0]            S_RD_ADDR_LEN  ,
    output [(2**S_WIDTH-1):0] [ 1:0]            S_RD_ADDR_BURST,
    output [(2**S_WIDTH-1):0]                   S_RD_ADDR_VALID,
    input  [(2**S_WIDTH-1):0]                   S_RD_ADDR_READY,
    input  [(2**S_WIDTH-1):0] [M_ID+M_WIDTH-1:0]S_RD_BACK_ID   ,
    input  [(2**S_WIDTH-1):0] [31:0]            S_RD_DATA      ,
    input  [(2**S_WIDTH-1):0] [ 1:0]            S_RD_DATA_RESP ,
    input  [(2**S_WIDTH-1):0]                   S_RD_DATA_LAST ,
    input  [(2**S_WIDTH-1):0]                   S_RD_DATA_VALID,
    output [(2**S_WIDTH-1):0]                   S_RD_DATA_READY,
        
    output [(2**M_WIDTH-1):0] [4:0] M_fifo_empty_flag,
    output [(2**S_WIDTH-1):0] [4:0] S_fifo_empty_flag
);
/*
AXI CLOCK CONVERTER模块，集中处理各个模块的时钟域转换
fifo的引入同时使主从模块支持了outstanding功能
*/

// 主设备异步桥接模块批量例化
genvar i;
generate
for (i = 0; i < 2**M_WIDTH; i++) begin : gen_master_async
    if(M_ASYNC_ON[i] == 1'b1) begin
        master_axi_async #(
            .ID_WIDTH(M_ID)
        )u_m_axi_async(
            .B_CLK            (BUS_CLK             ),
            .B_RSTN           (BUS_RSTN            ),
            .B_WR_ADDR_ID     (M_B_WR_ADDR_ID   [i]),
            .B_WR_ADDR        (M_B_WR_ADDR      [i]),
            .B_WR_ADDR_LEN    (M_B_WR_ADDR_LEN  [i]),
            .B_WR_ADDR_BURST  (M_B_WR_ADDR_BURST[i]),
            .B_WR_ADDR_VALID  (M_B_WR_ADDR_VALID[i]),
            .B_WR_ADDR_READY  (M_B_WR_ADDR_READY[i]),
            .B_WR_DATA        (M_B_WR_DATA      [i]),
            .B_WR_STRB        (M_B_WR_STRB      [i]),
            .B_WR_DATA_LAST   (M_B_WR_DATA_LAST [i]),
            .B_WR_DATA_VALID  (M_B_WR_DATA_VALID[i]),
            .B_WR_DATA_READY  (M_B_WR_DATA_READY[i]),
            .B_WR_BACK_ID     (M_B_WR_BACK_ID   [i]),
            .B_WR_BACK_RESP   (M_B_WR_BACK_RESP [i]),
            .B_WR_BACK_VALID  (M_B_WR_BACK_VALID[i]),
            .B_WR_BACK_READY  (M_B_WR_BACK_READY[i]),
            .B_RD_ADDR_ID     (M_B_RD_ADDR_ID   [i]),
            .B_RD_ADDR        (M_B_RD_ADDR      [i]),
            .B_RD_ADDR_LEN    (M_B_RD_ADDR_LEN  [i]),
            .B_RD_ADDR_BURST  (M_B_RD_ADDR_BURST[i]),
            .B_RD_ADDR_VALID  (M_B_RD_ADDR_VALID[i]),
            .B_RD_ADDR_READY  (M_B_RD_ADDR_READY[i]),
            .B_RD_BACK_ID     (M_B_RD_BACK_ID   [i]),
            .B_RD_DATA        (M_B_RD_DATA      [i]),
            .B_RD_DATA_RESP   (M_B_RD_DATA_RESP [i]),
            .B_RD_DATA_LAST   (M_B_RD_DATA_LAST [i]),
            .B_RD_DATA_VALID  (M_B_RD_DATA_VALID[i]),
            .B_RD_DATA_READY  (M_B_RD_DATA_READY[i]),
            .M_CLK            (M_CLK            [i]),
            .M_RSTN           (M_RSTN           [i]),
            .M_WR_ADDR_ID     (M_WR_ADDR_ID     [i]),
            .M_WR_ADDR        (M_WR_ADDR        [i]),
            .M_WR_ADDR_LEN    (M_WR_ADDR_LEN    [i]),
            .M_WR_ADDR_BURST  (M_WR_ADDR_BURST  [i]),
            .M_WR_ADDR_VALID  (M_WR_ADDR_VALID  [i]),
            .M_WR_ADDR_READY  (M_WR_ADDR_READY  [i]),
            .M_WR_DATA        (M_WR_DATA        [i]),
            .M_WR_STRB        (M_WR_STRB        [i]),
            .M_WR_DATA_LAST   (M_WR_DATA_LAST   [i]),
            .M_WR_DATA_VALID  (M_WR_DATA_VALID  [i]),
            .M_WR_DATA_READY  (M_WR_DATA_READY  [i]),
            .M_WR_BACK_ID     (M_WR_BACK_ID     [i]),
            .M_WR_BACK_RESP   (M_WR_BACK_RESP   [i]),
            .M_WR_BACK_VALID  (M_WR_BACK_VALID  [i]),
            .M_WR_BACK_READY  (M_WR_BACK_READY  [i]),
            .M_RD_ADDR_ID     (M_RD_ADDR_ID     [i]),
            .M_RD_ADDR        (M_RD_ADDR        [i]),
            .M_RD_ADDR_LEN    (M_RD_ADDR_LEN    [i]),
            .M_RD_ADDR_BURST  (M_RD_ADDR_BURST  [i]),
            .M_RD_ADDR_VALID  (M_RD_ADDR_VALID  [i]),
            .M_RD_ADDR_READY  (M_RD_ADDR_READY  [i]),
            .M_RD_BACK_ID     (M_RD_BACK_ID     [i]),
            .M_RD_DATA        (M_RD_DATA        [i]),
            .M_RD_DATA_RESP   (M_RD_DATA_RESP   [i]),
            .M_RD_DATA_LAST   (M_RD_DATA_LAST   [i]),
            .M_RD_DATA_VALID  (M_RD_DATA_VALID  [i]),
            .M_RD_DATA_READY  (M_RD_DATA_READY  [i]),
            .fifo_empty_flag  (M_fifo_empty_flag[i]));
    end else begin
        assign M_B_WR_ADDR_ID   [i] = M_WR_ADDR_ID   [i];
        assign M_B_WR_ADDR      [i] = M_WR_ADDR      [i];
        assign M_B_WR_ADDR_LEN  [i] = M_WR_ADDR_LEN  [i];
        assign M_B_WR_ADDR_BURST[i] = M_WR_ADDR_BURST[i];
        assign M_B_WR_ADDR_VALID[i] = M_WR_ADDR_VALID[i];
        assign M_B_WR_BACK_READY[i] = M_WR_BACK_READY[i];
        assign M_B_RD_ADDR_ID   [i] = M_RD_ADDR_ID   [i];
        assign M_B_RD_ADDR      [i] = M_RD_ADDR      [i];
        assign M_B_RD_ADDR_LEN  [i] = M_RD_ADDR_LEN  [i];
        assign M_B_RD_ADDR_BURST[i] = M_RD_ADDR_BURST[i];
        assign M_B_RD_ADDR_VALID[i] = M_RD_ADDR_VALID[i];
        assign M_B_RD_DATA_READY[i] = M_RD_DATA_READY[i];
        assign M_WR_ADDR_READY  [i] = M_B_WR_ADDR_READY  [i];
        assign M_WR_DATA_READY  [i] = M_B_WR_DATA_READY  [i];
        assign M_WR_BACK_ID     [i] = M_B_WR_BACK_ID     [i];
        assign M_WR_BACK_RESP   [i] = M_B_WR_BACK_RESP   [i];
        assign M_WR_BACK_VALID  [i] = M_B_WR_BACK_VALID  [i];
        assign M_RD_ADDR_READY  [i] = M_B_RD_ADDR_READY  [i];
        assign M_RD_BACK_ID     [i] = M_B_RD_BACK_ID     [i];
        assign M_RD_DATA        [i] = M_B_RD_DATA        [i];
        assign M_RD_DATA_RESP   [i] = M_B_RD_DATA_RESP   [i];
        assign M_RD_DATA_LAST   [i] = M_B_RD_DATA_LAST   [i];
        assign M_RD_DATA_VALID  [i] = M_B_RD_DATA_VALID  [i];
        assign M_fifo_empty_flag[i] = 0;
    end
end
endgenerate


// 从设备异步桥接模块批量例化
generate
for (i = 0; i < 2**S_WIDTH; i++) begin : gen_slave_async
    if(S_ASYNC_ON[i] == 1'b1) begin
        slave_axi_async #(
            .ID_WIDTH(M_ID + M_WIDTH)
        )u_s_axi_async(
            .B_CLK            (BUS_CLK             ),
            .B_RSTN           (BUS_RSTN            ),
            .B_WR_ADDR_ID     (S_B_WR_ADDR_ID   [i]),
            .B_WR_ADDR        (S_B_WR_ADDR      [i]),
            .B_WR_ADDR_LEN    (S_B_WR_ADDR_LEN  [i]),
            .B_WR_ADDR_BURST  (S_B_WR_ADDR_BURST[i]),
            .B_WR_ADDR_VALID  (S_B_WR_ADDR_VALID[i]),
            .B_WR_ADDR_READY  (S_B_WR_ADDR_READY[i]),
            .B_WR_DATA        (S_B_WR_DATA      [i]),
            .B_WR_STRB        (S_B_WR_STRB      [i]),
            .B_WR_DATA_LAST   (S_B_WR_DATA_LAST [i]),
            .B_WR_DATA_VALID  (S_B_WR_DATA_VALID[i]),
            .B_WR_DATA_READY  (S_B_WR_DATA_READY[i]),
            .B_WR_BACK_ID     (S_B_WR_BACK_ID   [i]),
            .B_WR_BACK_RESP   (S_B_WR_BACK_RESP [i]),
            .B_WR_BACK_VALID  (S_B_WR_BACK_VALID[i]),
            .B_WR_BACK_READY  (S_B_WR_BACK_READY[i]),
            .B_RD_ADDR_ID     (S_B_RD_ADDR_ID   [i]),
            .B_RD_ADDR        (S_B_RD_ADDR      [i]),
            .B_RD_ADDR_LEN    (S_B_RD_ADDR_LEN  [i]),
            .B_RD_ADDR_BURST  (S_B_RD_ADDR_BURST[i]),
            .B_RD_ADDR_VALID  (S_B_RD_ADDR_VALID[i]),
            .B_RD_ADDR_READY  (S_B_RD_ADDR_READY[i]),
            .B_RD_BACK_ID     (S_B_RD_BACK_ID   [i]),
            .B_RD_DATA        (S_B_RD_DATA      [i]),
            .B_RD_DATA_RESP   (S_B_RD_DATA_RESP [i]),
            .B_RD_DATA_LAST   (S_B_RD_DATA_LAST [i]),
            .B_RD_DATA_VALID  (S_B_RD_DATA_VALID[i]),
            .B_RD_DATA_READY  (S_B_RD_DATA_READY[i]),
            .S_CLK            (S_CLK            [i]),
            .S_RSTN           (S_RSTN           [i]),
            .S_WR_ADDR_ID     (S_WR_ADDR_ID     [i]),
            .S_WR_ADDR        (S_WR_ADDR        [i]),
            .S_WR_ADDR_LEN    (S_WR_ADDR_LEN    [i]),
            .S_WR_ADDR_BURST  (S_WR_ADDR_BURST  [i]),
            .S_WR_ADDR_VALID  (S_WR_ADDR_VALID  [i]),
            .S_WR_ADDR_READY  (S_WR_ADDR_READY  [i]),
            .S_WR_DATA        (S_WR_DATA        [i]),
            .S_WR_STRB        (S_WR_STRB        [i]),
            .S_WR_DATA_LAST   (S_WR_DATA_LAST   [i]),
            .S_WR_DATA_VALID  (S_WR_DATA_VALID  [i]),
            .S_WR_DATA_READY  (S_WR_DATA_READY  [i]),
            .S_WR_BACK_ID     (S_WR_BACK_ID     [i]),
            .S_WR_BACK_RESP   (S_WR_BACK_RESP   [i]),
            .S_WR_BACK_VALID  (S_WR_BACK_VALID  [i]),
            .S_WR_BACK_READY  (S_WR_BACK_READY  [i]),
            .S_RD_ADDR_ID     (S_RD_ADDR_ID     [i]),
            .S_RD_ADDR        (S_RD_ADDR        [i]),
            .S_RD_ADDR_LEN    (S_RD_ADDR_LEN    [i]),
            .S_RD_ADDR_BURST  (S_RD_ADDR_BURST  [i]),
            .S_RD_ADDR_VALID  (S_RD_ADDR_VALID  [i]),
            .S_RD_ADDR_READY  (S_RD_ADDR_READY  [i]),
            .S_RD_BACK_ID     (S_RD_BACK_ID     [i]),
            .S_RD_DATA        (S_RD_DATA        [i]),
            .S_RD_DATA_RESP   (S_RD_DATA_RESP   [i]),
            .S_RD_DATA_LAST   (S_RD_DATA_LAST   [i]),
            .S_RD_DATA_VALID  (S_RD_DATA_VALID  [i]),
            .S_RD_DATA_READY  (S_RD_DATA_READY  [i]),
            .fifo_empty_flag  (S_fifo_empty_flag[i]));
    end else begin
        assign S_B_WR_ADDR_READY[i] = S_WR_ADDR_READY[i];
        assign S_B_WR_DATA_READY[i] = S_WR_DATA_READY[i];
        assign S_B_WR_BACK_ID   [i] = S_WR_BACK_ID   [i];
        assign S_B_WR_BACK_RESP [i] = S_WR_BACK_RESP [i];
        assign S_B_WR_BACK_VALID[i] = S_WR_BACK_VALID[i];
        assign S_B_RD_ADDR_READY[i] = S_RD_ADDR_READY[i];
        assign S_B_RD_BACK_ID   [i] = S_RD_BACK_ID   [i];
        assign S_B_RD_DATA      [i] = S_RD_DATA      [i];
        assign S_B_RD_DATA_RESP [i] = S_RD_DATA_RESP [i];
        assign S_B_RD_DATA_LAST [i] = S_RD_DATA_LAST [i];
        assign S_B_RD_DATA_VALID[i] = S_RD_DATA_VALID[i];
        assign S_WR_ADDR_ID     [i] = S_B_WR_ADDR_ID     [i];
        assign S_WR_ADDR        [i] = S_B_WR_ADDR        [i];
        assign S_WR_ADDR_LEN    [i] = S_B_WR_ADDR_LEN    [i];
        assign S_WR_ADDR_BURST  [i] = S_B_WR_ADDR_BURST  [i];
        assign S_WR_ADDR_VALID  [i] = S_B_WR_ADDR_VALID  [i];
        assign S_WR_DATA        [i] = S_B_WR_DATA        [i];
        assign S_WR_STRB        [i] = S_B_WR_STRB        [i];
        assign S_WR_DATA_LAST   [i] = S_B_WR_DATA_LAST   [i];
        assign S_WR_DATA_VALID  [i] = S_B_WR_DATA_VALID  [i];
        assign S_WR_BACK_READY  [i] = S_B_WR_BACK_READY  [i];
        assign S_RD_ADDR_ID     [i] = S_B_RD_ADDR_ID     [i];
        assign S_RD_ADDR        [i] = S_B_RD_ADDR        [i];
        assign S_RD_ADDR_LEN    [i] = S_B_RD_ADDR_LEN    [i];
        assign S_RD_ADDR_BURST  [i] = S_B_RD_ADDR_BURST  [i];
        assign S_RD_ADDR_VALID  [i] = S_B_RD_ADDR_VALID  [i];
        assign S_RD_DATA_READY  [i] = S_B_RD_DATA_READY  [i];
        assign S_fifo_empty_flag[i] = 0;
    end
end
endgenerate

endmodule