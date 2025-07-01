module Basic_trigger#(
    parameter WIDTH = 8 //WIDTH=1 support: in == (0,1,X,R,F,B,N). WIDTH=others support: in (==,!=,<,<=,>,>=) (X, value)
    )(
    input wire clk,
    input wire [WIDTH-1:0] in,
    input wire [5:0] op, //{Operator(3),Value(3)}
    input wire [WIDTH-1:0] value, // Value for comparison
    output reg trig
);

reg [WIDTH-1:0] in_dly; // Delayed input for edge detection
always @(posedge clk) in_dly <= in;

//Operator: ==, !=, <, <=, >, >=
//Value(Bit): logic0, logic1, X, Rise, Fall, Rise or Fall, No Change
//Value(Multi bits): X, any number

localparam OP_EQ    = 3'b000, // ==
           OP_NEQ   = 3'b001, // !=
           OP_LT    = 3'b010, // <
           OP_LTE   = 3'b011, // <=
           OP_GT    = 3'b100, // >
           OP_GTE   = 3'b101; // >=

localparam VAL_LOGIC0 = 3'b000, // 0
           VAL_LOGIC1 = 3'b001, // 1
           VAL_X      = 3'b010, // X
           VAL_RISE   = 3'b011, // R
           VAL_FALL   = 3'b100, // F
           VAL_RF     = 3'b101, // B
           VAL_NC     = 3'b110; // N
           VAL_NUM    = 3'b111; // some number

generate
    if(WIDTH == 1) begin
        if(op[5:3] != OP_EQ) trig = 0;
        else case (op[2:0])
            VAL_LOGIC0: trig = (in == 1'b0);
            VAL_LOGIC1: trig = (in == 1'b1);
            VAL_X     : trig = 1'b1;
            VAL_RISE  : trig = (in == 1'b1 && in_dly == 1'b0);
            VAL_FALL  : trig = (in == 1'b0 && in_dly == 1'b1);
            VAL_RF    : trig = (in != in_dly);
            VAL_NC    : trig = (in == in_dly);
            default   : trig = 0;
        endcase
    end else begin
        if(op[2:0] == VAL_X) trig = 1; 
        else if(op[2:0] == VAL_NUM) begin
            case (op[5:3])
            OP_EQ : trig = (in == value);
            OP_NEQ: trig = (in != value);
            OP_LT : trig = (in <  value);
            OP_LTE: trig = (in <= value);
            OP_GT : trig = (in >  value);
            OP_GTE: trig = (in >= value);
            default: trig = 0;
            endcase
        end else trig = 0;
    end
endgenerate


endmodule //Basic_trigger
