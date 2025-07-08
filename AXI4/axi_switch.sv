module axi_master_switch #(
    parameter M_WIDTH = 2,
    parameter M_ID    = 2
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

always_comb begin: master_switch
    int i;
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
    for(i=0; i<2**M_WIDTH; i++) begin
        if(wr_addr_sel==i)begin
            BUS_WR_ADDR_ID    = {wr_addr_sel,MASTER_WR_ADDR_ID[i]};
            BUS_WR_ADDR       = MASTER_WR_ADDR      [i];
            BUS_WR_ADDR_LEN   = MASTER_WR_ADDR_LEN  [i];
            BUS_WR_ADDR_BURST = MASTER_WR_ADDR_BURST[i];
            BUS_WR_ADDR_VALID = MASTER_WR_ADDR_VALID[i];
        end
        if(wr_data_sel==i)begin
            BUS_WR_DATA       = MASTER_WR_DATA      [i];
            BUS_WR_STRB       = MASTER_WR_STRB      [i];
            BUS_WR_DATA_LAST  = MASTER_WR_DATA_LAST [i];
            BUS_WR_DATA_VALID = MASTER_WR_DATA_VALID[i];
        end
        if(wr_resp_sel==i)begin
            BUS_WR_BACK_READY = MASTER_WR_BACK_READY[i];
        end
        if(rd_addr_sel==i)begin
            BUS_RD_ADDR_ID    = {rd_addr_sel,MASTER_RD_ADDR_ID[i]};
            BUS_RD_ADDR       = MASTER_RD_ADDR      [i];
            BUS_RD_ADDR_LEN   = MASTER_RD_ADDR_LEN  [i];
            BUS_RD_ADDR_BURST = MASTER_RD_ADDR_BURST[i];
            BUS_RD_ADDR_VALID = MASTER_RD_ADDR_VALID[i];
        end
        if(rd_data_sel==i)begin
            BUS_RD_DATA_READY = MASTER_RD_DATA_READY[i];
        end
    end
end

endmodule

module axi_slave_switch #(
    parameter S_WIDTH = 2,
    parameter S_ID    = 4
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

always_comb begin: slave_switch
    int i;
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
    for(i=0; i<2**S_WIDTH; i++) begin
        if(wr_addr_sel==i)begin
            BUS_WR_ADDR_READY = SLAVE_WR_ADDR_READY[i];
        end
        if(wr_data_sel==i)begin
            BUS_WR_DATA_READY = SLAVE_WR_DATA_READY[i];
        end
        if(wr_resp_sel==i)begin
            BUS_WR_BACK_ID    = SLAVE_WR_BACK_ID   [i];
            BUS_WR_BACK_RESP  = SLAVE_WR_BACK_RESP [i];
            BUS_WR_BACK_VALID = SLAVE_WR_BACK_VALID[i];
        end
        if(rd_addr_sel==i)begin
            BUS_RD_ADDR_READY = SLAVE_RD_ADDR_READY[i];
        end
        if(rd_data_sel==i)begin
            BUS_RD_DATA       = SLAVE_RD_DATA      [i];
            BUS_RD_DATA_RESP  = SLAVE_RD_DATA_RESP [i];
            BUS_RD_BACK_ID    = SLAVE_RD_BACK_ID   [i];
            BUS_RD_DATA_LAST  = SLAVE_RD_DATA_LAST [i];
            BUS_RD_DATA_VALID = SLAVE_RD_DATA_VALID[i];
        end
    end
end

endmodule