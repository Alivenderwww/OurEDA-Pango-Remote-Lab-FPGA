module remote_update_origin_test();
    
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk; // 10 time units clock period

    reg rstn;
    initial begin
        rstn = 0;
        #20 rstn = 1; // Release reset after 20 time units
    end

    



endmodule //remote_update_origin_test
