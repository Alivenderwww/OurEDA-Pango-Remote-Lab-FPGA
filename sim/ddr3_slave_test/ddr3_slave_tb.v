`timescale 1ns/10fs
module ddr3_slave_tb ();
`include "ddr3_parameters.vh"

parameter MEM_DQ_WIDTH = 32;
parameter MEM_DQS_WIDTH = MEM_DQ_WIDTH/8;
parameter MEM_ROW_WIDTH = 15;

///////////////////////////test WRLVL case///////////////////////////
parameter CA_FIRST_DLY          = 0.15;
parameter CA_GROUP_TO_GROUP_DLY = 0.05;
////////////////////////////////////////////////////////////////////

reg          ddr_ref_clk  ;
reg          rst_n        ;
wire         ddr_init_done;

wire         BUS_CLK      ;
wire         BUS_RST      ;
reg  [27:0]  WR_ADDR      ; //写地址
reg  [ 7:0]  WR_LEN       ; //写长度，实际长度为WR_LEN+1
reg          WR_ADDR_VALID; //写地址通道有效
wire         WR_ADDR_READY; //写地址通道准备

reg  [ 31:0] WR_DATA      ; //写数据
reg  [  3:0] WR_STRB      ; //写数据掩码
reg          WR_DATA_VALID; //写数据有效
wire         WR_DATA_READY; //写数据准备
reg          WR_DATA_LAST ; //最后一个写数据标志位

reg  [27:0]  RD_ADDR      ; //读地址
reg  [ 7:0]  RD_LEN       ; //读长度，实际长度为WR_LEN+1
reg          RD_ADDR_VALID; //读地址通道有效
wire         RD_ADDR_READY; //读地址通道准备

wire [31:0] RD_DATA      ; //读数据
wire        RD_DATA_LAST ; //最后一个读数据标志位
reg         RD_DATA_READY; //读数据准备
wire        RD_DATA_VALID; //读数据有效

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
    #800000
    rst_n = 1;
end

always #10 ddr_ref_clk <= ~ddr_ref_clk;
assign BUS_RST = (~ddr_init_done);
assign BUS_CLK = ddr_ref_clk;

initial begin
    WR_ADDR = 28'h0001005;
    WR_LEN  = 8'd167;
    RD_ADDR = 28'h0001005;
    RD_LEN  = 8'd167;
end

reg [31:0] cnt;
always @(posedge BUS_CLK) begin
    if(BUS_RST) cnt <= 0;
    else if(ddr_init_done) cnt <= (cnt >= 50000)?(cnt):(cnt + 1);
end

/****写通道****/
always @(posedge BUS_CLK) begin
    if(BUS_RST) WR_ADDR_VALID <= 0;
    else if(cnt == 500 && WR_ADDR_VALID == 0) WR_ADDR_VALID <= 1;
    else if(WR_ADDR_READY && WR_ADDR_VALID) WR_ADDR_VALID <= 0;
end

always @(posedge BUS_CLK) begin
    if(BUS_RST) WR_DATA_VALID <= 0;
    else if(WR_ADDR_READY && WR_ADDR_VALID) WR_DATA_VALID <= 1;
    else if(WR_DATA_VALID && WR_DATA_READY && WR_DATA_LAST) WR_DATA_VALID <= 0;
end

always @(posedge BUS_CLK) begin
    if(BUS_RST) WR_DATA <= 0;
    else if(WR_DATA_VALID && WR_DATA_READY) WR_DATA <= WR_DATA + 1;
end

always @(posedge BUS_CLK) begin
    if(BUS_RST) WR_STRB <= 4'b1111;
    else if(WR_DATA_VALID && WR_DATA_READY) WR_STRB <= 4'b1111;
end

reg [10:0] wr_cnt;
always @(posedge BUS_CLK) begin
    if(BUS_RST) wr_cnt <= 0;
    else if(WR_DATA_VALID && WR_DATA_READY) wr_cnt <= wr_cnt + 1;
end
always @(*) begin
    WR_DATA_LAST = (wr_cnt >= WR_LEN);
end

/****读通道****/
always @(posedge BUS_CLK) begin
    if(BUS_RST) RD_ADDR_VALID <= 0;
    else if(cnt == 2000 && RD_ADDR_VALID == 0) RD_ADDR_VALID <= 1;
    else if(RD_ADDR_READY && RD_ADDR_VALID) RD_ADDR_VALID <= 0;
end

always @(posedge BUS_CLK) begin
    if(BUS_RST) RD_DATA_READY <= 0;
    else if(RD_ADDR_READY && RD_ADDR_VALID) RD_DATA_READY <= 1;
    else if(RD_DATA_VALID && RD_DATA_READY && RD_DATA_LAST) RD_DATA_READY <= 0;
end

slave_ddr3 slave_ddr3_inst(
    .ddr_ref_clk       (ddr_ref_clk   ),
    .rst_n             (rst_n         ),
    .ddr_init_done     (ddr_init_done ),
    .BUS_CLK           (BUS_CLK       ),
    .BUS_RST           (BUS_RST       ),
    .BUS_WR_ADDR       (WR_ADDR       ),
    .BUS_WR_LEN        (WR_LEN        ),
    .BUS_WR_ADDR_VALID (WR_ADDR_VALID ),
    .BUS_WR_ADDR_READY (WR_ADDR_READY ),
    .BUS_WR_DATA       (WR_DATA       ),
    .BUS_WR_STRB       (WR_STRB       ),
    .BUS_WR_DATA_VALID (WR_DATA_VALID ),
    .BUS_WR_DATA_READY (WR_DATA_READY ),
    .BUS_WR_DATA_LAST  (WR_DATA_LAST  ),
    .BUS_RD_ADDR       (RD_ADDR       ),
    .BUS_RD_LEN        (RD_LEN        ),
    .BUS_RD_ADDR_VALID (RD_ADDR_VALID ),
    .BUS_RD_ADDR_READY (RD_ADDR_READY ),
    .BUS_RD_DATA       (RD_DATA       ),
    .BUS_RD_DATA_LAST  (RD_DATA_LAST  ),
    .BUS_RD_DATA_READY (RD_DATA_READY ),
    .BUS_RD_DATA_VALID (RD_DATA_VALID ),
    .mem_rst_n         (mem_rst_n     ),
    .mem_ck            (mem_ck        ),
    .mem_ck_n          (mem_ck_n      ),
    .mem_cs_n          (mem_cs_n      ),
    .mem_a             (mem_a         ),
    .mem_dq            (mem_dq        ),
    .mem_dqs           (mem_dqs       ),
    .mem_dqs_n         (mem_dqs_n     ),
    .mem_dm            (mem_dm        ),
    .mem_cke           (mem_cke       ),
    .mem_odt           (mem_odt       ),
    .mem_ras_n         (mem_ras_n     ),
    .mem_cas_n         (mem_cas_n     ),
    .mem_we_n          (mem_we_n      ),
    .mem_ba            (mem_ba        )
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


wire GRS_N;
GTP_GRS GRS_INST (.GRS_N(1'b1));


endmodule