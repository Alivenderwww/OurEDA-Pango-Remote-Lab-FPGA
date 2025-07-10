module sys_status_axi_slave #(
    parameter DEFAULT_MAC_ADDR = 48'h12_34_56_78_9A_BC, // 默认MAC地址
    parameter DEFAULT_BOARD_IP_ADDR  = {8'd192, 8'd168, 8'd1, 8'd100},  // 默认IP地址
    parameter DEFAULT_HOST_IP_ADDR = {8'd192, 8'd168, 8'd1, 8'd1} // 默认上位机IP地址
)(
    // 时钟和复位信号
    input                clk                       , // 系统时钟
    input                rstn                      , // 系统复位，低电平有效
    output logic         STATUS_SLAVE_CLK          , // AXI从机时钟输出
    output logic         STATUS_SLAVE_RSTN         , // AXI从机复位输出
    
    // AXI写地址通道信号
    input  logic [4-1:0] STATUS_SLAVE_WR_ADDR_ID   , // 写地址ID
    input  logic [31:0]  STATUS_SLAVE_WR_ADDR      , // 写地址
    input  logic [ 7:0]  STATUS_SLAVE_WR_ADDR_LEN  , // 突发传输长度
    input  logic [ 1:0]  STATUS_SLAVE_WR_ADDR_BURST, // 突发类型
    input  logic         STATUS_SLAVE_WR_ADDR_VALID, // 写地址有效
    output logic         STATUS_SLAVE_WR_ADDR_READY, // 写地址就绪
    
    // AXI写数据通道信号
    input  logic [31:0]  STATUS_SLAVE_WR_DATA      , // 写数据
    input  logic [ 3:0]  STATUS_SLAVE_WR_STRB      , // 写数据字节选通
    input  logic         STATUS_SLAVE_WR_DATA_LAST , // 最后一个数据
    input  logic         STATUS_SLAVE_WR_DATA_VALID, // 写数据有效
    output logic         STATUS_SLAVE_WR_DATA_READY, // 写数据就绪
    
    // AXI写响应通道信号
    output logic [4-1:0] STATUS_SLAVE_WR_BACK_ID   , // 写响应ID
    output logic [ 1:0]  STATUS_SLAVE_WR_BACK_RESP , // 写响应状态
    output logic         STATUS_SLAVE_WR_BACK_VALID, // 写响应有效
    input  logic         STATUS_SLAVE_WR_BACK_READY, // 写响应就绪
    
    // AXI读地址通道信号
    input  logic [4-1:0] STATUS_SLAVE_RD_ADDR_ID   , // 读地址ID
    input  logic [31:0]  STATUS_SLAVE_RD_ADDR      , // 读地址
    input  logic [ 7:0]  STATUS_SLAVE_RD_ADDR_LEN  , // 突发传输长度
    input  logic [ 1:0]  STATUS_SLAVE_RD_ADDR_BURST, // 突发类型
    input  logic         STATUS_SLAVE_RD_ADDR_VALID, // 读地址有效
    output logic         STATUS_SLAVE_RD_ADDR_READY, // 读地址就绪
    
    // AXI读数据通道信号
    output logic [4-1:0] STATUS_SLAVE_RD_BACK_ID   , // 读数据ID
    output logic [31:0]  STATUS_SLAVE_RD_DATA      , // 读数据
    output logic [ 1:0]  STATUS_SLAVE_RD_DATA_RESP , // 读响应状态
    output logic         STATUS_SLAVE_RD_DATA_LAST , // 最后一个数据
    output logic         STATUS_SLAVE_RD_DATA_VALID, // 读数据有效
    input  logic         STATUS_SLAVE_RD_DATA_READY, // 读数据就绪

    // 系统状态接口
    input  logic [15:0]  axi_master_rstn_status,   // AXI主机复位状态
    input  logic [15:0]  axi_slave_rstn_status,    // AXI从机复位状态
    output logic [15:0]  axi_master_reset,         // AXI主机复位控制
    output logic [15:0]  axi_slave_reset,          // AXI从机复位控制
    input  logic [31:0]  uid_high,                 // UID高32位
    input  logic [31:0]  uid_low,                  // UID低32位
    output logic [ 7:0]  power_status,             // POWER上电状态
    output logic [ 7:0]  power_reset,              // POWER复位控制
    
    // MAC/IP配置接口
    output logic [31:0]  host_ip_addr,             // 当前上位机IP地址
    output logic [31:0]  board_ip_addr,            // 当前本机IP地址
    output logic [47:0]  host_mac_addr,            // 当前上位机MAC地址
    output logic [31:0]  board_mac_addr,           // 当前本机MAC地址
    input  logic [31:0]  default_host_ip_addr,     // 默认上位机IP地址
    input  logic [31:0]  default_board_ip_addr,    // 默认本机IP地址
    input  logic [47:0]  default_host_mac_addr,    // 默认上位机MAC地址
    input  logic [47:0]  default_board_mac_addr,   // 默认本机MAC地址

    output logic [31:0]  OV_STORE_BASE_ADDR,       // OV5640存储起始地址
    output logic [31:0]  OV_STORE_NUM,             // OV5640存储数量
    output logic         OV_capture_on             // OV5640捕获使能信号
);//系统状态AXI从机，用于读取和配置CTRL_FPGA系统的各项基本参数，如AXI总线复位情况，LAB_FPGA的上电、复位，UID，EEPROM，MAC地址，IP地址等等

// 复位同步逻辑
wire STATUS_SLAVE_RSTN_SYNC;
assign STATUS_SLAVE_CLK = clk;
assign STATUS_SLAVE_RSTN = STATUS_SLAVE_RSTN_SYNC;
rstn_sync status_rstn_sync(clk,rstn,STATUS_SLAVE_RSTN_SYNC);

/* 地址映射说明
32'h0000_0000:  只读    AXI总线主从机复位情况，[31:16]为16-1号主机，[15:0]为16-1号从机，1为复位结束（即正常运行中），0为正在复位
32'h0000_0001:  只写    AXI总线主从机手动复位，[31:16]为16-1号主机，[15:0]为16-1号从机，1为重新复位，0为不影响。复位后自动置零。对从机自身无效。
32'h0000_0002:  只读    UID高32位
32'h0000_0003:  只读    CTRL_FPGA的UID低32位，格式为{0x02,0x03}={UID}。UID是唯一器件标识符
32'h0000_0004:  读写    [7:0]位为电源管理模块8个供电口的状态，1为供电，0为不供电，可读取或更改
32'h0000_0005:  只写    [7:0]位为电源管理模块8个供电口对应器件的复位，1为重新复位，0为不影响。复位后自动置零

32'h0000_0006:  读写    上位机IP地址
32'h0000_0007:  读写    本机IP地址
32'h0000_0008:  读写    上位机MAC地址高16位
32'h0000_0009:  读写    上位机MAC地址低32位
32'h0000_000A:  读写    本机MAC地址高16位
32'h0000_000B:  读写    本机MAC地址低32位
32'h0000_000C:  只读    默认上位机IP地址
32'h0000_000D:  只读    默认本机IP地址
32'h0000_000E:  只读    默认上位机MAC地址高16位
32'h0000_000F:  只读    默认上位机MAC地址低32位
32'h0000_0010:  只读    默认本机MAC地址高16位
32'h0000_0011:  只读    默认本机MAC地址低32位

32'h0000_0012:  读写    OV5640存储起始地址，32位地址线
32'h0000_0013:  读写    OV5640存储数量，32位地址线，单位为32bit
32'h0000_0014:  读写    OV5640捕获使能信号，1为使能，0为禁止
*/

// 地址定义
localparam ADDR_AXI_INIT            = 32'h0000_0000, // AXI总线初始化状态
           ADDR_AXI_RESET           = 32'h0000_0001, // AXI总线复位控制
           ADDR_UID_2               = 32'h0000_0002, // UID高32位
           ADDR_UID_1               = 32'h0000_0003, // UID低32位
           ADDR_POWER_STATUS        = 32'h0000_0004, // POWER上电状态
           ADDR_POWER_RESET         = 32'h0000_0005, // POWER对应器件的复位控制
           ADDR_HOST_IP             = 32'h0000_0006, // 上位机IP地址
           ADDR_BOARD_IP            = 32'h0000_0007, // 本机IP地址
           ADDR_HOST_MAC_2          = 32'h0000_0008, // 上位机MAC地址高16位
           ADDR_HOST_MAC_1          = 32'h0000_0009, // 上位机MAC地址低32位
           ADDR_BOARD_MAC_2         = 32'h0000_000A, // 本机MAC地址高16位
           ADDR_BOARD_MAC_1         = 32'h0000_000B, // 本机MAC地址低32位
           ADDR_DEFAULT_HOST_IP     = 32'h0000_000C, // 默认上位机IP地址
           ADDR_DEFAULT_BOARD_IP    = 32'h0000_000D, // 默认本机IP地址
           ADDR_DEFAULT_HOST_MAC_2  = 32'h0000_000E, // 默认上位机MAC地址高16位
           ADDR_DEFAULT_HOST_MAC_1  = 32'h0000_000F, // 默认上位机MAC地址低32位
           ADDR_DEFAULT_BOARD_MAC_2 = 32'h0000_0010, // 默认本机MAC地址
           ADDR_DEFAULT_BOARD_MAC_1 = 32'h0000_0011, // 默认本机MAC地址低32位
           ADDR_OV_STORE_BASE_ADDR  = 32'h0000_0012, // OV5640存储起始地址
           ADDR_OV_STORE_NUM        = 32'h0000_0013, // OV5640存储数量
           ADDR_OV_CAPTURE_ON       = 32'h0000_0014; // OV5640捕获使能信号

//_________________写___通___道_________________//
reg [ 3:0] wr_addr_id;    // 写地址ID寄存器
reg [31:0] wr_addr;       // 写地址寄存器
reg [ 1:0] wr_addr_burst; // 写突发类型寄存器
reg        wr_transcript_error, wr_transcript_error_reg; // 写传输错误标志及其寄存器
//JTAG作为SLAVE不接收WR_ADDR_LEN，其DATA线的结束以WR_DATA_LAST为参考。

// 写通道状态机定义
reg [ 1:0] cu_wrchannel_st, nt_wrchannel_st;  // 当前状态和下一状态
localparam ST_WR_IDLE = 2'b00, // 写通道空闲
           ST_WR_DATA = 2'b01, // 地址线握手成功，数据线通道开启
           ST_WR_RESP = 2'b10; // 写响应

//_________________读___通___道_________________//
reg [ 3:0] rd_addr_id;     // 读地址ID寄存器
reg [31:0] rd_addr;        // 读地址寄存器
reg [ 7:0] rd_addr_len;    // 读突发长度寄存器
reg [ 1:0] rd_addr_burst;  // 读突发类型寄存器
reg [ 7:0] rd_data_trans_num; // 读数据传输计数器
reg        rd_transcript_error, rd_transcript_error_reg; // 读传输错误标志及其寄存器

// 读通道状态机定义
reg [ 1:0] cu_rdchannel_st, nt_rdchannel_st;  // 当前状态和下一状态
localparam ST_RD_IDLE = 2'b00, // 发送完LAST和RESP，读通道空闲
           ST_RD_DATA = 2'b01; // 地址线握手成功，数据线通道开启

// 系统状态寄存器
reg [31:0] host_ip_addr_reg;
reg [31:0] board_ip_addr_reg;
reg [47:0] host_mac_addr_reg;
reg [47:0] board_mac_addr_reg;

//_______________________________________________________________________________//
// 写通道状态机状态转换逻辑
always @(*) begin
    case (cu_wrchannel_st)
        ST_WR_IDLE: nt_wrchannel_st <= (STATUS_SLAVE_WR_ADDR_VALID && STATUS_SLAVE_WR_ADDR_READY)?(ST_WR_DATA):(ST_WR_IDLE);
        ST_WR_DATA: nt_wrchannel_st <= (STATUS_SLAVE_WR_DATA_VALID && STATUS_SLAVE_WR_DATA_READY && STATUS_SLAVE_WR_DATA_LAST)?(ST_WR_RESP):(ST_WR_DATA);
        ST_WR_RESP: nt_wrchannel_st <= (STATUS_SLAVE_WR_BACK_VALID && STATUS_SLAVE_WR_BACK_READY)?(ST_WR_IDLE):(ST_WR_RESP);
        default   : nt_wrchannel_st <= ST_WR_IDLE;
    endcase
end

// 写通道状态机时序逻辑
always @(posedge clk or negedge STATUS_SLAVE_RSTN_SYNC) begin
    if(~STATUS_SLAVE_RSTN_SYNC) cu_wrchannel_st <= ST_WR_IDLE;
    else cu_wrchannel_st <= nt_wrchannel_st;
end

// 写通道控制信号生成
assign STATUS_SLAVE_WR_ADDR_READY = (STATUS_SLAVE_RSTN_SYNC) && (cu_wrchannel_st == ST_WR_IDLE);
assign STATUS_SLAVE_WR_BACK_VALID = (STATUS_SLAVE_RSTN_SYNC) && (cu_wrchannel_st == ST_WR_RESP);
assign STATUS_SLAVE_WR_BACK_RESP  = ((STATUS_SLAVE_RSTN_SYNC) && ((~wr_transcript_error) && (~wr_transcript_error_reg)))?(2'b00):(2'b10);
assign STATUS_SLAVE_WR_BACK_ID    = wr_addr_id;

// 写通道地址和突发类型寄存
always @(posedge clk or negedge STATUS_SLAVE_RSTN_SYNC) begin
    if(~STATUS_SLAVE_RSTN_SYNC) begin
        wr_addr_id    <= 0;
        wr_addr_burst <= 0;
    end else if(STATUS_SLAVE_WR_ADDR_VALID && STATUS_SLAVE_WR_ADDR_READY) begin
        wr_addr_id    <= STATUS_SLAVE_WR_ADDR_ID;
        wr_addr_burst <= STATUS_SLAVE_WR_ADDR_BURST;
    end else begin
        wr_addr_id    <= wr_addr_id;
        wr_addr_burst <= wr_addr_burst;
    end
end

// 写地址计算逻辑
always @(posedge clk or negedge STATUS_SLAVE_RSTN_SYNC) begin
    if(~STATUS_SLAVE_RSTN_SYNC) wr_addr <= 0;
    else if(STATUS_SLAVE_WR_ADDR_VALID && STATUS_SLAVE_WR_ADDR_READY) wr_addr <= STATUS_SLAVE_WR_ADDR;
    else if((wr_addr_burst == 2'b01) && STATUS_SLAVE_WR_DATA_VALID && STATUS_SLAVE_WR_DATA_READY) wr_addr <= wr_addr + 1;
    else wr_addr <= wr_addr;
end

// 写错误检测逻辑
always @(*) begin
    if((~STATUS_SLAVE_RSTN_SYNC) || (cu_wrchannel_st == ST_WR_IDLE) || (cu_wrchannel_st == ST_WR_RESP)) wr_transcript_error <= 0;
    else if((wr_addr_burst == 2'b10) || (wr_addr_burst == 2'b11)) wr_transcript_error <= 1;
    else if((wr_addr < ADDR_AXI_INIT) || (wr_addr > ADDR_OV_CAPTURE_ON)) wr_transcript_error <= 1;
    else if(wr_addr == ADDR_UID_2 || wr_addr == ADDR_UID_1) wr_transcript_error <= 1;
    else wr_transcript_error <= 0;
end

// 写错误状态寄存
always @(posedge clk or negedge STATUS_SLAVE_RSTN_SYNC) begin
    if((~STATUS_SLAVE_RSTN_SYNC) || (cu_wrchannel_st == ST_WR_IDLE)) wr_transcript_error_reg <= 0;
    else wr_transcript_error_reg <= (wr_transcript_error)?(1):(wr_transcript_error_reg);
end

// 写数据READY选通
always @(*) begin
    if(~STATUS_SLAVE_RSTN_SYNC) STATUS_SLAVE_WR_DATA_READY <= 0;
    else if(cu_wrchannel_st == ST_WR_DATA) begin
        STATUS_SLAVE_WR_DATA_READY <= 1; // 其他寄存器可以直接写入
    end else STATUS_SLAVE_WR_DATA_READY <= 0;
end

// 写数据处理逻辑
always @(posedge clk or negedge STATUS_SLAVE_RSTN_SYNC) begin
    if(~STATUS_SLAVE_RSTN_SYNC) begin
        axi_master_reset <= 0;
        axi_slave_reset  <= 0;
        power_status     <= 0;
        host_ip_addr_reg   <= 0;
        host_mac_addr_reg  <= 0;
        board_ip_addr_reg  <= 0;
        board_mac_addr_reg <= 0;
        OV_STORE_BASE_ADDR <= 32'h0000_0000;
        OV_STORE_NUM       <= ((640*480)*16)/32;
        OV_capture_on      <= 0;
    end else if(STATUS_SLAVE_WR_DATA_VALID && STATUS_SLAVE_WR_DATA_READY) begin
        case(wr_addr)
            ADDR_AXI_RESET: begin
                if(STATUS_SLAVE_WR_STRB[3]) axi_master_reset[15:8] <= STATUS_SLAVE_WR_DATA[31:24];
                if(STATUS_SLAVE_WR_STRB[2]) axi_master_reset[7:0] <= STATUS_SLAVE_WR_DATA[23:16];
                if(STATUS_SLAVE_WR_STRB[1]) axi_slave_reset[15:8] <= STATUS_SLAVE_WR_DATA[15:8];
                if(STATUS_SLAVE_WR_STRB[0]) axi_slave_reset[7:0] <= STATUS_SLAVE_WR_DATA[7:0];
            end
            ADDR_POWER_STATUS: begin
                if(STATUS_SLAVE_WR_STRB[0]) power_status[7:0] <= STATUS_SLAVE_WR_DATA[7:0];
            end
            ADDR_POWER_RESET: begin
                if(STATUS_SLAVE_WR_STRB[0]) power_reset <= STATUS_SLAVE_WR_DATA[7:0];
            end
            ADDR_HOST_IP: begin
                if(STATUS_SLAVE_WR_STRB[3]) host_ip_addr_reg[31:24] <= STATUS_SLAVE_WR_DATA[31:24];
                if(STATUS_SLAVE_WR_STRB[2]) host_ip_addr_reg[23:16] <= STATUS_SLAVE_WR_DATA[23:16];
                if(STATUS_SLAVE_WR_STRB[1]) host_ip_addr_reg[15:8] <= STATUS_SLAVE_WR_DATA[15:8];
                if(STATUS_SLAVE_WR_STRB[0]) host_ip_addr_reg[7:0] <= STATUS_SLAVE_WR_DATA[7:0];
            end
            ADDR_HOST_MAC_2: begin
                if(STATUS_SLAVE_WR_STRB[1]) host_mac_addr_reg[47:40] <= STATUS_SLAVE_WR_DATA[15:8];
                if(STATUS_SLAVE_WR_STRB[0]) host_mac_addr_reg[39:32] <= STATUS_SLAVE_WR_DATA[7:0];
            end
            ADDR_HOST_MAC_1: begin
                if(STATUS_SLAVE_WR_STRB[3]) host_mac_addr_reg[31:24] <= STATUS_SLAVE_WR_DATA[31:24];
                if(STATUS_SLAVE_WR_STRB[2]) host_mac_addr_reg[23:16] <= STATUS_SLAVE_WR_DATA[23:16];
                if(STATUS_SLAVE_WR_STRB[1]) host_mac_addr_reg[15:8] <= STATUS_SLAVE_WR_DATA[15:8];
                if(STATUS_SLAVE_WR_STRB[0]) host_mac_addr_reg[7:0] <= STATUS_SLAVE_WR_DATA[7:0];
            end
            ADDR_BOARD_IP: begin
                if(STATUS_SLAVE_WR_STRB[3]) board_ip_addr_reg[31:24] <= STATUS_SLAVE_WR_DATA[31:24];
                if(STATUS_SLAVE_WR_STRB[2]) board_ip_addr_reg[23:16] <= STATUS_SLAVE_WR_DATA[23:16];
                if(STATUS_SLAVE_WR_STRB[1]) board_ip_addr_reg[15:8] <= STATUS_SLAVE_WR_DATA[15:8];
                if(STATUS_SLAVE_WR_STRB[0]) board_ip_addr_reg[7:0] <= STATUS_SLAVE_WR_DATA[7:0];
            end
            ADDR_BOARD_MAC_2: begin
                if(STATUS_SLAVE_WR_STRB[1]) board_mac_addr_reg[47:40] <= STATUS_SLAVE_WR_DATA[15:8];
                if(STATUS_SLAVE_WR_STRB[0]) board_mac_addr_reg[39:32] <= STATUS_SLAVE_WR_DATA[7:0];
            end
            ADDR_BOARD_MAC_1: begin
                if(STATUS_SLAVE_WR_STRB[3]) board_mac_addr_reg[31:24] <= STATUS_SLAVE_WR_DATA[31:24];
                if(STATUS_SLAVE_WR_STRB[2]) board_mac_addr_reg[23:16] <= STATUS_SLAVE_WR_DATA[23:16];
                if(STATUS_SLAVE_WR_STRB[1]) board_mac_addr_reg[15:8] <= STATUS_SLAVE_WR_DATA[15:8];
                if(STATUS_SLAVE_WR_STRB[0]) board_mac_addr_reg[7:0] <= STATUS_SLAVE_WR_DATA[7:0];
            end
            ADDR_OV_STORE_BASE_ADDR: begin
                if(STATUS_SLAVE_WR_STRB[3]) OV_STORE_BASE_ADDR[31:24] <= STATUS_SLAVE_WR_DATA[31:24];
                if(STATUS_SLAVE_WR_STRB[2]) OV_STORE_BASE_ADDR[23:16] <= STATUS_SLAVE_WR_DATA[23:16];
                if(STATUS_SLAVE_WR_STRB[1]) OV_STORE_BASE_ADDR[15:8] <= STATUS_SLAVE_WR_DATA[15:8];
                if(STATUS_SLAVE_WR_STRB[0]) OV_STORE_BASE_ADDR[7:0] <= STATUS_SLAVE_WR_DATA[7:0];
            end
            ADDR_OV_STORE_NUM: begin
                if(STATUS_SLAVE_WR_STRB[3]) OV_STORE_NUM[31:24] <= STATUS_SLAVE_WR_DATA[31:24];
                if(STATUS_SLAVE_WR_STRB[2]) OV_STORE_NUM[23:16] <= STATUS_SLAVE_WR_DATA[23:16];
                if(STATUS_SLAVE_WR_STRB[1]) OV_STORE_NUM[15:8] <= STATUS_SLAVE_WR_DATA[15:8];
                if(STATUS_SLAVE_WR_STRB[0]) OV_STORE_NUM[7:0] <= STATUS_SLAVE_WR_DATA[7:0];
            end
            ADDR_OV_CAPTURE_ON: begin
                if(STATUS_SLAVE_WR_STRB[0]) OV_capture_on <= STATUS_SLAVE_WR_DATA[0];
            end
            default: begin
            end
        endcase
    end else begin
        axi_master_reset <= 0;
        axi_slave_reset <= 0;
        power_reset <= 0;
    end
end

//_______________________________________________________________________________//
// 读通道状态机状态转换逻辑
always @(*) begin
    case (cu_rdchannel_st)
        ST_RD_IDLE: nt_rdchannel_st <= (STATUS_SLAVE_RD_ADDR_VALID && STATUS_SLAVE_RD_ADDR_READY)?(ST_RD_DATA):(ST_RD_IDLE);
        ST_RD_DATA: nt_rdchannel_st <= (STATUS_SLAVE_RD_DATA_VALID && STATUS_SLAVE_RD_DATA_READY && STATUS_SLAVE_RD_DATA_LAST)?(ST_RD_IDLE):(ST_RD_DATA);
        default   : nt_rdchannel_st <= ST_RD_IDLE;
    endcase
end

// 读通道状态机时序逻辑
always @(posedge clk or negedge STATUS_SLAVE_RSTN_SYNC) begin
    if(~STATUS_SLAVE_RSTN_SYNC) cu_rdchannel_st <= ST_RD_IDLE;
    else cu_rdchannel_st <= nt_rdchannel_st;
end

// 读通道控制信号生成
assign STATUS_SLAVE_RD_ADDR_READY = (STATUS_SLAVE_RSTN_SYNC) && (cu_rdchannel_st == ST_RD_IDLE);
assign STATUS_SLAVE_RD_BACK_ID = rd_addr_id;
assign STATUS_SLAVE_RD_DATA_RESP = ((STATUS_SLAVE_RSTN_SYNC) && ((~rd_transcript_error) && (~rd_transcript_error_reg)))?(2'b00):(2'b10);

// 读通道地址和突发参数寄存
always @(posedge clk or negedge STATUS_SLAVE_RSTN_SYNC) begin
    if(~STATUS_SLAVE_RSTN_SYNC) begin
        rd_addr_id <= 0;
        rd_addr_burst <= 0;
        rd_addr_len <= 0;
    end else if(STATUS_SLAVE_RD_ADDR_VALID && STATUS_SLAVE_RD_ADDR_READY) begin
        rd_addr_id <= STATUS_SLAVE_RD_ADDR_ID;
        rd_addr_burst <= STATUS_SLAVE_RD_ADDR_BURST;
        rd_addr_len <= STATUS_SLAVE_RD_ADDR_LEN;
    end else begin
        rd_addr_id <= rd_addr_id;
        rd_addr_burst <= rd_addr_burst;
        rd_addr_len <= rd_addr_len;
    end
end

// 读地址计算逻辑
always @(posedge clk or negedge STATUS_SLAVE_RSTN_SYNC) begin
    if(~STATUS_SLAVE_RSTN_SYNC) rd_addr <= 0;
    else if(STATUS_SLAVE_RD_ADDR_VALID && STATUS_SLAVE_RD_ADDR_READY) rd_addr <= STATUS_SLAVE_RD_ADDR;
    else if(STATUS_SLAVE_RD_DATA_VALID && STATUS_SLAVE_RD_DATA_READY) rd_addr <= rd_addr + 1;
    else rd_addr <= rd_addr;
end

// 读数据传输计数器
always @(posedge clk or negedge STATUS_SLAVE_RSTN_SYNC) begin
    if(~STATUS_SLAVE_RSTN_SYNC || (cu_rdchannel_st == ST_RD_IDLE)) rd_data_trans_num <= 0;
    else if(STATUS_SLAVE_RD_DATA_VALID && STATUS_SLAVE_RD_DATA_READY) rd_data_trans_num <= rd_data_trans_num + 1;
    else rd_data_trans_num <= rd_data_trans_num;
end

// 读通道控制信号生成
assign STATUS_SLAVE_RD_DATA_LAST = (STATUS_SLAVE_RD_DATA_VALID) && (rd_data_trans_num == rd_addr_len);

// 读错误检测逻辑
always @(*) begin
    if((~STATUS_SLAVE_RSTN_SYNC) || (cu_rdchannel_st == ST_RD_IDLE)) rd_transcript_error <= 0;
    else if((rd_addr_burst == 2'b10) || (rd_addr_burst == 2'b11)) rd_transcript_error <= 1;
    else if((rd_addr < ADDR_AXI_INIT) || (rd_addr > ADDR_OV_CAPTURE_ON)) rd_transcript_error <= 1;
    else if(rd_addr == ADDR_AXI_RESET || rd_addr == ADDR_POWER_RESET) rd_transcript_error <= 1;
    else rd_transcript_error <= 0;
end

// 读错误状态寄存
always @(posedge clk or negedge STATUS_SLAVE_RSTN_SYNC) begin
    if((~STATUS_SLAVE_RSTN_SYNC) || (cu_rdchannel_st == ST_RD_IDLE)) rd_transcript_error_reg <= 0;
    else rd_transcript_error_reg <= (rd_transcript_error)?(1):(rd_transcript_error_reg);
end

// 读数据VALID选通
always @(*) begin
    if(~STATUS_SLAVE_RSTN_SYNC) STATUS_SLAVE_RD_DATA_VALID <= 0;
    else if(cu_rdchannel_st == ST_RD_DATA) begin
        STATUS_SLAVE_RD_DATA_VALID <= 1; // 其他寄存器可以直接读取
    end else STATUS_SLAVE_RD_DATA_VALID <= 0;
end

// 读数据选通
always @(*) begin
    if(~STATUS_SLAVE_RSTN_SYNC) STATUS_SLAVE_RD_DATA <= 0;
    else if(cu_rdchannel_st == ST_RD_DATA) begin
        case(rd_addr)
            ADDR_AXI_INIT           : STATUS_SLAVE_RD_DATA <= {axi_master_rstn_status, axi_slave_rstn_status};
            ADDR_UID_2              : STATUS_SLAVE_RD_DATA <= uid_high;
            ADDR_UID_1              : STATUS_SLAVE_RD_DATA <= uid_low;
            ADDR_POWER_STATUS       : STATUS_SLAVE_RD_DATA <= {24'b0, power_status};
            ADDR_HOST_IP            : STATUS_SLAVE_RD_DATA <= host_ip_addr_reg;
            ADDR_HOST_MAC_2         : STATUS_SLAVE_RD_DATA <= {16'b0, host_mac_addr_reg[47:32]};
            ADDR_HOST_MAC_1         : STATUS_SLAVE_RD_DATA <= host_mac_addr_reg[31:0];
            ADDR_BOARD_IP           : STATUS_SLAVE_RD_DATA <= board_ip_addr_reg;
            ADDR_BOARD_MAC_2        : STATUS_SLAVE_RD_DATA <= {16'b0, board_mac_addr_reg[47:32]};
            ADDR_BOARD_MAC_1        : STATUS_SLAVE_RD_DATA <= board_mac_addr_reg[31:0];
            ADDR_DEFAULT_HOST_IP    : STATUS_SLAVE_RD_DATA <= default_host_ip_addr;
            ADDR_DEFAULT_HOST_MAC_2 : STATUS_SLAVE_RD_DATA <= {16'b0, default_host_mac_addr[47:32]};
            ADDR_DEFAULT_HOST_MAC_1 : STATUS_SLAVE_RD_DATA <= default_host_mac_addr[31:0];
            ADDR_DEFAULT_BOARD_IP   : STATUS_SLAVE_RD_DATA <= default_board_ip_addr;
            ADDR_DEFAULT_BOARD_MAC_2: STATUS_SLAVE_RD_DATA <= {16'b0, default_board_mac_addr[47:32]};
            ADDR_DEFAULT_BOARD_MAC_1: STATUS_SLAVE_RD_DATA <= default_board_mac_addr[31:0];
            ADDR_OV_STORE_BASE_ADDR : STATUS_SLAVE_RD_DATA <= OV_STORE_BASE_ADDR;
            ADDR_OV_STORE_NUM       : STATUS_SLAVE_RD_DATA <= OV_STORE_NUM;
            ADDR_OV_CAPTURE_ON      : STATUS_SLAVE_RD_DATA <= {31'b0, OV_capture_on};
            default: begin
                STATUS_SLAVE_RD_DATA <= 32'hFFFFFFFF;
            end
        endcase
    end else STATUS_SLAVE_RD_DATA <= 0;
end

assign host_ip_addr    = host_ip_addr_reg;
assign host_mac_addr   = host_mac_addr_reg;
assign board_ip_addr   = board_ip_addr_reg;
assign board_mac_addr  = board_mac_addr_reg;

endmodule //sys_status_axi_slave
