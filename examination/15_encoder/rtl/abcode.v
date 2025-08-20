module abcode(
        input        clk, 
        input        rstn,
        input        A/* synthesis PAP_MARK_DEBUG="true" */, //A相
        input        B/* synthesis PAP_MARK_DEBUG="true" */, //B相
        input        keyin/* synthesis PAP_MARK_DEBUG="true" */,
        output       keyflag/* synthesis PAP_MARK_DEBUG="true" */,
        output reg [19:0]  testcnt/* synthesis PAP_MARK_DEBUG="true" */
);

//10ms计数器，用于消抖。
reg ok_10ms/* synthesis PAP_MARK_DEBUG="true" */;
reg [31:0]cnt0/* synthesis PAP_MARK_DEBUG="true" */;
always@(posedge clk,negedge rstn)
begin
    if(!rstn)begin
        cnt0 <= 0;
        ok_10ms <= 1'b0;
    end
    else begin
        if(cnt0 < 32'd5000)begin//10ms消抖 //我的编码器 此值设置为4999可用！！！！！！！！！！！！！
            cnt0 <= cnt0 + 1'b1;
            ok_10ms <= 1'b0;
        end
        else begin
            cnt0 <= 0;
            ok_10ms <= 1'b1;
        end
    end
end


//同步/消抖 A、B
reg A_reg/* synthesis PAP_MARK_DEBUG="true" */,A_reg0/* synthesis PAP_MARK_DEBUG="true" */;
reg B_reg/* synthesis PAP_MARK_DEBUG="true" */,B_reg0/* synthesis PAP_MARK_DEBUG="true" */;
wire A_Debounce/* synthesis PAP_MARK_DEBUG="true" */;
wire B_Debounce/* synthesis PAP_MARK_DEBUG="true" */;
always@(posedge clk,negedge rstn)begin
    if(!rstn)begin
        A_reg <= 1'b1;
        A_reg0 <= 1'b1;
        B_reg <= 1'b1;
        B_reg0 <= 1'b1;
    end
    else begin
        if(ok_10ms)begin
            A_reg <= A;
            A_reg0 <= A_reg;
            B_reg <= B;
            B_reg0 <= B_reg;
        end
    end
end

assign A_Debounce = A_reg0 && A_reg && A;
assign B_Debounce = B_reg0 && B_reg && B;


//对消抖后的A进行上升沿，下降沿检测。
reg A_Debounce_reg/* synthesis PAP_MARK_DEBUG="true" */;
wire A_posedge/* synthesis PAP_MARK_DEBUG="true" */,A_negedge/* synthesis PAP_MARK_DEBUG="true" */;
always@(posedge clk,negedge rstn)begin
    if(!rstn)begin
        A_Debounce_reg <= 1'b1;
    end
    else begin
        A_Debounce_reg <= A_Debounce;
    end
end
assign A_posedge = !A_Debounce_reg && A_Debounce;
assign A_negedge = A_Debounce_reg && !A_Debounce;


//对AB相编码器的行为进行描述
reg rotary_right/* synthesis PAP_MARK_DEBUG="true" */;
reg rotary_left/* synthesis PAP_MARK_DEBUG="true" */;
always@(posedge clk,negedge rstn)begin
    if(!rstn)begin
        rotary_right <= 1'b1;
        rotary_left <= 1'b1;
    end
    else begin
        //A的上升沿时候如果B为低电平，则旋转编码器向右转
        if(A_posedge && !B_Debounce)begin
            rotary_right <= 1'b1;
        end
        //A上升沿时候如果B为高电平，则旋转编码器向左转
        else if(A_posedge && B_Debounce)begin
            rotary_left <= 1'b1;
        end
        //A的下降沿B为高电平，则旋转编码器向右转
        else if(A_negedge && B_Debounce)begin
            rotary_right <= 1'b1;
        end
        //A的下降沿B为低电平，则旋转编码器向左转
        else if(A_negedge && !B_Debounce)begin
            rotary_left <= 1'b1;
        end
        else begin
            rotary_right <= 1'b0;
            rotary_left  <= 1'b0;
        end
    end
end


//通过上面的描述，可以发现，
//“rotary_right”为上升沿的时候标志着一次右转
//“rotary_left” 为上升沿的时候标志着一次左转
//以下代码是对其进行上升沿检测
reg rotary_right_reg/* synthesis PAP_MARK_DEBUG="true" */,rotary_left_reg/* synthesis PAP_MARK_DEBUG="true" */;
wire rotary_right_pos/* synthesis PAP_MARK_DEBUG="true" */,rotary_left_pos/* synthesis PAP_MARK_DEBUG="true" */;
always@(posedge clk,negedge rstn)begin
    if(!rstn)begin
        rotary_right_reg <= 1'b1;
        rotary_left_reg <= 1'b1;
    end
    else begin
        rotary_right_reg <= rotary_right;
        rotary_left_reg <= rotary_left;
    end
end

assign rotary_right_pos = !rotary_right_reg && rotary_right;
assign rotary_left_pos = !rotary_left_reg && rotary_left;

//用于测试的计数器 右转+1 左转-1
always@(posedge clk,negedge rstn)begin
    if(!rstn)
        testcnt <= 'd0;
    else if(keyflag)
        testcnt <= 'd0; 
    else if(rotary_right_pos)
        testcnt <= testcnt + 1;
    else if(rotary_left_pos)
        testcnt <= testcnt - 1;
end

key_filter # (
  .CNT_MAX(20'd99_999)
)
  key_filter_inst (
    .sys_clk(clk),
    .sys_rst_n(rstn),
    .key_in(keyin),
    .key_flag(keyflag)
  );
endmodule
