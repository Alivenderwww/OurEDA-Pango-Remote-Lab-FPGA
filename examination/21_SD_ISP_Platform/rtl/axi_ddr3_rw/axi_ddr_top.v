`timescale  1ns/1ns
////////////////////////////////////////////////////////////////////////
// Author        : EmbedFire
// 实验平台: 野火FPGA系列开发板
// 公司    : http://www.embedfire.com
// 论坛    : http://www.firebbs.cn
// 淘宝    : https://fire-stm32.taobao.com
////////////////////////////////////////////////////////////////////////
module axi_ddr_top #
(
parameter  DDR_WR_LEN=128,//写突发长度 最大128个64bit
parameter  DDR_RD_LEN=128//读突发长度 最大128个64bit
)
(
    //50m的时钟与复位信号
    input   wire    sys_clk            , //系统时钟，50MHz
    input   wire    sys_rst_n          , //外部复位

    //DDR3接口
    output            mem_rst_n     , //Memory复位
    output            mem_ck        , //Memory差分时钟正端
    output            mem_ck_n      , //Memory差分时钟负端
    output            mem_cs_n      , //Memory片选
    output [14:0]     mem_a         , //Memory地址总线
    inout  [31:0]     mem_dq        , //数据总线
    inout  [3:0]      mem_dqs       , //数据时钟正端
    inout  [3:0]      mem_dqs_n     , //数据时钟负端
    output [3:0]      mem_dm        , //数据Mask
    output            mem_cke       , //Memory差分时钟使能
    output            mem_odt       , //On Die Termination
    output            mem_ras_n     , //行地址strobe
    output            mem_cas_n     , //列地址strobe
    output            mem_we_n      , //写使能
    output [2:0]      mem_ba        , //Bank地址总线

    input   wire      pingpang   , //乒乓操作，1使能，0不使能

    input   wire[31:0]wr_b_addr  , //写DDR首地址
    input   wire[31:0]wr_e_addr  , //写DDR末地址
    input   wire      user_wr_clk, //写FIFO写时钟
    input   wire      data_wren  , //写FIFO写请求
//写进fifo数据长度，可根据写fifo的写端口数据长度自行修改
//写FIFO写数据 16位，此时用64位是为了兼容32,64位
    input   wire[63:0]data_wr    , //写数据 低16有效
    input   wire      wr_rst     , //写地址复位

    input   wire[31:0]rd_b_addr  , //读DDR首地址
    input   wire[31:0]rd_e_addr  , //读DDR末地址
    input   wire      user_rd_clk, //读FIFO读时钟
    input   wire      data_rden  , //读FIFO读请求
//读出fifo数据长度，可根据读fifo的读端口数据长度自行修改
//读FIFO读数据,16位，此时用64位是为了兼容32,64位
    output  wire[63:0]data_rd    , //读数据 低16有效
    input   wire      rd_rst     , //读地址复位
    input   wire      read_enable, //读使能

    output  wire      ui_clk     , //输出时钟100m
    output  wire      calib_done   //ddr初始化完成
);

//********************************************************************//
//****************** Parameter and Internal Signal *******************//
//********************************************************************//

//wire  define
//axi写通道写地址
wire [3:0] M_AXI_WR_awid;   //写地址ID，用来标志一组写信号
wire [31:0]M_AXI_WR_awaddr; //写地址，给出一次写突发传输的写地址
wire [7:0] M_AXI_WR_awlen;  //突发长度，给出突发传输的次数
wire [2:0] M_AXI_WR_awsize; //突发大小，给出每次突发传输的字节数
wire [1:0] M_AXI_WR_awburst;//突发类型
wire       M_AXI_WR_awvalid;//有效信号，表明此通道的地址控制信号有效
wire       M_AXI_WR_awready;//表明“从”可以接收地址和对应的控制信号
//axi写通道读数据
wire [63:0]M_AXI_WR_wdata;  //写数据
wire [7:0] M_AXI_WR_wstrb;  //写数据有效的字节线
                            //用来表明哪8bits数据是有效的
wire       M_AXI_WR_wlast;  //表明此次传输是最后一个突发传输
wire       M_AXI_WR_wvalid; //写有效，表明此次写有效
wire       M_AXI_WR_wready; //表明从机可以接收写数据
//axi写通道读应答
wire [3:0] M_AXI_WR_bid;    //写响应ID TAG
wire [1:0] M_AXI_WR_bresp;  //写响应，表明写传输的状态
wire       M_AXI_WR_bvalid; //写响应有效
wire       M_AXI_WR_bready; //表明主机能够接收写响应
 //axi读通道写地址
wire [3:0] M_AXI_RD_arid;   //读地址ID，用来标志一组写信号
wire [31:0]M_AXI_RD_araddr; //读地址，给出一次写突发传输的读地址
wire [7:0] M_AXI_RD_arlen;  //突发长度，给出突发传输的次数
wire [2:0] M_AXI_RD_arsize; //突发大小，给出每次突发传输的字节数
wire [1:0] M_AXI_RD_arburst;//突发类型
wire       M_AXI_RD_arvalid;//有效信号，表明此通道的地址控制信号有效
wire       M_AXI_RD_arready;//表明“从”可以接收地址和对应的控制信号
//axi读通道读数据
wire [3:0] M_AXI_RD_rid;    //读ID tag
wire [63:0]M_AXI_RD_rdata;  //读数据
wire [1:0] M_AXI_RD_rresp;  //读响应，表明读传输的状态
wire       M_AXI_RD_rlast;  //表明读突发的最后一次传输
wire       M_AXI_RD_rvalid; //表明此通道信号有效
wire       M_AXI_RD_rready; //表明主机能够接收读数据和响应信息

//axi主机用户写控制信号
wire        wr_burst_req   ;
wire [31:0] wr_burst_addr  ;
wire [9:0]  wr_burst_len   ;
wire        wr_ready       ;
//axi写数据与使能fifo接口
wire        wr_fifo_re     ;
wire [63:0] wr_fifo_data   ;
wire        wr_burst_finish;
//axi主机用户读控制信号
wire        rd_burst_req   ;
wire [31:0] rd_burst_addr  ;
wire [9:0]  rd_burst_len   ;
wire        rd_ready       ;
//axi读数据与使能fifo接口
wire        rd_fifo_we     ;
wire [63:0] rd_fifo_data   ;
wire        rd_burst_finish;

//********************************************************************//
//*************************** Instantiation **************************//
//********************************************************************//

//------------- axi_ctrl_inst -------------
axi_ctrl
#(
.DDR_WR_LEN(DDR_WR_LEN),//写突发长度 128个64bit
.DDR_RD_LEN(DDR_RD_LEN)//读突发长度 128个64bit
)
axi_ctrl_inst
(
  .ui_clk     (ui_clk     ),
  .ui_rst     (sys_rst_n  ),
  .pingpang   (pingpang   ), //乒乓操作

  .wr_b_addr  (wr_b_addr  ), //写DDR首地址
  .wr_e_addr  (wr_e_addr  ), //写DDR末地址
  .user_wr_clk(user_wr_clk), //写FIFO写时钟
  .data_wren  (data_wren  ), //写FIFO写请求
  .data_wr    (data_wr    ), //写FIFO写数据 16位
                             //此时用64位是为了兼容32,64位
  .wr_rst     (wr_rst     ), //写地址复位

  .rd_b_addr  (rd_b_addr  ), //读DDR首地址
  .rd_e_addr  (rd_e_addr  ), //读DDR末地址
  .user_rd_clk(user_rd_clk), //读FIFO读时钟
  .data_rden  (data_rden  ), //读FIFO读请求
  .data_rd    (data_rd    ), //读FIFO读数据,16位，此时用64位是为了兼容32位
                             //64位，增强复用性，只需修改fifo即可
  .rd_rst     (rd_rst     ),
  .read_enable(read_enable),
  //连接到axi写主机
  .wr_burst_req     (wr_burst_req   ),
  .wr_burst_addr    (wr_burst_addr  ),
  .wr_burst_len     (wr_burst_len   ),
  .wr_ready         (wr_ready       ),
  .wr_fifo_re       (wr_fifo_re     ),
  .wr_fifo_data     (wr_fifo_data   ),
  .wr_burst_finish  (wr_burst_finish),
  //连接到axi读主机
  .rd_burst_req     (rd_burst_req   ),
  .rd_burst_addr    (rd_burst_addr  ),
  .rd_burst_len     (rd_burst_len   ),
  .rd_ready         (rd_ready       ),
  .rd_fifo_we       (rd_fifo_we     ),
  .rd_fifo_data     (rd_fifo_data   ),
  .rd_burst_finish  (rd_burst_finish)
);

//------------- axi_master_write_inst -------------
axi_master_write axi_master_write_inst
(
  .ARESETN      (sys_rst_n       ), //axi复位
  .ACLK         (ui_clk          ), //axi总时钟
  .M_AXI_AWID   (M_AXI_WR_awid   ), //写地址ID
  .M_AXI_AWADDR (M_AXI_WR_awaddr ), //写地址
  .M_AXI_AWLEN  (M_AXI_WR_awlen  ), //突发长度
  .M_AXI_AWSIZE (M_AXI_WR_awsize ), //突发大小
  .M_AXI_AWBURST(M_AXI_WR_awburst), //突发类型
  .M_AXI_AWLOCK (M_AXI_WR_awlock ), //总线锁信号
  .M_AXI_AWCACHE(M_AXI_WR_awcache), //内存类型
  .M_AXI_AWPROT (M_AXI_WR_awprot ), //保护类型
  .M_AXI_AWQOS  (M_AXI_WR_awqos  ), //质量服务QoS
  .M_AXI_AWVALID(M_AXI_WR_awvalid), //有效信号
  .M_AXI_AWREADY(M_AXI_WR_awready), //握手信号awready

  .M_AXI_WDATA (M_AXI_WR_wdata   ), //写数据
  .M_AXI_WSTRB (M_AXI_WR_wstrb   ), //写数据有效的字节线
  .M_AXI_WLAST (M_AXI_WR_wlast   ), //表明此次传输是最后一个突发传输
  .M_AXI_WVALID(M_AXI_WR_wvalid  ), //写有效
  .M_AXI_WREADY(M_AXI_WR_wready  ), //表明从机可以接收写数据

  .M_AXI_BID   (M_AXI_WR_bid     ), //写响应ID TAG
  .M_AXI_BRESP (M_AXI_WR_bresp   ), //写响应
  .M_AXI_BVALID(M_AXI_WR_bvalid  ), //写响应有效
  .M_AXI_BREADY(M_AXI_WR_bready  ), //表明主机能够接收写响应

  .WR_START    (wr_burst_req     ), //写突发触发信号
  .WR_ADRS     (wr_burst_addr    ), //地址
  .WR_LEN      (wr_burst_len     ), //长度
  .WR_READY    (wr_ready         ), //写空闲
  .WR_FIFO_RE  (wr_fifo_re       ), //连接到写fifo的读使能
  .WR_FIFO_DATA(wr_fifo_data     ), //连接到fifo的读数据
  .WR_DONE     (wr_burst_finish  )  //完成一次突发
);

//------------- axi_master_read_inst -------------
axi_master_read axi_master_read_inst
(
  . ARESETN      (sys_rst_n),
  . ACLK         (ui_clk),
  . M_AXI_ARID   (M_AXI_RD_arid   ), //读地址ID
  . M_AXI_ARADDR (M_AXI_RD_araddr ), //读地址
  . M_AXI_ARLEN  (M_AXI_RD_arlen  ), //突发长度
  . M_AXI_ARSIZE (M_AXI_RD_arsize ), //突发大小
  . M_AXI_ARBURST(M_AXI_RD_arburst), //突发类型
  . M_AXI_ARLOCK (M_AXI_RD_arlock ), //总线锁信号
  . M_AXI_ARCACHE(M_AXI_RD_arcache), //内存类型
  . M_AXI_ARPROT (M_AXI_RD_arprot ), //保护类型
  . M_AXI_ARQOS  (M_AXI_RD_arqos  ), //质量服务QOS
  . M_AXI_ARVALID(M_AXI_RD_arvalid), //有效信号
  . M_AXI_ARREADY(M_AXI_RD_arready), //握手信号arready

  . M_AXI_RID   (M_AXI_RD_rid   ), //读ID tag
  . M_AXI_RDATA (M_AXI_RD_rdata ), //读数据
  . M_AXI_RRESP (M_AXI_RD_rresp ), //读响应，表明读传输的状态
  . M_AXI_RLAST (M_AXI_RD_rlast ), //表明读突发的最后一次传输
  . M_AXI_RVALID(M_AXI_RD_rvalid), //表明此通道信号有效
  . M_AXI_RREADY(M_AXI_RD_rready), //表明主机能够接收读数据和响应信息

  . RD_START    (rd_burst_req   ), //读突发触发信号
  . RD_ADRS     (rd_burst_addr  ), //地址
  . RD_LEN      (rd_burst_len   ), //长度
  . RD_READY    (rd_ready       ), //读空闲
  . RD_FIFO_WE  (rd_fifo_we     ), //连接到读fifo的写使能
  . RD_FIFO_DATA(rd_fifo_data   ), //连接到读fifo的写数据
  . RD_DONE     (rd_burst_finish)  //完成一次突发
);

//------------- u_axi_ddr -------------
ddr3_test axi_ddr_inst
(
  .ref_clk          (sys_clk        ),
  .resetn           (sys_rst_n      ),  // input
  .core_clk         (ui_clk         ),  // output
  .pll_lock         (               ),  // output
  .phy_pll_lock     (               ),  // output
  .gpll_lock        (               ),  // output
  .rst_gpll_lock    (               ),  // output
  .ddrphy_cpd_lock  (               ),  // output
  .ddr_init_done    (calib_done     ),  // output
  
  .mem_cs_n         (mem_cs_n       ),  // output
  .mem_rst_n        (mem_rst_n      ),  // output
  .mem_ck           (mem_ck         ),  // output
  .mem_ck_n         (mem_ck_n       ),  // output
  .mem_cke          (mem_cke        ),  // output
  .mem_ras_n        (mem_ras_n      ),  // output
  .mem_cas_n        (mem_cas_n      ),  // output
  .mem_we_n         (mem_we_n       ),  // output
  .mem_odt          (mem_odt        ),  // output
  .mem_a            (mem_a          ),  // output [14:0]
  .mem_ba           (mem_ba         ),  // output [2:0]
  .mem_dqs          (mem_dqs        ),  // inout [3:0]
  .mem_dqs_n        (mem_dqs_n      ),  // inout [3:0]
  .mem_dq           (mem_dq         ),  // inout [31:0]
  .mem_dm           (mem_dm         ),  // output [3:0]

  .axi_awaddr       (M_AXI_WR_awaddr),  // input [27:0]
  .axi_awuser_ap    (1'b0           ),  // input
  .axi_awuser_id    (M_AXI_WR_awid  ),  // input [3:0]
  .axi_awlen        (M_AXI_WR_awlen ),  // input [3:0]
  .axi_awready      (M_AXI_WR_awready), // output
  .axi_awvalid      (M_AXI_WR_awvalid), // input
  
  .axi_wdata        (M_AXI_WR_wdata ),  // input [255:0]
  .axi_wstrb        (M_AXI_WR_wstrb ),  // input [31:0]
  .axi_wready       (M_AXI_WR_wready),  // output
  .axi_wusero_id    (               ),  // output [3:0]
  .axi_wusero_last  (M_AXI_WR_wlast ),  // output
  
  .axi_araddr       (M_AXI_RD_araddr),  // input [27:0]
  .axi_aruser_ap    (1'b0           ),  // input
  .axi_aruser_id    (M_AXI_RD_arid  ),  // input [3:0]
  .axi_arlen        (M_AXI_RD_arlen ),  // input [3:0]
  .axi_arready      (M_AXI_RD_arready), // output
  .axi_arvalid      (M_AXI_RD_arvalid), // input
  
  .axi_rdata        (M_AXI_RD_rdata ),  // output [255:0]
  .axi_rid          (M_AXI_RD_rid   ),  // output [3:0]
  .axi_rlast        (M_AXI_RD_rlast ),  // output
  .axi_rvalid       (M_AXI_RD_rvalid),  // output
  
  .apb_clk          (               ),  // input
  .apb_rst_n        (               ),  // input
  .apb_sel          (               ),  // input
  .apb_enable       (               ),  // input
  .apb_addr         (               ),  // input [7:0]
  .apb_write        (               ),  // input
  .apb_ready        (               ),  // output
  .apb_wdata        (               ),  // input [15:0]
  .apb_rdata        (               ),  // output [15:0]

  .dbg_gate_start           (1'b0       ),  // input
  .dbg_cpd_start            (1'b0       ),  // input 
  .dbg_ddrphy_rst_n         (1'b1       ),  // input
  .dbg_gpll_scan_rst        (1'b0       ),  // input
        
  .samp_position_dyn_adj    (1'b0       ),  // input
  .init_samp_position_even  (1'b0       ),  // input [31:0]
  .init_samp_position_odd   (1'b0       ),  // input [31:0]
        
  .wrcal_position_dyn_adj   (1'b0       ),  // input
  .init_wrcal_position      (1'b0       ),  // input [31:0]
        
  .force_read_clk_ctrl      (1'b0       ),  // input
  .init_slip_step           (1'b0       ),  // input [15:0]
  .init_read_clk_ctrl       (1'b0       ),  // input [11:0]
        
  .debug_calib_ctrl         (       ),  // output [33:0]
  .dbg_slice_status         (       ),  // output [67:0]
  .dbg_slice_state          (       ),  // output [87:0]
  .debug_data               (       ),  // output [275:0]
  .dbg_dll_upd_state        (       ),  // output [1:0]
  .debug_gpll_dps_phase     (       ),  // output [8:0]
        
  .dbg_rst_dps_state        (       ),  // output [2:0]
  .dbg_tran_err_rst_cnt     (       ),  // output [5:0]
  .dbg_ddrphy_init_fail     (       ),  // output
        
  .debug_cpd_offset_adj     (1'b0       ),  // input
  .debug_cpd_offset_dir     (1'b0       ),  // input
  .debug_cpd_offset         (1'b0       ),  // input [9:0]
  .debug_dps_cnt_dir0       (       ),  // output [9:0]
  .debug_dps_cnt_dir1       (       ),  // output [9:0]
        
  .ck_dly_en                (       ),  // input
  .init_ck_dly_step         (       ),  // input [7:0]
  .ck_dly_set_bin           (       ),  // output [7:0]
  .align_error              (       ),  // output
  .debug_rst_state          (       ),  // output [3:0]
  .debug_cpd_state          (       )   // output [3:0]

);

endmodule
