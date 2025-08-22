module led #(
    parameter CLK_CYCLE = 27000000
) (
    input clk,
    input rstn,
    output reg  [2:0] led1,//{红，黄，绿}
    output wire [2:0] led2,
    output reg  [2:0] led3,
    output wire [2:0] led4,
    output sck,
    output rck,
    output ser
); 
reg  [7:0] display1;
wire [7:0] display2;
reg  [7:0] display3;
wire [7:0] display4;
// localparam RED = 0;
// localparam YELLOW = 1;
// localparam GREEN = 2;
// localparam TWINKLE = 3;
assign led2 = led1;
assign led4 = led3;
assign display2 = display1;
assign display4 = display3;
reg [31:0] cnt1s;
reg [31:0] cnt500ms;
reg flag1s;
reg flag500ms;
reg [7:0] state;
reg [7:0] cnt12;
reg [7:0] cnt34;
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        cnt1s <= 0;
        flag1s <= 0;
    end
    else if(cnt1s == CLK_CYCLE - 1) begin
        cnt1s <= 0;
        flag1s <= 1;
    end
    else begin
        cnt1s <= cnt1s + 1;
        flag1s <= 0;
    end

    if(~rstn) begin
        cnt500ms <= 0;
        flag500ms <= 0;
    end
    else if(cnt500ms == CLK_CYCLE/2 - 1) begin
        cnt500ms <= 0;
        flag500ms <= 1;
    end
    else begin
        cnt500ms <= cnt500ms + 1;
        flag500ms <= 0;
    end
end
//7s红2s黄5s绿
always @(posedge clk or negedge rstn) begin
    if(~rstn) cnt12 <= 0;
    else if(cnt12 == 28) cnt12 <= 0;
    else if(flag500ms) cnt12 <= cnt12 + 1;
end
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        led1 <= 0;
    end
    else if(cnt12 < 14)begin
        led1 <= {1'b1,1'b0,1'b0};//红
    end
    else if(cnt12 >= 14 && cnt12 < 18)begin
        led1 <= {1'b0,1'b0,1'b1};
    end
    else if(cnt12 == 18 ) begin
        led1 <= {1'b0,1'b0,1'b0};
    end
    else if(cnt12 == 19 ) begin
        led1 <= {1'b0,1'b0,1'b1};
    end
    else if(cnt12 == 20 ) begin
        led1 <= {1'b0,1'b0,1'b0};
    end
    else if(cnt12 == 21 ) begin
        led1 <= {1'b0,1'b0,1'b1};
    end
    else if(cnt12 == 22 ) begin
        led1 <= {1'b0,1'b0,1'b0};
    end
    else if(cnt12 == 23 ) begin
        led1 <= {1'b0,1'b0,1'b1};
    end
    else if(cnt12 >= 24 && cnt12 < 28) begin
        led1 <= {1'b0,1'b1,1'b0};
    end
end

always @(posedge clk or negedge rstn) begin
    if(~rstn)
        led3 <= 0;
    else if(cnt12 < 4)
        led3 <= {1'b0,1'b0,1'b1};//绿；
    else if(cnt12 == 4)
        led3 <= {1'b0,1'b0,1'b0};
    else if(cnt12 == 5)
        led3 <= {1'b0,1'b0,1'b1};
    else if(cnt12 == 6)
        led3 <= {1'b0,1'b0,1'b0};
    else if(cnt12 == 7)
        led3 <= {1'b0,1'b0,1'b1};
    else if(cnt12 == 8)
        led3 <= {1'b0,1'b0,1'b0};
    else if(cnt12 == 9)
        led3 <= {1'b0,1'b0,1'b1};
    else if(cnt12 >= 10 && cnt12 < 14)
        led3 <= {1'b0,1'b1,1'b0};
    else if(cnt12 >= 14 && cnt12 < 28)
        led3 <= {1'b1,1'b0,1'b0};
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) 
        display1 <= 0;
    else if(cnt12 == 0)
        display1 <= "7";
    else if(cnt12 == 2)
        display1 <= "6";
    else if(cnt12 == 4)
        display1 <= "5";
    else if(cnt12 == 6)
        display1 <= "4";
    else if(cnt12 == 8)
        display1 <= "3";
    else if(cnt12 == 10)
        display1 <= "2";
    else if(cnt12 == 12)
        display1 <= "1";
    else if(cnt12 == 14)
        display1 <= "5";
    else if(cnt12 == 16)
        display1 <= "4";
    else if(cnt12 == 18)
        display1 <= "3";
    else if(cnt12 == 20)
        display1 <= "2";
    else if(cnt12 == 22)
        display1 <= "1";
    else if(cnt12 == 24)
        display1 <= "2";
    else if(cnt12 == 26)
        display1 <= "1";
    else 
        display1 <= display1;
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) 
        display3 <= 0;
    else if(cnt12 == 0)
        display3 <= "5";
    else if(cnt12 == 2)
        display3 <= "4";
    else if(cnt12 == 4)
        display3 <= "3";
    else if(cnt12 == 6)
        display3 <= "2";
    else if(cnt12 == 8)
        display3 <= "1";
    else if(cnt12 == 10)
        display3 <= "2";
    else if(cnt12 == 12)
        display3 <= "1";
    else if(cnt12 == 14)
        display3 <= "7";
    else if(cnt12 == 16)
        display3 <= "6";
    else if(cnt12 == 18)
        display3 <= "5";
    else if(cnt12 == 20)
        display3 <= "4";
    else if(cnt12 == 22)
        display3 <= "3";
    else if(cnt12 == 24)
        display3 <= "2";
    else if(cnt12 == 26)
        display3 <= "1";
    else 
        display3 <= display3;
end
wire [7:0]       seg;
wire [4:0]       sel;
hc595_ctrl  hc595_ctrl_inst (
    .sys_clk(clk),
    .sys_rst_n(rstn),
    .sel(sel),
    .seg(seg),
    .rck(rck),
    .sck(sck),
    .ser(ser)
  );
led_display_seg_ctrl # (
    .NUM(32),
    .MODE(1)
  )
  led_display_seg_ctrl_inst (
    .clk(clk),
    .rstn(rstn),
    .led_en(32'hFFFFFFFF),
    .assic_seg({"0",display1,"0",display2,"0",display3,"0",display4,"1","2","3","4","5","6","7","8","9","a","b","c","1","2","3","4","5","6","7","8","9","a","b","c"}),
    .seg_point(32'h00000000),
    .seg(seg),
    .sel(sel)
  );
endmodule