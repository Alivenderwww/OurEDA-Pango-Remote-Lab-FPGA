module slave_axi_async ( //用于总线-从机的时钟域转换
input          B_CLK          ,
input          B_RSTN         ,
input  [4-1:0] B_WR_ADDR_ID   ,
input  [31:0]  B_WR_ADDR      ,
input  [ 7:0]  B_WR_ADDR_LEN  ,
input  [ 1:0]  B_WR_ADDR_BURST,
input          B_WR_ADDR_VALID,
output         B_WR_ADDR_READY,
input  [31:0]  B_WR_DATA      ,
input  [ 3:0]  B_WR_STRB      ,
input          B_WR_DATA_LAST ,
input          B_WR_DATA_VALID,
output         B_WR_DATA_READY,
output [4-1:0] B_WR_BACK_ID   ,
output [ 1:0]  B_WR_BACK_RESP ,
output         B_WR_BACK_VALID,
input          B_WR_BACK_READY,
input  [4-1:0] B_RD_ADDR_ID   ,
input  [31:0]  B_RD_ADDR      ,
input  [ 7:0]  B_RD_ADDR_LEN  ,
input  [ 1:0]  B_RD_ADDR_BURST,
input          B_RD_ADDR_VALID,
output         B_RD_ADDR_READY,
output [4-1:0] B_RD_BACK_ID   ,
output [31:0]  B_RD_DATA      ,
output [ 1:0]  B_RD_DATA_RESP ,
output         B_RD_DATA_LAST ,
output         B_RD_DATA_VALID,
input          B_RD_DATA_READY,

input          S_CLK          ,
input          S_RSTN         ,
output [4-1:0] S_WR_ADDR_ID   ,
output [31:0]  S_WR_ADDR      ,
output [ 7:0]  S_WR_ADDR_LEN  ,
output [ 1:0]  S_WR_ADDR_BURST,
output         S_WR_ADDR_VALID,
input          S_WR_ADDR_READY,
output [31:0]  S_WR_DATA      ,
output [ 3:0]  S_WR_STRB      ,
output         S_WR_DATA_LAST ,
output         S_WR_DATA_VALID,
input          S_WR_DATA_READY,
input  [4-1:0] S_WR_BACK_ID   ,
input  [ 1:0]  S_WR_BACK_RESP ,
input          S_WR_BACK_VALID,
output         S_WR_BACK_READY,
output [4-1:0] S_RD_ADDR_ID   ,
output [31:0]  S_RD_ADDR      ,
output [ 7:0]  S_RD_ADDR_LEN  ,
output [ 1:0]  S_RD_ADDR_BURST,
output         S_RD_ADDR_VALID,
input          S_RD_ADDR_READY,
input  [4-1:0] S_RD_BACK_ID   ,
input  [31:0]  S_RD_DATA      ,
input  [ 1:0]  S_RD_DATA_RESP ,
input          S_RD_DATA_LAST ,
input          S_RD_DATA_VALID,
output         S_RD_DATA_READY,

output wire [4:0] fifo_empty_flag
);

wire BUS_RSTN_SYNC, SLAVE_RSTN_SYNC, RD_BUS_RSTN_SYNC, RD_SLAVE_RSTN_SYNC;
rstn_sync #(32) rstn_sync_bus   (B_CLK, B_RSTN, BUS_RSTN_SYNC);
rstn_sync #(64) rstn_sync_rd_bus(B_CLK, B_RSTN, RD_BUS_RSTN_SYNC);
rstn_sync #(32) rstn_sync_slave(S_CLK, S_RSTN, SLAVE_RSTN_SYNC);
rstn_sync #(64) rstn_sync_rd_slave(S_CLK, S_RSTN, RD_SLAVE_RSTN_SYNC);

wire                wr_addr_fifo_wr_rst  ;
wire                wr_addr_fifo_wr_en   ;
wire [32+8+4+2-1:0] wr_addr_fifo_wr_data ;
wire                wr_addr_fifo_wr_full ;
wire                wr_addr_fifo_almost_full ;
wire                wr_addr_fifo_rd_rst  ;
wire                wr_addr_fifo_rd_en   ;
wire [32+8+4+2-1:0] wr_addr_fifo_rd_data ;
wire                wr_addr_fifo_rd_empty;

reg async_wr_addr_fifo_data_dont_care;
always @(posedge S_CLK or negedge SLAVE_RSTN_SYNC) begin
    if(~SLAVE_RSTN_SYNC) async_wr_addr_fifo_data_dont_care <= 1;
    else if(wr_addr_fifo_rd_empty && (S_WR_ADDR_VALID && S_WR_ADDR_READY)) async_wr_addr_fifo_data_dont_care <= 1;
    else if(wr_addr_fifo_rd_en && async_wr_addr_fifo_data_dont_care) async_wr_addr_fifo_data_dont_care <= 0;
    else async_wr_addr_fifo_data_dont_care <= async_wr_addr_fifo_data_dont_care;
end

assign wr_addr_fifo_wr_rst  =  ~BUS_RSTN_SYNC;
assign wr_addr_fifo_wr_en   = (B_WR_ADDR_VALID && B_WR_ADDR_READY);
assign wr_addr_fifo_wr_data = {B_WR_ADDR_ID, B_WR_ADDR, B_WR_ADDR_LEN, B_WR_ADDR_BURST};
assign B_WR_ADDR_READY = (BUS_RSTN_SYNC) && (~wr_addr_fifo_almost_full);

assign wr_addr_fifo_rd_rst  =  (~SLAVE_RSTN_SYNC) || (~RD_SLAVE_RSTN_SYNC);
assign wr_addr_fifo_rd_en   = (~wr_addr_fifo_rd_empty) && ((async_wr_addr_fifo_data_dont_care) || (S_WR_ADDR_VALID && S_WR_ADDR_READY));
assign {S_WR_ADDR_ID, S_WR_ADDR, S_WR_ADDR_LEN, S_WR_ADDR_BURST} = wr_addr_fifo_rd_data;
assign S_WR_ADDR_VALID  = (SLAVE_RSTN_SYNC) && (~async_wr_addr_fifo_data_dont_care);

//写地址通道和读地址通道是完全一样的接口设计，都用async_addr_fifo模块就可以
slave_async_addr_fifo slave_async_wr_addr_fifo_inst(
    .wr_clk  (B_CLK             ), 
    .wr_rst  (wr_addr_fifo_wr_rst ), 
    .wr_en   (wr_addr_fifo_wr_en  ), 
    .wr_data (wr_addr_fifo_wr_data), 
    .wr_full (wr_addr_fifo_wr_full), 
    .almost_full (wr_addr_fifo_almost_full), 
    
    .rd_clk  (S_CLK            ),
    .rd_rst  (wr_addr_fifo_rd_rst  ),
    .rd_en   (wr_addr_fifo_rd_en   ),
    .rd_data (wr_addr_fifo_rd_data ),
    .rd_empty(wr_addr_fifo_rd_empty) 
);

//_______________________________________________________________//
wire                rd_addr_fifo_wr_rst  ;
wire                rd_addr_fifo_wr_en   ;
wire [32+8+4+2-1:0] rd_addr_fifo_wr_data ;
wire                rd_addr_fifo_wr_full ;
wire                rd_addr_fifo_almost_full ;
wire                rd_addr_fifo_rd_rst  ;
wire                rd_addr_fifo_rd_en   ;
wire [32+8+4+2-1:0] rd_addr_fifo_rd_data ;
wire                rd_addr_fifo_rd_empty;

reg async_rd_addr_fifo_data_dont_care;
always @(posedge S_CLK or negedge SLAVE_RSTN_SYNC) begin
    if(~SLAVE_RSTN_SYNC) async_rd_addr_fifo_data_dont_care <= 1;
    else if(rd_addr_fifo_rd_empty && (S_RD_ADDR_VALID && S_RD_ADDR_READY)) async_rd_addr_fifo_data_dont_care <= 1;
    else if(rd_addr_fifo_rd_en && async_rd_addr_fifo_data_dont_care) async_rd_addr_fifo_data_dont_care <= 0;
    else async_rd_addr_fifo_data_dont_care <= async_rd_addr_fifo_data_dont_care;
end

assign rd_addr_fifo_wr_rst  =  ~BUS_RSTN_SYNC;
assign rd_addr_fifo_wr_en   = (B_RD_ADDR_VALID && B_RD_ADDR_READY);
assign rd_addr_fifo_wr_data = {B_RD_ADDR_ID, B_RD_ADDR, B_RD_ADDR_LEN, B_RD_ADDR_BURST};
assign B_RD_ADDR_READY    = (BUS_RSTN_SYNC) && (~rd_addr_fifo_almost_full);

assign rd_addr_fifo_rd_rst  =  (~SLAVE_RSTN_SYNC) || (~RD_SLAVE_RSTN_SYNC);
assign rd_addr_fifo_rd_en   = (~rd_addr_fifo_rd_empty) && ((async_rd_addr_fifo_data_dont_care) || (S_RD_ADDR_VALID && S_RD_ADDR_READY));
assign {S_RD_ADDR_ID, S_RD_ADDR, S_RD_ADDR_LEN, S_RD_ADDR_BURST} = rd_addr_fifo_rd_data;
assign S_RD_ADDR_VALID  = (SLAVE_RSTN_SYNC) && (~async_rd_addr_fifo_data_dont_care);

//fifo写由BUS的写地址通道控制，fifo读由SLAVE的读地址通道控制
slave_async_addr_fifo slave_async_rd_addr_fifo_inst(
    .wr_clk  (B_CLK             ), 
    .wr_rst  (rd_addr_fifo_wr_rst ), 
    .wr_en   (rd_addr_fifo_wr_en  ), 
    .wr_data (rd_addr_fifo_wr_data), 
    .wr_full (rd_addr_fifo_wr_full), 
    .almost_full (rd_addr_fifo_almost_full), 
    
    .rd_clk  (S_CLK            ),
    .rd_rst  (rd_addr_fifo_rd_rst  ),
    .rd_en   (rd_addr_fifo_rd_en   ),
    .rd_data (rd_addr_fifo_rd_data ),
    .rd_empty(rd_addr_fifo_rd_empty) 
);

//_______________________________________________________________//
wire              wr_data_fifo_wr_rst  ;
wire              wr_data_fifo_wr_en   ;
wire [32+4+1-1:0] wr_data_fifo_wr_data ;
wire              wr_data_fifo_wr_full ;
wire              wr_data_fifo_almost_full ;
wire              wr_data_fifo_rd_rst  ;
wire              wr_data_fifo_rd_en   ;
wire [32+4+1-1:0] wr_data_fifo_rd_data ;
wire              wr_data_fifo_rd_empty;

reg async_wr_data_fifo_data_dont_care;
always @(posedge S_CLK or negedge SLAVE_RSTN_SYNC) begin
    if(~SLAVE_RSTN_SYNC) async_wr_data_fifo_data_dont_care <= 1;
    else if(wr_data_fifo_rd_empty && (S_WR_DATA_VALID && S_WR_DATA_READY)) async_wr_data_fifo_data_dont_care <= 1;
    else if(wr_data_fifo_rd_en && async_wr_data_fifo_data_dont_care) async_wr_data_fifo_data_dont_care <= 0;
    else async_wr_data_fifo_data_dont_care <= async_wr_data_fifo_data_dont_care;
end

assign wr_data_fifo_wr_rst  =  ~BUS_RSTN_SYNC;
assign wr_data_fifo_wr_en   = (B_WR_DATA_VALID && B_WR_DATA_READY);
assign wr_data_fifo_wr_data = {B_WR_DATA, B_WR_STRB, B_WR_DATA_LAST};
assign B_WR_DATA_READY    = (BUS_RSTN_SYNC) && ~wr_data_fifo_almost_full;

assign wr_data_fifo_rd_rst  =  (~SLAVE_RSTN_SYNC) || (~RD_SLAVE_RSTN_SYNC);
assign wr_data_fifo_rd_en   = (~wr_data_fifo_rd_empty) && ((async_wr_data_fifo_data_dont_care) || (S_WR_DATA_VALID && S_WR_DATA_READY));
assign {S_WR_DATA, S_WR_STRB, S_WR_DATA_LAST} = wr_data_fifo_rd_data & ({(32+4+1){S_WR_DATA_VALID}});
assign S_WR_DATA_VALID  = (SLAVE_RSTN_SYNC) && (~async_wr_data_fifo_data_dont_care);

slave_async_wr_data_fifo slave_async_wr_data_fifo_inst(
    .wr_clk  (B_CLK             ), 
    .wr_rst  (wr_data_fifo_wr_rst ), 
    .wr_en   (wr_data_fifo_wr_en  ), 
    .wr_data (wr_data_fifo_wr_data), 
    .wr_full (wr_data_fifo_wr_full), 
    .almost_full (wr_data_fifo_almost_full), 
    
    .rd_clk  (S_CLK            ),
    .rd_rst  (wr_data_fifo_rd_rst  ),
    .rd_en   (wr_data_fifo_rd_en   ),
    .rd_data (wr_data_fifo_rd_data ),
    .rd_empty(wr_data_fifo_rd_empty) 
);

//_______________________________________________________________//
wire                rd_data_fifo_wr_rst  ;
wire                rd_data_fifo_wr_en   ;
wire [4+32+2+1-1:0] rd_data_fifo_wr_data ;
wire                rd_data_fifo_wr_full ;
wire                rd_data_fifo_almost_full ;
wire                rd_data_fifo_rd_rst  ;
wire                rd_data_fifo_rd_en   ;
wire [4+32+2+1-1:0] rd_data_fifo_rd_data ;
wire                rd_data_fifo_rd_empty;

reg async_rd_data_fifo_data_dont_care;
always @(posedge B_CLK or negedge BUS_RSTN_SYNC) begin
    if(~BUS_RSTN_SYNC) async_rd_data_fifo_data_dont_care <= 1;
    else if(rd_data_fifo_rd_empty && (B_RD_DATA_VALID && B_RD_DATA_READY)) async_rd_data_fifo_data_dont_care <= 1;
    else if(rd_data_fifo_rd_en && async_rd_data_fifo_data_dont_care) async_rd_data_fifo_data_dont_care <= 0;
    else async_rd_data_fifo_data_dont_care <= async_rd_data_fifo_data_dont_care;
end

assign rd_data_fifo_wr_rst  =  ~SLAVE_RSTN_SYNC;
assign rd_data_fifo_wr_en   = (S_RD_DATA_VALID && S_RD_DATA_READY);
assign rd_data_fifo_wr_data = {S_RD_BACK_ID, S_RD_DATA, S_RD_DATA_RESP, S_RD_DATA_LAST};
assign S_RD_DATA_READY  = (SLAVE_RSTN_SYNC) && ~rd_data_fifo_almost_full;

assign rd_data_fifo_rd_rst  =  (~BUS_RSTN_SYNC) || (~RD_BUS_RSTN_SYNC);
assign rd_data_fifo_rd_en   = (~rd_data_fifo_rd_empty) && ((async_rd_data_fifo_data_dont_care) || (B_RD_DATA_VALID && B_RD_DATA_READY));
assign {B_RD_BACK_ID, B_RD_DATA, B_RD_DATA_RESP, B_RD_DATA_LAST} = rd_data_fifo_rd_data & ({(4+32+2+1){B_RD_DATA_VALID}});
assign B_RD_DATA_VALID    = (BUS_RSTN_SYNC) && (~async_rd_data_fifo_data_dont_care);

//BUS读数据通道<===>fifo写通道<===>fifo读通道<===>SLAVE读数据通道   !!!!这个通道反过来!!!!
//{BACK_ID, DATA, RESP, LAST} WIDTH = 37
slave_async_rd_data_fifo slave_async_rd_data_fifo_inst(
    .wr_clk  (S_CLK           ), 
    .wr_rst  (rd_data_fifo_wr_rst ), 
    .wr_en   (rd_data_fifo_wr_en  ), 
    .wr_data (rd_data_fifo_wr_data), 
    .wr_full (rd_data_fifo_wr_full), 
    .almost_full (rd_data_fifo_almost_full), 
    
    .rd_clk  (B_CLK              ),
    .rd_rst  (rd_data_fifo_rd_rst  ),
    .rd_en   (rd_data_fifo_rd_en   ),
    .rd_data (rd_data_fifo_rd_data ),
    .rd_empty(rd_data_fifo_rd_empty) 
);

//_______________________________________________________________//
wire                  wr_back_fifo_wr_rst  ;
wire                  wr_back_fifo_wr_en   ;
wire [4+2-1:0]        wr_back_fifo_wr_data ;
wire                  wr_back_fifo_wr_full ;
wire                  wr_back_fifo_almost_full ;
wire                  wr_back_fifo_rd_rst  ;
wire                  wr_back_fifo_rd_en   ;
wire [4+2-1:0]        wr_back_fifo_rd_data ;
wire                  wr_back_fifo_rd_empty;

reg async_wr_back_fifo_data_dont_care;
always @(posedge B_CLK or negedge BUS_RSTN_SYNC) begin
    if(~BUS_RSTN_SYNC) async_wr_back_fifo_data_dont_care <= 1;
    else if(wr_back_fifo_rd_empty && (B_WR_BACK_VALID && B_WR_BACK_READY)) async_wr_back_fifo_data_dont_care <= 1;
    else if(wr_back_fifo_rd_en && async_wr_back_fifo_data_dont_care) async_wr_back_fifo_data_dont_care <= 0;
    else async_wr_back_fifo_data_dont_care <= async_wr_back_fifo_data_dont_care;
end

assign wr_back_fifo_wr_rst  =  ~SLAVE_RSTN_SYNC;
assign wr_back_fifo_wr_en   = (S_WR_BACK_VALID && S_WR_BACK_READY);
assign wr_back_fifo_wr_data = {S_WR_BACK_ID, S_WR_BACK_RESP};
assign S_WR_BACK_READY  = (SLAVE_RSTN_SYNC) && (~wr_back_fifo_almost_full);

assign wr_back_fifo_rd_rst  =  (~BUS_RSTN_SYNC) || (~RD_BUS_RSTN_SYNC);
assign wr_back_fifo_rd_en   = (~wr_back_fifo_rd_empty) && ((async_wr_back_fifo_data_dont_care) || (B_WR_BACK_VALID && B_WR_BACK_READY));
assign {B_WR_BACK_ID, B_WR_BACK_RESP} = wr_back_fifo_rd_data;
assign B_WR_BACK_VALID    = (BUS_RSTN_SYNC) && (~async_wr_back_fifo_data_dont_care);

slave_async_wr_back_fifo slave_async_wr_back_fifo_inst(
    .wr_clk  (S_CLK           ), 
    .wr_rst  (wr_back_fifo_wr_rst ), 
    .wr_en   (wr_back_fifo_wr_en  ), 
    .wr_data (wr_back_fifo_wr_data), 
    .wr_full (wr_back_fifo_wr_full), 
    .almost_full (wr_back_fifo_almost_full), 
    
    .rd_clk  (B_CLK              ),
    .rd_rst  (wr_back_fifo_rd_rst  ),
    .rd_en   (wr_back_fifo_rd_en   ),
    .rd_data (wr_back_fifo_rd_data ),
    .rd_empty(wr_back_fifo_rd_empty) 
);

assign fifo_empty_flag = {wr_addr_fifo_rd_empty, rd_addr_fifo_rd_empty, wr_data_fifo_rd_empty, rd_data_fifo_rd_empty, wr_back_fifo_rd_empty} & 
                         {async_wr_addr_fifo_data_dont_care, async_rd_addr_fifo_data_dont_care, async_wr_data_fifo_data_dont_care, async_rd_data_fifo_data_dont_care, async_wr_back_fifo_data_dont_care};

endmodule