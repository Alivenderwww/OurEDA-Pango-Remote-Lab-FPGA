module axi_slave_sim #(
    parameter addr_b = 0,
    parameter addr_e = 2047
) (
    input  wire        clk          ,
    input  wire        rstn         ,
    input  wire        BUS_CLK      ,
    input  wire        BUS_RST      ,

    input wire [31:0]  WR_ADDR      , //写地址
    input wire [ 7:0]  WR_LEN       , //写突发长度，实际长度为WR_LEN+1
    input wire [ 3:0]  WR_ID        , //写ID
    input wire         WR_ADDR_VALID, //写地址通道有效
    output reg         WR_ADDR_READY, //写地址通道准备
    
    input wire [ 31:0] WR_DATA      , //写数据
    input wire [  3:0] WR_STRB      , //写数据掩码
    output reg [ 3: 0] WR_BACK_ID   , //写回ID
    input  wire        WR_DATA_VALID, //写数据有效
    output wire        WR_DATA_READY, //写数据准备
    input  wire        WR_DATA_LAST , //最后一个写数据标志位
    
    input wire [31:0]  RD_ADDR      , //读地址
    input wire [ 7:0]  RD_LEN       , //读突发长度，实际长度为WR_LEN+1
    input wire [ 3:0]  RD_ID        , //读ID
    input wire         RD_ADDR_VALID, //读地址通道有效
    output reg         RD_ADDR_READY, //读地址通道准备
    
    output reg  [ 3:0] RD_BACK_ID   , //读回ID
    output reg [31:0]  RD_DATA      , //读数据
    output reg         RD_DATA_LAST , //最后一个读数据标志位
    input  wire        RD_DATA_READY, //读数据准备
    output reg         RD_DATA_VALID //读数据有效
);
reg [31:0] wr_addr_reg;
reg [ 7:0] wr_len_reg;
reg [31:0] wr_data_reg[addr_b:addr_e];
reg [31:0] rd_addr_reg [0:7];
reg [ 7:0] rd_len_reg  [0:7];
reg [ 7:0] RD_ID_reg [0:7];
reg [ 3:0] rd_req_num;//0~7
reg [ 7:0] rd_req_en;
reg [ 7:0] task_on;
reg [1:0] wr_data_ready_cnt;
//wr_addr
always @(posedge clk or negedge rstn) begin
    if(~rstn) WR_ADDR_READY <= 1'b0;
    else if(WR_ADDR_VALID && ~WR_ADDR_READY) WR_ADDR_READY <= 1'b1;
    else if(WR_ADDR_VALID && WR_ADDR_READY) WR_ADDR_READY <= 1'b0;
    else WR_ADDR_READY <= 1'b0;
end
always @(posedge clk or negedge rstn) begin
    if (~rstn) begin
        wr_addr_reg <= 0;
        wr_len_reg  <= 0;
        WR_BACK_ID  <= 0;
    end
    else if (WR_ADDR_VALID && WR_ADDR_READY) begin
        wr_addr_reg <= WR_ADDR;
        wr_len_reg  <= WR_LEN;
        WR_BACK_ID  <= WR_ID;
    end
    else if(WR_DATA_VALID && WR_DATA_READY)begin
        if(wr_addr_reg == addr_e) wr_addr_reg <= addr_b;
        else wr_addr_reg <= wr_addr_reg + 1; 
    end
end
//wr_data
always @(posedge clk or negedge rstn) begin
    if(~rstn) wr_data_reg <= '{default:0};
    else if(WR_DATA_VALID && WR_DATA_READY) wr_data_reg[wr_addr_reg] <= WR_DATA;
end
always @(posedge clk or negedge rstn) begin
    if(~rstn) wr_data_ready_cnt <= 0;
    else if(WR_DATA_VALID && WR_DATA_READY && WR_DATA_LAST) wr_data_ready_cnt <= 0;
    else if(WR_DATA_VALID ) wr_data_ready_cnt <= wr_data_ready_cnt + 1;
    else wr_data_ready_cnt <= 0;
end
always @(posedge clk or negedge rstn) begin
    if(~rstn) WR_ADDR_READY <= 1'b0;
    else if(wr_data_ready_cnt == 3) WR_ADDR_READY <= 1'b1;
    else WR_ADDR_READY <= 1'b0;
end
//rd_addr
always @(posedge clk or negedge rstn) begin
    if(~rstn) RD_ADDR_READY <= 1'b0;
    else if(rd_req_en[rd_req_num] == 0) RD_ADDR_READY <= 1'b1;
    else if(rd_req_en[rd_req_num] == 1) RD_ADDR_READY <= 1'b0;
    else RD_ADDR_READY <= 1'b0;
end
always @ (posedge clk or negedge rstn) begin
    if (~rstn) begin
        rd_addr_reg <= '{default:0};
        rd_len_reg  <= '{default:0};
        RD_ID_reg  <= '{default:0};
        task_on <= 8'b0;
        rd_req_en <= 8'b0;
        rd_req_num <= 0;
    end
    else if (RD_ADDR_VALID && RD_ADDR_READY) begin
        rd_addr_reg[rd_req_num] <= RD_ADDR;
        rd_len_reg[rd_req_num]  <= RD_LEN;
        RD_ID_reg[rd_req_num]  <= RD_ID;
        rd_req_num <= rd_req_num + 1;
        rd_req_en[rd_req_num] <= 1'b1;
    end
    else if(rd_req_en[0] && ~task_on[0]) rd_req_en[0] <= 1'b0;
    else if(rd_req_en[1] && ~task_on[1]) rd_req_en[1] <= 1'b0;
    else if(rd_req_en[2] && ~task_on[2]) rd_req_en[2] <= 1'b0;
    else if(rd_req_en[3] && ~task_on[3]) rd_req_en[3] <= 1'b0;
    else if(rd_req_en[4] && ~task_on[4]) rd_req_en[4] <= 1'b0;
    else if(rd_req_en[5] && ~task_on[5]) rd_req_en[5] <= 1'b0;
    else if(rd_req_en[6] && ~task_on[6]) rd_req_en[6] <= 1'b0;
    else if(rd_req_en[7] && ~task_on[7]) rd_req_en[7] <= 1'b0;
end
//rd_data

always @(rd_req_en)begin
    if     (rd_req_en[0] && ~task_on[0]) send_data(rd_addr_reg[0],rd_len_reg[0],RD_ID_reg[0],RD_DATA_READY,RD_BACK_ID,RD_DATA,RD_DATA_LAST,RD_DATA_VALID,task_on[0]);
    else if(rd_req_en[1] && ~task_on[1]) send_data(rd_addr_reg[1],rd_len_reg[1],RD_ID_reg[1],RD_DATA_READY,RD_BACK_ID,RD_DATA,RD_DATA_LAST,RD_DATA_VALID,task_on[1]);
    else if(rd_req_en[2] && ~task_on[2]) send_data(rd_addr_reg[2],rd_len_reg[2],RD_ID_reg[2],RD_DATA_READY,RD_BACK_ID,RD_DATA,RD_DATA_LAST,RD_DATA_VALID,task_on[2]);
    else if(rd_req_en[3] && ~task_on[3]) send_data(rd_addr_reg[3],rd_len_reg[3],RD_ID_reg[3],RD_DATA_READY,RD_BACK_ID,RD_DATA,RD_DATA_LAST,RD_DATA_VALID,task_on[3]);    
    else if(rd_req_en[4] && ~task_on[4]) send_data(rd_addr_reg[4],rd_len_reg[4],RD_ID_reg[4],RD_DATA_READY,RD_BACK_ID,RD_DATA,RD_DATA_LAST,RD_DATA_VALID,task_on[4]);
    else if(rd_req_en[5] && ~task_on[5]) send_data(rd_addr_reg[5],rd_len_reg[5],RD_ID_reg[5],RD_DATA_READY,RD_BACK_ID,RD_DATA,RD_DATA_LAST,RD_DATA_VALID,task_on[5]);
    else if(rd_req_en[6] && ~task_on[6]) send_data(rd_addr_reg[6],rd_len_reg[6],RD_ID_reg[6],RD_DATA_READY,RD_BACK_ID,RD_DATA,RD_DATA_LAST,RD_DATA_VALID,task_on[6]);
    else if(rd_req_en[7] && ~task_on[7]) send_data(rd_addr_reg[7],rd_len_reg[7],RD_ID_reg[7],RD_DATA_READY,RD_BACK_ID,RD_DATA,RD_DATA_LAST,RD_DATA_VALID,task_on[7]);

end

task send_data; 
    input [31:0] rd_addr;
    input [ 8:0] rd_len;
    input [ 3:0] rd_id;
    input  rd_data_ready;
    output reg [3:0] rd_back_id;
    output reg [31:0] rd_data;
    output reg rd_data_last;
    output reg rd_data_valid;
    output reg task_on_task;
    reg [7:0] rd_num;
    begin
        task_on_task <= 1'b1;
        rd_num <= 0;
        rd_data_valid <= 1'b1;
        rd_data <= wr_data_reg[rd_addr];
        rd_addr = rd_addr + 1;
        while(rd_num <= rd_len)begin
            @(posedge clk)begin
                if(rd_data_ready && rd_data_valid)begin
                    rd_data <= wr_data_reg[rd_addr];
                    rd_data_last <= (rd_num == rd_len);
                    rd_back_id <= rd_id;
                    rd_num <= rd_num + 1;
                    if(rd_addr == addr_e) rd_addr <= addr_b;
                    else rd_addr <= rd_addr + 1;
                end
            end
        end
        while (rd_num == rd_len+1)begin
            @(posedge clk)begin
                if(rd_data_ready && rd_data_valid)begin
                    rd_data_last <= 1'b0;
                    rd_data_valid <= 1'b0;
                    task_on_task <= 1'b0;
                end
            end
        end
    end
endtask
endmodule