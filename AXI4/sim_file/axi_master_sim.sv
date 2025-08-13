`timescale 1ns/1ps
module axi_master_sim #(
    parameter ID_WIDTH = 2
)(
output logic         MASTER_CLK          ,
output logic         MASTER_RSTN         ,
output logic [ID_WIDTH-1:0] MASTER_WR_ADDR_ID   ,
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
input  logic [ID_WIDTH-1:0] MASTER_WR_BACK_ID   ,
input  logic [ 1:0]  MASTER_WR_BACK_RESP ,
input  logic         MASTER_WR_BACK_VALID,
output logic         MASTER_WR_BACK_READY,
output logic [ID_WIDTH-1:0] MASTER_RD_ADDR_ID   ,
output logic [31:0]  MASTER_RD_ADDR      ,
output logic [ 7:0]  MASTER_RD_ADDR_LEN  ,
output logic [ 1:0]  MASTER_RD_ADDR_BURST,
output logic         MASTER_RD_ADDR_VALID,
input  logic         MASTER_RD_ADDR_READY,
input  logic [ID_WIDTH-1:0] MASTER_RD_BACK_ID   ,
input  logic [31:0]  MASTER_RD_DATA      ,
input  logic [ 1:0]  MASTER_RD_DATA_RESP ,
input  logic         MASTER_RD_DATA_LAST ,
input  logic         MASTER_RD_DATA_VALID,
output logic         MASTER_RD_DATA_READY 
    
);

//axi_master_sim模块，用于模仿MASTER时序。支持outstanding传输，自动处理ID和LEN。

/*AXI4并未规定master一笔交易的地址线和数据线谁先发。也就是说MASTER可以先发数据，再发地址，数据会在interconnect中
  暂存，调整顺序后发给slave。本模块因为暂存列的设置，只允许先发地址，后发数据。*/
///////////////////////////////////////////////////////////////
//参考样式
// initial begin
//     #50000
//     while(~MASTER_RSTN) #500;
//     set_rd_data_channel(7);                           //设置读数据通道能力为7
//     set_wr_data_channel(7);                           //设置写数据通道能力为7
//     send_wr_addr(2'b00, 32'h00000000, 8'd255, 2'b01); //写地址通道，ID0，起始地址0x00000000，突发长度255，突发类型1
//     send_wr_addr(2'b01, 32'h00010000, 8'd255, 2'b01); //写地址通道，ID0，起始地址0x00010000，突发长度255，突发类型1
//     send_wr_data(32'h00000000, 4'b1111);              //写数据通道，起始数据0，每32位写选通4'b1111。自动按照先前发的地址线顺序发送数据。
//     send_rd_addr(2'b00, 32'h00000000, 8'd255, 2'b01); //读地址通道，ID0，起始地址0x00000000，突发长度255，突发类型1
//     send_wr_data(32'h00000000, 4'b1111);              //写数据通道，起始数据0，每32位写选通4'b1111。自动按照先前发的地址线顺序发送数据。
//     send_rd_addr(2'b00, 32'h00010000, 8'd255, 2'b01); //读地址通道，ID0，起始地址0x00000000，突发长度255，突发类型1
//     MASTER自动处理读数据通道，写响应通道，并将读数据暂存到队列中
//     
//     // 从读数据队列中获取数据的示例
//     reg [31:0] read_data;
//     reg [ID_WIDTH-1:0] read_id;
//     reg [1:0] read_resp;
//     reg data_valid;
//     get_rd_data_from_queue(read_data, read_id, read_resp, data_valid); //从队列获取第一个读数据
//     check_rd_data_queue_status(queue_cnt, queue_empty, queue_full);    //检查队列状态
// end
///////////////////////////////////////////////////////////////

localparam BUFF_WIDTH = 10;
reg [8+ID_WIDTH-1:0] wr_channel_buff[2**BUFF_WIDTH-1:0];
reg [BUFF_WIDTH:0] wr_channel_wrptr, wr_channel_rdptr, wr_channel_respptr;
wire wr_channel_buff_full  = ((wr_channel_wrptr ^ wr_channel_respptr) == {1'b1,{(BUFF_WIDTH-1){1'b0}}});
initial begin
    wr_channel_wrptr   = 0;
    wr_channel_rdptr   = 0;
    wr_channel_respptr = 0;
end
always @(posedge MASTER_CLK) begin
    if(MASTER_WR_ADDR_VALID && MASTER_WR_ADDR_READY)begin
        if(wr_channel_buff_full) //ERROR 记录事务失败，MASTER写地址通道事务已满，请完成先前的事务再发送新事务。
            $display("%m: at time %0t ERROR: Write Transction set failed. MASTER's write transction fifo is full, please complete the previous Transction first.", $time);
        else begin
            $display("%m: at time %0t INFO: ID is %b, write addr %h, len is %d, burst is %b.", $time, MASTER_WR_ADDR_ID, MASTER_WR_ADDR, MASTER_WR_ADDR_LEN, MASTER_WR_ADDR_BURST);
            wr_channel_wrptr <= wr_channel_wrptr + 1;
            wr_channel_buff[wr_channel_wrptr[BUFF_WIDTH-1:0]] <= {MASTER_WR_ADDR_LEN, MASTER_WR_ADDR_ID};
        end
    end
end
always @(posedge MASTER_CLK) begin
    if(MASTER_WR_DATA_VALID && MASTER_WR_DATA_READY && MASTER_WR_DATA_LAST)begin
        if(wr_channel_wrptr == wr_channel_rdptr) //ERROR 写数据错误，事务列表空
            $display("%m: at time %0t ERROR: Write data failed. MASTER's write transction fifo empty.", $time);
        else begin
            $display("%m: at time %0t INFO: ID %b write data finished, trans len is %d", $time, wr_channel_buff[wr_channel_rdptr[BUFF_WIDTH-1:0]][1:0], wr_channel_buff[wr_channel_rdptr[BUFF_WIDTH-1:0]][9:2]);
            wr_channel_rdptr <= wr_channel_rdptr + 1;
        end
    end
end
always @(posedge MASTER_CLK) begin
    if(MASTER_WR_BACK_VALID && MASTER_WR_BACK_READY)begin
        if(wr_channel_wrptr == wr_channel_respptr) //ERROR 写响应错误，事务列表为空
            $display("%m: at time %0t ERROR: Write resp failed. MASTER's write transction fifo empty.", $time);
        else begin
            if(wr_channel_buff[wr_channel_respptr[BUFF_WIDTH-1:0]][1:0] != MASTER_WR_BACK_ID) //ERROR 事务ID错误
                $display("%m: at time %0t ERROR: Write resp ID error. Back ID is %b but %b expexcted.", $time, MASTER_WR_BACK_ID, wr_channel_buff[wr_channel_respptr[BUFF_WIDTH-1:0]][1:0]);
            else begin
                $display("%m: at time %0t INFO: ID %b write resp finished, RESP is %b", $time, MASTER_WR_BACK_ID, MASTER_WR_BACK_RESP);
                wr_channel_respptr <= wr_channel_respptr + 1;
            end
        end
    end
end

reg [8+ID_WIDTH-1:0] rd_channel_buff[2**BUFF_WIDTH-1:0];
reg [BUFF_WIDTH:0] rd_channel_wrptr, rd_channel_rdptr;
wire rd_channel_buff_full  = ((rd_channel_wrptr ^ rd_channel_rdptr) == {1'b1,{(BUFF_WIDTH-1){1'b0}}});
wire rd_channel_buff_empty = (rd_channel_wrptr == rd_channel_rdptr);

// 读数据队列 - 暂存从slave返回的数据
localparam RD_DATA_QUEUE_WIDTH = 8;
reg [31:0] rd_data_queue[2**RD_DATA_QUEUE_WIDTH-1:0];
reg [ID_WIDTH-1:0] rd_data_id_queue[2**RD_DATA_QUEUE_WIDTH-1:0];
reg [1:0] rd_data_resp_queue[2**RD_DATA_QUEUE_WIDTH-1:0];
reg [RD_DATA_QUEUE_WIDTH:0] rd_data_queue_wrptr, rd_data_queue_rdptr;
wire rd_data_queue_full  = ((rd_data_queue_wrptr ^ rd_data_queue_rdptr) == {1'b1,{(RD_DATA_QUEUE_WIDTH-1){1'b0}}});
wire rd_data_queue_empty = (rd_data_queue_wrptr == rd_data_queue_rdptr);

initial begin
    rd_channel_wrptr = 0;
    rd_channel_rdptr = 0;
    rd_data_queue_wrptr = 0;
    rd_data_queue_rdptr = 0;
end
always @(posedge MASTER_CLK) begin
    if(MASTER_RD_ADDR_VALID && MASTER_RD_ADDR_READY)begin
        if(rd_channel_buff_full) //ERROR 记录事务失败，MASTER读地址通道事务已满，请完成先前的事务再发送新事务。
        $display("%m: at time %0t ERROR: Read Transction set failed. MASTER's read transction fifo is full, please complete the previous Transction first.", $time);
        else begin
            $display("%m: at time %0t INFO: ID is %b,  read addr %h, len is %d, burst is %b.", $time, MASTER_RD_ADDR_ID, MASTER_RD_ADDR, MASTER_RD_ADDR_LEN, MASTER_RD_ADDR_BURST);
            rd_channel_wrptr <= rd_channel_wrptr + 1;
            rd_channel_buff[rd_channel_wrptr[BUFF_WIDTH-1:0]] <= {MASTER_RD_ADDR_LEN, MASTER_RD_ADDR_ID};
        end
    end
end
always @(posedge MASTER_CLK) begin
    if(MASTER_RD_DATA_VALID && MASTER_RD_DATA_READY && MASTER_RD_DATA_LAST)begin
        if(rd_channel_buff_empty) //ERROR 读数据错误，事务列表空
            $display("%m: at time %0t ERROR: Read data failed. MASTER's read transction fifo empty.", $time);
        else if(rd_channel_buff[rd_channel_rdptr[BUFF_WIDTH-1:0]][1:0] != MASTER_RD_BACK_ID) //ERROR 事务ID错误
            $display("%m: at time %0t ERROR: Read resp ID error. Back ID is %b but %b expexcted.", $time, MASTER_RD_BACK_ID, rd_channel_buff[rd_channel_rdptr[BUFF_WIDTH-1:0]][1:0]);
        else begin
            $display("%m: at time %0t INFO: Read data finished. ID is %b, trans len is %d, RESP is %b", $time, MASTER_RD_BACK_ID, rd_channel_buff[rd_channel_rdptr[BUFF_WIDTH-1:0]][9:2], MASTER_RD_DATA_RESP);
            rd_channel_rdptr <= rd_channel_rdptr + 1;
        end
    end
end

// 暂存所有读数据到队列中
always @(posedge MASTER_CLK) begin
    if(MASTER_RD_DATA_VALID && MASTER_RD_DATA_READY) begin
        if(rd_data_queue_full) begin
            $display("%m: at time %0t ERROR: Read data queue is full, data lost: %h", $time, MASTER_RD_DATA);
        end else begin
            rd_data_queue[rd_data_queue_wrptr[RD_DATA_QUEUE_WIDTH-1:0]] <= MASTER_RD_DATA;
            rd_data_id_queue[rd_data_queue_wrptr[RD_DATA_QUEUE_WIDTH-1:0]] <= MASTER_RD_BACK_ID;
            rd_data_resp_queue[rd_data_queue_wrptr[RD_DATA_QUEUE_WIDTH-1:0]] <= MASTER_RD_DATA_RESP;
            rd_data_queue_wrptr <= rd_data_queue_wrptr + 1;
            $display("%m: at time %0t INFO: Read data stored to queue: data=%h, id=%b, resp=%b", $time, MASTER_RD_DATA, MASTER_RD_BACK_ID, MASTER_RD_DATA_RESP);
        end
    end
end

/*
设置MASTER的读数据通道READY能力
rd_data_capcity为MASTER读数据接收能力，31为最强（ready始终拉高），越小ready随机拉低的时间越长，0为最低（关闭通道）
*/
reg [4:0] rd_data_capcity;
initial rd_data_capcity = 31;
task automatic set_rd_data_channel;
    input [4:0] capcity_in;
    rd_data_capcity = capcity_in;
endtask

/*
设置MASTER的写数据通道VALID能力
wr_data_capcity为MASTER写数据发送能力，31为最强（valid在传输数据时始终拉高），越小valid随机拉低的时间越长，0为最低（关闭通道）
*/
reg [4:0] wr_data_capcity;
initial wr_data_capcity = 31;
task automatic set_wr_data_channel;
    input [4:0] capcity_in;
    wr_data_capcity = capcity_in;
endtask

/*
从读数据队列中获取第一个数据
返回数据，ID，RESP。如果队列为空，返回值无效并报告错误。
*/
task automatic get_rd_data_from_queue;
    output [31:0] data_out;
    output [ID_WIDTH-1:0] id_out;
    output [1:0] resp_out;
    output reg valid_out;
    begin
        if(rd_data_queue_empty) begin
            $display("%m: at time %0t ERROR: Read data queue is empty, no data available.", $time);
            data_out = 32'hXXXXXXXX;
            id_out = {ID_WIDTH{1'bx}};
            resp_out = 2'bxx;
            valid_out = 0;
        end else begin
            data_out = rd_data_queue[rd_data_queue_rdptr[RD_DATA_QUEUE_WIDTH-1:0]];
            id_out = rd_data_id_queue[rd_data_queue_rdptr[RD_DATA_QUEUE_WIDTH-1:0]];
            resp_out = rd_data_resp_queue[rd_data_queue_rdptr[RD_DATA_QUEUE_WIDTH-1:0]];
            valid_out = 1;
            rd_data_queue_rdptr <= rd_data_queue_rdptr + 1;
            $display("%m: at time %0t INFO: Read data retrieved from queue: data=%h, id=%b, resp=%b", $time, data_out, id_out, resp_out);
        end
    end
endtask

/*
检查读数据队列状态
*/
task automatic check_rd_data_queue_status;
    output reg [RD_DATA_QUEUE_WIDTH:0] queue_count;
    output reg queue_empty_status;
    output reg queue_full_status;
    begin
        queue_count = rd_data_queue_wrptr - rd_data_queue_rdptr;
        queue_empty_status = rd_data_queue_empty;
        queue_full_status = rd_data_queue_full;
        $display("%m: at time %0t INFO: Read data queue status - count=%d, empty=%b, full=%b", $time, queue_count, queue_empty_status, queue_full_status);
    end
endtask

/*
MASTER的写地址线通道传输一次。
指定ID，ADDR，LEN，BURST。
同时将ID，LEN存入写通道暂存fifo。
握手成功后解除堵塞状态。
*/
task automatic send_wr_addr;
    input [ID_WIDTH-1:0] id;
    input [31:0] addr;
    input [ 7:0] len;
    input [ 1:0] burst;
    begin
        @(posedge MASTER_CLK) begin
            MASTER_WR_ADDR_ID    <= id;
            MASTER_WR_ADDR       <= addr;
            MASTER_WR_ADDR_LEN   <= len;
            MASTER_WR_ADDR_BURST <= burst;
            MASTER_WR_ADDR_VALID <= 1;
        end
        while(~(MASTER_WR_ADDR_VALID && MASTER_WR_ADDR_READY))begin
            @(posedge MASTER_CLK);
        end
        @(negedge MASTER_CLK) MASTER_WR_ADDR_VALID <= 0;
    end
endtask

/*
MASTER的读地址线通道传输一次。
指定ID，ADDR，LEN，BURST。
同时将ID，LEN存入读通道暂存fifo。
握手成功后解除堵塞状态。
*/
task automatic send_rd_addr;
    input [ID_WIDTH-1:0] id;
    input [31:0] addr;
    input [ 7:0] len;
    input [ 1:0] burst;
    begin
        @(posedge MASTER_CLK) begin
            MASTER_RD_ADDR_ID    <= id;
            MASTER_RD_ADDR       <= addr;
            MASTER_RD_ADDR_LEN   <= len;
            MASTER_RD_ADDR_BURST <= burst;
            MASTER_RD_ADDR_VALID <= 1;
        end
        while(~(MASTER_RD_ADDR_VALID && MASTER_RD_ADDR_READY))begin
            @(posedge MASTER_CLK);
        end
        @(negedge MASTER_CLK) MASTER_RD_ADDR_VALID <= 0;
    end
endtask

/*
MASTER的写数据线通道传输一次。AXI协议取消了写交织功能，因此按照暂存fifo内的顺序传输数据
指定start_data，strb。
按照写通道暂存fifo内容读取id，len。
最后一个数据发出后解除堵塞状态。
*/
reg wr_data_enable;
initial wr_data_enable = 0;
reg [ 7:0] wr_data_trans_cnt;
initial wr_data_trans_cnt = 0;
task automatic send_wr_data;
//数据格式是从start_data开始每一次+1
    input [31:0] start_data;
    input [ 3:0] strb;
    begin
        wr_data_trans_cnt <= 0;
        @(posedge MASTER_CLK) begin
            MASTER_WR_DATA       <= start_data;
            MASTER_WR_STRB       <= strb;
            wr_data_enable       <= 1;
        end
        while(~(MASTER_WR_DATA_VALID && MASTER_WR_DATA_READY && MASTER_WR_DATA_LAST))begin
            @(posedge MASTER_CLK) if(MASTER_WR_DATA_VALID && MASTER_WR_DATA_READY) begin
                MASTER_WR_DATA <= MASTER_WR_DATA + 1;
                wr_data_trans_cnt <= wr_data_trans_cnt + 1;
            end
        end
        wr_data_enable       <= 0;
        wr_data_trans_cnt    <= 0;
    end
endtask
always @(negedge MASTER_CLK) begin
    MASTER_WR_DATA_VALID <= (wr_data_enable == 1) && (1+{$random}%(31) <= wr_data_capcity);
end
assign MASTER_WR_DATA_LAST = (wr_data_enable == 1) && (wr_data_trans_cnt == wr_channel_buff[wr_channel_rdptr[BUFF_WIDTH-1:0]][9:2]);

initial begin
    MASTER_WR_ADDR_ID    = 0;
    MASTER_WR_ADDR       = 0;
    MASTER_WR_ADDR_LEN   = 0;
    MASTER_WR_ADDR_BURST = 0;
    MASTER_WR_ADDR_VALID = 0;
    MASTER_WR_DATA       = 0;
    MASTER_WR_STRB       = 0;
    MASTER_WR_DATA_VALID = 0;
    MASTER_RD_ADDR_ID    = 0;
    MASTER_RD_ADDR       = 0;
    MASTER_RD_ADDR_LEN   = 0;
    MASTER_RD_ADDR_BURST = 0;
    MASTER_RD_ADDR_VALID = 0;
    MASTER_RD_DATA_READY = 0;
end

always @(negedge MASTER_CLK) begin
    MASTER_RD_DATA_READY <= (1+{$random}%(31) <= rd_data_capcity);
end
assign MASTER_WR_BACK_READY = 1;

integer clk_delay;
task automatic set_clk;
    input integer delayin;
    begin
        MASTER_RSTN = 0;
        #5000;
        clk_delay = delayin;
        #5000;
        MASTER_RSTN = 1;
    end
endtask

initial begin
    clk_delay = 5;
    MASTER_CLK = 0;
    MASTER_RSTN = 0;
    #5000;
    MASTER_RSTN = 1;
end

always #clk_delay MASTER_CLK = ~MASTER_CLK;


endmodule