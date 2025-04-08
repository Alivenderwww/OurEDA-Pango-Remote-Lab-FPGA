module axi_master_switch #(
    M_WIDTH = 2,
    M_ID    = 2
)(
    input wire [M_WIDTH-1:0] wr_addr_sel,
    input wire [M_WIDTH-1:0] wr_data_sel,
    input wire [M_WIDTH-1:0] wr_resp_sel,
    input wire [M_WIDTH-1:0] rd_addr_sel,
    input wire [M_WIDTH-1:0] rd_data_sel,
    
    input  logic [(2**M_WIDTH-1):0] [M_ID-1:0]  MASTER_WR_ADDR_ID   ,
    input  logic [(2**M_WIDTH-1):0] [31:0]      MASTER_WR_ADDR      ,
    input  logic [(2**M_WIDTH-1):0] [ 7:0]      MASTER_WR_ADDR_LEN  ,
    input  logic [(2**M_WIDTH-1):0] [ 1:0]      MASTER_WR_ADDR_BURST,
    input  logic [(2**M_WIDTH-1):0]             MASTER_WR_ADDR_VALID,
    output logic [(2**M_WIDTH-1):0]             MASTER_WR_ADDR_READY,
    input  logic [(2**M_WIDTH-1):0] [31:0]      MASTER_WR_DATA      ,
    input  logic [(2**M_WIDTH-1):0] [ 3:0]      MASTER_WR_STRB      ,
    input  logic [(2**M_WIDTH-1):0]             MASTER_WR_DATA_LAST ,
    input  logic [(2**M_WIDTH-1):0]             MASTER_WR_DATA_VALID,
    output logic [(2**M_WIDTH-1):0]             MASTER_WR_DATA_READY,
    output logic [(2**M_WIDTH-1):0] [M_ID-1:0]  MASTER_WR_BACK_ID   ,
    output logic [(2**M_WIDTH-1):0] [ 1:0]      MASTER_WR_BACK_RESP ,
    output logic [(2**M_WIDTH-1):0]             MASTER_WR_BACK_VALID,
    input  logic [(2**M_WIDTH-1):0]             MASTER_WR_BACK_READY,
    input  logic [(2**M_WIDTH-1):0] [M_ID-1:0]  MASTER_RD_ADDR_ID   ,
    input  logic [(2**M_WIDTH-1):0] [31:0]      MASTER_RD_ADDR      ,
    input  logic [(2**M_WIDTH-1):0] [ 7:0]      MASTER_RD_ADDR_LEN  ,
    input  logic [(2**M_WIDTH-1):0] [ 1:0]      MASTER_RD_ADDR_BURST,
    input  logic [(2**M_WIDTH-1):0]             MASTER_RD_ADDR_VALID,
    output logic [(2**M_WIDTH-1):0]             MASTER_RD_ADDR_READY,
    output logic [(2**M_WIDTH-1):0] [M_ID-1:0]  MASTER_RD_BACK_ID   ,
    output logic [(2**M_WIDTH-1):0] [31:0]      MASTER_RD_DATA      ,
    output logic [(2**M_WIDTH-1):0] [ 1:0]      MASTER_RD_DATA_RESP ,
    output logic [(2**M_WIDTH-1):0]             MASTER_RD_DATA_LAST ,
    output logic [(2**M_WIDTH-1):0]             MASTER_RD_DATA_VALID,
    input  logic [(2**M_WIDTH-1):0]             MASTER_RD_DATA_READY,

    output logic [M_ID+M_WIDTH-1:0]  BUS_WR_ADDR_ID   ,
    output logic [31:0]      BUS_WR_ADDR      ,
    output logic [ 7:0]      BUS_WR_ADDR_LEN  ,
    output logic [ 1:0]      BUS_WR_ADDR_BURST,
    output logic             BUS_WR_ADDR_VALID,
    input  logic             BUS_WR_ADDR_READY,
    output logic [31:0]      BUS_WR_DATA      ,
    output logic [ 3:0]      BUS_WR_STRB      ,
    output logic             BUS_WR_DATA_LAST ,
    output logic             BUS_WR_DATA_VALID,
    input  logic             BUS_WR_DATA_READY,
    input  logic [M_ID+M_WIDTH-1:0]  BUS_WR_BACK_ID   ,
    input  logic [ 1:0]      BUS_WR_BACK_RESP ,
    input  logic             BUS_WR_BACK_VALID,
    output logic             BUS_WR_BACK_READY,
    output logic [M_ID+M_WIDTH-1:0]  BUS_RD_ADDR_ID   ,
    output logic [31:0]      BUS_RD_ADDR      ,
    output logic [ 7:0]      BUS_RD_ADDR_LEN  ,
    output logic [ 1:0]      BUS_RD_ADDR_BURST,
    output logic             BUS_RD_ADDR_VALID,
    input  logic             BUS_RD_ADDR_READY,
    input  logic [M_ID+M_WIDTH-1:0]  BUS_RD_BACK_ID   ,
    input  logic [31:0]      BUS_RD_DATA      ,
    input  logic [ 1:0]      BUS_RD_DATA_RESP ,
    input  logic             BUS_RD_DATA_LAST ,
    input  logic             BUS_RD_DATA_VALID,
    output logic             BUS_RD_DATA_READY
);

logic [2**M_WIDTH-1:0] [M_ID-1:0]     M_WR_ADDR_ID   ;
logic [2**M_WIDTH-1:0] [31:0]         M_WR_ADDR      ;
logic [2**M_WIDTH-1:0] [ 7:0]         M_WR_ADDR_LEN  ;
logic [2**M_WIDTH-1:0] [ 1:0]         M_WR_ADDR_BURST;
logic [2**M_WIDTH-1:0]                M_WR_ADDR_VALID;
logic [2**M_WIDTH-1:0] [31:0]         M_WR_DATA      ;
logic [2**M_WIDTH-1:0] [ 3:0]         M_WR_STRB      ;
logic [2**M_WIDTH-1:0]                M_WR_DATA_LAST ;
logic [2**M_WIDTH-1:0]                M_WR_DATA_VALID;
logic [2**M_WIDTH-1:0]                M_WR_BACK_READY;
logic [2**M_WIDTH-1:0] [M_ID-1:0]     M_RD_ADDR_ID   ;
logic [2**M_WIDTH-1:0] [31:0]         M_RD_ADDR      ;
logic [2**M_WIDTH-1:0] [ 7:0]         M_RD_ADDR_LEN  ;
logic [2**M_WIDTH-1:0] [ 1:0]         M_RD_ADDR_BURST;
logic [2**M_WIDTH-1:0]                M_RD_ADDR_VALID;
logic [2**M_WIDTH-1:0]                M_RD_DATA_READY;

for (genvar i=0; i<(2**M_WIDTH); i++) begin: AXI_MASTER_OUT
    assign MASTER_WR_ADDR_READY[i] = (wr_addr_sel==i)?(BUS_WR_ADDR_READY):(0);
    assign MASTER_WR_DATA_READY[i] = (wr_data_sel==i)?(BUS_WR_DATA_READY):(0);
    assign MASTER_WR_BACK_ID   [i] = (wr_resp_sel==i)?(BUS_WR_BACK_ID   ):(0);
    assign MASTER_WR_BACK_RESP [i] = (wr_resp_sel==i)?(BUS_WR_BACK_RESP ):(0);
    assign MASTER_WR_BACK_VALID[i] = (wr_resp_sel==i)?(BUS_WR_BACK_VALID):(0);
    assign MASTER_RD_ADDR_READY[i] = (rd_addr_sel==i)?(BUS_RD_ADDR_READY):(0);
    assign MASTER_RD_BACK_ID   [i] = (rd_data_sel==i)?(BUS_RD_BACK_ID   ):(0);
    assign MASTER_RD_DATA      [i] = (rd_data_sel==i)?(BUS_RD_DATA      ):(0);
    assign MASTER_RD_DATA_RESP [i] = (rd_data_sel==i)?(BUS_RD_DATA_RESP ):(0);
    assign MASTER_RD_DATA_LAST [i] = (rd_data_sel==i)?(BUS_RD_DATA_LAST ):(0);
    assign MASTER_RD_DATA_VALID[i] = (rd_data_sel==i)?(BUS_RD_DATA_VALID):(0);
end

for (genvar i=0;i<(2**M_WIDTH);i++) begin: AXI_MASTER_IN
    assign M_WR_ADDR_ID   [i] = MASTER_WR_ADDR_ID   [i];
    assign M_WR_ADDR      [i] = MASTER_WR_ADDR      [i];
    assign M_WR_ADDR_LEN  [i] = MASTER_WR_ADDR_LEN  [i];
    assign M_WR_ADDR_BURST[i] = MASTER_WR_ADDR_BURST[i];
    assign M_WR_ADDR_VALID[i] = MASTER_WR_ADDR_VALID[i];
    assign M_WR_DATA      [i] = MASTER_WR_DATA      [i];
    assign M_WR_STRB      [i] = MASTER_WR_STRB      [i];
    assign M_WR_DATA_LAST [i] = MASTER_WR_DATA_LAST [i];
    assign M_WR_DATA_VALID[i] = MASTER_WR_DATA_VALID[i];
    assign M_WR_BACK_READY[i] = MASTER_WR_BACK_READY[i];
    assign M_RD_ADDR_ID   [i] = MASTER_RD_ADDR_ID   [i];
    assign M_RD_ADDR      [i] = MASTER_RD_ADDR      [i];
    assign M_RD_ADDR_LEN  [i] = MASTER_RD_ADDR_LEN  [i];
    assign M_RD_ADDR_BURST[i] = MASTER_RD_ADDR_BURST[i];
    assign M_RD_ADDR_VALID[i] = MASTER_RD_ADDR_VALID[i];
    assign M_RD_DATA_READY[i] = MASTER_RD_DATA_READY[i];
end

always_comb begin
    BUS_WR_ADDR_ID    = 0;
    BUS_WR_ADDR       = 0;
    BUS_WR_ADDR_LEN   = 0;
    BUS_WR_ADDR_BURST = 0;
    BUS_WR_ADDR_VALID = 0;
    BUS_WR_DATA       = 0;
    BUS_WR_STRB       = 0;
    BUS_WR_DATA_LAST  = 0;
    BUS_WR_DATA_VALID = 0;
    BUS_WR_BACK_READY = 0;
    BUS_RD_ADDR_ID    = 0;
    BUS_RD_ADDR       = 0;
    BUS_RD_ADDR_LEN   = 0;
    BUS_RD_ADDR_BURST = 0;
    BUS_RD_ADDR_VALID = 0;
    BUS_RD_DATA_READY = 0;
    for(int i=0; i<2**M_WIDTH; i++) begin
        if(wr_addr_sel==i)begin
            BUS_WR_ADDR_ID    = {wr_addr_sel,M_WR_ADDR_ID[i]};
            BUS_WR_ADDR       = M_WR_ADDR      [i];
            BUS_WR_ADDR_LEN   = M_WR_ADDR_LEN  [i];
            BUS_WR_ADDR_BURST = M_WR_ADDR_BURST[i];
            BUS_WR_ADDR_VALID = M_WR_ADDR_VALID[i];
        end
        if(wr_data_sel==i)begin
            BUS_WR_DATA       = M_WR_DATA      [i];
            BUS_WR_STRB       = M_WR_STRB      [i];
            BUS_WR_DATA_LAST  = M_WR_DATA_LAST [i];
            BUS_WR_DATA_VALID = M_WR_DATA_VALID[i];
        end
        if(wr_resp_sel==i)begin
            BUS_WR_BACK_READY = M_WR_BACK_READY[i];
        end
        if(rd_addr_sel==i)begin
            BUS_RD_ADDR_ID    = {rd_addr_sel,M_RD_ADDR_ID[i]};
            BUS_RD_ADDR       = M_RD_ADDR      [i];
            BUS_RD_ADDR_LEN   = M_RD_ADDR_LEN  [i];
            BUS_RD_ADDR_BURST = M_RD_ADDR_BURST[i];
            BUS_RD_ADDR_VALID = M_RD_ADDR_VALID[i];
        end
        if(rd_data_sel==i)begin
            BUS_RD_DATA_READY = M_RD_DATA_READY[i];
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

    output logic [(2**S_WIDTH-1):0] [S_ID-1:0]     SLAVE_WR_ADDR_ID   ,
    output logic [(2**S_WIDTH-1):0] [31:0]         SLAVE_WR_ADDR      ,
    output logic [(2**S_WIDTH-1):0] [ 7:0]         SLAVE_WR_ADDR_LEN  ,
    output logic [(2**S_WIDTH-1):0] [ 1:0]         SLAVE_WR_ADDR_BURST,
    output logic [(2**S_WIDTH-1):0]                SLAVE_WR_ADDR_VALID,
    input  logic [(2**S_WIDTH-1):0]                SLAVE_WR_ADDR_READY,
    output logic [(2**S_WIDTH-1):0] [31:0]         SLAVE_WR_DATA      ,
    output logic [(2**S_WIDTH-1):0] [ 3:0]         SLAVE_WR_STRB      ,
    output logic [(2**S_WIDTH-1):0]                SLAVE_WR_DATA_LAST ,
    output logic [(2**S_WIDTH-1):0]                SLAVE_WR_DATA_VALID,
    input  logic [(2**S_WIDTH-1):0]                SLAVE_WR_DATA_READY,
    input  logic [(2**S_WIDTH-1):0] [S_ID-1:0]     SLAVE_WR_BACK_ID   ,
    input  logic [(2**S_WIDTH-1):0] [ 1:0]         SLAVE_WR_BACK_RESP ,
    input  logic [(2**S_WIDTH-1):0]                SLAVE_WR_BACK_VALID,
    output logic [(2**S_WIDTH-1):0]                SLAVE_WR_BACK_READY,
    output logic [(2**S_WIDTH-1):0] [S_ID-1:0]     SLAVE_RD_ADDR_ID   ,
    output logic [(2**S_WIDTH-1):0] [31:0]         SLAVE_RD_ADDR      ,
    output logic [(2**S_WIDTH-1):0] [ 7:0]         SLAVE_RD_ADDR_LEN  ,
    output logic [(2**S_WIDTH-1):0] [ 1:0]         SLAVE_RD_ADDR_BURST,
    output logic [(2**S_WIDTH-1):0]                SLAVE_RD_ADDR_VALID,
    input  logic [(2**S_WIDTH-1):0]                SLAVE_RD_ADDR_READY,
    input  logic [(2**S_WIDTH-1):0] [S_ID-1:0]     SLAVE_RD_BACK_ID   ,
    input  logic [(2**S_WIDTH-1):0] [31:0]         SLAVE_RD_DATA      ,
    input  logic [(2**S_WIDTH-1):0] [ 1:0]         SLAVE_RD_DATA_RESP ,
    input  logic [(2**S_WIDTH-1):0]                SLAVE_RD_DATA_LAST ,
    input  logic [(2**S_WIDTH-1):0]                SLAVE_RD_DATA_VALID,
    output logic [(2**S_WIDTH-1):0]                SLAVE_RD_DATA_READY,

    input  logic [S_ID-1:0]     BUS_WR_ADDR_ID   ,
    input  logic [31:0]         BUS_WR_ADDR      ,
    input  logic [ 7:0]         BUS_WR_ADDR_LEN  ,
    input  logic [ 1:0]         BUS_WR_ADDR_BURST,
    input  logic                BUS_WR_ADDR_VALID,
    output logic                BUS_WR_ADDR_READY,
    input  logic [31:0]         BUS_WR_DATA      ,
    input  logic [ 3:0]         BUS_WR_STRB      ,
    input  logic                BUS_WR_DATA_LAST ,
    input  logic                BUS_WR_DATA_VALID,
    output logic                BUS_WR_DATA_READY,
    output logic [S_ID-1:0]     BUS_WR_BACK_ID   ,
    output logic [ 1:0]         BUS_WR_BACK_RESP ,
    output logic                BUS_WR_BACK_VALID,
    input  logic                BUS_WR_BACK_READY,
    input  logic [S_ID-1:0]     BUS_RD_ADDR_ID   ,
    input  logic [31:0]         BUS_RD_ADDR      ,
    input  logic [ 7:0]         BUS_RD_ADDR_LEN  ,
    input  logic [ 1:0]         BUS_RD_ADDR_BURST,
    input  logic                BUS_RD_ADDR_VALID,
    output logic                BUS_RD_ADDR_READY,
    output logic [S_ID-1:0]     BUS_RD_BACK_ID   ,
    output logic [31:0]         BUS_RD_DATA      ,
    output logic [ 1:0]         BUS_RD_DATA_RESP ,
    output logic                BUS_RD_DATA_LAST ,
    output logic                BUS_RD_DATA_VALID,
    input  logic                BUS_RD_DATA_READY
);

logic [2**S_WIDTH-1:0]            S_WR_ADDR_READY;
logic [2**S_WIDTH-1:0]            S_WR_DATA_READY;
logic [2**S_WIDTH-1:0] [S_ID-1:0] S_WR_BACK_ID   ;
logic [2**S_WIDTH-1:0] [ 1:0]     S_WR_BACK_RESP ;
logic [2**S_WIDTH-1:0]            S_WR_BACK_VALID;
logic [2**S_WIDTH-1:0]            S_RD_ADDR_READY;
logic [2**S_WIDTH-1:0] [S_ID-1:0] S_RD_BACK_ID   ;
logic [2**S_WIDTH-1:0] [31:0]     S_RD_DATA      ;
logic [2**S_WIDTH-1:0] [ 1:0]     S_RD_DATA_RESP ;
logic [2**S_WIDTH-1:0]            S_RD_DATA_LAST ;
logic [2**S_WIDTH-1:0]            S_RD_DATA_VALID;

for (genvar i=0; i<2**S_WIDTH; i++) begin: AXI_SLAVE_OUT
    assign SLAVE_WR_ADDR_ID   [i] = (wr_addr_sel==i)?(BUS_WR_ADDR_ID   ):(0);
    assign SLAVE_WR_ADDR      [i] = (wr_addr_sel==i)?(BUS_WR_ADDR      ):(0);
    assign SLAVE_WR_ADDR_LEN  [i] = (wr_addr_sel==i)?(BUS_WR_ADDR_LEN  ):(0);
    assign SLAVE_WR_ADDR_BURST[i] = (wr_addr_sel==i)?(BUS_WR_ADDR_BURST):(0);
    assign SLAVE_WR_ADDR_VALID[i] = (wr_addr_sel==i)?(BUS_WR_ADDR_VALID):(0);
    assign SLAVE_WR_DATA      [i] = (wr_data_sel==i)?(BUS_WR_DATA      ):(0);
    assign SLAVE_WR_STRB      [i] = (wr_data_sel==i)?(BUS_WR_STRB      ):(0);
    assign SLAVE_WR_DATA_LAST [i] = (wr_data_sel==i)?(BUS_WR_DATA_LAST ):(0);
    assign SLAVE_WR_DATA_VALID[i] = (wr_data_sel==i)?(BUS_WR_DATA_VALID):(0);
    assign SLAVE_WR_BACK_READY[i] = (wr_resp_sel==i)?(BUS_WR_BACK_READY):(0);
    assign SLAVE_RD_ADDR_ID   [i] = (rd_addr_sel==i)?(BUS_RD_ADDR_ID   ):(0);
    assign SLAVE_RD_ADDR      [i] = (rd_addr_sel==i)?(BUS_RD_ADDR      ):(0);
    assign SLAVE_RD_ADDR_LEN  [i] = (rd_addr_sel==i)?(BUS_RD_ADDR_LEN  ):(0);
    assign SLAVE_RD_ADDR_BURST[i] = (rd_addr_sel==i)?(BUS_RD_ADDR_BURST):(0);
    assign SLAVE_RD_ADDR_VALID[i] = (rd_addr_sel==i)?(BUS_RD_ADDR_VALID):(0);
    assign SLAVE_RD_DATA_READY[i] = (rd_data_sel==i)?(BUS_RD_DATA_READY):(0);
end

for (genvar i=0;i<(2**S_WIDTH);i++) begin: AXI_SLAVE_IN
    assign S_WR_ADDR_READY[i] = SLAVE_WR_ADDR_READY[i];
    assign S_WR_DATA_READY[i] = SLAVE_WR_DATA_READY[i];
    assign S_WR_BACK_ID   [i] = SLAVE_WR_BACK_ID   [i];
    assign S_WR_BACK_RESP [i] = SLAVE_WR_BACK_RESP [i];
    assign S_WR_BACK_VALID[i] = SLAVE_WR_BACK_VALID[i];
    assign S_RD_ADDR_READY[i] = SLAVE_RD_ADDR_READY[i];
    assign S_RD_BACK_ID   [i] = SLAVE_RD_BACK_ID   [i];
    assign S_RD_DATA      [i] = SLAVE_RD_DATA      [i];
    assign S_RD_DATA_RESP [i] = SLAVE_RD_DATA_RESP [i];
    assign S_RD_DATA_LAST [i] = SLAVE_RD_DATA_LAST [i];
    assign S_RD_DATA_VALID[i] = SLAVE_RD_DATA_VALID[i];
end

always_comb begin
    BUS_WR_ADDR_READY = 0;
    BUS_WR_DATA_READY = 0;
    BUS_WR_BACK_ID    = 0;
    BUS_WR_BACK_RESP  = 0;
    BUS_WR_BACK_VALID = 0;
    BUS_RD_ADDR_READY = 0;
    BUS_RD_BACK_ID    = 0;
    BUS_RD_DATA       = 0;
    BUS_RD_DATA_RESP  = 0;
    BUS_RD_DATA_LAST  = 0;
    BUS_RD_DATA_VALID = 0;
    for(int i=0; i<2**S_WIDTH; i++) begin
        if(wr_addr_sel==i)begin
            BUS_WR_ADDR_READY = S_WR_ADDR_READY[i];
        end
        if(wr_data_sel==i)begin
            BUS_WR_DATA_READY = S_WR_DATA_READY[i];
        end
        if(wr_resp_sel==i)begin
            BUS_WR_BACK_ID    = S_WR_BACK_ID   [i];
            BUS_WR_BACK_RESP  = S_WR_BACK_RESP [i];
            BUS_WR_BACK_VALID = S_WR_BACK_VALID[i];
        end
        if(rd_addr_sel==i)begin
            BUS_RD_ADDR_READY = S_RD_ADDR_READY[i];
        end
        if(rd_data_sel==i)begin
            BUS_RD_DATA       = S_RD_DATA      [i];
            BUS_RD_DATA_RESP  = S_RD_DATA_RESP [i];
            BUS_RD_DATA_LAST  = S_RD_DATA_LAST [i];
            BUS_RD_DATA_VALID = S_RD_DATA_VALID[i];
        end
    end
end

endmodule