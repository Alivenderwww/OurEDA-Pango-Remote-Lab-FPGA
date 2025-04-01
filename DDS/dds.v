module dds#(
    parameter RESOLUTION   = 12,      //分辨率12bit
    parameter DATA_WIDTH   = 8 ,      //电平分辨率8bit
    parameter ADDER_LOWBIT = 20       //相位累加器低20bit
    // parameter FREQ_CTRL = 32'd42949,  //相位累加器单次累加值
    // parameter PHASE_CTRL = 12'd1024   //相位偏移量
)(
    input  wire                               clk         ,   //系统时钟,50MHz
    input  wire                               rst_n       ,   //复位信号,低电平有效
    input  wire [3:0]                         wave_select ,   //输出波形选择
    input  wire [RESOLUTION+ADDER_LOWBIT-1:0] freq_ctrl   ,   //频率控制，位宽与相位累加器位宽相同
    input  wire [RESOLUTION-1:0]              phase_ctrl  ,   //相位控制，位宽与一个周期的地址位相同
    output wire [DATA_WIDTH-1:0]              data_out        //波形输出
);

/*
相位累加器原理：
设一个周期波形的地址rom_addr_reg位宽为M，相位累加器fre_add的位宽为P（P>M）
则freq_ctrl的位宽也为M。
rom_addr_reg = fre_add的高M位 + freq_ctrl
phase_ctrl表示一个clk fre_add的自增数。
为1时fre_add的低P-M位会放缓rom_addr_reg的增速，
恰好为2^(P-M)时，一次clk正好使rom_addr_reg+1，即输出频率等于clk频率。
再高也可以使输出频率大于clk频率，但波形会有损失。
freq_ctrl从0变为最高值即可调整输出相位从0到360°。
*/


//parameter define
parameter   sin_wave    =   4'b0001     ,   //正弦波
            squ_wave    =   4'b0010     ,   //方波
            tri_wave    =   4'b0100     ,   //三角波
            saw_wave    =   4'b1000     ;   //锯齿波

//reg   define
reg [RESOLUTION+ADDER_LOWBIT-1:0] fre_add     ;   //相位累加器
reg [RESOLUTION-1:0]              rom_addr_reg;   //相位调制后的相位码
reg [RESOLUTION-1+2:0]            rom_addr    ;   //ROM读地址

//fre_add:相位累加器
always@(posedge clk)begin
    if(rst_n == 1'b0) fre_add <= 0;
    else fre_add <= fre_add + freq_ctrl;
end

//rom_addr:ROM读地址
always@(posedge clk)begin
    if(rst_n == 1'b0) rom_addr <= 0;
    else case(wave_select)
        sin_wave: rom_addr <= rom_addr_reg + 0      ;//正弦波
        squ_wave: rom_addr <= rom_addr_reg + 4096   ;//方波
        tri_wave: rom_addr <= rom_addr_reg + 4096*2 ;//三角波
        saw_wave: rom_addr <= rom_addr_reg + 4096*3 ;//锯齿波
        default : rom_addr <= rom_addr_reg + 0      ;//正弦波
    endcase
end

//rom_addr_reg:相位调制后的相位码
always@(posedge clk)begin
    if(rst_n == 1'b0) rom_addr_reg <= 0;
    else rom_addr_reg <= fre_add[RESOLUTION+ADDER_LOWBIT-1 -: RESOLUTION] + phase_ctrl;
end

rom_wave rom_wave_inst(
    .addr    (rom_addr ),  //ROM读地址
    .clk     (clk      ),  //读时钟
    .rst     (~rst_n   ),  //复位
    .rd_data (data_out )   //读出波形数据
);
endmodule
