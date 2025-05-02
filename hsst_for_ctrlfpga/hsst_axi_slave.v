module hsst_axi_slave (
    input wire          i_p_refckn_0       ,
    input wire          i_p_refckp_0       ,
    input wire          rstn               ,
    input wire          i_free_clk         ,//50M

    output wire         SLAVE_CLK          ,
    output wire         SLAVE_RSTN         ,

    input  wire [4-1:0] SLAVE_WR_ADDR_ID   ,
    input  wire [31:0]  SLAVE_WR_ADDR      ,
    input  wire [ 7:0]  SLAVE_WR_ADDR_LEN  ,
    input  wire [ 1:0]  SLAVE_WR_ADDR_BURST,
    input  wire         SLAVE_WR_ADDR_VALID,
    output reg          SLAVE_WR_ADDR_READY,

    input  wire [31:0]  SLAVE_WR_DATA      ,
    input  wire [ 3:0]  SLAVE_WR_STRB      ,
    input  wire         SLAVE_WR_DATA_LAST ,
    input  wire         SLAVE_WR_DATA_VALID,
    output reg          SLAVE_WR_DATA_READY,

    output wire [4-1:0] SLAVE_WR_BACK_ID   ,
    output wire [ 1:0]  SLAVE_WR_BACK_RESP ,
    output reg          SLAVE_WR_BACK_VALID,
    input  wire         SLAVE_WR_BACK_READY,

    input  wire [4-1:0] SLAVE_RD_ADDR_ID   ,
    input  wire [31:0]  SLAVE_RD_ADDR      ,
    input  wire [ 7:0]  SLAVE_RD_ADDR_LEN  ,
    input  wire [ 1:0]  SLAVE_RD_ADDR_BURST,
    input  wire         SLAVE_RD_ADDR_VALID,
    output reg          SLAVE_RD_ADDR_READY,
    output wire [4-1:0] SLAVE_RD_BACK_ID   ,

    output wire [31:0]  SLAVE_RD_DATA      ,
    output wire [ 1:0]  SLAVE_RD_DATA_RESP ,
    output wire         SLAVE_RD_DATA_LAST ,
    output wire         SLAVE_RD_DATA_VALID,
    input  wire         SLAVE_RD_DATA_READY
);
//32位地址,前16位,a0是以命令方式访问ctrlfpga,a1是访问labfpga
//ctrlfpga会监测labfpga的状态,比如有没有采样完成
//debug使用lane0,主时钟使用txclk,接收数据经过异步fifo转成txclk时钟域

//一共有4种任务形式,写本地localtask_wr,读本地localtask_rd,向labfpga传输数据(txtask_wr,txtask_rd),接收来自labfpga的cmd
wire hsstinit;
wire o_pll_done_0;
wire o_txlane_done_0;
wire o_txlane_done_1;
wire o_rxlane_done_0;
wire o_rxlane_done_1;
wire o_p_pll_lock_0;
wire o_p_rx_sigdet_sta_0;
wire o_p_rx_sigdet_sta_1;
wire o_p_lx_cdr_align_0;
wire o_p_lx_cdr_align_1;
wire txclk_0;
wire txclk_1;
wire rxclk_0;
wire rxclk_1;
reg  [31:0] i_txd_0;
reg  [ 3:0] i_txk_0;
reg  [31:0] i_txd_1;
reg  [ 3:0] i_txk_1;
wire data_valid_0;
wire data_valid_1;
wire [31:0] data_af_align_0;
wire [31:0] data_af_align_1;
wire data_last_0;                   //rxclk
wire data_last_1;

// assign data_af_align_0 = debugtest_top_inst.sfp_txdata;
// assign data_last_0 = debugtest_top_inst.sfp_txdatalast;
// assign data_valid_0 = debugtest_top_inst.sfp_txdatavalid;
//
reg rd_fifo_data_valid;
wire [31:0] sfpfifo_data;
wire sfpfifo_data_last;
reg rd_local_data_valid;
reg rd_local_data_last;
//txtask
localparam IDLE    = 0;
localparam WRHEAD  = 1;
localparam RDHEAD  = 2;
localparam CMDDATA = 3;
reg [ 7:0] txtask_state;
reg [31:0] task_cmd;
//loacltask
localparam LOCALREAD    = 1;
localparam LOCALWRITE   = 2;
localparam HANDSHAKE    = 3;
wire       localtask_wr;
wire       localtask_rd;
reg [ 7:0] localtask_state;
reg [31:0] localtask_wr_cmd;
//sfprxtask
localparam RXPORTDATA = 1;
localparam RXCMD = 2;
reg [ 7:0] sfprxstate;
reg [31:0] sfprxstate_cmd;
reg        sfprxtask;
reg [31:0] debugger_statue;
reg        trigdone_clear;
//fifo
wire       sfpfifo_wren;
wire sfpfifo_almostempty;
wire sfpfifo_almostfull;
wire sfpfifo_empty;
wire sfpfifo_rden;
reg sfpfifo_rden_reg;
reg rd_addr_ready_d0,rd_addr_ready_d1;
always @(posedge SLAVE_CLK or negedge rstn) begin
    if(~rstn)begin
        rd_addr_ready_d0 <= 0;
        rd_addr_ready_d1 <= 0;
    end
    else begin
        rd_addr_ready_d0 <= SLAVE_RD_DATA_LAST;
        rd_addr_ready_d1 <= rd_addr_ready_d0;
    end
end
//////
// reg [1:0] rd_addr_ready_flag;
// always @(posedge SLAVE_CLK or negedge rstn) begin
//     if(~rstn) rd_addr_ready_flag <= 0;
//     else if(rd_addr_ready_flag == 0) begin
//         if(sfpfifo_almostfull)
//             rd_addr_ready_flag <= 1;
//         else if(localtask_rd)
//             rd_addr_ready_flag <= 2;
//     end
//     else if(rd_addr_ready_flag == 1 && sfpfifo_almostempty) rd_addr_ready_flag <= 3;
//     else if(rd_addr_ready_flag == 2 && SLAVE_RD_DATA_LAST)  rd_addr_ready_flag <= 3;
//     else if(rd_addr_ready_flag == 3 )rd_addr_ready_flag <= 0;
//     else rd_addr_ready_flag <= rd_addr_ready_flag;
// end
//*************************//
assign SLAVE_CLK = txclk_0;
//***********************AXI***********************//
//wraddr
reg [ 3:0] wraddrid;
reg [31:0] wraddr;
reg [ 7:0] wraddrlen;
reg [ 1:0] wraddrburst;
reg        task_wraddrdelay;//延迟为了消除亚稳态
reg        task_wraddr;
reg        task_wrdata;
wire       txtask_wr;
assign txtask_wr    = task_wraddr && task_wrdata && txtask_state       == IDLE && wraddr[24] == 1;
assign localtask_wr = task_wraddr && task_wrdata && localtask_state == IDLE && wraddr[24] == 0;
assign SLAVE_WR_BACK_ID = wraddrid;
always @(posedge SLAVE_CLK or negedge rstn) begin
    if(~rstn) SLAVE_WR_ADDR_READY <= 1;
    else if(SLAVE_WR_ADDR_VALID && SLAVE_WR_ADDR_READY) SLAVE_WR_ADDR_READY <= 0;
    else if(txtask_wr || localtask_wr) SLAVE_WR_ADDR_READY <= 1;
    else SLAVE_WR_ADDR_READY <= SLAVE_WR_ADDR_READY;
end
always @(posedge SLAVE_CLK or negedge rstn) begin
    if(~rstn)begin
        wraddrid         <= 0;
        wraddr           <= 0;
        wraddrlen        <= 0;
        wraddrburst      <= 0;
        task_wraddrdelay <= 0;
    end
    else if(SLAVE_WR_ADDR_VALID && SLAVE_WR_ADDR_READY)begin
        wraddrid         <= SLAVE_WR_ADDR_ID;
        wraddr           <= SLAVE_WR_ADDR;
        wraddrlen        <= SLAVE_WR_ADDR_LEN;
        wraddrburst      <= SLAVE_WR_ADDR_BURST;
        task_wraddrdelay <= 1;
    end
    else begin
        wraddrid         <= wraddrid;
        wraddr           <= wraddr;
        wraddrlen        <= wraddrlen;
        wraddrburst      <= wraddrburst;
        task_wraddrdelay <= 0;
    end
end
always @(posedge SLAVE_CLK or negedge rstn) begin
    if(~rstn) task_wraddr <= 0;
    else if(task_wraddrdelay) task_wraddr <= 1;
    else if(txtask_wr || localtask_wr) task_wraddr <= 0;
    else task_wraddr <= task_wraddr;
end
//wrdata
reg [31:0] wrdata;
reg [ 3:0] wrstrb;
always @(posedge SLAVE_CLK or negedge rstn) begin
    if(~rstn) SLAVE_WR_DATA_READY <= 1;
    else if(SLAVE_WR_DATA_VALID && SLAVE_WR_DATA_READY) SLAVE_WR_DATA_READY <= 0;
    else if(txtask_wr || localtask_wr) SLAVE_WR_DATA_READY <= 1;
    else SLAVE_WR_DATA_READY <= SLAVE_WR_DATA_READY;
end
always @(posedge SLAVE_CLK or negedge rstn) begin
    if(~rstn)begin
        wrdata <= 0;
        wrstrb <= 0;
    end
    else if(SLAVE_WR_DATA_VALID && SLAVE_WR_DATA_READY)begin
        wrdata <= SLAVE_WR_DATA;
        wrstrb <= SLAVE_WR_STRB;
    end
    else begin
        wrdata <= wrdata;
        wrstrb <= wrstrb;
    end
end
always @(posedge SLAVE_CLK or negedge rstn) begin
    if(~rstn) task_wrdata <= 0;
    else if(SLAVE_WR_DATA_VALID && SLAVE_WR_DATA_READY) task_wrdata <= 1;
    else if(txtask_wr || localtask_wr) task_wrdata <= 0;
    else task_wrdata <= task_wrdata;
end
//wrback
assign SLAVE_WR_BACK_ID = wraddrid;
assign SLAVE_WR_BACK_RESP = 2'b00;
always @(posedge SLAVE_CLK or negedge rstn) begin
    if(~rstn) SLAVE_WR_BACK_VALID <= 0;
    else if(SLAVE_WR_BACK_READY && SLAVE_WR_BACK_VALID) SLAVE_WR_BACK_VALID <= 0;
    else if(txtask_wr) SLAVE_WR_BACK_VALID <= 1;
    else SLAVE_WR_BACK_VALID <= SLAVE_WR_BACK_VALID;
end
//rdaddr
reg [ 3:0] rdaddrid;
reg [31:0] rdaddr;
reg [ 7:0] rdaddrlen;
reg [ 1:0] rdaddrburst;
reg        task_rddelay;//延迟为了消除亚稳态
reg        task_rdaddr;
wire       txtask_rd;

assign txtask_rd    = task_rdaddr && txtask_state       == IDLE && rdaddr[24] == 1;
assign localtask_rd = task_rdaddr && localtask_state == IDLE && rdaddr[24] == 0;
assign SLAVE_RD_BACK_ID = rdaddrid;
always @(posedge SLAVE_CLK or negedge rstn) begin
    if(~rstn) SLAVE_RD_ADDR_READY <= 1;
    else if(SLAVE_RD_ADDR_VALID && SLAVE_RD_ADDR_READY) SLAVE_RD_ADDR_READY <= 0;
    // else if(rd_addr_ready_flag == 3) SLAVE_RD_ADDR_READY <= 1;
    else if(rd_addr_ready_d0 && ~rd_addr_ready_d1) SLAVE_RD_ADDR_READY <= 1;
    else SLAVE_RD_ADDR_READY <= SLAVE_RD_ADDR_READY;
end
always @(posedge SLAVE_CLK or negedge rstn) begin
    if(~rstn)begin
        rdaddrid     <= 0;
        rdaddr       <= 0;
        rdaddrlen    <= 0;
        rdaddrburst  <= 0;
        task_rddelay <= 0;
    end
    else if(SLAVE_RD_ADDR_VALID && SLAVE_RD_ADDR_READY)begin
        rdaddrid     <= SLAVE_RD_ADDR_ID;
        rdaddr       <= SLAVE_RD_ADDR;
        rdaddrlen    <= SLAVE_RD_ADDR_LEN;
        rdaddrburst  <= SLAVE_RD_ADDR_BURST;
        task_rddelay <= 1;
    end
    else begin
        rdaddrid     <= rdaddrid;
        rdaddr       <= rdaddr;
        rdaddrlen    <= rdaddrlen;
        rdaddrburst  <= rdaddrburst;
        task_rddelay <= 0;
    end
end
always @(posedge SLAVE_CLK or negedge rstn) begin
    if(~rstn) task_rdaddr <= 0;
    else if(task_rddelay) task_rdaddr <= 1;
    else if(txtask_rd || localtask_rd) task_rdaddr <= 0;
    else task_rdaddr <= task_rdaddr;
end
//rddata
reg [3:0] rddata_state;
assign SLAVE_RD_DATA_VALID = localtask_state == HANDSHAKE ? rd_local_data_valid : rddata_state == 3 ? rd_fifo_data_valid : 1'b0;
assign SLAVE_RD_DATA = localtask_state == HANDSHAKE ? debugger_statue : rddata_state == 3 ? sfpfifo_data : 32'b0;
assign SLAVE_RD_DATA_LAST = localtask_state == HANDSHAKE ? rd_local_data_last : rddata_state == 3 ? sfpfifo_data_last : 1'b0;
assign sfpfifo_rden = sfpfifo_rden_reg || (rd_fifo_data_valid && SLAVE_RD_DATA_READY && ~SLAVE_RD_DATA_LAST && ~sfpfifo_empty);
assign SLAVE_RD_DATA_RESP = 2'b00;
always @(posedge SLAVE_CLK or negedge rstn) begin
    if(~rstn)begin
        sfpfifo_rden_reg <= 0;
        rddata_state <= 0;
        rd_fifo_data_valid <= 0;
    end
    else if(rddata_state == 0 && ~sfpfifo_empty)begin
        rd_fifo_data_valid <= 0;
        sfpfifo_rden_reg <= 1;
        rddata_state <= rddata_state + 1;
    end
    else if(rddata_state == 1)begin
        sfpfifo_rden_reg <= 0;
        rddata_state <= rddata_state + 1;
    end
    else if(rddata_state == 2 && sfpfifo_almostfull)begin
        rddata_state <= rddata_state + 1;
    end
    else if(rddata_state == 3 )begin
        if(rd_fifo_data_valid && SLAVE_RD_DATA_READY && SLAVE_RD_DATA_LAST)begin
            rd_fifo_data_valid <= 0;
            rddata_state <= 0;
        end
        else begin
            rd_fifo_data_valid <= 1;
            rddata_state <= rddata_state;
        end
    end
end
assign sfpfifo_wren = (sfprxstate == RXPORTDATA) ? data_valid_0 : 1'b0;
fifo_sfp_rd fifo_sfp_rd_inst (
  .wr_clk(rxclk_0),                // input
  .wr_rst(~rstn),                // input
  .wr_en(sfpfifo_wren),                  // input
  .wr_data({data_last_0,data_af_align_0}),              // input [32:0]
  .wr_full(),              // output
  .almost_full(sfpfifo_almostfull),      // output   200
  .rd_clk(SLAVE_CLK),                // input
  .rd_rst(~rstn),                // input
  .rd_en(sfpfifo_rden),                  // input
  .rd_data({sfpfifo_data_last,sfpfifo_data}),              // output [32:0]
  .rd_empty(sfpfifo_empty),            // output
  .almost_empty(sfpfifo_almostempty)     // output
);
//****************txtask********************//
always @(posedge SLAVE_CLK or negedge rstn) begin
    if(~rstn) task_cmd <= 0;
    else if(txtask_rd) task_cmd <= {8'b0,rdaddrlen,rdaddr[15:0]};
    else if(txtask_wr) task_cmd <= {wraddr[15:0],wrdata[15:0]};
    else task_cmd <= task_cmd;
end
always @(posedge SLAVE_CLK or negedge rstn) begin
    if(~rstn) begin
        i_txd_0 <= 32'hBCBCBCBC;
        i_txk_0 <= 4'b1111;
        txtask_state <= 0;
    end
    else begin
        case(txtask_state)
            IDLE : begin
                i_txd_0 <= 32'hBCBCBCBC;
                i_txk_0 <= 4'b1111;
                if(txtask_rd)      
                    txtask_state <= RDHEAD;
                else if(txtask_wr) 
                    txtask_state <= WRHEAD;
                else
                    txtask_state <= IDLE;
            end
            RDHEAD : begin
                i_txd_0 <= 32'hFF_000000;
                i_txk_0 <= 4'b0000;
                txtask_state <= CMDDATA;
            end
            WRHEAD : begin
                i_txd_0 <= 32'h00_000000;
                i_txk_0 <= 4'b0000;
                txtask_state <= CMDDATA;
            end
            CMDDATA : begin
                i_txd_0 <= task_cmd;
                i_txk_0 <= 4'b0000;
                txtask_state <= IDLE;
            end
        endcase
    end
end
//****************localtask********************//
always @(posedge SLAVE_CLK or negedge rstn) begin
    if(~rstn) begin
        localtask_state <= IDLE;
        trigdone_clear <= 0;
        rd_local_data_valid <= 0;
        rd_local_data_last <= 0;
    end
    else begin
        case(localtask_state)
            IDLE : begin
                rd_local_data_valid <= 0;
                rd_local_data_last <= 0;
                trigdone_clear <= 0;
                if(localtask_rd)
                    localtask_state <= LOCALREAD;
                else if(localtask_wr)
                    localtask_state <= LOCALWRITE;
                else 
                    localtask_state <= IDLE;
            end
            LOCALREAD : begin
                if(rdaddr[23:0] == 24'h000001)begin
                    rd_local_data_valid <= 1;
                    rd_local_data_last <= 1;
                    localtask_state <= HANDSHAKE;
                end
            end
            LOCALWRITE : begin
                if(wraddr[23:0] == 24'h000001)begin
                    if(debugger_statue[0] == 0)begin
                        trigdone_clear <= 0;
                        localtask_state <= IDLE;
                    end
                    else if(wrdata == 32'hFFFFFFFF) begin
                        trigdone_clear <= 1;
                        localtask_state <= LOCALWRITE;
                    end
                    else begin
                        trigdone_clear <= 0;
                        localtask_state <= IDLE;
                    end
                end
            end
            HANDSHAKE : begin
                if(SLAVE_RD_DATA_READY && SLAVE_RD_DATA_VALID)begin
                    rd_local_data_valid <= 0;
                    rd_local_data_last <= 0;
                    localtask_state <= IDLE;
                end
            end
        endcase
    end
end
//*****************rxcmd********************//rxclk_0
always @(posedge rxclk_0 or negedge rstn) begin
    if(~rstn)begin
        sfprxstate <= IDLE;
        sfprxtask  <= 0;
        sfprxstate_cmd <= 0;
    end
    else begin
        case(sfprxstate)
            IDLE : begin
                sfprxtask <= 0;
                if(data_valid_0)begin
                    if(data_af_align_0[31:24] == 8'h00)
                        sfprxstate <= RXCMD;
                    else if(data_af_align_0[31:24] == 8'hFF)
                        sfprxstate <= RXPORTDATA;
                end
                else begin
                    sfprxstate <= IDLE;
                end
            end
            RXPORTDATA : begin
                if(data_last_0) sfprxstate <= IDLE;
                else sfprxstate <= RXPORTDATA;
            end
            RXCMD : begin
                if(data_valid_0)begin
                    sfprxstate_cmd <= data_af_align_0;
                    sfprxtask <= 1;
                    sfprxstate <= IDLE;
                end
            end
        endcase
    end
end

always @(posedge rxclk_0 or negedge rstn) begin
    if(~rstn)begin
        debugger_statue <= 0;
    end
    else if(sfprxtask)begin
        if(sfprxstate_cmd == 32'hFFFFFFFF) 
            debugger_statue[0] <= 1;
        else debugger_statue <= debugger_statue;
    end
    else if(trigdone_clear)begin
        debugger_statue[0] <= 0;
    end
    else debugger_statue <= debugger_statue;
end


wire i_p_l0rxn;
wire i_p_l0rxp;
wire i_p_l1rxn;
wire i_p_l1rxp;
wire o_p_l0txn;
wire o_p_l0txp;
wire o_p_l1txn;
wire o_p_l1txp;
assign hsstinit = o_txlane_done_0 & o_rxlane_done_0 & o_p_pll_lock_0 ;
assign SLAVE_RSTN = hsstinit && rstn;
hsst_for_ctrlfpga_dut_top  hsst_for_ctrlfpga_dut_top_inst (
    .i_free_clk(i_free_clk),
    .rstn(rstn),
    .o_pll_done_0(o_pll_done_0),
    .o_txlane_done_0(o_txlane_done_0),
    .o_txlane_done_1(o_txlane_done_1),
    .o_rxlane_done_0(o_rxlane_done_0),
    .o_rxlane_done_1(o_rxlane_done_1),
    .i_p_refckn_0(i_p_refckn_0),
    .i_p_refckp_0(i_p_refckp_0),
    .o_p_pll_lock_0(o_p_pll_lock_0),
    .o_p_rx_sigdet_sta_0(o_p_rx_sigdet_sta_0),
    .o_p_rx_sigdet_sta_1(o_p_rx_sigdet_sta_1),
    .o_p_lx_cdr_align_0(o_p_lx_cdr_align_0),
    .o_p_lx_cdr_align_1(o_p_lx_cdr_align_1),
    .i_p_l0rxn(i_p_l0rxn),
    .i_p_l0rxp(i_p_l0rxp),
    .i_p_l1rxn(i_p_l1rxn),
    .i_p_l1rxp(i_p_l1rxp),
    .o_p_l0txn(o_p_l0txn),
    .o_p_l0txp(o_p_l0txp),
    .o_p_l1txn(o_p_l1txn),
    .o_p_l1txp(o_p_l1txp),
    .o_rxstatus_0(),
    .o_rxstatus_1(),
    .o_rdisper_0(),
    .o_rdecer_0(),
    .o_rdisper_1(),
    .o_rdecer_1(),
    .txclk_0(txclk_0),
    .txclk_1(txclk_1),
    .rxclk_0(rxclk_0),
    .rxclk_1(rxclk_1),
    .i_txd_0(i_txd_0),
    .i_txk_0(i_txk_0),
    .i_txd_1(i_txd_1),
    .i_txk_1(i_txk_1),
    .data_valid_0(data_valid_0),
    .data_valid_1(data_valid_1),
    .data_af_align_0(data_af_align_0),
    .data_af_align_1(data_af_align_1),
    .data_last_0(data_last_0),
    .data_last_1(data_last_1)
  );    
endmodule