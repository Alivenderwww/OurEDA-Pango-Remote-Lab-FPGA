module data_ctrl_slave #(
parameter OFFSET_ADDR           = 32'h3000_0000     ,
parameter FPGA_VESION           = 48'h2000_0101_1200,   // year,month,day,hour,minute;
parameter USER_BITSTREAM_CNT    = 2'd3              ,
parameter USER_BITSTREAM1_ADDR  = 24'h20_b000       ,   // user bitstream1 start address  ---> [6*4KB+2068KB(2065),32MB- 2068KB(2065)],4KB align  // 24'h20_b000
parameter USER_BITSTREAM2_ADDR  = 24'h41_0000       ,   // user bitstream2 start address  ---> 24'h41_0000 
parameter USER_BITSTREAM3_ADDR  = 24'h61_5000           // user bitstream3 start address  ---> 24'h61_5000
)(
input  wire        clk                     ,
input  wire        rst_n                   ,

//写入比特流-控制接口1
output  reg [1:0]  bitstream_wr_num        ,
output  reg        flash_wr_en             ,
//写入比特流-控制接口2
input  wire        clear_bs_done           ,
input  wire        bitstream_wr_done       ,
//写入比特流-数据接口
output wire        bitstream_fifo_rd_rdy   ,
input  wire        bitstream_fifo_rd_req   ,
output wire        bitstream_valid         ,
output wire [7:0]  bitstream_data          ,
output wire        bitstream_eop           ,

//读出比特流-控制接口1
output wire [1:0]  bitstream_rd_num        ,
output wire        flash_rd_en             ,
//读出比特流-控制接口2
input  wire        bitstream_rd_done       ,
input  wire        bs_readback_crc_valid   ,
input  wire [31:0] bs_readback_crc         ,
//读出比特流-控制接口3
output wire        crc_check_en        ,
output wire [1:0]  bs_crc32_ok             ,//[1]:valid   [0]:1'b0,OK  1'b1,error
//读出比特流-回读接口
output wire        bitstream_up2cpu_en ,
output wire        flash_rd_data_fifo_afull,
input  wire [7:0]  flash_rd_data           ,
input  wire        flash_rd_valid          ,

//单独擦除开关接口
output wire        clear_sw_en         ,
input  wire        clear_sw_done           ,

//写开关接口
output wire        write_sw_code_en        ,
input  wire        open_sw_code_done       ,

//热启动接口
output wire        hotreset_en             ,
output wire [1:0]  open_sw_num         ,

//未知用途
output wire        spi_status_rd_en        ,
input  wire [7:0]  spi_status_erorr        ,
input  wire        ipal_busy               ,
input  wire        time_out_reg            ,

//弃用
input  wire [15:0] flash_flag_status       ,
output wire        flash_cfg_cmd_en        ,
output wire [7:0]  flash_cfg_cmd           ,
output wire [15:0] flash_cfg_reg_wrdata    ,
input  wire        flash_cfg_reg_rd_en     ,
input  wire [15:0] flash_cfg_reg_rddata    ,

output wire        SLAVE_CLK               , //向AXI总线提供的本主机时钟信号
output wire        SLAVE_RSTN              , //向AXI总线提供的本主机复位信号
input  wire [ 3:0] SLAVE_WR_ADDR_ID        , //写地址通道-ID
input  wire [31:0] SLAVE_WR_ADDR           , //写地址通道-地址
input  wire [ 7:0] SLAVE_WR_ADDR_LEN       , //写地址通道-突发长度-最小为0（1突发），最大为255（256突发）
input  wire [ 1:0] SLAVE_WR_ADDR_BURST     , //写地址通道-突发类型
input  wire        SLAVE_WR_ADDR_VALID     , //写地址通道-握手信号-有效
output reg         SLAVE_WR_ADDR_READY     , //写地址通道-握手信号-准备
input  wire [31:0] SLAVE_WR_DATA           , //写数据通道-数据
input  wire [ 3:0] SLAVE_WR_STRB           , //写数据通道-选通
input  wire        SLAVE_WR_DATA_LAST      , //写数据通道-last信号
input  wire        SLAVE_WR_DATA_VALID     , //写数据通道-握手信号-有效
output reg         SLAVE_WR_DATA_READY     , //写数据通道-握手信号-准备
output reg  [ 3:0] SLAVE_WR_BACK_ID        , //写响应通道-ID
output reg  [ 1:0] SLAVE_WR_BACK_RESP      , //写响应通道-响应 //SLAVE_WR_DATA_LAST拉高的同时或者之后 00 01正常 10写错误 11地址有问题找不到从机
output reg         SLAVE_WR_BACK_VALID     , //写响应通道-握手信号-有效
input  wire        SLAVE_WR_BACK_READY     , //写响应通道-握手信号-准备
input  wire [ 3:0] SLAVE_RD_ADDR_ID        , //读地址通道-ID
input  wire [31:0] SLAVE_RD_ADDR           , //读地址通道-地址
input  wire [ 7:0] SLAVE_RD_ADDR_LEN       , //读地址通道-突发长度。最小为0（1突发），最大为255（256突发）
input  wire [ 1:0] SLAVE_RD_ADDR_BURST     , //读地址通道-突发类型。
input  wire        SLAVE_RD_ADDR_VALID     , //读地址通道-握手信号-有效
output reg         SLAVE_RD_ADDR_READY     , //读地址通道-握手信号-准备
output reg  [ 3:0] SLAVE_RD_BACK_ID        , //读数据通道-ID
output reg  [31:0] SLAVE_RD_DATA           , //读数据通道-数据
output reg  [ 1:0] SLAVE_RD_DATA_RESP      , //读数据通道-响应
output reg         SLAVE_RD_DATA_LAST      , //读数据通道-last信号
output reg         SLAVE_RD_DATA_VALID     , //读数据通道-握手信号-有效
input  wire        SLAVE_RD_DATA_READY       //读数据通道-握手信号-准备
);

//读/写FLASH芯片配置寄存器及状态指示信号
assign flash_cfg_cmd_en     = 0;
assign flash_cfg_cmd        = 0;
assign flash_cfg_reg_wrdata = 0;

/*
OFFSET_ADDR + 0: 写比特流-读写地址——控制位
[31:24]: 保留
[23:17]: 保留
[16: 8]: 保留
[ 7: 0]: {-, -, -, -, -,{bitstream_wr_num}, flash_wr_en}

OFFSET_ADDR + 1: 写比特流-只写地址——FIFO入口
[31:0]:  写比特流数据入口

OFFSET_ADDR + 2: 写比特流-只读地址——标志位
[31:24]: 保留
[23:17]: 保留
[16: 8]: {-, -, -, -, -, -, -, bitstream_wr_done}
[ 7: 0]: {-, -, -, -, -, -, -,     clear_bs_done}

OFFSET_ADDR + 3: 读比特流-读写地址——控制位
[31:24]: {-, -, -, -, -, -,{   bs_crc32_ok           }}
[23:17]: {-, -, -, -, -, -, -,            crc_check_en}
[16: 8]: {-, -, -, -, -, -, -,     bitstream_up2cpu_en}
[ 7: 0]: {-, -, -, -, -,{bitstream_rd_num},flash_rd_en}

OFFSET_ADDR + 4: 读比特流-只读地址——FIFO出口
[31:0]: 读比特流数据出口

OFFSET_ADDR + 5: 读比特流-只读地址——CRC校验值
[31:0]: CRC校验值 bs_readback_crc

OFFSET_ADDR + 6: 读比特流-只读地址——标志位
[31:24]: {-, -, -, -, -, -, -,          -           }
[23:17]: {-, -, -, -, -, -, -,          -           }
[16: 8]: {-, -, -, -, -, -, -,     bitstream_rd_done}
[ 7: 0]: {-, -, -, -, -, -, -, bs_readback_crc_valid}

OFFSET_ADDR + 7: 单独擦除开关-读写地址——控制位
[31:24]: {-, -, -, -, -, -, -,       -    }
[23:17]: {-, -, -, -, -, -, -,       -    }
[16: 8]: {-, -, -, -, -, -, -,       -    }
[ 7: 0]: {-, -, -, -, -, -, -, clear_sw_en}

OFFSET_ADDR + 8: 单独擦除开关-只读地址——标志位
[31:24]: {-, -, -, -, -, -, -,       -      }
[23:17]: {-, -, -, -, -, -, -,       -      }
[16: 8]: {-, -, -, -, -, -, -,       -      }
[ 7: 0]: {-, -, -, -, -, -, -, clear_sw_done}

OFFSET_ADDR + 9: 写开关-读写地址——标志位
[31:24]: {-, -, -, -, -, -, -,       -         }
[23:17]: {-, -, -, -, -, -, -,       -         }
[16: 8]: {-, -, -, -, -, -, {      open_sw_num}}
[ 7: 0]: {-, -, -, -, -, -, -, write_sw_code_en}

OFFSET_ADDR + A: 写开关-只读地址——控制位
[31:24]: {-, -, -, -, -, -, -,       -          }
[23:17]: {-, -, -, -, -, -, -,       -          }
[16: 8]: {-, -, -, -, -, -, -,       -          }
[ 7: 0]: {-, -, -, -, -, -, -, open_sw_code_done}

OFFSET_ADDR + B: 热启动开关-读写地址——控制位
[31:24]: {-, -, -, -, -, -, -,       -       }
[23:17]: {-, -, -, -, -, -, -,       -       }
[16: 8]: {-, -, -, -, -, -,                  }
[ 7: 0]: {-, -, -, -, -, -, -,    hotreset_en}
*/

localparam BASE_RU_WRBIT_RW_CTRL_ADDR = 32'h0000_0000; localparam REAL_RU_WRBIT_RW_CTRL_ADDR = OFFSET_ADDR + BASE_RU_WRBIT_RW_CTRL_ADDR;
localparam BASE_RU_WRBIT_WO_FIFO_ADDR = 32'h0000_0001; localparam REAL_RU_WRBIT_WO_FIFO_ADDR = OFFSET_ADDR + BASE_RU_WRBIT_WO_FIFO_ADDR;
localparam BASE_RU_WRBIT_RO_FLAG_ADDR = 32'h0000_0002; localparam REAL_RU_WRBIT_RO_FLAG_ADDR = OFFSET_ADDR + BASE_RU_WRBIT_RO_FLAG_ADDR;
  
localparam BASE_RU_RDBIT_RW_CTRL_ADDR = 32'h0000_0003; localparam REAL_RU_RDBIT_RW_CTRL_ADDR = OFFSET_ADDR + BASE_RU_RDBIT_RW_CTRL_ADDR;
localparam BASE_RU_RDBIT_RO_FIFO_ADDR = 32'h0000_0004; localparam REAL_RU_RDBIT_RO_FIFO_ADDR = OFFSET_ADDR + BASE_RU_RDBIT_RO_FIFO_ADDR;
localparam BASE_RU_RDBIT_RO__CRC_ADDR = 32'h0000_0005; localparam REAL_RU_RDBIT_RO__CRC_ADDR = OFFSET_ADDR + BASE_RU_RDBIT_RO__CRC_ADDR;
localparam BASE_RU_RDBIT_RO_FLAG_ADDR = 32'h0000_0006; localparam REAL_RU_RDBIT_RO_FLAG_ADDR = OFFSET_ADDR + BASE_RU_RDBIT_RO_FLAG_ADDR;
  
localparam BASE_RU_CLEAR_RW_CTRL_ADDR = 32'h0000_0007; localparam REAL_RU_CLEAR_RW_CTRL_ADDR = OFFSET_ADDR + BASE_RU_CLEAR_RW_CTRL_ADDR;
localparam BASE_RU_CLEAR_RO_FLAG_ADDR = 32'h0000_0008; localparam REAL_RU_CLEAR_RO_FLAG_ADDR = OFFSET_ADDR + BASE_RU_CLEAR_RO_FLAG_ADDR;
  
localparam BASE_RU_SWTCH_RW_CTRL_ADDR = 32'h0000_0009; localparam REAL_RU_SWTCH_RW_CTRL_ADDR = OFFSET_ADDR + BASE_RU_SWTCH_RW_CTRL_ADDR;
localparam BASE_RU_SWTCH_RO_FLAG_ADDR = 32'h0000_000A; localparam REAL_RU_SWTCH_RO_FLAG_ADDR = OFFSET_ADDR + BASE_RU_SWTCH_RO_FLAG_ADDR;
  
localparam BASE_RU_HOTRS_RW_CTRL_ADDR = 32'h0000_000B; localparam REAL_RU_HOTRS_RW_CTRL_ADDR = OFFSET_ADDR + BASE_RU_HOTRS_RW_CTRL_ADDR;


assign SLAVE_CLK = clk;
assign SLAVE_RSTN = rstn;

reg  [ 3:0] wr_addr_id;   
reg  [31:0] wr_addr;
reg  [ 1:0] wr_addr_burst;
reg         wr_error_detect;
reg  [ 1:0] cu_wr_st, nt_wr_st;
localparam ST_WR_IDLE = 2'b01,
           ST_WR_DATA = 2'b10,
           ST_WR_RESP = 2'b11;

reg  [ 3:0] rd_addr_id;   
reg  [31:0] rd_addr;
reg  [ 7:0] rd_addr_len;
reg  [ 1:0] rd_addr_burst;
reg         rd_error_detect, rd_error_detect_reg;
reg  [ 7:0] trans_num;
reg         cu_rd_st, nt_rd_st;
localparam ST_RD_IDLE = 1'b0,
           ST_RD_DATA = 1'b1;

wire        wr_fifo_rst;
wire        wr_fifo_wr_en;
wire [31:0] wr_fifo_wr_data;
wire        wr_fifo_rd_en;
wire [ 7:0] wr_fifo_rd_data;
reg         wr_fifo_rd_data_valid;
wire        wr_fifo_full;
wire        wr_fifo_empty;
wire [31:0] wr_fifo_bytes_num;
reg  [31:0] wr_fifo_trans_cnt;

wire        rd_fifo_rst;
wire        rd_fifo_wr_en;
wire [ 7:0] rd_fifo_wr_data;
wire        rd_fifo_rd_en;
wire [31:0] rd_fifo_rd_data;
reg         rd_fifo_rd_data_valid;
wire        rd_fifo_afull;
wire        rd_fifo_empty;

//___________________写通道___________________//

always @(*) begin
    if(~rstn) nt_wr_st <= ST_WR_IDLE;
    else case (cu_wr_st)
        ST_WR_IDLE: nt_wr_st <= (SLAVE_WR_ADDR_READY && SLAVE_WR_ADDR_VALID)?(ST_WR_DATA):(ST_WR_IDLE);
        ST_WR_DATA: nt_wr_st <= (SLAVE_WR_DATA_READY && SLAVE_WR_DATA_VALID && SLAVE_WR_DATA_LAST)?(ST_WR_RESP):(ST_WR_DATA);
        ST_WR_RESP: nt_wr_st <= (SLAVE_WR_BACK_READY && SLAVE_WR_BACK_VALID)?(ST_WR_IDLE):(ST_WR_RESP);
        default:    nt_wr_st <= ST_WR_IDLE;
    endcase
end
always @(posedge clk) cu_wr_st <= nt_wr_st;

always @(posedge clk) begin
    if(~rstn) begin
        wr_addr_id <= 0;
        wr_addr_burst <= 0;
    end else if(SLAVE_WR_ADDR_READY && SLAVE_WR_ADDR_VALID)begin
        wr_addr_id <= SLAVE_WR_ADDR_ID;
        wr_addr_burst <= SLAVE_WR_ADDR_BURST;
    end else begin
        wr_addr_id <= wr_addr_id;
        wr_addr_burst <= wr_addr_burst;
    end
end

always @(posedge clk) begin
    if(~rstn) wr_addr <= 0;
    else if(SLAVE_WR_ADDR_READY && SLAVE_WR_ADDR_VALID) wr_addr <= SLAVE_WR_ADDR;
    else if((cu_wr_st == ST_WR_DATA) && SLAVE_WR_DATA_READY && SLAVE_WR_DATA_VALID && (wr_addr_burst == 2'b01)) wr_addr <= wr_addr + 1;
    else wr_addr <= wr_addr;
end

always @(posedge clk) begin
    if((~rstn) || (cu_wr_st == ST_WR_IDLE)) wr_error_detect <= 0;
    else if(cu_wr_st == ST_WR_DATA)begin
        if((wr_addr_burst == 2'b10) || (wr_addr_burst == 2'b11)) wr_error_detect <= 1;
        else if((wr_addr < REAL_RU_WRBIT_RW_CTRL_ADDR) || (wr_addr > REAL_RU_HOTRS_RW_CTRL_ADDR)) wr_error_detect <= 1;
    end else wr_error_detect <= wr_error_detect;
end

assign SLAVE_WR_ADDR_READY = (cu_wr_st == ST_WR_IDLE);
assign SLAVE_WR_BACK_ID    = wr_addr_id;
assign SLAVE_WR_BACK_RESP  = (wr_error_detect)?(2'b10):(2'b00);
assign SLAVE_WR_BACK_VALID = (cu_wr_st == ST_WR_RESP);

//___________________读通道___________________//

// always @(posedge clk) begin
//     if(~rstn) led <= 0;
//     else if(SLAVE_WR_DATA_READY && SLAVE_WR_DATA_VALID && (wr_addr == REAL_ADDR))begin
//         led <= SLAVE_WR_DATA;
//         $display("%m: at time %0t INFO: remote update slave recv write data %h", $time, SLAVE_WR_DATA);
//     end else led <= led;
// end

always @(*) begin
    if(~rstn) nt_rd_st <= ST_RD_IDLE;
    else case (cu_rd_st)
        ST_RD_IDLE: nt_rd_st <= (SLAVE_RD_ADDR_READY && SLAVE_RD_ADDR_VALID)?(ST_RD_DATA):(ST_RD_IDLE);
        ST_RD_DATA: nt_rd_st <= (SLAVE_RD_DATA_READY && SLAVE_RD_DATA_VALID && SLAVE_RD_DATA_LAST)?(ST_RD_IDLE):(ST_RD_DATA);
    endcase
end
always @(posedge clk) cu_rd_st <= nt_rd_st;

always @(posedge clk) begin
    if(~rstn) begin
        rd_addr_id <= 0;
        rd_addr_burst <= 0;
        rd_addr_len <= 0;
    end else if(SLAVE_RD_ADDR_READY && SLAVE_RD_ADDR_VALID)begin
        rd_addr_id <= SLAVE_RD_ADDR_ID;
        rd_addr_burst <= SLAVE_RD_ADDR_BURST;
        rd_addr_len <= SLAVE_RD_ADDR_LEN;
    end else begin
        rd_addr_id <= rd_addr_id;
        rd_addr_burst <= rd_addr_burst;
        rd_addr_len <= rd_addr_len;
    end
end

always @(posedge clk) begin
    if(~rstn) rd_addr <= 0;
    else if(SLAVE_RD_ADDR_READY && SLAVE_RD_ADDR_VALID) rd_addr <= SLAVE_RD_ADDR;
    else if((cu_rd_st == ST_RD_DATA) && SLAVE_RD_DATA_READY && SLAVE_RD_DATA_VALID && (rd_addr_burst == 2'b01)) rd_addr <= rd_addr + 1;
    else rd_addr <= rd_addr;
end

always @(posedge clk) begin
    if((~rstn) || (cu_rd_st == ST_RD_IDLE)) trans_num <= 0;
    else if(SLAVE_RD_DATA_READY && SLAVE_RD_DATA_VALID) trans_num <= trans_num + 1;
    else trans_num <= trans_num;
end

always @(*) begin
    if((~rstn) || (cu_rd_st == ST_RD_IDLE)) rd_error_detect <= 0;
    else if(cu_rd_st == ST_RD_DATA)begin
        if((rd_addr < REAL_RU_WRBIT_RW_CTRL_ADDR) || (rd_addr > REAL_RU_HOTRS_RW_CTRL_ADDR)) rd_error_detect <= 1;
        else if(rd_addr != REAL_ADDR) rd_error_detect <= 1;
    end else rd_error_detect <= 0;
end
always @(posedge clk) rd_error_detect_reg <= rd_error_detect;

assign SLAVE_RD_ADDR_READY = (cu_rd_st == ST_RD_IDLE);
assign SLAVE_RD_BACK_ID    = rd_addr_id;
assign SLAVE_RD_DATA_RESP  = (rd_error_detect || rd_error_detect_reg)?(2'b10):(2'b00);
assign SLAVE_RD_DATA_LAST  = (SLAVE_RD_DATA_VALID && (trans_num == rd_addr_len));

//写通道的READY信号
always @(*) begin
    if(~rstn || (cu_wr_st == ST_WR_IDLE) || (cu_wr_st == ST_WR_RESP)) SLAVE_WR_DATA_READY <= 0;
    else if(cu_wr_st == ST_WR_DATA)begin
        case (wr_addr)
            REAL_RU_WRBIT_WO_FIFO_ADDR: SLAVE_WR_DATA_READY <= (~wr_fifo_full);
            default                   : SLAVE_WR_DATA_READY <= 1;
        endcase
    end else SLAVE_WR_DATA_READY <= 0;
end

//读通道的VALID信号
always @(*) begin
    if(~rstn || (cu_rd_st == ST_WR_IDLE)) SLAVE_RD_DATA_VALID <= 0;
    else if(cu_rd_st == ST_RD_DATA)begin
        case (rd_addr)
            REAL_RU_RDBIT_RO_FIFO_ADDR: SLAVE_RD_DATA_VALID <= (rd_fifo_rd_data_valid);
            default                   : SLAVE_RD_DATA_VALID <= 1;
        endcase
    end else SLAVE_RD_DATA_VALID <= 0;
end

//读通道的DATA选通
always @(*) begin
    if(~rstn || (cu_rd_st == ST_WR_IDLE)) SLAVE_RD_DATA <= 0;
    else if(cu_rd_st == ST_RD_DATA)begin
        case (rd_addr)
            REAL_RU_WRBIT_RW_CTRL_ADDR: SLAVE_RD_DATA <= {{8'b0}            ,{8'b0}                 ,{8'b0}                         ,{5'b0, bitstream_wr_num, flash_wr_en}  };
            REAL_RU_WRBIT_WO_FIFO_ADDR: SLAVE_RD_DATA <= 32'hFFFF_FFFF;
            REAL_RU_WRBIT_RO_FLAG_ADDR: SLAVE_RD_DATA <= {{8'b0}            ,{8'b0}                 ,{7'b0,bitstream_wr_done}       ,{7'b0, clear_bs_done}                  };
            REAL_RU_RDBIT_RW_CTRL_ADDR: SLAVE_RD_DATA <= {{6'b0,bs_crc32_ok},{7'b0,crc_check_en},{7'b0,bitstream_up2cpu_en} ,{5'b0, bitstream_rd_num, flash_rd_en}  };
            REAL_RU_RDBIT_RO_FIFO_ADDR: SLAVE_RD_DATA <= rd_fifo_rd_data;
            REAL_RU_RDBIT_RO__CRC_ADDR: SLAVE_RD_DATA <= bs_readback_crc;
            REAL_RU_RDBIT_RO_FLAG_ADDR: SLAVE_RD_DATA <= {{8'b0}            ,{8'b0}                 ,{6'b0,bitstream_rd_done}       ,{7'b0, bs_readback_crc_valid}          };
            REAL_RU_CLEAR_RW_CTRL_ADDR: SLAVE_RD_DATA <= {{8'b0}            ,{8'b0}                 ,{8'b0}                         ,{7'b0, clear_sw_en}                };
            REAL_RU_CLEAR_RO_FLAG_ADDR: SLAVE_RD_DATA <= {{8'b0}            ,{8'b0}                 ,{8'b0}                         ,{7'b0, clear_sw_done}                  };
            REAL_RU_SWTCH_RW_CTRL_ADDR: SLAVE_RD_DATA <= {{8'b0}            ,{8'b0}                 ,{6'b0,open_sw_num}             ,{7'b0, write_sw_code_en}               };
            REAL_RU_SWTCH_RO_FLAG_ADDR: SLAVE_RD_DATA <= {{8'b0}            ,{8'b0}                 ,{8'b0}                         ,{7'b0, open_sw_code_done}              };
            REAL_RU_HOTRS_RW_CTRL_ADDR: SLAVE_RD_DATA <= {{8'b0}            ,{8'b0}                 ,{8'b0}                         ,{7'b0, hotreset_en}                    };
            default                   : SLAVE_RD_DATA <= 32'hFFFF_FFFF;
        endcase
    end else SLAVE_RD_DATA <= 32'hFFFF_FFFF;
end

assign wr_fifo_rst     = (~rstn);
assign wr_fifo_wr_en   = (cu_wr_st == ST_WR_DATA) && (wr_addr == REAL_RU_WRBIT_WO_FIFO_ADDR) && (SLAVE_WR_DATA_VALID) && (SLAVE_WR_DATA_READY);
assign wr_fifo_wr_data = SLAVE_WR_DATA;
assign wr_fifo_rd_en   = (~wr_fifo_empty) && ((~wr_fifo_rd_data_valid) || (bitstream_valid));
always @(posedge clk) begin
    if(~rstn) wr_fifo_rd_data_valid <= 0;
    else if((~wr_fifo_rd_data_valid) && (~wr_fifo_empty) && (wr_fifo_rd_en)) wr_fifo_rd_data_valid <= 1;
    else if((wr_fifo_rd_data_valid) && (wr_fifo_empty) && (bitstream_valid)) wr_fifo_rd_data_valid <= 0;
    else wr_fifo_rd_data_valid <= wr_fifo_rd_data_valid;
end

assign rd_fifo_rst     = (~rstn);
assign rd_fifo_wr_en   = flash_rd_valid;
assign rd_fifo_wr_data = flash_rd_data;
assign rd_fifo_rd_en   = (~rd_fifo_empty) && ((~rd_fifo_rd_data_valid) || ((cu_rd_st == ST_RD_DATA) && (rd_addr == REAL_RU_RDBIT_RO_FIFO_ADDR) && (SLAVE_RD_DATA_VALID) && (SLAVE_RD_DATA_READY)));
always @(posedge clk) begin
    if(~rstn) rd_fifo_rd_data_valid <= 0;
    else if((~rd_fifo_rd_data_valid) && (~rd_fifo_empty) && (rd_fifo_rd_en)) rd_fifo_rd_data_valid <= 1;
    else if((rd_fifo_rd_data_valid) && (rd_fifo_empty) && ((cu_rd_st == ST_RD_DATA) && (rd_addr == REAL_RU_RDBIT_RO_FIFO_ADDR) && (SLAVE_RD_DATA_VALID) && (SLAVE_RD_DATA_READY)))
        rd_fifo_rd_data_valid <= 0;
    else rd_fifo_rd_data_valid <= rd_fifo_rd_data_valid;
end


reg cu_wr_fifo_st, nt_wr_fifo_st;
localparam ST_WR_FIFO_IDLE  = 1'b00;
localparam ST_WR_FIFO_TRANS = 1'b00;
always @(*) begin
    if(~rstn) nt_wr_fifo_st <= ST_WR_FIFO_IDLE;
    else case(cu_wr_fifo_st)
        ST_WR_FIFO_IDLE : nt_wr_fifo_st <= (wr_fifo_bytes_num >= 255)?(ST_WR_FIFO_TRANS):(ST_WR_FIFO_IDLE); //因为会事先读出来一个
        ST_WR_FIFO_TRANS: nt_wr_fifo_st <= (bitstream_eop)?(ST_WR_FIFO_IDLE):(ST_WR_FIFO_TRANS);
    endcase
end
always @(posedge clk) cu_wr_fifo_st <= nt_wr_fifo_st;

always @(posedge clk) begin
    if(~rstn) wr_fifo_trans_cnt <= 0;
    else if(cu_wr_fifo_st == ST_WR_FIFO_TRANS) begin
        if(bitstream_valid) wr_fifo_trans_cnt <= wr_fifo_trans_cnt + 1;
        else wr_fifo_trans_cnt <= wr_fifo_trans_cnt;
    end else wr_fifo_trans_cnt <= 0;
end
assign bitstream_fifo_rd_rdy = (cu_wr_fifo_st == ST_WR_FIFO_TRANS);
assign bitstream_valid = bitstream_fifo_rd_req;
assign bitstream_data = wr_fifo_rd_data;
assign bitstream_eop = (wr_fifo_trans_cnt >= 255);
assign flash_rd_data_fifo_afull = rd_fifo_afull;

remote_update_wr_fifo remote_update_wr_fifo_inst(
    .clk           (clk),
    .rst           (wr_fifo_rst),
    .wr_en         (wr_fifo_wr_en),
    .wr_data       (wr_fifo_wr_data),
    .rd_en         (wr_fifo_rd_en),
    .rd_data       (wr_fifo_rd_data),

    .full          (wr_fifo_full),
    .empty         (wr_fifo_empty),
    .rd_water_level(wr_fifo_bytes_num)
);

remote_update_rd_fifo remote_update_rd_fifo_inst(
    .clk           (clk),
    .rst           (rd_fifo_rst),
    .wr_en         (rd_fifo_wr_en),
    .wr_data       (rd_fifo_wr_data),
    .rd_en         (rd_fifo_rd_en),
    .rd_data       (rd_fifo_rd_data),

    .empty         (rd_fifo_empty),
    .almost_full   (rd_fifo_afull) //set n-256 bytes almost full
);

///__________输出信号___________///
always @(posedge clk) begin
    if(~rstn) {bitstream_wr_num, flash_wr_en} <= 0;
    else if(SLAVE_WR_DATA_VALID && SLAVE_WR_DATA_READY && wr_addr == REAL_RU_WRBIT_RW_CTRL_ADDR)
        {bitstream_wr_num, flash_wr_en} <= (wr_addr_burst[0])?(SLAVE_WR_DATA[2:0]):({bitstream_wr_num, flash_wr_en});
    else {bitstream_wr_num, flash_wr_en} <= {bitstream_wr_num, 1'b0};
end
always @(posedge clk) begin
    if(~rstn)begin
        bs_crc32_ok                      <= 0;
        crc_check_en                     <= 0;
        bitstream_up2cpu_en              <= 0;
        {{bitstream_rd_num},flash_rd_en} <= 0;
    end else if(SLAVE_WR_DATA_VALID && SLAVE_WR_DATA_READY && wr_addr == REAL_RU_RDBIT_RW_CTRL_ADDR)begin
        bs_crc32_ok                      <= (wr_addr_burst[3])?(SLAVE_WR_DATA[25:24]):(bs_crc32_ok                     );
        crc_check_en                     <= (wr_addr_burst[2])?(SLAVE_WR_DATA[17]   ):(crc_check_en                    );
        bitstream_up2cpu_en              <= (wr_addr_burst[1])?(SLAVE_WR_DATA[8]    ):(bitstream_up2cpu_en             );
        {{bitstream_rd_num},flash_rd_en} <= (wr_addr_burst[0])?(SLAVE_WR_DATA[ 2: 0]):({{bitstream_rd_num},flash_rd_en});
    end else begin
        bs_crc32_ok                      <= bs_crc32_ok                     ;
        crc_check_en                     <= crc_check_en                    ;
        bitstream_up2cpu_en              <= bitstream_up2cpu_en             ;
        {{bitstream_rd_num},flash_rd_en} <= {{bitstream_rd_num},1'b0};//自动置0
    end
end
always @(posedge clk) begin
    if(~rstn) clear_sw_en <= 0;
    else if(SLAVE_WR_DATA_VALID && SLAVE_WR_DATA_READY && wr_addr == REAL_RU_CLEAR_RW_CTRL_ADDR)
        clear_sw_en <= (wr_addr_burst[0])?(SLAVE_WR_DATA[0]):(clear_sw_en);
    else begin
        clear_sw_en <= 0;//自动置0
    end
end
always @(posedge clk) begin
    if(~rstn)begin
        open_sw_num      <= 0;
        write_sw_code_en <= 0;
    end else if(SLAVE_WR_DATA_VALID && SLAVE_WR_DATA_READY && wr_addr == REAL_RU_SWTCH_RW_CTRL_ADDR)begin
        open_sw_num      <= (wr_addr_burst[1])?(SLAVE_WR_DATA[9:8]):(open_sw_num);
        write_sw_code_en <= (wr_addr_burst[0])?(SLAVE_WR_DATA[0]  ):(write_sw_code_en);
    end else begin
        open_sw_num      <= open_sw_num;
        write_sw_code_en <= 0;
    end
end
always @(posedge clk) begin
    if(~rstn) hotreset_en <= 0;
    else if(SLAVE_WR_DATA_VALID && SLAVE_WR_DATA_READY && wr_addr == REAL_RU_HOTRS_RW_CTRL_ADDR)
        hotreset_en <= (wr_addr_burst[0])?(SLAVE_WR_DATA[0]):(hotreset_en);
    else begin
        hotreset_en <= 0;//自动置0
    end
end


endmodule