`timescale 1ns/1ps
module axi_master_sim (//模拟AXI-MASTER时序，时钟域为clk
    input  wire        clk          ,
    input  wire        rst          ,

    //___________________AXI接口_____________________//
    output wire        MASTER_CLK          , //向AXI总线提供的本主机时钟信号
    output wire        MASTER_RSTN         , //向AXI总线提供的本主机复位信号

    output wire [ 1:0] MASTER_WR_ADDR_ID   , //写地址通道-ID
    output wire [31:0] MASTER_WR_ADDR      , //写地址通道-地址
    output wire [ 7:0] MASTER_WR_ADDR_LEN  , //写地址通道-突发长度-最小为0（1突发），最大为255（256突发）
    output wire [ 1:0] MASTER_WR_ADDR_BURST, //写地址通道-突发类型
    output wire        MASTER_WR_ADDR_VALID, //写地址通道-握手信号-有效
    input  wire        MASTER_WR_ADDR_READY, //写地址通道-握手信号-准备

    output wire [ 1:0] MASTER_WR_DATA_ID   , //写数据通道-ID
    output wire [31:0] MASTER_WR_DATA      , //写数据通道-数据
    output wire [ 3:0] MASTER_WR_STRB      , //写数据通道-选通
    output wire        MASTER_WR_DATA_LAST , //写数据通道-last信号
    output wire        MASTER_WR_DATA_VALID, //写数据通道-握手信号-有效
    input  wire        MASTER_WR_DATA_READY, //写数据通道-握手信号-准备

    input  wire [ 3:0] MASTER_WR_BACK_ID   , //写响应通道-ID
    input  wire [ 1:0] MASTER_WR_BACK_RESP , //写响应通道-响应
    input  wire        MASTER_WR_BACK_VALID, //写响应通道-握手信号-有效
    output wire        MASTER_WR_BACK_READY, //写响应通道-握手信号-准备

    output wire [ 1:0] MASTER_RD_ADDR_ID   , //读地址通道-ID
    output wire [31:0] MASTER_RD_ADDR      , //读地址通道-地址
    output wire [ 7:0] MASTER_RD_ADDR_LEN  , //读地址通道-突发长度。最小为0（1突发），最大为255（256突发）
    output wire [ 1:0] MASTER_RD_ADDR_BURST, //读地址通道-突发类型。
    output wire        MASTER_RD_ADDR_VALID, //读地址通道-握手信号-有效
    input  wire        MASTER_RD_ADDR_READY, //读地址通道-握手信号-准备

    input  wire [ 1:0] MASTER_RD_BACK_ID   , //读数据通道-ID
    input  wire [31:0] MASTER_RD_DATA      , //读数据通道-数据
    input  wire [ 1:0] MASTER_RD_DATA_RESP , //读数据通道-响应
    input  wire        MASTER_RD_DATA_LAST , //读数据通道-last信号
    input  wire        MASTER_RD_DATA_VALID, //读数据通道-握手信号-有效
    output wire        MASTER_RD_DATA_READY  //读数据通道-握手信号-准备
);

///////////////////////////////////////////////////////////////
//参考样式
// initial begin
//     #50000
//     send_wr_addr(32'h00000170, 111, 0);
//     send_wr_data(32'h00000000, 100, 4'b1111, 0);
//     send_rd_addr(32'h00000170, 111, 0);
//     recv_rd_data(0);
// end
///////////////////////////////////////////////////////////////

localparam BUFF_WIDTH = 10;
reg [9:0] wr_channel_buff[2**BUFF_WIDTH-1:0];
reg [BUFF_WIDTH:0] wr_channel_wrptr, wr_channel_rdptr, wr_channel_respptr;
wire wr_channel_buff_full  = (wr_channel_wrptr ^ wr_channel_respptr == {1'b1,{(BUFF_WIDTH-1){1'b0}}});
wire wr_channel_buff_empty = (wr_channel_wrptr == wr_channel_respptr);
initial begin
    wr_channel_wrptr   = 0;
    wr_channel_respptr = 0;
end
always @(posedge clk) begin
    if(MASTER_WR_ADDR_VALID && MASTER_WR_ADDR_READY)begin
        if(wr_channel_buff_full) ; //ERROR 记录事务失败，MASTER写地址通道事务已满，请完成先前的事务再发送新事务。
        else begin
            wr_channel_wrptr <= wr_channel_wrptr + 1;
            wr_channel_buff[wr_channel_wrptr[BUFF_WIDTH-1:0]] <= {MASTER_WR_ADDR_LEN, MASTER_WR_ADDR_ID};
        end
    end
end
always @(posedge clk) begin
    if(MASTER_WR_BACK_VALID && MASTER_WR_BACK_READY)begin
        if(wr_channel_buff_empty) ; //ERROR 事务列表为空
        else begin
            if(wr_channel_buff[wr_channel_rdptr[BUFF_WIDTH-1:0]][1:0] != MASTER_WR_BACK_ID) ; //ERROR 事务执行顺序错误
            wr_channel_rdptr <= wr_channel_rdptr + 1;
        end
    end
end

/*
MASTER的写地址线通道传输一次。
指定ID，ADDR，LEN，BURST。
同时将ID，LEN存入写通道暂存fifo。
握手成功后解除堵塞状态。
*/
task send_wr_addr;
    input [ 1:0] id;
    input [31:0] addr;
    input [ 7:0] len;
    input [ 1:0] burst;
    begin
        @(posedge clk) begin
            MASTER_WR_ADDR_ID    <= id;
            MASTER_WR_ADDR       <= addr;
            MASTER_WR_ADDR_LEN   <= len;
            MASTER_WR_ADDR_BURST <= burst;
            MASTER_WR_ADDR_VALID <= 1;
        end
        while(~(MASTER_WR_ADDR_VALID && MASTER_WR_ADDR_READY))begin
            @(posedge clk);
        end
        @(negedge clk) MASTER_WR_ADDR_VALID <= 0;
    end
endtask

task send_rd_addr; //MASTER的读地址线通道传输一次。指定WR_ADDR，WR_LEN，WR_ID。
    input [31:0] rd_addr;
    input [ 7:0] rd_len;
    input [ 1:0] rd_id;
    begin
        @(posedge clk) begin
            RD_ADDR <= rd_addr;
            RD_LEN  <= rd_len;
            RD_ID   <= rd_id;
            RD_ADDR_VALID <= 1;
        end
        while(~(RD_ADDR_READY && RD_ADDR_VALID))begin
            @(posedge clk);
        end
        @(negedge clk) RD_ADDR_VALID <= 0;
    end
endtask

task send_wr_data; //MASTER的写数据线通道传输一次。指定起始数据，突发长度（禁止与之前设置的突发长度不一致），掩码，敏感ID号。
//数据格式是从start_data开始每一次+1
    input [31:0] start_data;
    input [ 7:0] len;
    input [ 3:0] strb;
    input [ 1:0] sensitive_id;
    reg   [ 7:0] trans_cnt;
    begin
        trans_cnt <= 0;
        @(posedge clk) begin
            WR_DATA       <= start_data;
            WR_STRB       <= strb;
            WR_DATA_VALID <= 1;
            WR_DATA_LAST  <= (trans_cnt == len);
        end
        while(~((sensitive_id == WR_BACK_ID) && WR_DATA_READY && WR_DATA_VALID && WR_DATA_LAST))begin
            WR_DATA_LAST <= (trans_cnt == len);
            @(posedge clk) if((sensitive_id == WR_BACK_ID) && WR_DATA_READY && WR_DATA_VALID) begin
                WR_DATA <= WR_DATA + 1;
                trans_cnt <= trans_cnt + 1;
            end
            WR_DATA_LAST <= (trans_cnt == len);
        end
        @(negedge clk) begin
            WR_DATA_VALID <= 0;
            WR_DATA_LAST <= 0;
        end
    end
endtask

task recv_rd_data; //MASTER的读数据线通道传输一次。指定敏感ID号。不存储收到的数据，收到LAST信号后结束。
    input [ 1:0] sensitive_id;
    begin
        @(posedge clk) begin
            RD_DATA_READY <= 1;
        end
        while(~((sensitive_id == RD_BACK_ID) && RD_DATA_READY && RD_DATA_VALID && RD_DATA_LAST))begin
            @(posedge clk);
        end
        @(negedge clk) begin
            RD_DATA_READY <= 0;
        end
    end
endtask

initial begin
    WR_ADDR       = 0;
    WR_LEN        = 0;
    WR_ID         = 0;
    WR_ADDR_VALID = 0;
    WR_DATA       = 0;
    WR_STRB       = 0;
    WR_DATA_VALID = 0;
    WR_DATA_LAST  = 0;
    RD_ADDR       = 0;
    RD_LEN        = 0;
    RD_ID         = 0;
    RD_ADDR_VALID = 0;
    RD_DATA_READY = 0;
end

endmodule