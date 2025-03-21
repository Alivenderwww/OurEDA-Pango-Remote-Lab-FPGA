module axi_interconnect #(
    parameter S0_START_ADDR = 32'h00_00_00_00,
    parameter S0_END_ADDR   = 32'h0F_FF_FF_FF,
    parameter S1_START_ADDR = 32'h10_00_00_00,
    parameter S1_END_ADDR   = 32'h10_00_00_0F
)(
    input wire BUS_CLK,
    input wire BUS_RST,

    //MASTER 0 以太网主机                    MASTER 1 主机                             MASTER 2 主机                        MASTER 3 主机
    input  wire [31:0] M0_WR_ADDR      ,    input  wire [31:0] M1_WR_ADDR      ,    input  wire [31:0] M2_WR_ADDR      ,    input  wire [31:0] M3_WR_ADDR      ,
    input  wire [ 7:0] M0_WR_LEN       ,    input  wire [ 7:0] M1_WR_LEN       ,    input  wire [ 7:0] M2_WR_LEN       ,    input  wire [ 7:0] M3_WR_LEN       ,
    input  wire [ 1:0] M0_WR_ID        ,    input  wire [ 1:0] M1_WR_ID        ,    input  wire [ 1:0] M2_WR_ID        ,    input  wire [ 1:0] M3_WR_ID        ,
    input  wire        M0_WR_ADDR_VALID,    input  wire        M1_WR_ADDR_VALID,    input  wire        M2_WR_ADDR_VALID,    input  wire        M3_WR_ADDR_VALID,
    output wire        M0_WR_ADDR_READY,    output wire        M1_WR_ADDR_READY,    output wire        M2_WR_ADDR_READY,    output wire        M3_WR_ADDR_READY,
      
    input  wire [31:0] M0_WR_DATA      ,    input  wire [31:0] M1_WR_DATA      ,    input  wire [31:0] M2_WR_DATA      ,    input  wire [31:0] M3_WR_DATA      ,
    input  wire [ 3:0] M0_WR_STRB      ,    input  wire [ 3:0] M1_WR_STRB      ,    input  wire [ 3:0] M2_WR_STRB      ,    input  wire [ 3:0] M3_WR_STRB      ,
    output wire [ 1:0] M0_WR_BACK_ID   ,    output wire [ 1:0] M1_WR_BACK_ID   ,    output wire [ 1:0] M2_WR_BACK_ID   ,    output wire [ 1:0] M3_WR_BACK_ID   ,
    input  wire        M0_WR_DATA_VALID,    input  wire        M1_WR_DATA_VALID,    input  wire        M2_WR_DATA_VALID,    input  wire        M3_WR_DATA_VALID,
    output wire        M0_WR_DATA_READY,    output wire        M1_WR_DATA_READY,    output wire        M2_WR_DATA_READY,    output wire        M3_WR_DATA_READY,
    input  wire        M0_WR_DATA_LAST ,    input  wire        M1_WR_DATA_LAST ,    input  wire        M2_WR_DATA_LAST ,    input  wire        M3_WR_DATA_LAST ,
      
    input  wire [31:0] M0_RD_ADDR      ,    input  wire [31:0] M1_RD_ADDR      ,    input  wire [31:0] M2_RD_ADDR      ,    input  wire [31:0] M3_RD_ADDR      ,
    input  wire [ 7:0] M0_RD_LEN       ,    input  wire [ 7:0] M1_RD_LEN       ,    input  wire [ 7:0] M2_RD_LEN       ,    input  wire [ 7:0] M3_RD_LEN       ,
    input  wire [ 1:0] M0_RD_ID        ,    input  wire [ 1:0] M1_RD_ID        ,    input  wire [ 1:0] M2_RD_ID        ,    input  wire [ 1:0] M3_RD_ID        ,
    input  wire        M0_RD_ADDR_VALID,    input  wire        M1_RD_ADDR_VALID,    input  wire        M2_RD_ADDR_VALID,    input  wire        M3_RD_ADDR_VALID,
    output wire        M0_RD_ADDR_READY,    output wire        M1_RD_ADDR_READY,    output wire        M2_RD_ADDR_READY,    output wire        M3_RD_ADDR_READY,
      
    output wire [31:0] M0_RD_DATA      ,    output wire [31:0] M1_RD_DATA      ,    output wire [31:0] M2_RD_DATA      ,    output wire [31:0] M3_RD_DATA      ,
    output wire        M0_RD_DATA_LAST ,    output wire        M1_RD_DATA_LAST ,    output wire        M2_RD_DATA_LAST ,    output wire        M3_RD_DATA_LAST ,
    output wire [ 1:0] M0_RD_BACK_ID   ,    output wire [ 1:0] M1_RD_BACK_ID   ,    output wire [ 1:0] M2_RD_BACK_ID   ,    output wire [ 1:0] M3_RD_BACK_ID   ,
    input  wire        M0_RD_DATA_READY,    input  wire        M1_RD_DATA_READY,    input  wire        M2_RD_DATA_READY,    input  wire        M3_RD_DATA_READY,
    output wire        M0_RD_DATA_VALID,    output wire        M1_RD_DATA_VALID,    output wire        M2_RD_DATA_VALID,    output wire        M3_RD_DATA_VALID,

    //SLAVE 0 DDR从机                       //SLAVE 1 JTAG从机
    output wire [27:0] S0_WR_ADDR      ,    output wire [ 3:0] S1_WR_ADDR      ,
    output wire [ 7:0] S0_WR_LEN       ,    output wire [ 7:0] S1_WR_LEN       ,
    output wire [ 3:0] S0_WR_ID        ,    output wire [ 3:0] S1_WR_ID        ,
    output wire        S0_WR_ADDR_VALID,    output wire        S1_WR_ADDR_VALID,
    input  wire        S0_WR_ADDR_READY,    input  wire        S1_WR_ADDR_READY,

    output wire [31:0] S0_WR_DATA      ,    output wire [31:0] S1_WR_DATA      ,
    output wire [ 3:0] S0_WR_STRB      ,    output wire [ 3:0] S1_WR_STRB      ,
    input  wire [ 3:0] S0_WR_BACK_ID   ,    input  wire [ 3:0] S1_WR_BACK_ID   ,
    output wire        S0_WR_DATA_VALID,    output wire        S1_WR_DATA_VALID,
    input  wire        S0_WR_DATA_READY,    input  wire        S1_WR_DATA_READY,
    output wire        S0_WR_DATA_LAST ,    output wire        S1_WR_DATA_LAST ,

    output wire [27:0] S0_RD_ADDR      ,    output wire [ 3:0] S1_RD_ADDR      ,
    output wire [ 7:0] S0_RD_LEN       ,    output wire [ 7:0] S1_RD_LEN       ,
    output wire [ 3:0] S0_RD_ID        ,    output wire [ 3:0] S1_RD_ID        ,
    output wire        S0_RD_ADDR_VALID,    output wire        S1_RD_ADDR_VALID,
    input  wire        S0_RD_ADDR_READY,    input  wire        S1_RD_ADDR_READY,

    input  wire [31:0] S0_RD_DATA      ,    input  wire [31:0] S1_RD_DATA      ,
    input  wire        S0_RD_DATA_LAST ,    input  wire        S1_RD_DATA_LAST ,
    input  wire [ 3:0] S0_RD_BACK_ID   ,    input  wire [ 3:0] S1_RD_BACK_ID   ,
    output wire        S0_RD_DATA_READY,    output wire        S1_RD_DATA_READY,
    input  wire        S0_RD_DATA_VALID,    input  wire        S1_RD_DATA_VALID
);

/**
想要多主机-多从机通信，ID号不能缺失
但是先想这么一个问题：系统到底要多少个主机？
AXI协议只能做到主机到从机通信，即主机向从机申请数据传输，从机是被动的。

以太网接收上位机的数据传输命令，所以它是一个主机
但是以太网还需要主动上传数据。
比如视频流数据，一种方法是以太网主动向上位机发送视频流，而不用上位机每次申请一定范围的地址数据。
比如逻辑分析仪Trigger触发，需要以太网主动上报给上位机通知其逻辑分析仪被触发。

在这个层面上来说，以太网还需要做成从机。也就是说以太网模块要做成"主机 / 从机兼容类型"。
以太网是从机，就得为以太网从机分配地址和数据结构。
而且里面就得有个主机。

先不考虑这么多。总之，目前来说，必须考虑ID号。
事先约定好地址分配，从而判断主机->从机通路。
主机ID号是2位。axi_interconnect根据主机个数将其拓展为4位ID。即最多四个主机。
从机ID号是4位。axi_interconnect根据从机高两位ID判断从机->主机通路，并连接对应信号。

有了ID线，interconnect可以单独处理四个通道，四个通道完全独立。
写/读地址通道：VALID拉高后，读取主机传输地址，确定从机，建立传输通道。主机把地址和控制线发给从机，一次传输结束。在建立传输后不允许改变主从机。
写/读数据通道：VALID拉高后，读取从机返回ID，确定主机，建立传输通道。主机或从机把数据发给另一方，一次传输结束。在建立传输后不允许改变主从机。
**/

reg [27:0] BUS_WR_ADDR      ;
reg [ 7:0] BUS_WR_LEN       ;
reg [ 1:0] BUS_WR_ID        ;
reg        BUS_WR_ADDR_VALID;
reg        BUS_WR_ADDR_READY;
reg [ 1:0] cu_master_wr_addr_id, nt_master_wr_addr_id;
reg [ 1:0] cu_master_rd_addr_id, nt_master_rd_addr_id;
reg [ 1:0] cu_master_wr_data_id, nt_master_wr_data_id;
reg [ 1:0] cu_master_rd_data_id, nt_master_rd_data_id;

//主机-写地址通道接口
always @(*) begin
    if((BUS_WR_ADDR_VALID == 0)||(BUS_WR_ADDR_VALID == 1 && BUS_WR_ADDR_READY == 1))begin //下一时刻可以更改主从机选通
             if(M0_WR_ADDR_VALID) nt_master_wr_addr_id <= 2'd0;
        else if(M1_WR_ADDR_VALID) nt_master_wr_addr_id <= 2'd1;
        else if(M2_WR_ADDR_VALID) nt_master_wr_addr_id <= 2'd2;
        else if(M3_WR_ADDR_VALID) nt_master_wr_addr_id <= 2'd3;
        else                      nt_master_wr_addr_id <= 2'd0;
    end else                      nt_master_wr_addr_id <= cu_master_wr_addr_id;//传输尚未结束，不允许更改主从机选通
end
always @(posedge clk) begin
    if(BUS_RST) cu_master_wr_addr_id <= 2'd0;
    else cu_master_wr_addr_id <= nt_master_wr_addr_id;
end
always @(*) begin
    case (cu_master_wr_addr_id)
        2'd0: begin
            BUS_WR_ADDR       <= M0_WR_ADDR      ;
            BUS_WR_LEN        <= M0_WR_LEN       ;
            BUS_WR_ID         <= M0_WR_ID        ;
            BUS_WR_ADDR_VALID <= M0_WR_ADDR_VALID;
        end
        2'd1: begin
            BUS_WR_ADDR       <= M1_WR_ADDR      ;
            BUS_WR_LEN        <= M1_WR_LEN       ;
            BUS_WR_ID         <= M1_WR_ID        ;
            BUS_WR_ADDR_VALID <= M1_WR_ADDR_VALID;
        end
        2'd2: begin
            BUS_WR_ADDR       <= M2_WR_ADDR      ;
            BUS_WR_LEN        <= M2_WR_LEN       ;
            BUS_WR_ID         <= M2_WR_ID        ;
            BUS_WR_ADDR_VALID <= M2_WR_ADDR_VALID;
        end
        2'd3: begin
            BUS_WR_ADDR       <= M3_WR_ADDR      ;
            BUS_WR_LEN        <= M3_WR_LEN       ;
            BUS_WR_ID         <= M3_WR_ID        ;
            BUS_WR_ADDR_VALID <= M3_WR_ADDR_VALID;
        end
    endcase
end

//主机-读地址通道接口
always @(*) begin
    if((BUS_RD_ADDR_VALID == 0)||(BUS_RD_ADDR_VALID == 1 && BUS_RD_ADDR_READY == 1))begin //下一时刻可以更改主从机选通
             if(M0_RD_ADDR_VALID) nt_master_rd_addr_id <= 2'd0;
        else if(M1_RD_ADDR_VALID) nt_master_rd_addr_id <= 2'd1;
        else if(M2_RD_ADDR_VALID) nt_master_rd_addr_id <= 2'd2;
        else if(M3_RD_ADDR_VALID) nt_master_rd_addr_id <= 2'd3;
        else                      nt_master_rd_addr_id <= 2'd0;
    end else                      nt_master_rd_addr_id <= cu_master_rd_addr_id;//传输尚未结束，不允许更改主从机选通
end
always @(posedge clk) begin
    if(BUS_RST) cu_master_rd_addr_id <= 2'd0;
    else cu_master_rd_addr_id <= nt_master_rd_addr_id;
end
always @(*) begin
    case (cu_master_rd_addr_id)
        2'd0: begin
            BUS_RD_ADDR       <= M0_RD_ADDR      ;
            BUS_RD_LEN        <= M0_RD_LEN       ;
            BUS_RD_ID         <= M0_RD_ID        ;
            BUS_RD_ADDR_VALID <= M0_RD_ADDR_VALID;
        end
        2'd1: begin
            BUS_RD_ADDR       <= M1_RD_ADDR      ;
            BUS_RD_LEN        <= M1_RD_LEN       ;
            BUS_RD_ID         <= M1_RD_ID        ;
            BUS_RD_ADDR_VALID <= M1_RD_ADDR_VALID;
        end
        2'd2: begin
            BUS_RD_ADDR       <= M2_RD_ADDR      ;
            BUS_RD_LEN        <= M2_RD_LEN       ;
            BUS_RD_ID         <= M2_RD_ID        ;
            BUS_RD_ADDR_VALID <= M2_RD_ADDR_VALID;
        end
        2'd3: begin
            BUS_RD_ADDR       <= M3_RD_ADDR      ;
            BUS_RD_LEN        <= M3_RD_LEN       ;
            BUS_RD_ID         <= M3_RD_ID        ;
            BUS_RD_ADDR_VALID <= M3_RD_ADDR_VALID;
        end
    endcase
end

//从机-写地址通道接口
always @(*) begin
    if(BUS_WR_ADDR >= S0_START_ADDR && BUS_WR_ADDR <= S0_END_ADDR) begin
        BUS_WR_ADDR_READY <= S0_WR_ADDR_READY;
        S0_WR_ADDR_VALID  <= BUS_WR_ADDR_VALID;
    end else if(BUS_WR_ADDR >= S1_START_ADDR && BUS_WR_ADDR <= S1_END_ADDR) begin
        BUS_WR_ADDR_READY <= S1_WR_ADDR_READY;
        S1_WR_ADDR_VALID  <= BUS_WR_ADDR_VALID;
    end else begin
        BUS_WR_ADDR_READY <= S1_WR_ADDR_READY;
        S1_WR_ADDR_VALID  <= BUS_WR_ADDR_VALID;
    end
end


endmodule