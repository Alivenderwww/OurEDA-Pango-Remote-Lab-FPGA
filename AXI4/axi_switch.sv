module axi_master_switch #(
    M_WIDTH = 2,
    M_ID    = 2
)(
    input wire [M_WIDTH-1:0] wr_addr_sel,
    input wire [M_WIDTH-1:0] wr_data_sel,
    input wire [M_WIDTH-1:0] wr_resp_sel,
    input wire [M_WIDTH-1:0] rd_addr_sel,
    input wire [M_WIDTH-1:0] rd_data_sel,
    AXI_INF.S                AXI_MASTER[0:2**M_WIDTH-1],
    AXI_INF.M                AXI_BUS
);

logic  [M_ID-1:0]     M_WR_ADDR_ID   [2**M_WIDTH-1:0];
logic  [31:0]         M_WR_ADDR      [2**M_WIDTH-1:0];
logic  [ 7:0]         M_WR_ADDR_LEN  [2**M_WIDTH-1:0];
logic  [ 1:0]         M_WR_ADDR_BURST[2**M_WIDTH-1:0];
logic                 M_WR_ADDR_VALID[2**M_WIDTH-1:0];
logic  [31:0]         M_WR_DATA      [2**M_WIDTH-1:0];
logic  [ 3:0]         M_WR_STRB      [2**M_WIDTH-1:0];
logic                 M_WR_DATA_LAST [2**M_WIDTH-1:0];
logic                 M_WR_DATA_VALID[2**M_WIDTH-1:0];
logic                 M_WR_BACK_READY[2**M_WIDTH-1:0];
logic  [M_ID-1:0]     M_RD_ADDR_ID   [2**M_WIDTH-1:0];
logic  [31:0]         M_RD_ADDR      [2**M_WIDTH-1:0];
logic  [ 7:0]         M_RD_ADDR_LEN  [2**M_WIDTH-1:0];
logic  [ 1:0]         M_RD_ADDR_BURST[2**M_WIDTH-1:0];
logic                 M_RD_ADDR_VALID[2**M_WIDTH-1:0];
logic                 M_RD_DATA_READY[2**M_WIDTH-1:0];

for (genvar i=0; i<(2**M_WIDTH); i++) begin: AXI_MASTER_OUT
    assign AXI_MASTER[i].WR_ADDR_READY = (wr_addr_sel==i)?(AXI_BUS.WR_ADDR_READY):(0);
    assign AXI_MASTER[i].WR_DATA_READY = (wr_data_sel==i)?(AXI_BUS.WR_DATA_READY):(0);
    assign AXI_MASTER[i].WR_BACK_ID    = (wr_resp_sel==i)?(AXI_BUS.WR_BACK_ID   ):(0);
    assign AXI_MASTER[i].WR_BACK_RESP  = (wr_resp_sel==i)?(AXI_BUS.WR_BACK_RESP ):(0);
    assign AXI_MASTER[i].WR_BACK_VALID = (wr_resp_sel==i)?(AXI_BUS.WR_BACK_VALID):(0);
    assign AXI_MASTER[i].RD_ADDR_READY = (rd_addr_sel==i)?(AXI_BUS.RD_ADDR_READY):(0);
    assign AXI_MASTER[i].RD_BACK_ID    = (rd_data_sel==i)?(AXI_BUS.RD_BACK_ID   ):(0);
    assign AXI_MASTER[i].RD_DATA       = (rd_data_sel==i)?(AXI_BUS.RD_DATA      ):(0);
    assign AXI_MASTER[i].RD_DATA_RESP  = (rd_data_sel==i)?(AXI_BUS.RD_DATA_RESP ):(0);
    assign AXI_MASTER[i].RD_DATA_LAST  = (rd_data_sel==i)?(AXI_BUS.RD_DATA_LAST ):(0);
    assign AXI_MASTER[i].RD_DATA_VALID = (rd_data_sel==i)?(AXI_BUS.RD_DATA_VALID):(0);
end

for (genvar i=0;i<(2**M_WIDTH);i++) begin: AXI_MASTER_IN
    assign M_WR_ADDR_ID   [i] = AXI_MASTER[i].WR_ADDR_ID   ;
    assign M_WR_ADDR      [i] = AXI_MASTER[i].WR_ADDR      ;
    assign M_WR_ADDR_LEN  [i] = AXI_MASTER[i].WR_ADDR_LEN  ;
    assign M_WR_ADDR_BURST[i] = AXI_MASTER[i].WR_ADDR_BURST;
    assign M_WR_ADDR_VALID[i] = AXI_MASTER[i].WR_ADDR_VALID;
    assign M_WR_DATA      [i] = AXI_MASTER[i].WR_DATA      ;
    assign M_WR_STRB      [i] = AXI_MASTER[i].WR_STRB      ;
    assign M_WR_DATA_LAST [i] = AXI_MASTER[i].WR_DATA_LAST ;
    assign M_WR_DATA_VALID[i] = AXI_MASTER[i].WR_DATA_VALID;
    assign M_WR_BACK_READY[i] = AXI_MASTER[i].WR_BACK_READY;
    assign M_RD_ADDR_ID   [i] = AXI_MASTER[i].RD_ADDR_ID   ;
    assign M_RD_ADDR      [i] = AXI_MASTER[i].RD_ADDR      ;
    assign M_RD_ADDR_LEN  [i] = AXI_MASTER[i].RD_ADDR_LEN  ;
    assign M_RD_ADDR_BURST[i] = AXI_MASTER[i].RD_ADDR_BURST;
    assign M_RD_ADDR_VALID[i] = AXI_MASTER[i].RD_ADDR_VALID;
    assign M_RD_DATA_READY[i] = AXI_MASTER[i].RD_DATA_READY;
end

always_comb begin
    AXI_BUS.WR_ADDR_ID    = 0;
    AXI_BUS.WR_ADDR       = 0;
    AXI_BUS.WR_ADDR_LEN   = 0;
    AXI_BUS.WR_ADDR_BURST = 0;
    AXI_BUS.WR_ADDR_VALID = 0;
    AXI_BUS.WR_DATA       = 0;
    AXI_BUS.WR_STRB       = 0;
    AXI_BUS.WR_DATA_LAST  = 0;
    AXI_BUS.WR_DATA_VALID = 0;
    AXI_BUS.WR_BACK_READY = 0;
    AXI_BUS.RD_ADDR_ID    = 0;
    AXI_BUS.RD_ADDR       = 0;
    AXI_BUS.RD_ADDR_LEN   = 0;
    AXI_BUS.RD_ADDR_BURST = 0;
    AXI_BUS.RD_ADDR_VALID = 0;
    AXI_BUS.RD_DATA_READY = 0;
    for(int i=0; i<2**M_WIDTH; i++) begin
        if(wr_addr_sel==i)begin
            AXI_BUS.WR_ADDR_ID    = M_WR_ADDR_ID   [i];
            AXI_BUS.WR_ADDR       = M_WR_ADDR      [i];
            AXI_BUS.WR_ADDR_LEN   = M_WR_ADDR_LEN  [i];
            AXI_BUS.WR_ADDR_BURST = M_WR_ADDR_BURST[i];
            AXI_BUS.WR_ADDR_VALID = M_WR_ADDR_VALID[i];
        end
        if(wr_data_sel==i)begin
            AXI_BUS.WR_DATA       = M_WR_DATA      [i];
            AXI_BUS.WR_STRB       = M_WR_STRB      [i];
            AXI_BUS.WR_DATA_LAST  = M_WR_DATA_LAST [i];
            AXI_BUS.WR_DATA_VALID = M_WR_DATA_VALID[i];
        end
        if(wr_resp_sel==i)begin
            AXI_BUS.WR_BACK_READY = M_WR_BACK_READY[i];
        end
        if(rd_addr_sel==i)begin
            AXI_BUS.RD_ADDR_ID    = M_RD_ADDR_ID   [i];
            AXI_BUS.RD_ADDR       = M_RD_ADDR      [i];
            AXI_BUS.RD_ADDR_LEN   = M_RD_ADDR_LEN  [i];
            AXI_BUS.RD_ADDR_BURST = M_RD_ADDR_BURST[i];
            AXI_BUS.RD_ADDR_VALID = M_RD_ADDR_VALID[i];
        end
        if(rd_data_sel==i)begin
            AXI_BUS.RD_DATA_READY = M_RD_DATA_READY[i];
        end
    end
end

endmodule

module axi_slave_switch #(
    S_WIDTH = 2,
    S_ID    = 4
)(
    input wire [S_WIDTH-1:0] wr_addr_sel,
    input wire [S_WIDTH-1:0] wr_data_sel,
    input wire [S_WIDTH-1:0] wr_resp_sel,
    input wire [S_WIDTH-1:0] rd_addr_sel,
    input wire [S_WIDTH-1:0] rd_data_sel,
    AXI_INF.M                AXI_SLAVE[0:2**S_WIDTH-1],
    AXI_INF.S                AXI_BUS
);

logic            S_WR_ADDR_READY[2**S_WIDTH-1:0];
logic            S_WR_DATA_READY[2**S_WIDTH-1:0];
logic [S_ID-1:0] S_WR_BACK_ID   [2**S_WIDTH-1:0];
logic [ 1:0]     S_WR_BACK_RESP [2**S_WIDTH-1:0];
logic            S_WR_BACK_VALID[2**S_WIDTH-1:0];
logic            S_RD_ADDR_READY[2**S_WIDTH-1:0];
logic [S_ID-1:0] S_RD_BACK_ID   [2**S_WIDTH-1:0];
logic [31:0]     S_RD_DATA      [2**S_WIDTH-1:0];
logic [ 1:0]     S_RD_DATA_RESP [2**S_WIDTH-1:0];
logic            S_RD_DATA_LAST [2**S_WIDTH-1:0];
logic            S_RD_DATA_VALID[2**S_WIDTH-1:0];

for (genvar i=0; i<2**S_WIDTH; i++) begin: AXI_SLAVE_OUT
    assign AXI_SLAVE[i].WR_ADDR_ID    = (wr_addr_sel==i)?(AXI_BUS.WR_ADDR_ID   ):(0);
    assign AXI_SLAVE[i].WR_ADDR       = (wr_addr_sel==i)?(AXI_BUS.WR_ADDR      ):(0);
    assign AXI_SLAVE[i].WR_ADDR_LEN   = (wr_addr_sel==i)?(AXI_BUS.WR_ADDR_LEN  ):(0);
    assign AXI_SLAVE[i].WR_ADDR_BURST = (wr_addr_sel==i)?(AXI_BUS.WR_ADDR_BURST):(0);
    assign AXI_SLAVE[i].WR_ADDR_VALID = (wr_addr_sel==i)?(AXI_BUS.WR_ADDR_VALID):(0);
    assign AXI_SLAVE[i].WR_DATA       = (wr_data_sel==i)?(AXI_BUS.WR_DATA      ):(0);
    assign AXI_SLAVE[i].WR_STRB       = (wr_data_sel==i)?(AXI_BUS.WR_STRB      ):(0);
    assign AXI_SLAVE[i].WR_DATA_LAST  = (wr_data_sel==i)?(AXI_BUS.WR_DATA_LAST ):(0);
    assign AXI_SLAVE[i].WR_DATA_VALID = (wr_data_sel==i)?(AXI_BUS.WR_DATA_VALID):(0);
    assign AXI_SLAVE[i].WR_BACK_READY = (wr_resp_sel==i)?(AXI_BUS.WR_BACK_READY):(0);
    assign AXI_SLAVE[i].RD_ADDR_ID    = (rd_addr_sel==i)?(AXI_BUS.RD_ADDR_ID   ):(0);
    assign AXI_SLAVE[i].RD_ADDR       = (rd_addr_sel==i)?(AXI_BUS.RD_ADDR      ):(0);
    assign AXI_SLAVE[i].RD_ADDR_LEN   = (rd_addr_sel==i)?(AXI_BUS.RD_ADDR_LEN  ):(0);
    assign AXI_SLAVE[i].RD_ADDR_BURST = (rd_addr_sel==i)?(AXI_BUS.RD_ADDR_BURST):(0);
    assign AXI_SLAVE[i].RD_ADDR_VALID = (rd_addr_sel==i)?(AXI_BUS.RD_ADDR_VALID):(0);
    assign AXI_SLAVE[i].RD_DATA_READY = (rd_data_sel==i)?(AXI_BUS.RD_DATA_READY):(0);
end

for (genvar i=0;i<(2**S_WIDTH);i++) begin: AXI_SLAVE_IN
    assign S_WR_ADDR_READY[i] = AXI_SLAVE[i].WR_ADDR_READY;
    assign S_WR_DATA_READY[i] = AXI_SLAVE[i].WR_DATA_READY;
    assign S_WR_BACK_ID   [i] = AXI_SLAVE[i].WR_BACK_ID   ;
    assign S_WR_BACK_RESP [i] = AXI_SLAVE[i].WR_BACK_RESP ;
    assign S_WR_BACK_VALID[i] = AXI_SLAVE[i].WR_BACK_VALID;
    assign S_RD_ADDR_READY[i] = AXI_SLAVE[i].RD_ADDR_READY;
    assign S_RD_BACK_ID   [i] = AXI_SLAVE[i].RD_BACK_ID   ;
    assign S_RD_DATA      [i] = AXI_SLAVE[i].RD_DATA      ;
    assign S_RD_DATA_RESP [i] = AXI_SLAVE[i].RD_DATA_RESP ;
    assign S_RD_DATA_LAST [i] = AXI_SLAVE[i].RD_DATA_LAST ;
    assign S_RD_DATA_VALID[i] = AXI_SLAVE[i].RD_DATA_VALID;
end

always_comb begin
    AXI_BUS.WR_ADDR_READY = 0;
    AXI_BUS.WR_DATA_READY = 0;
    AXI_BUS.WR_BACK_ID    = 0;
    AXI_BUS.WR_BACK_RESP  = 0;
    AXI_BUS.WR_BACK_VALID = 0;
    AXI_BUS.RD_ADDR_READY = 0;
    AXI_BUS.RD_BACK_ID    = 0;
    AXI_BUS.RD_DATA       = 0;
    AXI_BUS.RD_DATA_RESP  = 0;
    AXI_BUS.RD_DATA_LAST  = 0;
    AXI_BUS.RD_DATA_VALID = 0;
    for(int i=0; i<2**S_WIDTH; i++) begin
        if(wr_addr_sel==i)begin
            AXI_BUS.WR_ADDR_READY = S_WR_ADDR_READY[i];
        end
        if(wr_data_sel==i)begin
            AXI_BUS.WR_DATA_READY = S_WR_DATA_READY[i];
        end
        if(wr_resp_sel==i)begin
            AXI_BUS.WR_BACK_ID    = S_WR_BACK_ID   [i];
            AXI_BUS.WR_BACK_RESP  = S_WR_BACK_RESP [i];
            AXI_BUS.WR_BACK_VALID = S_WR_BACK_VALID[i];
        end
        if(rd_addr_sel==i)begin
            AXI_BUS.RD_ADDR_READY = S_RD_ADDR_READY[i];
        end
        if(rd_data_sel==i)begin
            AXI_BUS.RD_DATA       = S_RD_DATA      [i];
            AXI_BUS.RD_DATA_RESP  = S_RD_DATA_RESP [i];
            AXI_BUS.RD_DATA_LAST  = S_RD_DATA_LAST [i];
            AXI_BUS.RD_DATA_VALID = S_RD_DATA_VALID[i];
        end
    end
end

endmodule