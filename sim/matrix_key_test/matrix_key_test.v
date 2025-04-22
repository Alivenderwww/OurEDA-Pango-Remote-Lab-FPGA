`timescale 1ns/1ps
module matrix_key_test ();

    parameter ROW_NUM = 4;
    parameter COL_NUM = 4;
    parameter DEBOUNCE_TIME = 2000;
    parameter DELAY_TIME = 200;

    reg clk;
    reg rstn;
    wire [ROW_NUM-1:0] row;
    wire [COL_NUM-1:0] col;
    wire [ROW_NUM*COL_NUM-1:0] key_out;
    reg [ROW_NUM*COL_NUM-1:0] key_in;

    matrix_key #(
        .ROW_NUM(ROW_NUM),
        .COL_NUM(COL_NUM),
        .DEBOUNCE_TIME(DEBOUNCE_TIME),
        .DELAY_TIME(DELAY_TIME)
    ) uut (
        .clk(clk),
        .rstn(rstn),
        .row(row),
        .col(col),
        .key_out(key_out)
    );

    initial begin
        clk = 0;
        rstn = 0;
        #5 rstn = 1; // Release reset
    end
    always #5 clk = ~clk; // Generate clock signal
    
    matrix_key_ctrl #(
        .ROW_NUM 	(4  ),
        .COL_NUM 	(4  ))
    u_matrix_key_ctrl(
        .key_ctrl_enable 	(1'b1  ),
        .key_in 	(key_in  ),
        .row 	(row  ),
        .col 	(col  )
    );

    reg [63:0] key_cnt;

    always @(negedge clk or negedge rstn) begin
        if(~rstn) begin
            key_in <= 0;
            key_cnt <= 0;
        end else begin
                key_cnt <= key_cnt + 1;
                key_in <= key_cnt[35-:ROW_NUM*COL_NUM];
        end
    end

    reg grs_n;
    GTP_GRS GRS_INST(.GRS_N (grs_n));
    initial begin
    grs_n = 1'b0;
    #5 grs_n = 1'b1;
    end
endmodule