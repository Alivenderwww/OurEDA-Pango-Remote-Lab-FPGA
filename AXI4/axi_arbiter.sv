module axi_master_arbiter #(
    parameter M_ID = 2,
    parameter M_WIDTH = 2
)(
    input  wire                      clk,
    input  wire                      rstn,
    input  wire  [(2**M_WIDTH-1):0]  MASTER_WR_ADDR_VALID,
    input  wire  [(2**M_WIDTH-1):0]  MASTER_RD_ADDR_VALID,
    input  wire                      BUS_WR_ADDR_VALID,
    input  wire                      BUS_WR_ADDR_READY,
    input  wire                      BUS_WR_DATA_VALID,
    input  wire                      BUS_WR_DATA_READY,
    input  wire                      BUS_WR_DATA_LAST,
    input  wire  [M_ID+M_WIDTH-1:0]  BUS_WR_BACK_ID,
    input  wire                      BUS_RD_ADDR_VALID,
    input  wire                      BUS_RD_ADDR_READY,
    input  wire  [M_ID+M_WIDTH-1:0]  BUS_RD_BACK_ID,
    output logic [M_WIDTH-1:0]       wr_addr_master_sel,
    output logic [M_WIDTH-1:0]       wr_data_master_sel,
    output logic [M_WIDTH-1:0]       wr_resp_master_sel,
    output logic [M_WIDTH-1:0]       rd_addr_master_sel,
    output logic [M_WIDTH-1:0]       rd_data_master_sel
);

reg        wr_channel_lock;
reg        rd_addr_channel_lock;
reg        wr_resp_lock;

logic [M_WIDTH-1:0] cu_wr_master_sel;
logic [M_WIDTH-1:0] cu_rd_addr_master_sel;

/**************************写通道接口（包括写地址，写数据通道）**********************/
localparam WR_IDLE = 1'b0;
localparam WR_DATA = 1'b1;
reg cu_wr_st,nt_wr_st;
always @(*)begin
    case (cu_wr_st)
        WR_IDLE: nt_wr_st <= (BUS_WR_ADDR_VALID && BUS_WR_ADDR_READY)?(WR_DATA):(WR_IDLE);
        WR_DATA: nt_wr_st <= (BUS_WR_DATA_VALID && BUS_WR_DATA_READY && BUS_WR_DATA_LAST)?(WR_IDLE):(WR_DATA);
    endcase
end
always @(posedge clk or negedge rstn)begin
    if(~rstn) cu_wr_st <= WR_IDLE;
    else cu_wr_st <= nt_wr_st;
end
always @(posedge clk or negedge rstn) begin
    if(~rstn) wr_channel_lock <= 0;
    else if((cu_wr_st == WR_DATA) && (BUS_WR_DATA_VALID && BUS_WR_DATA_READY && BUS_WR_DATA_LAST)) wr_channel_lock <= 0; //传输结束，传输通道解锁
    else if((cu_wr_st == WR_IDLE) && BUS_WR_ADDR_VALID) wr_channel_lock <= 1; //握手未成功，传输通道加锁
    else  wr_channel_lock <= wr_channel_lock;
end

logic M_WR_ADDR_VALID[2**M_WIDTH-1:0];
for (genvar i=0;i<(2**M_WIDTH);i++) begin
    assign M_WR_ADDR_VALID[i] = MASTER_WR_ADDR_VALID[i];
end
always_comb begin: wr_addr_master
    int rev_i;
    wr_addr_master_sel = 0;
    if (wr_channel_lock) wr_addr_master_sel = cu_wr_master_sel;
    else for(rev_i=(2**M_WIDTH-1); rev_i>=0; rev_i--) if(M_WR_ADDR_VALID[rev_i])
        wr_addr_master_sel = rev_i[M_WIDTH-1:0];
end
always_comb begin
    wr_data_master_sel = wr_addr_master_sel;
end
always @(posedge clk or negedge rstn) begin
    if(~rstn) cu_wr_master_sel <= 0;
    else cu_wr_master_sel <= wr_addr_master_sel;
end

/**************************写响应接口**********************/
always_comb begin
    wr_resp_master_sel = BUS_WR_BACK_ID[M_ID+:M_WIDTH];
end

/**********************读地址接口 需要lock**********************/
always @(posedge clk or negedge rstn) begin
    if(~rstn) rd_addr_channel_lock <= 0;
    else if((BUS_RD_ADDR_VALID && BUS_RD_ADDR_READY)) rd_addr_channel_lock <= 0; //握手成功，传输通道解锁
    else if(BUS_RD_ADDR_VALID) rd_addr_channel_lock <= 1; //握手未成功，传输通道加锁
    else  rd_addr_channel_lock <= rd_addr_channel_lock;
end

logic M_RD_ADDR_VALID[2**M_WIDTH-1:0];
for (genvar i=0;i<(2**M_WIDTH);i++) begin
    assign M_RD_ADDR_VALID[i] = MASTER_RD_ADDR_VALID[i];
end
always_comb begin: rd_addr_master
    int rev_i;
    rd_addr_master_sel = 0;
    if (rd_addr_channel_lock) rd_addr_master_sel = cu_rd_addr_master_sel;
    else for(rev_i=(2**M_WIDTH-1); rev_i>=0; rev_i--) if(M_RD_ADDR_VALID[rev_i])
        rd_addr_master_sel = rev_i[M_WIDTH-1:0];
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) cu_rd_addr_master_sel <= 2'd0;
    else cu_rd_addr_master_sel <= rd_addr_master_sel;
end
/**********************读数据接口 支持写交织，无需lock**********************/
always @(*) begin
    rd_data_master_sel <= BUS_RD_BACK_ID[M_ID+:M_WIDTH];
end


endmodule //axi_master_arbiter

module axi_slave_arbiter #(
    parameter S_WIDTH = 3,
    parameter [0:(2**S_WIDTH-1)][31:0] START_ADDR= {32'h00000000, 32'h10000000, 32'h20000000, 32'h30000000, 32'h40000000, 32'h50000000, 32'h60000000, 32'h70000000},
    parameter [0:(2**S_WIDTH-1)][31:0]   END_ADDR= {32'h0FFFFFFF, 32'h1FFFFFFF, 32'h2FFFFFFF, 32'h3FFFFFFF, 32'h4FFFFFFF, 32'h5FFFFFFF, 32'h6FFFFFFF, 32'h7FFFFFFF}
)(
    input  wire                     clk,
    input  wire                     rstn,
    input  wire  [(2**S_WIDTH-1):0] SLAVE_WR_BACK_VALID,
    input  wire  [(2**S_WIDTH-1):0] SLAVE_RD_DATA_VALID,
    input  wire  [31:0]             BUS_WR_ADDR,
    input  wire                     BUS_WR_BACK_VALID,
    input  wire                     BUS_WR_BACK_READY,
    input  wire  [31:0]             BUS_RD_ADDR,
    output logic [31:0]             TRANS_WR_ADDR,
    output logic [31:0]             TRANS_RD_ADDR,
    output logic [S_WIDTH-1:0]      wr_addr_slave_sel,
    output logic [S_WIDTH-1:0]      wr_data_slave_sel,
    output logic [S_WIDTH-1:0]      wr_resp_slave_sel,
    output logic [S_WIDTH-1:0]      rd_addr_slave_sel,
    output logic [S_WIDTH-1:0]      rd_data_slave_sel
);

reg wr_resp_lock;
logic [S_WIDTH-1:0] cu_wr_resp_slave_sel;

/**************************写通道接口（包括写地址，写数据通道）**********************/
always_comb begin: wr_addr_slave
    int rev_i;
    wr_addr_slave_sel = 0;
    for (rev_i=0; rev_i<(2**S_WIDTH); rev_i++) if ((BUS_WR_ADDR >= START_ADDR[rev_i]) && (BUS_WR_ADDR <= END_ADDR[rev_i]))
        wr_addr_slave_sel = rev_i[S_WIDTH-1:0];
end
always_comb begin
    wr_data_slave_sel = wr_addr_slave_sel;
end

always_comb begin: wr_addr_calculate
    int rev_i;
    TRANS_WR_ADDR = 0;
    for(rev_i=0; rev_i<(2**S_WIDTH); rev_i++) if((BUS_WR_ADDR >= START_ADDR[rev_i]) && (BUS_WR_ADDR <= END_ADDR[rev_i]))
        TRANS_WR_ADDR = BUS_RD_ADDR - START_ADDR[rev_i];
end

/**************************写响应接口**********************/
always @(posedge clk or negedge rstn) begin
    if(~rstn) wr_resp_lock <= 0;
    else if(BUS_WR_BACK_VALID && BUS_WR_BACK_READY) wr_resp_lock <= 0; //传输结束，传输通道解锁
    else if(BUS_WR_BACK_VALID) wr_resp_lock <= 1; //握手未成功，传输通道加锁
    else  wr_resp_lock <= wr_resp_lock;
end
logic S_WR_BACK_VALID[2**S_WIDTH-1:0];
for (genvar i=0;i<(2**S_WIDTH);i++) begin
    assign S_WR_BACK_VALID[i] = SLAVE_WR_BACK_VALID[i];
end
always_comb begin: wr_resp_slave
    int rev_i;
    wr_resp_slave_sel = 0;
    if (wr_resp_lock) wr_resp_slave_sel = cu_wr_resp_slave_sel;
    else for(rev_i=(2**S_WIDTH-1); rev_i>=0; rev_i--) if(S_WR_BACK_VALID[rev_i])
        wr_resp_slave_sel = rev_i[S_WIDTH-1:0];
end
always @(posedge clk or negedge rstn) begin
    if(~rstn) cu_wr_resp_slave_sel <= 0;
    else cu_wr_resp_slave_sel <= wr_resp_slave_sel;
end

/**********************读地址接口 需要lock**********************/
always_comb begin: rd_addr_slave
    int rev_i;
    rd_addr_slave_sel = 0;
    for (rev_i=(2**S_WIDTH-1); rev_i>=0; rev_i--) if ((BUS_RD_ADDR >= START_ADDR[rev_i]) && (BUS_RD_ADDR <= END_ADDR[rev_i]))
        rd_addr_slave_sel = rev_i[S_WIDTH-1:0];
end
/**********************读数据接口 支持写交织，无需lock**********************/
logic S_RD_DATA_VALID[2**S_WIDTH-1:0];
for (genvar i=0;i<(2**S_WIDTH);i++) begin
    assign S_RD_DATA_VALID[i] = SLAVE_RD_DATA_VALID[i];
end
always_comb begin: rd_data_slave
    int rev_i;
    rd_data_slave_sel = 0;
    for(rev_i=(2**S_WIDTH-1); rev_i>=0; rev_i--) if(S_RD_DATA_VALID[rev_i])
        rd_data_slave_sel = rev_i[S_WIDTH-1:0];
end

always_comb begin: rd_addr_calculate
    int rev_i;
    TRANS_RD_ADDR = 0;
    for(rev_i=(2**S_WIDTH-1); rev_i>=0; rev_i--) if((BUS_RD_ADDR >= START_ADDR[rev_i]) && (BUS_RD_ADDR <= END_ADDR[rev_i]))
        TRANS_RD_ADDR = BUS_RD_ADDR - START_ADDR[rev_i];
end

endmodule //axi_slave_arbiter