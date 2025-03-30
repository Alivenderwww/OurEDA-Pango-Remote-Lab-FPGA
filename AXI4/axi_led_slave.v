/*
axi_led_slave模块，作为AXI从机提供操纵LED的地址
可用于写地址和写数据功能的验证
小眼睛的100H有8个LED
野火的有4个
这里为LED分配地址为 OFFSET + 32'h00000000
即最多连32个灯
*/
module axi_led_slave #(
    parameter OFFSET_ADDR = 32'h2000_0000
)(
    input  wire        clk                ,
    input  wire        rstn               ,
    output  reg [31:0] led                ,

    output wire        LED_SLAVE_CLK          , //向AXI总线提供的本主机时钟信号
    output wire        LED_SLAVE_RSTN         , //向AXI总线提供的本主机复位信号

    input  wire [ 3:0] LED_SLAVE_WR_ADDR_ID   , //写地址通道-ID
    input  wire [31:0] LED_SLAVE_WR_ADDR      , //写地址通道-地址
    input  wire [ 7:0] LED_SLAVE_WR_ADDR_LEN  , //写地址通道-突发长度-最小为0（1突发），最大为255（256突发）
    input  wire [ 1:0] LED_SLAVE_WR_ADDR_BURST, //写地址通道-突发类型
    input  wire        LED_SLAVE_WR_ADDR_VALID, //写地址通道-握手信号-有效
    output wire        LED_SLAVE_WR_ADDR_READY, //写地址通道-握手信号-准备

    input  wire [31:0] LED_SLAVE_WR_DATA      , //写数据通道-数据
    input  wire [ 3:0] LED_SLAVE_WR_STRB      , //写数据通道-选通
    input  wire        LED_SLAVE_WR_DATA_LAST , //写数据通道-last信号
    input  wire        LED_SLAVE_WR_DATA_VALID, //写数据通道-握手信号-有效
    output wire        LED_SLAVE_WR_DATA_READY, //写数据通道-握手信号-准备

    output wire [ 3:0] LED_SLAVE_WR_BACK_ID   , //写响应通道-ID
    output wire [ 1:0] LED_SLAVE_WR_BACK_RESP , //写响应通道-响应 //SLAVE_WR_DATA_LAST拉高的同时或者之后 00 01正常 10写错误 11地址有问题找不到从机
    output wire        LED_SLAVE_WR_BACK_VALID, //写响应通道-握手信号-有效
    input  wire        LED_SLAVE_WR_BACK_READY, //写响应通道-握手信号-准备

    input  wire [ 3:0] LED_SLAVE_RD_ADDR_ID   , //读地址通道-ID
    input  wire [31:0] LED_SLAVE_RD_ADDR      , //读地址通道-地址
    input  wire [ 7:0] LED_SLAVE_RD_ADDR_LEN  , //读地址通道-突发长度。最小为0（1突发），最大为255（256突发）
    input  wire [ 1:0] LED_SLAVE_RD_ADDR_BURST, //读地址通道-突发类型。
    input  wire        LED_SLAVE_RD_ADDR_VALID, //读地址通道-握手信号-有效
    output wire        LED_SLAVE_RD_ADDR_READY, //读地址通道-握手信号-准备

    output wire [ 3:0] LED_SLAVE_RD_BACK_ID   , //读数据通道-ID
    output wire [31:0] LED_SLAVE_RD_DATA      , //读数据通道-数据
    output wire [ 1:0] LED_SLAVE_RD_DATA_RESP , //读数据通道-响应
    output wire        LED_SLAVE_RD_DATA_LAST , //读数据通道-last信号
    output wire        LED_SLAVE_RD_DATA_VALID, //读数据通道-握手信号-有效
    input  wire        LED_SLAVE_RD_DATA_READY  //读数据通道-握手信号-准备
);
localparam BASE_LED_ADDR = 32'h0000_0000;
localparam REAL_LED_ADDR = OFFSET_ADDR + BASE_LED_ADDR;

assign LED_SLAVE_CLK = clk;
assign LED_SLAVE_RSTN = rstn;

reg  [ 3:0] wr_addr_id;   
reg  [31:0] wr_addr;
reg  [ 1:0] wr_addr_burst;
reg         wr_error_detect;
reg  [ 1:0] cu_wr_st, nt_wr_st;
localparam ST_WR_IDLE = 2'b01,
           ST_WR_DATA = 2'b10,
           ST_WR_RESP = 2'b11;

reg  [ 3:0] rd_addr_id;   
reg  [31:0] rd_addr;
reg  [ 7:0] rd_addr_len;
reg  [ 1:0] rd_addr_burst;
reg         rd_error_detect, rd_error_detect_reg;
reg  [ 7:0] trans_num;
reg         cu_rd_st, nt_rd_st;
localparam ST_RD_IDLE = 1'b0,
           ST_RD_DATA = 1'b1;

//___________________写通道___________________//

always @(*) begin
    if(~rstn) nt_wr_st <= ST_WR_IDLE;
    else case (cu_wr_st)
        ST_WR_IDLE: nt_wr_st <= (LED_SLAVE_WR_ADDR_READY && LED_SLAVE_WR_ADDR_VALID)?(ST_WR_DATA):(ST_WR_IDLE);
        ST_WR_DATA: nt_wr_st <= (LED_SLAVE_WR_DATA_READY && LED_SLAVE_WR_DATA_VALID && LED_SLAVE_WR_DATA_LAST)?(ST_WR_RESP):(ST_WR_DATA);
        ST_WR_RESP: nt_wr_st <= (LED_SLAVE_WR_BACK_READY && LED_SLAVE_WR_BACK_VALID)?(ST_WR_IDLE):(ST_WR_RESP);
        default:    nt_wr_st <= ST_WR_IDLE;
    endcase
end
always @(posedge clk) cu_wr_st <= nt_wr_st;

always @(posedge clk) begin
    if(~rstn) begin
        wr_addr_id <= 0;
        wr_addr_burst <= 0;
    end else if(LED_SLAVE_WR_ADDR_READY && LED_SLAVE_WR_ADDR_VALID)begin
        wr_addr_id <= LED_SLAVE_WR_ADDR_ID;
        wr_addr_burst <= LED_SLAVE_WR_ADDR_BURST;
    end else begin
        wr_addr_id <= wr_addr_id;
        wr_addr_burst <= wr_addr_burst;
    end
end

always @(posedge clk) begin
    if(~rstn) wr_addr <= 0;
    else if(LED_SLAVE_WR_ADDR_READY && LED_SLAVE_WR_ADDR_VALID) wr_addr <= LED_SLAVE_WR_ADDR;
    else if((cu_wr_st == ST_WR_DATA) && LED_SLAVE_WR_DATA_READY && LED_SLAVE_WR_DATA_VALID && (wr_addr_burst == 2'b01)) wr_addr <= wr_addr + 1;
    else wr_addr <= wr_addr;
end

always @(posedge clk) begin
    if((~rstn) || (cu_wr_st == ST_WR_IDLE)) wr_error_detect <= 0;
    else if(cu_wr_st == ST_WR_DATA)begin
        if((wr_addr_burst == 2'b10) || (wr_addr_burst == 2'b11)) wr_error_detect <= 1;
        else if(wr_addr != REAL_LED_ADDR) wr_error_detect <= 1;
    end else wr_error_detect <= wr_error_detect;
end

assign LED_SLAVE_WR_ADDR_READY = (cu_wr_st == ST_WR_IDLE);
assign LED_SLAVE_WR_DATA_READY = (cu_wr_st == ST_WR_DATA);
assign LED_SLAVE_WR_BACK_ID    = wr_addr_id;
assign LED_SLAVE_WR_BACK_RESP  = (wr_error_detect)?(2'b10):(2'b00);
assign LED_SLAVE_WR_BACK_VALID = (cu_wr_st == ST_WR_RESP);

//___________________读通道___________________//

always @(posedge clk) begin
    if(~rstn) led <= 0;
    else if(LED_SLAVE_WR_DATA_READY && LED_SLAVE_WR_DATA_VALID && (wr_addr == REAL_LED_ADDR))begin
        led <= LED_SLAVE_WR_DATA;
        $display("%m: at time %0t INFO: led slave recv write data %h", $time, LED_SLAVE_WR_DATA);
    end else led <= led;
end

always @(*) begin
    if(~rstn) nt_rd_st <= ST_RD_IDLE;
    else case (cu_rd_st)
        ST_RD_IDLE: nt_rd_st <= (LED_SLAVE_RD_ADDR_READY && LED_SLAVE_RD_ADDR_VALID)?(ST_RD_DATA):(ST_RD_IDLE);
        ST_RD_DATA: nt_rd_st <= (LED_SLAVE_RD_DATA_READY && LED_SLAVE_RD_DATA_VALID && LED_SLAVE_RD_DATA_LAST)?(ST_RD_IDLE):(ST_RD_DATA);
    endcase
end
always @(posedge clk) cu_rd_st <= nt_rd_st;

always @(posedge clk) begin
    if(~rstn) begin
        rd_addr_id <= 0;
        rd_addr_burst <= 0;
        rd_addr_len <= 0;
    end else if(LED_SLAVE_RD_ADDR_READY && LED_SLAVE_RD_ADDR_VALID)begin
        rd_addr_id <= LED_SLAVE_RD_ADDR_ID;
        rd_addr_burst <= LED_SLAVE_RD_ADDR_BURST;
        rd_addr_len <= LED_SLAVE_RD_ADDR_LEN;
    end else begin
        rd_addr_id <= rd_addr_id;
        rd_addr_burst <= rd_addr_burst;
        rd_addr_len <= rd_addr_len;
    end
end

always @(posedge clk) begin
    if(~rstn) rd_addr <= 0;
    else if(LED_SLAVE_RD_ADDR_READY && LED_SLAVE_RD_ADDR_VALID) rd_addr <= LED_SLAVE_RD_ADDR;
    else if((cu_rd_st == ST_RD_DATA) && LED_SLAVE_RD_DATA_READY && LED_SLAVE_RD_DATA_VALID && (rd_addr_burst == 2'b01)) rd_addr <= rd_addr + 1;
    else rd_addr <= rd_addr;
end

always @(posedge clk) begin
    if((~rstn) || (cu_rd_st == ST_RD_IDLE)) trans_num <= 0;
    else if(LED_SLAVE_RD_DATA_READY && LED_SLAVE_RD_DATA_VALID) trans_num <= trans_num + 1;
    else trans_num <= trans_num;
end

always @(*) begin
    if((~rstn) || (cu_rd_st == ST_RD_IDLE)) rd_error_detect <= 0;
    else if(cu_rd_st == ST_RD_DATA)begin
        if((rd_addr_burst == 2'b10) || (rd_addr_burst) == 2'b11) rd_error_detect <= 1;
        else if(rd_addr != REAL_LED_ADDR) rd_error_detect <= 1;
    end else rd_error_detect <= 0;
end
always @(posedge clk) rd_error_detect_reg <= rd_error_detect;

assign LED_SLAVE_RD_ADDR_READY = (cu_rd_st == ST_RD_IDLE);
assign LED_SLAVE_RD_BACK_ID    = rd_addr_id;
assign LED_SLAVE_RD_DATA       = (rd_addr == REAL_LED_ADDR)?(led):(32'hFFFFFFFF);
assign LED_SLAVE_RD_DATA_RESP  = (rd_error_detect || rd_error_detect_reg)?(2'b10):(2'b00);
assign LED_SLAVE_RD_DATA_LAST  = (LED_SLAVE_RD_DATA_VALID && (trans_num == rd_addr_len));
assign LED_SLAVE_RD_DATA_VALID = (cu_rd_st == ST_RD_DATA);


endmodule