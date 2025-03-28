// *********************************************************************************/
// Project Name :
// File Name    : cellfifo_rd_logic.v
// Module Name  : cellfifo_rd_logic
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
module cellfifo_rd_logic #(
parameter                           SYNC_NUM    = 3,
parameter                           ADDR_SIZE   = 9,
parameter                           DATA_SIZE   = 36,
parameter                           ASYNC_MODE  = 0,
parameter                           AEMPTY_NUM  = 1,
parameter                           RAM_LATENCY = 2,
parameter                           U_DLY       = 1
)
(
input                               rst_n,
input                               clk,
output wire                         rd_rdy,
input                               rd_req,
output                              rd_vld,
output                              rd_eoc,
output          [DATA_SIZE-1:0]     rd_data,
output reg                          rd_empty,
output reg                          rd_aempty,
output wire     [ADDR_SIZE-1:0]     rd_used,
input           [ADDR_SIZE-1:0]     waddr2rd,
input                               waddr_togf,
output wire                         waddr_togb,
output wire     [ADDR_SIZE-1:0]     raddr2wr,
output wire                         ram_rcken,
output wire     [ADDR_SIZE-1:0]     ram_raddr,
input           [DATA_SIZE:0]       ram_rdata
);
// Parameter Define 

// Register Define 
reg             [ADDR_SIZE-1:0]     waddr2rd_sync2;
reg             [ADDR_SIZE-1:0]     waddr2rd_syn;
reg             [ADDR_SIZE-1:0]     rd_addr;
reg             [ADDR_SIZE-1:0]     rd_addr_gry;
reg             [RAM_LATENCY-1:0]   empty_dly;
reg                                 nc;
reg                                 rd_vld_pre;
// Wire Define 
wire            [ADDR_SIZE-1:0]     waddr2rd_sync1;
wire                                fifo_ren;
wire            [ADDR_SIZE-1:0]     rd_addr_pre;


// return toggling bit to write side to allow waddr2rd update
syncdff #(
    .DATA_SIZE              (1              ),
    .SYNC_NUM               (SYNC_NUM       )
) u_togf_sync (
    .rst_n                  (rst_n          ),
    .clk                    (clk            ),
    .data_in                (waddr_togf     ),
    .data_sync              (waddr_togb     )
);

syncdff #(
    .DATA_SIZE              (ADDR_SIZE      ),
    .SYNC_NUM               (SYNC_NUM       )
) u_waddr_sync (
    .rst_n                  (rst_n          ),
    .clk                    (clk            ),
    .data_in                (waddr2rd       ),
    .data_sync              (waddr2rd_sync1 )
);

always @ (posedge clk or negedge rst_n)
begin
    if (rst_n==1'b0)     
    begin
        waddr2rd_sync2 <=#U_DLY 'h0;
        waddr2rd_syn   <=#U_DLY 'h0;
    end
    else
    begin
        waddr2rd_sync2 <=#U_DLY waddr2rd_sync1;
        if (waddr2rd_sync2==waddr2rd_sync1)     // accept address from write side if it's stable
            waddr2rd_syn <=#U_DLY waddr2rd_sync2;
        else;
    end
end

// read FIFO in two kinds of conditions:
// 1. there is no data on Q port of RAM(prefetch operation)
// 2. sink is ready for data
assign fifo_ren = (rd_req==1'b1 || rd_rdy==1'b0) ? ~rd_empty : 1'b0;
//assign fifo_ren = (rd_req==1'b1) ? ~rd_empty : 1'b0;

always @ (posedge clk or negedge rst_n)
begin
    if (rst_n==1'b0)     
    begin
        rd_addr     <=#U_DLY 'h0;
        rd_addr_gry <=#U_DLY 'h0;
    end
    else
    begin
        rd_addr     <=#U_DLY rd_addr_pre;
        rd_addr_gry <=#U_DLY rd_addr_pre ^ {1'b0, rd_addr_pre[ADDR_SIZE-1:1]};
    end
end

assign rd_addr_pre = (fifo_ren==1'b1) ? rd_addr+'h1 : rd_addr;
assign raddr2wr    = (ASYNC_MODE==1)  ? rd_addr_gry : rd_addr;
assign rd_used     = (ASYNC_MODE==1)  ? waddr2rd_syn-rd_addr : waddr2rd-rd_addr;

always @ (posedge clk or negedge rst_n)
begin
    if (rst_n==1'b0)     
        rd_empty <=#U_DLY 1'b1;
    else begin
        if (rd_used=='h1 && fifo_ren==1'b1)     // assert rd_empty after last data is read
            rd_empty <=#U_DLY 1'b1;
        else if (rd_used=='h0)
            rd_empty <=#U_DLY 1'b1;
        else
            rd_empty <=#U_DLY 1'b0;
    end
end

always @ (posedge clk or negedge rst_n)
begin
    if (rst_n==1'b0)     
        rd_aempty <=#U_DLY 1'b1;
    else begin
        if (rd_used<=AEMPTY_NUM)
            rd_aempty <=#U_DLY 1'b1;
        else
            rd_aempty <=#U_DLY 1'b0;
    end
end

// prefetch data from RAM according to it's latency
always @ (posedge clk or negedge rst_n)
begin
    if (rst_n==1'b0)     
    begin
        nc        <=#U_DLY 1'b0;
        empty_dly <=#U_DLY {RAM_LATENCY{1'b1}};
    end
    else
    begin
        if (ram_rcken==1'b1)
            {nc, empty_dly} <=#U_DLY {empty_dly, rd_empty};
        else;
    end
end

always @ (posedge clk or negedge rst_n)
begin
    if (rst_n==1'b0)
        rd_vld_pre <=#U_DLY 1'b0;
    else
        rd_vld_pre <=#U_DLY rd_rdy & rd_req;
end

assign rd_rdy    = ~empty_dly[RAM_LATENCY-1];
assign ram_rcken = (rd_req==1'b1 || rd_rdy==1'b0) ? 1'b1 : 1'b0;
//assign ram_rcken = (rd_req==1'b1) ? 1'b1 : 1'b0;
assign ram_raddr = rd_addr;
assign rd_vld    = rd_vld_pre;
assign rd_eoc    = ram_rdata[DATA_SIZE];
assign rd_data   = ram_rdata[DATA_SIZE-1:0];

endmodule

