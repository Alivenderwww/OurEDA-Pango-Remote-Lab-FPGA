module timingDivider #(
    parameter INPUTCLKHZ = 64'd125000000,
    parameter OUTPUTCLKus = 0,
    parameter OUTPUTCLKms = 0,
    parameter SIMULATION = 0
) (
    input wire inclk,
    input wire reset,

    output reg tick
);

reg [63:0] cnt;

localparam CNTMAX = (SIMULATION)?(100):(
                    (OUTPUTCLKus != 0)?((OUTPUTCLKus)*(INPUTCLKHZ / 1000_000)): (
                    (OUTPUTCLKms != 0)?((OUTPUTCLKms)*(INPUTCLKHZ / 1000)):(100))
                                       );

always @(posedge inclk) begin
    if(reset) cnt <= 0;
    else if(cnt >= CNTMAX - 1) cnt <= 0;
    else cnt <= cnt + 1;
end

always @(posedge inclk) begin
    if(reset) tick <= 0;
    else if(cnt >= CNTMAX - 1) tick <= 1;
    else tick <= 0;
end

endmodule