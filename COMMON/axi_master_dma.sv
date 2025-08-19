module axi_master_write_dma #(
    parameter RD_INTERFACE_NUM = 2,
    parameter WR_INTERFACE_NUM = 1
)(
    input  logic [RD_INTERFACE_NUM-1:0] [31:0] START_WRITE_ADDR    ,
    input  logic [RD_INTERFACE_NUM-1:0] [31:0] END_WRITE_ADDR      ,
    input  logic [WR_INTERFACE_NUM-1:0] [31:0] START_READ_ADDR    ,
    input  logic [WR_INTERFACE_NUM-1:0] [31:0] END_READ_ADDR      ,

    input  logic         clk,
    input  logic         rstn,

    output logic [RD_INTERFACE_NUM-1:0]        rd_rstn             ,
    input  logic [RD_INTERFACE_NUM-1:0]        rd_capture_rstn     ,
    input  logic [RD_INTERFACE_NUM-1:0]        rd_addr_reset       ,
    
    input  logic [RD_INTERFACE_NUM-1:0]        rd_data_burst_valid ,
    output logic [RD_INTERFACE_NUM-1:0]        rd_data_burst_ready ,
    input  logic [RD_INTERFACE_NUM-1:0] [7:0]  rd_data_burst       ,

    output logic [RD_INTERFACE_NUM-1:0]        rd_data_ready       ,
    input  logic [RD_INTERFACE_NUM-1:0]        rd_data_valid       ,
    input  logic [RD_INTERFACE_NUM-1:0] [31:0] rd_data             ,
    input  logic [RD_INTERFACE_NUM-1:0]        rd_data_last        ,


    output logic [WR_INTERFACE_NUM-1:0]        wr_rstn             ,
    input  logic [WR_INTERFACE_NUM-1:0]        wr_capture_rstn     ,
    input  logic [WR_INTERFACE_NUM-1:0]        wr_addr_reset       ,

    input  logic [WR_INTERFACE_NUM-1:0]        wr_data_burst_valid ,
    output logic [WR_INTERFACE_NUM-1:0]        wr_data_burst_ready ,
    input  logic [WR_INTERFACE_NUM-1:0] [7:0]  wr_data_burst       ,

    input  logic [WR_INTERFACE_NUM-1:0]        wr_data_ready       ,
    output logic [WR_INTERFACE_NUM-1:0]        wr_data_valid       ,
    output logic [WR_INTERFACE_NUM-1:0] [31:0] wr_data             ,
    output logic [WR_INTERFACE_NUM-1:0]        wr_data_last        ,

    //AXI MASTER interface
    output logic         MASTER_CLK          ,
    output logic         MASTER_RSTN         ,
    output logic [2-1:0] MASTER_WR_ADDR_ID   ,
    output logic [31:0]  MASTER_WR_ADDR      ,
    output logic [ 7:0]  MASTER_WR_ADDR_LEN  ,
    output logic [ 1:0]  MASTER_WR_ADDR_BURST,
    output logic         MASTER_WR_ADDR_VALID,
    input  logic         MASTER_WR_ADDR_READY,
    output logic [31:0]  MASTER_WR_DATA      ,
    output logic [ 3:0]  MASTER_WR_STRB      ,
    output logic         MASTER_WR_DATA_LAST ,
    output logic         MASTER_WR_DATA_VALID,
    input  logic         MASTER_WR_DATA_READY,
    input  logic [2-1:0] MASTER_WR_BACK_ID   ,
    input  logic [ 1:0]  MASTER_WR_BACK_RESP ,
    input  logic         MASTER_WR_BACK_VALID,
    output logic         MASTER_WR_BACK_READY,
    output logic [2-1:0] MASTER_RD_ADDR_ID   ,
    output logic [31:0]  MASTER_RD_ADDR      ,
    output logic [ 7:0]  MASTER_RD_ADDR_LEN  ,
    output logic [ 1:0]  MASTER_RD_ADDR_BURST,
    output logic         MASTER_RD_ADDR_VALID,
    input  logic         MASTER_RD_ADDR_READY,
    input  logic [2-1:0] MASTER_RD_BACK_ID   ,
    input  logic [31:0]  MASTER_RD_DATA      ,
    input  logic [ 1:0]  MASTER_RD_DATA_RESP ,
    input  logic         MASTER_RD_DATA_LAST ,
    input  logic         MASTER_RD_DATA_VALID,
    output logic         MASTER_RD_DATA_READY);

wire dma_rstn_sync;
rstn_sync rstn_sync_ov(clk, rstn, dma_rstn_sync);

assign MASTER_CLK  = clk;
assign MASTER_RSTN = dma_rstn_sync;


//-------------------READ: read from fifo, auto write to axi slave-------------------//

reg [RD_INTERFACE_NUM-1:0] rd_channel;
reg                        rd_channel_lock;

reg  [RD_INTERFACE_NUM-1:0] [7:0]  rd_data_burst_load;
reg  [RD_INTERFACE_NUM-1:0]        need_second_wr;
reg  [RD_INTERFACE_NUM-1:0] [31:0] wr_addr_load;
reg  [RD_INTERFACE_NUM-1:0] [7:0]  wr_len_load, wr_len_load_count;
reg  [RD_INTERFACE_NUM-1:0] [8:0]  axi_rd_cu_st;
reg  [RD_INTERFACE_NUM-1:0] [8:0]  axi_rd_nt_st;
reg  [RD_INTERFACE_NUM-1:0]        rd_addr_reset_d;

integer i;
localparam AXI_RD_ST_FIRST_LOAD = 9'b000000001,
           AXI_RD_ST_IDLE       = 9'b000000010,
           AXI_RD_ST_LOAD_BURST = 9'b000000100,
           AXI_RD_ST_WR_ADDR    = 9'b000001000,
           AXI_RD_ST_WR_DATA    = 9'b000010000,
           AXI_RD_ST_WR_RESP    = 9'b000100000,
           AXI_RD_ST_WR_ADDR_END= 9'b001000000,
           AXI_RD_ST_WR_DATA_END= 9'b010000000,
           AXI_RD_ST_WR_RESP_END= 9'b100000000;
always @(posedge clk or negedge dma_rstn_sync) begin
    if(~dma_rstn_sync) for(i=0;i<RD_INTERFACE_NUM;i=i+1)
        axi_rd_cu_st[i] <= AXI_RD_ST_FIRST_LOAD;
    else for(i=0;i<RD_INTERFACE_NUM;i=i+1)
        axi_rd_cu_st[i] <= axi_rd_nt_st[i];
end
always @(*) begin
    for(i=0;i<RD_INTERFACE_NUM;i=i+1)
    case (axi_rd_cu_st[i])
        AXI_RD_ST_FIRST_LOAD : axi_rd_nt_st[i] = (rd_capture_rstn[i]) ? (AXI_RD_ST_LOAD_BURST):(AXI_RD_ST_FIRST_LOAD);
        AXI_RD_ST_IDLE       : axi_rd_nt_st[i] = (rd_capture_rstn[i]) ? (AXI_RD_ST_LOAD_BURST) : (AXI_RD_ST_FIRST_LOAD);
        AXI_RD_ST_LOAD_BURST : axi_rd_nt_st[i] = (rd_capture_rstn[i]) ? ((rd_data_burst_valid[i] && rd_data_burst_ready[i]) ? ((need_second_wr[i])?(AXI_RD_ST_WR_ADDR_END):(AXI_RD_ST_WR_ADDR)):(AXI_RD_ST_LOAD_BURST)):(AXI_RD_ST_FIRST_LOAD);
        AXI_RD_ST_WR_ADDR    : axi_rd_nt_st[i] = ((rd_channel == i) && MASTER_WR_ADDR_VALID && MASTER_WR_ADDR_READY) ? (AXI_RD_ST_WR_DATA) : (AXI_RD_ST_WR_ADDR);
        AXI_RD_ST_WR_DATA    : axi_rd_nt_st[i] = ((rd_channel == i) && MASTER_WR_DATA_VALID && MASTER_WR_DATA_READY && MASTER_WR_DATA_LAST) ? (AXI_RD_ST_WR_RESP) : (AXI_RD_ST_WR_DATA);
        AXI_RD_ST_WR_RESP    : axi_rd_nt_st[i] = ((rd_channel == i) && MASTER_WR_BACK_VALID && MASTER_WR_BACK_READY) ? (AXI_RD_ST_IDLE) : (AXI_RD_ST_WR_RESP);
        AXI_RD_ST_WR_ADDR_END: axi_rd_nt_st[i] = ((rd_channel == i) && MASTER_WR_ADDR_VALID && MASTER_WR_ADDR_READY) ? (AXI_RD_ST_WR_DATA_END) : (AXI_RD_ST_WR_ADDR_END);
        AXI_RD_ST_WR_DATA_END: axi_rd_nt_st[i] = ((rd_channel == i) && MASTER_WR_DATA_VALID && MASTER_WR_DATA_READY && MASTER_WR_DATA_LAST) ? (AXI_RD_ST_WR_RESP_END) : (AXI_RD_ST_WR_DATA_END);
        AXI_RD_ST_WR_RESP_END: axi_rd_nt_st[i] = ((rd_channel == i) && MASTER_WR_BACK_VALID && MASTER_WR_BACK_READY) ? (AXI_RD_ST_WR_ADDR) : (AXI_RD_ST_WR_RESP_END);
        default              : axi_rd_nt_st[i] = AXI_RD_ST_FIRST_LOAD;
    endcase
end

//rd_addr_reset_d
always @(posedge clk or negedge dma_rstn_sync) begin
    if(~dma_rstn_sync) for(i=0;i<RD_INTERFACE_NUM;i=i+1) rd_addr_reset_d[i] <= 0;
    else for(i=0;i<RD_INTERFACE_NUM;i=i+1) begin
        if(rd_addr_reset[i]) rd_addr_reset_d[i] <= 1;
        else if(axi_rd_nt_st[i] == AXI_RD_ST_LOAD_BURST) rd_addr_reset_d[i] <= 0;
        else rd_addr_reset_d[i] <= rd_addr_reset_d[i];
    end
end

always @(posedge clk or negedge dma_rstn_sync) begin
    if(~dma_rstn_sync) rd_channel_lock <= 0;
    else for(i=0;i<RD_INTERFACE_NUM;i=i+1) if(rd_channel == i) begin
        if(axi_rd_cu_st[i] == AXI_RD_ST_IDLE) rd_channel_lock <= 0; //传输结束，传输通道解锁
        else if(axi_rd_cu_st[i] == AXI_RD_ST_WR_ADDR || axi_rd_cu_st[i] == AXI_RD_ST_WR_ADDR_END)
              rd_channel_lock <= 1; //开始传输，传输通道加锁
        else  rd_channel_lock <= rd_channel_lock;
    end 
end
always @(posedge clk or negedge dma_rstn_sync) begin
    if(~dma_rstn_sync) rd_channel <= 0;
    else if(rd_channel_lock) rd_channel <= rd_channel;
    else for(i=0;i<RD_INTERFACE_NUM;i=i+1) begin
        if(axi_rd_cu_st[i] == AXI_RD_ST_WR_ADDR || axi_rd_cu_st[i] == AXI_RD_ST_WR_ADDR_END)
            rd_channel <= i[RD_INTERFACE_NUM-1:0];
    end
end

//update when WR_RESP -> IDLE
always @(posedge clk or negedge dma_rstn_sync) begin
    if(~dma_rstn_sync) for(i=0;i<RD_INTERFACE_NUM;i=i+1) begin
        wr_addr_load[i] <= 0;
    end else for(i=0;i<RD_INTERFACE_NUM;i=i+1) begin
        if((axi_rd_nt_st[i] == AXI_RD_ST_LOAD_BURST) && rd_addr_reset_d[i]) begin
            wr_addr_load[i] <= START_WRITE_ADDR[i];
        end else if((axi_rd_cu_st[i] == AXI_RD_ST_FIRST_LOAD) && (axi_rd_nt_st[i] == AXI_RD_ST_LOAD_BURST)) begin
            wr_addr_load[i] <= START_WRITE_ADDR[i];
        end else if((axi_rd_cu_st[i] == AXI_RD_ST_WR_RESP_END) && (axi_rd_nt_st[i] == AXI_RD_ST_WR_ADDR)) begin
            wr_addr_load[i] <= START_WRITE_ADDR[i];
        end else if((axi_rd_cu_st[i] == AXI_RD_ST_WR_RESP) && (axi_rd_nt_st[i] == AXI_RD_ST_IDLE)) begin
            //wr_addr_load + wr_len_load + 1 是下一次写入的起始地址（如果没到边界）
            if(wr_addr_load[i] + wr_len_load[i] + 1 > END_WRITE_ADDR[i]) 
                 wr_addr_load[i] <= START_WRITE_ADDR[i];
            else wr_addr_load[i] <= wr_addr_load[i] + (wr_len_load[i] + 1);
        end else wr_addr_load[i] <= wr_addr_load[i];
    end
end

always @(*) begin
    for(i=0;i<RD_INTERFACE_NUM;i=i+1)
        need_second_wr[i] = (wr_addr_load[i] + rd_data_burst[i] > END_WRITE_ADDR[i]) ? 1'b1 : 1'b0;
end
//update when LOAD_BURST -> WR_ADDR, or WR_RESP_END -> WR_ADDR
always @(posedge clk or negedge dma_rstn_sync) begin
    if(~dma_rstn_sync) for(i=0;i<RD_INTERFACE_NUM;i=i+1) begin
        wr_len_load[i] <= 0;
    end else for(i=0;i<RD_INTERFACE_NUM;i=i+1) begin
        if((axi_rd_cu_st[i] == AXI_RD_ST_LOAD_BURST) && (rd_data_burst_valid[i] && rd_data_burst_ready[i])) begin
            wr_len_load[i] <= (need_second_wr[i]) ? (END_WRITE_ADDR[i] - wr_addr_load[i]) : rd_data_burst[i];
        end else if((axi_rd_cu_st[i] == AXI_RD_ST_WR_RESP_END) && (axi_rd_nt_st[i] == AXI_RD_ST_WR_ADDR)) begin
            wr_len_load[i] <= rd_data_burst_load[i] - (wr_len_load[i] + 1);
        end else wr_len_load[i] <= wr_len_load[i];
    end
end

//update when WR_ADDR(_END) -> WR_DATA
always @(posedge clk or negedge dma_rstn_sync) begin
    if(~dma_rstn_sync) for(i=0;i<RD_INTERFACE_NUM;i=i+1) wr_len_load_count[i] <= 0;
    else for(i=0;i<RD_INTERFACE_NUM;i=i+1) if(rd_channel == i) begin
        if(MASTER_WR_ADDR_VALID && MASTER_WR_ADDR_READY)
             wr_len_load_count[i] <= wr_len_load[i];
        else if(MASTER_WR_DATA_VALID && MASTER_WR_DATA_READY)
             wr_len_load_count[i] <= (MASTER_WR_DATA_LAST) ? (wr_len_load_count[i]) : (wr_len_load_count[i] - 1);
        else wr_len_load_count[i] <= wr_len_load_count[i];
    end else wr_len_load_count[i] <= wr_len_load_count[i];
end

always_comb begin: MASTER_WRITE_CHANNEL
    int comb_i;
    MASTER_WR_ADDR_ID    = 0;
    MASTER_WR_ADDR_BURST = 2'b01;
    MASTER_WR_STRB       = 4'b1111; //always write 32bit
    MASTER_WR_ADDR       = 0;
    MASTER_WR_ADDR_LEN   = 0;
    MASTER_WR_ADDR_VALID = 0;
    MASTER_WR_DATA_VALID = 0;
    MASTER_WR_DATA_LAST  = 0;
    MASTER_WR_DATA       = 0;
    MASTER_WR_BACK_READY = 0;
    if(rd_channel_lock) begin
        for(comb_i=0;comb_i<RD_INTERFACE_NUM;comb_i=comb_i+1) if(rd_channel == comb_i) begin
            MASTER_WR_ADDR       = wr_addr_load[comb_i];
            MASTER_WR_ADDR_LEN   = wr_len_load[comb_i];
            MASTER_WR_ADDR_VALID = (axi_rd_cu_st[comb_i] == AXI_RD_ST_WR_ADDR) || (axi_rd_cu_st[comb_i] == AXI_RD_ST_WR_ADDR_END);
            MASTER_WR_DATA_VALID = (axi_rd_cu_st[comb_i] == AXI_RD_ST_WR_DATA || axi_rd_cu_st[comb_i] == AXI_RD_ST_WR_DATA_END) && (rd_data_valid[comb_i] || (~rd_capture_rstn[comb_i]));
            MASTER_WR_DATA_LAST  = ((axi_rd_cu_st[comb_i] == AXI_RD_ST_WR_DATA) && (rd_data_last[comb_i])) || ((axi_rd_cu_st[comb_i] == AXI_RD_ST_WR_DATA_END) && (wr_len_load_count[comb_i] == 0));
            MASTER_WR_DATA       = rd_data[comb_i];
            MASTER_WR_BACK_READY = (axi_rd_cu_st[comb_i] == AXI_RD_ST_WR_RESP) || (axi_rd_cu_st[comb_i] == AXI_RD_ST_WR_RESP_END);
        end
    end
end

always @(*) begin
    for(i=0;i<RD_INTERFACE_NUM;i=i+1) begin
        rd_data_burst_ready[i] = (axi_rd_cu_st[i] == AXI_RD_ST_LOAD_BURST) & rd_capture_rstn[i];
        rd_data_ready[i]       = ((rd_channel == i) && rd_channel_lock)?((rd_capture_rstn[i]) && ((axi_rd_cu_st[i] == AXI_RD_ST_WR_DATA || axi_rd_cu_st[i] == AXI_RD_ST_WR_DATA_END) && (MASTER_WR_DATA_READY))):(0);
        rd_rstn[i]             = dma_rstn_sync & rd_capture_rstn[i];
    end
end

always @(posedge clk or negedge dma_rstn_sync) begin
    if(~dma_rstn_sync) for(i=0;i<RD_INTERFACE_NUM;i=i+1) rd_data_burst_load[i] <= 0;
    else for(i=0;i<RD_INTERFACE_NUM;i=i+1) begin
        if((axi_rd_cu_st[i] == AXI_RD_ST_LOAD_BURST) && rd_data_burst_valid[i] && rd_data_burst_ready[i])
             rd_data_burst_load[i] <= rd_data_burst[i];
        else rd_data_burst_load[i] <= rd_data_burst_load[i];
    end
end

//-------------------WRITE: auto read to axi slave, write from fifo-------------------//

reg [WR_INTERFACE_NUM-1:0] wr_channel;
reg                        wr_channel_lock;

reg  [WR_INTERFACE_NUM-1:0] [7:0]  wr_data_burst_load;
reg  [WR_INTERFACE_NUM-1:0]        need_second_rd;
reg  [WR_INTERFACE_NUM-1:0] [31:0] rd_addr_load;
reg  [WR_INTERFACE_NUM-1:0] [7:0]  rd_len_load;
reg  [WR_INTERFACE_NUM-1:0] [7:0]  axi_wr_cu_st;
reg  [WR_INTERFACE_NUM-1:0] [7:0]  axi_wr_nt_st;
reg  [WR_INTERFACE_NUM-1:0]        wr_addr_reset_d;

localparam AXI_WR_ST_FIRST_LOAD     = 8'b00000001,
           AXI_WR_ST_IDLE           = 8'b00000010,
           AXI_WR_ST_LOAD_BURST     = 8'b00000100,
           AXI_WR_ST_RD_ADDR        = 8'b00001000,
           AXI_WR_ST_RD_DATA        = 8'b00010000,
           AXI_WR_ST_RD_ADDR_END    = 8'b00100000,
           AXI_WR_ST_RD_DATA_END    = 8'b01000000,
           AXI_WR_ST_RD_DATA_ENDDING= 8'b10000000;
always @(posedge clk or negedge dma_rstn_sync) begin
    if(~dma_rstn_sync) for(i=0;i<WR_INTERFACE_NUM;i=i+1)
        axi_wr_cu_st[i] <= AXI_WR_ST_FIRST_LOAD;
    else for(i=0;i<WR_INTERFACE_NUM;i=i+1)
        axi_wr_cu_st[i] <= axi_wr_nt_st[i];
end
always @(*) begin
    for(i=0;i<WR_INTERFACE_NUM;i=i+1)
    case (axi_wr_cu_st[i])
        AXI_WR_ST_FIRST_LOAD     : axi_wr_nt_st[i] = (wr_capture_rstn[i]) ? (AXI_WR_ST_LOAD_BURST):(AXI_WR_ST_FIRST_LOAD);
        AXI_WR_ST_IDLE           : axi_wr_nt_st[i] = (wr_capture_rstn[i]) ? (AXI_WR_ST_LOAD_BURST) : (AXI_WR_ST_FIRST_LOAD);
        AXI_WR_ST_LOAD_BURST     : axi_wr_nt_st[i] = (wr_capture_rstn[i]) ? ((wr_data_burst_valid[i] && wr_data_burst_ready[i]) ? ((need_second_rd[i])?(AXI_WR_ST_RD_ADDR_END):(AXI_WR_ST_RD_ADDR)):(AXI_WR_ST_LOAD_BURST)) : (AXI_WR_ST_FIRST_LOAD);
        AXI_WR_ST_RD_ADDR        : axi_wr_nt_st[i] = ((wr_channel == i) && MASTER_RD_ADDR_VALID && MASTER_RD_ADDR_READY) ? (AXI_WR_ST_RD_DATA) : (AXI_WR_ST_RD_ADDR);
        AXI_WR_ST_RD_DATA        : axi_wr_nt_st[i] = ((wr_channel == i) && MASTER_RD_DATA_VALID && MASTER_RD_DATA_READY && MASTER_RD_DATA_LAST) ? (AXI_WR_ST_IDLE) : (AXI_WR_ST_RD_DATA);
        AXI_WR_ST_RD_ADDR_END    : axi_wr_nt_st[i] = ((wr_channel == i) && MASTER_RD_ADDR_VALID && MASTER_RD_ADDR_READY) ? (AXI_WR_ST_RD_DATA_END) : (AXI_WR_ST_RD_ADDR_END);
        AXI_WR_ST_RD_DATA_END    : axi_wr_nt_st[i] = ((wr_channel == i) && MASTER_RD_DATA_VALID && MASTER_RD_DATA_READY && MASTER_RD_DATA_LAST) ? (AXI_WR_ST_RD_DATA_ENDDING) : (AXI_WR_ST_RD_DATA_END);
        AXI_WR_ST_RD_DATA_ENDDING: axi_wr_nt_st[i] = AXI_WR_ST_RD_ADDR;
        default                  : axi_wr_nt_st[i] = AXI_WR_ST_FIRST_LOAD;
    endcase
end

//wr_addr_reset_d
always @(posedge clk or negedge dma_rstn_sync) begin
    if(~dma_rstn_sync) for(i=0;i<WR_INTERFACE_NUM;i=i+1) wr_addr_reset_d[i] <= 0;
    else for(i=0;i<WR_INTERFACE_NUM;i=i+1) begin
        if(wr_addr_reset[i]) wr_addr_reset_d[i] <= 1;
        else if(axi_wr_nt_st[i] == AXI_WR_ST_LOAD_BURST) wr_addr_reset_d[i] <= 0;
        else wr_addr_reset_d[i] <= wr_addr_reset_d[i];
    end
end

always @(posedge clk or negedge dma_rstn_sync) begin
    if(~dma_rstn_sync) wr_channel_lock <= 0;
    else for(i=0;i<WR_INTERFACE_NUM;i=i+1) if(wr_channel == i) begin
        if(axi_wr_cu_st[i] == AXI_WR_ST_IDLE) wr_channel_lock <= 0; //传输结束，传输通道解锁
        else if(axi_wr_cu_st[i] == AXI_WR_ST_RD_ADDR || axi_wr_cu_st[i] == AXI_WR_ST_RD_ADDR_END)
              wr_channel_lock <= 1; //开始传输，传输通道加锁
        else  wr_channel_lock <= wr_channel_lock;
    end 
end
always @(posedge clk or negedge dma_rstn_sync) begin
    if(~dma_rstn_sync) wr_channel <= 0;
    else if(WR_INTERFACE_NUM == 1) wr_channel <= 0; //如果只有一个通道，直接锁定
    else if(wr_channel_lock) wr_channel <= wr_channel;
    else for(i=0;i<WR_INTERFACE_NUM;i=i+1) begin
        if(axi_wr_cu_st[i] == AXI_WR_ST_RD_ADDR || axi_wr_cu_st[i] == AXI_WR_ST_RD_ADDR_END)
            wr_channel <= i[WR_INTERFACE_NUM-1:0];
    end
end

always @(posedge clk or negedge dma_rstn_sync) begin
    if(~dma_rstn_sync) for(i=0;i<WR_INTERFACE_NUM;i=i+1) begin
        rd_addr_load[i] <= 0;
    end else for(i=0;i<WR_INTERFACE_NUM;i=i+1) begin
        if((axi_wr_nt_st[i] == AXI_WR_ST_LOAD_BURST) && wr_addr_reset_d[i]) begin
            rd_addr_load[i] <= START_READ_ADDR[i];
        end else if((axi_wr_cu_st[i] == AXI_WR_ST_FIRST_LOAD) && (axi_wr_nt_st[i] == AXI_WR_ST_LOAD_BURST)) begin
            rd_addr_load[i] <= START_READ_ADDR[i];
        end else if((axi_wr_cu_st[i] == AXI_WR_ST_RD_DATA_END) && (axi_wr_nt_st[i] == AXI_WR_ST_RD_DATA_ENDDING)) begin
            rd_addr_load[i] <= START_READ_ADDR[i];
        end else if((axi_wr_cu_st[i] == AXI_WR_ST_RD_DATA) && (axi_wr_nt_st[i] == AXI_WR_ST_IDLE)) begin
            //rd_addr_load + rd_len_load + 1 是下一次读的起始地址（如果没到边界）
            if(rd_addr_load[i] + rd_len_load[i] + 1 > END_READ_ADDR[i]) 
                 rd_addr_load[i] <= START_READ_ADDR[i];
            else rd_addr_load[i] <= rd_addr_load[i] + (rd_len_load[i] + 1);
        end else rd_addr_load[i] <= rd_addr_load[i];
    end
end

always @(*) begin
    for(i=0;i<WR_INTERFACE_NUM;i=i+1)
        need_second_rd[i] = (rd_addr_load[i] + wr_data_burst[i] > END_READ_ADDR[i]) ? 1'b1 : 1'b0;
end
//update when LOAD_BURST -> WR_ADDR, or WR_RESP_END -> WR_ADDR
always @(posedge clk or negedge dma_rstn_sync) begin
    if(~dma_rstn_sync) for(i=0;i<WR_INTERFACE_NUM;i=i+1) begin
        rd_len_load[i] <= 0;
    end else for(i=0;i<WR_INTERFACE_NUM;i=i+1) begin
        if((axi_wr_cu_st[i] == AXI_WR_ST_LOAD_BURST) && (wr_data_burst_valid[i] && wr_data_burst_ready[i])) begin
            rd_len_load[i] <= (need_second_rd[i]) ? (END_READ_ADDR[i] - rd_addr_load[i]) : wr_data_burst[i];
        end else if((axi_wr_cu_st[i] == AXI_WR_ST_RD_DATA_END) && (axi_wr_nt_st[i] == AXI_WR_ST_RD_DATA_ENDDING)) begin
            rd_len_load[i] <= wr_data_burst_load[i] - (rd_len_load[i] + 1);
        end else rd_len_load[i] <= rd_len_load[i];
    end
end

always_comb begin: MASTER_READ_CHANNEL
    int comb_i;
    MASTER_RD_ADDR_ID    = 1;
    MASTER_RD_ADDR_BURST = 2'b01;
    MASTER_RD_ADDR       = 0;
    MASTER_RD_ADDR_LEN   = 0;
    MASTER_RD_ADDR_VALID = 0;
    MASTER_RD_DATA_READY = 0;
    if(wr_channel_lock) begin
        for(comb_i=0;comb_i<WR_INTERFACE_NUM;comb_i=comb_i+1) if(wr_channel == comb_i) begin
        MASTER_RD_ADDR       = rd_addr_load[comb_i];
        MASTER_RD_ADDR_LEN   = rd_len_load[comb_i];
        MASTER_RD_ADDR_VALID = (axi_wr_cu_st[comb_i] == AXI_WR_ST_RD_ADDR) || (axi_wr_cu_st[comb_i] == AXI_WR_ST_RD_ADDR_END);
        MASTER_RD_DATA_READY = (axi_wr_cu_st[comb_i] == AXI_WR_ST_RD_DATA || axi_wr_cu_st[comb_i] == AXI_WR_ST_RD_DATA_END) && (wr_data_ready[comb_i] || (~wr_capture_rstn[comb_i]));
        end
    end
end

always @(*) begin
    for(i=0;i<WR_INTERFACE_NUM;i=i+1) begin
        wr_data_burst_ready[i] = (axi_wr_cu_st[i] == AXI_WR_ST_LOAD_BURST) & wr_capture_rstn[i];
        wr_data[i]             = MASTER_RD_DATA;
        wr_data_last[i]        = ((wr_channel == i) & wr_channel_lock)?((axi_wr_cu_st[i] == AXI_WR_ST_RD_DATA) && MASTER_RD_DATA_LAST):(0);
        wr_data_valid[i]       = ((wr_channel == i) & wr_channel_lock)?((wr_capture_rstn[i]) && ((axi_wr_cu_st[i] == AXI_WR_ST_RD_DATA || axi_wr_cu_st[i] == AXI_WR_ST_RD_DATA_END) && (MASTER_RD_DATA_VALID))):(0);
        wr_rstn[i]             = dma_rstn_sync & wr_capture_rstn[i];
    end
end

always @(posedge clk or negedge dma_rstn_sync) begin
    if(~dma_rstn_sync) for(i=0;i<WR_INTERFACE_NUM;i=i+1) wr_data_burst_load[i] <= 0;
    else for(i=0;i<WR_INTERFACE_NUM;i=i+1) begin
        if((axi_wr_cu_st[i] == AXI_WR_ST_LOAD_BURST) && wr_data_burst_valid[i] && wr_data_burst_ready[i])
             wr_data_burst_load[i] <= wr_data_burst[i];
        else wr_data_burst_load[i] <= wr_data_burst_load[i];
    end
end


endmodule