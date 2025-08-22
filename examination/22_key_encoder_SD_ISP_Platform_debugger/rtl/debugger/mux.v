module mux #(
    parameter PORT_NUM = 2
) (
    input wire rxclk,
    input wire txclk,
    input wire rstn,
    input wire txidle,
    input wire [PORT_NUM - 1 : 0] porten,       //rxclk
    input wire [PORT_NUM - 1 : 0] tx_datalast,  //txclk
    output reg [PORT_NUM - 1 : 0] portsel       //txclk
);
//跨时钟
reg [PORT_NUM - 1 : 0] porten_reg;

genvar i;
generate
    for (i = 0;i < PORT_NUM ;i = i + 1 ) begin
        always @(posedge rxclk or negedge rstn) begin
            if(~rstn)
                porten_reg[i] <= 0;
            else if(portsel[i])
                porten_reg[i] <= 0;
            else if(porten[i])
                porten_reg[i] <= 1;
            else 
                porten_reg[i] <= porten_reg[i];
        end

        always @(posedge txclk or negedge rstn) begin
            if(~rstn)
                portsel[i] <= 0;
            else if(tx_datalast[i])
                portsel[i] <= 0;
            else if(porten_reg[i] && txidle) 
                portsel[i] <= 1;
            else
                portsel[i] <= portsel[i];
        end
    end
endgenerate

endmodule