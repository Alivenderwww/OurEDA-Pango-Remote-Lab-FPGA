module axi_master_write_dma (
    input  logic [31:0]  START_WRITE_ADDR    ,
    input  logic [31:0]  END_WRITE_ADDR      ,

    input  logic         clk,
    input  logic         rstn,

    output logic         rd_clk              ,
    input  logic         rd_capture_on       ,//capture on/off 是启动/暂停DMA传输，暂停期间rd_data_valid不会拉高接收数据，重新启动后从停止时的地址继续传输
    input  logic         rd_capture_rst      ,//capture reset 是DMA状态机复位，重新开始DMA传输，地址也会从START_WRITE_ADDR重新开始
    input  logic         rd_data_ready       ,
    output logic         rd_data_valid       ,
    input  logic [31:0]  rd_data             ,

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
/*
write dma 有一个FIFO读输入口和一个AXI MASTER写输出口
用于将FIFO内数据自动写入至AXI SLAVE中

当rd_data_ready为1时，表示FIFO内有数据可以读取，
rd_data_valid为1时，表示AXI可以读取FIFO内数据。
rd_capture_on为1开始转移，为0暂停转移，暂停转移期间rd_data_valid为0
rd_capture_rst为1清除dma状态机。
*/

localparam [7:0] MAX_BURST_LEN = 8'hFF; //最大突发长度

wire dma_rstn_sync;
rstn_sync rstn_sync_ov(clk, rstn, dma_rstn_sync);
reg rd_capture_rst_d;

assign MASTER_CLK  = clk;
assign MASTER_RSTN = dma_rstn_sync;
assign rd_clk = MASTER_CLK;

assign MASTER_RD_ADDR_ID    = 0;
assign MASTER_RD_ADDR       = 0;
assign MASTER_RD_ADDR_LEN   = 0;
assign MASTER_RD_ADDR_BURST = 0;
assign MASTER_RD_ADDR_VALID = 0;
assign MASTER_RD_DATA_READY = 1;

reg [31:0] wr_addr_load;
reg [7:0] wr_len_load, wr_len_load_count;

reg [2:0] axi_cu_st, axi_nt_st;
localparam AXI_ST_FIRST_LOAD = 3'b000,
           AXI_ST_IDLE       = 3'b001,
           AXI_ST_WR_ADDR    = 3'b010,
           AXI_ST_WR_DATA    = 3'b011,
           AXI_ST_WR_RESP    = 3'b100;
always @(posedge clk or negedge dma_rstn_sync) begin
    if(~dma_rstn_sync) axi_cu_st <= AXI_ST_FIRST_LOAD;
    else axi_cu_st <= axi_nt_st;
end
always @(*) begin
    case (axi_cu_st)
        AXI_ST_FIRST_LOAD : axi_nt_st = (rd_capture_on && (~rd_capture_rst) && (rd_data_ready)) ? (AXI_ST_WR_ADDR):(AXI_ST_FIRST_LOAD);
        AXI_ST_IDLE       : axi_nt_st = (rd_capture_rst) ? (AXI_ST_FIRST_LOAD) : ((rd_capture_on && (rd_data_ready)) ? (AXI_ST_WR_ADDR):(AXI_ST_IDLE));
        AXI_ST_WR_ADDR    : axi_nt_st = (MASTER_WR_ADDR_VALID && MASTER_WR_ADDR_READY) ? (AXI_ST_WR_DATA) : (AXI_ST_WR_ADDR);
        AXI_ST_WR_DATA    : axi_nt_st = (MASTER_WR_DATA_VALID && MASTER_WR_DATA_READY && MASTER_WR_DATA_LAST) ? (AXI_ST_WR_RESP) : (AXI_ST_WR_DATA);
        AXI_ST_WR_RESP    : axi_nt_st = (MASTER_WR_BACK_VALID && MASTER_WR_BACK_READY) ? (AXI_ST_IDLE) : (AXI_ST_WR_RESP);
    endcase
end
always @(posedge clk or negedge dma_rstn_sync) begin
    if(~dma_rstn_sync) rd_capture_rst_d <= 0;
    else if(rd_capture_rst) rd_capture_rst_d <= 1;
    else if(axi_cu_st == AXI_ST_FIRST_LOAD) rd_capture_rst_d <= 0;
    else rd_capture_rst_d <= rd_capture_rst_d;
end

always @(posedge clk or negedge dma_rstn_sync) begin
    if(~dma_rstn_sync) begin
        wr_addr_load <= 0;
    end else if((axi_cu_st == AXI_ST_FIRST_LOAD) && (axi_nt_st == AXI_ST_WR_ADDR)) begin
        wr_addr_load <= START_WRITE_ADDR;
    end else if((axi_cu_st == AXI_ST_WR_RESP) && (axi_nt_st == AXI_ST_IDLE)) begin
        //wr_addr_load + wr_len_load + 1 是下一次写入的起始地址（如果没到边界）
        if(wr_addr_load + wr_len_load + 1 > END_WRITE_ADDR) wr_addr_load <= START_WRITE_ADDR;
        else wr_addr_load <= wr_addr_load + wr_len_load + 1;
    end else wr_addr_load <= wr_addr_load;
end

always @(posedge clk or negedge dma_rstn_sync) begin
    if(~dma_rstn_sync) begin
        wr_len_load <= 0;
    end else if((axi_cu_st == AXI_ST_FIRST_LOAD) && (axi_nt_st == AXI_ST_WR_ADDR)) begin
        wr_len_load <= (START_WRITE_ADDR + MAX_BURST_LEN > END_WRITE_ADDR) ? (END_WRITE_ADDR - START_WRITE_ADDR) : MAX_BURST_LEN;
    end else if((axi_cu_st == AXI_ST_IDLE) && (axi_nt_st == AXI_ST_WR_ADDR)) begin
        wr_len_load  <= (wr_addr_load + MAX_BURST_LEN > END_WRITE_ADDR) ? (END_WRITE_ADDR - wr_addr_load) : MAX_BURST_LEN;
    end else wr_len_load <= wr_len_load;
end

always @(posedge clk or negedge dma_rstn_sync) begin
    if(~dma_rstn_sync) wr_len_load_count <= 0;
    else if((axi_cu_st == AXI_ST_WR_ADDR) && MASTER_WR_ADDR_VALID && MASTER_WR_ADDR_READY)
        wr_len_load_count <= wr_len_load;
    else if((axi_cu_st == AXI_ST_WR_DATA) && MASTER_WR_DATA_VALID && MASTER_WR_DATA_READY)
        wr_len_load_count <= (MASTER_WR_DATA_LAST) ? (wr_len_load_count) : (wr_len_load_count - 1);
    else wr_len_load_count <= wr_len_load_count;
end

assign rd_data_valid        = (~rd_capture_rst_d) && ((axi_cu_st == AXI_ST_WR_DATA) && (MASTER_WR_DATA_READY));
assign MASTER_WR_ADDR_ID    = 0;
assign MASTER_WR_ADDR       = wr_addr_load;
assign MASTER_WR_ADDR_LEN   = wr_len_load;
assign MASTER_WR_ADDR_BURST = 2'b01;
assign MASTER_WR_ADDR_VALID = (axi_cu_st == AXI_ST_WR_ADDR);
assign MASTER_WR_DATA_VALID = (axi_cu_st == AXI_ST_WR_DATA) && (rd_data_ready || rd_capture_rst_d);
assign MASTER_WR_DATA_LAST  = (MASTER_WR_DATA_VALID && MASTER_WR_DATA_READY) && (wr_len_load_count == 0);
assign MASTER_WR_DATA       = rd_data;
assign MASTER_WR_STRB       = 4'b1111; //always write 32bit
assign MASTER_WR_BACK_READY = (axi_cu_st == AXI_ST_WR_RESP);

assign rd_data_en = (axi_cu_st == AXI_ST_WR_DATA) && MASTER_WR_DATA_READY && MASTER_WR_DATA_VALID;
    
endmodule