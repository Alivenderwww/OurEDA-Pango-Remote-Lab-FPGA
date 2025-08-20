module HSV2RGB #(          //HSV: hue, saturation, value. (same as HSB(Brightness))
    parameter HSV_DEPTH = 8,
    parameter RGB_DEPTH = 8
) (
    input wire                    clk,              
    input wire  [HSV_DEPTH - 1:0] hue, // -> 0° - 360°
    input wire  [HSV_DEPTH - 1:0] sat, // -> 0% - 100%
    input wire  [HSV_DEPTH - 1:0] val, // -> 0% - 100%
    output reg  [RGB_DEPTH - 1:0] R,
    output reg  [RGB_DEPTH - 1:0] G,
    output reg  [RGB_DEPTH - 1:0] B 
);

wire [4*HSV_DEPTH - 1 :0] p, q, t;
reg  [  HSV_DEPTH - 1 :0] f, _f, _sat;
wire [  HSV_DEPTH - 1 :0] p__, q__, t__;
wire [2*HSV_DEPTH - 1 :0] fsat, _fsat, __fsat;

localparam MAX  = (1<<HSV_DEPTH),
           MAX0 = ((MAX - 0   )/6) + 0    + 1,//42  + 1 when dep=8
           MAX1 = ((MAX - MAX0)/5) + MAX0 + 1,//84  + 1 when dep=8
           MAX2 = ((MAX - MAX1)/4) + MAX1 + 1,//127 + 1 when dep=8
           MAX3 = ((MAX - MAX2)/3) + MAX2 + 1,//170 + 1 when dep=8
           MAX4 = ((MAX - MAX3)/2) + MAX3 + 1,//213 + 1 when dep=8
           MAX5 = ((MAX - MAX4)/1) + MAX4 + 1;//256 + 1 when dep=8

always @(*) begin
    if     (hue < MAX0) f = (hue     ) * 6;
    else if(hue < MAX1) f = (hue-MAX0) * 6;
    else if(hue < MAX2) f = (hue-MAX1) * 6;
    else if(hue < MAX3) f = (hue-MAX2) * 6;
    else if(hue < MAX4) f = (hue-MAX3) * 6;
    else                f = (hue-MAX4) * 6;
end

assign _f     = ~  f       ;
assign _sat   = ~      sat ;
assign   fsat =    f * sat ;
assign  _fsat = ~( f * sat);
assign __fsat = ~(_f * sat);
assign p   = (val * _sat  );
assign q   = (val * _fsat );
assign t   = (val * __fsat);
assign p__ = p[  HSV_DEPTH +: HSV_DEPTH];
assign q__ = q[2*HSV_DEPTH +: HSV_DEPTH];
assign t__ = t[2*HSV_DEPTH +: HSV_DEPTH];

always @(posedge clk) begin
    if      (hue < MAX0) {R,G,B} = {val[HSV_DEPTH-1 -: RGB_DEPTH],t__[HSV_DEPTH-1 -: RGB_DEPTH],p__[HSV_DEPTH-1 -: RGB_DEPTH]};
    else if (hue < MAX1) {R,G,B} = {q__[HSV_DEPTH-1 -: RGB_DEPTH],val[HSV_DEPTH-1 -: RGB_DEPTH],p__[HSV_DEPTH-1 -: RGB_DEPTH]};
    else if (hue < MAX2) {R,G,B} = {p__[HSV_DEPTH-1 -: RGB_DEPTH],val[HSV_DEPTH-1 -: RGB_DEPTH],t__[HSV_DEPTH-1 -: RGB_DEPTH]};
    else if (hue < MAX3) {R,G,B} = {p__[HSV_DEPTH-1 -: RGB_DEPTH],q__[HSV_DEPTH-1 -: RGB_DEPTH],val[HSV_DEPTH-1 -: RGB_DEPTH]};
    else if (hue < MAX4) {R,G,B} = {t__[HSV_DEPTH-1 -: RGB_DEPTH],p__[HSV_DEPTH-1 -: RGB_DEPTH],val[HSV_DEPTH-1 -: RGB_DEPTH]};
    else                 {R,G,B} = {val[HSV_DEPTH-1 -: RGB_DEPTH],p__[HSV_DEPTH-1 -: RGB_DEPTH],q__[HSV_DEPTH-1 -: RGB_DEPTH]};
end

endmodule