module i2c_master_axi_slave #(
    parameter OFFSET_ADDR = 32'h0000_0000
)(
    input  wire         clk,
    input  wire         rstn,

    input  wire         scl_in    ,
    output wire         scl_out   ,
    output wire         scl_enable,
    input  wire         sda_in    ,
    output wire         sda_out   ,
    output wire         sda_enable,
    // AXI Slave Interface
    
    output wire         SLAVE_CLK          ,
    output wire         SLAVE_RSTN         ,
    input  wire [4-1:0] SLAVE_WR_ADDR_ID   ,
    input  wire [31:0]  SLAVE_WR_ADDR      ,
    input  wire [ 7:0]  SLAVE_WR_ADDR_LEN  ,
    input  wire [ 1:0]  SLAVE_WR_ADDR_BURST,
    input  wire         SLAVE_WR_ADDR_VALID,
    output wire         SLAVE_WR_ADDR_READY,
    input  wire [31:0]  SLAVE_WR_DATA      ,
    input  wire [ 3:0]  SLAVE_WR_STRB      ,
    input  wire         SLAVE_WR_DATA_LAST ,
    input  wire         SLAVE_WR_DATA_VALID,
    output  reg         SLAVE_WR_DATA_READY,
    output wire [4-1:0] SLAVE_WR_BACK_ID   ,
    output wire [ 1:0]  SLAVE_WR_BACK_RESP ,
    output wire         SLAVE_WR_BACK_VALID,
    input  wire         SLAVE_WR_BACK_READY,
    input  wire [4-1:0] SLAVE_RD_ADDR_ID   ,
    input  wire [31:0]  SLAVE_RD_ADDR      ,
    input  wire [ 7:0]  SLAVE_RD_ADDR_LEN  ,
    input  wire [ 1:0]  SLAVE_RD_ADDR_BURST,
    input  wire         SLAVE_RD_ADDR_VALID,
    output wire         SLAVE_RD_ADDR_READY,
    output wire [4-1:0] SLAVE_RD_BACK_ID   ,
    output wire [31:0]  SLAVE_RD_DATA      ,
    output wire [ 1:0]  SLAVE_RD_DATA_RESP ,
    output wire         SLAVE_RD_DATA_LAST ,
    output  reg         SLAVE_RD_DATA_VALID,
    input  wire         SLAVE_RD_DATA_READY
);

wire I2C_MASTER_AXI_SLAVE_RSTN_SYNC;
assign SLAVE_CLK = clk;
assign SLAVE_RSTN = I2C_MASTER_AXI_SLAVE_RSTN_SYNC;
rstn_sync i2c_rstn_sync(clk,rstn,I2C_MASTER_AXI_SLAVE_RSTN_SYNC);

// 地址定义-{0000_0000_{0000_000}{0}_{0000_0000_0000_0000}
//           保留      -i2c地址-16b寻址---字节地址----
//i2c读写注意事项：1. I2C是8bit数据存储的，数据通道32bit位宽，写操作会直接抛弃高24bit数据，读操作高24bit数据为0
//                 2. EEPROM一次读写最多8个字节，超过部分会从起始地址重新读写，因此需控制突发长度不超过7.
//                 3. I2C读写较慢，且失败概率较高，总线会等待读写完毕后再返回RESP。
//                 4. I2C读写不支持突发类型设置

reg [ 6:0] i2c_slave_addr;
reg        i2c_read_write;
reg        i2c_addr_length;
reg [15:0] i2c_start_addr;
reg [15:0] i2c_data_length;

wire       cmd_valid;
wire       cmd_ready;
wire       cmd_done;
wire       cmd_error;
wire       cmd_rollback;

wire       i2c_wr_fifo_wr_en        ;
wire [7:0] i2c_wr_fifo_wr_data      ;
wire       i2c_wr_fifo_wr_full      ;
wire       i2c_wr_fifo_wr_snapshot  ;
wire       i2c_wr_fifo_wr_rollback  ;
wire       i2c_wr_fifo_rd_en        ;
wire [7:0] i2c_wr_fifo_rd_data      ;
wire       i2c_wr_fifo_rd_data_valid;
wire       i2c_wr_fifo_rd_empty     ;
wire       i2c_wr_fifo_rd_snapshot  ;
wire       i2c_wr_fifo_rd_rollback  ;

wire       i2c_rd_fifo_wr_en        ;
wire [7:0] i2c_rd_fifo_wr_data      ;
wire       i2c_rd_fifo_wr_full      ;
wire       i2c_rd_fifo_wr_snapshot  ;
wire       i2c_rd_fifo_wr_rollback  ;
wire       i2c_rd_fifo_rd_en        ;
wire [7:0] i2c_rd_fifo_rd_data      ;
wire       i2c_rd_fifo_rd_data_valid;
wire       i2c_rd_fifo_rd_empty     ;
wire       i2c_rd_fifo_rd_snapshot  ;
wire       i2c_rd_fifo_rd_rollback  ;

//_________________写___通___道_________________//
reg [ 3:0] wr_addr_id;    // 写地址ID寄存器
reg [31:0] wr_addr;       // 写地址寄存器
reg [ 1:0] wr_addr_burst; // 写突发类型寄存器
reg        wr_transcript_error, wr_transcript_error_reg; // 写传输错误标志及其寄存器
//JTAG作为SLAVE不接收WR_ADDR_LEN，其DATA线的结束以WR_DATA_LAST为参考。

// 写通道状态机定义
reg [ 2:0] cu_wrchannel_st, nt_wrchannel_st;  // 当前状态和下一状态
localparam ST_WR_IDLE = 3'b000, // 写通道空闲
           ST_WR_DATA = 3'b001, // 地址线握手成功，数据线通道开启
           ST_WR_CMD  = 3'b011, // 写命令发送
           ST_WR_WAIT = 3'b100, // 等待写完成
           ST_WR_RESP = 3'b101; // 写响应

//_________________读___通___道_________________//
reg [ 3:0] rd_addr_id;     // 读地址ID寄存器
reg [31:0] rd_addr;        // 读地址寄存器
reg [ 7:0] rd_addr_len;    // 读突发长度寄存器
reg [ 1:0] rd_addr_burst;  // 读突发类型寄存器
reg        rd_transcript_error, rd_transcript_error_reg; // 读传输错误标志及其寄存器

// 读通道状态机定义
reg [ 1:0] cu_rdchannel_st, nt_rdchannel_st;  // 当前状态和下一状态
localparam ST_RD_IDLE = 2'b00, // 发送完LAST和RESP，读通道空闲
           ST_RD_CMD  = 2'b01, // 读命令发送
           ST_RD_WAIT = 2'b10, // 等待读完成
           ST_RD_DATA = 2'b11; // 地址线握手成功，数据线通道开启

//_______________________________________________________________________________//
// 写通道状态机状态转换逻辑
always @(*) begin
    case (cu_wrchannel_st)
        ST_WR_IDLE: nt_wrchannel_st <= (SLAVE_WR_ADDR_VALID && SLAVE_WR_ADDR_READY)?(ST_WR_DATA):(ST_WR_IDLE);
        ST_WR_DATA: nt_wrchannel_st <= (SLAVE_WR_DATA_VALID && SLAVE_WR_DATA_READY && SLAVE_WR_DATA_LAST)?(ST_WR_CMD):(ST_WR_DATA);
        ST_WR_CMD : nt_wrchannel_st <= ((cmd_valid && cmd_ready)||(wr_transcript_error_reg || wr_transcript_error))?(ST_WR_WAIT):(ST_WR_CMD);
        ST_WR_WAIT: nt_wrchannel_st <= (cmd_done)?(ST_WR_RESP):(ST_WR_WAIT);
        ST_WR_RESP: nt_wrchannel_st <= (SLAVE_WR_BACK_VALID && SLAVE_WR_BACK_READY)?(ST_WR_IDLE):(ST_WR_RESP);
        default   : nt_wrchannel_st <= ST_WR_IDLE;
    endcase
end

// 写通道状态机时序逻辑
always @(posedge clk or negedge I2C_MASTER_AXI_SLAVE_RSTN_SYNC) begin
    if(~I2C_MASTER_AXI_SLAVE_RSTN_SYNC) cu_wrchannel_st <= ST_WR_IDLE;
    else cu_wrchannel_st <= nt_wrchannel_st;
end

// 写通道控制信号生成
assign SLAVE_WR_ADDR_READY = (I2C_MASTER_AXI_SLAVE_RSTN_SYNC) && (cu_wrchannel_st == ST_WR_IDLE) && (cu_rdchannel_st == ST_RD_IDLE);
assign SLAVE_WR_BACK_VALID = (I2C_MASTER_AXI_SLAVE_RSTN_SYNC) && (cu_wrchannel_st == ST_WR_RESP);
assign SLAVE_WR_BACK_RESP  = ((I2C_MASTER_AXI_SLAVE_RSTN_SYNC) && ((~wr_transcript_error) && (~wr_transcript_error_reg)))?(2'b00):(2'b10);
assign SLAVE_WR_BACK_ID    = wr_addr_id;

// 写通道ID和突发类型寄存
always @(posedge clk or negedge I2C_MASTER_AXI_SLAVE_RSTN_SYNC) begin
    if(~I2C_MASTER_AXI_SLAVE_RSTN_SYNC) begin
        wr_addr_id    <= 0;
        wr_addr_burst <= 0;
    end else if(SLAVE_WR_ADDR_VALID && SLAVE_WR_ADDR_READY) begin
        wr_addr_id    <= SLAVE_WR_ADDR_ID;
        wr_addr_burst <= SLAVE_WR_ADDR_BURST;
    end else begin
        wr_addr_id    <= wr_addr_id;
        wr_addr_burst <= wr_addr_burst;
    end
end

wire [31:0] wr_addr_offset = SLAVE_WR_ADDR - OFFSET_ADDR; // 计算偏移地址
// 写地址计算逻辑（）
always @(posedge clk or negedge I2C_MASTER_AXI_SLAVE_RSTN_SYNC) begin
    if(~I2C_MASTER_AXI_SLAVE_RSTN_SYNC) wr_addr <= 0;
    else if(SLAVE_WR_ADDR_VALID && SLAVE_WR_ADDR_READY) wr_addr <= wr_addr_offset;
    else wr_addr <= wr_addr;
end


// 写错误检测逻辑
always @(*) begin
    if((~I2C_MASTER_AXI_SLAVE_RSTN_SYNC) || (cu_wrchannel_st == ST_WR_IDLE) || (cu_wrchannel_st == ST_WR_RESP)) wr_transcript_error <= 0;
    else if(cmd_error) wr_transcript_error <= 1;
    else wr_transcript_error <= 0;
end

// 写错误状态寄存
always @(posedge clk or negedge I2C_MASTER_AXI_SLAVE_RSTN_SYNC) begin
    if((~I2C_MASTER_AXI_SLAVE_RSTN_SYNC) || (cu_wrchannel_st == ST_WR_IDLE)) wr_transcript_error_reg <= 0;
    else wr_transcript_error_reg <= (wr_transcript_error)?(1):(wr_transcript_error_reg);
end

// 写数据READY选通
always @(*) begin
    if(~I2C_MASTER_AXI_SLAVE_RSTN_SYNC) SLAVE_WR_DATA_READY <= 0;
    else if(cu_wrchannel_st == ST_WR_DATA) SLAVE_WR_DATA_READY <= (~i2c_wr_fifo_wr_full) || (wr_transcript_error || wr_transcript_error_reg);
    else SLAVE_WR_DATA_READY <= 0;
end


//_______________________________________________________________________________//
// 读通道状态机状态转换逻辑
always @(*) begin
    case (cu_rdchannel_st)
        ST_RD_IDLE: nt_rdchannel_st <= (SLAVE_RD_ADDR_VALID && SLAVE_RD_ADDR_READY)?(ST_RD_CMD):(ST_RD_IDLE);
        ST_RD_CMD : nt_rdchannel_st <= ((cmd_valid && cmd_ready) || (rd_transcript_error_reg || rd_transcript_error))?(ST_RD_WAIT):(ST_RD_CMD);
        ST_RD_WAIT: nt_rdchannel_st <= (cmd_done)?(ST_RD_DATA):(ST_RD_WAIT);
        ST_RD_DATA: nt_rdchannel_st <= (SLAVE_RD_DATA_VALID && SLAVE_RD_DATA_READY && SLAVE_RD_DATA_LAST)?(ST_RD_IDLE):(ST_RD_DATA);
        default   : nt_rdchannel_st <= ST_RD_IDLE;
    endcase
end

// 读通道状态机时序逻辑
always @(posedge clk or negedge I2C_MASTER_AXI_SLAVE_RSTN_SYNC) begin
    if(~I2C_MASTER_AXI_SLAVE_RSTN_SYNC) cu_rdchannel_st <= ST_RD_IDLE;
    else cu_rdchannel_st <= nt_rdchannel_st;
end

// 读通道控制信号生成
assign SLAVE_RD_ADDR_READY = (I2C_MASTER_AXI_SLAVE_RSTN_SYNC) && (cu_rdchannel_st == ST_RD_IDLE) && (cu_wrchannel_st == ST_WR_IDLE) && (nt_wrchannel_st == ST_WR_IDLE);
assign SLAVE_RD_BACK_ID = rd_addr_id;
assign SLAVE_RD_DATA_RESP = ((I2C_MASTER_AXI_SLAVE_RSTN_SYNC) && ((~rd_transcript_error) && (~rd_transcript_error_reg)))?(2'b00):(2'b10);

// 读通道地址和突发参数寄存
always @(posedge clk or negedge I2C_MASTER_AXI_SLAVE_RSTN_SYNC) begin
    if(~I2C_MASTER_AXI_SLAVE_RSTN_SYNC) begin
        rd_addr_id <= 0;
        rd_addr_burst <= 0;
    end else if(SLAVE_RD_ADDR_VALID && SLAVE_RD_ADDR_READY) begin
        rd_addr_id <= SLAVE_RD_ADDR_ID;
        rd_addr_burst <= SLAVE_RD_ADDR_BURST;
    end else begin
        rd_addr_id <= rd_addr_id;
        rd_addr_burst <= rd_addr_burst;
    end
end

wire [31:0] rd_addr_offset = SLAVE_RD_ADDR - OFFSET_ADDR; // 计算偏移地址
// 读地址计算逻辑
always @(posedge clk or negedge I2C_MASTER_AXI_SLAVE_RSTN_SYNC) begin
    if(~I2C_MASTER_AXI_SLAVE_RSTN_SYNC) rd_addr <= 0;
    else if(SLAVE_RD_ADDR_VALID && SLAVE_RD_ADDR_READY) rd_addr <= rd_addr_offset;
    else rd_addr <= rd_addr;
end

// rd_addr_len
always @(posedge clk or negedge I2C_MASTER_AXI_SLAVE_RSTN_SYNC) begin
    if(~I2C_MASTER_AXI_SLAVE_RSTN_SYNC) rd_addr_len <= 0;
    else if(SLAVE_RD_ADDR_VALID && SLAVE_RD_ADDR_READY) rd_addr_len <= SLAVE_RD_ADDR_LEN;
    else if(SLAVE_RD_DATA_VALID && SLAVE_RD_DATA_READY && rd_addr_len > 0) rd_addr_len <= rd_addr_len - 1;
    else rd_addr_len <= rd_addr_len;
    
end

// 读通道控制信号生成
assign SLAVE_RD_DATA_LAST = (SLAVE_RD_DATA_VALID) && (rd_addr_len == 0);

// 读错误检测逻辑
always @(*) begin
    if((~I2C_MASTER_AXI_SLAVE_RSTN_SYNC) || (cu_rdchannel_st == ST_RD_IDLE)) rd_transcript_error <= 0;
    else if(cmd_error) rd_transcript_error <= 1;
    else rd_transcript_error <= 0;
end

// 读错误状态寄存
always @(posedge clk or negedge I2C_MASTER_AXI_SLAVE_RSTN_SYNC) begin
    if((~I2C_MASTER_AXI_SLAVE_RSTN_SYNC)) rd_transcript_error_reg <= 0;
    else if(cu_rdchannel_st == ST_RD_IDLE) rd_transcript_error_reg <= 0;
    else rd_transcript_error_reg <= (rd_transcript_error)?(1):(rd_transcript_error_reg);
end

// 读数据VALID选通
always @(*) begin
    if(~I2C_MASTER_AXI_SLAVE_RSTN_SYNC) SLAVE_RD_DATA_VALID <= 0;
    else if(cu_rdchannel_st == ST_RD_DATA)
        SLAVE_RD_DATA_VALID <= ((i2c_rd_fifo_rd_data_valid) && (~i2c_rd_fifo_rd_empty)) || (rd_transcript_error || rd_transcript_error_reg);
    else SLAVE_RD_DATA_VALID <= 0;
end

// CMD命令生成逻辑
always @(posedge clk or negedge I2C_MASTER_AXI_SLAVE_RSTN_SYNC) begin
    if(~I2C_MASTER_AXI_SLAVE_RSTN_SYNC)begin
        {i2c_slave_addr, i2c_addr_length, i2c_start_addr} <= 0;
        i2c_read_write <= 0;
        i2c_data_length <= 0;
    end else if(SLAVE_WR_ADDR_VALID && SLAVE_WR_ADDR_READY) begin 
        {i2c_slave_addr, i2c_addr_length, i2c_start_addr} <= wr_addr_offset[24:0];
        i2c_read_write <= 1'b0; // 写操作
        i2c_data_length <= {7'b0,SLAVE_WR_ADDR_LEN};
    end else if(SLAVE_RD_ADDR_VALID && SLAVE_RD_ADDR_READY)begin
        {i2c_slave_addr, i2c_addr_length, i2c_start_addr} <= rd_addr_offset[24:0];
        i2c_read_write <= 1'b1; // 读操作
        i2c_data_length <= {7'b0,SLAVE_RD_ADDR_LEN};
    end else begin
        {i2c_slave_addr, i2c_addr_length, i2c_start_addr} <= {i2c_slave_addr, i2c_addr_length, i2c_start_addr};
        i2c_read_write <= i2c_read_write;
        i2c_data_length <= i2c_data_length;
    end
end

i2c_fifo #(
	.FIFO_DEPTH 	(4))
i2c_wr_fifo(
	.clk           	( clk                      ),
	.rstn          	( I2C_MASTER_AXI_SLAVE_RSTN_SYNC),
	.wr_en         	( i2c_wr_fifo_wr_en        ),//接AXI_READY&AXI_VALID信号
	.wr_data       	( i2c_wr_fifo_wr_data      ),//接AXI_DATA信号
	.wr_full       	( i2c_wr_fifo_wr_full      ),//接AXI_READY信号
	.wr_snapshot   	( i2c_wr_fifo_wr_snapshot  ),//done就拉高
	.wr_rollback   	( i2c_wr_fifo_wr_rollback  ),//不接
	.rd_en         	( i2c_wr_fifo_rd_en        ),//接i2c写进去的
	.rd_data       	( i2c_wr_fifo_rd_data      ),//接i2c写进去的
	.rd_data_valid 	( i2c_wr_fifo_rd_data_valid),//不接
	.rd_empty      	( i2c_wr_fifo_rd_empty     ),//不接
	.rd_snapshot   	( i2c_wr_fifo_rd_snapshot  ),//done就拉高
	.rd_rollback   	( i2c_wr_fifo_rd_rollback  ) //rollback且处于写状态就拉高
);

assign i2c_wr_fifo_wr_en = SLAVE_WR_DATA_VALID && SLAVE_WR_DATA_READY;
assign i2c_wr_fifo_wr_data = SLAVE_WR_DATA[7:0];
assign i2c_wr_fifo_wr_snapshot = cmd_done && (cu_wrchannel_st != ST_WR_IDLE);
assign i2c_wr_fifo_wr_rollback = 1'b0;
assign i2c_wr_fifo_rd_snapshot = cmd_done && (cu_wrchannel_st != ST_WR_IDLE);
assign i2c_wr_fifo_rd_rollback = cmd_rollback && (cu_wrchannel_st != ST_WR_IDLE);

i2c_fifo #(
	.FIFO_DEPTH 	(4))
i2c_rd_fifo(
	.clk           	( clk                       ),
	.rstn          	( I2C_MASTER_AXI_SLAVE_RSTN_SYNC),
	.wr_en         	( i2c_rd_fifo_wr_en         ),//接i2c读出来的
	.wr_data       	( i2c_rd_fifo_wr_data       ),//接i2c读出来的
	.wr_full       	( i2c_rd_fifo_wr_full       ),//不接
	.wr_snapshot   	( i2c_rd_fifo_wr_snapshot   ),//done就拉高
	.wr_rollback   	( i2c_rd_fifo_wr_rollback   ),//rollback且处于读状态就拉高
	.rd_en         	( i2c_rd_fifo_rd_en         ),//接AXI_READY&AXI_VALID信号
	.rd_data       	( i2c_rd_fifo_rd_data       ),//接AXI_DATA信号
	.rd_data_valid 	( i2c_rd_fifo_rd_data_valid ),//接AXI_VALID信号
	.rd_empty      	( i2c_rd_fifo_rd_empty      ),//接AXI_VALID信号
	.rd_snapshot   	( i2c_rd_fifo_rd_snapshot   ),//done就拉高
	.rd_rollback   	( i2c_rd_fifo_rd_rollback   ) //不接
);

assign i2c_rd_fifo_wr_snapshot = cmd_done && (cu_rdchannel_st != ST_RD_IDLE);
assign i2c_rd_fifo_wr_rollback = cmd_rollback && (cu_rdchannel_st != ST_RD_IDLE);
assign i2c_rd_fifo_rd_en = SLAVE_RD_DATA_VALID && SLAVE_RD_DATA_READY;
assign SLAVE_RD_DATA = i2c_rd_fifo_rd_data;
assign i2c_rd_fifo_rd_snapshot = cmd_done && (cu_rdchannel_st != ST_RD_IDLE);
assign i2c_rd_fifo_rd_rollback = 1'b0;

assign cmd_valid = (I2C_MASTER_AXI_SLAVE_RSTN_SYNC) && (((cu_wrchannel_st == ST_WR_CMD) && (~wr_transcript_error) && (~wr_transcript_error_reg)) || ((cu_rdchannel_st == ST_RD_CMD) && (~rd_transcript_error) && (~rd_transcript_error_reg)));

i2c_master i2c_master_inst(
    .clk            (clk            ),
    .rstn           (I2C_MASTER_AXI_SLAVE_RSTN_SYNC),
    .scl_in         (scl_in         ),
    .scl_out        (scl_out        ),
    .scl_enable     (scl_enable     ),
    .sda_in         (sda_in         ),
    .sda_out        (sda_out        ),
    .sda_enable     (sda_enable     ),
    .cmd_valid      (cmd_valid      ),
    .cmd_ready      (cmd_ready      ),
    .cmd_done       (cmd_done       ),
    .cmd_error      (cmd_error      ),
    .cmd_rollback   (cmd_rollback   ),
    .i2c_slave_addr (i2c_slave_addr ),
    .i2c_read_write (i2c_read_write ),
    .i2c_addr_length(i2c_addr_length),
    .i2c_start_addr (i2c_start_addr ),
    .i2c_data_length(i2c_data_length),
    .wr_data_ready  (i2c_wr_fifo_rd_en  ),
    .wr_data        (i2c_wr_fifo_rd_data),
    .rd_data_valid  (i2c_rd_fifo_wr_en  ),
    .rd_data        (i2c_rd_fifo_wr_data)
);

endmodule
// I2C Master AXI Slave Interface