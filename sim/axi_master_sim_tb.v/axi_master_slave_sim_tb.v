module axi_master_slave_sim_tb();

reg clk,rst;

wire [31:0] WR_ADDR      ;
wire [ 7:0] WR_LEN       ;
wire [ 1:0] WR_ID        ;
wire        WR_ADDR_VALID;
wire        WR_ADDR_READY;
wire [31:0] WR_DATA      ;
wire [ 3:0] WR_STRB      ;
wire [ 1:0] WR_BACK_ID   ;
wire        WR_DATA_VALID;
wire        WR_DATA_READY;
wire        WR_DATA_LAST ;
wire [31:0] RD_ADDR      ;
wire [ 7:0] RD_LEN       ;
wire [ 1:0] RD_ID        ;
wire        RD_ADDR_VALID;
wire        RD_ADDR_READY;
wire [31:0] RD_DATA      ;
wire        RD_DATA_LAST ;
wire [ 1:0] RD_BACK_ID   ;
wire        RD_DATA_READY;
wire        RD_DATA_VALID;
initial begin
    clk = 0;
    rst = 1;
    #10
    rst = 0;
end
always #5 clk = ~clk;

axi_master_sim master_inst(
   .clk          (clk          ),
   .rst          (rst          ),
   .WR_ADDR      (WR_ADDR      ),
   .WR_LEN       (WR_LEN       ),
   .WR_ID        (WR_ID        ),
   .WR_ADDR_VALID(WR_ADDR_VALID),
   .WR_ADDR_READY(WR_ADDR_READY),
   .WR_DATA      (WR_DATA      ),
   .WR_STRB      (WR_STRB      ),
   .WR_BACK_ID   (WR_BACK_ID   ),
   .WR_DATA_VALID(WR_DATA_VALID),
   .WR_DATA_READY(WR_DATA_READY),
   .WR_DATA_LAST (WR_DATA_LAST ),
   .RD_ADDR      (RD_ADDR      ),
   .RD_LEN       (RD_LEN       ),
   .RD_ID        (RD_ID        ),
   .RD_ADDR_VALID(RD_ADDR_VALID),
   .RD_ADDR_READY(RD_ADDR_READY),
   .RD_DATA      (RD_DATA      ),
   .RD_DATA_LAST (RD_DATA_LAST ),
   .RD_BACK_ID   (RD_BACK_ID   ),
   .RD_DATA_READY(RD_DATA_READY),
   .RD_DATA_VALID(RD_DATA_VALID)
);


axi_slave_sim slave_inst(
   .clk          (clk          ),
   .rstn         (~rst         ),
   .BUS_CLK      (    ),
   .BUS_RST      (    ),
   .WR_ADDR      (WR_ADDR      ),
   .WR_LEN       (WR_LEN       ),
   .WR_ID        (WR_ID        ),
   .WR_ADDR_VALID(WR_ADDR_VALID),
   .WR_ADDR_READY(WR_ADDR_READY),
   .WR_DATA      (WR_DATA      ),
   .WR_STRB      (WR_STRB      ),
   .WR_BACK_ID   (WR_BACK_ID   ),
   .WR_DATA_VALID(WR_DATA_VALID),
   .WR_DATA_READY(WR_DATA_READY),
   .WR_DATA_LAST (WR_DATA_LAST ),
   .RD_ADDR      (RD_ADDR      ),
   .RD_LEN       (RD_LEN       ),
   .RD_ID        (RD_ID        ),
   .RD_ADDR_VALID(RD_ADDR_VALID),
   .RD_ADDR_READY(RD_ADDR_READY),
   .RD_BACK_ID   (RD_DATA      ),
   .RD_DATA      (RD_DATA_LAST ),
   .RD_DATA_LAST (RD_BACK_ID   ),
   .RD_DATA_READY(RD_DATA_READY),
   .RD_DATA_VALID(RD_DATA_VALID) 

);
endmodule