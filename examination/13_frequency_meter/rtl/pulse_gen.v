module pulse_gen(
    input           rstn,      //系统复位，低电平有效
    
    input  [7:0]    trig_level,
    input           ad_clk,     //AD9280驱动时钟
    input  [7:0]    ad_data,    //AD输入数据
    
    output          ad_pulse    //输出的脉冲信号
);
//因为可能会有抖动，设置一个范围值避免反复触发
parameter THR_DATA = 3;

//reg define
reg          pulse;
reg          pulse_delay;

//*****************************************************
//**                    main code
//*****************************************************

assign ad_pulse = pulse & pulse_delay;

//根据触发电平，将输入的AD采样值转换成高低电平
always @ (posedge ad_clk or negedge rstn)begin
    if(!rstn)
        pulse <= 1'b0;
    else begin
        if((trig_level >= THR_DATA) && (ad_data < trig_level - THR_DATA))
            pulse <= 1'b0;
        else if(ad_data > trig_level + THR_DATA)
            pulse <= 1'b1;
    end    
end

//延时一个时钟周期，用于消除抖动
always @ (posedge ad_clk or negedge rstn)begin
    if(!rstn)
        pulse_delay <= 1'b0;
    else
        pulse_delay <= pulse;
end

endmodule 