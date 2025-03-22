`timescale 1ns/1ps
`include "ddr3_parameters.vh"
module udp_axi_ddr_tb_top();

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

reg     ddr_ref_clk      ;
reg     rst_n            ;
wire    ddr_init_done    ;
wire    BUS_CLK          ;
wire    BUS_RST          ;

wire [27:0]  BUS_WR_ADDR      ;
wire [ 7:0]  BUS_WR_LEN       ;
wire         BUS_WR_ADDR_VALID;
wire        BUS_WR_ADDR_READY;
wire [ 31:0] BUS_WR_DATA      ;
wire [  3:0] BUS_WR_STRB      ;
wire        BUS_WR_DATA_VALID;
wire        BUS_WR_DATA_READY;
wire        BUS_WR_DATA_LAST ;
wire [27:0]  BUS_RD_ADDR      ;
wire [ 7:0]  BUS_RD_LEN       ;
wire         BUS_RD_ADDR_VALID;
wire        BUS_RD_ADDR_READY;
wire [31:0] BUS_RD_DATA      ;
wire        BUS_RD_DATA_LAST ;
wire        BUS_RD_DATA_READY;
wire        BUS_RD_DATA_VALID;
// Parameters

//Ports
reg gmii_rx_clk;
reg wr_en;
reg rd_en;
reg [7:0] wr_num;
reg [7:0] rd_num;
reg [27:0] wr_addr;
reg [27:0] rd_addr;
wire rec_pkt_done;
wire [31:0] udp_rx_data;
wire rec_en;
wire tx_req;
wire tx_start_en;
wire [31:0] udp_tx_data;
  
always #4   gmii_rx_clk = ! gmii_rx_clk;
always #10  ddr_ref_clk = ! ddr_ref_clk;
assign BUS_RST = ((!rst_n) || (!ddr_init_done));
assign BUS_CLK = gmii_rx_clk;
    

/*************************************/
reg [31:0] rd_cnt;

initial begin
  gmii_rx_clk = 0;
  ddr_ref_clk = 0;
  rst_n = 0;
  wr_en = 0;
  rd_en = 0;
  wr_addr = 0;
  rd_addr = 0;
  rd_cnt = 0;
  rd_num <= 255;
  wr_num = 255;
  #500000
  rst_n = 1;
  wr_addr = 0;
  while (ddr_init_done == 0) #100;
  #20000
  wr_en = 1;
  #100
  wr_en = 0;
  #20000
  rd_en = 1;
  #100
  rd_en = 0;
  #20000
  wr_en = 1;
  #100
  wr_en = 0;
  #20000
  rd_en = 1;
  #100
  rd_en = 0;
end


udp_model  udp_model_inst (
  .gmii_rx_clk(gmii_rx_clk),
  .rstn(rst_n),
  .wr_en(wr_en),
  .rd_en(rd_en),
  .wr_num(wr_num),
  .rd_num(rd_num),
  .wr_addr(wr_addr),
  .rd_addr(rd_addr),
  .rec_pkt_done(rec_pkt_done),
  .udp_rx_data(udp_rx_data),
  .rec_en(rec_en),
  .tx_req(tx_req),
  .tx_start_en(tx_start_en),
  .udp_tx_data(udp_tx_data)
);

axi_udp_cmd  axi_udp_cmd_inst (
  .gmii_rx_clk  (gmii_rx_clk       ),
  .rstn         (rst_n             ),
  .wr_addr      (BUS_WR_ADDR       ),
  .wr_len       (BUS_WR_LEN        ),
  .wr_addr_valid(BUS_WR_ADDR_VALID ),
  .wr_addr_ready(BUS_WR_ADDR_READY ),
  .wr_data      (BUS_WR_DATA       ),
  .wr_strb      (BUS_WR_STRB       ),
  .wr_data_valid(BUS_WR_DATA_VALID ),
  .wr_data_ready(BUS_WR_DATA_READY ),
  .wr_data_last (BUS_WR_DATA_LAST  ),
  .rd_addr      (BUS_RD_ADDR       ),
  .rd_len       (BUS_RD_LEN        ),
  .rd_addr_valid(BUS_RD_ADDR_VALID ),
  .rd_addr_ready(BUS_RD_ADDR_READY ),
  .rd_data      (BUS_RD_DATA       ),
  .rd_data_last (BUS_RD_DATA_LAST  ),
  .rd_data_ready(BUS_RD_DATA_READY ),
  .rd_data_valid(BUS_RD_DATA_VALID ),
  .rec_pkt_done (rec_pkt_done      ),
  .datain       (udp_rx_data       ),
  .rec_en       (rec_en            ),
  .tx_req       (tx_req            ),
  .tx_start_en  (tx_start_en       ),
  .udp_tx_data  (udp_tx_data       )
);

/*************************************/

slave_ddr3 slave_ddr3_inst(
    .ddr_ref_clk       (ddr_ref_clk       ),
    .rst_n             (rst_n             ),
    .ddr_init_done     (ddr_init_done     ),
    .BUS_CLK           (BUS_CLK           ),
    .BUS_RST           (BUS_RST           ),
    .BUS_WR_ADDR       (BUS_WR_ADDR       ),
    .BUS_WR_LEN        (BUS_WR_LEN        ),
    .BUS_WR_ADDR_VALID (BUS_WR_ADDR_VALID ),
    .BUS_WR_ADDR_READY (BUS_WR_ADDR_READY ),
    .BUS_WR_DATA       (BUS_WR_DATA       ),
    .BUS_WR_STRB       (BUS_WR_STRB       ),
    .BUS_WR_DATA_VALID (BUS_WR_DATA_VALID ),
    .BUS_WR_DATA_READY (BUS_WR_DATA_READY ),
    .BUS_WR_DATA_LAST  (BUS_WR_DATA_LAST  ),
    .BUS_RD_ADDR       (BUS_RD_ADDR       ),
    .BUS_RD_LEN        (BUS_RD_LEN        ),
    .BUS_RD_ADDR_VALID (BUS_RD_ADDR_VALID ),
    .BUS_RD_ADDR_READY (BUS_RD_ADDR_READY ),
    .BUS_RD_DATA       (BUS_RD_DATA       ),
    .BUS_RD_DATA_LAST  (BUS_RD_DATA_LAST  ),
    .BUS_RD_DATA_READY (BUS_RD_DATA_READY ),
    .BUS_RD_DATA_VALID (BUS_RD_DATA_VALID ),
    .mem_rst_n         (mem_rst_n         ),
    .mem_ck            (mem_ck            ),
    .mem_ck_n          (mem_ck_n          ),
    .mem_cs_n          (mem_cs_n          ),
    .mem_a             (mem_a             ),
    .mem_dq            (mem_dq            ),
    .mem_dqs           (mem_dqs           ),
    .mem_dqs_n         (mem_dqs_n         ),
    .mem_dm            (mem_dm            ),
    .mem_cke           (mem_cke           ),
    .mem_odt           (mem_odt           ),
    .mem_ras_n         (mem_ras_n         ),
    .mem_cas_n         (mem_cas_n         ),
    .mem_we_n          (mem_we_n          ),
    .mem_ba            (mem_ba            )
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
assign b1_gate = udp_axi_ddr_tb_top.slave_ddr3_inst.ddr3_top_inst.axi_ddr3_inst.u_ddrphy_top.ddrphy_reset_ctrl.ddrphy_ioclk_gate[1];
assign #OUT_SYNC_DLY b0_gate =  b1_gate;
initial 
begin    
    force udp_axi_ddr_tb_top.slave_ddr3_inst.ddr3_top_inst.axi_ddr3_inst.u_ddrphy_top.ddrphy_slice_top.i_dqs_bank[0].ddrphy_ppll.clkoutphy_gate = b0_gate;
//    force udp_axi_ddr_tb_top.slave_ddr3_inst.ddr3_top_inst.axi_ddr3_inst.u_ddrphy_top.ddrphy_slice_top.i_dqs_bank[2].ddrphy_ppll.clkoutphy_gate = b0_gate;
end

endmodule
