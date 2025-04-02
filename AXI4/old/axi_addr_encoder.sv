module axi_addr_encoder #(
    parameter WIDTH  = 2,
    parameter [31:0] START_ADDR[0:(2**WIDTH-1)] = '{32'h00000000, 32'h10000000, 32'h20000000, 32'h30000000},
    parameter [31:0]   END_ADDR[0:(2**WIDTH-1)] = '{32'h0FFFFFFF, 32'h1FFFFFFF, 32'h2FFFFFFF, 32'h3FFFFFFF}
)(
    input logic [31:0] ADDR,
    output logic [WIDTH-1:0] channel_sel
);

always_comb begin
    channel_sel = '0;  // 默认输出0
    for (int i = 0; i < (2 ** WIDTH); i++) begin
        // 优先级检查：仅当未找到有效区间时继续检查
        if ((channel_sel == '0) && (ADDR >= START_ADDR[i]) && (ADDR <= END_ADDR[i])) begin
            channel_sel = i[WIDTH-1:0];
        end
    end
end
    
endmodule //axi_addr_encoder
