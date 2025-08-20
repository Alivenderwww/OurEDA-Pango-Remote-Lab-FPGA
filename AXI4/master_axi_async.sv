module master_axi_async #(
    parameter ID_WIDTH = 2
)( //用于总线-主机的时钟域转换
input                   B_CLK          ,
input                   B_RSTN         ,
output [ID_WIDTH-1:0]   B_WR_ADDR_ID   ,
output [31:0]           B_WR_ADDR      ,
output [ 7:0]           B_WR_ADDR_LEN  ,
output [ 1:0]           B_WR_ADDR_BURST,
output                  B_WR_ADDR_VALID,
input                   B_WR_ADDR_READY,
output [31:0]           B_WR_DATA      ,
output [ 3:0]           B_WR_STRB      ,
output                  B_WR_DATA_LAST ,
output                  B_WR_DATA_VALID,
input                   B_WR_DATA_READY,
input  [ID_WIDTH-1:0]   B_WR_BACK_ID   ,
input  [ 1:0]           B_WR_BACK_RESP ,
input                   B_WR_BACK_VALID,
output                  B_WR_BACK_READY,
output [ID_WIDTH-1:0]   B_RD_ADDR_ID   ,
output [31:0]           B_RD_ADDR      ,
output [ 7:0]           B_RD_ADDR_LEN  ,
output [ 1:0]           B_RD_ADDR_BURST,
output                  B_RD_ADDR_VALID,
input                   B_RD_ADDR_READY,
input  [ID_WIDTH-1:0]   B_RD_BACK_ID   ,
input  [31:0]           B_RD_DATA      ,
input  [ 1:0]           B_RD_DATA_RESP ,
input                   B_RD_DATA_LAST ,
input                   B_RD_DATA_VALID,
output                  B_RD_DATA_READY,

input                   M_CLK          ,
input                   M_RSTN         ,
input  [ID_WIDTH-1:0]   M_WR_ADDR_ID   ,
input  [31:0]           M_WR_ADDR      ,
input  [ 7:0]           M_WR_ADDR_LEN  ,
input  [ 1:0]           M_WR_ADDR_BURST,
input                   M_WR_ADDR_VALID,
output                  M_WR_ADDR_READY,
input  [31:0]           M_WR_DATA      ,
input  [ 3:0]           M_WR_STRB      ,
input                   M_WR_DATA_LAST ,
input                   M_WR_DATA_VALID,
output                  M_WR_DATA_READY,
output [ID_WIDTH-1:0]   M_WR_BACK_ID   ,
output [ 1:0]           M_WR_BACK_RESP ,
output                  M_WR_BACK_VALID,
input                   M_WR_BACK_READY,
input  [ID_WIDTH-1:0]   M_RD_ADDR_ID   ,
input  [31:0]           M_RD_ADDR      ,
input  [ 7:0]           M_RD_ADDR_LEN  ,
input  [ 1:0]           M_RD_ADDR_BURST,
input                   M_RD_ADDR_VALID,
output                  M_RD_ADDR_READY,
output [ID_WIDTH-1:0]   M_RD_BACK_ID   ,
output [31:0]           M_RD_DATA      ,
output [ 1:0]           M_RD_DATA_RESP ,
output                  M_RD_DATA_LAST ,
output                  M_RD_DATA_VALID,
input                   M_RD_DATA_READY,

output wire [4:0] fifo_empty_flag
);

wire BUS_RSTN_SYNC, MASTER_RSTN_SYNC, RD_BUS_RSTN_SYNC, RD_MASTER_RSTN_SYNC;
rstn_sync #(32) rstn_sync_bus   (B_CLK, B_RSTN, BUS_RSTN_SYNC);
rstn_sync #(64) rstn_sync_rd_bus(B_CLK, B_RSTN, RD_BUS_RSTN_SYNC);
rstn_sync #(32) rstn_sync_master(M_CLK, M_RSTN, MASTER_RSTN_SYNC);
rstn_sync #(64) rstn_sync_rd_master(M_CLK, M_RSTN, RD_MASTER_RSTN_SYNC);

wire                       wr_addr_fifo_wr_rst  ;
wire                       wr_addr_fifo_wr_en   ;
wire [32+8+2+ID_WIDTH-1:0] wr_addr_fifo_wr_data ;
wire                       wr_addr_fifo_wr_full ;
wire                       wr_addr_fifo_almost_full ;
wire                       wr_addr_fifo_rd_rst  ;
wire                       wr_addr_fifo_rd_en   ;
wire [32+8+2+ID_WIDTH-1:0] wr_addr_fifo_rd_data ;
wire                       wr_addr_fifo_rd_empty;

reg async_wr_addr_fifo_data_dont_care;
always @(posedge B_CLK or negedge BUS_RSTN_SYNC) begin
    if(~BUS_RSTN_SYNC) async_wr_addr_fifo_data_dont_care <= 1;
    else if(wr_addr_fifo_rd_empty && (B_WR_ADDR_VALID && B_WR_ADDR_READY)) async_wr_addr_fifo_data_dont_care <= 1;
    else if(wr_addr_fifo_rd_en && async_wr_addr_fifo_data_dont_care) async_wr_addr_fifo_data_dont_care <= 0;
    else async_wr_addr_fifo_data_dont_care <= async_wr_addr_fifo_data_dont_care;
end

assign wr_addr_fifo_wr_rst  =  ~MASTER_RSTN_SYNC;
assign wr_addr_fifo_wr_en   = (M_WR_ADDR_VALID && M_WR_ADDR_READY);
assign wr_addr_fifo_wr_data = {M_WR_ADDR_ID, M_WR_ADDR, M_WR_ADDR_LEN, M_WR_ADDR_BURST};
assign M_WR_ADDR_READY = (MASTER_RSTN_SYNC) && (~wr_addr_fifo_almost_full);

assign wr_addr_fifo_rd_rst  =  (~BUS_RSTN_SYNC) || (~RD_BUS_RSTN_SYNC);
assign wr_addr_fifo_rd_en   = (~wr_addr_fifo_rd_empty) && ((async_wr_addr_fifo_data_dont_care) || (B_WR_ADDR_VALID && B_WR_ADDR_READY));
assign {B_WR_ADDR_ID, B_WR_ADDR, B_WR_ADDR_LEN, B_WR_ADDR_BURST} = wr_addr_fifo_rd_data;
assign B_WR_ADDR_VALID    = (BUS_RSTN_SYNC) && (~async_wr_addr_fifo_data_dont_care);

//写地址通道和读地址通道是完全一样的接口设计，都用async_addr_fifo模块就可以
//MASTER写地址通道<===>fifo写通道<===>fifo读通道<===>BUS写地址通道
master_async_addr_fifo master_async_wr_addr_fifo_inst(
    .wr_clk  (M_CLK      ), 
    .wr_rst  (wr_addr_fifo_wr_rst ), 
    .wr_en   (wr_addr_fifo_wr_en  ), 
    .wr_data (wr_addr_fifo_wr_data), 
    .wr_full (wr_addr_fifo_wr_full), 
    .almost_full (wr_addr_fifo_almost_full), 
    
    .rd_clk  (B_CLK          ),
    .rd_rst  (wr_addr_fifo_rd_rst  ),
    .rd_en   (wr_addr_fifo_rd_en   ),
    .rd_data (wr_addr_fifo_rd_data ),
    .rd_empty(wr_addr_fifo_rd_empty) 
);

//_______________________________________________________________//
wire                       rd_addr_fifo_wr_rst  ;
wire                       rd_addr_fifo_wr_en   ;
wire [32+8+2+ID_WIDTH-1:0] rd_addr_fifo_wr_data ;
wire                       rd_addr_fifo_wr_full ;
wire                       rd_addr_fifo_almost_full ;
wire                       rd_addr_fifo_rd_rst  ;
wire                       rd_addr_fifo_rd_en   ;
wire [32+8+2+ID_WIDTH-1:0] rd_addr_fifo_rd_data ;
wire                       rd_addr_fifo_rd_empty;

reg async_rd_addr_fifo_data_dont_care;
always @(posedge B_CLK or negedge BUS_RSTN_SYNC) begin
    if(~BUS_RSTN_SYNC) async_rd_addr_fifo_data_dont_care <= 1;
    else if(rd_addr_fifo_rd_empty && (B_RD_ADDR_VALID && B_RD_ADDR_READY)) async_rd_addr_fifo_data_dont_care <= 1;
    else if(rd_addr_fifo_rd_en && async_rd_addr_fifo_data_dont_care) async_rd_addr_fifo_data_dont_care <= 0;
    else async_rd_addr_fifo_data_dont_care <= async_rd_addr_fifo_data_dont_care;
end

assign rd_addr_fifo_wr_rst  =  ~MASTER_RSTN_SYNC;
assign rd_addr_fifo_wr_en   = (M_RD_ADDR_VALID && M_RD_ADDR_READY);
assign rd_addr_fifo_wr_data = {M_RD_ADDR_ID, M_RD_ADDR, M_RD_ADDR_LEN, M_RD_ADDR_BURST};
assign M_RD_ADDR_READY = (MASTER_RSTN_SYNC) && (~rd_addr_fifo_almost_full);

assign rd_addr_fifo_rd_rst  =  (~BUS_RSTN_SYNC) || (~RD_BUS_RSTN_SYNC);
assign rd_addr_fifo_rd_en   = (~rd_addr_fifo_rd_empty) && ((async_rd_addr_fifo_data_dont_care) || (B_RD_ADDR_VALID && B_RD_ADDR_READY));
assign {B_RD_ADDR_ID, B_RD_ADDR, B_RD_ADDR_LEN, B_RD_ADDR_BURST} = rd_addr_fifo_rd_data;
assign B_RD_ADDR_VALID    = (BUS_RSTN_SYNC) && (~async_rd_addr_fifo_data_dont_care);

//fifo写由BUS的写地址通道控制，fifo读由MASTER的读地址通道控制
//MASTER读地址通道<===>fifo写通道<===>fifo读通道<===>BUS读地址通道
//{M_RD_ADDR, M_RD_LEN, M_RD_ID} WIDTH = 42
master_async_addr_fifo master_async_rd_addr_fifo_inst(
    .wr_clk  (M_CLK          ), 
    .wr_rst  (rd_addr_fifo_wr_rst ), 
    .wr_en   (rd_addr_fifo_wr_en  ), 
    .wr_data (rd_addr_fifo_wr_data), 
    .wr_full (rd_addr_fifo_wr_full), 
    .almost_full (rd_addr_fifo_almost_full), 
    
    .rd_clk  (B_CLK              ),
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
always @(posedge B_CLK or negedge BUS_RSTN_SYNC) begin
    if(~BUS_RSTN_SYNC) async_wr_data_fifo_data_dont_care <= 1;
    else if(wr_data_fifo_rd_empty && (B_WR_DATA_VALID && B_WR_DATA_READY)) async_wr_data_fifo_data_dont_care <= 1;
    else if(wr_data_fifo_rd_en && async_wr_data_fifo_data_dont_care) async_wr_data_fifo_data_dont_care <= 0;
    else async_wr_data_fifo_data_dont_care <= async_wr_data_fifo_data_dont_care;
end

assign wr_data_fifo_wr_rst  =  ~MASTER_RSTN_SYNC;
assign wr_data_fifo_wr_en   = (M_WR_DATA_VALID && M_WR_DATA_READY);
assign wr_data_fifo_wr_data = {M_WR_DATA, M_WR_STRB, M_WR_DATA_LAST};
assign M_WR_DATA_READY = (MASTER_RSTN_SYNC) && ~wr_data_fifo_almost_full;

assign wr_data_fifo_rd_rst  =  (~BUS_RSTN_SYNC) || (~RD_BUS_RSTN_SYNC);
assign wr_data_fifo_rd_en   = (~wr_data_fifo_rd_empty) && ((async_wr_data_fifo_data_dont_care) || (B_WR_DATA_VALID && B_WR_DATA_READY));
assign {B_WR_DATA, B_WR_STRB, B_WR_DATA_LAST} = wr_data_fifo_rd_data;
assign B_WR_DATA_VALID   = (BUS_RSTN_SYNC) && (~async_wr_data_fifo_data_dont_care);

//MASTER写数据通道<===>fifo写通道<===>fifo读通道<===>BUS写数据通道
master_async_wr_data_fifo master_async_wr_data_fifo_inst(
    .wr_clk  (M_CLK          ), 
    .wr_rst  (wr_data_fifo_wr_rst ), 
    .wr_en   (wr_data_fifo_wr_en  ), 
    .wr_data (wr_data_fifo_wr_data), 
    .wr_full (wr_data_fifo_wr_full), 
    .almost_full (wr_data_fifo_almost_full), 
    
    .rd_clk  (B_CLK              ),
    .rd_rst  (wr_data_fifo_rd_rst  ),
    .rd_en   (wr_data_fifo_rd_en   ),
    .rd_data (wr_data_fifo_rd_data ),
    .rd_empty(wr_data_fifo_rd_empty) 
);

//_______________________________________________________________//
wire                       rd_data_fifo_wr_rst  ;
wire                       rd_data_fifo_wr_en   ;
wire [ID_WIDTH+32+2+1-1:0] rd_data_fifo_wr_data ;
wire                       rd_data_fifo_wr_full ;
wire                       rd_data_fifo_almost_full ;
wire                       rd_data_fifo_rd_rst  ;
wire                       rd_data_fifo_rd_en   ;
wire [ID_WIDTH+32+2+1-1:0] rd_data_fifo_rd_data ;
wire                       rd_data_fifo_rd_empty;

reg async_rd_data_fifo_data_dont_care;
always @(posedge M_CLK or negedge MASTER_RSTN_SYNC) begin
    if(~MASTER_RSTN_SYNC) async_rd_data_fifo_data_dont_care <= 1;
    else if(rd_data_fifo_rd_empty && (M_RD_DATA_VALID && M_RD_DATA_READY)) async_rd_data_fifo_data_dont_care <= 1;
    else if(rd_data_fifo_rd_en && async_rd_data_fifo_data_dont_care) async_rd_data_fifo_data_dont_care <= 0;
    else async_rd_data_fifo_data_dont_care <= async_rd_data_fifo_data_dont_care;
end

assign rd_data_fifo_wr_rst  =  ~BUS_RSTN_SYNC;
assign rd_data_fifo_wr_en   = (B_RD_DATA_VALID && B_RD_DATA_READY);
assign rd_data_fifo_wr_data = {B_RD_BACK_ID, B_RD_DATA, B_RD_DATA_RESP, B_RD_DATA_LAST};
assign B_RD_DATA_READY    = (BUS_RSTN_SYNC) && ~rd_data_fifo_almost_full;

assign rd_data_fifo_rd_rst  =  (~MASTER_RSTN_SYNC) || (~RD_MASTER_RSTN_SYNC);
assign rd_data_fifo_rd_en   = (~rd_data_fifo_rd_empty) && ((async_rd_data_fifo_data_dont_care) || (M_RD_DATA_VALID && M_RD_DATA_READY));
assign {M_RD_BACK_ID, M_RD_DATA, M_RD_DATA_RESP, M_RD_DATA_LAST} = rd_data_fifo_rd_data;
assign M_RD_DATA_VALID = (MASTER_RSTN_SYNC) && (~async_rd_data_fifo_data_dont_care);

//BUS读数据通道<===>fifo写通道<===>fifo读通道<===>MASTER读数据通道   !!!!这个通道反过来!!!!
//{BACK_ID, DATA, RESP, LAST} WIDTH = 37
master_async_rd_data_fifo master_async_rd_data_fifo_inst(
    .wr_clk  (B_CLK             ), 
    .wr_rst  (rd_data_fifo_wr_rst ), 
    .wr_en   (rd_data_fifo_wr_en  ), 
    .wr_data (rd_data_fifo_wr_data), 
    .wr_full (rd_data_fifo_wr_full), 
    .almost_full (rd_data_fifo_almost_full), 
    
    .rd_clk  (M_CLK           ),
    .rd_rst  (rd_data_fifo_rd_rst  ),
    .rd_en   (rd_data_fifo_rd_en   ),
    .rd_data (rd_data_fifo_rd_data ),
    .rd_empty(rd_data_fifo_rd_empty) 
);

//_______________________________________________________________//
wire                         wr_back_fifo_wr_rst  ;
wire                         wr_back_fifo_wr_en   ;
wire [ID_WIDTH+2-1:0]        wr_back_fifo_wr_data ;
wire                         wr_back_fifo_wr_full ;
wire                         wr_back_fifo_almost_full ;
wire                         wr_back_fifo_rd_rst  ;
wire                         wr_back_fifo_rd_en   ;
wire [ID_WIDTH+2-1:0]        wr_back_fifo_rd_data ;
wire                         wr_back_fifo_rd_empty;

reg async_wr_back_fifo_data_dont_care;
always @(posedge M_CLK or negedge MASTER_RSTN_SYNC) begin
    if(~MASTER_RSTN_SYNC) async_wr_back_fifo_data_dont_care <= 1;
    else if(wr_back_fifo_rd_empty && (M_WR_BACK_VALID && M_WR_BACK_READY)) async_wr_back_fifo_data_dont_care <= 1;
    else if(wr_back_fifo_rd_en && async_wr_back_fifo_data_dont_care) async_wr_back_fifo_data_dont_care <= 0;
    else async_wr_back_fifo_data_dont_care <= async_wr_back_fifo_data_dont_care;
end

assign wr_back_fifo_wr_rst  =  ~BUS_RSTN_SYNC;
assign wr_back_fifo_wr_en   = (B_WR_BACK_VALID && B_WR_BACK_READY);
assign wr_back_fifo_wr_data = {B_WR_BACK_ID, B_WR_BACK_RESP};
assign B_WR_BACK_READY    = (BUS_RSTN_SYNC) && ~wr_back_fifo_almost_full;

assign wr_back_fifo_rd_rst  =  (~MASTER_RSTN_SYNC) || (~RD_MASTER_RSTN_SYNC);
assign wr_back_fifo_rd_en   = (~wr_back_fifo_rd_empty) && ((async_wr_back_fifo_data_dont_care) || (M_WR_BACK_VALID && M_WR_BACK_READY));
assign {M_WR_BACK_ID, M_WR_BACK_RESP} = wr_back_fifo_rd_data;
assign M_WR_BACK_VALID = (MASTER_RSTN_SYNC) && (~async_wr_back_fifo_data_dont_care);

//BUS读数据通道<===>fifo写通道<===>fifo读通道<===>MASTER读数据通道   !!!!这个通道反过来!!!!
master_async_wr_back_fifo master_async_wr_back_fifo_inst(
    .wr_clk  (B_CLK             ), 
    .wr_rst  (wr_back_fifo_wr_rst ), 
    .wr_en   (wr_back_fifo_wr_en  ), 
    .wr_data (wr_back_fifo_wr_data), 
    .wr_full (wr_back_fifo_wr_full), 
    .almost_full (wr_back_fifo_almost_full), 
    
    .rd_clk  (M_CLK           ),
    .rd_rst  (wr_back_fifo_rd_rst  ),
    .rd_en   (wr_back_fifo_rd_en   ),
    .rd_data (wr_back_fifo_rd_data ),
    .rd_empty(wr_back_fifo_rd_empty) 
);

assign fifo_empty_flag = {wr_addr_fifo_rd_empty, rd_addr_fifo_rd_empty, wr_data_fifo_rd_empty, rd_data_fifo_rd_empty, wr_back_fifo_rd_empty} & 
                         {async_wr_addr_fifo_data_dont_care, async_rd_addr_fifo_data_dont_care, async_wr_data_fifo_data_dont_care, async_rd_data_fifo_data_dont_care, async_wr_back_fifo_data_dont_care};

endmodule