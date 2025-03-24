`timescale 1ns/1ps
`include "ddr3_parameters.vh"
module ddr3_slave_tb ();

parameter MEM_DQ_WIDTH = 32;
parameter MEM_DQS_WIDTH = MEM_DQ_WIDTH/8;
parameter MEM_ROW_WIDTH = 15;


///////////////////////////test WRLVL case///////////////////////////
parameter CA_FIRST_DLY          = 0.15;
parameter CA_GROUP_TO_GROUP_DLY = 0.05;
////////////////////////////////////////////////////////////////////
localparam real ACTUAL_RATE  =  800.0   ; 
///////////////////////////test ppll sync case///////////////////////////
// 1 step rst_clk phase adjust changes 2 / 128 ppll fast clk phase. the ppll fast clk frequency is twice the otput frequecey of ppll.
parameter real OUT_SYNC_DLY = (500.0 / ACTUAL_RATE) * (123.0 / 128.0); 
////////////////////////////////////////////////////////////////////

reg          ddr_ref_clk  ;
reg          rst_n        ;

wire         mem_rst_n    ; //Memory复位
wire         mem_ck       ; //Memory差分时钟正端
wire         mem_ck_n     ; //Memory差分时钟负端
wire         mem_cs_n     ; //Memory片选
wire [MEM_ROW_WIDTH-1:0]  mem_a        ; //Memory地址总线
wire [MEM_DQ_WIDTH-1:0]   mem_dq       ; //数据总线
wire [MEM_DQS_WIDTH-1:0]  mem_dqs      ; //数据时钟正端
wire [MEM_DQS_WIDTH-1:0]  mem_dqs_n    ; //数据时钟负端
wire [MEM_DQS_WIDTH-1:0]  mem_dm       ; //数据Mask
wire         mem_cke      ; //Memory差分时钟使能
wire         mem_odt      ; //On Die Termination
wire         mem_ras_n    ; //行地址strobe
wire         mem_cas_n    ; //列地址strobe
wire         mem_we_n     ; //写使能
wire [ 2:0]  mem_ba       ; //Bank地址总线

wire        AXI_CLK;
wire        AXI_RSTN;
wire [ 1:0] WR_ADDR_ID   ;
wire [31:0] WR_ADDR      ;
wire [ 7:0] WR_ADDR_LEN  ;
wire [ 1:0] WR_ADDR_BURST;
wire        WR_ADDR_VALID;
wire        WR_ADDR_READY;
wire [31:0] WR_DATA      ;
wire [ 3:0] WR_STRB      ;
wire        WR_DATA_LAST ;
wire        WR_DATA_VALID;
wire        WR_DATA_READY;
wire [ 3:0] WR_BACK_ID   ;
wire [ 1:0] WR_BACK_RESP ;
wire        WR_BACK_VALID;
wire        WR_BACK_READY;
wire [ 1:0] RD_ADDR_ID   ;
wire [31:0] RD_ADDR      ;
wire [ 7:0] RD_ADDR_LEN  ;
wire [ 1:0] RD_ADDR_BURST;
wire        RD_ADDR_VALID;
wire        RD_ADDR_READY;
wire [ 1:0] RD_BACK_ID   ;
wire [31:0] RD_DATA      ;
wire [ 1:0] RD_DATA_RESP ;
wire        RD_DATA_LAST ;
wire        RD_DATA_VALID;
wire        RD_DATA_READY;
 
wire [ADDR_BITS-1:0] mem_addr;

initial begin
    ddr_ref_clk = 0;
    rst_n = 0;
    #300000
    rst_n = 1;
end

always #10 ddr_ref_clk <= ~ddr_ref_clk;

initial begin
    #50000
    while(~AXI_RSTN) #500;
    MASTER.set_rd_data_channel(7);                              
    MASTER.set_wr_data_channel(7);                              
    MASTER.send_wr_addr(2'b00, 32'h00000000, 8'd255, 2'b00);
    MASTER.send_wr_data(32'h00000000, 4'b1111);
    MASTER.send_wr_addr(2'b01, 32'h00010000, 8'd255, 2'b00);
    MASTER.send_wr_data(32'h10000000, 4'b1111);
    MASTER.send_rd_addr(2'b00, 32'h00000000, 8'd255, 2'b00);
    MASTER.send_rd_addr(2'b00, 32'h00010000, 8'd255, 2'b00);
end

axi_master_sim MASTER(
    .clk                  (AXI_CLK       ),
    .rstn                 (AXI_RSTN      ),
    .MASTER_CLK           (              ),
    .MASTER_RSTN          (              ),
    .MASTER_WR_ADDR_ID    (WR_ADDR_ID    ),
    .MASTER_WR_ADDR       (WR_ADDR       ),
    .MASTER_WR_ADDR_LEN   (WR_ADDR_LEN   ),
    .MASTER_WR_ADDR_BURST (WR_ADDR_BURST ),
    .MASTER_WR_ADDR_VALID (WR_ADDR_VALID ),
    .MASTER_WR_ADDR_READY (WR_ADDR_READY ),
    .MASTER_WR_DATA       (WR_DATA       ),
    .MASTER_WR_STRB       (WR_STRB       ),
    .MASTER_WR_DATA_LAST  (WR_DATA_LAST  ),
    .MASTER_WR_DATA_VALID (WR_DATA_VALID ),
    .MASTER_WR_DATA_READY (WR_DATA_READY ),
    .MASTER_WR_BACK_ID    (WR_BACK_ID    ),
    .MASTER_WR_BACK_RESP  (WR_BACK_RESP  ),
    .MASTER_WR_BACK_VALID (WR_BACK_VALID ),
    .MASTER_WR_BACK_READY (WR_BACK_READY ),
    .MASTER_RD_ADDR_ID    (RD_ADDR_ID    ),
    .MASTER_RD_ADDR       (RD_ADDR       ),
    .MASTER_RD_ADDR_LEN   (RD_ADDR_LEN   ),
    .MASTER_RD_ADDR_BURST (RD_ADDR_BURST ),
    .MASTER_RD_ADDR_VALID (RD_ADDR_VALID ),
    .MASTER_RD_ADDR_READY (RD_ADDR_READY ),
    .MASTER_RD_BACK_ID    (RD_BACK_ID    ),
    .MASTER_RD_DATA       (RD_DATA       ),
    .MASTER_RD_DATA_RESP  (RD_DATA_RESP  ),
    .MASTER_RD_DATA_LAST  (RD_DATA_LAST  ),
    .MASTER_RD_DATA_VALID (RD_DATA_VALID ),
    .MASTER_RD_DATA_READY (RD_DATA_READY )
);


slave_ddr3 slave_ddr3_inst(
    .ddr_ref_clk             (ddr_ref_clk   ),
    .rst_n                   (rst_n         ),
    .ddr_init_done           (ddr_init_done ),
    
    //DDR-AXI-SLAVE接口
    .DDR_SLAVE_CLK          (AXI_CLK  ),
    .DDR_SLAVE_RSTN         (AXI_RSTN ),

    .DDR_SLAVE_WR_ADDR_ID   ({2'b00,WR_ADDR_ID}   ),
    .DDR_SLAVE_WR_ADDR      (WR_ADDR      ),
    .DDR_SLAVE_WR_ADDR_LEN  (WR_ADDR_LEN  ),
    .DDR_SLAVE_WR_ADDR_BURST(WR_ADDR_BURST),
    .DDR_SLAVE_WR_ADDR_VALID(WR_ADDR_VALID),
    .DDR_SLAVE_WR_ADDR_READY(WR_ADDR_READY),

    .DDR_SLAVE_WR_DATA      (WR_DATA      ),
    .DDR_SLAVE_WR_STRB      (WR_STRB      ),
    .DDR_SLAVE_WR_DATA_LAST (WR_DATA_LAST ),
    .DDR_SLAVE_WR_DATA_VALID(WR_DATA_VALID),
    .DDR_SLAVE_WR_DATA_READY(WR_DATA_READY),

    .DDR_SLAVE_WR_BACK_ID   (WR_BACK_ID   ),
    .DDR_SLAVE_WR_BACK_RESP (WR_BACK_RESP ),
    .DDR_SLAVE_WR_BACK_VALID(WR_BACK_VALID),
    .DDR_SLAVE_WR_BACK_READY(WR_BACK_READY),

    .DDR_SLAVE_RD_ADDR_ID   ({2'b00,RD_ADDR_ID}   ),
    .DDR_SLAVE_RD_ADDR      (RD_ADDR      ),
    .DDR_SLAVE_RD_ADDR_LEN  (RD_ADDR_LEN  ),
    .DDR_SLAVE_RD_ADDR_BURST(RD_ADDR_BURST),
    .DDR_SLAVE_RD_ADDR_VALID(RD_ADDR_VALID),
    .DDR_SLAVE_RD_ADDR_READY(RD_ADDR_READY),

    .DDR_SLAVE_RD_BACK_ID   (RD_BACK_ID   ),
    .DDR_SLAVE_RD_DATA      (RD_DATA      ),
    .DDR_SLAVE_RD_DATA_RESP (RD_DATA_RESP ),
    .DDR_SLAVE_RD_DATA_LAST (RD_DATA_LAST ),
    .DDR_SLAVE_RD_DATA_VALID(RD_DATA_VALID),
    .DDR_SLAVE_RD_DATA_READY(RD_DATA_READY),

    .mem_rst_n               (mem_rst_n     ),
    .mem_ck                  (mem_ck        ),
    .mem_ck_n                (mem_ck_n      ),
    .mem_cs_n                (mem_cs_n      ),
    .mem_a                   (mem_a         ),
    .mem_dq                  (mem_dq        ),
    .mem_dqs                 (mem_dqs       ),
    .mem_dqs_n               (mem_dqs_n     ),
    .mem_dm                  (mem_dm        ),
    .mem_cke                 (mem_cke       ),
    .mem_odt                 (mem_odt       ),
    .mem_ras_n               (mem_ras_n     ),
    .mem_cas_n               (mem_cas_n     ),
    .mem_we_n                (mem_we_n      ),
    .mem_ba                  (mem_ba        )
);

wire [MEM_DQS_WIDTH+1:0] mem_ck_dly;
wire [MEM_DQS_WIDTH+1:0] mem_ck_n_dly;
wire [(MEM_DQS_WIDTH+2)*ADDR_BITS:0] mem_addr_dly;
wire [MEM_DQS_WIDTH+1:0] mem_cke_dly;
wire [MEM_DQS_WIDTH+1:0] mem_odt_dly;
wire [MEM_DQS_WIDTH+1:0] mem_ras_n_dly;
wire [MEM_DQS_WIDTH+1:0] mem_cas_n_dly;
wire [MEM_DQS_WIDTH+1:0] mem_we_n_dly;
wire [MEM_DQS_WIDTH*3+6:0] mem_ba_dly;
wire [MEM_DQS_WIDTH+1:0] mem_cs_n_dly;
wire [MEM_DQS_WIDTH+1:0] mem_rst_n_dly;


assign #CA_FIRST_DLY   mem_ck_dly[1:0]               =  {mem_ck,mem_ck}    ;
assign #CA_FIRST_DLY   mem_ck_n_dly[1:0]             =  {mem_ck_n,mem_ck_n}  ;
assign #CA_FIRST_DLY   mem_addr_dly[ADDR_BITS*2-1:0] =  {mem_addr,mem_addr}  ;
assign #CA_FIRST_DLY   mem_cke_dly[1:0]              =  {mem_cke,mem_cke}   ;
assign #CA_FIRST_DLY   mem_odt_dly[1:0]              =  {mem_odt,mem_odt}   ;
assign #CA_FIRST_DLY   mem_ras_n_dly[1:0]            =  {mem_ras_n,mem_ras_n} ;
assign #CA_FIRST_DLY   mem_cas_n_dly[1:0]            =  {mem_cas_n,mem_cas_n} ;
assign #CA_FIRST_DLY   mem_we_n_dly[1:0]             =  {mem_we_n,mem_we_n}  ;
assign #CA_FIRST_DLY   mem_ba_dly[5:0]               =  {mem_ba,mem_ba}    ;
assign #CA_FIRST_DLY   mem_cs_n_dly[1:0]             =  {mem_cs_n,mem_cs_n}  ;
assign #CA_FIRST_DLY   mem_rst_n_dly[1:0]            =  {mem_rst_n,mem_rst_n} ;


assign mem_addr = {{(ADDR_BITS-MEM_ROW_WIDTH){1'b0}},{mem_a}};

genvar gen_mem;                                                    
generate                                                         
    for(gen_mem=0; gen_mem<(MEM_DQS_WIDTH/2); gen_mem=gen_mem+1) begin: i_mem 
        assign #CA_GROUP_TO_GROUP_DLY   mem_addr_dly[(ADDR_BITS*(gen_mem+1)+ADDR_BITS)*2-1:(ADDR_BITS*(gen_mem+1))*2] =  mem_addr_dly[(ADDR_BITS*gen_mem+ADDR_BITS)*2-1:(ADDR_BITS*gen_mem)*2];
        assign #CA_GROUP_TO_GROUP_DLY   mem_cke_dly[2*gen_mem+3:2*gen_mem+2]                                          =  mem_cke_dly[2*gen_mem+1:2*gen_mem];
        assign #CA_GROUP_TO_GROUP_DLY   mem_odt_dly[2*gen_mem+3:2*gen_mem+2]                                          =  mem_odt_dly[2*gen_mem+1:2*gen_mem];
        assign #CA_GROUP_TO_GROUP_DLY   mem_ras_n_dly[2*gen_mem+3:2*gen_mem+2]                                        =  mem_ras_n_dly[2*gen_mem+1:2*gen_mem];
        assign #CA_GROUP_TO_GROUP_DLY   mem_cas_n_dly[2*gen_mem+3:2*gen_mem+2]                                        =  mem_cas_n_dly[2*gen_mem+1:2*gen_mem];
        assign #CA_GROUP_TO_GROUP_DLY   mem_we_n_dly[2*gen_mem+3:2*gen_mem+2]                                         =  mem_we_n_dly[2*gen_mem+1:2*gen_mem];
        assign #CA_GROUP_TO_GROUP_DLY   mem_ba_dly[(gen_mem+1)*6+5:(gen_mem+1)*6]                                     =  mem_ba_dly[gen_mem*6+5:gen_mem*6];
        assign #CA_GROUP_TO_GROUP_DLY   mem_cs_n_dly[2*gen_mem+3:2*gen_mem+2]                                         =  mem_cs_n_dly[2*gen_mem+1:2*gen_mem];
        assign #CA_GROUP_TO_GROUP_DLY   mem_rst_n_dly[2*gen_mem+3:2*gen_mem+2]                                        =  mem_rst_n_dly[2*gen_mem+1:2*gen_mem];
        assign #CA_GROUP_TO_GROUP_DLY   mem_ck_dly[2*gen_mem+3:2*gen_mem+2]                                           =  mem_ck_dly[2*gen_mem+1:2*gen_mem];
        assign #CA_GROUP_TO_GROUP_DLY   mem_ck_n_dly[2*gen_mem+3:2*gen_mem+2]                                         =  mem_ck_n_dly[2*gen_mem+1:2*gen_mem];
        ddr3 mem_core (
            .rst_n   (mem_rst_n_dly[2*gen_mem+1:2*gen_mem]                                 ),

            .ck      (mem_ck_dly[2*gen_mem+1:2*gen_mem]                                    ),
            .ck_n    (mem_ck_n_dly[2*gen_mem+1:2*gen_mem]                                  ),


            .cs_n    (mem_cs_n_dly[2*gen_mem+1:2*gen_mem]                                  ),

            .ras_n   (mem_ras_n_dly[2*gen_mem+1:2*gen_mem]                                 ),
            .cas_n   (mem_cas_n_dly[2*gen_mem+1:2*gen_mem]                                 ),
            .we_n    (mem_we_n_dly[2*gen_mem+1:2*gen_mem]                                  ),
            .addr    (mem_addr_dly[(ADDR_BITS*gen_mem+ADDR_BITS)*2-1:ADDR_BITS*gen_mem*2]  ),
            .ba      (mem_ba_dly[gen_mem*6+5:gen_mem*6]                                    ),
            .odt     (mem_odt_dly[2*gen_mem+1:2*gen_mem]                                   ),
            .cke     (mem_cke_dly[2*gen_mem+1:2*gen_mem]                                   ),

            .dq      (mem_dq[16*gen_mem+15:16*gen_mem]                                     ),
            .dqs     (mem_dqs[2*gen_mem+1:2*gen_mem]                                       ),
            .dqs_n   (mem_dqs_n[2*gen_mem+1:2*gen_mem]                                     ),
            .dm_tdqs (mem_dm[2*gen_mem+1:2*gen_mem]                                        ),
            .tdqs_n  (                                                                     )
        );
end     
endgenerate

reg grs_n;
GTP_GRS GRS_INST(.GRS_N (grs_n));
initial begin
grs_n = 1'b0;
#5 grs_n = 1'b1;
end


wire b0_gate;
wire b1_gate;
assign b1_gate = ddr3_slave_tb.slave_ddr3_inst.ddr3_top_inst.axi_ddr3_inst.u_ddrphy_top.ddrphy_reset_ctrl.ddrphy_ioclk_gate[1];
assign #OUT_SYNC_DLY b0_gate =  b1_gate;
initial 
begin    
    force ddr3_slave_tb.slave_ddr3_inst.ddr3_top_inst.axi_ddr3_inst.u_ddrphy_top.ddrphy_slice_top.i_dqs_bank[0].ddrphy_ppll.clkoutphy_gate = b0_gate;
//    force ddr3_slave_tb.slave_ddr3_inst.ddr3_top_inst.axi_ddr3_inst.u_ddrphy_top.ddrphy_slice_top.i_dqs_bank[2].ddrphy_ppll.clkoutphy_gate = b0_gate;
end

endmodule