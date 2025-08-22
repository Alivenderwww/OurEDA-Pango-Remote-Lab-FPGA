module bcd2ascii (
    input [3:0] bcd,
    output reg [7:0] asciidata
);
always@(*)begin
    case(bcd)
        4'b0000 : asciidata = "0";
        4'b0001 : asciidata = "1";
        4'b0010 : asciidata = "2";
        4'b0011 : asciidata = "3";
        4'b0100 : asciidata = "4";
        4'b0101 : asciidata = "5";
        4'b0110 : asciidata = "6";
        4'b0111 : asciidata = "7";
        4'b1000 : asciidata = "8";
        4'b1001 : asciidata = "9";
    endcase
end

endmodule