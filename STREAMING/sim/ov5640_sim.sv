module ov5640_sim (
    input  logic       CCD_RSTN,
    output logic       CCD_PCLK,
    output logic       CCD_VSYNC,
    output logic       CCD_HSYNC,
    output logic [7:0] CCD_DATA 
);
//一个仅模拟HSYNC和VSYNC时序的仿真文件

integer CCD_DATA_integer;
integer CCD_HPIXEL, CCD_VPIXEL;
integer clk_delay;
assign CCD_DATA = CCD_DATA_integer[7:0];

task automatic set_ccd_size;
    input integer hsize, vsize;
    begin
        CCD_HPIXEL = hsize;
        CCD_VPIXEL = vsize;
    end
endtask

task automatic set_clk;
    input integer delayin;
    begin
        clk_delay = delayin;
    end
endtask
initial begin
    clk_delay = 5;
end
always #clk_delay CCD_PCLK = ~CCD_PCLK;

initial begin
    CCD_PCLK = 0;
    CCD_VSYNC = 1;
    CCD_HSYNC = 0;
    CCD_DATA_integer = 0;
    CCD_HPIXEL = 64; //默认640*480
    CCD_VPIXEL = 24;
end

always begin
    CCD_VSYNC <= 1;
    CCD_HSYNC <= 0;
    repeat(10000) @(posedge CCD_PCLK);
    CCD_VSYNC <= 0;
    CCD_DATA_integer <= 0;
    repeat(CCD_VPIXEL) begin
        CCD_HSYNC <= 0;
        repeat(100) @(posedge CCD_PCLK);
        repeat(CCD_HPIXEL)begin
            CCD_DATA_integer <= CCD_DATA_integer + 1;
            CCD_HSYNC <= 1;
            @(posedge CCD_PCLK);
        end
    end
end

endmodule