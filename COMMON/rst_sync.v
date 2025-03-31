module rstn_sync(
    input wire clk,
    input wire rstn_async,
    output wire rstn_sync
);

reg rstn_d0, rstn_d1;
always @(posedge clk or negedge rstn_async) begin
    if(!rstn_async) rstn_d0 <= 1'b0;
    else rstn_d0 <= 1'b1;
end
always @(posedge clk or negedge rstn_async) begin
    if(!rstn_async) rstn_d1 <= 1'b0;
    else rstn_d1 <= rstn_d0;
end
assign rstn_sync = rstn_d1;


endmodule //rst_sync