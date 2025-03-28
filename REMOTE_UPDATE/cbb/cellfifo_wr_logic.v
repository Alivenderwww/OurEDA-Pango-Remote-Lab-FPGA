// *********************************************************************************/
// Project Name :
// File Name    : cellfifo_wr_logic.v
// Module Name  : cellfifo_wr_logic
// Called By    :
// Abstract     :
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
module cellfifo_wr_logic #(
parameter                           ADDR_SIZE  = 9,
parameter                           DATA_SIZE  = 36,
parameter                           SYNC_NUM   = 3,
parameter                           MAX_LEN    = 16,
parameter                           AFULL_NUM  = 2**9-1-16,  // MAX_LEN < AFULL_NUM < 2**ADDR_SIZE-1-MAX_LEN
parameter                           ASYNC_MODE = 0,
parameter                           U_DLY      = 1
)
(
input                               rst_n,
input                               clk,
input                               wr_vld,
input           [DATA_SIZE-1:0]     wr_data,
input                               wr_eoc,
input                               wr_drop,
output wire                         wr_full,
output reg                          wr_afull,
output reg                          wr_over,
output wire     [ADDR_SIZE-1:0]     wr_used,
// write and read address exchanges between write and read side
output          [ADDR_SIZE-1:0]     waddr2rd,   // write address to read side, it's a sop address
output reg                          waddr_togf, // transfer toggling forward
input                               waddr_togb, // transfer toggling backward
input           [ADDR_SIZE-1:0]     raddr2wr,   // read address to write side
output wire                         ram_wen,
output wire     [ADDR_SIZE-1:0]     ram_waddr,
output wire     [DATA_SIZE:0]       ram_wdata,
output reg                          fifo_err
);
// Parameter Define 

// Register Define 
reg             [ADDR_SIZE-1:0]     wr_addr;
reg             [ADDR_SIZE-1:0]     soc_addr;
reg                                 full;
reg                                 wr_over_hld;
// Wire Define 
wire                                pkt_drop;
wire                                fifo_wen;
wire            [ADDR_SIZE-1:0]     cell_len;

assign wr_full = full;

// drop current cell/packet in three conditions:
// 1. required by user according to wr_drop
// 2. "full" has ever occurred before end of cell
// 3. "full"  occur just at end of cell
assign pkt_drop = wr_drop | wr_over_hld | full;

// if MAX_LEN is wrong, one probable dead state is:
// wr_afull maybe assert while writting a oversize cell/packet, so that
// user stop writting bytes to FIFO according to wr_afull. Finally,
// no cell will be read out in the obsence of the oversized cell's eoc
always @ (posedge clk or negedge rst_n)
begin
    if (rst_n==1'b0)
        wr_addr <=#U_DLY 'h0;
    else begin
        if (fifo_err==1'b1)     // drop oversize cell to avoid dead state, right MAX_LEN is important
            wr_addr <=#U_DLY soc_addr;
        else if (wr_vld==1'b1 && wr_eoc==1'b1)
        begin
            if (pkt_drop==1'b1) // address jump to start of current cell, drop the cell
                wr_addr <=#U_DLY soc_addr;
            else                // add address to start of next cell
                wr_addr <=#U_DLY wr_addr + 'h1;    // accept the cell
        end
        else if (wr_vld==1'b1 && full==1'b0)
            wr_addr <=#U_DLY wr_addr + 'h1;
        else;
    end
end

always @ (posedge clk or negedge rst_n)
begin
    if (rst_n==1'b0)     
        soc_addr <=#U_DLY {ADDR_SIZE{1'b0}};
    else begin
        if (wr_vld==1'b1 && wr_eoc==1'b1 && pkt_drop==1'b0 && fifo_err==1'b0)   // record start address of the cell/packet
            soc_addr <=#U_DLY wr_addr + 'h1;
        else;
    end
end

// transfer write address of soc to read side:
//  SYNC: directly
// ASYNC: hold waadr2rd_reg until read side have received previous value
//        waddr_togf: toggling bit forward to read side
//        waddr_togb: toggling bit backward from read side, a copy of waddr_togf
//        these two bits are for negotiation between read and write
generate
    if (ASYNC_MODE==1)
    begin
        wire                        waddr_togb_sync;
        reg     [ADDR_SIZE-1:0]     waddr2rd_reg;
        syncdff #(
            .DATA_SIZE              (1              ),
            .SYNC_NUM               (SYNC_NUM       )
        ) u_togb_sync (
            .rst_n                  (rst_n          ),
            .clk                    (clk            ),
            .data_in                (waddr_togb     ),
            .data_sync              (waddr_togb_sync)
        );
        always @ (posedge clk or negedge rst_n)
        begin
            if (rst_n==1'b0)
            begin
                waddr2rd_reg <=#U_DLY {ADDR_SIZE{1'b0}};
                waddr_togf   <=#U_DLY 1'b0;
            end
            else
            begin
                if (waddr2rd_reg!=soc_addr && waddr_togf==waddr_togb_sync)
                begin
                    waddr2rd_reg <=#U_DLY soc_addr;
                    waddr_togf   <=#U_DLY ~waddr_togf;
                end
                else;
            end
        end
        assign waddr2rd = waddr2rd_reg;
    end
    else
    begin
        assign waddr2rd = soc_addr;
        always @ (*)
        begin
            waddr_togf = 1'b0;
        end
    end
endgenerate

assign cell_len = wr_addr - soc_addr;

always @ (posedge clk or negedge rst_n)
begin
    if (rst_n==1'b0)     
        fifo_err <=#U_DLY 1'b0;
    else begin
        if (wr_vld==1'b1 && wr_eoc==1'b1)
            fifo_err <=#U_DLY 1'b0;
        else if (cell_len==(MAX_LEN-'d1) && wr_vld==1'b1 && wr_eoc==1'b0)
            fifo_err <=#U_DLY 1'b1;
        else if (cell_len>=MAX_LEN)
            fifo_err <=#U_DLY 1'b1;
        else;
    end
end

generate
    if (ASYNC_MODE==1)
    begin
        wire    [ADDR_SIZE-1:0]     raddr_gry_sync;
        reg     [ADDR_SIZE-1:0]     rd_addr_ungry;
        syncdff #(
            .DATA_SIZE              (ADDR_SIZE      ),
            .SYNC_NUM               (SYNC_NUM       )
        ) u_raddr_sync (
            .rst_n                  (rst_n          ),
            .clk                    (clk            ),
            .data_in                (raddr2wr       ),
            .data_sync              (raddr_gry_sync )
        );
        always @ (posedge clk or negedge rst_n)
        begin
            if (rst_n==1'b0)
                rd_addr_ungry <=#U_DLY 'h0;
            else
                rd_addr_ungry <=#U_DLY ungray_f(raddr_gry_sync);
        end
        assign wr_used = wr_addr - rd_addr_ungry;
    end
    else
    begin
        assign wr_used = wr_addr - raddr2wr;
    end
endgenerate

assign fifo_wen = (fifo_err==1'b1 || (wr_vld==1'b1 && wr_eoc==1'b1 && pkt_drop==1'b1)) ? 1'b0 :
                  (wr_vld==1'b1 && full==1'b0) ? 1'b1 : 1'b0;

always @ (posedge clk or negedge rst_n)
begin
    if (rst_n==1'b0)     
        full <=#U_DLY 1'b0;
    else begin
        if (wr_used=={ADDR_SIZE{1'b1}}-'h1 && fifo_wen==1'b1)
            full <=#U_DLY 1'b1;     // the max depth of FIFO is 2**ADDR_SIZE-1, waste one unit to avoid empty-and-full
        else if (wr_used=={ADDR_SIZE{1'b1}})
            full <=#U_DLY 1'b1;
        else
            full <=#U_DLY 1'b0;
    end
end

always @ (posedge clk or negedge rst_n)
begin
    if (rst_n==1'b0)     
        wr_afull <=#U_DLY 1'b0;
    else begin
        if (wr_used>=AFULL_NUM)
            wr_afull <=#U_DLY 1'b1;
        else
            wr_afull <=#U_DLY 1'b0;
    end
end

always @ (posedge clk or negedge rst_n)
begin
    if (rst_n==1'b0)     
        wr_over_hld <=#U_DLY 1'b0;
    else begin
        if (wr_vld==1'b1 && wr_eoc==1'b1)   // hold wr_over until end of cell
            wr_over_hld <=#U_DLY 1'b0;
        else if (wr_vld==1'b1 && full==1'b1)
            wr_over_hld <=#U_DLY 1'b1;
        else;
    end
end

always @ (posedge clk or negedge rst_n)
begin
    if (rst_n==1'b0)     
        wr_over <=#U_DLY 1'b0;
    else begin
        if (wr_vld==1'b1 && full==1'b1)
            wr_over <=#U_DLY 1'b1;
        else
            wr_over <=#U_DLY 1'b0;
    end
end

assign ram_wen   = wr_vld & (~full);
assign ram_waddr = wr_addr;
assign ram_wdata = {wr_eoc, wr_data};

function  [ADDR_SIZE-1:0] ungray_f;
    input [ADDR_SIZE-1:0] d_gry;
    integer               i;
    begin
        ungray_f[ADDR_SIZE-1] = d_gry[ADDR_SIZE-1];
        for (i=ADDR_SIZE-2; i>=0; i=i-1)
            ungray_f[i] = ungray_f[i+1] ^ d_gry[i];
    end
endfunction

endmodule

