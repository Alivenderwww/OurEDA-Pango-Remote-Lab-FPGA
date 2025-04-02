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


endmodule