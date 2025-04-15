module sys_status_axi_slave#(
    parameter OFFSET_ADDR = 32'h3000_0000
)(
    input                clk,
    input                rstn,
    output logic         STATUS_SLAVE_CLK          ,
    output logic         STATUS_SLAVE_RSTN         ,
    input  logic [4-1:0] STATUS_SLAVE_WR_ADDR_ID   ,
    input  logic [31:0]  STATUS_SLAVE_WR_ADDR      ,
    input  logic [ 7:0]  STATUS_SLAVE_WR_ADDR_LEN  ,
    input  logic [ 1:0]  STATUS_SLAVE_WR_ADDR_BURST,
    input  logic         STATUS_SLAVE_WR_ADDR_VALID,
    output logic         STATUS_SLAVE_WR_ADDR_READY,
    input  logic [31:0]  STATUS_SLAVE_WR_DATA      ,
    input  logic [ 3:0]  STATUS_SLAVE_WR_STRB      ,
    input  logic         STATUS_SLAVE_WR_DATA_LAST ,
    input  logic         STATUS_SLAVE_WR_DATA_VALID,
    output logic         STATUS_SLAVE_WR_DATA_READY,
    output logic [4-1:0] STATUS_SLAVE_WR_BACK_ID   ,
    output logic [ 1:0]  STATUS_SLAVE_WR_BACK_RESP ,
    output logic         STATUS_SLAVE_WR_BACK_VALID,
    input  logic         STATUS_SLAVE_WR_BACK_READY,
    input  logic [4-1:0] STATUS_SLAVE_RD_ADDR_ID   ,
    input  logic [31:0]  STATUS_SLAVE_RD_ADDR      ,
    input  logic [ 7:0]  STATUS_SLAVE_RD_ADDR_LEN  ,
    input  logic [ 1:0]  STATUS_SLAVE_RD_ADDR_BURST,
    input  logic         STATUS_SLAVE_RD_ADDR_VALID,
    output logic         STATUS_SLAVE_RD_ADDR_READY,
    output logic [4-1:0] STATUS_SLAVE_RD_BACK_ID   ,
    output logic [31:0]  STATUS_SLAVE_RD_DATA      ,
    output logic [ 1:0]  STATUS_SLAVE_RD_DATA_RESP ,
    output logic         STATUS_SLAVE_RD_DATA_LAST ,
    output logic         STATUS_SLAVE_RD_DATA_VALID,
    input  logic         STATUS_SLAVE_RD_DATA_READY
);//系统状态AXI从机，用于读取和配置CTRL_FPGA系统的各项基本参数，如AXI总线复位情况，LAB_FPGA的上电、复位，UID，EEPROM，MAC地址，IP地址等等
wire STATUS_SLAVE_RSTN_SYNC;
assign STATUS_SLAVE_CLK = clk;
assign STATUS_SLAVE_RSTN = STATUS_SLAVE_RSTN_SYNC;
rstn_sync status_rstn_sync(clk,rstn,STATUS_SLAVE_RSTN_SYNC);
/* 地址规定
32'h0000_0000:  只读    AXI总线主从机复位情况，[31:16]为16-1号主机，[15:0]为16-1号从机，1为复位结束，0为正在复位
32'h0000_0001:  只写    AXI总线主从机手动复位，[31:16]为16-1号主机，[15:0]为16-1号从机，1为重新复位，0为不影响。复位后自动置零
32'h0000_0002:  只读    见下
32'h0000_0003:  只读    见下
32'h0000_0004:  只读    CTRL_FPGA的UID，格式为{0x02,0x03,0x04}={UID}。UID是唯一器件标识符
32'h0000_0005:  读写    [7]位标志LAB_FPGA的上电情况，0为断电状态，1为上电状态。其余位保留
32'h0000_0006:  只写    [7]位，置1使LAB_FPGA重新上电（复位）。复位后自动置零

32'h0000_0007:  读写    见下
32'h0000_0008:  读写    当前CTRL_FPGA的以太网MAC地址，格式为{0x07,0x08}={16'b0,MAC}。
                        上电后的默认以太网MAC配置优先级顺序为：EEPROM配置 > 取UID低48位 > 12-34-56-78-AB-CD
                        上位机可以通过写地址07,08来动态重分配MAC地址，但下次复位后仍会以EEPROM中存放的MAC地址配置
                        如想永久更改MAC地址，建议写EEPROM+写地址07,08执行两次
                        MAC地址的更改会在AXI总线和UDP完全空闲后执行，因此写响应数据包仍是原MAC配置。

32'h0000_0009:  读写    见下
32'h0000_000A:  读写    上位机的MAC地址，格式为{0x09,0x0A}={16'b0,MAC}。
                        注意事项同上

32'h0000_0009:  读写    当前CTRL_FPGA的以太网IP地址。上电后的默认以太网IP地址配置优先级顺序为：EEPROM配置 > 取UID低32位 > 169.254.109.5
                        上位机可以通过写地址09来动态重分配IP地址，但下次复位后仍会以EEPROM中存放的IP地址配置
                        如想永久更改IP地址，建议写EEPROM+写地址07,08执行两次
                        IP地址的更改会在AXI总线和UDP完全空闲后执行，因此写响应数据包仍是原IP配置。

32'h0000_000A:  读写    上位机的IP地址。上电后的默认以太网IP地址配置优先级顺序为：EEPROM配置 > 取UID低32位 > 169.254.109.5
                        注意事项同上

32'h0000_000B - 32'h0000_000F 保留，不可读不可写
32'h0000_0010:  读写    板载EEPROM的起始地址。小眼睛的PG2L100H BASE板板载AT24C02C-SSHM-T芯片，2048bit，即256个8bit，即64个32bit（草，好少）
32'h0000_004F:  读写    板载EEPROM的结束地址。（依EEPROM的大小可变，小眼睛的是这么大）
*/

localparam ADDR_AXI_INIT            = 32'h0000_0000,
           ADDR_AXI_RESET           = 32'h0000_0001,
           ADDR_UID_3               = 32'h0000_0002,
           ADDR_UID_2               = 32'h0000_0003,
           ADDR_UID_1               = 32'h0000_0004,
           ADDR_LAB_FPGA_START      = 32'h0000_0005,
           ADDR_LAB_FPGA_RESET      = 32'h0000_0006,
           ADDR_CTRL_FPGA_MAC_2     = 32'h0000_0007,
           ADDR_CTRL_FPGA_MAC_1     = 32'h0000_0008,
           ADDR_LAB_FPGA_START      = 32'h0000_0009,
           ADDR_LAB_FPGA_START      = 32'h0000_0003;

reg  [31:0] STATUS_STATE_REG_WR;
reg  [31:0] STATUS_STATE_REG_READ;

//_________________写___通___道_________________//
reg [ 3:0] wr_addr_id;
reg [31:0] wr_addr;
reg [ 3:0] wr_addr_burst;
reg        wr_transcript_error, wr_transcript_error_reg;
//JTAG作为SLAVE不接收WR_ADDR_LEN，其DATA线的结束以WR_DATA_LAST为参考。
reg [ 1:0] cu_wrchannel_st, nt_wrchannel_st;
localparam ST_WR_IDLE = 2'b00, //写通道空闲
           ST_WR_DATA = 2'b01, //地址线握手成功，数据线通道开启
           ST_WR_RESP = 2'b10; //写响应

//_________________读___通___道_________________//
reg [ 3:0] rd_addr_id;
reg [31:0] rd_addr;
reg [ 7:0] rd_addr_len;
reg [ 3:0] rd_addr_burst;
reg [ 7:0] rd_data_trans_num;
reg        rd_transcript_error, rd_transcript_error_reg;
reg [ 1:0] cu_rdchannel_st, nt_rdchannel_st;
localparam ST_RD_IDLE = 2'b00, //发送完LAST和RESP，读通道空闲
           ST_RD_DATA = 2'b01; //地址线握手成功，数据线通道开启

//_______________________________________________________________________________//
always @(*) begin
    case (cu_wrchannel_st)
        ST_WR_IDLE: nt_wrchannel_st <= (STATUS_SLAVE_WR_ADDR_VALID && STATUS_SLAVE_WR_ADDR_READY)?(ST_WR_DATA):(ST_WR_IDLE);
        ST_WR_DATA: nt_wrchannel_st <= (STATUS_SLAVE_WR_DATA_VALID && STATUS_SLAVE_WR_DATA_READY && STATUS_SLAVE_WR_DATA_LAST)?(ST_WR_RESP):(ST_WR_DATA);
        ST_WR_RESP: nt_wrchannel_st <= (STATUS_SLAVE_WR_BACK_VALID && STATUS_SLAVE_WR_BACK_READY)?(ST_WR_IDLE):(ST_WR_RESP);
        default   : nt_wrchannel_st <= ST_WR_IDLE;
    endcase
end
always @(posedge clk or negedge status_rstn_sync) begin
    if(~status_rstn_sync) cu_wrchannel_st <= ST_WR_IDLE;
    else cu_wrchannel_st <= nt_wrchannel_st;
end
assign STATUS_SLAVE_WR_ADDR_READY = (status_rstn_sync) && (cu_wrchannel_st == ST_WR_IDLE);
assign STATUS_SLAVE_WR_BACK_VALID = (status_rstn_sync) && (cu_wrchannel_st == ST_WR_RESP);
assign STATUS_SLAVE_WR_BACK_RESP  = ((status_rstn_sync) && ((~wr_transcript_error) && (~wr_transcript_error_reg)))?(2'b00):(2'b10);
assign STATUS_SLAVE_WR_BACK_ID    = wr_addr_id;
always @(posedge clk or negedge status_rstn_sync) begin
    if(~status_rstn_sync) begin
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
always @(posedge clk or negedge status_rstn_sync) begin
    if(~status_rstn_sync) wr_addr <= 0;
    else if(STATUS_SLAVE_WR_ADDR_VALID && STATUS_SLAVE_WR_ADDR_READY) wr_addr <= STATUS_SLAVE_WR_ADDR - OFFSET_ADDR;
    else if((wr_addr_burst == 2'b01) && STATUS_SLAVE_WR_DATA_VALID && STATUS_SLAVE_WR_DATA_READY) wr_addr <= wr_addr + 1;
    else wr_addr <= wr_addr;
end
always @(*) begin
    if((~status_rstn_sync) || (cu_wrchannel_st == ST_WR_IDLE) || (cu_wrchannel_st == ST_WR_RESP)) wr_transcript_error <= 0;
    else if((wr_addr_burst == 2'b10) || (wr_addr_burst == 2'b11)) wr_transcript_error <= 1;
    else if((wr_addr < STATUS_STATE_ADDR) || (wr_addr > STATUS_SHIFT_CMD_ADDR)) wr_transcript_error <= 1;
    else if(wr_addr == STATUS_SHIFT_OUT_ADDR) wr_transcript_error <= 1;
    else wr_transcript_error <= 0;
end
always @(posedge clk or negedge status_rstn_sync) begin
    if((~status_rstn_sync) || (cu_wrchannel_st == ST_WR_IDLE)) wr_transcript_error_reg <= 0;
    else wr_transcript_error_reg <= (wr_transcript_error)?(1):(wr_transcript_error_reg);
end

//_______________________________________________________________________________//
always @(*) begin
    case (cu_rdchannel_st)
        ST_RD_IDLE: nt_rdchannel_st <= (STATUS_SLAVE_RD_ADDR_VALID && STATUS_SLAVE_RD_ADDR_READY)?(ST_RD_DATA):(ST_RD_IDLE);
        ST_RD_DATA: nt_rdchannel_st <= (STATUS_SLAVE_RD_DATA_VALID && STATUS_SLAVE_RD_DATA_READY && STATUS_SLAVE_RD_DATA_LAST)?(ST_RD_IDLE):(ST_RD_DATA);
        default   : nt_rdchannel_st <= ST_RD_IDLE;
    endcase
end
always @(posedge clk or negedge status_rstn_sync)begin
    if(~status_rstn_sync) cu_rdchannel_st <= ST_RD_IDLE;
    else cu_rdchannel_st <= nt_rdchannel_st;
end
assign STATUS_SLAVE_RD_ADDR_READY = (status_rstn_sync) && (cu_rdchannel_st == ST_RD_IDLE);
always @(posedge clk or negedge status_rstn_sync) begin
    if(~status_rstn_sync) begin
        rd_addr_id    <= 0;
        rd_addr_burst <= 0;
        rd_addr_len   <= 0;
    end else if(STATUS_SLAVE_RD_ADDR_VALID && STATUS_SLAVE_RD_ADDR_READY) begin
        rd_addr_id    <= STATUS_SLAVE_RD_ADDR_ID;
        rd_addr_burst <= STATUS_SLAVE_RD_ADDR_BURST;
        rd_addr_len   <= STATUS_SLAVE_RD_ADDR_LEN;
    end else begin
        rd_addr_id    <= rd_addr_id;
        rd_addr_burst <= rd_addr_burst;
        rd_addr_len   <= rd_addr_len;
    end
end
always @(posedge clk or negedge status_rstn_sync) begin
    if(~status_rstn_sync) rd_addr <= 0;
    else if(STATUS_SLAVE_RD_ADDR_VALID && STATUS_SLAVE_RD_ADDR_READY) rd_addr <= STATUS_SLAVE_RD_ADDR - OFFSET_ADDR;
    else if(STATUS_SLAVE_RD_DATA_VALID && STATUS_SLAVE_RD_DATA_READY) rd_addr <= rd_addr + 1;
    else rd_addr <= rd_addr;
end
always @(posedge clk or negedge status_rstn_sync) begin
    if(~status_rstn_sync || (cu_rdchannel_st == ST_RD_IDLE)) rd_data_trans_num <= 0;
    else if(STATUS_SLAVE_RD_DATA_VALID && STATUS_SLAVE_RD_DATA_READY) rd_data_trans_num <= rd_data_trans_num + 1;
    else rd_data_trans_num <= rd_data_trans_num;
end
assign STATUS_SLAVE_RD_DATA_LAST = (STATUS_SLAVE_RD_DATA_VALID) && (rd_data_trans_num == rd_addr_len);
assign STATUS_SLAVE_RD_BACK_ID = rd_addr_id;
assign STATUS_SLAVE_RD_DATA_RESP  = ((status_rstn_sync) && ((~rd_transcript_error) && (~rd_transcript_error_reg)))?(2'b00):(2'b10);

always @(*) begin
    //写数据READY选通
    if(~status_rstn_sync) STATUS_SLAVE_WR_DATA_READY <= 0;
    else if(cu_wrchannel_st == ST_WR_DATA) begin
             if(wr_addr == STATUS_STATE_ADDR    ) STATUS_SLAVE_WR_DATA_READY <= 1; //状态寄存器可立即写
        else if(wr_addr == STATUS_SHIFT_IN_ADDR ) STATUS_SLAVE_WR_DATA_READY <= (~fifo_shift_data_full); //写FIFO未满可写
        else if(wr_addr == STATUS_SHIFT_CMD_ADDR) STATUS_SLAVE_WR_DATA_READY <= (~fifo_shift_cmd_full); //写FIFO未满可写
        else STATUS_SLAVE_WR_DATA_READY <= 1; //ERROR，直接跳过不写
    end else STATUS_SLAVE_WR_DATA_READY <= 0;
    //读数据VALID选通
    if(~status_rstn_sync) STATUS_SLAVE_RD_DATA_VALID <= 0;
    else if(cu_rdchannel_st == ST_RD_DATA) begin
             if(rd_addr == STATUS_STATE_ADDR    ) STATUS_SLAVE_RD_DATA_VALID <= 1; //状态寄存器可立即读   
        else if(rd_addr == STATUS_SHIFT_OUT_ADDR) STATUS_SLAVE_RD_DATA_VALID <= (fifo_shift_out_out_valid); //读FIFO数据有效可读
        else STATUS_SLAVE_RD_DATA_VALID <= 1; //ERROR，直接跳过默认为全1
    end else STATUS_SLAVE_RD_DATA_VALID <= 0;
    //读数据DATA选通
    if(~status_rstn_sync) STATUS_SLAVE_RD_DATA <= 0;
    else if(cu_rdchannel_st == ST_RD_DATA) begin
             if(rd_addr == STATUS_STATE_ADDR    ) STATUS_SLAVE_RD_DATA <= STATUS_STATE_REG_READ; //状态寄存器可立即读  
        else if(rd_addr == STATUS_SHIFT_OUT_ADDR) STATUS_SLAVE_RD_DATA <= fifo_shift_out_rd_data; //读FIFO数据有效可读
        else STATUS_SLAVE_RD_DATA <= 32'hFFFFFFFF;
    end else STATUS_SLAVE_RD_DATA <= 0;
end

always @(*) begin
    if((~status_rstn_sync) || (cu_rdchannel_st == ST_RD_IDLE)) rd_transcript_error <= 0;
    else if((rd_addr_burst == 2'b10) || (rd_addr_burst == 2'b11)) rd_transcript_error <= 1;
    else if((rd_addr < STATUS_STATE_ADDR) || (rd_addr > STATUS_SHIFT_OUT_ADDR)) rd_transcript_error <= 1;
    else rd_transcript_error <= 0;
end
always @(posedge clk or negedge status_rstn_sync) begin
    if((~status_rstn_sync) || (cu_rdchannel_st == ST_RD_IDLE)) rd_transcript_error_reg <= 0;
    else rd_transcript_error_reg <= (rd_transcript_error)?(1):(rd_transcript_error_reg);
end

//_______32'h10000000_______//
always @(*) begin
    STATUS_STATE_REG_READ[0]    = STATUS_STATE_REG_WR[0];
    STATUS_STATE_REG_READ[1]    = fifo_shift_out_empty;
    STATUS_STATE_REG_READ[2]    = fifo_shift_out_full;
    STATUS_STATE_REG_READ[7:3]  = 0;

    STATUS_STATE_REG_READ[8]    = STATUS_STATE_REG_WR[8];
    STATUS_STATE_REG_READ[9]    = fifo_shift_data_empty;
    STATUS_STATE_REG_READ[10]   = fifo_shift_data_full;
    STATUS_STATE_REG_READ[15:11]= 0;

    STATUS_STATE_REG_READ[16]   = STATUS_STATE_REG_WR[16];
    STATUS_STATE_REG_READ[17]   = fifo_shift_cmd_empty;
    STATUS_STATE_REG_READ[18]   = fifo_shift_cmd_full;
    STATUS_STATE_REG_READ[23:19]= 0;
    STATUS_STATE_REG_READ[24]   = cmd_done;
    STATUS_STATE_REG_READ[31:25]= 0;
end
always @(posedge clk or negedge status_rstn_sync) begin
    if(~status_rstn_sync) STATUS_STATE_REG_WR <= 0;
    else if(STATUS_SLAVE_WR_DATA_VALID && STATUS_SLAVE_WR_DATA_READY && (wr_addr == STATUS_STATE_ADDR))begin
        STATUS_STATE_REG_WR[07:00] <= (STATUS_SLAVE_WR_STRB[0])?(STATUS_SLAVE_WR_DATA[07:00]):(STATUS_STATE_REG_WR[07:00]);
        STATUS_STATE_REG_WR[15:08] <= (STATUS_SLAVE_WR_STRB[1])?(STATUS_SLAVE_WR_DATA[15:08]):(STATUS_STATE_REG_WR[15:08]);
        STATUS_STATE_REG_WR[23:16] <= (STATUS_SLAVE_WR_STRB[2])?(STATUS_SLAVE_WR_DATA[23:16]):(STATUS_STATE_REG_WR[23:16]);
        STATUS_STATE_REG_WR[31:24] <= (STATUS_SLAVE_WR_STRB[3])?(STATUS_SLAVE_WR_DATA[31:24]):(STATUS_STATE_REG_WR[31:24]);
    end else begin
        STATUS_STATE_REG_WR[0]  <= 0; //自动置0
        STATUS_STATE_REG_WR[8]  <= 0; //自动置0
        STATUS_STATE_REG_WR[16] <= 0; //自动置0
    end
end

endmodule //sys_status_axi_slave
