module decimator(
    input       ad_clk,
    input       rstn,
    
    input [9:0] deci_rate, 
    output reg  deci_valid
);

//reg define
reg [9:0] deci_cnt;         // 抽样计数器

//*****************************************************
//**                    main code
//*****************************************************

//抽样计数器计数
always @(posedge ad_clk or negedge rstn) begin
    if(!rstn)
        deci_cnt <= 10'd0;
    else
        if(deci_cnt == deci_rate-1)
            deci_cnt <= 10'd0;
        else
            deci_cnt <= deci_cnt + 1'b1;
end

//输出抽样有效信号
always @(posedge ad_clk or negedge rstn) begin
    if(!rstn)
        deci_valid <= 1'b0;
    else
        if(deci_cnt == deci_rate-1)
            deci_valid <= 1'b1;
        else
            deci_valid <= 1'b0;    
end

endmodule 