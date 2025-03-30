module slave_axi_async ( //用于总线-从机的时钟域转换
input wire         BUS_CLK          , input  wire        SLAVE_CLK          ,
input wire         BUS_RSTN         , input  wire        SLAVE_RSTN         ,
input  wire [ 3:0] BUS_WR_ADDR_ID   , output wire [ 3:0] SLAVE_WR_ADDR_ID   ,
input  wire [31:0] BUS_WR_ADDR      , output wire [31:0] SLAVE_WR_ADDR      ,
input  wire [ 7:0] BUS_WR_ADDR_LEN  , output wire [ 7:0] SLAVE_WR_ADDR_LEN  ,
input  wire [ 1:0] BUS_WR_ADDR_BURST, output wire [ 1:0] SLAVE_WR_ADDR_BURST,
input  wire        BUS_WR_ADDR_VALID, output wire        SLAVE_WR_ADDR_VALID,
output wire        BUS_WR_ADDR_READY, input  wire        SLAVE_WR_ADDR_READY,

input  wire [31:0] BUS_WR_DATA      , output wire [31:0] SLAVE_WR_DATA      ,
input  wire [ 3:0] BUS_WR_STRB      , output wire [ 3:0] SLAVE_WR_STRB      ,
input  wire        BUS_WR_DATA_LAST , output wire        SLAVE_WR_DATA_LAST ,
input  wire        BUS_WR_DATA_VALID, output wire        SLAVE_WR_DATA_VALID,
output wire        BUS_WR_DATA_READY, input  wire        SLAVE_WR_DATA_READY,

output wire [ 3:0] BUS_WR_BACK_ID   , input  wire [ 3:0] SLAVE_WR_BACK_ID   ,
output wire [ 1:0] BUS_WR_BACK_RESP , input  wire [ 1:0] SLAVE_WR_BACK_RESP ,
output wire        BUS_WR_BACK_VALID, input  wire        SLAVE_WR_BACK_VALID,
input  wire        BUS_WR_BACK_READY, output wire        SLAVE_WR_BACK_READY,

input  wire [ 3:0] BUS_RD_ADDR_ID   , output wire [ 3:0] SLAVE_RD_ADDR_ID   ,
input  wire [31:0] BUS_RD_ADDR      , output wire [31:0] SLAVE_RD_ADDR      ,
input  wire [ 7:0] BUS_RD_ADDR_LEN  , output wire [ 7:0] SLAVE_RD_ADDR_LEN  ,
input  wire [ 1:0] BUS_RD_ADDR_BURST, output wire [ 1:0] SLAVE_RD_ADDR_BURST,
input  wire        BUS_RD_ADDR_VALID, output wire        SLAVE_RD_ADDR_VALID,
output wire        BUS_RD_ADDR_READY, input  wire        SLAVE_RD_ADDR_READY,

output wire [ 3:0] BUS_RD_BACK_ID   , input  wire [ 3:0] SLAVE_RD_BACK_ID   ,
output wire [31:0] BUS_RD_DATA      , input  wire [31:0] SLAVE_RD_DATA      ,
output wire [ 1:0] BUS_RD_DATA_RESP , input  wire [ 1:0] SLAVE_RD_DATA_RESP ,
output wire        BUS_RD_DATA_LAST , input  wire        SLAVE_RD_DATA_LAST ,
output wire        BUS_RD_DATA_VALID, input  wire        SLAVE_RD_DATA_VALID,
input  wire        BUS_RD_DATA_READY, output wire        SLAVE_RD_DATA_READY,

output wire [ 4:0] fifo_empty_flag
);

wire RSTN = BUS_RSTN & SLAVE_RSTN;

wire                wr_addr_fifo_wr_rst  ;
wire                wr_addr_fifo_wr_en   ;
wire [32+8+4+2-1:0] wr_addr_fifo_wr_data ;
wire                wr_addr_fifo_wr_full ;
wire                wr_addr_fifo_rd_rst  ;
wire                wr_addr_fifo_rd_en   ;
wire [32+8+4+2-1:0] wr_addr_fifo_rd_data ;
wire                wr_addr_fifo_rd_empty;

reg async_wr_addr_fifo_data_dont_care;
always @(posedge SLAVE_CLK) begin
    if(~SLAVE_RSTN) async_wr_addr_fifo_data_dont_care <= 1;
    else if(wr_addr_fifo_rd_empty && (SLAVE_WR_ADDR_VALID && SLAVE_WR_ADDR_READY)) async_wr_addr_fifo_data_dont_care <= 1;
    else if(wr_addr_fifo_rd_en && async_wr_addr_fifo_data_dont_care) async_wr_addr_fifo_data_dont_care <= 0;
    else async_wr_addr_fifo_data_dont_care <= async_wr_addr_fifo_data_dont_care;
end

assign wr_addr_fifo_wr_rst  =  ~BUS_RSTN;
assign wr_addr_fifo_wr_en   = (BUS_WR_ADDR_VALID && BUS_WR_ADDR_READY);
assign wr_addr_fifo_wr_data = {BUS_WR_ADDR_ID, BUS_WR_ADDR, BUS_WR_ADDR_LEN, BUS_WR_ADDR_BURST};
assign BUS_WR_ADDR_READY = (RSTN) && (~wr_addr_fifo_wr_full);

assign wr_addr_fifo_rd_rst  =  ~SLAVE_RSTN;
assign wr_addr_fifo_rd_en   = (~wr_addr_fifo_rd_empty) && ((async_wr_addr_fifo_data_dont_care) || (SLAVE_WR_ADDR_VALID && SLAVE_WR_ADDR_READY));
assign {SLAVE_WR_ADDR_ID, SLAVE_WR_ADDR, SLAVE_WR_ADDR_LEN, SLAVE_WR_ADDR_BURST} = wr_addr_fifo_rd_data;
assign SLAVE_WR_ADDR_VALID  = (RSTN) && (~async_wr_addr_fifo_data_dont_care);

//写地址通道和读地址通道是完全一样的接口设计，都用async_addr_fifo模块就可以
slave_async_addr_fifo slave_async_wr_addr_fifo_inst(
    .wr_clk  (BUS_CLK             ), 
    .wr_rst  (wr_addr_fifo_wr_rst ), 
    .wr_en   (wr_addr_fifo_wr_en  ), 
    .wr_data (wr_addr_fifo_wr_data), 
    .wr_full (wr_addr_fifo_wr_full), 
    
    .rd_clk  (SLAVE_CLK            ),
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
wire                rd_addr_fifo_rd_rst  ;
wire                rd_addr_fifo_rd_en   ;
wire [32+8+4+2-1:0] rd_addr_fifo_rd_data ;
wire                rd_addr_fifo_rd_empty;

reg async_rd_addr_fifo_data_dont_care;
always @(posedge SLAVE_CLK) begin
    if(~SLAVE_RSTN) async_rd_addr_fifo_data_dont_care <= 1;
    else if(rd_addr_fifo_rd_empty && (SLAVE_RD_ADDR_VALID && SLAVE_RD_ADDR_READY)) async_rd_addr_fifo_data_dont_care <= 1;
    else if(rd_addr_fifo_rd_en && async_rd_addr_fifo_data_dont_care) async_rd_addr_fifo_data_dont_care <= 0;
    else async_rd_addr_fifo_data_dont_care <= async_rd_addr_fifo_data_dont_care;
end

assign rd_addr_fifo_wr_rst  =  ~BUS_RSTN;
assign rd_addr_fifo_wr_en   = (BUS_RD_ADDR_VALID && BUS_RD_ADDR_READY);
assign rd_addr_fifo_wr_data = {BUS_RD_ADDR_ID, BUS_RD_ADDR, BUS_RD_ADDR_LEN, BUS_RD_ADDR_BURST};
assign BUS_RD_ADDR_READY    = (RSTN) && (~rd_addr_fifo_wr_full);

assign rd_addr_fifo_rd_rst  =  ~SLAVE_RSTN;
assign rd_addr_fifo_rd_en   = (~rd_addr_fifo_rd_empty) && ((async_rd_addr_fifo_data_dont_care) || (SLAVE_RD_ADDR_VALID && SLAVE_RD_ADDR_READY));
assign {SLAVE_RD_ADDR_ID, SLAVE_RD_ADDR, SLAVE_RD_ADDR_LEN, SLAVE_RD_ADDR_BURST} = rd_addr_fifo_rd_data;
assign SLAVE_RD_ADDR_VALID  = (RSTN) && (~async_rd_addr_fifo_data_dont_care);

//fifo写由BUS的写地址通道控制，fifo读由SLAVE的读地址通道控制
slave_async_addr_fifo slave_async_rd_addr_fifo_inst(
    .wr_clk  (BUS_CLK             ), 
    .wr_rst  (rd_addr_fifo_wr_rst ), 
    .wr_en   (rd_addr_fifo_wr_en  ), 
    .wr_data (rd_addr_fifo_wr_data), 
    .wr_full (rd_addr_fifo_wr_full), 
    
    .rd_clk  (SLAVE_CLK            ),
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
wire              wr_data_fifo_rd_rst  ;
wire              wr_data_fifo_rd_en   ;
wire [32+4+1-1:0] wr_data_fifo_rd_data ;
wire              wr_data_fifo_rd_empty;

reg async_wr_data_fifo_data_dont_care;
always @(posedge SLAVE_CLK) begin
    if(~SLAVE_RSTN) async_wr_data_fifo_data_dont_care <= 1;
    else if(wr_data_fifo_rd_empty && (SLAVE_WR_DATA_VALID && SLAVE_WR_DATA_READY)) async_wr_data_fifo_data_dont_care <= 1;
    else if(wr_data_fifo_rd_en && async_wr_data_fifo_data_dont_care) async_wr_data_fifo_data_dont_care <= 0;
    else async_wr_data_fifo_data_dont_care <= async_wr_data_fifo_data_dont_care;
end

assign wr_data_fifo_wr_rst  =  ~BUS_RSTN;
assign wr_data_fifo_wr_en   = (BUS_WR_DATA_VALID && BUS_WR_DATA_READY);
assign wr_data_fifo_wr_data = {BUS_WR_DATA, BUS_WR_STRB, BUS_WR_DATA_LAST};
assign BUS_WR_DATA_READY    = (RSTN) && ~wr_data_fifo_wr_full;

assign wr_data_fifo_rd_rst  =  ~SLAVE_RSTN;
assign wr_data_fifo_rd_en   = (~wr_data_fifo_rd_empty) && ((async_wr_data_fifo_data_dont_care) || (SLAVE_WR_DATA_VALID && SLAVE_WR_DATA_READY));
assign {SLAVE_WR_DATA, SLAVE_WR_STRB, SLAVE_WR_DATA_LAST} = wr_data_fifo_rd_data & ({(32+4+1){SLAVE_WR_DATA_VALID}});
assign SLAVE_WR_DATA_VALID  = (RSTN) && (~async_wr_data_fifo_data_dont_care);

slave_async_wr_data_fifo slave_async_wr_data_fifo_inst(
    .wr_clk  (BUS_CLK             ), 
    .wr_rst  (wr_data_fifo_wr_rst ), 
    .wr_en   (wr_data_fifo_wr_en  ), 
    .wr_data (wr_data_fifo_wr_data), 
    .wr_full (wr_data_fifo_wr_full), 
    
    .rd_clk  (SLAVE_CLK            ),
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
wire                rd_data_fifo_rd_rst  ;
wire                rd_data_fifo_rd_en   ;
wire [4+32+2+1-1:0] rd_data_fifo_rd_data ;
wire                rd_data_fifo_rd_empty;

reg async_rd_data_fifo_data_dont_care;
always @(posedge BUS_CLK) begin
    if(~BUS_RSTN) async_rd_data_fifo_data_dont_care <= 1;
    else if(rd_data_fifo_rd_empty && (BUS_RD_DATA_VALID && BUS_RD_DATA_READY)) async_rd_data_fifo_data_dont_care <= 1;
    else if(rd_data_fifo_rd_en && async_rd_data_fifo_data_dont_care) async_rd_data_fifo_data_dont_care <= 0;
    else async_rd_data_fifo_data_dont_care <= async_rd_data_fifo_data_dont_care;
end

assign rd_data_fifo_wr_rst  =  ~SLAVE_RSTN;
assign rd_data_fifo_wr_en   = (SLAVE_RD_DATA_VALID && SLAVE_RD_DATA_READY);
assign rd_data_fifo_wr_data = {SLAVE_RD_BACK_ID, SLAVE_RD_DATA, SLAVE_RD_DATA_RESP, SLAVE_RD_DATA_LAST};
assign SLAVE_RD_DATA_READY  = (RSTN) && ~rd_data_fifo_wr_full;

assign rd_data_fifo_rd_rst  =  ~BUS_RSTN;
assign rd_data_fifo_rd_en   = (~rd_data_fifo_rd_empty) && ((async_rd_data_fifo_data_dont_care) || (BUS_RD_DATA_VALID && BUS_RD_DATA_READY));
assign {BUS_RD_BACK_ID, BUS_RD_DATA, BUS_RD_DATA_RESP, BUS_RD_DATA_LAST} = rd_data_fifo_rd_data & ({(4+32+2+1){BUS_RD_DATA_VALID}});
assign BUS_RD_DATA_VALID    = (RSTN) && (~async_rd_data_fifo_data_dont_care);

//BUS读数据通道<===>fifo写通道<===>fifo读通道<===>SLAVE读数据通道   !!!!这个通道反过来!!!!
//{BACK_ID, DATA, RESP, LAST} WIDTH = 37
slave_async_rd_data_fifo slave_async_rd_data_fifo_inst(
    .wr_clk  (SLAVE_CLK           ), 
    .wr_rst  (rd_data_fifo_wr_rst ), 
    .wr_en   (rd_data_fifo_wr_en  ), 
    .wr_data (rd_data_fifo_wr_data), 
    .wr_full (rd_data_fifo_wr_full), 
    
    .rd_clk  (BUS_CLK              ),
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
wire                  wr_back_fifo_rd_rst  ;
wire                  wr_back_fifo_rd_en   ;
wire [4+2-1:0]        wr_back_fifo_rd_data ;
wire                  wr_back_fifo_rd_empty;

reg async_wr_back_fifo_data_dont_care;
always @(posedge BUS_CLK) begin
    if(~BUS_RSTN) async_wr_back_fifo_data_dont_care <= 1;
    else if(wr_back_fifo_rd_empty && (BUS_WR_BACK_VALID && BUS_WR_BACK_READY)) async_wr_back_fifo_data_dont_care <= 1;
    else if(wr_back_fifo_rd_en && async_wr_back_fifo_data_dont_care) async_wr_back_fifo_data_dont_care <= 0;
    else async_wr_back_fifo_data_dont_care <= async_wr_back_fifo_data_dont_care;
end

assign wr_back_fifo_wr_rst  =  ~SLAVE_RSTN;
assign wr_back_fifo_wr_en   = (SLAVE_WR_BACK_VALID && SLAVE_WR_BACK_READY);
assign wr_back_fifo_wr_data = {SLAVE_WR_BACK_ID, SLAVE_WR_BACK_RESP};
assign SLAVE_WR_BACK_READY  = (RSTN) && (~wr_back_fifo_wr_full);

assign wr_back_fifo_rd_rst  =  ~BUS_RSTN;
assign wr_back_fifo_rd_en   = (~wr_back_fifo_rd_empty) && ((async_wr_back_fifo_data_dont_care) || (BUS_WR_BACK_VALID && BUS_WR_BACK_READY));
assign {BUS_WR_BACK_ID, BUS_WR_BACK_RESP} = wr_back_fifo_rd_data;
assign BUS_WR_BACK_VALID    = (RSTN) && (~async_wr_back_fifo_data_dont_care);

slave_async_wr_back_fifo slave_async_wr_back_fifo_inst(
    .wr_clk  (SLAVE_CLK           ), 
    .wr_rst  (wr_back_fifo_wr_rst ), 
    .wr_en   (wr_back_fifo_wr_en  ), 
    .wr_data (wr_back_fifo_wr_data), 
    .wr_full (wr_back_fifo_wr_full), 
    
    .rd_clk  (BUS_CLK              ),
    .rd_rst  (wr_back_fifo_rd_rst  ),
    .rd_en   (wr_back_fifo_rd_en   ),
    .rd_data (wr_back_fifo_rd_data ),
    .rd_empty(wr_back_fifo_rd_empty) 
);

assign fifo_empty_flag = {wr_addr_fifo_rd_empty, rd_addr_fifo_rd_empty, wr_data_fifo_rd_empty, rd_data_fifo_rd_empty, wr_back_fifo_rd_empty};

endmodule