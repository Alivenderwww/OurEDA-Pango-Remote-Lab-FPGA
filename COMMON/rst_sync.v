module rstn_sync #(
    parameter DELAY = 32
)(
    input wire clk,
    input wire rstn_async,
    output wire rstn_sync
);

reg [DELAY-1:0] rstcnt;
always @(posedge clk or negedge rstn_async) begin
    if(!rstn_async) rstcnt <= 0;
    else rstcnt <= {rstcnt[DELAY-2:0], 1'b1};
end

reg rstn_d0, rstn_d1;
always @(posedge clk or negedge rstn_async) begin
    if(!rstn_async) rstn_d0 <= 0;
    else rstn_d0 <= &rstcnt;
end
always @(posedge clk or negedge rstn_async) begin
    if(!rstn_async) rstn_d1 <= 0;
    else rstn_d1 <= rstn_d0;
end
assign rstn_sync = rstn_d1;


endmodule //rst_sync