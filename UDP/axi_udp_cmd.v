module axi_udp_cmd  (
    input  wire        gmii_rx_clk         ,//125M
    input  wire        rstn                ,
    //___________________AXI接口_____________________//
    output wire        MASTER_CLK          , //向AXI总线提供的本主机时钟信号
    output wire        MASTER_RSTN         , //向AXI总线提供的本主机复位信号

    output wire [ 3:0] MASTER_WR_ADDR_ID   , //写地址通道-ID
    output wire [31:0] MASTER_WR_ADDR      , //写地址通道-地址
    output wire [ 7:0] MASTER_WR_ADDR_LEN  , //写地址通道-突发长度-最小为0（1突发），最大为255（256突发）
    output wire [ 1:0] MASTER_WR_ADDR_BURST, //写地址通道-突发类型
    output wire        MASTER_WR_ADDR_VALID, //写地址通道-握手信号-有效
    input  wire        MASTER_WR_ADDR_READY, //写地址通道-握手信号-准备

    output wire [31:0] MASTER_WR_DATA      , //写数据通道-数据
    output wire [ 3:0] MASTER_WR_STRB      , //写数据通道-选通
    output wire        MASTER_WR_DATA_LAST , //写数据通道-last信号
    output wire        MASTER_WR_DATA_VALID, //写数据通道-握手信号-有效
    input  wire        MASTER_WR_DATA_READY, //写数据通道-握手信号-准备

    input  wire [ 3:0] MASTER_WR_BACK_ID   , //写响应通道-ID
    input  wire [ 1:0] MASTER_WR_BACK_RESP , //写响应通道-响应
    input  wire        MASTER_WR_BACK_VALID, //写响应通道-握手信号-有效
    output wire        MASTER_WR_BACK_READY, //写响应通道-握手信号-准备

    output reg  [ 3:0] MASTER_RD_ADDR_ID   , //读地址通道-ID
    output reg  [31:0] MASTER_RD_ADDR      , //读地址通道-地址
    output reg  [ 7:0] MASTER_RD_ADDR_LEN  , //读地址通道-突发长度。最小为0（1突发），最大为255（256突发）
    output reg  [ 1:0] MASTER_RD_ADDR_BURST, //读地址通道-突发类型。
    output reg         MASTER_RD_ADDR_VALID, //读地址通道-握手信号-有效
    input  wire        MASTER_RD_ADDR_READY, //读地址通道-握手信号-准备

    input  wire [ 3:0] MASTER_RD_BACK_ID   , //读数据通道-ID
    input  wire [31:0] MASTER_RD_DATA      , //读数据通道-数据
    input  wire [ 1:0] MASTER_RD_DATA_RESP , //读数据通道-响应
    input  wire        MASTER_RD_DATA_LAST , //读数据通道-last信号
    input  wire        MASTER_RD_DATA_VALID, //读数据通道-握手信号-有效
    output wire        MASTER_RD_DATA_READY, //读数据通道-握手信号-准备
    //___________________UDP接口_____________________//
    input  wire        udp_rx_done    ,
    input  wire [31:0] udp_rx_data    ,
    input  wire        udp_rx_en      ,
 
    input  wire        udp_tx_req     ,
    output reg         udp_tx_start   ,
    output      [31:0] udp_tx_data     
);

localparam IDLE      = 0;
localparam ADDR      = 1;
localparam DATA      = 2;
reg [4:0] head_cnt;
reg [4:0] state, next_state;
reg [63:0] head_data;
//data_fifo
wire data_fifo_rx_en;
reg data_fifo_en;
//cmd_fifo
wire cmd_fifo_rx_en;
wire cmd_fifo_empty;
reg cmd_fifo_rd_en;
wire [32:0] cmd_fifo_rd_data;
//wr_addr_fifo
wire wraddr_fifo_empty;
reg wraddr_fifo_wr_en;
reg wraddr_fifo_rd_en;
reg [63:0] wraddr_fifo_wr_data;
//rd_addr
wire rdaddr_fifo_empty;
reg rdaddr_fifo_wr_en;
reg rdaddr_fifo_rd_en;
reg [63:0] rdaddr_fifo_wr_data; 

assign cmd_fifo_rx_en  = udp_rx_en && ~data_fifo_en;
assign data_fifo_rx_en = udp_rx_en &&  data_fifo_en;


always @(posedge gmii_rx_clk or negedge rstn) begin
    if(!rstn)
        state <= next_state;
    else
        state <= next_state;
end

always @(*) begin
    next_state = IDLE;
    case(state)
        IDLE : begin                                  
            if(cmd_fifo_rd_en) begin
                if(cmd_fifo_rd_data[31:24] == 8'hFF)
                    next_state <= DATA;
                else if(cmd_fifo_rd_data[31:24] == 8'h00)
                    next_state <= ADDR;
                else 
                    next_state <= IDLE; 
            end
            else 
                next_state = IDLE;
        end
        ADDR : begin
            if(cmd_fifo_rd_data[32] && head_cnt == 3)
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
        default : next_state = IDLE;
    endcase
end
always @(posedge gmii_rx_clk ) begin
    if(~rstn)begin
        cmd_fifo_rd_en <= 0;
        wraddr_fifo_wr_en <= 1'b0;
        rdaddr_fifo_wr_en <= 1'b0;
        data_fifo_en <= 0;
        head_cnt <= 0;

    end
    else begin
        cmd_fifo_rd_en <= 1'b0;
        wraddr_fifo_wr_en <= 1'b0;
        rdaddr_fifo_wr_en <= 1'b0;
        case(state)
            IDLE : begin                                //取出第一个数据
                data_fifo_en <= 0;
                head_cnt <= 0;
                if(cmd_fifo_rx_en) begin 
                    cmd_fifo_rd_en <= 1'b1;//提前拉高
                end
                else begin
                    cmd_fifo_rd_en <= 1'b0;
                end
            end
            ADDR : begin    
                if(head_cnt == 0)begin                  //取数据
                    head_data[63:32] <= cmd_fifo_rd_data[31:0];
                    cmd_fifo_rd_en <= 1'b1;
                    head_cnt <= head_cnt + 1;
                end
                else if(head_cnt == 1)begin
                    head_data[31: 0] <= cmd_fifo_rd_data[31:0];
                    head_cnt <= head_cnt + 1;
                end
                else if(head_cnt == 2)begin
                    if(head_data[63:56] == 8'h00 && head_data[48] == 1)begin
                        wraddr_fifo_wr_data <= head_data;
                        wraddr_fifo_wr_en <= 1'b1;
                    end
                    else if(head_data[63:56] == 8'h00 && head_data[48] == 0)begin
                        rdaddr_fifo_wr_data <= head_data;
                        rdaddr_fifo_wr_en <= 1'b1;
                    end
                    if(cmd_fifo_rd_data[32]) head_cnt <= 3;
                    else head_cnt <= 0;
                end
            end
            DATA : begin                                 
                data_fifo_en <= 1;
                // if(MASTER_WR_BACK_VALID && MASTER_WR_BACK_READY)begin
                //     data_fifo_en <= 0;
                // end
            end
            default : ;
        endcase
    end
end
udp_cmd_fifo u_sync_fifo_64x33b_cmd (
    .clk             (gmii_rx_clk  ),              // input
    .rst             (~rstn        ),              // input
    .wr_en           (cmd_fifo_rx_en    ),            // input
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
  wr_addr_fifo u_sync_fifo_64x64b_wraddr (
    .clk             (gmii_rx_clk  ),              // input
    .rst             (~rstn        ),              // input
    .wr_en           ( wraddr_fifo_wr_en   ),            // input
    .wr_data         (wraddr_fifo_wr_data),          // input [31:0]
    .wr_full         (),          // output
//    .wr_water_level  (),   // output [12:0]
    .almost_full     (),      // output
    .rd_en           (wraddr_fifo_rd_en),            // input
    .rd_data         (),          // output [31:0]
    .rd_empty        (),         // output
//    .rd_water_level  (),   // output [12:0]
    .almost_empty    ()      // output
  );
  //******************************************************************//
//*****************************axi_rd_addr*******************************//
//******************************************************************//
  rd_addr_fifo u_sync_fifo_64x64b_rdaddr (
    .clk             (gmii_rx_clk  ),              // input
    .rst             (~rstn        ),              // input
    .wr_en           ( rdaddr_fifo_wr_en   ),            // input
    .wr_data         (rdaddr_fifo_wr_data),          // input [31:0]
    .wr_full         (),          // output
//    .wr_water_level  (),   // output [12:0]
    .almost_full     (),      // output
    .rd_en           (rdaddr_fifo_rd_en),            // input
    .rd_data         (),          // output [31:0]
    .rd_empty        (),         // output
//    .rd_water_level  (),   // output [12:0]
    .almost_empty    ()      // output
  );
//******************************************************************//
//*****************************axi_wr*******************************//
//******************************************************************//
udp_fifo_wr u_sync_fifo_2048x33b_wr (
    .clk             (gmii_rx_clk  ),              // input
    .rst             (~rstn        ),              // input
    .wr_en           (data_fifo_rx_en       ),            // input
    .wr_data         ({udp_rx_done,udp_rx_data} ),          // input [31:0]
    .wr_full         (),          // output
    .wr_water_level  (),   // output [12:0]
    .almost_full     (),      // output
    .rd_en           (),            // input
    .rd_data         (),          // output [31:0]
    .rd_empty        (),         // output
    .rd_water_level  (),   // output [12:0]
    .almost_empty    ()      // output
  );
//******************************************************************//
//*****************************axi_rd*******************************//
//******************************************************************//
udp_fifo_rd u_sync_fifo_2048x32b_rd (
    .clk             (gmii_rx_clk  ),              // input
    .rst             (~rstn        ),              // input
    .wr_en           (),            // input
    .wr_data         ( ),          // input [31:0]
    //.wr_full         (),          // output
    //.wr_water_level  (),   // output [12:0]
    .almost_full     (),      // output 设为1000
    .rd_en           (),            // input
    .rd_data         (),          // output [31:0]
    //.rd_empty        (),         // output
    //.rd_water_level  (),   // output [12:0]
    .almost_empty    ()      // output
  );


endmodule