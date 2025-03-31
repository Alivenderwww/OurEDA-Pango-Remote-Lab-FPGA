module btn_ggle(
    input wire clk,
    input wire rstn,
    input wire btn,
    output reg btn_ggle
);

reg [7:0] cnt;
reg btn_temp;
always @(posedge clk) btn_temp <= btn;

always @(posedge clk) begin
    if(~rstn) cnt <= 0;
    else if(btn_temp != btn) cnt <= 1;
    else if(cnt != 0) cnt <= cnt + 1;
    else cnt <= 0;
end

always @(posedge clk) begin
    if(~rstn) btn_ggle <= btn;
    else if(cnt == 8'hFF) btn_ggle <= btn_temp;
    else btn_ggle <= btn_ggle;
end

endmodule //btn_ggle