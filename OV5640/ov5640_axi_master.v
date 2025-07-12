module ov5640_axi_master(
    input wire        clk,
    input wire        rstn,

    //camera interface (no need iic)
    input  wire       CCD_RSTN,
    input  wire       CCD_PCLK,
    input  wire       CCD_VSYNC,
    input  wire       CCD_HSYNC, //原理图把HREF和HSYNC搞混了
    input  wire [7:0] CCD_DATA,

    //input base and end address
    input  wire [31:0] STORE_BASE_ADDR,
    input  wire [31:0] STORE_NUM, //256*4bytes
    input  wire        capture_on,
    input  wire [15:0] expect_width, //期望宽度
    input  wire [15:0] expect_height, //期望高度

    //AXI MASTER interface
    output wire         MASTER_CLK          ,
    output wire         MASTER_RSTN         ,
    output wire [2-1:0] MASTER_WR_ADDR_ID   ,
    output wire [31:0]  MASTER_WR_ADDR      ,
    output wire [ 7:0]  MASTER_WR_ADDR_LEN  ,
    output wire [ 1:0]  MASTER_WR_ADDR_BURST,
    output wire         MASTER_WR_ADDR_VALID,
    input  wire         MASTER_WR_ADDR_READY,
    output wire [31:0]  MASTER_WR_DATA      ,
    output wire [ 3:0]  MASTER_WR_STRB      ,
    output wire         MASTER_WR_DATA_LAST ,
    output wire         MASTER_WR_DATA_VALID,
    input  wire         MASTER_WR_DATA_READY,
    input  wire [2-1:0] MASTER_WR_BACK_ID   ,
    input  wire [ 1:0]  MASTER_WR_BACK_RESP ,
    input  wire         MASTER_WR_BACK_VALID,
    output wire         MASTER_WR_BACK_READY,
    output wire [2-1:0] MASTER_RD_ADDR_ID   ,
    output wire [31:0]  MASTER_RD_ADDR      ,
    output wire [ 7:0]  MASTER_RD_ADDR_LEN  ,
    output wire [ 1:0]  MASTER_RD_ADDR_BURST,
    output wire         MASTER_RD_ADDR_VALID,
    input  wire         MASTER_RD_ADDR_READY,
    input  wire [2-1:0] MASTER_RD_BACK_ID   ,
    input  wire [31:0]  MASTER_RD_DATA      ,
    input  wire [ 1:0]  MASTER_RD_DATA_RESP ,
    input  wire         MASTER_RD_DATA_LAST ,
    input  wire         MASTER_RD_DATA_VALID,
    output wire         MASTER_RD_DATA_READY);

wire ov_rstn_sync;
rstn_sync rstn_sync_ov(clk, rstn, ov_rstn_sync);

assign MASTER_CLK  = clk;
assign MASTER_RSTN = ov_rstn_sync;

//OV5640作为AXI主机只需要维护写地址通道、写数据通道和写响应通道。
assign MASTER_RD_ADDR_ID    = 0;
assign MASTER_RD_ADDR       = 0;
assign MASTER_RD_ADDR_LEN   = 0;
assign MASTER_RD_ADDR_BURST = 0;
assign MASTER_RD_ADDR_VALID = 0;
assign MASTER_RD_DATA_READY = 1;

wire            rd_data_en;
wire        	almost_empty;
wire [31:0] 	rd_data;

reg [31:0] wr_addr_load;
reg [7:0] wr_len_load;

reg [1:0] axi_cu_st, axi_nt_st;
localparam AXI_ST_IDLE    = 2'b00,
           AXI_ST_WR_ADDR = 2'b01,
           AXI_ST_WR_DATA = 2'b10,
           AXI_ST_WR_RESP = 2'b11;
always @(posedge clk or negedge ov_rstn_sync) begin
    if(~ov_rstn_sync) axi_cu_st <= AXI_ST_IDLE;
    else axi_cu_st <= axi_nt_st;
end
always @(*) begin
    case (axi_cu_st)
        AXI_ST_IDLE   : axi_nt_st = ((capture_on) && (~almost_empty)) ? (AXI_ST_WR_ADDR) : (AXI_ST_IDLE);
        AXI_ST_WR_ADDR: axi_nt_st = (MASTER_WR_ADDR_VALID && MASTER_WR_ADDR_READY) ? (AXI_ST_WR_DATA) : (AXI_ST_WR_ADDR);
        AXI_ST_WR_DATA: axi_nt_st = (MASTER_WR_DATA_VALID && MASTER_WR_DATA_READY && MASTER_WR_DATA_LAST) ? (AXI_ST_WR_RESP) : (AXI_ST_WR_DATA);
        AXI_ST_WR_RESP: axi_nt_st = (MASTER_WR_BACK_VALID && MASTER_WR_BACK_READY) ? (AXI_ST_IDLE) : (AXI_ST_WR_RESP);
    endcase
end

always @(posedge clk or negedge ov_rstn_sync) begin
    if(~ov_rstn_sync) wr_addr_load <= 0;
    else if((axi_cu_st == AXI_ST_IDLE) && (~capture_on)) wr_addr_load <= STORE_BASE_ADDR;
    else if((axi_cu_st == AXI_ST_WR_RESP) && (axi_nt_st == AXI_ST_IDLE)) begin
        if((wr_addr_load + 256) < (STORE_BASE_ADDR + STORE_NUM)) wr_addr_load <= wr_addr_load + 256;
        else wr_addr_load <= STORE_BASE_ADDR;
    end else wr_addr_load <= wr_addr_load;
end

always @(posedge clk or negedge ov_rstn_sync) begin
    if(~ov_rstn_sync) wr_len_load <= 0;
    else if((axi_cu_st == AXI_ST_IDLE) && (~almost_empty)) wr_len_load <= ~0;
    else if((axi_cu_st == AXI_ST_WR_DATA) && MASTER_WR_DATA_VALID && MASTER_WR_DATA_READY)
        wr_len_load <= (MASTER_WR_DATA_LAST) ? (wr_len_load) : (wr_len_load - 1);
    else wr_len_load <= wr_len_load;
end

assign MASTER_WR_ADDR_ID    = 0;
assign MASTER_WR_ADDR       = wr_addr_load;
assign MASTER_WR_ADDR_LEN   = ~0;
assign MASTER_WR_ADDR_BURST = 2'b01;
assign MASTER_WR_ADDR_VALID = (axi_cu_st == AXI_ST_WR_ADDR);
assign MASTER_WR_DATA_VALID = (axi_cu_st == AXI_ST_WR_DATA);
assign MASTER_WR_DATA_LAST  = (MASTER_WR_DATA_VALID && MASTER_WR_DATA_READY) && (wr_len_load == 0);
assign MASTER_WR_DATA       = rd_data;
assign MASTER_WR_STRB       = 4'b1111; //always write 32bit
assign MASTER_WR_BACK_READY = (axi_cu_st == AXI_ST_WR_RESP);

assign rd_data_en = (axi_cu_st == AXI_ST_WR_DATA) && MASTER_WR_DATA_READY && MASTER_WR_DATA_VALID;
ov56450_data_store u_ov56450_data_store(
	.clk          	( clk           ),
	.rstn         	( ov_rstn_sync  ),
	.CCD_RSTN      	( CCD_RSTN      ),
	.CCD_PCLK     	( CCD_PCLK      ),
	.CCD_VSYNC    	( CCD_VSYNC     ),
	.CCD_HSYNC    	( CCD_HSYNC     ),
	.CCD_DATA     	( CCD_DATA      ),
    .capture_on  	( capture_on    ),
    .expect_width   ( expect_width  ),
    .expect_height  ( expect_height ),
	.rd_data_en   	( rd_data_en    ),
	.almost_empty 	( almost_empty  ),
	.rd_data 	    ( rd_data       )
);


endmodule //ov5640_axi_master
