`timescale 1ns/1ps
module axi_bus_test_tb ();
//对AXI总线的整体仿真，包括AXI-MASTER-SIM，AXI_SLAVE_SIM，AXI-BUS，AXI-INTERCONNECT，AXI_CLOCK_CONVERTER模块

reg         BUS_CLK;
reg         BUS_RST;

reg         M0_CLK          ;reg         M1_CLK          ;reg         M2_CLK          ;reg         M3_CLK          ;
reg         M0_RST          ;reg         M1_RST          ;reg         M2_RST          ;reg         M3_RST          ;
wire [31:0] M0_WR_ADDR      ;wire [31:0] M1_WR_ADDR      ;wire [31:0] M2_WR_ADDR      ;wire [31:0] M3_WR_ADDR      ;
wire [ 7:0] M0_WR_LEN       ;wire [ 7:0] M1_WR_LEN       ;wire [ 7:0] M2_WR_LEN       ;wire [ 7:0] M3_WR_LEN       ;
wire [ 1:0] M0_WR_ID        ;wire [ 1:0] M1_WR_ID        ;wire [ 1:0] M2_WR_ID        ;wire [ 1:0] M3_WR_ID        ;
wire        M0_WR_ADDR_VALID;wire        M1_WR_ADDR_VALID;wire        M2_WR_ADDR_VALID;wire        M3_WR_ADDR_VALID;
wire        M0_WR_ADDR_READY;wire        M1_WR_ADDR_READY;wire        M2_WR_ADDR_READY;wire        M3_WR_ADDR_READY;
wire [31:0] M0_WR_DATA      ;wire [31:0] M1_WR_DATA      ;wire [31:0] M2_WR_DATA      ;wire [31:0] M3_WR_DATA      ;
wire [ 3:0] M0_WR_STRB      ;wire [ 3:0] M1_WR_STRB      ;wire [ 3:0] M2_WR_STRB      ;wire [ 3:0] M3_WR_STRB      ;
wire [ 1:0] M0_WR_BACK_ID   ;wire [ 1:0] M1_WR_BACK_ID   ;wire [ 1:0] M2_WR_BACK_ID   ;wire [ 1:0] M3_WR_BACK_ID   ;
wire        M0_WR_DATA_VALID;wire        M1_WR_DATA_VALID;wire        M2_WR_DATA_VALID;wire        M3_WR_DATA_VALID;
wire        M0_WR_DATA_READY;wire        M1_WR_DATA_READY;wire        M2_WR_DATA_READY;wire        M3_WR_DATA_READY;
wire        M0_WR_DATA_LAST ;wire        M1_WR_DATA_LAST ;wire        M2_WR_DATA_LAST ;wire        M3_WR_DATA_LAST ;
wire [31:0] M0_RD_ADDR      ;wire [31:0] M1_RD_ADDR      ;wire [31:0] M2_RD_ADDR      ;wire [31:0] M3_RD_ADDR      ;
wire [ 7:0] M0_RD_LEN       ;wire [ 7:0] M1_RD_LEN       ;wire [ 7:0] M2_RD_LEN       ;wire [ 7:0] M3_RD_LEN       ;
wire [ 1:0] M0_RD_ID        ;wire [ 1:0] M1_RD_ID        ;wire [ 1:0] M2_RD_ID        ;wire [ 1:0] M3_RD_ID        ;
wire        M0_RD_ADDR_VALID;wire        M1_RD_ADDR_VALID;wire        M2_RD_ADDR_VALID;wire        M3_RD_ADDR_VALID;
wire        M0_RD_ADDR_READY;wire        M1_RD_ADDR_READY;wire        M2_RD_ADDR_READY;wire        M3_RD_ADDR_READY;
wire [31:0] M0_RD_DATA      ;wire [31:0] M1_RD_DATA      ;wire [31:0] M2_RD_DATA      ;wire [31:0] M3_RD_DATA      ;
wire        M0_RD_DATA_LAST ;wire        M1_RD_DATA_LAST ;wire        M2_RD_DATA_LAST ;wire        M3_RD_DATA_LAST ;
wire [ 1:0] M0_RD_BACK_ID   ;wire [ 1:0] M1_RD_BACK_ID   ;wire [ 1:0] M2_RD_BACK_ID   ;wire [ 1:0] M3_RD_BACK_ID   ;
wire        M0_RD_DATA_READY;wire        M1_RD_DATA_READY;wire        M2_RD_DATA_READY;wire        M3_RD_DATA_READY;
wire        M0_RD_DATA_VALID;wire        M1_RD_DATA_VALID;wire        M2_RD_DATA_VALID;wire        M3_RD_DATA_VALID;
reg         S0_CLK          ;reg         S1_CLK          ;reg         S2_CLK          ;reg         S3_CLK          ;
reg         S0_RST          ;reg         S1_RST          ;reg         S2_RST          ;reg         S3_RST          ;
wire [31:0] S0_WR_ADDR      ;wire [31:0] S1_WR_ADDR      ;wire [31:0] S2_WR_ADDR      ;wire [31:0] S3_WR_ADDR      ;
wire [ 7:0] S0_WR_LEN       ;wire [ 7:0] S1_WR_LEN       ;wire [ 7:0] S2_WR_LEN       ;wire [ 7:0] S3_WR_LEN       ;
wire [ 3:0] S0_WR_ID        ;wire [ 3:0] S1_WR_ID        ;wire [ 3:0] S2_WR_ID        ;wire [ 3:0] S3_WR_ID        ;
wire        S0_WR_ADDR_VALID;wire        S1_WR_ADDR_VALID;wire        S2_WR_ADDR_VALID;wire        S3_WR_ADDR_VALID;
wire        S0_WR_ADDR_READY;wire        S1_WR_ADDR_READY;wire        S2_WR_ADDR_READY;wire        S3_WR_ADDR_READY;
wire [31:0] S0_WR_DATA      ;wire [31:0] S1_WR_DATA      ;wire [31:0] S2_WR_DATA      ;wire [31:0] S3_WR_DATA      ;
wire [ 3:0] S0_WR_STRB      ;wire [ 3:0] S1_WR_STRB      ;wire [ 3:0] S2_WR_STRB      ;wire [ 3:0] S3_WR_STRB      ;
wire [ 3:0] S0_WR_BACK_ID   ;wire [ 3:0] S1_WR_BACK_ID   ;wire [ 3:0] S2_WR_BACK_ID   ;wire [ 3:0] S3_WR_BACK_ID   ;
wire        S0_WR_DATA_VALID;wire        S1_WR_DATA_VALID;wire        S2_WR_DATA_VALID;wire        S3_WR_DATA_VALID;
wire        S0_WR_DATA_READY;wire        S1_WR_DATA_READY;wire        S2_WR_DATA_READY;wire        S3_WR_DATA_READY;
wire        S0_WR_DATA_LAST ;wire        S1_WR_DATA_LAST ;wire        S2_WR_DATA_LAST ;wire        S3_WR_DATA_LAST ;
wire [31:0] S0_RD_ADDR      ;wire [31:0] S1_RD_ADDR      ;wire [31:0] S2_RD_ADDR      ;wire [31:0] S3_RD_ADDR      ;
wire [ 7:0] S0_RD_LEN       ;wire [ 7:0] S1_RD_LEN       ;wire [ 7:0] S2_RD_LEN       ;wire [ 7:0] S3_RD_LEN       ;
wire [ 3:0] S0_RD_ID        ;wire [ 3:0] S1_RD_ID        ;wire [ 3:0] S2_RD_ID        ;wire [ 3:0] S3_RD_ID        ;
wire        S0_RD_ADDR_VALID;wire        S1_RD_ADDR_VALID;wire        S2_RD_ADDR_VALID;wire        S3_RD_ADDR_VALID;
wire        S0_RD_ADDR_READY;wire        S1_RD_ADDR_READY;wire        S2_RD_ADDR_READY;wire        S3_RD_ADDR_READY;
wire [31:0] S0_RD_DATA      ;wire [31:0] S1_RD_DATA      ;wire [31:0] S2_RD_DATA      ;wire [31:0] S3_RD_DATA      ;
wire        S0_RD_DATA_LAST ;wire        S1_RD_DATA_LAST ;wire        S2_RD_DATA_LAST ;wire        S3_RD_DATA_LAST ;
wire [ 3:0] S0_RD_BACK_ID   ;wire [ 3:0] S1_RD_BACK_ID   ;wire [ 3:0] S2_RD_BACK_ID   ;wire [ 3:0] S3_RD_BACK_ID   ;
wire        S0_RD_DATA_READY;wire        S1_RD_DATA_READY;wire        S2_RD_DATA_READY;wire        S3_RD_DATA_READY;
wire        S0_RD_DATA_VALID;wire        S1_RD_DATA_VALID;wire        S2_RD_DATA_VALID;wire        S3_RD_DATA_VALID;

parameter S0_START_ADDR = 32'h00_00_00_00,
          S0_END_ADDR   = 32'h0F_FF_FF_FF,
          S1_START_ADDR = 32'h10_00_00_00,
          S1_END_ADDR   = 32'h1F_FF_FF_0F,
          S2_START_ADDR = 32'h20_00_00_00,
          S2_END_ADDR   = 32'h2F_FF_FF_0F,
          S3_START_ADDR = 32'h30_00_00_00,
          S3_END_ADDR   = 32'h3F_FF_FF_0F;

always #10 BUS_CLK = ~BUS_CLK; //speed:4
always #7    M0_CLK = ~M0_CLK; //speed:1
always #9    M1_CLK = ~M1_CLK; //speed:3
always #11   M2_CLK = ~M2_CLK; //speed:5
always #13   M3_CLK = ~M3_CLK; //speed:7
always #6    S0_CLK = ~S0_CLK; //speed:0(FAST)
always #8    S1_CLK = ~S1_CLK; //speed:2
always #12   S2_CLK = ~S2_CLK; //speed:6
always #14   S3_CLK = ~S3_CLK; //speed:8(SLOW)

initial begin
    BUS_CLK = 0; BUS_RST = 1;
    M0_CLK  = 0; M0_RST  = 1;
    M1_CLK  = 0; M1_RST  = 1;
    M2_CLK  = 0; M2_RST  = 1;
    M3_CLK  = 0; M3_RST  = 1;
    S0_CLK  = 0; S0_RST  = 1;
    S1_CLK  = 0; S1_RST  = 1;
    S2_CLK  = 0; S2_RST  = 1;
    S3_CLK  = 0; S3_RST  = 1;
#50000
    M0_RST = 0;
    M1_RST = 0;
    M2_RST = 0;
    M3_RST = 0;
    S0_RST = 0;
    S1_RST = 0;
    S2_RST = 0;
    S3_RST = 0;
#5000
    BUS_RST = 0;
end

initial begin //M0
    #1000000
    #500 M0.send_wr_addr(32'h00000170, 111, 0);
    #300 M0.send_wr_data(32'h00000000, 100, 4'b1111, 0);
    #200 M0.send_rd_addr(32'h00000170, 111, 0);
    #600 M0.recv_rd_data(0);
end

initial begin //M1
    #1000000
    #100  M1.send_wr_addr(32'h10000170, 111, 0);
    #700  M1.send_wr_data(32'h10000000, 100, 4'b1111, 0);
    #300  M1.send_rd_addr(32'h10000170, 111, 0);
    #1000 M1.recv_rd_data(0);
end

initial begin //M2
    #1000000
    #600  M2.send_wr_addr(32'h20000170, 111, 0);
    #100  M2.send_wr_data(32'h20000000, 100, 4'b1111, 0);
    #200  M2.send_rd_addr(32'h20000170, 111, 0);
    #50   M2.recv_rd_data(0);
end

initial begin //M3
    #1000000
    #300  M3.send_wr_addr(32'h30000170, 111, 0);
    #100  M3.send_wr_data(32'h30000000, 100, 4'b1111, 0);
    #900  M3.send_rd_addr(32'h30000170, 111, 0);
    #300  M3.recv_rd_data(0);
end

axi_master_sim M0(
    .clk           (M0_CLK           ),
    .rst           (M0_RST           ),
    .WR_ADDR       (M0_WR_ADDR       ),
    .WR_LEN        (M0_WR_LEN        ),
    .WR_ID         (M0_WR_ID         ),
    .WR_ADDR_VALID (M0_WR_ADDR_VALID ),
    .WR_ADDR_READY (M0_WR_ADDR_READY ),
    .WR_DATA       (M0_WR_DATA       ),
    .WR_STRB       (M0_WR_STRB       ),
    .WR_BACK_ID    (M0_WR_BACK_ID    ),
    .WR_DATA_VALID (M0_WR_DATA_VALID ),
    .WR_DATA_READY (M0_WR_DATA_READY ),
    .WR_DATA_LAST  (M0_WR_DATA_LAST  ),
    .RD_ADDR       (M0_RD_ADDR       ),
    .RD_LEN        (M0_RD_LEN        ),
    .RD_ID         (M0_RD_ID         ),
    .RD_ADDR_VALID (M0_RD_ADDR_VALID ),
    .RD_ADDR_READY (M0_RD_ADDR_READY ),
    .RD_DATA       (M0_RD_DATA       ),
    .RD_DATA_LAST  (M0_RD_DATA_LAST  ),
    .RD_BACK_ID    (M0_RD_BACK_ID    ),
    .RD_DATA_READY (M0_RD_DATA_READY ),
    .RD_DATA_VALID (M0_RD_DATA_VALID )
);

axi_master_sim M1(
    .clk           (M1_CLK           ),
    .rst           (M1_RST           ),
    .WR_ADDR       (M1_WR_ADDR       ),
    .WR_LEN        (M1_WR_LEN        ),
    .WR_ID         (M1_WR_ID         ),
    .WR_ADDR_VALID (M1_WR_ADDR_VALID ),
    .WR_ADDR_READY (M1_WR_ADDR_READY ),
    .WR_DATA       (M1_WR_DATA       ),
    .WR_STRB       (M1_WR_STRB       ),
    .WR_BACK_ID    (M1_WR_BACK_ID    ),
    .WR_DATA_VALID (M1_WR_DATA_VALID ),
    .WR_DATA_READY (M1_WR_DATA_READY ),
    .WR_DATA_LAST  (M1_WR_DATA_LAST  ),
    .RD_ADDR       (M1_RD_ADDR       ),
    .RD_LEN        (M1_RD_LEN        ),
    .RD_ID         (M1_RD_ID         ),
    .RD_ADDR_VALID (M1_RD_ADDR_VALID ),
    .RD_ADDR_READY (M1_RD_ADDR_READY ),
    .RD_DATA       (M1_RD_DATA       ),
    .RD_DATA_LAST  (M1_RD_DATA_LAST  ),
    .RD_BACK_ID    (M1_RD_BACK_ID    ),
    .RD_DATA_READY (M1_RD_DATA_READY ),
    .RD_DATA_VALID (M1_RD_DATA_VALID )
);

axi_master_sim M2(
    .clk           (M2_CLK           ),
    .rst           (M2_RST           ),
    .WR_ADDR       (M2_WR_ADDR       ),
    .WR_LEN        (M2_WR_LEN        ),
    .WR_ID         (M2_WR_ID         ),
    .WR_ADDR_VALID (M2_WR_ADDR_VALID ),
    .WR_ADDR_READY (M2_WR_ADDR_READY ),
    .WR_DATA       (M2_WR_DATA       ),
    .WR_STRB       (M2_WR_STRB       ),
    .WR_BACK_ID    (M2_WR_BACK_ID    ),
    .WR_DATA_VALID (M2_WR_DATA_VALID ),
    .WR_DATA_READY (M2_WR_DATA_READY ),
    .WR_DATA_LAST  (M2_WR_DATA_LAST  ),
    .RD_ADDR       (M2_RD_ADDR       ),
    .RD_LEN        (M2_RD_LEN        ),
    .RD_ID         (M2_RD_ID         ),
    .RD_ADDR_VALID (M2_RD_ADDR_VALID ),
    .RD_ADDR_READY (M2_RD_ADDR_READY ),
    .RD_DATA       (M2_RD_DATA       ),
    .RD_DATA_LAST  (M2_RD_DATA_LAST  ),
    .RD_BACK_ID    (M2_RD_BACK_ID    ),
    .RD_DATA_READY (M2_RD_DATA_READY ),
    .RD_DATA_VALID (M2_RD_DATA_VALID )
);

axi_master_sim M3(
    .clk           (M3_CLK           ),
    .rst           (M3_RST           ),
    .WR_ADDR       (M3_WR_ADDR       ),
    .WR_LEN        (M3_WR_LEN        ),
    .WR_ID         (M3_WR_ID         ),
    .WR_ADDR_VALID (M3_WR_ADDR_VALID ),
    .WR_ADDR_READY (M3_WR_ADDR_READY ),
    .WR_DATA       (M3_WR_DATA       ),
    .WR_STRB       (M3_WR_STRB       ),
    .WR_BACK_ID    (M3_WR_BACK_ID    ),
    .WR_DATA_VALID (M3_WR_DATA_VALID ),
    .WR_DATA_READY (M3_WR_DATA_READY ),
    .WR_DATA_LAST  (M3_WR_DATA_LAST  ),
    .RD_ADDR       (M3_RD_ADDR       ),
    .RD_LEN        (M3_RD_LEN        ),
    .RD_ID         (M3_RD_ID         ),
    .RD_ADDR_VALID (M3_RD_ADDR_VALID ),
    .RD_ADDR_READY (M3_RD_ADDR_READY ),
    .RD_DATA       (M3_RD_DATA       ),
    .RD_DATA_LAST  (M3_RD_DATA_LAST  ),
    .RD_BACK_ID    (M3_RD_BACK_ID    ),
    .RD_DATA_READY (M3_RD_DATA_READY ),
    .RD_DATA_VALID (M3_RD_DATA_VALID )
);

axi_slave_sim #(
    .addr_b (S0_START_ADDR ),
    .addr_e (S0_END_ADDR )
)S0(
    .clk           (S0_CLK           ),
    .rst           (S0_RST           ),
    .WR_ADDR       (S0_WR_ADDR       ),
    .WR_LEN        (S0_WR_LEN        ),
    .WR_ID         (S0_WR_ID         ),
    .WR_ADDR_VALID (S0_WR_ADDR_VALID ),
    .WR_ADDR_READY (S0_WR_ADDR_READY ),
    .WR_DATA       (S0_WR_DATA       ),
    .WR_STRB       (S0_WR_STRB       ),
    .WR_BACK_ID    (S0_WR_BACK_ID    ),
    .WR_DATA_VALID (S0_WR_DATA_VALID ),
    .WR_DATA_READY (S0_WR_DATA_READY ),
    .WR_DATA_LAST  (S0_WR_DATA_LAST  ),
    .RD_ADDR       (S0_RD_ADDR       ),
    .RD_LEN        (S0_RD_LEN        ),
    .RD_ID         (S0_RD_ID         ),
    .RD_ADDR_VALID (S0_RD_ADDR_VALID ),
    .RD_ADDR_READY (S0_RD_ADDR_READY ),
    .RD_DATA       (S0_RD_DATA       ),
    .RD_DATA_LAST  (S0_RD_DATA_LAST  ),
    .RD_BACK_ID    (S0_RD_BACK_ID    ),
    .RD_DATA_READY (S0_RD_DATA_READY ),
    .RD_DATA_VALID (S0_RD_DATA_VALID )
);

axi_slave_sim #(
    .addr_b (S1_START_ADDR ),
    .addr_e (S1_END_ADDR )
)S1(
    .clk           (S1_CLK           ),
    .rst           (S1_RST           ),
    .WR_ADDR       (S1_WR_ADDR       ),
    .WR_LEN        (S1_WR_LEN        ),
    .WR_ID         (S1_WR_ID         ),
    .WR_ADDR_VALID (S1_WR_ADDR_VALID ),
    .WR_ADDR_READY (S1_WR_ADDR_READY ),
    .WR_DATA       (S1_WR_DATA       ),
    .WR_STRB       (S1_WR_STRB       ),
    .WR_BACK_ID    (S1_WR_BACK_ID    ),
    .WR_DATA_VALID (S1_WR_DATA_VALID ),
    .WR_DATA_READY (S1_WR_DATA_READY ),
    .WR_DATA_LAST  (S1_WR_DATA_LAST  ),
    .RD_ADDR       (S1_RD_ADDR       ),
    .RD_LEN        (S1_RD_LEN        ),
    .RD_ID         (S1_RD_ID         ),
    .RD_ADDR_VALID (S1_RD_ADDR_VALID ),
    .RD_ADDR_READY (S1_RD_ADDR_READY ),
    .RD_DATA       (S1_RD_DATA       ),
    .RD_DATA_LAST  (S1_RD_DATA_LAST  ),
    .RD_BACK_ID    (S1_RD_BACK_ID    ),
    .RD_DATA_READY (S1_RD_DATA_READY ),
    .RD_DATA_VALID (S1_RD_DATA_VALID )
);

axi_slave_sim #(
    .addr_b (S2_START_ADDR ),
    .addr_e (S2_END_ADDR )
)S2(
    .clk           (S2_CLK           ),
    .rst           (S2_RST           ),
    .WR_ADDR       (S2_WR_ADDR       ),
    .WR_LEN        (S2_WR_LEN        ),
    .WR_ID         (S2_WR_ID         ),
    .WR_ADDR_VALID (S2_WR_ADDR_VALID ),
    .WR_ADDR_READY (S2_WR_ADDR_READY ),
    .WR_DATA       (S2_WR_DATA       ),
    .WR_STRB       (S2_WR_STRB       ),
    .WR_BACK_ID    (S2_WR_BACK_ID    ),
    .WR_DATA_VALID (S2_WR_DATA_VALID ),
    .WR_DATA_READY (S2_WR_DATA_READY ),
    .WR_DATA_LAST  (S2_WR_DATA_LAST  ),
    .RD_ADDR       (S2_RD_ADDR       ),
    .RD_LEN        (S2_RD_LEN        ),
    .RD_ID         (S2_RD_ID         ),
    .RD_ADDR_VALID (S2_RD_ADDR_VALID ),
    .RD_ADDR_READY (S2_RD_ADDR_READY ),
    .RD_DATA       (S2_RD_DATA       ),
    .RD_DATA_LAST  (S2_RD_DATA_LAST  ),
    .RD_BACK_ID    (S2_RD_BACK_ID    ),
    .RD_DATA_READY (S2_RD_DATA_READY ),
    .RD_DATA_VALID (S2_RD_DATA_VALID )
);

axi_slave_sim #(
    .addr_b (S3_START_ADDR ),
    .addr_e (S3_END_ADDR )
)S3(
    .clk           (S3_CLK           ),
    .rst           (S3_RST           ),
    .WR_ADDR       (S3_WR_ADDR       ),
    .WR_LEN        (S3_WR_LEN        ),
    .WR_ID         (S3_WR_ID         ),
    .WR_ADDR_VALID (S3_WR_ADDR_VALID ),
    .WR_ADDR_READY (S3_WR_ADDR_READY ),
    .WR_DATA       (S3_WR_DATA       ),
    .WR_STRB       (S3_WR_STRB       ),
    .WR_BACK_ID    (S3_WR_BACK_ID    ),
    .WR_DATA_VALID (S3_WR_DATA_VALID ),
    .WR_DATA_READY (S3_WR_DATA_READY ),
    .WR_DATA_LAST  (S3_WR_DATA_LAST  ),
    .RD_ADDR       (S3_RD_ADDR       ),
    .RD_LEN        (S3_RD_LEN        ),
    .RD_ID         (S3_RD_ID         ),
    .RD_ADDR_VALID (S3_RD_ADDR_VALID ),
    .RD_ADDR_READY (S3_RD_ADDR_READY ),
    .RD_DATA       (S3_RD_DATA       ),
    .RD_DATA_LAST  (S3_RD_DATA_LAST  ),
    .RD_BACK_ID    (S3_RD_BACK_ID    ),
    .RD_DATA_READY (S3_RD_DATA_READY ),
    .RD_DATA_VALID (S3_RD_DATA_VALID )
);

axi_bus #(
    .S0_START_ADDR(S0_START_ADDR),
    .S0_END_ADDR  (S0_END_ADDR  ),
    .S1_START_ADDR(S1_START_ADDR),
    .S1_END_ADDR  (S1_END_ADDR  ),
    .S2_START_ADDR(S2_START_ADDR),
    .S2_END_ADDR  (S2_END_ADDR  ),
    .S3_START_ADDR(S3_START_ADDR),
    .S3_END_ADDR  (S3_END_ADDR  )
)AXI_BUS(
    .BUS_CLK          (BUS_CLK          ),
    .BUS_RST          (BUS_RST          ),

    .M0_CLK           (M0_CLK           ),  .M1_CLK           (M1_CLK           ),  .M2_CLK           (M2_CLK           ),  .M3_CLK           (M3_CLK           ),
    .M0_RST           (M0_RST           ),  .M1_RST           (M1_RST           ),  .M2_RST           (M2_RST           ),  .M3_RST           (M3_RST           ),

    .M0_WR_ADDR       (M0_WR_ADDR       ),  .M1_WR_ADDR       (M1_WR_ADDR       ),  .M2_WR_ADDR       (M2_WR_ADDR       ),  .M3_WR_ADDR       (M3_WR_ADDR       ),
    .M0_WR_LEN        (M0_WR_LEN        ),  .M1_WR_LEN        (M1_WR_LEN        ),  .M2_WR_LEN        (M2_WR_LEN        ),  .M3_WR_LEN        (M3_WR_LEN        ),
    .M0_WR_ID         (M0_WR_ID         ),  .M1_WR_ID         (M1_WR_ID         ),  .M2_WR_ID         (M2_WR_ID         ),  .M3_WR_ID         (M3_WR_ID         ),
    .M0_WR_ADDR_VALID (M0_WR_ADDR_VALID ),  .M1_WR_ADDR_VALID (M1_WR_ADDR_VALID ),  .M2_WR_ADDR_VALID (M2_WR_ADDR_VALID ),  .M3_WR_ADDR_VALID (M3_WR_ADDR_VALID ),
    .M0_WR_ADDR_READY (M0_WR_ADDR_READY ),  .M1_WR_ADDR_READY (M1_WR_ADDR_READY ),  .M2_WR_ADDR_READY (M2_WR_ADDR_READY ),  .M3_WR_ADDR_READY (M3_WR_ADDR_READY ),

    .M0_WR_DATA       (M0_WR_DATA       ),  .M1_WR_DATA       (M1_WR_DATA       ),  .M2_WR_DATA       (M2_WR_DATA       ),  .M3_WR_DATA       (M3_WR_DATA       ),
    .M0_WR_STRB       (M0_WR_STRB       ),  .M1_WR_STRB       (M1_WR_STRB       ),  .M2_WR_STRB       (M2_WR_STRB       ),  .M3_WR_STRB       (M3_WR_STRB       ),
    .M0_WR_BACK_ID    (M0_WR_BACK_ID    ),  .M1_WR_BACK_ID    (M1_WR_BACK_ID    ),  .M2_WR_BACK_ID    (M2_WR_BACK_ID    ),  .M3_WR_BACK_ID    (M3_WR_BACK_ID    ),
    .M0_WR_DATA_VALID (M0_WR_DATA_VALID ),  .M1_WR_DATA_VALID (M1_WR_DATA_VALID ),  .M2_WR_DATA_VALID (M2_WR_DATA_VALID ),  .M3_WR_DATA_VALID (M3_WR_DATA_VALID ),
    .M0_WR_DATA_READY (M0_WR_DATA_READY ),  .M1_WR_DATA_READY (M1_WR_DATA_READY ),  .M2_WR_DATA_READY (M2_WR_DATA_READY ),  .M3_WR_DATA_READY (M3_WR_DATA_READY ),
    .M0_WR_DATA_LAST  (M0_WR_DATA_LAST  ),  .M1_WR_DATA_LAST  (M1_WR_DATA_LAST  ),  .M2_WR_DATA_LAST  (M2_WR_DATA_LAST  ),  .M3_WR_DATA_LAST  (M3_WR_DATA_LAST  ),

    .M0_RD_ADDR       (M0_RD_ADDR       ),  .M1_RD_ADDR       (M1_RD_ADDR       ),  .M2_RD_ADDR       (M2_RD_ADDR       ),  .M3_RD_ADDR       (M3_RD_ADDR       ),
    .M0_RD_LEN        (M0_RD_LEN        ),  .M1_RD_LEN        (M1_RD_LEN        ),  .M2_RD_LEN        (M2_RD_LEN        ),  .M3_RD_LEN        (M3_RD_LEN        ),
    .M0_RD_ID         (M0_RD_ID         ),  .M1_RD_ID         (M1_RD_ID         ),  .M2_RD_ID         (M2_RD_ID         ),  .M3_RD_ID         (M3_RD_ID         ),
    .M0_RD_ADDR_VALID (M0_RD_ADDR_VALID ),  .M1_RD_ADDR_VALID (M1_RD_ADDR_VALID ),  .M2_RD_ADDR_VALID (M2_RD_ADDR_VALID ),  .M3_RD_ADDR_VALID (M3_RD_ADDR_VALID ),
    .M0_RD_ADDR_READY (M0_RD_ADDR_READY ),  .M1_RD_ADDR_READY (M1_RD_ADDR_READY ),  .M2_RD_ADDR_READY (M2_RD_ADDR_READY ),  .M3_RD_ADDR_READY (M3_RD_ADDR_READY ),

    .M0_RD_DATA       (M0_RD_DATA       ),  .M1_RD_DATA       (M1_RD_DATA       ),  .M2_RD_DATA       (M2_RD_DATA       ),  .M3_RD_DATA       (M3_RD_DATA       ),
    .M0_RD_DATA_LAST  (M0_RD_DATA_LAST  ),  .M1_RD_DATA_LAST  (M1_RD_DATA_LAST  ),  .M2_RD_DATA_LAST  (M2_RD_DATA_LAST  ),  .M3_RD_DATA_LAST  (M3_RD_DATA_LAST  ),
    .M0_RD_BACK_ID    (M0_RD_BACK_ID    ),  .M1_RD_BACK_ID    (M1_RD_BACK_ID    ),  .M2_RD_BACK_ID    (M2_RD_BACK_ID    ),  .M3_RD_BACK_ID    (M3_RD_BACK_ID    ),
    .M0_RD_DATA_READY (M0_RD_DATA_READY ),  .M1_RD_DATA_READY (M1_RD_DATA_READY ),  .M2_RD_DATA_READY (M2_RD_DATA_READY ),  .M3_RD_DATA_READY (M3_RD_DATA_READY ),
    .M0_RD_DATA_VALID (M0_RD_DATA_VALID ),  .M1_RD_DATA_VALID (M1_RD_DATA_VALID ),  .M2_RD_DATA_VALID (M2_RD_DATA_VALID ),  .M3_RD_DATA_VALID (M3_RD_DATA_VALID ),

    .S0_CLK           (S0_CLK           ),  .S1_CLK           (S1_CLK           ),  .S2_CLK           (S2_CLK           ),  .S3_CLK           (S3_CLK           ),
    .S0_RST           (S0_RST           ),  .S1_RST           (S1_RST           ),  .S2_RST           (S2_RST           ),  .S3_RST           (S3_RST           ),

    .S0_WR_ADDR       (S0_WR_ADDR       ),  .S1_WR_ADDR       (S1_WR_ADDR       ),  .S2_WR_ADDR       (S2_WR_ADDR       ),  .S3_WR_ADDR       (S3_WR_ADDR       ),
    .S0_WR_LEN        (S0_WR_LEN        ),  .S1_WR_LEN        (S1_WR_LEN        ),  .S2_WR_LEN        (S2_WR_LEN        ),  .S3_WR_LEN        (S3_WR_LEN        ),
    .S0_WR_ID         (S0_WR_ID         ),  .S1_WR_ID         (S1_WR_ID         ),  .S2_WR_ID         (S2_WR_ID         ),  .S3_WR_ID         (S3_WR_ID         ),
    .S0_WR_ADDR_VALID (S0_WR_ADDR_VALID ),  .S1_WR_ADDR_VALID (S1_WR_ADDR_VALID ),  .S2_WR_ADDR_VALID (S2_WR_ADDR_VALID ),  .S3_WR_ADDR_VALID (S3_WR_ADDR_VALID ),
    .S0_WR_ADDR_READY (S0_WR_ADDR_READY ),  .S1_WR_ADDR_READY (S1_WR_ADDR_READY ),  .S2_WR_ADDR_READY (S2_WR_ADDR_READY ),  .S3_WR_ADDR_READY (S3_WR_ADDR_READY ),

    .S0_WR_DATA       (S0_WR_DATA       ),  .S1_WR_DATA       (S1_WR_DATA       ),  .S2_WR_DATA       (S2_WR_DATA       ),  .S3_WR_DATA       (S3_WR_DATA       ),
    .S0_WR_STRB       (S0_WR_STRB       ),  .S1_WR_STRB       (S1_WR_STRB       ),  .S2_WR_STRB       (S2_WR_STRB       ),  .S3_WR_STRB       (S3_WR_STRB       ),
    .S0_WR_BACK_ID    (S0_WR_BACK_ID    ),  .S1_WR_BACK_ID    (S1_WR_BACK_ID    ),  .S2_WR_BACK_ID    (S2_WR_BACK_ID    ),  .S3_WR_BACK_ID    (S3_WR_BACK_ID    ),
    .S0_WR_DATA_VALID (S0_WR_DATA_VALID ),  .S1_WR_DATA_VALID (S1_WR_DATA_VALID ),  .S2_WR_DATA_VALID (S2_WR_DATA_VALID ),  .S3_WR_DATA_VALID (S3_WR_DATA_VALID ),
    .S0_WR_DATA_READY (S0_WR_DATA_READY ),  .S1_WR_DATA_READY (S1_WR_DATA_READY ),  .S2_WR_DATA_READY (S2_WR_DATA_READY ),  .S3_WR_DATA_READY (S3_WR_DATA_READY ),
    .S0_WR_DATA_LAST  (S0_WR_DATA_LAST  ),  .S1_WR_DATA_LAST  (S1_WR_DATA_LAST  ),  .S2_WR_DATA_LAST  (S2_WR_DATA_LAST  ),  .S3_WR_DATA_LAST  (S3_WR_DATA_LAST  ),

    .S0_RD_ADDR       (S0_RD_ADDR       ),  .S1_RD_ADDR       (S1_RD_ADDR       ),  .S2_RD_ADDR       (S2_RD_ADDR       ),  .S3_RD_ADDR       (S3_RD_ADDR       ),
    .S0_RD_LEN        (S0_RD_LEN        ),  .S1_RD_LEN        (S1_RD_LEN        ),  .S2_RD_LEN        (S2_RD_LEN        ),  .S3_RD_LEN        (S3_RD_LEN        ),
    .S0_RD_ID         (S0_RD_ID         ),  .S1_RD_ID         (S1_RD_ID         ),  .S2_RD_ID         (S2_RD_ID         ),  .S3_RD_ID         (S3_RD_ID         ),
    .S0_RD_ADDR_VALID (S0_RD_ADDR_VALID ),  .S1_RD_ADDR_VALID (S1_RD_ADDR_VALID ),  .S2_RD_ADDR_VALID (S2_RD_ADDR_VALID ),  .S3_RD_ADDR_VALID (S3_RD_ADDR_VALID ),
    .S0_RD_ADDR_READY (S0_RD_ADDR_READY ),  .S1_RD_ADDR_READY (S1_RD_ADDR_READY ),  .S2_RD_ADDR_READY (S2_RD_ADDR_READY ),  .S3_RD_ADDR_READY (S3_RD_ADDR_READY ),
    
    .S0_RD_DATA       (S0_RD_DATA       ),  .S1_RD_DATA       (S1_RD_DATA       ),  .S2_RD_DATA       (S2_RD_DATA       ),  .S3_RD_DATA       (S3_RD_DATA       ),
    .S0_RD_DATA_LAST  (S0_RD_DATA_LAST  ),  .S1_RD_DATA_LAST  (S1_RD_DATA_LAST  ),  .S2_RD_DATA_LAST  (S2_RD_DATA_LAST  ),  .S3_RD_DATA_LAST  (S3_RD_DATA_LAST  ),
    .S0_RD_BACK_ID    (S0_RD_BACK_ID    ),  .S1_RD_BACK_ID    (S1_RD_BACK_ID    ),  .S2_RD_BACK_ID    (S2_RD_BACK_ID    ),  .S3_RD_BACK_ID    (S3_RD_BACK_ID    ),
    .S0_RD_DATA_READY (S0_RD_DATA_READY ),  .S1_RD_DATA_READY (S1_RD_DATA_READY ),  .S2_RD_DATA_READY (S2_RD_DATA_READY ),  .S3_RD_DATA_READY (S3_RD_DATA_READY ),
    .S0_RD_DATA_VALID (S0_RD_DATA_VALID ),  .S1_RD_DATA_VALID (S1_RD_DATA_VALID ),  .S2_RD_DATA_VALID (S2_RD_DATA_VALID ),  .S3_RD_DATA_VALID (S3_RD_DATA_VALID )
);


reg grs_n;
GTP_GRS GRS_INST(.GRS_N (grs_n));
initial begin
grs_n = 1'b0;
#5 grs_n = 1'b1;
end




endmodule