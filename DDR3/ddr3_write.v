module ddr3_write(
    input  wire         clk              ,
    input  wire         rst              ,
    input  wire         ddr_init_done    ,

    input  wire [ 27:0] WR_ADDR          ,
    input  wire [  7:0] WR_LEN           ,
    input  wire         WR_ADDR_VALID    ,
    output wire         WR_ADDR_READY    ,
     
    input  wire [ 31:0] WR_DATA          ,
    input  wire [  3:0] WR_STRB          ,
    input  wire         WR_DATA_VALID    ,
    output wire         WR_DATA_READY    ,
    input  wire         WR_DATA_LAST     ,

    output wire [ 27:0]  WRITE_ADDR      ,
    output wire [  3:0]  WRITE_LEN       ,
    output wire          WRITE_ADDR_VALID,
    input  wire          WRITE_ADDR_READY,
     
    output wire [255:0] WRITE_DATA       ,
    output wire [ 31:0] WRITE_STRB       ,
    input  wire         WRITE_DATA_READY ,
    input  wire         WRITE_DATA_LAST 
);
/*
WRITE_LEN最大16突发长度
256*16 = 4096 bits
因此支持最大突发长度的FIFO存储量设定为4096bits
写模块需多给FIFO空间形成流水
因此设定为8192bit
*/

/*
写流程：
处于IDLE状态时WR_ADDR_READY为高电平
当其与WR_ADDR_VALID均为高电平时地址线握手成功，记录地址线，进入WAIT状态
同时计算出需要做多少空数据和STRB掩码以对齐位宽

进入WAIT状态后，事先向FIFO填入空数据和掩码，处理掉位宽问题
填入前向空数据后，只要FIFO未满，就可以一直向上级模块发送DATA_READY信号。
当数据FIFO内数据量高于固定值时，进入TRANS_ADDR状态，发送地址线，握手成功后进入TRANS_DATA状态，将这些数据+掩码传入下一级AXI，最后回到WAIT状态
当检测到FIFO内剩余数据是最后一波数据且已经收到了上级模块的DATA_LAST，进入AFTER状态，补全掩码和空数据后....
*/

wire         fifo_rst;
wire         fifo_wr_en;
wire [ 31:0] fifo_wr_data;
wire         fifo_rd_en;
wire [255:0] fifo_rd_data;
wire         full, empty;
wire         almost_full;
wire [  3:0] fifo_wr_strb;
wire [ 31:0] fifo_rd_strb;
reg          fifo_rd_first_need;

reg [2:0] start_complete_num, end_complete_num;
reg [27:0] wr_addr_load;
reg [ 7:0] wr_len_load;
wire [27:0] wr_addr_end = WR_ADDR + WR_LEN;
reg flag_last_trans;
reg flag_data_recv_over;

reg [2:0] cu_wr_st, nt_wr_st;
localparam WRITE_ST_IDLE       = 3'b000,
           WRITE_ST_WAIT       = 3'b001,
           WRITE_ST_TRANS_ADDR = 3'b010,
           WRITE_ST_TRANS_DATA = 3'b011,
           WRITE_ST_AFTER      = 3'b100;
always @(*) begin
    if(rst) nt_wr_st <= WRITE_ST_IDLE;
    else case (cu_wr_st)
        WRITE_ST_IDLE      : nt_wr_st <= (WR_ADDR_READY && WR_ADDR_VALID)?(WRITE_ST_WAIT):(WRITE_ST_IDLE);
        WRITE_ST_WAIT      : begin
            //在WAIT状态下，如果检测到start_complete_num不为0就先存入空数据，并且只要非满就持续接收上级模块的数据
            //触发条件1 为存入了大于32x(8x16)bit的数据，表现为almost_full被拉高。跳转至WRITE_ST_TRANS_ADDR以直接发送WRITE_ADDR等地址线
            //触发条件2 为"收到过"WR_DATA_LAST. 说明与上级模块的数据传输已经结束。跳转至WRITE_ST_AFTER，先补齐位宽再跳转至WRITE_ST_TRANS_ADDR。
            if(almost_full) nt_wr_st <= WRITE_ST_TRANS_ADDR;
            else if(flag_data_recv_over) nt_wr_st <= WRITE_ST_AFTER;
            else nt_wr_st <= WRITE_ST_WAIT;
        end
        WRITE_ST_TRANS_ADDR: nt_wr_st <= (WRITE_ADDR_READY && WRITE_ADDR_VALID)?(WRITE_ST_TRANS_DATA):(WRITE_ST_TRANS_ADDR);
        WRITE_ST_TRANS_DATA: begin
            if(WRITE_DATA_READY && WRITE_DATA_LAST) begin
                if(flag_last_trans) nt_wr_st <= WRITE_ST_IDLE;
                else nt_wr_st <= WRITE_ST_WAIT;
            end else nt_wr_st <= WRITE_ST_TRANS_DATA;
        end
        WRITE_ST_AFTER     : nt_wr_st <= (end_complete_num == 0)?(WRITE_ST_TRANS_ADDR):(WRITE_ST_AFTER);
        default            : nt_wr_st <= WRITE_ST_IDLE;
    endcase
end
always @(posedge clk) cu_wr_st <= nt_wr_st;

always @(posedge clk) begin
    if(rst || cu_wr_st == WRITE_ST_IDLE) flag_data_recv_over <= 0;
    else if(WR_DATA_READY && WR_DATA_VALID && WR_DATA_LAST) flag_data_recv_over <= 1;
    else flag_data_recv_over <= flag_data_recv_over;
end

always @(posedge clk) begin
    if(rst) begin
        wr_addr_load     <= 0;
        wr_len_load      <= 0;
    end else if(WR_ADDR_VALID && WR_ADDR_READY) begin
        wr_addr_load     <= {WR_ADDR[27:3],3'b000};
        wr_len_load      <= wr_addr_end[7:3] - WR_ADDR[7:3];
    end else if(WRITE_ADDR_VALID && WRITE_ADDR_READY) begin
        if(flag_last_trans) begin
            wr_addr_load <= wr_addr_load;
            wr_len_load  <= wr_len_load;
        end else begin
            wr_addr_load <= wr_addr_load + WRITE_LEN * 8 + 8;
            wr_len_load  <= wr_len_load - WRITE_LEN - 1;
        end
    end else begin
        wr_addr_load <= wr_addr_load;
        wr_len_load  <= wr_len_load;
    end
end

always @(posedge clk) begin
    if(rst || cu_wr_st == WRITE_ST_IDLE) begin
        flag_last_trans <= 0;
    end else if((cu_wr_st == WRITE_ST_TRANS_DATA) && (nt_wr_st == WRITE_ST_WAIT)) begin
        flag_last_trans <= (wr_len_load <= 15);
    end else begin
        flag_last_trans <= flag_last_trans;
    end
end

always @(posedge clk) begin
    if(rst) start_complete_num <= 0;
    else if(WR_ADDR_VALID && WR_ADDR_READY) start_complete_num <= WR_ADDR[2:0];
    else if((fifo_wr_en) && (~full) && (cu_wr_st != WRITE_ST_IDLE) && (start_complete_num != 0)) start_complete_num <= start_complete_num - 1;
    else start_complete_num <= start_complete_num;
end

always @(posedge clk) begin
    if(rst) end_complete_num <= 0;
    else if(WR_ADDR_VALID && WR_ADDR_READY) end_complete_num <= 7 - wr_addr_end[2:0];
    else if((fifo_wr_en) && (cu_wr_st == WRITE_ST_AFTER) && (end_complete_num != 0)) end_complete_num <= end_complete_num - 1;
    else end_complete_num <= end_complete_num;
end

always @(posedge clk) begin
    if(fifo_rst) fifo_rd_first_need <= 1;
    else if(empty && (WRITE_DATA_READY)) fifo_rd_first_need <= 1;
    else if(fifo_rd_en && fifo_rd_first_need) fifo_rd_first_need <= 0;
    else fifo_rd_first_need <= fifo_rd_first_need;
end

assign WR_ADDR_READY    = (ddr_init_done) && (cu_wr_st == WRITE_ST_IDLE);
assign WR_DATA_READY    = (ddr_init_done) && ((cu_wr_st != WRITE_ST_IDLE) && (~full) && (start_complete_num == 0));
assign WRITE_ADDR       = wr_addr_load;
assign WRITE_LEN        = (wr_len_load >= 15)?(4'b1111):(wr_len_load);
assign WRITE_ADDR_VALID = (ddr_init_done) && (cu_wr_st == WRITE_ST_TRANS_ADDR);
assign WRITE_DATA       = fifo_rd_data;
assign WRITE_STRB       = fifo_rd_strb;

assign fifo_rst     = rst;
assign fifo_wr_en   = (~full) && (((cu_wr_st != WRITE_ST_IDLE ) && (start_complete_num != 0))
                              ||  ((cu_wr_st == WRITE_ST_AFTER) && (  end_complete_num != 0))
                              ||  (WR_DATA_READY && WR_DATA_VALID));
assign fifo_wr_data = (((cu_wr_st == WRITE_ST_WAIT) && (start_complete_num != 0)) || ((cu_wr_st == WRITE_ST_AFTER) && (end_complete_num != 0)))
                     ?(32'b0):(WR_DATA);
assign fifo_wr_strb = (((cu_wr_st == WRITE_ST_WAIT) && (start_complete_num != 0)) || ((cu_wr_st == WRITE_ST_AFTER) && (end_complete_num != 0)))
                     ?(4'b0000):(WR_STRB);
assign fifo_rd_en   = (~empty) && ((fifo_rd_first_need) || (WRITE_DATA_READY));

fifo_ddr3_write fifo_ddr3_write(
    .clk    (clk),
    .rst    (fifo_rst),

    .wr_en  (fifo_wr_en),
    .wr_data(fifo_wr_data),

    .rd_en  (fifo_rd_en),
    .rd_data(fifo_rd_data),

    .wr_full   (full),
    .rd_empty  (empty),

    .almost_full (almost_full)
);

fifo_ddr3_write_strb fifo_ddr3_write_strb(
    .clk    (clk),
    .rst    (fifo_rst),

    .wr_en  (fifo_wr_en),
    .wr_data(fifo_wr_strb),

    .rd_en  (fifo_rd_en),
    .rd_data(fifo_rd_strb)
);






endmodule