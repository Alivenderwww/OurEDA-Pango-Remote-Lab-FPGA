module axi_udp_cmd  #(
    parameter RESET_ADDR = 32'h0000_0000 //复位地址
)(
    input  wire        gmii_rx_clk         /* synthesis PAP_MARK_DEBUG="true" */,//125M
    input  wire        rstn                ,
    output wire        SYSTEM_RESET        ,

    output wire  [7:0]  cmdled              ,
    //___________________AXI接口_____________________//
    output wire        MASTER_CLK          , //向AXI总线提供的本主机时钟信号
    output wire        MASTER_RSTN         , //向AXI总线提供的本主机复位信号

    output wire [ 1:0] MASTER_WR_ADDR_ID   /* synthesis PAP_MARK_DEBUG="true" */, //写地址通道-ID
    output wire [31:0] MASTER_WR_ADDR      /* synthesis PAP_MARK_DEBUG="true" */, //写地址通道-地址
    output wire [ 7:0] MASTER_WR_ADDR_LEN  /* synthesis PAP_MARK_DEBUG="true" */, //写地址通道-突发长度-最小为0（1突发），最大为255（256突发）
    output wire [ 1:0] MASTER_WR_ADDR_BURST/* synthesis PAP_MARK_DEBUG="true" */, //写地址通道-突发类型
    output reg         MASTER_WR_ADDR_VALID/* synthesis PAP_MARK_DEBUG="true" */, //写地址通道-握手信号-有效
    input  wire        MASTER_WR_ADDR_READY/* synthesis PAP_MARK_DEBUG="true" */, //写地址通道-握手信号-准备

    output wire [31:0] MASTER_WR_DATA      /* synthesis PAP_MARK_DEBUG="true" */, //写数据通道-数据
    output reg  [ 3:0] MASTER_WR_STRB      /* synthesis PAP_MARK_DEBUG="true" */, //写数据通道-选通
    output wire        MASTER_WR_DATA_LAST /* synthesis PAP_MARK_DEBUG="true" */, //写数据通道-last信号
    output wire        MASTER_WR_DATA_VALID/* synthesis PAP_MARK_DEBUG="true" */, //写数据通道-握手信号-有效
    input  wire        MASTER_WR_DATA_READY/* synthesis PAP_MARK_DEBUG="true" */, //写数据通道-握手信号-准备

    input  wire [ 1:0] MASTER_WR_BACK_ID    /* synthesis PAP_MARK_DEBUG="true" */, //写响应通道-ID
    input  wire [ 1:0] MASTER_WR_BACK_RESP  /* synthesis PAP_MARK_DEBUG="true" */, //写响应通道-响应
    input  wire        MASTER_WR_BACK_VALID /* synthesis PAP_MARK_DEBUG="true" */, //写响应通道-握手信号-有效
    output reg         MASTER_WR_BACK_READY /* synthesis PAP_MARK_DEBUG="true" */, //写响应通道-握手信号-准备

    output wire [ 1:0] MASTER_RD_ADDR_ID   /* synthesis PAP_MARK_DEBUG="true" */, //读地址通道-ID
    output wire [31:0] MASTER_RD_ADDR      /* synthesis PAP_MARK_DEBUG="true" */, //读地址通道-地址
    output wire [ 7:0] MASTER_RD_ADDR_LEN  /* synthesis PAP_MARK_DEBUG="true" */, //读地址通道-突发长度。最小为0（1突发），最大为255（256突发）
    output wire [ 1:0] MASTER_RD_ADDR_BURST/* synthesis PAP_MARK_DEBUG="true" */, //读地址通道-突发类型。
    output reg         MASTER_RD_ADDR_VALID/* synthesis PAP_MARK_DEBUG="true" */, //读地址通道-握手信号-有效
    input  wire        MASTER_RD_ADDR_READY/* synthesis PAP_MARK_DEBUG="true" */, //读地址通道-握手信号-准备

    input  wire [ 1:0] MASTER_RD_BACK_ID   /* synthesis PAP_MARK_DEBUG="true" */, //读数据通道-ID
    input  wire [31:0] MASTER_RD_DATA      /* synthesis PAP_MARK_DEBUG="true" */, //读数据通道-数据
    input  wire [ 1:0] MASTER_RD_DATA_RESP /* synthesis PAP_MARK_DEBUG="true" */, //读数据通道-响应
    input  wire        MASTER_RD_DATA_LAST /* synthesis PAP_MARK_DEBUG="true" */, //读数据通道-last信号
    input  wire        MASTER_RD_DATA_VALID/* synthesis PAP_MARK_DEBUG="true" */, //读数据通道-握手信号-有效
    output reg         MASTER_RD_DATA_READY/* synthesis PAP_MARK_DEBUG="true" */, //读数据通道-握手信号-准备
    //___________________UDP接口_____________________//
    input  wire        udp_rx_done    /* synthesis PAP_MARK_DEBUG="true" */,
    input  wire [31:0] udp_rx_data    /* synthesis PAP_MARK_DEBUG="true" */,
    input  wire        udp_rx_en      /* synthesis PAP_MARK_DEBUG="true" */,
 
    input              udp_tx_done    ,
    input  wire        udp_tx_req     ,
    output reg         udp_tx_start   ,
    output      [31:0] udp_tx_data    ,
    output reg  [15:0] udp_tx_byte_num 
);

localparam IDLE      = 0;
localparam WAIT      = 1;
localparam ADDR      = 2;
localparam DATA      = 3;
reg [4:0] head_cnt/* synthesis PAP_MARK_DEBUG="true" */;
reg [4:0] state/* synthesis PAP_MARK_DEBUG="true" */;
reg [4:0] next_state/* synthesis PAP_MARK_DEBUG="true" */;
reg [63:0] head_data/* synthesis PAP_MARK_DEBUG="true" */;
reg  head_rx_done/* synthesis PAP_MARK_DEBUG="true" */;
//仲裁
localparam TXIDLE   = 0;
localparam TXWRBACK = 1; // 优先级高
localparam TXRDDATA = 2;
reg [4:0] tx_state;
reg wrback_tx_done;
reg rddata_tx_done;
//cmd_fifo
wire cmd_fifo_wr_en;
wire cmd_fifo_empty;
reg cmd_fifo_rd_en;
wire [32:0] cmd_fifo_rd_data;

//wr_addr_fifo
wire wraddr_fifo_empty;
reg wraddr_fifo_wr_en;
reg wraddr_fifo_rd_en;
reg [63:0] wraddr_fifo_wr_data;
wire[63:0] wraddr_fifo_rd_data;
reg [4 :0] wraddr_fifo_rd_cnt; //类似状态机
//rd_addr
wire rdaddr_fifo_empty;
reg rdaddr_fifo_wr_en;
reg rdaddr_fifo_rd_en;
reg [63:0] rdaddr_fifo_wr_data; 
wire[63:0] rdaddr_fifo_rd_data;
reg [4 :0] rdaddr_fifo_rd_cnt; //类似状态机
//wrback_fifo
reg [31:0] wrback_fifo_wr_data /* synthesis PAP_MARK_DEBUG="true" */; 
reg wrback_fifo_wr_en /* synthesis PAP_MARK_DEBUG="true" */;
wire wrback_fifo_rd_en /* synthesis PAP_MARK_DEBUG="true" */;
wire wrback_fifo_full /* synthesis PAP_MARK_DEBUG="true" */;
wire wrback_fifo_empty /* synthesis PAP_MARK_DEBUG="true" */;
wire [6:0] wrback_fifo_wr_water_level /* synthesis PAP_MARK_DEBUG="true" */;
reg [4:0] wrback_fifo_rd_cnt /* synthesis PAP_MARK_DEBUG="true" */;//类似状态机
wire [31:0] wrback_fifo_rd_data /* synthesis PAP_MARK_DEBUG="true" */;
reg wrback_tx_start_req /* synthesis PAP_MARK_DEBUG="true" */;
wire [6:0] wrback_fifo_rd_water_level /* synthesis PAP_MARK_DEBUG="true" */;
//wrdata_fifo
wire wrdata_fifo_empty;
wire wrdata_fifo_wr_en; reg wrdata_fifo_wr_en_reg;
wire wrdata_fifo_rd_en; reg wrdata_fifo_rd_en_reg;
reg [4:0] wrdata_fifo_rd_cnt;//类似状态机
//rddata_fifo
wire rddata_fifo_wr_en;
wire rddata_fifo_empty;
wire [11:0] rddata_fifo_rd_water_level;
wire [31:0] rddata_head;
reg [4:0] rddata_fifo_rd_cnt;//类似状态机
reg rddata_tx_start_req;
wire rddata_fifo_rd_en;
wire[31:0] rddata_fifo_rd_data;
assign cmd_fifo_wr_en  = udp_rx_en && ~wrdata_fifo_wr_en_reg;
assign wrdata_fifo_wr_en = udp_rx_en &&  wrdata_fifo_wr_en_reg;

reg SYSTEM_RESET_TRIG;
reg [10:0] SYSTEM_RESET_DELAY;
wire SYSTEM_RESET = (SYSTEM_RESET_DELAY != 0);
always @(posedge gmii_rx_clk or posedge SYSTEM_RESET_TRIG) begin
    if(SYSTEM_RESET_TRIG) begin
        SYSTEM_RESET_DELAY <= 1;
    end else if(SYSTEM_RESET_DELAY != 0)begin
        SYSTEM_RESET_DELAY <= SYSTEM_RESET_DELAY + 1;
    end else SYSTEM_RESET_DELAY <= 0;
end

//debug
assign cmdled = {3'b000, wraddr_fifo_empty, rdaddr_fifo_empty, wrback_fifo_empty, wrdata_fifo_empty, rddata_fifo_empty};
reg [1:0] rdaddr_cnt;
reg  rdaddr_fifo_wr_en_cnt;
reg  rdaddr_fifo_rd_en_cnt;
reg  wraddr_fifo_wr_en_cnt;
reg  wraddr_fifo_rd_en_cnt;
reg udp_tx_done_cnt;
always @(posedge gmii_rx_clk or negedge rstn)begin
    if(~rstn)begin
        rdaddr_cnt <= 0; 
    end
    else if(MASTER_RD_ADDR_READY && MASTER_RD_ADDR_VALID)begin
        rdaddr_cnt <= rdaddr_cnt + 1;
    end
    
    if(~rstn)begin
        rdaddr_fifo_wr_en_cnt <= 0; 
    end
    else if(rdaddr_fifo_wr_en)begin
        rdaddr_fifo_wr_en_cnt <= rdaddr_fifo_wr_en_cnt + 1;
    end

    if(~rstn)begin
        rdaddr_fifo_rd_en_cnt <= 0; 
    end
    else if(rdaddr_fifo_rd_en)begin
        rdaddr_fifo_rd_en_cnt <= rdaddr_fifo_rd_en_cnt + 1;
    end

    if(~rstn)begin
        udp_tx_done_cnt <= 0; 
    end
    else if(udp_tx_done)begin
        udp_tx_done_cnt <= udp_tx_done_cnt + 1;
    end

    if(~rstn)begin
        wraddr_fifo_wr_en_cnt <= 0; 
    end
    else if(wraddr_fifo_wr_en)begin
        wraddr_fifo_wr_en_cnt <= wraddr_fifo_wr_en_cnt + 1;
    end

    if(~rstn)begin
        wraddr_fifo_rd_en_cnt <= 0; 
    end
    else if(wraddr_fifo_rd_en)begin
        wraddr_fifo_rd_en_cnt <= wraddr_fifo_rd_en_cnt + 1;
    end
end

assign udp_tx_data = (tx_state == TXWRBACK) ? wrback_fifo_rd_data : (rddata_fifo_rd_cnt == 3 && tx_state == TXRDDATA) ? rddata_head : rddata_fifo_rd_data ;

assign MASTER_CLK  = gmii_rx_clk;
assign MASTER_RSTN = rstn;

always @(posedge gmii_rx_clk or negedge rstn) begin
    if(!rstn)
        state <= IDLE;
    else
        state <= next_state;
end

always @(*) begin
    next_state <= IDLE;
    case(state)
        IDLE : begin                                  
            if(cmd_fifo_wr_en) begin
                if(udp_rx_data[31:24] == 8'hFF)
                    next_state <= DATA;
                else if(udp_rx_data[31:24] == 8'h00)
                    next_state <= WAIT;
                else 
                    next_state <= IDLE; 
            end
            else 
                next_state <= IDLE;
        end
        WAIT : begin
            if(udp_rx_done)
                next_state <= ADDR;
            else 
                next_state <= WAIT;
        end
        ADDR : begin
            if(head_cnt == 4)
                next_state <= IDLE;
            else 
                next_state <= ADDR;
        end
        DATA : begin                                 
            if(udp_rx_done)
                next_state <= IDLE;
            else 
                next_state <= DATA;
        end
        default : next_state <= IDLE;
    endcase
end
always @(posedge gmii_rx_clk ) begin
    if(~rstn)begin
        cmd_fifo_rd_en <= 0;
        wraddr_fifo_wr_en <= 1'b0;
        wraddr_fifo_wr_data <= 0;
        rdaddr_fifo_wr_en <= 1'b0;
        wrdata_fifo_wr_en_reg <= 0;
        head_cnt <= 0;
        head_data <= 0;
        rdaddr_fifo_wr_data <= 0;
        head_rx_done <= 0;
        SYSTEM_RESET_TRIG <= 0;
    end
    else begin
//        cmd_fifo_rd_en <= 1'b0;
        wraddr_fifo_wr_en <= 1'b0;
        rdaddr_fifo_wr_en <= 1'b0;
        case(state)
            IDLE : begin                                //取出第一个数据
                wrdata_fifo_wr_en_reg <= 0;
                head_cnt <= 0;
                head_rx_done <= 0;
                if(cmd_fifo_wr_en) begin 
                    cmd_fifo_rd_en <= 1'b1;//提前拉高
                end
                else begin
                    cmd_fifo_rd_en <= 1'b0;
                end
            end
            WAIT : begin
                 cmd_fifo_rd_en <= 1'b0;

                end
            ADDR : begin    
                if(head_cnt == 0)begin                  //取数据
                    head_data[63:32] <= cmd_fifo_rd_data[31:0];
                    cmd_fifo_rd_en <= 1'b1;
                    head_cnt <= head_cnt + 1;
                end
                if(head_cnt == 1)begin//等待数据准备好
                    head_cnt <= head_cnt + 1;
                end
                if(head_cnt == 2)begin//将第二个数据写入
                    head_data[31: 0] <= cmd_fifo_rd_data[31:0];
                    head_cnt <= head_cnt + 1;
                    rdaddr_fifo_wr_en <= 1'b0;
                    wraddr_fifo_wr_en <= 1'b0;
                    head_rx_done      <= cmd_fifo_rd_data[32];
                end
                if(head_cnt == 3)begin//判断是读地址还是写地址
                    if(head_data[63:56] == 8'h00 && head_data[48] == 1)begin
                        wraddr_fifo_wr_data <= head_data;
                        SYSTEM_RESET_TRIG <= (head_data[31:0] == RESET_ADDR);
                        wraddr_fifo_wr_en <= 1'b1;
                    end
                    else if(head_data[63:56] == 8'h00 && head_data[48] == 0)begin
                        rdaddr_fifo_wr_data <= head_data;
                        rdaddr_fifo_wr_en <= 1'b1;
                    end
                    if(head_rx_done)begin
                        head_cnt <= 4;
                        cmd_fifo_rd_en <= 1'b0;
                    end 
                    else begin
                        head_data[63:32] <= cmd_fifo_rd_data[31:0];
                        cmd_fifo_rd_en <= 1'b1;
                        head_cnt <= 2;
                    end
                end
            end
            DATA : begin                                 
                wrdata_fifo_wr_en_reg <= 1;
                // if(MASTER_WR_BACK_VALID && MASTER_WR_BACK_READY)begin
                //     wrdata_fifo_wr_en_reg <= 0;
                // end
            end
            default : ;
        endcase
    end
end
udp_cmd_fifo u_sync_fifo_512x33b_cmd (
    .clk             (gmii_rx_clk  ),              // input
    .rst             (~rstn        ),              // input
    .wr_en           (cmd_fifo_wr_en    ),            // input
    .wr_data         ({udp_rx_done,udp_rx_data}),          // input [31:0]
    .wr_full         (),          // output
//    .wr_water_level  (),   // output [12:0]
    .almost_full     (),      // output
    .rd_en           (cmd_fifo_rd_en),            // input
    .rd_data         (cmd_fifo_rd_data),          // output [31:0]
    .rd_empty        (cmd_fifo_empty),         // output
//    .rd_water_level  (),   // output [12:0]
    .almost_empty    ()      // output
  );
//******************************************************************//
//*****************************axi_wr_addr*******************************//
//******************************************************************//
//wraddr //如果地址fifo非空，并且valid为低，那么取出数据使能，等待一个时钟周期，取出数据，拉高valid，握手成功拉低valid
assign MASTER_WR_ADDR_ID    = wraddr_fifo_rd_data[53:52];
assign MASTER_WR_ADDR       = wraddr_fifo_rd_data[31: 0];
assign MASTER_WR_ADDR_LEN   = wraddr_fifo_rd_data[47:40];
assign MASTER_WR_ADDR_BURST = wraddr_fifo_rd_data[55:54];

always @(posedge gmii_rx_clk ) begin
    if(~rstn) begin
        wraddr_fifo_rd_cnt <= 0;
        MASTER_WR_ADDR_VALID <= 0;
        wraddr_fifo_rd_en <= 0;
    end
    else if(wraddr_fifo_rd_cnt == 0 && MASTER_WR_ADDR_VALID == 0 && ~wraddr_fifo_empty)begin
        wraddr_fifo_rd_en <= 1;//拉高一个时钟周期取出一个数据
        wraddr_fifo_rd_cnt <= wraddr_fifo_rd_cnt + 1;
    end
    else if(wraddr_fifo_rd_cnt == 1)begin
        wraddr_fifo_rd_en <= 0;
        wraddr_fifo_rd_cnt <= wraddr_fifo_rd_cnt + 1;
    end
    else if(wraddr_fifo_rd_cnt == 2 )begin
        if(MASTER_WR_ADDR_READY && MASTER_WR_ADDR_VALID)begin
            MASTER_WR_ADDR_VALID <= 0;
            wraddr_fifo_rd_cnt <= 0;
        end
        else begin
            MASTER_WR_ADDR_VALID <= 1;
            wraddr_fifo_rd_cnt <= wraddr_fifo_rd_cnt;
        end
    end
end
wr_addr_fifo u_sync_fifo_512x64b_wraddr (
  .clk             (gmii_rx_clk  ),              // input
  .rst             (~rstn        ),              // input
  .wr_en           ( wraddr_fifo_wr_en   ),            // input
  .wr_data         (wraddr_fifo_wr_data),          // input [31:0]
  .wr_full         (),          // output
//    .wr_water_level  (),   // output [12:0]
  .almost_full     (),      // output
  .rd_en           (wraddr_fifo_rd_en),            // input
  .rd_data         (wraddr_fifo_rd_data),          // output [31:0]
  .rd_empty        (wraddr_fifo_empty),         // output
//    .rd_water_level  (),   // output [12:0]
  .almost_empty    ()      // output
);
//******************************************************************//
//*****************************axi_rd_addr**************************//
//******************************************************************//
assign MASTER_RD_ADDR_ID    = rdaddr_fifo_rd_data[53:52];
assign MASTER_RD_ADDR       = rdaddr_fifo_rd_data[31: 0];
assign MASTER_RD_ADDR_LEN   = rdaddr_fifo_rd_data[47:40];
assign MASTER_RD_ADDR_BURST = rdaddr_fifo_rd_data[55:54];

always @(posedge gmii_rx_clk ) begin
    if(~rstn) begin
        rdaddr_fifo_rd_cnt <= 0;
        MASTER_RD_ADDR_VALID <= 0;
        rdaddr_fifo_rd_en <= 0;
    end
    else if(rdaddr_fifo_rd_cnt == 0 && MASTER_RD_ADDR_VALID == 0 && ~rdaddr_fifo_empty)begin
        rdaddr_fifo_rd_en <= 1;//拉高一个时钟周期取出一个数据
        rdaddr_fifo_rd_cnt <= rdaddr_fifo_rd_cnt + 1;
    end
    else if(rdaddr_fifo_rd_cnt == 1)begin
        rdaddr_fifo_rd_en <= 0;
        rdaddr_fifo_rd_cnt <= rdaddr_fifo_rd_cnt + 1;
    end
    else if(rdaddr_fifo_rd_cnt == 2 )begin
        if(MASTER_RD_ADDR_READY && MASTER_RD_ADDR_VALID)begin
            MASTER_RD_ADDR_VALID <= 0;
            rdaddr_fifo_rd_cnt <= 0;
        end
        else begin
            MASTER_RD_ADDR_VALID <= 1;
            rdaddr_fifo_rd_cnt <= rdaddr_fifo_rd_cnt;
        end
    end
end
rd_addr_fifo u_sync_fifo_512x64b_rdaddr (
    .clk             (gmii_rx_clk  ),              // input
    .rst             (~rstn        ),              // input
    .wr_en           ( rdaddr_fifo_wr_en   ),            // input
    .wr_data         (rdaddr_fifo_wr_data),          // input [31:0]
    .wr_full         (),          // output
//    .wr_water_level  (),   // output [12:0]
    .almost_full     (),      // output
    .rd_en           (rdaddr_fifo_rd_en),            // input
    .rd_data         (rdaddr_fifo_rd_data),          // output [31:0]
    .rd_empty        (rdaddr_fifo_empty),         // output
//    .rd_water_level  (),   // output [12:0]
    .almost_empty    ()      // output
);
//******************************************************************//
//*****************************axi_wrback***************************//
//******************************************************************//
//wrback
assign wrback_fifo_rd_en = (tx_state == TXWRBACK) ? udp_tx_req : 0;
always @(posedge gmii_rx_clk ) begin
    if(~rstn)begin
        MASTER_WR_BACK_READY <= 0;
        wrback_fifo_wr_en <= 0;
        wrback_fifo_wr_data <= 0;
    end
    else if(~wrback_fifo_full) begin
        MASTER_WR_BACK_READY <= 1;
        if(MASTER_WR_BACK_READY && MASTER_WR_BACK_VALID) begin
            wrback_fifo_wr_data <= {8'hf0,6'b000000,MASTER_WR_BACK_ID,6'b000000,MASTER_WR_BACK_RESP,8'h00};
            wrback_fifo_wr_en <= 1;
        end
        else begin
            wrback_fifo_wr_data <= wrback_fifo_wr_data;
            wrback_fifo_wr_en <= 0;
        end
    end
    else if(wrback_fifo_full)begin
        MASTER_WR_BACK_READY <= 0;
        wrback_fifo_wr_en <= 0;
    end
end
always @(posedge gmii_rx_clk ) begin
    if(~rstn)begin
        wrback_fifo_rd_cnt <= 0;
        wrback_tx_start_req <= 0;
    end
    else if(wrback_fifo_rd_cnt == 0)begin
        if(~wrback_fifo_empty)begin
            wrback_tx_start_req <= 1;
            wrback_fifo_rd_cnt <= wrback_fifo_rd_cnt + 1;
        end
    end
    else if(wrback_fifo_rd_cnt == 1)begin
        if(tx_state == 1)begin
            wrback_tx_start_req <= 0;
        end
        if(wrback_tx_done)begin
            wrback_fifo_rd_cnt <= 0;
        end
    end
end
udp_fifo_wrback u_sync_fifo_64x32b_wrback (
    .clk             (gmii_rx_clk  ),              // input
    .rst             (~rstn        ),              // input
    .wr_en           (wrback_fifo_wr_en ),            // input
    .wr_data         (wrback_fifo_wr_data),          // input [31:0]
    .wr_full         (wrback_fifo_full),          // output
    .wr_water_level  (wrback_fifo_wr_water_level),                        // output [12:0]
    .almost_full     (),                        // output
    .rd_en           (wrback_fifo_rd_en),                        // input
    .rd_data         (wrback_fifo_rd_data),                        // output [31:0]
    .rd_empty        (wrback_fifo_empty),                        // output
    .rd_water_level  (wrback_fifo_rd_water_level),                        // output [12:0]
    .almost_empty    ()                         // output
  );
//******************************************************************//
//*****************************axi_wr*******************************//
//******************************************************************//
//wrdata
assign wrdata_fifo_rd_en = wrdata_fifo_rd_en_reg || (MASTER_WR_DATA_READY && MASTER_WR_DATA_VALID && ~MASTER_WR_DATA_LAST && ~wrdata_fifo_empty);
assign MASTER_WR_DATA_VALID = (wrdata_fifo_rd_cnt == 2 && (~wrdata_fifo_empty || MASTER_WR_DATA_LAST)); 
always @(posedge gmii_rx_clk ) begin
    if(~rstn)begin
        wrdata_fifo_rd_cnt <= 0;
        wrdata_fifo_rd_en_reg <= 0;
        MASTER_WR_STRB <= 4'b1111;
        // MASTER_WR_DATA_VALID <= 0;
    end
    else if(wrdata_fifo_rd_cnt == 0 && ~wrdata_fifo_empty )begin
        wrdata_fifo_rd_en_reg <= 1;
        wrdata_fifo_rd_cnt <= wrdata_fifo_rd_cnt + 1;
    end
    else if(wrdata_fifo_rd_cnt == 1 )begin
        wrdata_fifo_rd_en_reg <= 0;
        wrdata_fifo_rd_cnt <= wrdata_fifo_rd_cnt + 1;
    end
    else if(wrdata_fifo_rd_cnt == 2 )begin
        if(MASTER_WR_DATA_VALID && MASTER_WR_DATA_READY && MASTER_WR_DATA_LAST )begin
            // MASTER_WR_DATA_VALID <= 0;
            wrdata_fifo_rd_cnt <= 0;
        end
        else if(MASTER_WR_DATA_LAST)begin
            // MASTER_WR_DATA_VALID <= 1;
        end
        else if(wrdata_fifo_empty)begin
            // MASTER_WR_DATA_VALID <= 0;
        end
        else begin
            // MASTER_WR_DATA_VALID <= 1;
            wrdata_fifo_rd_cnt <= wrdata_fifo_rd_cnt;
        end
    end
end
udp_fifo_wr u_sync_fifo_2048x33b_wr (
    .clk             (gmii_rx_clk  ),              // input
    .rst             (~rstn        ),              // input
    .wr_en           (wrdata_fifo_wr_en       ),            // input
    .wr_data         ({udp_rx_done,udp_rx_data} ),          // input [31:0]
    .wr_full         (),          // output
    .wr_water_level  (),   // output [12:0]
    .almost_full     (),      // output
    .rd_en           (wrdata_fifo_rd_en),            // input
    .rd_data         ({MASTER_WR_DATA_LAST,MASTER_WR_DATA}),          // output [31:0]
    .rd_empty        (wrdata_fifo_empty),         // output
    .rd_water_level  (),   // output [12:0]
    .almost_empty    ()      // output
  );
//******************************************************************//
//*****************************axi_rd*******************************//
//******************************************************************//

  //传输长度还没写
assign rddata_head = MASTER_RD_DATA_LAST ? {8'h0F,6'b000000,MASTER_RD_BACK_ID,6'b000000,MASTER_RD_DATA_RESP,8'h00} : rddata_head;
assign rddata_fifo_wr_en = MASTER_RD_DATA_VALID && MASTER_RD_DATA_READY;

assign rddata_fifo_rd_en = (rddata_fifo_rd_cnt == 3 || rddata_fifo_rd_cnt == 4) ? udp_tx_req : 0 ;////3或者4不太好，应该用格雷码
always @(posedge gmii_rx_clk ) begin
    if(~rstn)begin
        MASTER_RD_DATA_READY <= 0;
        rddata_fifo_rd_cnt <= 0;
        // rddata_head <= 0;
        rddata_tx_start_req <= 0;
        // rddata_tx_req_en <= 0;
    end
    else if(rddata_fifo_empty && rddata_fifo_rd_cnt == 0)begin
        MASTER_RD_DATA_READY <= 1;
        rddata_fifo_rd_cnt <= rddata_fifo_rd_cnt + 1;
    end
    else if(MASTER_RD_DATA_LAST && MASTER_RD_DATA_VALID && MASTER_RD_DATA_READY && rddata_fifo_rd_cnt == 1)begin
        MASTER_RD_DATA_READY <= 0;
        rddata_fifo_rd_cnt <= rddata_fifo_rd_cnt + 1;
        rddata_tx_start_req <= 1;
    end
    else if(rddata_fifo_rd_cnt == 2 && tx_state == TXRDDATA)begin//回应请求
        rddata_tx_start_req <= 0;
        if(udp_tx_req)begin //进入下一个状态，把head送上去
            rddata_fifo_rd_cnt <= rddata_fifo_rd_cnt + 1;
        end
    end
    else if(rddata_fifo_rd_cnt == 3 && tx_state == TXRDDATA)begin//发送head
        rddata_tx_start_req <= 0;
        if(udp_tx_req)begin//进入下一个状态，并且把fifo数据送上去
            rddata_fifo_rd_cnt <= rddata_fifo_rd_cnt + 1;
        end
    end
    else if(rddata_fifo_rd_cnt == 4 && rddata_tx_done )begin
        rddata_fifo_rd_cnt <= 0;
    end
end
udp_fifo_rd u_sync_fifo_2048x32b_rd (
    .clk             (gmii_rx_clk  ),              // input
    .rst             (~rstn        ),              // input
    .wr_en           (rddata_fifo_wr_en),            // input
    .wr_data         ( MASTER_RD_DATA ),          // input [31:0]
    //.wr_full         (),          // output
    //.wr_water_level  (),   // output [12:0]
    .almost_full     (),      // output 设为1000
    .rd_en           (rddata_fifo_rd_en),            // input
    .rd_data         (rddata_fifo_rd_data),          // output [31:0]
    .rd_empty        (rddata_fifo_empty),         // output
    .rd_water_level  (rddata_fifo_rd_water_level),   // output [12:0]
    .almost_empty    ()      // output
  );



///_______________________仲裁发送请求________________________///

always @(posedge gmii_rx_clk ) begin
    if(~rstn)begin
        tx_state <= TXIDLE;
        udp_tx_byte_num <= 0;
        rddata_tx_done <= 0;
        wrback_tx_done <= 0;
        udp_tx_start <= 0;
    end
    else if(tx_state == TXIDLE)begin
        rddata_tx_done <= 0;
        wrback_tx_done <= 0;
        if(wrback_tx_start_req)begin
            udp_tx_byte_num <= wrback_fifo_rd_water_level*4;
            tx_state <= TXWRBACK;
            udp_tx_start <= 1;
        end
        else if(rddata_tx_start_req)begin
            tx_state <= TXRDDATA;
            udp_tx_byte_num <= (rddata_fifo_rd_water_level+1)*4;
            udp_tx_start <= 1;
        end
        else begin
            tx_state <= tx_state;  
        end
    end
    else if(tx_state == TXWRBACK)begin
        udp_tx_start <= 0;
        if(udp_tx_done)begin
            wrback_tx_done <= 1;
            tx_state <= TXIDLE;
        end
    end
    else if(tx_state == TXRDDATA)begin
        udp_tx_start <= 0;
        if(udp_tx_done)begin
            tx_state <= TXIDLE;
            rddata_tx_done <= 1;
        end
    end
end
endmodule