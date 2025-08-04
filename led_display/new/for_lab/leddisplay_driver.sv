module leddisplay_driver #(
    parameter [7:0]  NUM = 4,
    parameter [31:0] CLK_CYCLE = 1000,
    parameter mode = 0     //0 : 0号位数码管显示led高位，1 : 0号位数码管显示led低位
)(
    input             clk                    ,
    input             rstn                   ,
    input     [NUM * 8 - 1 : 0] led_in       ,      //31~0
    output reg        ser                    ,      //串行输出，先输出Q15，最后输出Q0
    output reg        sck                    ,      //串行输出时钟
    output reg        rck                           //并行输出时钟
);
localparam DIV_CLK = 4; //4分频
reg [15:0] sck_cnt;
always @(posedge sck or negedge rstn) begin
    if(~rstn) sck_cnt <= 0;
    else sck_cnt <= sck_cnt + 1;
end
wire seg_change = (sck_cnt == CLK_CYCLE/DIV_CLK) ? 1'b1 : 1'b0; //来一次刷新一个数码管
//*********************************************//
//偶数分频，产生sck
reg [3:0] cnt;
always@(posedge clk or negedge rstn)begin
    if(~rstn)
        cnt <=  'd0;
    else if(cnt == DIV_CLK)
        cnt <=  2'd0;
    else
        cnt <=  cnt +   1'b1;
end
always@(posedge clk or negedge rstn)begin
    if(~rstn)
        sck <=  1'b0;
    else if(cnt >= DIV_CLK/2)
        sck <=  1'b1;
    else
        sck <=  1'b0;
end
//*********************************************//
wire [7:0] led_display_seg[NUM - 1 : 0];
genvar i;
generate
    for (i = 0;i < NUM ; i++) begin
        assign led_display_seg[i] = led_in[8*(i+1)-1 : 8*i];
    end
endgenerate
reg [15:0] data;
reg tx_en;
wire tx_done;
reg [7:0] tx_cnt;
reg  [4:0] select_cnt; //0~31计数
wire [4:0] select_cnt_n; 
assign select_cnt_n = ~select_cnt;
assign tx_done      = tx_cnt == 16 ? 1'b1 : 1'b0;
always @(posedge sck or negedge rstn) begin
    if(~rstn) 
        data <= 0;
    else if(seg_change | tx_en)begin
        data <= {data[14: 0] ,data[15]};//移位，从最高位开始发送
    end
    else begin
        if(mode) data <= {3'b111,select_cnt , led_display_seg[select_cnt]};//先发sel，然后seg 
        else     data <= {3'b111,select_cnt , led_display_seg[NUM - select_cnt - 1]};//先发sel，然后seg 
    end
end
//tx_en
always @(posedge sck or negedge rstn) begin
    if(~rstn) 
        tx_en <= 0;
    else if(seg_change) 
        tx_en <= 1;
    else if(tx_done) 
        tx_en <= 0;
    else 
        tx_en <= tx_en; 
end
//ser发送data最高位
always @(posedge sck or negedge rstn) begin
    if(~rstn) 
        ser <= 0;
    else if(seg_change | tx_en) 
        ser <= data[15];
    else if(tx_done) 
        ser <= 0;
    else 
        ser <= 0;
end
//tx_cnt
always @(posedge sck or negedge rstn) begin
    if(~rstn) 
        tx_cnt <= 0;
    else if(tx_en) 
        tx_cnt <= tx_cnt + 1;
    else if(tx_done) 
        tx_cnt <= 0;
    else 
        tx_cnt <= 0;
end
//rck
always @(posedge clk or negedge rstn) begin
    if(~rstn) 
        rck <= 0;
    else if(tx_cnt == 16 && cnt == 3) //????
        rck <= 1;
    else 
        rck <= 0;
end
// //rck不能这样写
// always @(posedge sck or negedge rstn) begin
//     if(~rstn) 
//         rck <= 0;
//     else if(tx_cnt == 16) 
//         rck <= 1;
//     else 
//         rck <= 0;
// end
always @(posedge sck or negedge rstn) begin
    if(~rstn) 
        select_cnt <= 0;
    else if(tx_done) 
        if (select_cnt == NUM - 1) 
            select_cnt <= 0;
        else 
            select_cnt <= select_cnt + 1;
    else 
        select_cnt <= select_cnt;
end

endmodule