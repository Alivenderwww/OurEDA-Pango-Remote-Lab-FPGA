module divider #(
        // Bit width of the dividend.
        parameter DIVIDEND = 32,
        // Bit width of the divisor.
        parameter DIVISOR  = 24
    ) (
        // Clock input
        input                 clock,
        // Asynchronous reset with active high
        input                 reset,

        // @Flow Input valid
        // Synchronized input with the divisor & dividend port
        input                 ivalid,
        // @Flow divisor signed input
        input  [DIVISOR-1:0]  divisor,
        // @Flow dividend signed input
        input  [DIVIDEND-1:0] dividend,

        // @Flow Output valid
        // Synchronized output with the quotient port
        output                ovalid,
        // @Flow quotient signed output
        output [DIVIDEND-1:0] quotient
    );

    reg [DIVIDEND:0]      sign;
    reg [DIVIDEND*2-1:0]  remainder[DIVIDEND:0];
    reg [DIVIDEND*2-1:0]  divisor_in[DIVIDEND:0];
    reg [DIVIDEND:0]      valid_in;
    reg [DIVIDEND-1:0]    quotient_d1[DIVIDEND:0];

    wire [DIVIDEND*2-1:0] remainder_shift[DIVIDEND-1:0];
    wire [DIVIDEND-1:0]   dividend_in = dividend[DIVIDEND-1] ? ~(dividend-1'b1) : dividend;


    //capture input data and conversion
    always @(posedge clock or posedge reset) begin
        if(reset) begin
            sign[0] <= 1'b0;
        end
        else begin
            sign[0] <= dividend[DIVIDEND-1] ^ divisor[DIVISOR-1];
        end
    end

    always @(posedge clock or posedge reset) begin
        if(reset) begin
            remainder[0] <= 1'b0;
        end
        else begin
            remainder[0] <= {{(DIVIDEND){1'b0}},dividend_in};
        end
    end

    always @(posedge clock or posedge reset) begin
        if(reset) begin
            divisor_in[0] <= 1'b0;
        end
        else if(divisor[DIVISOR-1]) begin
            divisor_in[0][DIVIDEND+DIVISOR-1 : DIVIDEND] <= ~(divisor - 1'b1);
        end
        else begin
            divisor_in[0][DIVIDEND+DIVISOR-1 : DIVIDEND] <= divisor;
        end
    end

    always @(posedge clock or posedge reset) begin
        if(reset) begin
            quotient_d1[0] <= 1'b0;
        end
    end

    always @(posedge clock or posedge reset) begin
        if(reset) begin
            valid_in[0] <= 1'b0;
        end
        else begin
            valid_in[0] <= ivalid;
        end
    end

    /*

                            dividend > divisor: remainder = dividend - dividor
    shift_left + compare ----
                            dividend < dividor: remainder = dividend

    */

    genvar i;
    generate for(i = 0 ; i < DIVIDEND; i = i + 1) begin : recovery_remainder
        
        //sign
        always @(posedge clock or posedge reset) begin
            if(reset) begin
                sign[i+1] <= 1'b0;
            end
            else begin
                sign[i+1] <= sign[i];
            end
        end

        //remainder
        assign remainder_shift[i] = remainder[i] << 1;

        always @(posedge clock or posedge reset) begin
            if(reset) begin
                remainder[i+1] <= 1'b0;
            end
            else if(remainder_shift[i] >= divisor_in[i]) begin
                remainder[i+1] <= remainder_shift[i] - divisor_in[i];
            end
            else begin
                remainder[i+1] <= remainder_shift[i];
            end
        end

        //quotient_d1
        always @(posedge clock or posedge reset) begin
            if(reset) begin
                quotient_d1[i+1] <= 1'b0;
            end
            else if(valid_in[i]) begin
                if(remainder_shift[i] >= divisor_in[i])begin
                    quotient_d1[i+1] <= quotient_d1[i] << 1;
                    quotient_d1[i+1][0] <= 1'b1;
                end
                else begin
                    quotient_d1[i+1] <= quotient_d1[i] << 1;
                    quotient_d1[i+1][0] <= 1'b0;
                end
            end
            else begin
                quotient_d1[i+1] <= quotient_d1[i+1];
            end
        end

        //divisor_in
        always @(posedge clock or posedge reset) begin
            if(reset) begin
                divisor_in[i+1] <= 1'b0;
            end
            else begin
                divisor_in[i+1] <= divisor_in[i];
            end
        end

        //valid_in
        always @(posedge clock or posedge reset) begin
            if(reset) begin
                valid_in[i+1] <= 1'b0;
            end
            else begin
                valid_in[i+1] <= valid_in[i];
            end
        end
    end
    endgenerate

    //output
    reg ovalid_r;
    always @(posedge clock or posedge reset) begin
        if(reset) begin
            ovalid_r <= 1'b0;
        end
        else begin
            ovalid_r <= valid_in[DIVIDEND - 1];
        end
    end
    assign ovalid = ovalid_r;

    assign quotient = (sign[DIVIDEND]) ? 
                      (~quotient_d1[DIVIDEND] + 1'b1) : 
                      (quotient_d1[DIVIDEND]);

endmodule