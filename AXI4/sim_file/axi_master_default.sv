module axi_master_default (AXI_INF.M AXI_M);
//如果AXI总线某一个模块暂时不需要连接，用default模块代替。

assign AXI_M.WR_ADDR_ID    = 0;
assign AXI_M.WR_ADDR       = 0;
assign AXI_M.WR_ADDR_LEN   = 0;
assign AXI_M.WR_ADDR_BURST = 0;
assign AXI_M.WR_ADDR_VALID = 0;
assign AXI_M.WR_DATA       = 0;
assign AXI_M.WR_STRB       = 0;
assign AXI_M.WR_DATA_LAST  = 0;
assign AXI_M.WR_DATA_VALID = 0;
assign AXI_M.WR_BACK_READY = 0;
assign AXI_M.RD_ADDR_ID    = 0;
assign AXI_M.RD_ADDR       = 0;
assign AXI_M.RD_ADDR_LEN   = 0;
assign AXI_M.RD_ADDR_BURST = 0;
assign AXI_M.RD_ADDR_VALID = 0;
assign AXI_M.RD_DATA_READY = 0;

endmodule