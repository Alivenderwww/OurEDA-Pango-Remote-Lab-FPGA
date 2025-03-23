module axi_interconnect #(
    parameter S0_START_ADDR = 32'h00_00_00_00,
    parameter S0_END_ADDR   = 32'h0F_FF_FF_FF,
    parameter S1_START_ADDR = 32'h10_00_00_00,
    parameter S1_END_ADDR   = 32'h1F_FF_FF_0F,
    parameter S2_START_ADDR = 32'h20_00_00_00,
    parameter S2_END_ADDR   = 32'h2F_FF_FF_0F,
    parameter S3_START_ADDR = 32'h30_00_00_00,
    parameter S3_END_ADDR   = 32'h3F_FF_FF_0F
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

    //SLAVE 0 DDR从机                       //SLAVE 1 JTAG从机                      //SLAVE 2 从机                          //SLAVE 3 从机
    output wire [31:0] S0_WR_ADDR      ,    output wire [31:0] S1_WR_ADDR      ,    output wire [31:0] S2_WR_ADDR      ,    output wire [31:0] S3_WR_ADDR      ,
    output wire [ 7:0] S0_WR_LEN       ,    output wire [ 7:0] S1_WR_LEN       ,    output wire [ 7:0] S2_WR_LEN       ,    output wire [ 7:0] S3_WR_LEN       ,
    output wire [ 3:0] S0_WR_ID        ,    output wire [ 3:0] S1_WR_ID        ,    output wire [ 3:0] S2_WR_ID        ,    output wire [ 3:0] S3_WR_ID        ,
    output wire        S0_WR_ADDR_VALID,    output wire        S1_WR_ADDR_VALID,    output wire        S2_WR_ADDR_VALID,    output wire        S3_WR_ADDR_VALID,
    input  wire        S0_WR_ADDR_READY,    input  wire        S1_WR_ADDR_READY,    input  wire        S2_WR_ADDR_READY,    input  wire        S3_WR_ADDR_READY,

    output wire [31:0] S0_WR_DATA      ,    output wire [31:0] S1_WR_DATA      ,    output wire [31:0] S2_WR_DATA      ,    output wire [31:0] S3_WR_DATA      ,
    output wire [ 3:0] S0_WR_STRB      ,    output wire [ 3:0] S1_WR_STRB      ,    output wire [ 3:0] S2_WR_STRB      ,    output wire [ 3:0] S3_WR_STRB      ,
    input  wire [ 3:0] S0_WR_BACK_ID   ,    input  wire [ 3:0] S1_WR_BACK_ID   ,    input  wire [ 3:0] S2_WR_BACK_ID   ,    input  wire [ 3:0] S3_WR_BACK_ID   ,
    output wire        S0_WR_DATA_VALID,    output wire        S1_WR_DATA_VALID,    output wire        S2_WR_DATA_VALID,    output wire        S3_WR_DATA_VALID,
    input  wire        S0_WR_DATA_READY,    input  wire        S1_WR_DATA_READY,    input  wire        S2_WR_DATA_READY,    input  wire        S3_WR_DATA_READY,
    output wire        S0_WR_DATA_LAST ,    output wire        S1_WR_DATA_LAST ,    output wire        S2_WR_DATA_LAST ,    output wire        S3_WR_DATA_LAST ,

    output wire [27:0] S0_RD_ADDR      ,    output wire [ 3:0] S1_RD_ADDR      ,    output wire [27:0] S2_RD_ADDR      ,    output wire [ 3:0] S3_RD_ADDR      ,
    output wire [ 7:0] S0_RD_LEN       ,    output wire [ 7:0] S1_RD_LEN       ,    output wire [ 7:0] S2_RD_LEN       ,    output wire [ 7:0] S3_RD_LEN       ,
    output wire [ 3:0] S0_RD_ID        ,    output wire [ 3:0] S1_RD_ID        ,    output wire [ 3:0] S2_RD_ID        ,    output wire [ 3:0] S3_RD_ID        ,
    output wire        S0_RD_ADDR_VALID,    output wire        S1_RD_ADDR_VALID,    output wire        S2_RD_ADDR_VALID,    output wire        S3_RD_ADDR_VALID,
    input  wire        S0_RD_ADDR_READY,    input  wire        S1_RD_ADDR_READY,    input  wire        S2_RD_ADDR_READY,    input  wire        S3_RD_ADDR_READY,

    input  wire [31:0] S0_RD_DATA      ,    input  wire [31:0] S1_RD_DATA      ,    input  wire [31:0] S2_RD_DATA      ,    input  wire [31:0] S3_RD_DATA      ,
    input  wire        S0_RD_DATA_LAST ,    input  wire        S1_RD_DATA_LAST ,    input  wire        S2_RD_DATA_LAST ,    input  wire        S3_RD_DATA_LAST ,
    input  wire [ 3:0] S0_RD_BACK_ID   ,    input  wire [ 3:0] S1_RD_BACK_ID   ,    input  wire [ 3:0] S2_RD_BACK_ID   ,    input  wire [ 3:0] S3_RD_BACK_ID   ,
    output wire        S0_RD_DATA_READY,    output wire        S1_RD_DATA_READY,    output wire        S2_RD_DATA_READY,    output wire        S3_RD_DATA_READY,
    input  wire        S0_RD_DATA_VALID,    input  wire        S1_RD_DATA_VALID,    input  wire        S2_RD_DATA_VALID,    input  wire        S3_RD_DATA_VALID
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

//__________________________________________//
wire [27:0] BUS_WR_ADDR      ;
wire [ 7:0] BUS_WR_LEN       ;
wire [ 1:0] BUS_WR_ID        ;
wire        BUS_WR_ADDR_VALID;
wire        BUS_WR_ADDR_READY;
wire [27:0] BUS_RD_ADDR      ;
wire [ 7:0] BUS_RD_LEN       ;
wire [ 1:0] BUS_RD_ID        ;
wire        BUS_RD_ADDR_VALID;
wire        BUS_RD_ADDR_READY;
wire [31:0] BUS_WR_DATA      ;
wire [ 3:0] BUS_WR_STRB      ;
wire [ 3:0] BUS_WR_BACK_ID   ;
wire        BUS_WR_DATA_VALID;
wire        BUS_WR_DATA_READY;
wire        BUS_WR_DATA_LAST ;
wire [31:0] BUS_RD_DATA      ;
wire        BUS_RD_DATA_LAST ;
wire [ 1:0] BUS_RD_BACK_ID   ;
wire        BUS_RD_DATA_READY;
wire        BUS_RD_DATA_VALID;

reg        wr_addr_lock     ;
reg        rd_addr_lock     ;
reg        wr_data_lock     ;
reg        rd_data_lock     ;

reg [ 1:0] cu_master_wr_addr_id, nt_master_wr_addr_id;
reg [ 1:0] cu_master_rd_addr_id, nt_master_rd_addr_id;
reg [ 1:0] master_wr_data_id;
reg [ 1:0] master_rd_data_id;

reg [ 1:0] slave_wr_addr_sel;
reg [ 1:0] slave_rd_addr_sel;
reg [ 1:0] cu_slave_wr_data_sel, nt_slave_wr_data_sel;
reg [ 1:0] cu_slave_rd_data_sel, nt_slave_rd_data_sel;

/**************************写地址通道接口**********************/
always @(posedge BUS_CLK) begin
    if(BUS_RST) wr_addr_lock <= 0;
    else if((BUS_WR_ADDR_VALID && BUS_WR_ADDR_READY)) wr_addr_lock <= 0; //握手成功，传输通道解锁
    else if(BUS_WR_ADDR_VALID) wr_addr_lock <= 1; //握手未成功，传输通道加锁
    else  wr_addr_lock <= wr_addr_lock;
end
always @(*) begin
    if(~wr_addr_lock)begin
             if(M0_WR_ADDR_VALID) nt_master_wr_addr_id <= 2'd0;
        else if(M1_WR_ADDR_VALID) nt_master_wr_addr_id <= 2'd1;
        else if(M2_WR_ADDR_VALID) nt_master_wr_addr_id <= 2'd2;
        else if(M3_WR_ADDR_VALID) nt_master_wr_addr_id <= 2'd3;
        else                      nt_master_wr_addr_id <= 2'd0;
    end else                      nt_master_wr_addr_id <= cu_master_wr_addr_id;
end
always @(posedge BUS_CLK) begin
    if(BUS_RST) cu_master_wr_addr_id <= 2'd0;
    else cu_master_wr_addr_id <= nt_master_wr_addr_id;
end
always @(*) begin
         if(BUS_WR_ADDR >= S0_START_ADDR && BUS_WR_ADDR <= S0_END_ADDR) slave_wr_addr_sel <= 2'd0;
    else if(BUS_WR_ADDR >= S1_START_ADDR && BUS_WR_ADDR <= S1_END_ADDR) slave_wr_addr_sel <= 2'd1;
    else if(BUS_WR_ADDR >= S2_START_ADDR && BUS_WR_ADDR <= S2_END_ADDR) slave_wr_addr_sel <= 2'd2;
    else if(BUS_WR_ADDR >= S3_START_ADDR && BUS_WR_ADDR <= S3_END_ADDR) slave_wr_addr_sel <= 2'd3;
    else slave_wr_addr_sel <= 2'd0;
end

axi_inter_sel41 #(32)selM_WR_ADDR      ( cu_master_wr_addr_id, BUS_WR_ADDR      , M0_WR_ADDR      , M1_WR_ADDR      , M2_WR_ADDR      , M3_WR_ADDR      );
axi_inter_nosel #( 4)selS_WR_ADDR      (                       BUS_WR_ADDR      , S0_WR_ADDR      , S1_WR_ADDR      , S2_WR_ADDR      , S3_WR_ADDR      );
axi_inter_sel41 #( 8)selM_WR_LEN       ( cu_master_wr_addr_id, BUS_WR_LEN       , M0_WR_LEN       , M1_WR_LEN       , M2_WR_LEN       , M3_WR_LEN       );
axi_inter_nosel #( 8)selS_WR_LEN       (                       BUS_WR_LEN       , S0_WR_LEN       , S1_WR_LEN       , S2_WR_LEN       , S3_WR_LEN       );
axi_inter_sel41 #( 2)selM_WR_ID        ( cu_master_wr_addr_id, BUS_WR_ID        , M0_WR_ID        , M1_WR_ID        , M2_WR_ID        , M3_WR_ID        );
axi_inter_nosel #( 4)selS_WR_ID        ({cu_master_wr_addr_id, BUS_WR_ID}       , S0_WR_ID        , S1_WR_ID        , S2_WR_ID        , S3_WR_ID        );
axi_inter_sel41 #( 1)selM_WR_ADDR_VALID( cu_master_wr_addr_id, BUS_WR_ADDR_VALID, M0_WR_ADDR_VALID, M1_WR_ADDR_VALID, M2_WR_ADDR_VALID, M3_WR_ADDR_VALID);
axi_inter_sel14 #( 1)selS_WR_ADDR_VALID(    slave_wr_addr_sel, BUS_WR_ADDR_VALID, S0_WR_ADDR_VALID, S1_WR_ADDR_VALID, S2_WR_ADDR_VALID, S3_WR_ADDR_VALID);
axi_inter_sel41 #( 1)selS_WR_ADDR_READY(    slave_wr_addr_sel, BUS_WR_ADDR_READY, S0_WR_ADDR_READY, S1_WR_ADDR_READY, S2_WR_ADDR_READY, S3_WR_ADDR_READY);
axi_inter_sel14 #( 1)selM_WR_ADDR_READY( cu_master_wr_addr_id, BUS_WR_ADDR_READY, M0_WR_ADDR_READY, M1_WR_ADDR_READY, M2_WR_ADDR_READY, M3_WR_ADDR_READY);

/**************************读地址通道接口**********************/
always @(posedge BUS_CLK) begin
    if(BUS_RST) rd_addr_lock <= 0;
    else if((BUS_RD_ADDR_VALID && BUS_RD_ADDR_READY)) rd_addr_lock <= 0; //握手成功，传输通道解锁
    else if(BUS_RD_ADDR_VALID) rd_addr_lock <= 1; //握手未成功，传输通道加锁
    else  rd_addr_lock <= rd_addr_lock;
end
always @(*) begin
    if(~rd_addr_lock)begin
             if(M0_RD_ADDR_VALID) nt_master_rd_addr_id <= 2'd0;
        else if(M1_RD_ADDR_VALID) nt_master_rd_addr_id <= 2'd1;
        else if(M2_RD_ADDR_VALID) nt_master_rd_addr_id <= 2'd2;
        else if(M3_RD_ADDR_VALID) nt_master_rd_addr_id <= 2'd3;
        else                      nt_master_rd_addr_id <= 2'd0;
    end else                      nt_master_rd_addr_id <= cu_master_rd_addr_id;
end
always @(posedge BUS_CLK) begin
    if(BUS_RST) cu_master_rd_addr_id <= 2'd0;
    else cu_master_rd_addr_id <= nt_master_rd_addr_id;
end
always @(*) begin
         if(BUS_RD_ADDR >= S0_START_ADDR && BUS_RD_ADDR <= S0_END_ADDR) slave_rd_addr_sel <= 2'd0;
    else if(BUS_RD_ADDR >= S1_START_ADDR && BUS_RD_ADDR <= S1_END_ADDR) slave_rd_addr_sel <= 2'd1;
    else if(BUS_RD_ADDR >= S2_START_ADDR && BUS_RD_ADDR <= S2_END_ADDR) slave_rd_addr_sel <= 2'd2;
    else if(BUS_RD_ADDR >= S3_START_ADDR && BUS_RD_ADDR <= S3_END_ADDR) slave_rd_addr_sel <= 2'd3;
    else slave_rd_addr_sel <= 2'd0;
end

axi_inter_sel41 #(32)selM_RD_ADDR      ( cu_master_rd_addr_id, BUS_RD_ADDR      , M0_RD_ADDR      , M1_RD_ADDR      , M2_RD_ADDR      , M3_RD_ADDR      );
axi_inter_nosel #(32)selS_RD_ADDR      (                       BUS_RD_ADDR      , S0_RD_ADDR      , S1_RD_ADDR      , S2_RD_ADDR      , S3_RD_ADDR      );
axi_inter_sel41 #( 8)selM_RD_LEN       ( cu_master_rd_addr_id, BUS_RD_LEN       , M0_RD_LEN       , M1_RD_LEN       , M2_RD_LEN       , M3_RD_LEN       );
axi_inter_nosel #( 8)selS_RD_LEN       (                       BUS_RD_LEN       , S0_RD_LEN       , S1_RD_LEN       , S2_RD_LEN       , S3_RD_LEN       );
axi_inter_sel41 #( 2)selM_RD_ID        ( cu_master_rd_addr_id, BUS_RD_ID        , M0_RD_ID        , M1_RD_ID        , M2_RD_ID        , M3_RD_ID        );
axi_inter_nosel #( 4)selS_RD_ID        ({cu_master_rd_addr_id, BUS_RD_ID}       , S0_RD_ID        , S1_RD_ID        , S2_RD_ID        , S3_RD_ID        );
axi_inter_sel41 #( 1)selM_RD_ADDR_VALID( cu_master_rd_addr_id, BUS_RD_ADDR_VALID, M0_RD_ADDR_VALID, M1_RD_ADDR_VALID, M2_RD_ADDR_VALID, M3_RD_ADDR_VALID);
axi_inter_sel14 #( 1)selS_RD_ADDR_VALID(    slave_rd_addr_sel, BUS_RD_ADDR_VALID, S0_RD_ADDR_VALID, S1_RD_ADDR_VALID, S2_RD_ADDR_VALID, S3_RD_ADDR_VALID);
axi_inter_sel41 #( 1)selS_RD_ADDR_READY(    slave_rd_addr_sel, BUS_RD_ADDR_READY, S0_RD_ADDR_READY, S1_RD_ADDR_READY, S2_RD_ADDR_READY, S3_RD_ADDR_READY);
axi_inter_sel14 #( 1)selM_RD_ADDR_READY( cu_master_rd_addr_id, BUS_RD_ADDR_READY, M0_RD_ADDR_READY, M1_RD_ADDR_READY, M2_RD_ADDR_READY, M3_RD_ADDR_READY);


/**************************写数据通道接口**********************/
always @(posedge BUS_CLK) begin
    if(BUS_RST) wr_data_lock <= 0;
    else if((BUS_WR_DATA_VALID && BUS_WR_DATA_READY && BUS_WR_DATA_LAST))
        wr_data_lock <= 0; //握手成功并收到最后一个数据标志位，传输通道解锁
    else if((BUS_WR_DATA_VALID && BUS_WR_DATA_READY))
        wr_data_lock <= 1; //数据位握手，传输通道加锁（虽然AXI没有规定不能更改通道）
    else  wr_data_lock <= wr_data_lock;
end
always @(*) begin
    if(~wr_data_lock)begin
             if(S0_WR_DATA_VALID) nt_slave_wr_data_sel <= 2'd0;
        else if(S1_WR_DATA_VALID) nt_slave_wr_data_sel <= 2'd1;
        else if(S2_WR_DATA_VALID) nt_slave_wr_data_sel <= 2'd2;
        else if(S3_WR_DATA_VALID) nt_slave_wr_data_sel <= 2'd3;
        else                      nt_slave_wr_data_sel <= 2'd0;
    end else                      nt_slave_wr_data_sel <= cu_slave_wr_data_sel;
end
always @(posedge BUS_CLK) begin
    if(BUS_RST) cu_slave_wr_data_sel <= 2'd0;
    else cu_slave_wr_data_sel <= nt_slave_wr_data_sel;
end
always @(*) begin
    master_wr_data_id <= BUS_WR_BACK_ID[3:2];
end

axi_inter_sel41 #(32)selM_WR_DATA      (    master_wr_data_id, BUS_WR_DATA        , M0_WR_DATA      , M1_WR_DATA      , M2_WR_DATA      , M3_WR_DATA      );
axi_inter_nosel #(32)selS_WR_DATA      (                       BUS_WR_DATA        , S0_WR_DATA      , S1_WR_DATA      , S2_WR_DATA      , S3_WR_DATA      );
axi_inter_sel41 #( 4)selM_WR_STRB      (    master_wr_data_id, BUS_WR_STRB        , M0_WR_STRB      , M1_WR_STRB      , M2_WR_STRB      , M3_WR_STRB      );
axi_inter_nosel #( 4)selS_WR_STRB      (                       BUS_WR_STRB        , S0_WR_STRB      , S1_WR_STRB      , S2_WR_STRB      , S3_WR_STRB      );
axi_inter_sel41 #( 4)selS_WR_BACK_ID   ( cu_slave_wr_data_sel, BUS_WR_BACK_ID     , S0_WR_BACK_ID   , S1_WR_BACK_ID   , S2_WR_BACK_ID   , S3_WR_BACK_ID   );
axi_inter_nosel #( 2)selM_WR_BACK_ID   (    master_wr_data_id, BUS_WR_BACK_ID[1:0], M0_WR_BACK_ID   , M1_WR_BACK_ID   , M2_WR_BACK_ID   , M3_WR_BACK_ID   );
axi_inter_sel41 #( 1)selM_WR_DATA_VALID(    master_wr_data_id, BUS_WR_DATA_VALID  , M0_WR_DATA_VALID, M1_WR_DATA_VALID, M2_WR_DATA_VALID, M3_WR_DATA_VALID);
axi_inter_sel14 #( 1)selS_WR_DATA_VALID( cu_slave_wr_data_sel, BUS_WR_DATA_VALID  , S0_WR_DATA_VALID, S1_WR_DATA_VALID, S2_WR_DATA_VALID, S3_WR_DATA_VALID);
axi_inter_sel41 #( 1)selS_WR_DATA_READY( cu_slave_wr_data_sel, BUS_WR_DATA_READY  , S0_WR_DATA_READY, S1_WR_DATA_READY, S2_WR_DATA_READY, S3_WR_DATA_READY);
axi_inter_sel14 #( 1)selM_WR_DATA_READY(    master_wr_data_id, BUS_WR_DATA_READY  , M0_WR_DATA_READY, M1_WR_DATA_READY, M2_WR_DATA_READY, M3_WR_DATA_READY);
axi_inter_sel41 #( 1)selM_WR_DATA_LAST (    master_wr_data_id,  BUS_WR_DATA_LAST  , M0_WR_DATA_LAST , M1_WR_DATA_LAST , M2_WR_DATA_LAST , M3_WR_DATA_LAST );
axi_inter_sel14 #( 1)selS_WR_DATA_LAST ( cu_slave_wr_data_sel,  BUS_WR_DATA_LAST  , S0_WR_DATA_LAST , S1_WR_DATA_LAST , S2_WR_DATA_LAST , S3_WR_DATA_LAST );


/**************************读数据通道接口**********************/
always @(posedge BUS_CLK) begin
    if(BUS_RST) rd_data_lock <= 0;
    else if((BUS_RD_DATA_VALID && BUS_RD_DATA_READY && BUS_RD_DATA_LAST))
        rd_data_lock <= 0; //握手成功并收到最后一个数据标志位，传输通道解锁
    else if((BUS_RD_DATA_VALID && BUS_RD_DATA_READY))
        rd_data_lock <= 1; //数据位握手，传输通道加锁（虽然AXI没有规定不能更改通道）
    else  rd_data_lock <= rd_data_lock;
end
always @(*) begin
    if(~rd_data_lock)begin
             if(S0_RD_DATA_VALID) nt_slave_rd_data_sel <= 2'd0;
        else if(S1_RD_DATA_VALID) nt_slave_rd_data_sel <= 2'd1;
        else if(S2_RD_DATA_VALID) nt_slave_rd_data_sel <= 2'd2;
        else if(S3_RD_DATA_VALID) nt_slave_rd_data_sel <= 2'd3;
        else                      nt_slave_rd_data_sel <= 2'd0;
    end else                      nt_slave_rd_data_sel <= cu_slave_rd_data_sel;
end
always @(posedge BUS_CLK) begin
    if(BUS_RST) cu_slave_rd_data_sel <= 2'd0;
    else cu_slave_rd_data_sel <= nt_slave_rd_data_sel;
end

axi_inter_sel41 #(32)selS_RD_DATA      ( cu_slave_rd_data_sel, BUS_RD_DATA        , S0_RD_DATA      , S1_RD_DATA      , S2_RD_DATA      , S3_RD_DATA      );
axi_inter_nosel #(32)selM_RD_DATA      (                       BUS_RD_DATA        , M0_RD_DATA      , M1_RD_DATA      , M2_RD_DATA      , M3_RD_DATA      );
axi_inter_sel41 #( 4)selS_RD_BACK_ID   ( cu_slave_rd_data_sel,{master_rd_data_id,BUS_RD_BACK_ID}    , S0_RD_BACK_ID   , S1_RD_BACK_ID   , S2_RD_BACK_ID   , S3_RD_BACK_ID   );
axi_inter_nosel #( 2)selM_RD_BACK_ID   (    master_rd_data_id, BUS_RD_BACK_ID     , M0_RD_BACK_ID   , M1_RD_BACK_ID   , M2_RD_BACK_ID   , M3_RD_BACK_ID   );
axi_inter_sel41 #( 1)selS_RD_DATA_VALID( cu_slave_rd_data_sel, BUS_RD_DATA_VALID  , S0_RD_DATA_VALID, S1_RD_DATA_VALID, S2_RD_DATA_VALID, S3_RD_DATA_VALID);
axi_inter_sel14 #( 1)selM_RD_DATA_VALID(    master_rd_data_id, BUS_RD_DATA_VALID  , M0_RD_DATA_VALID, M1_RD_DATA_VALID, M2_RD_DATA_VALID, M3_RD_DATA_VALID);
axi_inter_sel41 #( 1)selM_RD_DATA_READY(    master_rd_data_id, BUS_RD_DATA_READY  , M0_RD_DATA_READY, M1_RD_DATA_READY, M2_RD_DATA_READY, M3_RD_DATA_READY);
axi_inter_sel14 #( 1)selS_RD_DATA_READY( cu_slave_rd_data_sel, BUS_RD_DATA_READY  , S0_RD_DATA_READY, S1_RD_DATA_READY, S2_RD_DATA_READY, S3_RD_DATA_READY);
axi_inter_sel41 #( 1)selS_RD_DATA_LAST ( cu_slave_rd_data_sel, BUS_RD_DATA_LAST   , S0_RD_DATA_LAST , S1_RD_DATA_LAST , S2_RD_DATA_LAST , S3_RD_DATA_LAST );
axi_inter_sel14 #( 1)selM_RD_DATA_LAST (    master_rd_data_id, BUS_RD_DATA_LAST   , M0_RD_DATA_LAST , M1_RD_DATA_LAST , M2_RD_DATA_LAST , M3_RD_DATA_LAST );


endmodule