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

wire         DDR_SLAVE_CLK      ;
wire         DDR_SLAVE_RST      ;
reg  [31:0]  DDR_SLAVE_WR_ADDR      ; //写地址
reg  [ 7:0]  DDR_SLAVE_WR_LEN       ; //写长度，实际长度为WR_LEN+1
reg          DDR_SLAVE_WR_ADDR_VALID; //写地址通道有效
wire         DDR_SLAVE_WR_ADDR_READY; //写地址通道准备

reg  [ 31:0] DDR_SLAVE_WR_DATA      ; //写数据
reg  [  3:0] DDR_SLAVE_WR_STRB      ; //写数据掩码
reg          DDR_SLAVE_WR_DATA_VALID; //写数据有效
wire         DDR_SLAVE_WR_DATA_READY; //写数据准备
reg          DDR_SLAVE_WR_DATA_LAST ; //最后一个写数据标志位

reg  [31:0]  DDR_SLAVE_RD_ADDR      ; //读地址
reg  [ 7:0]  DDR_SLAVE_RD_LEN       ; //读长度，实际长度为WR_LEN+1
reg          DDR_SLAVE_RD_ADDR_VALID; //读地址通道有效
wire         DDR_SLAVE_RD_ADDR_READY; //读地址通道准备

wire [31:0]  DDR_SLAVE_RD_DATA      ; //读数据
wire         DDR_SLAVE_RD_DATA_LAST ; //最后一个读数据标志位
reg          DDR_SLAVE_RD_DATA_READY; //读数据准备
wire         DDR_SLAVE_RD_DATA_VALID; //读数据有效

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
 
wire [ADDR_BITS-1:0] mem_addr;

initial begin
    ddr_ref_clk = 0;
    rst_n = 0;
    #300000
    rst_n = 1;
end

always #10 ddr_ref_clk <= ~ddr_ref_clk;

initial begin
    DDR_SLAVE_WR_ADDR = 32'h0001005;
    DDR_SLAVE_WR_LEN  = 8'd167;
    DDR_SLAVE_RD_ADDR = 32'h0001005;
    DDR_SLAVE_RD_LEN  = 8'd167;
end

reg [31:0] cnt;
always @(posedge DDR_SLAVE_CLK) begin
    if(DDR_SLAVE_RST) cnt <= 0;
    else cnt <= (cnt >= 50000)?(cnt):(cnt + 1);
end

/****写通道****/
always @(posedge DDR_SLAVE_CLK) begin
    if(DDR_SLAVE_RST) DDR_SLAVE_WR_ADDR_VALID <= 0;
    else if(cnt == 500 && DDR_SLAVE_WR_ADDR_VALID == 0) DDR_SLAVE_WR_ADDR_VALID <= 1;
    else if(DDR_SLAVE_WR_ADDR_READY && DDR_SLAVE_WR_ADDR_VALID) DDR_SLAVE_WR_ADDR_VALID <= 0;
end

always @(posedge DDR_SLAVE_CLK) begin
    if(DDR_SLAVE_RST) DDR_SLAVE_WR_DATA_VALID <= 0;
    else if(DDR_SLAVE_WR_ADDR_READY && DDR_SLAVE_WR_ADDR_VALID) DDR_SLAVE_WR_DATA_VALID <= 1;
    else if(DDR_SLAVE_WR_DATA_VALID && DDR_SLAVE_WR_DATA_READY && DDR_SLAVE_WR_DATA_LAST) DDR_SLAVE_WR_DATA_VALID <= 0;
end

always @(posedge DDR_SLAVE_CLK) begin
    if(DDR_SLAVE_RST) DDR_SLAVE_WR_DATA <= 0;
    else if(DDR_SLAVE_WR_DATA_VALID && DDR_SLAVE_WR_DATA_READY) DDR_SLAVE_WR_DATA <= DDR_SLAVE_WR_DATA + 1;
end

always @(posedge DDR_SLAVE_CLK) begin
    if(DDR_SLAVE_RST) DDR_SLAVE_WR_STRB <= 4'b1111;
    else if(DDR_SLAVE_WR_DATA_VALID && DDR_SLAVE_WR_DATA_READY) DDR_SLAVE_WR_STRB <= 4'b1111;
end

reg [10:0] wr_cnt;
always @(posedge DDR_SLAVE_CLK) begin
    if(DDR_SLAVE_RST) wr_cnt <= 0;
    else if(DDR_SLAVE_WR_DATA_VALID && DDR_SLAVE_WR_DATA_READY) wr_cnt <= wr_cnt + 1;
end
always @(*) begin
    DDR_SLAVE_WR_DATA_LAST = (wr_cnt >= DDR_SLAVE_WR_LEN);
end

/****读通道****/
always @(posedge DDR_SLAVE_CLK) begin
    if(DDR_SLAVE_RST) DDR_SLAVE_RD_ADDR_VALID <= 0;
    else if(cnt == 2000 && DDR_SLAVE_RD_ADDR_VALID == 0) DDR_SLAVE_RD_ADDR_VALID <= 1;
    else if(DDR_SLAVE_RD_ADDR_READY && DDR_SLAVE_RD_ADDR_VALID) DDR_SLAVE_RD_ADDR_VALID <= 0;
end

always @(posedge DDR_SLAVE_CLK) begin
    if(DDR_SLAVE_RST) DDR_SLAVE_RD_DATA_READY <= 0;
    else if(DDR_SLAVE_RD_ADDR_READY && DDR_SLAVE_RD_ADDR_VALID) DDR_SLAVE_RD_DATA_READY <= 1;
    else if(DDR_SLAVE_RD_DATA_VALID && DDR_SLAVE_RD_DATA_READY && DDR_SLAVE_RD_DATA_LAST) DDR_SLAVE_RD_DATA_READY <= 0;
end

slave_ddr3 slave_ddr3_inst(
    .ddr_ref_clk             (ddr_ref_clk   ),
    .rst_n                   (rst_n         ),
    .ddr_init_done           (ddr_init_done ),

    .DDR_SLAVE_CLK           (DDR_SLAVE_CLK           ),
    .DDR_SLAVE_RST           (DDR_SLAVE_RST           ),
    .DDR_SLAVE_WR_ADDR       (DDR_SLAVE_WR_ADDR       ),
    .DDR_SLAVE_WR_LEN        (DDR_SLAVE_WR_LEN        ),
    .DDR_SLAVE_WR_ADDR_VALID (DDR_SLAVE_WR_ADDR_VALID ),
    .DDR_SLAVE_WR_ADDR_READY (DDR_SLAVE_WR_ADDR_READY ),
    .DDR_SLAVE_WR_DATA       (DDR_SLAVE_WR_DATA       ),
    .DDR_SLAVE_WR_STRB       (DDR_SLAVE_WR_STRB       ),
    .DDR_SLAVE_WR_DATA_VALID (DDR_SLAVE_WR_DATA_VALID ),
    .DDR_SLAVE_WR_DATA_READY (DDR_SLAVE_WR_DATA_READY ),
    .DDR_SLAVE_WR_DATA_LAST  (DDR_SLAVE_WR_DATA_LAST  ),
    .DDR_SLAVE_RD_ADDR       (DDR_SLAVE_RD_ADDR       ),
    .DDR_SLAVE_RD_LEN        (DDR_SLAVE_RD_LEN        ),
    .DDR_SLAVE_RD_ADDR_VALID (DDR_SLAVE_RD_ADDR_VALID ),
    .DDR_SLAVE_RD_ADDR_READY (DDR_SLAVE_RD_ADDR_READY ),
    .DDR_SLAVE_RD_DATA       (DDR_SLAVE_RD_DATA       ),
    .DDR_SLAVE_RD_DATA_LAST  (DDR_SLAVE_RD_DATA_LAST  ),
    .DDR_SLAVE_RD_DATA_READY (DDR_SLAVE_RD_DATA_READY ),
    .DDR_SLAVE_RD_DATA_VALID (DDR_SLAVE_RD_DATA_VALID ),
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