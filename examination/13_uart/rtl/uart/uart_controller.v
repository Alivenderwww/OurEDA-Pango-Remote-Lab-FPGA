module uart_controller (
    input               clk,        //50M时钟
    input               reset,
    //output
    output reg [15:0]   out_addr,
    output reg [15:0]   out_data,
    output reg          en,
    //debug
    output  [7:0]       led,
    //uart interface
    output              tx,
    input               rx
);
//==========================
parameter IDLE   = 0;
parameter ERROR  = 1;
parameter rDATA  = 2;
//==========================
reg  [7:0]      txdata;         //要传输的数据tx
wire [7:0]      rxdata;         //接收的数据
reg             rdyclc;         //rdy清除信号
reg             txval;          //传输启动信号
wire            rxrdy;          //接收数据有效
wire            txbusy;         //传输忙
reg [7:0]       cmd;            //cmd暂存
reg [15:0]      addr;           //addr
reg [15:0]      data;           //data
reg [23:0]      enddata;       //
reg [7:0]       rxcnt;          //接收计数
reg rxrdyd0,rxrdyd1;            //rxrdy上升沿检测
// wire            en;           //tset检测成功信号
reg [7:0]       add;
reg [3:0]       state;          //系统状态机
//==========================debug
//assign led = ~{cmd[0],addr[11],addr[9],data[3],data[1],rxcnt[0],rst};
assign led = ~{rxdata};
//==========================复位
reg [31:0] watchdog_cnt;
//==========================接收
//rxrdy上升沿检测
always @(posedge clk ) begin
    if(reset)begin
        rxrdyd0 <= 0;
        rxrdyd1 <= 0;
    end
    else begin
        rxrdyd0 <= rxrdy;
        rxrdyd1 <= rxrdyd0;
    end
end
//移位寄存
always @(posedge clk ) begin
    if(reset) begin
        out_addr <= 0; out_data <= 0;
        rxcnt <= 0;
        cmd <= 0;addr <= 0;data <= 0; enddata <= 0;
        txval <= 0;txdata <= 0;
        watchdog_cnt <= 0;
        en <= 0;
    end 
    else begin
        if(watchdog_cnt >= 1_000_000_0) begin
            out_addr <= 0; out_data <= 0;
            rxcnt <= 0;
            cmd <= 0; addr <= 0; data <= 0; enddata <= 0;
            txval <= 0;txdata <= 0;
            watchdog_cnt <= 0;
            en <= 0;
        end else if(rxrdyd0 && ~rxrdyd1)begin
            watchdog_cnt <= 0;
            rxcnt <= rxcnt + 1;
            en <= 0;
            case (rxcnt)
                0:begin cmd            <= rxdata; end
                1:begin addr[15:8]     <= rxdata; end
                2:begin addr[ 7:0]     <= rxdata; end
                3:begin data[15:8]     <= rxdata; end
                4:begin data[ 7:0]     <= rxdata; end
                5:begin enddata[23:16] <= rxdata; end
                6:begin enddata[15: 8] <= rxdata; end
                7:begin enddata[ 7: 0] <= rxdata; end
                default: ;
            endcase
        end else if(rxcnt >= 8) begin
            watchdog_cnt <= 0;
            rxcnt <= 0;
            if(1) begin
                out_addr <= addr;
                out_data <= data;
                en <= 1;
            end
        end else begin
            {cmd,addr,data,enddata} <= {cmd,addr,data,enddata};
            en <= 0;
            watchdog_cnt <= watchdog_cnt + 1;
        end
    end
end
//rxrdy标志清除
always @(posedge clk ) begin
    if(reset) rdyclc <= 0;
    else if(rxrdy) rdyclc <= 1;
    else rdyclc <= 0;
end
// //add
// always @(posedge clk ) begin
//     if(rst) add <= 0;
//     else if(rxcnt == 6) add <= 0;
//     else if(rxrdyd0 && ~rxrdyd1 && rxcnt <= 4) add <= add + rxdata;
//     else add <= add;
// end
// assign en = (rxcnt == 6) ? 1 : 0;
//==========================发送
//==========================系统状态机
// parameter CMD_ADDR = 1;
// always @(posedge clk ) begin
//     if(rst) state <= IDLE;
//     else case(state)
//         IDLE: begin
//             if(en) state <= rDATA;
//         end
//     endcase
// end
//==========================地址译码decoder
// parameter Port0_en = 1;
// parameter Port1_en = 1;
// parameter Port2_en = 1;
// parameter Port3_en = 1;
// parameter Port4_en = 1;
// parameter Port5_en = 1;
// parameter Port6_en = 1;



//==========================uart
uart  uart_inst (
    .din            (txdata),       //要传输的数据tx
    .wr_en          (txval),        //传输启动信号
    .clk_50m        (clk),          //50M时钟
    .tx             (tx),           //接rx
    .tx_busy        (txbusy),       //传输忙
    .rx             (rx),           //接tx
    .rdy            (rxrdy),        //接收数据有效
    .rdy_clr        (rdyclc),       //rdy清除信号
    .dout           (rxdata)        //接收的数据
  );
endmodule