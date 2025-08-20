module axi_slave_sim #(
    parameter addr_b = 0,
    parameter addr_e = 1023
)
(
    output logic         SLAVE_CLK          ,
    output logic         SLAVE_RSTN         ,
    input  logic [ID_WIDTH-1:0] SLAVE_WR_ADDR_ID   ,
    input  logic [31:0]  SLAVE_WR_ADDR      ,
    input  logic [ 7:0]  SLAVE_WR_ADDR_LEN  ,
    input  logic [ 1:0]  SLAVE_WR_ADDR_BURST,
    input  logic         SLAVE_WR_ADDR_VALID,
    output logic         SLAVE_WR_ADDR_READY,
    input  logic [31:0]  SLAVE_WR_DATA      ,
    input  logic [ 3:0]  SLAVE_WR_STRB      ,
    input  logic         SLAVE_WR_DATA_LAST ,
    input  logic         SLAVE_WR_DATA_VALID,
    output logic         SLAVE_WR_DATA_READY,
    output logic [ID_WIDTH-1:0] SLAVE_WR_BACK_ID   ,
    output logic [ 1:0]  SLAVE_WR_BACK_RESP ,
    output logic         SLAVE_WR_BACK_VALID,
    input  logic         SLAVE_WR_BACK_READY,
    input  logic [ID_WIDTH-1:0] SLAVE_RD_ADDR_ID   ,
    input  logic [31:0]  SLAVE_RD_ADDR      ,
    input  logic [ 7:0]  SLAVE_RD_ADDR_LEN  ,
    input  logic [ 1:0]  SLAVE_RD_ADDR_BURST,
    input  logic         SLAVE_RD_ADDR_VALID,
    output logic         SLAVE_RD_ADDR_READY,
    output logic [ID_WIDTH-1:0] SLAVE_RD_BACK_ID   ,
    output logic [31:0]  SLAVE_RD_DATA      ,
    output logic [ 1:0]  SLAVE_RD_DATA_RESP ,
    output logic         SLAVE_RD_DATA_LAST ,
    output logic         SLAVE_RD_DATA_VALID,
    input  logic         SLAVE_RD_DATA_READY
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
always @(posedge SLAVE_CLK) begin
    if(~SLAVE_RSTN) SLAVE_WR_ADDR_READY <= 1'b0;
    else if(SLAVE_WR_ADDR_VALID && ~SLAVE_WR_ADDR_READY) SLAVE_WR_ADDR_READY <= 1'b1;
    else if(SLAVE_WR_ADDR_VALID && SLAVE_WR_ADDR_READY) SLAVE_WR_ADDR_READY <= 1'b0;
    else SLAVE_WR_ADDR_READY <= 1'b0;
end
always @(posedge SLAVE_CLK) begin
    if (~SLAVE_RSTN) begin
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
always @(posedge SLAVE_CLK) begin
    if(~SLAVE_RSTN) wr_data_reg <= '{default:0};
    else if(SLAVE_WR_DATA_VALID && SLAVE_WR_DATA_READY) wr_data_reg[wr_addr_reg] <= SLAVE_WR_DATA;
end
always @(posedge SLAVE_CLK) begin
    if(~SLAVE_RSTN) wr_data_ready_cnt <= 0;
    else if(SLAVE_WR_DATA_VALID && SLAVE_WR_DATA_READY && SLAVE_WR_DATA_LAST) wr_data_ready_cnt <= 0;
    else if(SLAVE_WR_DATA_VALID ) wr_data_ready_cnt <= wr_data_ready_cnt + 1;
    else wr_data_ready_cnt <= 0;
end
always @(posedge SLAVE_CLK) begin
    if(~SLAVE_RSTN) SLAVE_WR_DATA_READY <= 1'b0;
    else if(wr_data_ready_cnt == 3) SLAVE_WR_DATA_READY <= 1'b1;
    else SLAVE_WR_DATA_READY <= 1'b0;
end
//写响应
always @(posedge SLAVE_CLK) begin
    if(~SLAVE_RSTN) begin
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
always @(posedge SLAVE_CLK) begin
    if(~SLAVE_RSTN) SLAVE_RD_ADDR_READY <= 1'b0;
    else if(rd_req_en[rd_req_num] == 0) SLAVE_RD_ADDR_READY <= 1'b1;
    else if(rd_req_en[rd_req_num] == 1) SLAVE_RD_ADDR_READY <= 1'b0;
    else SLAVE_RD_ADDR_READY <= 1'b0;
end
always @ (posedge SLAVE_CLK) begin
    if (~SLAVE_RSTN) begin
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
            @(posedge SLAVE_CLK)begin
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
            @(posedge SLAVE_CLK)begin
                if(SLAVE_RD_DATA_READY && SLAVE_RD_DATA_VALID)begin
                    SLAVE_RD_DATA_LAST = 1'b0;
                    rd_num = rd_num + 1;
                end
            end
        end
        SLAVE_RD_DATA_VALID = 1'b0;
        task_end = 1'b1;
        @(posedge SLAVE_CLK);
        task_end = 1'b0;
        task_on_task = 1'b0;
    end
endtask


integer clk_delay;
task automatic set_clk;
    input integer delayin;
    begin
        SLAVE_RSTN = 0;
        #5000;
        clk_delay = delayin;
        #5000;
        SLAVE_RSTN = 1;
    end
endtask

initial begin
    clk_delay = 5;
    SLAVE_CLK = 0;
    SLAVE_RSTN = 0;
    #5000;
    SLAVE_RSTN = 1;
end
always #clk_delay SLAVE_CLK = ~SLAVE_CLK;

endmodule