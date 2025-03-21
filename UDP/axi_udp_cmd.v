module axi_udp_cmd  (
    input wire gmii_rx_clk,            //125M
    input wire rstn,
    //AXI_master接口
    output reg [27:0] wr_addr        , //命令给出//addr握手之后就置为0
    output reg [ 7:0] wr_len         , //命令给出//一直保持到下一条指令
    output reg        wr_addr_valid  , //
    input wire        wr_addr_ready  , //

    output  [31:0] wr_data        , //
    output wire [ 3:0] wr_strb        , //
    output reg        wr_data_valid  , //
    input wire        wr_data_ready  , //
    output         wr_data_last   , //

    output reg [27:0] rd_addr        , //
    output reg [ 7:0] rd_len         , //
    output reg        rd_addr_valid  , //
    input wire        rd_addr_ready  , //

    input wire [31:0] rd_data        , //
    input wire        rd_data_last   , //
    output reg        rd_data_ready  , //
    input wire        rd_data_valid  , //
    
    // input wire        almost_full    , //
    //udp_rx
    input wire        rec_pkt_done   , //
    input wire [31:0] datain         , //
    input wire        rec_en         ,
    //udp_tx
    input wire        tx_req         , //
    output reg        tx_start_en    , //
    output     [31:0] udp_tx_data        
);
reg [7:0] wr_len_reg;
reg [7:0] rd_len_reg;
wire wr_almost_full;
reg rx_cmd_en;
reg [1:0] rx_cmd_en_cnt;
reg [63:0] cmddata;//接收的64位命令数据
reg rxcmdend;
reg wr_addr_en;//根据cmd判断是读还是写
reg rd_addr_en;
wire rd_en;
wire rx_data_valid;
wire rd_almost_full;
reg rd_almost_full_d0,rd_almost_full_d1;
wire wr_data_last_fifo;
wire wr_water_level,rd_water_level;
wire rd_empty;
reg wr_data_en;
assign wr_strb = 4'b1111;
//接受64位命令 接收完成后rxcmdend跳一个时钟周期
assign rx_data_valid = rec_en & (~rx_cmd_en);
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn) rx_cmd_en_cnt <= 0;
    else if(rx_cmd_en == 0 || rx_cmd_en_cnt == 2) rx_cmd_en_cnt <= 0;
    else if(rec_en) rx_cmd_en_cnt <= rx_cmd_en_cnt + 1;
    else rx_cmd_en_cnt <= rx_cmd_en_cnt;
end
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn) rx_cmd_en <= 1;
    else if(rec_pkt_done) rx_cmd_en <= 1;
    else if(rx_cmd_en_cnt >= 2) rx_cmd_en <= 0;
    else rx_cmd_en <= rx_cmd_en;
end
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn) cmddata <= 0;
    else if(rec_en && rx_cmd_en && rx_cmd_en_cnt <= 1) 
        cmddata <={cmddata[31:0],datain} ;
    else cmddata <= cmddata;
end
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn) rxcmdend <= 0;
    else if(rx_cmd_en == 1 && rx_cmd_en_cnt == 2)
        rxcmdend <= 1;
    else rxcmdend <= 0;
end
//judge
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn) begin
        wr_addr_en <= 0;
        wr_len <= 0;
        wr_addr <= 0;
    end
    else if(wr_addr_valid && wr_addr_ready) begin
        wr_addr_en <= 0;
        wr_addr <= 0;
    end
    else if(rxcmdend && (cmddata[63] == 1)) begin
        wr_addr_en <= cmddata[63];    //第一个字节的最高位
        wr_len <= cmddata[55:48];//第二个字节
        wr_addr <= cmddata[27: 0];
    end
    else begin
        wr_addr_en <= wr_addr_en;
        wr_len <= wr_len;
        wr_addr <= wr_addr;
    end

    
    if(~rstn) begin
        rd_addr_en <= 0;
        rd_len <= 0;
        rd_addr <= 0;
    end
    else if(rd_addr_valid && rd_addr_ready) begin
        rd_addr_en <= 0;
        rd_addr <= 0;
    end
    else if(rxcmdend && (cmddata[62] == 1)) begin
        rd_addr_en <= cmddata[62];    //
        rd_len <= cmddata[55:48];//第二个字节
        rd_addr <= cmddata[27: 0];
    end
    else begin
        rd_addr_en <= rd_addr_en;
        rd_len <= rd_len;
        rd_addr <= rd_addr;
    end
end
//addr
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn)
        wr_addr_valid <= 0;
    else if(wr_addr_valid && wr_addr_ready)
        wr_addr_valid <= 0;
    else if(wr_addr_en)
        wr_addr_valid <= 1;
    else 
        wr_addr_valid <= wr_addr_valid;

    if(~rstn)
        rd_addr_valid <= 0;
    else if(rd_addr_valid && rd_addr_ready)
        rd_addr_valid <= 0;
    else if(rd_addr_en)
        rd_addr_valid <= 1;
    else 
        rd_addr_valid <= rd_addr_valid;
end
//******************************************************************//
//*****************************axi_wr*******************************//
//******************************************************************//

always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn) wr_data_en <= 0;
    else if(wr_addr_en)  wr_data_en <= 1;
    else if(wr_data_valid) wr_data_en <= 0;
    else wr_data_en <= wr_data_en;
end

assign wr_data_last = wr_data_valid ? wr_data_last_fifo : 0;
assign rd_en = (( rec_pkt_done|| wr_almost_full )&& wr_data_en) || (wr_data_ready && wr_data_valid && ~wr_data_last);
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn) wr_data_valid <= 0;
    else if(wr_data_ready && wr_data_last)  wr_data_valid <= 0;
    else if(( rec_pkt_done|| wr_almost_full )&& wr_data_en) wr_data_valid <= 1;
    else wr_data_valid <= wr_data_valid;
end
udp_fifo_wr u_sync_fifo_2048x33b_wr (
    .clk             (gmii_rx_clk  ),              // input
    .rst             (~rstn        ),              // input
    .wr_en           (rx_data_valid       ),            // input
    .wr_data         ({rec_pkt_done,datain} ),          // input [31:0]
    .wr_full         (),          // output
    .wr_water_level  (wr_water_level),   // output [12:0]
    .almost_full     (wr_almost_full),      // output
    .rd_en           (rd_en),            // input
    .rd_data         ({wr_data_last_fifo,wr_data}),          // output [31:0]
    .rd_empty        (rd_empty),         // output
    .rd_water_level  (rd_water_level),   // output [12:0]
    .almost_empty    ()      // output
  );
//******************************************************************//
//*****************************axi_rd*******************************//
//******************************************************************//

  //tx_start_en 逻辑有问题，而且线还没有连，就是可能一次发送内en跳两下
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn) 
        tx_start_en <= 0;
    else if(tx_start_en) 
        tx_start_en <= 0;
    else if((rd_data_last && rd_data_ready && rd_data_valid))
        tx_start_en <= 1;
    else
        tx_start_en <= tx_start_en;
end
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn) rd_data_ready <= 0;
    else if(rd_data_valid && rd_data_last) rd_data_ready <= 0;
    else if(rd_addr_valid && rd_addr_ready) rd_data_ready <= 1;
    else rd_data_ready <= rd_data_ready;
end
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn)begin
        rd_almost_full_d0 <= 0;
        rd_almost_full_d1 <= 0;
    end
    else begin
        rd_almost_full_d0 <= rd_almost_full;
        rd_almost_full_d1 <= rd_almost_full_d0;
    end
end
udp_fifo_rd u_sync_fifo_2048x32b_rd (
    .clk             (gmii_rx_clk  ),              // input
    .rst             (~rstn        ),              // input
    .wr_en           (rd_data_valid       ),            // input
    .wr_data         (rd_data ),          // input [31:0]
    //.wr_full         (),          // output
    //.wr_water_level  (),   // output [12:0]
    .almost_full     (rd_almost_full),      // output 设为1000
    .rd_en           (tx_req),            // input
    .rd_data         (udp_tx_data),          // output [31:0]
    //.rd_empty        (),         // output
    //.rd_water_level  (),   // output [12:0]
    .almost_empty    ()      // output
  );


endmodule