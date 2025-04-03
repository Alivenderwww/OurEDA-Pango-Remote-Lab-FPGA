module axi_slave_default (AXI_INF.S AXI_S);
//如果AXI总线某一个模块暂时不需要连接，用default模块代替。

assign AXI_S.WR_ADDR_READY = 0;
assign AXI_S.WR_DATA_READY = 0;
assign AXI_S.WR_BACK_ID    = 0;
assign AXI_S.WR_BACK_RESP  = 0;
assign AXI_S.WR_BACK_VALID = 0;
assign AXI_S.RD_ADDR_READY = 0;
assign AXI_S.RD_BACK_ID    = 0;
assign AXI_S.RD_DATA       = 0;
assign AXI_S.RD_DATA_RESP  = 0;
assign AXI_S.RD_DATA_LAST  = 0;
assign AXI_S.RD_DATA_VALID = 0;

integer clk_delay;
task automatic set_clk;
    input integer delayin;
    begin
        AXI_S.RSTN = 0;
        #5000;
        clk_delay = delayin;
        #5000;
        AXI_S.RSTN = 1;
    end
endtask
initial begin
    clk_delay = 5;
    AXI_S.CLK = 0;
    AXI_S.RSTN = 0;
    #5000;
    AXI_S.RSTN = 1;
end
always #clk_delay AXI_S.CLK = ~AXI_S.CLK;


endmodule