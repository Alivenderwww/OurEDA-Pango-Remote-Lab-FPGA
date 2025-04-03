module slave_axi_async ( //用于总线-从机的时钟域转换
input B_CLK,
input B_RSTN,
AXI_INF.SYNC_S   AXI_B  ,
AXI_INF.INTER_S  AXI_S  ,
output wire [4:0] fifo_empty_flag
);

wire BUS_RSTN_SYNC, SLAVE_RSTN_SYNC;
rstn_sync rstn_sync_bus   (B_CLK, B_RSTN, BUS_RSTN_SYNC);
rstn_sync rstn_sync_slave (AXI_S.CLK, AXI_S.RSTN, SLAVE_RSTN_SYNC);

wire                wr_addr_fifo_wr_rst  ;
wire                wr_addr_fifo_wr_en   ;
wire [32+8+4+2-1:0] wr_addr_fifo_wr_data ;
wire                wr_addr_fifo_wr_full ;
wire                wr_addr_fifo_rd_rst  ;
wire                wr_addr_fifo_rd_en   ;
wire [32+8+4+2-1:0] wr_addr_fifo_rd_data ;
wire                wr_addr_fifo_rd_empty;

reg async_wr_addr_fifo_data_dont_care;
always @(posedge AXI_S.CLK or negedge SLAVE_RSTN_SYNC) begin
    if(~SLAVE_RSTN_SYNC) async_wr_addr_fifo_data_dont_care <= 1;
    else if(wr_addr_fifo_rd_empty && (AXI_S.WR_ADDR_VALID && AXI_S.WR_ADDR_READY)) async_wr_addr_fifo_data_dont_care <= 1;
    else if(wr_addr_fifo_rd_en && async_wr_addr_fifo_data_dont_care) async_wr_addr_fifo_data_dont_care <= 0;
    else async_wr_addr_fifo_data_dont_care <= async_wr_addr_fifo_data_dont_care;
end

assign wr_addr_fifo_wr_rst  =  ~BUS_RSTN_SYNC;
assign wr_addr_fifo_wr_en   = (AXI_B.WR_ADDR_VALID && AXI_B.WR_ADDR_READY);
assign wr_addr_fifo_wr_data = {AXI_B.WR_ADDR_ID, AXI_B.WR_ADDR, AXI_B.WR_ADDR_LEN, AXI_B.WR_ADDR_BURST};
assign AXI_B.WR_ADDR_READY = (BUS_RSTN_SYNC) && (~wr_addr_fifo_wr_full);

assign wr_addr_fifo_rd_rst  =  ~SLAVE_RSTN_SYNC;
assign wr_addr_fifo_rd_en   = (~wr_addr_fifo_rd_empty) && ((async_wr_addr_fifo_data_dont_care) || (AXI_S.WR_ADDR_VALID && AXI_S.WR_ADDR_READY));
assign {AXI_S.WR_ADDR_ID, AXI_S.WR_ADDR, AXI_S.WR_ADDR_LEN, AXI_S.WR_ADDR_BURST} = wr_addr_fifo_rd_data;
assign AXI_S.WR_ADDR_VALID  = (SLAVE_RSTN_SYNC) && (~async_wr_addr_fifo_data_dont_care);

//写地址通道和读地址通道是完全一样的接口设计，都用async_addr_fifo模块就可以
slave_async_addr_fifo slave_async_wr_addr_fifo_inst(
    .wr_clk  (B_CLK             ), 
    .wr_rst  (wr_addr_fifo_wr_rst ), 
    .wr_en   (wr_addr_fifo_wr_en  ), 
    .wr_data (wr_addr_fifo_wr_data), 
    .wr_full (wr_addr_fifo_wr_full), 
    
    .rd_clk  (AXI_S.CLK            ),
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
always @(posedge AXI_S.CLK or negedge SLAVE_RSTN_SYNC) begin
    if(~SLAVE_RSTN_SYNC) async_rd_addr_fifo_data_dont_care <= 1;
    else if(rd_addr_fifo_rd_empty && (AXI_S.RD_ADDR_VALID && AXI_S.RD_ADDR_READY)) async_rd_addr_fifo_data_dont_care <= 1;
    else if(rd_addr_fifo_rd_en && async_rd_addr_fifo_data_dont_care) async_rd_addr_fifo_data_dont_care <= 0;
    else async_rd_addr_fifo_data_dont_care <= async_rd_addr_fifo_data_dont_care;
end

assign rd_addr_fifo_wr_rst  =  ~BUS_RSTN_SYNC;
assign rd_addr_fifo_wr_en   = (AXI_B.RD_ADDR_VALID && AXI_B.RD_ADDR_READY);
assign rd_addr_fifo_wr_data = {AXI_B.RD_ADDR_ID, AXI_B.RD_ADDR, AXI_B.RD_ADDR_LEN, AXI_B.RD_ADDR_BURST};
assign AXI_B.RD_ADDR_READY    = (BUS_RSTN_SYNC) && (~rd_addr_fifo_wr_full);

assign rd_addr_fifo_rd_rst  =  ~SLAVE_RSTN_SYNC;
assign rd_addr_fifo_rd_en   = (~rd_addr_fifo_rd_empty) && ((async_rd_addr_fifo_data_dont_care) || (AXI_S.RD_ADDR_VALID && AXI_S.RD_ADDR_READY));
assign {AXI_S.RD_ADDR_ID, AXI_S.RD_ADDR, AXI_S.RD_ADDR_LEN, AXI_S.RD_ADDR_BURST} = rd_addr_fifo_rd_data;
assign AXI_S.RD_ADDR_VALID  = (SLAVE_RSTN_SYNC) && (~async_rd_addr_fifo_data_dont_care);

//fifo写由BUS的写地址通道控制，fifo读由SLAVE的读地址通道控制
slave_async_addr_fifo slave_async_rd_addr_fifo_inst(
    .wr_clk  (B_CLK             ), 
    .wr_rst  (rd_addr_fifo_wr_rst ), 
    .wr_en   (rd_addr_fifo_wr_en  ), 
    .wr_data (rd_addr_fifo_wr_data), 
    .wr_full (rd_addr_fifo_wr_full), 
    
    .rd_clk  (AXI_S.CLK            ),
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
always @(posedge AXI_S.CLK or negedge SLAVE_RSTN_SYNC) begin
    if(~SLAVE_RSTN_SYNC) async_wr_data_fifo_data_dont_care <= 1;
    else if(wr_data_fifo_rd_empty && (AXI_S.WR_DATA_VALID && AXI_S.WR_DATA_READY)) async_wr_data_fifo_data_dont_care <= 1;
    else if(wr_data_fifo_rd_en && async_wr_data_fifo_data_dont_care) async_wr_data_fifo_data_dont_care <= 0;
    else async_wr_data_fifo_data_dont_care <= async_wr_data_fifo_data_dont_care;
end

assign wr_data_fifo_wr_rst  =  ~BUS_RSTN_SYNC;
assign wr_data_fifo_wr_en   = (AXI_B.WR_DATA_VALID && AXI_B.WR_DATA_READY);
assign wr_data_fifo_wr_data = {AXI_B.WR_DATA, AXI_B.WR_STRB, AXI_B.WR_DATA_LAST};
assign AXI_B.WR_DATA_READY    = (BUS_RSTN_SYNC) && ~wr_data_fifo_wr_full;

assign wr_data_fifo_rd_rst  =  ~SLAVE_RSTN_SYNC;
assign wr_data_fifo_rd_en   = (~wr_data_fifo_rd_empty) && ((async_wr_data_fifo_data_dont_care) || (AXI_S.WR_DATA_VALID && AXI_S.WR_DATA_READY));
assign {AXI_S.WR_DATA, AXI_S.WR_STRB, AXI_S.WR_DATA_LAST} = wr_data_fifo_rd_data & ({(32+4+1){AXI_S.WR_DATA_VALID}});
assign AXI_S.WR_DATA_VALID  = (SLAVE_RSTN_SYNC) && (~async_wr_data_fifo_data_dont_care);

slave_async_wr_data_fifo slave_async_wr_data_fifo_inst(
    .wr_clk  (B_CLK             ), 
    .wr_rst  (wr_data_fifo_wr_rst ), 
    .wr_en   (wr_data_fifo_wr_en  ), 
    .wr_data (wr_data_fifo_wr_data), 
    .wr_full (wr_data_fifo_wr_full), 
    
    .rd_clk  (AXI_S.CLK            ),
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
always @(posedge B_CLK or negedge BUS_RSTN_SYNC) begin
    if(~BUS_RSTN_SYNC) async_rd_data_fifo_data_dont_care <= 1;
    else if(rd_data_fifo_rd_empty && (AXI_B.RD_DATA_VALID && AXI_B.RD_DATA_READY)) async_rd_data_fifo_data_dont_care <= 1;
    else if(rd_data_fifo_rd_en && async_rd_data_fifo_data_dont_care) async_rd_data_fifo_data_dont_care <= 0;
    else async_rd_data_fifo_data_dont_care <= async_rd_data_fifo_data_dont_care;
end

assign rd_data_fifo_wr_rst  =  ~SLAVE_RSTN_SYNC;
assign rd_data_fifo_wr_en   = (AXI_S.RD_DATA_VALID && AXI_S.RD_DATA_READY);
assign rd_data_fifo_wr_data = {AXI_S.RD_BACK_ID, AXI_S.RD_DATA, AXI_S.RD_DATA_RESP, AXI_S.RD_DATA_LAST};
assign AXI_S.RD_DATA_READY  = (SLAVE_RSTN_SYNC) && ~rd_data_fifo_wr_full;

assign rd_data_fifo_rd_rst  =  ~BUS_RSTN_SYNC;
assign rd_data_fifo_rd_en   = (~rd_data_fifo_rd_empty) && ((async_rd_data_fifo_data_dont_care) || (AXI_B.RD_DATA_VALID && AXI_B.RD_DATA_READY));
assign {AXI_B.RD_BACK_ID, AXI_B.RD_DATA, AXI_B.RD_DATA_RESP, AXI_B.RD_DATA_LAST} = rd_data_fifo_rd_data & ({(4+32+2+1){AXI_B.RD_DATA_VALID}});
assign AXI_B.RD_DATA_VALID    = (BUS_RSTN_SYNC) && (~async_rd_data_fifo_data_dont_care);

//BUS读数据通道<===>fifo写通道<===>fifo读通道<===>SLAVE读数据通道   !!!!这个通道反过来!!!!
//{BACK_ID, DATA, RESP, LAST} WIDTH = 37
slave_async_rd_data_fifo slave_async_rd_data_fifo_inst(
    .wr_clk  (AXI_S.CLK           ), 
    .wr_rst  (rd_data_fifo_wr_rst ), 
    .wr_en   (rd_data_fifo_wr_en  ), 
    .wr_data (rd_data_fifo_wr_data), 
    .wr_full (rd_data_fifo_wr_full), 
    
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
wire                  wr_back_fifo_rd_rst  ;
wire                  wr_back_fifo_rd_en   ;
wire [4+2-1:0]        wr_back_fifo_rd_data ;
wire                  wr_back_fifo_rd_empty;

reg async_wr_back_fifo_data_dont_care;
always @(posedge B_CLK or negedge BUS_RSTN_SYNC) begin
    if(~BUS_RSTN_SYNC) async_wr_back_fifo_data_dont_care <= 1;
    else if(wr_back_fifo_rd_empty && (AXI_B.WR_BACK_VALID && AXI_B.WR_BACK_READY)) async_wr_back_fifo_data_dont_care <= 1;
    else if(wr_back_fifo_rd_en && async_wr_back_fifo_data_dont_care) async_wr_back_fifo_data_dont_care <= 0;
    else async_wr_back_fifo_data_dont_care <= async_wr_back_fifo_data_dont_care;
end

assign wr_back_fifo_wr_rst  =  ~SLAVE_RSTN_SYNC;
assign wr_back_fifo_wr_en   = (AXI_S.WR_BACK_VALID && AXI_S.WR_BACK_READY);
assign wr_back_fifo_wr_data = {AXI_S.WR_BACK_ID, AXI_S.WR_BACK_RESP};
assign AXI_S.WR_BACK_READY  = (SLAVE_RSTN_SYNC) && (~wr_back_fifo_wr_full);

assign wr_back_fifo_rd_rst  =  ~BUS_RSTN_SYNC;
assign wr_back_fifo_rd_en   = (~wr_back_fifo_rd_empty) && ((async_wr_back_fifo_data_dont_care) || (AXI_B.WR_BACK_VALID && AXI_B.WR_BACK_READY));
assign {AXI_B.WR_BACK_ID, AXI_B.WR_BACK_RESP} = wr_back_fifo_rd_data;
assign AXI_B.WR_BACK_VALID    = (BUS_RSTN_SYNC) && (~async_wr_back_fifo_data_dont_care);

slave_async_wr_back_fifo slave_async_wr_back_fifo_inst(
    .wr_clk  (AXI_S.CLK           ), 
    .wr_rst  (wr_back_fifo_wr_rst ), 
    .wr_en   (wr_back_fifo_wr_en  ), 
    .wr_data (wr_back_fifo_wr_data), 
    .wr_full (wr_back_fifo_wr_full), 
    
    .rd_clk  (B_CLK              ),
    .rd_rst  (wr_back_fifo_rd_rst  ),
    .rd_en   (wr_back_fifo_rd_en   ),
    .rd_data (wr_back_fifo_rd_data ),
    .rd_empty(wr_back_fifo_rd_empty) 
);

assign fifo_empty_flag = {wr_addr_fifo_rd_empty, rd_addr_fifo_rd_empty, wr_data_fifo_rd_empty, rd_data_fifo_rd_empty, wr_back_fifo_rd_empty};

endmodule