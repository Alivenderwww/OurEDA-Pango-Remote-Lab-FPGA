module axi_slave_sim #(
    parameter addr_b = 0,
    parameter addr_e = 1023
)
(
    //___________________其他接口_____________________//
    input  wire        clk          ,
    input  wire        rstn         ,

    //___________________AXI接口_____________________//
    input  wire        SLAVE_CLK          , //向AXI总线提供的本主机时钟信号
    input  wire        SLAVE_RSTN         , //向AXI总线提供的本主机复位信号

    input  wire [ 3:0] SLAVE_WR_ADDR_ID   , //写地址通道-ID
    input  wire [31:0] SLAVE_WR_ADDR      , //写地址通道-地址
    input  wire [ 7:0] SLAVE_WR_ADDR_LEN  , //写地址通道-突发长度-最小为0（1突发），最大为255（256突发）
    input  wire [ 1:0] SLAVE_WR_ADDR_BURST, //写地址通道-突发类型
    input  wire        SLAVE_WR_ADDR_VALID, //写地址通道-握手信号-有效
    output reg         SLAVE_WR_ADDR_READY, //写地址通道-握手信号-准备

    input  wire [31:0] SLAVE_WR_DATA      , //写数据通道-数据
    input  wire [ 3:0] SLAVE_WR_STRB      , //写数据通道-选通
    input  wire        SLAVE_WR_DATA_LAST , //写数据通道-last信号
    input  wire        SLAVE_WR_DATA_VALID, //写数据通道-握手信号-有效
    output reg         SLAVE_WR_DATA_READY, //写数据通道-握手信号-准备

    output reg  [ 3:0] SLAVE_WR_BACK_ID   , //写响应通道-ID
    output reg  [ 1:0] SLAVE_WR_BACK_RESP , //写响应通道-响应 //SLAVE_WR_DATA_LAST拉高的同时或者之后 00 01正常 10写错误 11地址有问题找不到从机
    output reg         SLAVE_WR_BACK_VALID, //写响应通道-握手信号-有效
    input  wire        SLAVE_WR_BACK_READY, //写响应通道-握手信号-准备

    input  wire [ 3:0] SLAVE_RD_ADDR_ID   , //读地址通道-ID
    input  wire [31:0] SLAVE_RD_ADDR      , //读地址通道-地址
    input  wire [ 7:0] SLAVE_RD_ADDR_LEN  , //读地址通道-突发长度。最小为0（1突发），最大为255（256突发）
    input  wire [ 1:0] SLAVE_RD_ADDR_BURST, //读地址通道-突发类型。
    input  wire        SLAVE_RD_ADDR_VALID, //读地址通道-握手信号-有效
    output reg         SLAVE_RD_ADDR_READY, //读地址通道-握手信号-准备

    output reg  [ 3:0] SLAVE_RD_BACK_ID   , //读数据通道-ID
    output reg  [31:0] SLAVE_RD_DATA      , //读数据通道-数据
    output reg  [ 1:0] SLAVE_RD_DATA_RESP , //读数据通道-响应
    output reg         SLAVE_RD_DATA_LAST , //读数据通道-last信号
    output reg         SLAVE_RD_DATA_VALID, //读数据通道-握手信号-有效
    input  wire        SLAVE_RD_DATA_READY  //读数据通道-握手信号-准备
);
//如果AXI总线某一个模块暂时不需要连接，用default模块代替。
reg [31:0] wr_addr_reg;
reg [ 7:0] wr_len_reg;
reg [31:0] wr_data_reg[addr_b:addr_e];
reg [31:0] rd_addr_reg [0:7];
reg [ 7:0] rd_len_reg  [0:7];
reg [ 3:0] RD_ID_reg [0:7];
reg [ 3:0] rd_req_num;//0~7
reg [ 7:0] rd_req_en;
reg [ 7:0] task_on;
reg [1:0] wr_data_ready_cnt;
reg task_end;
initial begin
    task_on <= 8'b0;
    SLAVE_RD_BACK_ID <= 4'b0;
    SLAVE_RD_DATA_VALID <= 0;
    SLAVE_RD_DATA_LAST <= 0;
    SLAVE_RD_DATA <= 32'b0;
    task_end <= 0;
end
//wr_addr
always @(posedge clk) begin
    if(~rstn) SLAVE_WR_ADDR_READY <= 1'b0;
    else if(SLAVE_WR_ADDR_VALID && ~SLAVE_WR_ADDR_READY) SLAVE_WR_ADDR_READY <= 1'b1;
    else if(SLAVE_WR_ADDR_VALID && SLAVE_WR_ADDR_READY) SLAVE_WR_ADDR_READY <= 1'b0;
    else SLAVE_WR_ADDR_READY <= 1'b0;
end
always @(posedge clk) begin
    if (~rstn) begin
        wr_addr_reg <= 0;
        wr_len_reg  <= 0;
        SLAVE_WR_BACK_ID  <= 0;
    end
    else if (SLAVE_WR_ADDR_VALID && SLAVE_WR_ADDR_READY) begin
        wr_addr_reg <= SLAVE_WR_ADDR;
        wr_len_reg  <= SLAVE_WR_ADDR_LEN;
        SLAVE_WR_BACK_ID  <= SLAVE_WR_ADDR_ID;
    end
    else if(SLAVE_WR_DATA_VALID && SLAVE_WR_DATA_READY)begin
        if(wr_addr_reg == addr_e) wr_addr_reg <= addr_b;
        else wr_addr_reg <= wr_addr_reg + 1; 
    end
end
//wr_data
always @(posedge clk) begin
    if(~rstn) wr_data_reg <= '{default:0};
    else if(SLAVE_WR_DATA_VALID && SLAVE_WR_DATA_READY) wr_data_reg[wr_addr_reg] <= SLAVE_WR_DATA;
end
always @(posedge clk) begin
    if(~rstn) wr_data_ready_cnt <= 0;
    else if(SLAVE_WR_DATA_VALID && SLAVE_WR_DATA_READY && SLAVE_WR_DATA_LAST) wr_data_ready_cnt <= 0;
    else if(SLAVE_WR_DATA_VALID ) wr_data_ready_cnt <= wr_data_ready_cnt + 1;
    else wr_data_ready_cnt <= 0;
end
always @(posedge clk) begin
    if(~rstn) SLAVE_WR_DATA_READY <= 1'b0;
    else if(wr_data_ready_cnt == 3) SLAVE_WR_DATA_READY <= 1'b1;
    else SLAVE_WR_DATA_READY <= 1'b0;
end
//写响应
always @(posedge clk) begin
    if(~rstn) begin
        SLAVE_WR_BACK_RESP <= 2'b00;
        SLAVE_WR_BACK_VALID <= 1'b0;
    end
    else if(SLAVE_WR_DATA_LAST) begin
        SLAVE_WR_BACK_RESP <= 2'b00;
        SLAVE_WR_BACK_VALID <= 1'b1;
    end
    else if(SLAVE_WR_BACK_VALID && SLAVE_WR_BACK_READY) 
        SLAVE_WR_BACK_VALID <= 1'b0;
end
//rd_addr
always @(posedge clk) begin
    if(~rstn) SLAVE_RD_ADDR_READY <= 1'b0;
    else if(rd_req_en[rd_req_num] == 0) SLAVE_RD_ADDR_READY <= 1'b1;
    else if(rd_req_en[rd_req_num] == 1) SLAVE_RD_ADDR_READY <= 1'b0;
    else SLAVE_RD_ADDR_READY <= 1'b0;
end
always @ (posedge clk) begin
    if (~rstn) begin
        rd_addr_reg <= '{default:0};
        rd_len_reg  <= '{default:0};
        RD_ID_reg  <= '{default:0};

        rd_req_en <= 8'b0;
        rd_req_num <= 0;
        // SLAVE_RD_BACK_ID <= 0;
        // SLAVE_RD_DATA <= 0;
        // SLAVE_RD_DATA_LAST <= 0;
        // SLAVE_RD_DATA_VALID <= 0;
    end
    else if (SLAVE_RD_ADDR_VALID && SLAVE_RD_ADDR_READY) begin
        rd_addr_reg[rd_req_num] <= SLAVE_RD_ADDR;
        rd_len_reg[rd_req_num]  <= SLAVE_RD_ADDR_LEN;
        RD_ID_reg[rd_req_num]  <= SLAVE_RD_ADDR_ID;
        rd_req_num <= rd_req_num + 1;
        rd_req_en[rd_req_num] <= 1'b1;
    end
    else if(rd_req_en[0] && task_on[0] && task_end) rd_req_en[0] <= 1'b0;
    else if(rd_req_en[1] && task_on[1] && task_end) rd_req_en[1] <= 1'b0;
    else if(rd_req_en[2] && task_on[2] && task_end) rd_req_en[2] <= 1'b0;
    else if(rd_req_en[3] && task_on[3] && task_end) rd_req_en[3] <= 1'b0;
    else if(rd_req_en[4] && task_on[4] && task_end) rd_req_en[4] <= 1'b0;
    else if(rd_req_en[5] && task_on[5] && task_end) rd_req_en[5] <= 1'b0;
    else if(rd_req_en[6] && task_on[6] && task_end) rd_req_en[6] <= 1'b0;
    else if(rd_req_en[7] && task_on[7] && task_end) rd_req_en[7] <= 1'b0;
end
//SLAVE_RD_DATA

always @(*)begin
    if     (rd_req_en[0] && ~task_on[0])begin task_on[0] <= 1'b1; send_data(rd_addr_reg[0],rd_len_reg[0],RD_ID_reg[0],task_on[0]); end
    else if(rd_req_en[1] && ~task_on[1])begin task_on[1] <= 1'b1; send_data(rd_addr_reg[1],rd_len_reg[1],RD_ID_reg[1],task_on[1]); end
    else if(rd_req_en[2] && ~task_on[2])begin task_on[2] <= 1'b1; send_data(rd_addr_reg[2],rd_len_reg[2],RD_ID_reg[2],task_on[2]); end
    else if(rd_req_en[3] && ~task_on[3])begin task_on[3] <= 1'b1; send_data(rd_addr_reg[3],rd_len_reg[3],RD_ID_reg[3],task_on[3]); end 
    else if(rd_req_en[4] && ~task_on[4])begin task_on[4] <= 1'b1; send_data(rd_addr_reg[4],rd_len_reg[4],RD_ID_reg[4],task_on[4]); end
    else if(rd_req_en[5] && ~task_on[5])begin task_on[5] <= 1'b1; send_data(rd_addr_reg[5],rd_len_reg[5],RD_ID_reg[5],task_on[5]); end
    else if(rd_req_en[6] && ~task_on[6])begin task_on[6] <= 1'b1; send_data(rd_addr_reg[6],rd_len_reg[6],RD_ID_reg[6],task_on[6]); end
    else if(rd_req_en[7] && ~task_on[7])begin task_on[7] <= 1'b1; send_data(rd_addr_reg[7],rd_len_reg[7],RD_ID_reg[7],task_on[7]); end

end

task send_data; 
    input [31:0] rd_addr;
    input [ 8:0] rd_len;
    input [ 3:0] rd_id;
    output reg task_on_task;
    reg [8:0] rd_num;
    begin : axi_slave_sim_send_data
        task_on_task = 1'b1;
        rd_num = 1;
        SLAVE_RD_DATA = wr_data_reg[rd_addr];
        rd_addr = rd_addr+1;
        SLAVE_RD_DATA_LAST = 1'b0;
        SLAVE_RD_BACK_ID = rd_id;
        SLAVE_RD_DATA_VALID = 1'b1;
        SLAVE_RD_DATA_LAST = (rd_num == rd_len + 1);
        SLAVE_RD_DATA_RESP = (rd_num == rd_len + 1) ? 2'b00 : 2'b01;
        while(rd_num <= rd_len)begin
            SLAVE_RD_DATA_VALID = 1'b1;
            SLAVE_RD_DATA_LAST <= (rd_num == rd_len);
            SLAVE_RD_DATA_RESP <= (rd_num == rd_len) ? 2'b00 : 2'b01;
            @(posedge clk)begin
                if(SLAVE_RD_DATA_READY && SLAVE_RD_DATA_VALID)begin
                    SLAVE_RD_DATA <= wr_data_reg[rd_addr];
                    rd_num <= rd_num + 1;
                    if(rd_addr == addr_e) rd_addr <= addr_b;
                    else rd_addr <= rd_addr + 1;
                end
            end
            SLAVE_RD_DATA_LAST <= (rd_num == rd_len);
            SLAVE_RD_DATA_RESP <= (rd_num == rd_len) ? 2'b00 : 2'b01;
        end
        while (rd_num == rd_len+1)begin
            @(posedge clk)begin
                if(SLAVE_RD_DATA_READY && SLAVE_RD_DATA_VALID)begin
                    SLAVE_RD_DATA_LAST = 1'b0;
                    rd_num = rd_num + 1;
                end
            end
        end
        SLAVE_RD_DATA_VALID = 1'b0;
        task_end = 1'b1;
        @(posedge clk);
        task_end = 1'b0;
        task_on_task = 1'b0;
    end
endtask
endmodule