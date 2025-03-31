module axi_interconnect #(
    parameter S0_START_ADDR = 32'h00_00_00_00,
    parameter S0_END_ADDR   = 32'h0F_FF_FF_FF,
    parameter S1_START_ADDR = 32'h10_00_00_00,
    parameter S1_END_ADDR   = 32'h1F_FF_FF_0F,
    parameter S2_START_ADDR = 32'h20_00_00_00,
    parameter S2_END_ADDR   = 32'h2F_FF_FF_0F,
    parameter S3_START_ADDR = 32'h30_00_00_00,
    parameter S3_END_ADDR   = 32'h3F_FF_FF_0F
)(
    input wire BUS_CLK,
    input wire BUS_RSTN,

    input  wire [ 1:0] M0_WR_ADDR_ID   ,    input  wire [ 1:0] M1_WR_ADDR_ID   ,    input  wire [ 1:0] M2_WR_ADDR_ID   ,    input  wire [ 1:0] M3_WR_ADDR_ID   ,
    input  wire [31:0] M0_WR_ADDR      ,    input  wire [31:0] M1_WR_ADDR      ,    input  wire [31:0] M2_WR_ADDR      ,    input  wire [31:0] M3_WR_ADDR      ,
    input  wire [ 7:0] M0_WR_ADDR_LEN  ,    input  wire [ 7:0] M1_WR_ADDR_LEN  ,    input  wire [ 7:0] M2_WR_ADDR_LEN  ,    input  wire [ 7:0] M3_WR_ADDR_LEN  ,
    input  wire [ 1:0] M0_WR_ADDR_BURST,    input  wire [ 1:0] M1_WR_ADDR_BURST,    input  wire [ 1:0] M2_WR_ADDR_BURST,    input  wire [ 1:0] M3_WR_ADDR_BURST,
    input  wire        M0_WR_ADDR_VALID,    input  wire        M1_WR_ADDR_VALID,    input  wire        M2_WR_ADDR_VALID,    input  wire        M3_WR_ADDR_VALID,
    output wire        M0_WR_ADDR_READY,    output wire        M1_WR_ADDR_READY,    output wire        M2_WR_ADDR_READY,    output wire        M3_WR_ADDR_READY,

    input  wire [31:0] M0_WR_DATA      ,    input  wire [31:0] M1_WR_DATA      ,    input  wire [31:0] M2_WR_DATA      ,    input  wire [31:0] M3_WR_DATA      ,
    input  wire [ 3:0] M0_WR_STRB      ,    input  wire [ 3:0] M1_WR_STRB      ,    input  wire [ 3:0] M2_WR_STRB      ,    input  wire [ 3:0] M3_WR_STRB      ,
    input  wire        M0_WR_DATA_LAST ,    input  wire        M1_WR_DATA_LAST ,    input  wire        M2_WR_DATA_LAST ,    input  wire        M3_WR_DATA_LAST ,
    input  wire        M0_WR_DATA_VALID,    input  wire        M1_WR_DATA_VALID,    input  wire        M2_WR_DATA_VALID,    input  wire        M3_WR_DATA_VALID,
    output wire        M0_WR_DATA_READY,    output wire        M1_WR_DATA_READY,    output wire        M2_WR_DATA_READY,    output wire        M3_WR_DATA_READY,

    output wire [ 1:0] M0_WR_BACK_ID   ,    output wire [ 1:0] M1_WR_BACK_ID   ,    output wire [ 1:0] M2_WR_BACK_ID   ,    output wire [ 1:0] M3_WR_BACK_ID   ,
    output wire [ 1:0] M0_WR_BACK_RESP ,    output wire [ 1:0] M1_WR_BACK_RESP ,    output wire [ 1:0] M2_WR_BACK_RESP ,    output wire [ 1:0] M3_WR_BACK_RESP ,
    output wire        M0_WR_BACK_VALID,    output wire        M1_WR_BACK_VALID,    output wire        M2_WR_BACK_VALID,    output wire        M3_WR_BACK_VALID,
    input  wire        M0_WR_BACK_READY,    input  wire        M1_WR_BACK_READY,    input  wire        M2_WR_BACK_READY,    input  wire        M3_WR_BACK_READY,

    input  wire [ 1:0] M0_RD_ADDR_ID   ,    input  wire [ 1:0] M1_RD_ADDR_ID   ,    input  wire [ 1:0] M2_RD_ADDR_ID   ,    input  wire [ 1:0] M3_RD_ADDR_ID   ,
    input  wire [31:0] M0_RD_ADDR      ,    input  wire [31:0] M1_RD_ADDR      ,    input  wire [31:0] M2_RD_ADDR      ,    input  wire [31:0] M3_RD_ADDR      ,
    input  wire [ 7:0] M0_RD_ADDR_LEN  ,    input  wire [ 7:0] M1_RD_ADDR_LEN  ,    input  wire [ 7:0] M2_RD_ADDR_LEN  ,    input  wire [ 7:0] M3_RD_ADDR_LEN  ,
    input  wire [ 1:0] M0_RD_ADDR_BURST,    input  wire [ 1:0] M1_RD_ADDR_BURST,    input  wire [ 1:0] M2_RD_ADDR_BURST,    input  wire [ 1:0] M3_RD_ADDR_BURST,
    input  wire        M0_RD_ADDR_VALID,    input  wire        M1_RD_ADDR_VALID,    input  wire        M2_RD_ADDR_VALID,    input  wire        M3_RD_ADDR_VALID,
    output wire        M0_RD_ADDR_READY,    output wire        M1_RD_ADDR_READY,    output wire        M2_RD_ADDR_READY,    output wire        M3_RD_ADDR_READY,

    output wire [ 1:0] M0_RD_BACK_ID   ,    output wire [ 1:0] M1_RD_BACK_ID   ,    output wire [ 1:0] M2_RD_BACK_ID   ,    output wire [ 1:0] M3_RD_BACK_ID   ,
    output wire [31:0] M0_RD_DATA      ,    output wire [31:0] M1_RD_DATA      ,    output wire [31:0] M2_RD_DATA      ,    output wire [31:0] M3_RD_DATA      ,
    output wire [ 1:0] M0_RD_DATA_RESP ,    output wire [ 1:0] M1_RD_DATA_RESP ,    output wire [ 1:0] M2_RD_DATA_RESP ,    output wire [ 1:0] M3_RD_DATA_RESP ,
    output wire        M0_RD_DATA_LAST ,    output wire        M1_RD_DATA_LAST ,    output wire        M2_RD_DATA_LAST ,    output wire        M3_RD_DATA_LAST ,
    output wire        M0_RD_DATA_VALID,    output wire        M1_RD_DATA_VALID,    output wire        M2_RD_DATA_VALID,    output wire        M3_RD_DATA_VALID,
    input  wire        M0_RD_DATA_READY,    input  wire        M1_RD_DATA_READY,    input  wire        M2_RD_DATA_READY,    input  wire        M3_RD_DATA_READY,

    output wire [ 3:0] S0_WR_ADDR_ID   ,    output wire [ 3:0] S1_WR_ADDR_ID   ,    output wire [ 3:0] S2_WR_ADDR_ID   ,    output wire [ 3:0] S3_WR_ADDR_ID   ,
    output wire [31:0] S0_WR_ADDR      ,    output wire [31:0] S1_WR_ADDR      ,    output wire [31:0] S2_WR_ADDR      ,    output wire [31:0] S3_WR_ADDR      ,
    output wire [ 7:0] S0_WR_ADDR_LEN  ,    output wire [ 7:0] S1_WR_ADDR_LEN  ,    output wire [ 7:0] S2_WR_ADDR_LEN  ,    output wire [ 7:0] S3_WR_ADDR_LEN  ,
    output wire [ 1:0] S0_WR_ADDR_BURST,    output wire [ 1:0] S1_WR_ADDR_BURST,    output wire [ 1:0] S2_WR_ADDR_BURST,    output wire [ 1:0] S3_WR_ADDR_BURST,
    output wire        S0_WR_ADDR_VALID,    output wire        S1_WR_ADDR_VALID,    output wire        S2_WR_ADDR_VALID,    output wire        S3_WR_ADDR_VALID,
    input  wire        S0_WR_ADDR_READY,    input  wire        S1_WR_ADDR_READY,    input  wire        S2_WR_ADDR_READY,    input  wire        S3_WR_ADDR_READY,

    output wire [31:0] S0_WR_DATA      ,    output wire [31:0] S1_WR_DATA      ,    output wire [31:0] S2_WR_DATA      ,    output wire [31:0] S3_WR_DATA      ,
    output wire [ 3:0] S0_WR_STRB      ,    output wire [ 3:0] S1_WR_STRB      ,    output wire [ 3:0] S2_WR_STRB      ,    output wire [ 3:0] S3_WR_STRB      ,
    output wire        S0_WR_DATA_LAST ,    output wire        S1_WR_DATA_LAST ,    output wire        S2_WR_DATA_LAST ,    output wire        S3_WR_DATA_LAST ,
    output wire        S0_WR_DATA_VALID,    output wire        S1_WR_DATA_VALID,    output wire        S2_WR_DATA_VALID,    output wire        S3_WR_DATA_VALID,
    input  wire        S0_WR_DATA_READY,    input  wire        S1_WR_DATA_READY,    input  wire        S2_WR_DATA_READY,    input  wire        S3_WR_DATA_READY,

    input  wire [ 3:0] S0_WR_BACK_ID   ,    input  wire [ 3:0] S1_WR_BACK_ID   ,    input  wire [ 3:0] S2_WR_BACK_ID   ,    input  wire [ 3:0] S3_WR_BACK_ID   ,
    input  wire [ 1:0] S0_WR_BACK_RESP ,    input  wire [ 1:0] S1_WR_BACK_RESP ,    input  wire [ 1:0] S2_WR_BACK_RESP ,    input  wire [ 1:0] S3_WR_BACK_RESP ,
    input  wire        S0_WR_BACK_VALID,    input  wire        S1_WR_BACK_VALID,    input  wire        S2_WR_BACK_VALID,    input  wire        S3_WR_BACK_VALID,
    output wire        S0_WR_BACK_READY,    output wire        S1_WR_BACK_READY,    output wire        S2_WR_BACK_READY,    output wire        S3_WR_BACK_READY,

    output wire [ 3:0] S0_RD_ADDR_ID   ,    output wire [ 3:0] S1_RD_ADDR_ID   ,    output wire [ 3:0] S2_RD_ADDR_ID   ,    output wire [ 3:0] S3_RD_ADDR_ID   ,
    output wire [31:0] S0_RD_ADDR      ,    output wire [31:0] S1_RD_ADDR      ,    output wire [31:0] S2_RD_ADDR      ,    output wire [31:0] S3_RD_ADDR      ,
    output wire [ 7:0] S0_RD_ADDR_LEN  ,    output wire [ 7:0] S1_RD_ADDR_LEN  ,    output wire [ 7:0] S2_RD_ADDR_LEN  ,    output wire [ 7:0] S3_RD_ADDR_LEN  ,
    output wire [ 1:0] S0_RD_ADDR_BURST,    output wire [ 1:0] S1_RD_ADDR_BURST,    output wire [ 1:0] S2_RD_ADDR_BURST,    output wire [ 1:0] S3_RD_ADDR_BURST,
    output wire        S0_RD_ADDR_VALID,    output wire        S1_RD_ADDR_VALID,    output wire        S2_RD_ADDR_VALID,    output wire        S3_RD_ADDR_VALID,
    input  wire        S0_RD_ADDR_READY,    input  wire        S1_RD_ADDR_READY,    input  wire        S2_RD_ADDR_READY,    input  wire        S3_RD_ADDR_READY,

    input  wire [ 3:0] S0_RD_BACK_ID   ,    input  wire [ 3:0] S1_RD_BACK_ID   ,    input  wire [ 3:0] S2_RD_BACK_ID   ,    input  wire [ 3:0] S3_RD_BACK_ID   ,
    input  wire [31:0] S0_RD_DATA      ,    input  wire [31:0] S1_RD_DATA      ,    input  wire [31:0] S2_RD_DATA      ,    input  wire [31:0] S3_RD_DATA      ,
    input  wire [ 1:0] S0_RD_DATA_RESP ,    input  wire [ 1:0] S1_RD_DATA_RESP ,    input  wire [ 1:0] S2_RD_DATA_RESP ,    input  wire [ 1:0] S3_RD_DATA_RESP ,
    input  wire        S0_RD_DATA_LAST ,    input  wire        S1_RD_DATA_LAST ,    input  wire        S2_RD_DATA_LAST ,    input  wire        S3_RD_DATA_LAST ,
    input  wire        S0_RD_DATA_VALID,    input  wire        S1_RD_DATA_VALID,    input  wire        S2_RD_DATA_VALID,    input  wire        S3_RD_DATA_VALID,
    output wire        S0_RD_DATA_READY,    output wire        S1_RD_DATA_READY,    output wire        S2_RD_DATA_READY,    output wire        S3_RD_DATA_READY
);
wire BUS_RSTN_SYNC;
rstn_sync rstn_sync_bus (BUS_CLK, BUS_RSTN, BUS_RSTN_SYNC);

wire [ 1:0] BUS_WR_ADDR_ID   ;
wire [31:0] BUS_WR_ADDR      ;
wire [ 7:0] BUS_WR_ADDR_LEN  ;
wire [ 1:0] BUS_WR_ADDR_BURST;
wire        BUS_WR_ADDR_VALID;
wire        BUS_WR_ADDR_READY;
wire [31:0] BUS_WR_DATA      ;
wire [ 3:0] BUS_WR_STRB      ;
wire        BUS_WR_DATA_LAST ;
wire        BUS_WR_DATA_VALID;
wire        BUS_WR_DATA_READY;
wire [ 3:0] BUS_WR_BACK_ID   ;
wire [ 1:0] BUS_WR_BACK_RESP ;
wire        BUS_WR_BACK_VALID;
wire        BUS_WR_BACK_READY;
wire [ 1:0] BUS_RD_ADDR_ID   ;
wire [31:0] BUS_RD_ADDR      ;
wire [ 7:0] BUS_RD_ADDR_LEN  ;
wire [ 1:0] BUS_RD_ADDR_BURST;
wire        BUS_RD_ADDR_VALID;
wire        BUS_RD_ADDR_READY;
wire [ 3:0] BUS_RD_BACK_ID   ;
wire [31:0] BUS_RD_DATA      ;
wire [ 1:0] BUS_RD_DATA_RESP ;
wire        BUS_RD_DATA_LAST ;
wire        BUS_RD_DATA_VALID;
wire        BUS_RD_DATA_READY;

reg        wr_channel_lock;
reg        rd_addr_channel_lock;
reg        wr_resp_lock;

reg [ 1:0] cu_master_wr_channel_id, nt_master_wr_channel_id;
reg [ 1:0] cu_master_rd_addr_channel_id, nt_master_rd_addr_channel_id;
reg [ 1:0] master_rd_data_channel_id;
reg [ 1:0] master_wr_resp_id;

reg [ 1:0] slave_wr_channel_sel;
reg [ 1:0] slave_rd_addr_channel_sel;
reg [ 1:0] slave_rd_data_channel_sel;
reg [ 1:0] cu_slave_wr_resp_sel, nt_slave_wr_resp_sel;

/**************************写通道接口（包括写地址，写数据通道）**********************/
reg cu_wr_st, nt_wr_st;
localparam ST_WR_IDLE = 0,
           ST_WR_DATA = 1;
always @(*)begin
    case (cu_wr_st)
        ST_WR_IDLE: nt_wr_st <= (BUS_WR_ADDR_VALID && BUS_WR_ADDR_READY)?(ST_WR_DATA):(ST_WR_IDLE);
        ST_WR_DATA: nt_wr_st <= (BUS_WR_DATA_VALID && BUS_WR_DATA_READY && BUS_WR_DATA_LAST)?(ST_WR_IDLE):(ST_WR_DATA);
    endcase
end
always @(posedge BUS_CLK or negedge BUS_RSTN_SYNC)begin
    if(~BUS_RSTN_SYNC) cu_wr_st <= ST_WR_IDLE;
    else cu_wr_st <= nt_wr_st;
end

always @(posedge BUS_CLK or negedge BUS_RSTN_SYNC) begin
    if(~BUS_RSTN_SYNC) wr_channel_lock <= 0;
    else if((cu_wr_st == ST_WR_DATA) && (BUS_WR_DATA_VALID && BUS_WR_DATA_READY && BUS_WR_DATA_LAST)) wr_channel_lock <= 0; //传输结束，传输通道解锁
    else if((cu_wr_st == ST_WR_IDLE) && BUS_WR_ADDR_VALID) wr_channel_lock <= 1; //握手未成功，传输通道加锁
    else  wr_channel_lock <= wr_channel_lock;
end
always @(*) begin
    if(~wr_channel_lock)begin
             if(M0_WR_ADDR_VALID) nt_master_wr_channel_id <= 2'd0;
        else if(M1_WR_ADDR_VALID) nt_master_wr_channel_id <= 2'd1;
        else if(M2_WR_ADDR_VALID) nt_master_wr_channel_id <= 2'd2;
        else if(M3_WR_ADDR_VALID) nt_master_wr_channel_id <= 2'd3;
        else                      nt_master_wr_channel_id <= 2'd0;
    end else                      nt_master_wr_channel_id <= cu_master_wr_channel_id;
end
always @(posedge BUS_CLK or negedge BUS_RSTN_SYNC) begin
    if(~BUS_RSTN_SYNC) cu_master_wr_channel_id <= 2'd0;
    else cu_master_wr_channel_id <= nt_master_wr_channel_id;
end
always @(*) begin
         if(BUS_WR_ADDR >= S0_START_ADDR && BUS_WR_ADDR <= S0_END_ADDR) slave_wr_channel_sel <= 2'd0;
    else if(BUS_WR_ADDR >= S1_START_ADDR && BUS_WR_ADDR <= S1_END_ADDR) slave_wr_channel_sel <= 2'd1;
    else if(BUS_WR_ADDR >= S2_START_ADDR && BUS_WR_ADDR <= S2_END_ADDR) slave_wr_channel_sel <= 2'd2;
    else if(BUS_WR_ADDR >= S3_START_ADDR && BUS_WR_ADDR <= S3_END_ADDR) slave_wr_channel_sel <= 2'd3;
    else slave_wr_channel_sel <= 2'd0;
end

axi_inter_sel41 #( 2)selM_WR_ADDR_ID   ( nt_master_wr_channel_id, BUS_WR_ADDR_ID   , M0_WR_ADDR_ID   , M1_WR_ADDR_ID   , M2_WR_ADDR_ID   , M3_WR_ADDR_ID   );
axi_inter_nosel #( 4)selS_WR_ADDR_ID   ({nt_master_wr_channel_id, BUS_WR_ADDR_ID}  , S0_WR_ADDR_ID   , S1_WR_ADDR_ID   , S2_WR_ADDR_ID   , S3_WR_ADDR_ID   );
axi_inter_sel41 #(32)selM_WR_ADDR      ( nt_master_wr_channel_id, BUS_WR_ADDR      , M0_WR_ADDR      , M1_WR_ADDR      , M2_WR_ADDR      , M3_WR_ADDR      );
axi_inter_nosel #(32)selS_WR_ADDR      (                          BUS_WR_ADDR      , S0_WR_ADDR      , S1_WR_ADDR      , S2_WR_ADDR      , S3_WR_ADDR      );
axi_inter_sel41 #( 8)selM_WR_ADDR_LEN  ( nt_master_wr_channel_id, BUS_WR_ADDR_LEN  , M0_WR_ADDR_LEN  , M1_WR_ADDR_LEN  , M2_WR_ADDR_LEN  , M3_WR_ADDR_LEN  );
axi_inter_nosel #( 8)selS_WR_ADDR_LEN  (                          BUS_WR_ADDR_LEN  , S0_WR_ADDR_LEN  , S1_WR_ADDR_LEN  , S2_WR_ADDR_LEN  , S3_WR_ADDR_LEN  );
axi_inter_sel41 #( 2)selM_WR_ADDR_BURST( nt_master_wr_channel_id, BUS_WR_ADDR_BURST, M0_WR_ADDR_BURST, M1_WR_ADDR_BURST, M2_WR_ADDR_BURST, M3_WR_ADDR_BURST);
axi_inter_nosel #( 2)selS_WR_ADDR_BURST(                          BUS_WR_ADDR_BURST, S0_WR_ADDR_BURST, S1_WR_ADDR_BURST, S2_WR_ADDR_BURST, S3_WR_ADDR_BURST);
axi_inter_sel41 #( 1)selM_WR_ADDR_VALID( nt_master_wr_channel_id, BUS_WR_ADDR_VALID, M0_WR_ADDR_VALID, M1_WR_ADDR_VALID, M2_WR_ADDR_VALID, M3_WR_ADDR_VALID);
axi_inter_sel14 #( 1)selS_WR_ADDR_VALID(    slave_wr_channel_sel, (BUS_WR_ADDR_VALID & (cu_wr_st == ST_WR_IDLE)), S0_WR_ADDR_VALID, S1_WR_ADDR_VALID, S2_WR_ADDR_VALID, S3_WR_ADDR_VALID);
axi_inter_sel41 #( 1)selS_WR_ADDR_READY(    slave_wr_channel_sel, BUS_WR_ADDR_READY, S0_WR_ADDR_READY, S1_WR_ADDR_READY, S2_WR_ADDR_READY, S3_WR_ADDR_READY);
axi_inter_sel14 #( 1)selM_WR_ADDR_READY( nt_master_wr_channel_id, (BUS_WR_ADDR_READY & (cu_wr_st == ST_WR_IDLE)), M0_WR_ADDR_READY, M1_WR_ADDR_READY, M2_WR_ADDR_READY, M3_WR_ADDR_READY);

axi_inter_sel41 #(32)selM_WR_DATA      (nt_master_wr_channel_id, BUS_WR_DATA        , M0_WR_DATA      , M1_WR_DATA      , M2_WR_DATA      , M3_WR_DATA      );
axi_inter_nosel #(32)selS_WR_DATA      (                         BUS_WR_DATA        , S0_WR_DATA      , S1_WR_DATA      , S2_WR_DATA      , S3_WR_DATA      );
axi_inter_sel41 #( 4)selM_WR_STRB      (nt_master_wr_channel_id, BUS_WR_STRB        , M0_WR_STRB      , M1_WR_STRB      , M2_WR_STRB      , M3_WR_STRB      );
axi_inter_nosel #( 4)selS_WR_STRB      (                         BUS_WR_STRB        , S0_WR_STRB      , S1_WR_STRB      , S2_WR_STRB      , S3_WR_STRB      );
axi_inter_sel41 #( 1)selM_WR_DATA_LAST (nt_master_wr_channel_id, BUS_WR_DATA_LAST   , M0_WR_DATA_LAST , M1_WR_DATA_LAST , M2_WR_DATA_LAST , M3_WR_DATA_LAST );
axi_inter_sel14 #( 1)selS_WR_DATA_LAST (   slave_wr_channel_sel, BUS_WR_DATA_LAST   , S0_WR_DATA_LAST , S1_WR_DATA_LAST , S2_WR_DATA_LAST , S3_WR_DATA_LAST );
axi_inter_sel41 #( 1)selM_WR_DATA_VALID(nt_master_wr_channel_id, BUS_WR_DATA_VALID  , M0_WR_DATA_VALID, M1_WR_DATA_VALID, M2_WR_DATA_VALID, M3_WR_DATA_VALID);
axi_inter_sel14 #( 1)selS_WR_DATA_VALID(   slave_wr_channel_sel, (BUS_WR_DATA_VALID & (cu_wr_st == ST_WR_DATA))  , S0_WR_DATA_VALID, S1_WR_DATA_VALID, S2_WR_DATA_VALID, S3_WR_DATA_VALID);
axi_inter_sel41 #( 1)selS_WR_DATA_READY(   slave_wr_channel_sel, BUS_WR_DATA_READY  , S0_WR_DATA_READY, S1_WR_DATA_READY, S2_WR_DATA_READY, S3_WR_DATA_READY);
axi_inter_sel14 #( 1)selM_WR_DATA_READY(nt_master_wr_channel_id, (BUS_WR_DATA_READY & (cu_wr_st == ST_WR_DATA))  , M0_WR_DATA_READY, M1_WR_DATA_READY, M2_WR_DATA_READY, M3_WR_DATA_READY);

/**********************读地址接口 需要lock**********************/
always @(posedge BUS_CLK or negedge BUS_RSTN_SYNC) begin
    if(~BUS_RSTN_SYNC) rd_addr_channel_lock <= 0;
    else if((BUS_RD_ADDR_VALID && BUS_RD_ADDR_READY)) rd_addr_channel_lock <= 0; //握手成功，传输通道解锁
    else if(BUS_RD_ADDR_VALID) rd_addr_channel_lock <= 1; //握手未成功，传输通道加锁
    else  rd_addr_channel_lock <= rd_addr_channel_lock;
end
always @(*) begin
    if(~rd_addr_channel_lock)begin
             if(M0_RD_ADDR_VALID) nt_master_rd_addr_channel_id <= 2'd0;
        else if(M1_RD_ADDR_VALID) nt_master_rd_addr_channel_id <= 2'd1;
        else if(M2_RD_ADDR_VALID) nt_master_rd_addr_channel_id <= 2'd2;
        else if(M3_RD_ADDR_VALID) nt_master_rd_addr_channel_id <= 2'd3;
        else                      nt_master_rd_addr_channel_id <= 2'd0;
    end else                      nt_master_rd_addr_channel_id <= cu_master_rd_addr_channel_id;
end
always @(posedge BUS_CLK or negedge BUS_RSTN_SYNC) begin
    if(~BUS_RSTN_SYNC) cu_master_rd_addr_channel_id <= 2'd0;
    else cu_master_rd_addr_channel_id <= nt_master_rd_addr_channel_id;
end
always @(*) begin
         if(BUS_RD_ADDR >= S0_START_ADDR && BUS_RD_ADDR <= S0_END_ADDR) slave_rd_addr_channel_sel <= 2'd0;
    else if(BUS_RD_ADDR >= S1_START_ADDR && BUS_RD_ADDR <= S1_END_ADDR) slave_rd_addr_channel_sel <= 2'd1;
    else if(BUS_RD_ADDR >= S2_START_ADDR && BUS_RD_ADDR <= S2_END_ADDR) slave_rd_addr_channel_sel <= 2'd2;
    else if(BUS_RD_ADDR >= S3_START_ADDR && BUS_RD_ADDR <= S3_END_ADDR) slave_rd_addr_channel_sel <= 2'd3;
    else slave_rd_addr_channel_sel <= 2'd0;
end

axi_inter_sel41 #( 2)selM_RD_ADDR_ID   ( nt_master_rd_addr_channel_id, BUS_RD_ADDR_ID   , M0_RD_ADDR_ID   , M1_RD_ADDR_ID   , M2_RD_ADDR_ID   , M3_RD_ADDR_ID   );
axi_inter_nosel #( 4)selS_RD_ADDR_ID   ({nt_master_rd_addr_channel_id, BUS_RD_ADDR_ID}  , S0_RD_ADDR_ID   , S1_RD_ADDR_ID   , S2_RD_ADDR_ID   , S3_RD_ADDR_ID   );
axi_inter_sel41 #(32)selM_RD_ADDR      ( nt_master_rd_addr_channel_id, BUS_RD_ADDR      , M0_RD_ADDR      , M1_RD_ADDR      , M2_RD_ADDR      , M3_RD_ADDR      );
axi_inter_nosel #(32)selS_RD_ADDR      (                               BUS_RD_ADDR      , S0_RD_ADDR      , S1_RD_ADDR      , S2_RD_ADDR      , S3_RD_ADDR      );
axi_inter_sel41 #( 8)selM_RD_ADDR_LEN  ( nt_master_rd_addr_channel_id, BUS_RD_ADDR_LEN  , M0_RD_ADDR_LEN  , M1_RD_ADDR_LEN  , M2_RD_ADDR_LEN  , M3_RD_ADDR_LEN  );
axi_inter_nosel #( 8)selS_RD_ADDR_LEN  (                               BUS_RD_ADDR_LEN  , S0_RD_ADDR_LEN  , S1_RD_ADDR_LEN  , S2_RD_ADDR_LEN  , S3_RD_ADDR_LEN  );
axi_inter_sel41 #( 2)selM_RD_ADDR_BURST( nt_master_rd_addr_channel_id, BUS_RD_ADDR_BURST, M0_RD_ADDR_BURST, M1_RD_ADDR_BURST, M2_RD_ADDR_BURST, M3_RD_ADDR_BURST);
axi_inter_nosel #( 2)selS_RD_ADDR_BURST(                               BUS_RD_ADDR_BURST, S0_RD_ADDR_BURST, S1_RD_ADDR_BURST, S2_RD_ADDR_BURST, S3_RD_ADDR_BURST);
axi_inter_sel41 #( 1)selM_RD_ADDR_VALID( nt_master_rd_addr_channel_id, BUS_RD_ADDR_VALID, M0_RD_ADDR_VALID, M1_RD_ADDR_VALID, M2_RD_ADDR_VALID, M3_RD_ADDR_VALID);
axi_inter_sel14 #( 1)selS_RD_ADDR_VALID(    slave_rd_addr_channel_sel, BUS_RD_ADDR_VALID, S0_RD_ADDR_VALID, S1_RD_ADDR_VALID, S2_RD_ADDR_VALID, S3_RD_ADDR_VALID);
axi_inter_sel41 #( 1)selS_RD_ADDR_READY(    slave_rd_addr_channel_sel, BUS_RD_ADDR_READY, S0_RD_ADDR_READY, S1_RD_ADDR_READY, S2_RD_ADDR_READY, S3_RD_ADDR_READY);
axi_inter_sel14 #( 1)selM_RD_ADDR_READY( nt_master_rd_addr_channel_id, BUS_RD_ADDR_READY, M0_RD_ADDR_READY, M1_RD_ADDR_READY, M2_RD_ADDR_READY, M3_RD_ADDR_READY);

/**********************读数据接口 支持写交织，无需lock**********************/
//有优化空间
always @(*) begin
    master_rd_data_channel_id <= BUS_RD_BACK_ID[3:2];
end
always @(*) begin
         if(S0_RD_DATA_VALID) slave_rd_data_channel_sel <= 2'd0;
    else if(S1_RD_DATA_VALID) slave_rd_data_channel_sel <= 2'd1;
    else if(S2_RD_DATA_VALID) slave_rd_data_channel_sel <= 2'd2;
    else if(S3_RD_DATA_VALID) slave_rd_data_channel_sel <= 2'd3;
    else slave_rd_data_channel_sel <= 2'd0;
end

axi_inter_sel41 #( 4)selS_RD_BACK_ID   (    slave_rd_data_channel_sel, BUS_RD_BACK_ID     , S0_RD_BACK_ID   , S1_RD_BACK_ID   , S2_RD_BACK_ID   , S3_RD_BACK_ID   );
axi_inter_nosel #( 2)selM_RD_BACK_ID   (                               BUS_RD_BACK_ID[1:0], M0_RD_BACK_ID   , M1_RD_BACK_ID   , M2_RD_BACK_ID   , M3_RD_BACK_ID   );
axi_inter_sel41 #(32)selS_RD_DATA      (    slave_rd_data_channel_sel, BUS_RD_DATA        , S0_RD_DATA      , S1_RD_DATA      , S2_RD_DATA      , S3_RD_DATA      );
axi_inter_nosel #(32)selM_RD_DATA      (                               BUS_RD_DATA        , M0_RD_DATA      , M1_RD_DATA      , M2_RD_DATA      , M3_RD_DATA      );
axi_inter_sel41 #( 2)selS_RD_DATA_RESP (    slave_rd_data_channel_sel, BUS_RD_DATA_RESP   , S0_RD_DATA_RESP , S1_RD_DATA_RESP , S2_RD_DATA_RESP , S3_RD_DATA_RESP );
axi_inter_nosel #( 2)selM_RD_DATA_RESP (                               BUS_RD_DATA_RESP   , M0_RD_DATA_RESP , M1_RD_DATA_RESP , M2_RD_DATA_RESP , M3_RD_DATA_RESP );
axi_inter_sel41 #( 1)selS_RD_DATA_LAST (    slave_rd_data_channel_sel, BUS_RD_DATA_LAST   , S0_RD_DATA_LAST , S1_RD_DATA_LAST , S2_RD_DATA_LAST , S3_RD_DATA_LAST );
axi_inter_sel14 #( 1)selM_RD_DATA_LAST (    master_rd_data_channel_id, BUS_RD_DATA_LAST   , M0_RD_DATA_LAST , M1_RD_DATA_LAST , M2_RD_DATA_LAST , M3_RD_DATA_LAST );
axi_inter_sel41 #( 1)selS_RD_DATA_VALID(    slave_rd_data_channel_sel, BUS_RD_DATA_VALID  , S0_RD_DATA_VALID, S1_RD_DATA_VALID, S2_RD_DATA_VALID, S3_RD_DATA_VALID);
axi_inter_sel14 #( 1)selM_RD_DATA_VALID(    master_rd_data_channel_id, BUS_RD_DATA_VALID  , M0_RD_DATA_VALID, M1_RD_DATA_VALID, M2_RD_DATA_VALID, M3_RD_DATA_VALID);
axi_inter_sel41 #( 1)selM_RD_DATA_READY(    master_rd_data_channel_id, BUS_RD_DATA_READY  , M0_RD_DATA_READY, M1_RD_DATA_READY, M2_RD_DATA_READY, M3_RD_DATA_READY);
axi_inter_sel14 #( 1)selS_RD_DATA_READY(    slave_rd_data_channel_sel, BUS_RD_DATA_READY  , S0_RD_DATA_READY, S1_RD_DATA_READY, S2_RD_DATA_READY, S3_RD_DATA_READY);


/**************************写响应接口**********************/
always @(posedge BUS_CLK or negedge BUS_RSTN_SYNC) begin
    if(~BUS_RSTN_SYNC) wr_resp_lock <= 0;
    else if(BUS_WR_BACK_VALID && BUS_WR_BACK_READY) wr_resp_lock <= 0; //传输结束，传输通道解锁
    else if(BUS_WR_BACK_VALID) wr_resp_lock <= 1; //握手未成功，传输通道加锁
    else  wr_resp_lock <= wr_resp_lock;
end
always @(*) begin
    if(~wr_resp_lock)begin
             if(S0_WR_BACK_VALID) nt_slave_wr_resp_sel <= 2'd0;
        else if(S1_WR_BACK_VALID) nt_slave_wr_resp_sel <= 2'd1;
        else if(S2_WR_BACK_VALID) nt_slave_wr_resp_sel <= 2'd2;
        else if(S3_WR_BACK_VALID) nt_slave_wr_resp_sel <= 2'd3;
        else                      nt_slave_wr_resp_sel <= 2'd0;
    end else                      nt_slave_wr_resp_sel <= cu_slave_wr_resp_sel;
end
always @(posedge BUS_CLK or negedge BUS_RSTN_SYNC) begin
    if(~BUS_RSTN_SYNC) cu_slave_wr_resp_sel <= 2'd0;
    else cu_slave_wr_resp_sel <= nt_slave_wr_resp_sel;
end
always @(*) begin
    master_wr_resp_id <= BUS_WR_BACK_ID[3:2];
end

axi_inter_sel41 #( 4)selS_WR_BACK_ID   (nt_slave_wr_resp_sel,     BUS_WR_BACK_ID,    S0_WR_BACK_ID,    S1_WR_BACK_ID,    S2_WR_BACK_ID,    S3_WR_BACK_ID);
axi_inter_nosel #( 2)selM_WR_BACK_ID   (                     BUS_WR_BACK_ID[1:0],    M0_WR_BACK_ID,    M1_WR_BACK_ID,    M2_WR_BACK_ID,    M3_WR_BACK_ID);
axi_inter_sel41 #( 2)selS_WR_BACK_RESP (nt_slave_wr_resp_sel,   BUS_WR_BACK_RESP,  S0_WR_BACK_RESP,  S1_WR_BACK_RESP,  S2_WR_BACK_RESP,  S3_WR_BACK_RESP);
axi_inter_nosel #( 2)selM_WR_BACK_RESP (                        BUS_WR_BACK_RESP,  M0_WR_BACK_RESP,  M1_WR_BACK_RESP,  M2_WR_BACK_RESP,  M3_WR_BACK_RESP);
axi_inter_sel41 #( 1)selS_WR_BACK_VALID(nt_slave_wr_resp_sel,  BUS_WR_BACK_VALID, S0_WR_BACK_VALID, S1_WR_BACK_VALID, S2_WR_BACK_VALID, S3_WR_BACK_VALID);
axi_inter_sel14 #( 1)selM_WR_BACK_VALID(   master_wr_resp_id,  BUS_WR_BACK_VALID, M0_WR_BACK_VALID, M1_WR_BACK_VALID, M2_WR_BACK_VALID, M3_WR_BACK_VALID);
axi_inter_sel41 #( 1)selM_WR_BACK_READY(   master_wr_resp_id,  BUS_WR_BACK_READY, M0_WR_BACK_READY, M1_WR_BACK_READY, M2_WR_BACK_READY, M3_WR_BACK_READY);
axi_inter_sel14 #( 1)selS_WR_BACK_READY(nt_slave_wr_resp_sel,  BUS_WR_BACK_READY, S0_WR_BACK_READY, S1_WR_BACK_READY, S2_WR_BACK_READY, S3_WR_BACK_READY);


endmodule