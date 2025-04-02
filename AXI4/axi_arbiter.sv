module axi_master_arbiter #(
    parameter M_ID = 2,
    parameter M_WIDTH = 2
)(
    input wire                  clk,
    input wire                  rstn,
    AXI_INF.S                   AXI_MASTER[0:(2**M_WIDTH-1)],
    AXI_INF.S                   AXI_BUS,
    output logic [M_WIDTH-1:0]  wr_addr_master_sel,
    output logic [M_WIDTH-1:0]  wr_data_master_sel,
    output logic [M_WIDTH-1:0]  wr_resp_master_sel,
    output logic [M_WIDTH-1:0]  rd_addr_master_sel,
    output logic [M_WIDTH-1:0]  rd_data_master_sel
);

reg        wr_channel_lock;
reg        rd_addr_channel_lock;
reg        wr_resp_lock;

logic [M_WIDTH-1:0] cu_wr_master_sel;
logic [M_WIDTH-1:0] cu_rd_addr_master_sel;

/**************************写通道接口（包括写地址，写数据通道）**********************/
enum {WR_IDLE,WR_DATA} cu_wr_st,nt_wr_st;
always @(*)begin
    case (cu_wr_st)
        WR_IDLE: nt_wr_st <= (AXI_BUS.WR_ADDR_VALID && AXI_BUS.WR_ADDR_READY)?(WR_DATA):(WR_IDLE);
        WR_DATA: nt_wr_st <= (AXI_BUS.WR_DATA_VALID && AXI_BUS.WR_DATA_READY && AXI_BUS.WR_DATA_LAST)?(WR_IDLE):(WR_DATA);
    endcase
end
always @(posedge clk or negedge rstn)begin
    if(~rstn) cu_wr_st <= WR_IDLE;
    else cu_wr_st <= nt_wr_st;
end
always @(posedge clk or negedge rstn) begin
    if(~rstn) wr_channel_lock <= 0;
    else if((cu_wr_st == WR_DATA) && (AXI_BUS.WR_DATA_VALID && AXI_BUS.WR_DATA_READY && AXI_BUS.WR_DATA_LAST)) wr_channel_lock <= 0; //传输结束，传输通道解锁
    else if((cu_wr_st == WR_IDLE) && AXI_BUS.WR_ADDR_VALID) wr_channel_lock <= 1; //握手未成功，传输通道加锁
    else  wr_channel_lock <= wr_channel_lock;
end

logic M_WR_ADDR_VALID[2**M_WIDTH-1:0];
for (genvar i=0;i<(2**M_WIDTH);i++) begin
    assign M_WR_ADDR_VALID[i] = AXI_MASTER[i].WR_ADDR_VALID;
end
always_comb begin
    wr_addr_master_sel = 0;
    if (wr_channel_lock) wr_addr_master_sel = cu_wr_master_sel;
    else for(int i=(2**M_WIDTH-1); i>=0; i--) if(M_WR_ADDR_VALID[i])
        wr_addr_master_sel = i[M_WIDTH-1:0];
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
    wr_resp_master_sel = AXI_BUS.WR_BACK_ID[M_ID+:M_WIDTH];
end

/**********************读地址接口 需要lock**********************/
always @(posedge clk or negedge rstn) begin
    if(~rstn) rd_addr_channel_lock <= 0;
    else if((AXI_BUS.RD_ADDR_VALID && AXI_BUS.RD_ADDR_READY)) rd_addr_channel_lock <= 0; //握手成功，传输通道解锁
    else if(AXI_BUS.RD_ADDR_VALID) rd_addr_channel_lock <= 1; //握手未成功，传输通道加锁
    else  rd_addr_channel_lock <= rd_addr_channel_lock;
end

logic M_RD_ADDR_VALID[2**M_WIDTH-1:0];
for (genvar i=0;i<(2**M_WIDTH);i++) begin
    assign M_RD_ADDR_VALID[i] = AXI_MASTER[i].RD_ADDR_VALID;
end
always_comb begin
    rd_addr_master_sel = 0;
    if (rd_addr_channel_lock) rd_addr_master_sel = cu_rd_addr_master_sel;
    else for(int i=(2**M_WIDTH-1); i>=0; i--) if(M_RD_ADDR_VALID[i])
        rd_addr_master_sel = i[M_WIDTH-1:0];
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) cu_rd_addr_master_sel <= 2'd0;
    else cu_rd_addr_master_sel <= rd_addr_master_sel;
end
/**********************读数据接口 支持写交织，无需lock**********************/
always @(*) begin
    rd_data_master_sel <= AXI_BUS.RD_BACK_ID[M_ID+:M_WIDTH];
end


endmodule //axi_master_arbiter

module axi_slave_arbiter #(
    parameter S_WIDTH = 2,
    parameter [31:0] START_ADDR[0:(2**S_WIDTH-1)] = '{32'h00000000, 32'h10000000, 32'h20000000, 32'h30000000, 32'h40000000, 32'h50000000, 32'h60000000, 32'h70000000},
    parameter [31:0]   END_ADDR[0:(2**S_WIDTH-1)] = '{32'h0FFFFFFF, 32'h1FFFFFFF, 32'h2FFFFFFF, 32'h3FFFFFFF, 32'h4FFFFFFF, 32'h5FFFFFFF, 32'h6FFFFFFF, 32'h7FFFFFFF}
)(
    input wire          clk,
    input wire          rstn,
    AXI_INF.S           AXI_SLAVE[0:(2**S_WIDTH-1)],
    AXI_INF.S           AXI_BUS,
    output logic [S_WIDTH-1:0]  wr_addr_slave_sel,
    output logic [S_WIDTH-1:0]  wr_data_slave_sel,
    output logic [S_WIDTH-1:0]  wr_resp_slave_sel,
    output logic [S_WIDTH-1:0]  rd_addr_slave_sel,
    output logic [S_WIDTH-1:0]  rd_data_slave_sel
);

reg wr_resp_lock;
logic [S_WIDTH-1:0] cu_wr_resp_slave_sel;

/**************************写通道接口（包括写地址，写数据通道）**********************/
always_comb begin
    wr_addr_slave_sel = 0;
    for (int i=0; i<(2**S_WIDTH); i++) if ((AXI_BUS.WR_ADDR >= START_ADDR[i]) && (AXI_BUS.WR_ADDR <= END_ADDR[i]))
        wr_addr_slave_sel = i[S_WIDTH-1:0];
end
always_comb begin
    wr_data_slave_sel = wr_addr_slave_sel;
end

/**************************写响应接口**********************/
always @(posedge clk or negedge rstn) begin
    if(~rstn) wr_resp_lock <= 0;
    else if(AXI_BUS.WR_BACK_VALID && AXI_BUS.WR_BACK_READY) wr_resp_lock <= 0; //传输结束，传输通道解锁
    else if(AXI_BUS.WR_BACK_VALID) wr_resp_lock <= 1; //握手未成功，传输通道加锁
    else  wr_resp_lock <= wr_resp_lock;
end
logic S_WR_BACK_VALID[2**S_WIDTH-1:0];
for (genvar i=0;i<(2**S_WIDTH);i++) begin
    assign S_WR_BACK_VALID[i] = AXI_SLAVE[i].WR_BACK_VALID;
end
always_comb begin
    wr_resp_slave_sel = 0;
    if (wr_resp_lock) wr_resp_slave_sel = cu_wr_resp_slave_sel;
    else for(int i=(2**S_WIDTH-1); i>=0; i--) if(S_WR_BACK_VALID[i])
        wr_resp_slave_sel = i[S_WIDTH-1:0];
end
always @(posedge clk or negedge rstn) begin
    if(~rstn) cu_wr_resp_slave_sel <= 0;
    else cu_wr_resp_slave_sel <= wr_resp_slave_sel;
end

/**********************读地址接口 需要lock**********************/
always_comb begin
    rd_addr_slave_sel = 0;
    for (int i=(2**S_WIDTH-1); i>=0; i--) if ((AXI_BUS.RD_ADDR >= START_ADDR[i]) && (AXI_BUS.RD_ADDR <= END_ADDR[i]))
        rd_addr_slave_sel = i[S_WIDTH-1:0];
end
/**********************读数据接口 支持写交织，无需lock**********************/
logic S_RD_DATA_VALID[2**S_WIDTH-1:0];
for (genvar i=0;i<(2**S_WIDTH);i++) begin
    assign S_RD_DATA_VALID[i] = AXI_SLAVE[i].RD_DATA_VALID;
end
always_comb begin
    rd_data_slave_sel = 0;
    for(int i=(2**S_WIDTH-1); i>=0; i--) if(S_RD_DATA_VALID[i])
        rd_data_slave_sel = i[S_WIDTH-1:0];
end

endmodule //axi_slave_arbiter