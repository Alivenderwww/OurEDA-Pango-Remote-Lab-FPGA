module ws_ctrl_top (
    input wire external_clk,
    input wire external_rstn,
    output wire dataout
);

localparam BANK_NUM = 1,
           BANK_X = 4,
           BANK_Y = 4;
localparam WS_NUM = BANK_NUM*BANK_X*BANK_Y;
wire [23:0] wscolor [BANK_NUM*BANK_X*BANK_Y];

Datacreate #(
    .CLKHZ    (32'd50_000_000),
    .BANK_NUM (BANK_NUM),
    .BANK_X   (BANK_X),
    .BANK_Y   (BANK_Y)
) Datacreate_inst(
    .clk    (external_clk),
    .rst    (~external_rstn),
    .wscolor(wscolor)
);

Send #(
    .CLKHZ  (32'd50_000_000),
    .WS_NUM (WS_NUM)
) Send_inst(
    .wscolor        (wscolor),
    .clk            (external_clk),
    .rst            (~external_rstn),
    .data_stream    (dataout)
);

endmodule