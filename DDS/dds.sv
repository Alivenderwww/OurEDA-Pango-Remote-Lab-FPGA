module dds #(
    parameter HORIZON_RESOLUTION  = 12, //水平分辨率12bit
    parameter VERTICAL_RESOLUTION = 8 , //垂直分辨率8bit
    parameter ADDER_LOWBIT        = 20, //相位累加器低20bit
    parameter WAVE_STORE          = 2   //存储2**2个波形数据
)(
    //时钟信号
    input  wire                                       clk                            , //系统时钟,50MHz
    input  wire                                       rstn                           , //复位信号,低电平有效
    //选通信号
    input  wire [WAVE_STORE-1:0]                      wave_sel                       , //波形选通，共WAVE_STORE组
    //调制信号
    input  wire [HORIZON_RESOLUTION+ADDER_LOWBIT-1:0] freq_ctrl [0:(2**WAVE_STORE)-1], //频率控制，位宽与相位累加器位宽相同，共WAVE_STORE组
    input  wire [HORIZON_RESOLUTION-1:0]              phase_ctrl[0:(2**WAVE_STORE)-1], //相位控制，位宽与一个周期的地址位相同，共WAVE_STORE组
    output wire [VERTICAL_RESOLUTION-1:0]             wave_out                       , //输出wave_sel选中的波形
    //RAM写信号
    input  wire                                       wr_enable,
    input  wire                                       wr_valid ,
    input  wire [32-1:0]                              wr_data  
);

/*
相位累加器原理：
设一个周期波形的地址ram_addr_reg位宽为M，相位累加器fre_add的位宽为P（P>M）
则freq_ctrl的位宽也为M。
ram_addr_reg = fre_add的高M位 + freq_ctrl
phase_ctrl表示一个clk fre_add的自增数。
为1时fre_add的低P-M位会放缓ram_addr_reg的增速，
恰好为2^(P-M)时，一次clk正好使ram_addr_reg+1，即输出频率等于clk频率。
再高也可以使输出频率大于clk频率，但波形会有损失。
freq_ctrl从0变为最高值即可调整输出相位从0到360°。
*/

wire dds_rstn_sync;
rstn_sync u_rstn_sync(clk,rstn,dds_rstn_sync);

reg [HORIZON_RESOLUTION+ADDER_LOWBIT-1:0] fre_add     [0:(2**WAVE_STORE)-1];//相位累加器
reg [HORIZON_RESOLUTION-1:0]              ram_addr_reg[0:(2**WAVE_STORE)-1];//相位调制后的相位码
reg [HORIZON_RESOLUTION+WAVE_STORE-1:0]   ram_rd_addr                      ;//RAM读地址
reg                                       ram_wr_en                        ;//RAM写使能
reg [HORIZON_RESOLUTION+WAVE_STORE-1:0]   ram_wr_addr                      ;//RAM写地址
reg [VERTICAL_RESOLUTION-1:0]             ram_wr_data                      ;//RAM写数据

integer i;
//fre_add:相位累加器
always@(posedge clk or negedge dds_rstn_sync)begin
    if(~dds_rstn_sync) for(i=0;i<(2**WAVE_STORE);i=i+1) fre_add[i] <= 0;
    else for(i=0;i<(2**WAVE_STORE);i=i+1) fre_add[i] <= fre_add[i] + freq_ctrl[i];
end

//ram_addr_reg:相位调制后的相位码
always@(posedge clk or negedge dds_rstn_sync)begin
    if(~dds_rstn_sync) for(i=0;i<(2**WAVE_STORE);i=i+1) ram_addr_reg[i] <= 0;
    else for(i=0;i<(2**WAVE_STORE);i=i+1) ram_addr_reg[i] <= fre_add[i][(HORIZON_RESOLUTION+ADDER_LOWBIT-1)-:(HORIZON_RESOLUTION)] + phase_ctrl[i];
end

//ram_wr_addr:RAM写地址
always@(posedge clk or negedge dds_rstn_sync)begin
    if(~dds_rstn_sync) begin
        ram_wr_en   <= 0;
        ram_wr_addr <= {wave_sel,{(HORIZON_RESOLUTION){1'b0}}} - 1;
        ram_wr_data <= 0;
    end else if(wr_enable) begin
        ram_wr_en   <= wr_valid;
        ram_wr_addr <= ram_wr_addr + wr_valid;
        ram_wr_data <= wr_data[VERTICAL_RESOLUTION-1:0];
    end else begin
        ram_wr_en   <= 0;
        ram_wr_addr <= {wave_sel,{(HORIZON_RESOLUTION){1'b0}}} - 1;
        ram_wr_data <= 0;
    end
end

//ram_rd_addr:RAM读地址
always@(posedge clk or negedge dds_rstn_sync)begin
    if(~dds_rstn_sync) ram_rd_addr <= 0;
    else ram_rd_addr <= {wave_sel,ram_addr_reg[wave_sel]};
end

//Distribute Simple Dual Port RAM。ADDR_WIDTH = HORIZON_RESOLUTION+WAVE_STORE
ram_wave ram_wave_inst(
    .wr_rst  (~dds_rstn_sync         ),
    .rd_rst  (~dds_rstn_sync         ),
    .wr_clk  (clk                    ),
    .wr_en   (ram_wr_en              ),
    .wr_addr (ram_wr_addr            ),
    .wr_data (ram_wr_data            ),

    .rd_clk  (clk                    ),
    .rd_addr (ram_rd_addr            ),
    .rd_data (wave_out               )
);
endmodule
