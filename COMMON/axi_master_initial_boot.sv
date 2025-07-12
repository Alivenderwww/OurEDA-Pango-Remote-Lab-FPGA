module axi_master_initial_boot #(
    parameter [31:0] I2C_EEPROM_SLAVE_BASEADDR = 32'h3000_0000 // I2C对应SLAVE的BASEADDR
)(
    input  wire          clk                 ,
    input  wire          rstn                ,
    // get ip and mac address from EEPROM
    output logic [31:0]  eeprom_host_ip      ,
    output logic [47:0]  eeprom_host_mac     ,
    output logic [31:0]  eeprom_board_ip     ,
    output logic [47:0]  eeprom_board_mac    ,
    // AXI Master Interface
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
在这里用作系统上电后自动从EEPROM中获取板卡的IP地址

读取的配置顺序
    // 写地址通道，id=0, addr=01, len=0, burst=01
    // 写数据通道，id=0, data={16'd1, 16'd7}, strb=1111
    //                   (读DUMMY为2字节，传输8字节有效数据)
    // 写地址通道，id=0, addr=03, len=5, burst=01
    // 写数据通道，id=0, data={24'h0, 8'h0},{24'h0, 8'h0}, strb=1111
    //                   (读DUMMY为0x00, 即读地址从0x00开始)
    // 写地址通道，id=0, addr=00, len=0, burst=01
    // 写数据通道，id=0, data={8'h1,8'h0,8'h1,1'b0,7'b1010_000}, strb=1111
    //                   (开启传输，I2C协议，读模式，I2C地址为1010_000)
    // 读地址通道，id=0, addr=04, len=3, burst=00 (读4字节数据)

    读地址通道，id=0, addr=32'hS0_A7_00_00, len=7, burst=00 (读8字节数据)
    读地址通道，接收8个32bit数据，低八位有效。
*/

localparam [6:0] I2C_EEPROM_SLAVE_ADDR = 7'b1010_011; // EEPROM的I2C地址
localparam [0:0] I2C_EEPROM_SLAVE_16B_ADDR_ENABLE = 1'b1;
localparam [31:0] I2C_EEPROM_SLAVE_OFFSET = {I2C_EEPROM_SLAVE_BASEADDR[31:24], 
                                       I2C_EEPROM_SLAVE_ADDR,
                                       I2C_EEPROM_SLAVE_16B_ADDR_ENABLE,
                                       16'b0};

wire dma_rstn_sync;
rstn_sync rstn_sync_dma(clk, rstn, dma_rstn_sync);

assign MASTER_CLK  = clk;
assign MASTER_RSTN = dma_rstn_sync;

assign MASTER_WR_ADDR_ID    = 0;
assign MASTER_WR_ADDR       = 0;
assign MASTER_WR_ADDR_LEN   = 0;
assign MASTER_WR_ADDR_BURST = 0;
assign MASTER_WR_ADDR_VALID = 0;
assign MASTER_WR_DATA       = 0;
assign MASTER_WR_STRB       = 0;
assign MASTER_WR_DATA_LAST  = 0;
assign MASTER_WR_DATA_VALID = 0;
assign MASTER_WR_BACK_READY = 1;

reg [31:0] rd_addr_load;
reg [7:0] rd_len_load;

reg [31:0] wait_count;

reg [1:0] axi_cu_st, axi_nt_st;
reg [2:0] dma_cu_st, dma_nt_st;
localparam AXI_ST_IDLE    = 2'b00,
           AXI_ST_RD_ADDR = 2'b01,
           AXI_ST_RD_DATA = 2'b10;
localparam DMA_ST_IDLE          = 3'b000,
           DMA_ST_GET_HOST_IP   = 3'b001,
           DMA_ST_GET_BOARD_IP  = 3'b010,
           DMA_ST_GET_HOST_MAC  = 3'b011,
           DMA_ST_GET_BOARD_MAC = 3'b100,
           DMA_ST_END           = 3'b101;

always @(posedge clk or negedge dma_rstn_sync) begin
    if(~dma_rstn_sync) axi_cu_st <= AXI_ST_IDLE;
    else axi_cu_st <= axi_nt_st;
end
always @(*) begin
    case (axi_cu_st)
        AXI_ST_IDLE   : axi_nt_st = (wait_count >= 32'h0003_FFFF)?(AXI_ST_RD_ADDR):(AXI_ST_IDLE);
        AXI_ST_RD_ADDR: axi_nt_st = (MASTER_RD_ADDR_VALID && MASTER_RD_ADDR_READY) ? (AXI_ST_RD_DATA) : (AXI_ST_RD_ADDR);
        AXI_ST_RD_DATA: axi_nt_st = (MASTER_RD_DATA_VALID && MASTER_RD_DATA_READY && MASTER_RD_DATA_LAST) ? (AXI_ST_IDLE) : (AXI_ST_RD_DATA);
        default       : axi_nt_st = AXI_ST_IDLE;
    endcase
end

always @(posedge clk or negedge dma_rstn_sync) begin
    if(~dma_rstn_sync) dma_cu_st <= DMA_ST_IDLE;
    else dma_cu_st <= dma_nt_st;
end
always @(*) begin
    case (dma_cu_st)
        DMA_ST_IDLE         : dma_nt_st = DMA_ST_GET_HOST_IP;
        DMA_ST_GET_HOST_IP  : dma_nt_st = ((axi_cu_st == AXI_ST_RD_DATA) && (axi_nt_st == AXI_ST_IDLE)) ? (DMA_ST_GET_BOARD_IP ) : (DMA_ST_GET_HOST_IP  );
        DMA_ST_GET_BOARD_IP : dma_nt_st = ((axi_cu_st == AXI_ST_RD_DATA) && (axi_nt_st == AXI_ST_IDLE)) ? (DMA_ST_GET_HOST_MAC ) : (DMA_ST_GET_BOARD_IP );
        DMA_ST_GET_HOST_MAC : dma_nt_st = ((axi_cu_st == AXI_ST_RD_DATA) && (axi_nt_st == AXI_ST_IDLE)) ? (DMA_ST_GET_BOARD_MAC) : (DMA_ST_GET_HOST_MAC );
        DMA_ST_GET_BOARD_MAC: dma_nt_st = ((axi_cu_st == AXI_ST_RD_DATA) && (axi_nt_st == DMA_ST_END)) ? (DMA_ST_IDLE) : (DMA_ST_GET_BOARD_MAC);
        DMA_ST_END          : dma_nt_st = DMA_ST_END;
        default             : dma_nt_st = DMA_ST_IDLE;
    endcase
end
always @(posedge clk or negedge dma_rstn_sync) begin
    if(~dma_rstn_sync) wait_count <= 0;
    else if(dma_cu_st == DMA_ST_IDLE) wait_count <= 0;
    else if(axi_cu_st == AXI_ST_IDLE) wait_count <= wait_count + 1;
    else wait_count <= 0;
end

always @(posedge clk or negedge dma_rstn_sync) begin
    if(~dma_rstn_sync) rd_addr_load <= 0;
    else if((axi_cu_st == AXI_ST_IDLE) && (axi_nt_st == AXI_ST_RD_ADDR)) begin
        case (dma_cu_st)
            DMA_ST_GET_HOST_IP  : rd_addr_load <= I2C_EEPROM_SLAVE_OFFSET + 0;
            DMA_ST_GET_BOARD_IP : rd_addr_load <= I2C_EEPROM_SLAVE_OFFSET + 4;
            DMA_ST_GET_HOST_MAC : rd_addr_load <= I2C_EEPROM_SLAVE_OFFSET + 8;
            DMA_ST_GET_BOARD_MAC: rd_addr_load <= I2C_EEPROM_SLAVE_OFFSET + 14;
            default             : rd_addr_load <= 0;
        endcase
    end else rd_addr_load <= rd_addr_load;
end

always @(posedge clk or negedge dma_rstn_sync) begin
    if(~dma_rstn_sync) rd_len_load <= 0;
    else if((axi_cu_st == AXI_ST_IDLE) && (axi_nt_st == AXI_ST_RD_ADDR)) case (dma_cu_st)
        DMA_ST_GET_HOST_IP  : rd_len_load <= 3;
        DMA_ST_GET_BOARD_IP : rd_len_load <= 3;
        DMA_ST_GET_HOST_MAC : rd_len_load <= 5;
        DMA_ST_GET_BOARD_MAC: rd_len_load <= 5;
        default             : rd_len_load <= 0;
    endcase else rd_len_load <= rd_len_load;
end

assign MASTER_RD_ADDR_ID    = 0;
assign MASTER_RD_ADDR       = rd_addr_load;
assign MASTER_RD_ADDR_LEN   = rd_len_load;
assign MASTER_RD_ADDR_BURST = 2'b01;
assign MASTER_RD_ADDR_VALID = (axi_cu_st == AXI_ST_RD_ADDR);
assign MASTER_RD_DATA_READY = (axi_cu_st == AXI_ST_RD_DATA);

always @(posedge clk or negedge dma_rstn_sync) begin
    if(~dma_rstn_sync) eeprom_host_ip <= 0;
    else if((dma_cu_st == DMA_ST_GET_HOST_IP) && (axi_cu_st == AXI_ST_RD_DATA) && (MASTER_RD_DATA_VALID && MASTER_RD_DATA_READY)) begin
        eeprom_host_ip <= {eeprom_host_ip[23:0],MASTER_RD_DATA[7:0]};
    end else eeprom_host_ip <= eeprom_host_ip;
end

always @(posedge clk or negedge dma_rstn_sync) begin
    if(~dma_rstn_sync) eeprom_board_ip <= 0;
    else if((dma_cu_st == DMA_ST_GET_BOARD_IP) && (axi_cu_st == AXI_ST_RD_DATA) && (MASTER_RD_DATA_VALID && MASTER_RD_DATA_READY)) begin
        eeprom_board_ip <= {eeprom_board_ip[23:0],MASTER_RD_DATA[7:0]};
    end else eeprom_board_ip <= eeprom_board_ip;
end

always @(posedge clk or negedge dma_rstn_sync) begin
    if(~dma_rstn_sync) eeprom_host_mac <= 0;
    else if((dma_cu_st == DMA_ST_GET_HOST_MAC) && (axi_cu_st == AXI_ST_RD_DATA) && (MASTER_RD_DATA_VALID && MASTER_RD_DATA_READY)) begin
        eeprom_host_mac <= {eeprom_host_mac[39:0],MASTER_RD_DATA[7:0]};
    end else eeprom_host_mac <= eeprom_host_mac;
end

always @(posedge clk or negedge dma_rstn_sync) begin
    if(~dma_rstn_sync) eeprom_board_mac <= 0;
    else if((dma_cu_st == DMA_ST_GET_HOST_MAC) && (axi_cu_st == AXI_ST_RD_DATA) && (MASTER_RD_DATA_VALID && MASTER_RD_DATA_READY)) begin
        eeprom_board_mac <= {eeprom_board_mac[39:0],MASTER_RD_DATA[7:0]};
    end else eeprom_board_mac <= eeprom_board_mac;
end

endmodule //axi_master_auto_dma
