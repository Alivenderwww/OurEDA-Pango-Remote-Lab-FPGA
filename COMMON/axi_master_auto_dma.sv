module axi_master_auto_dma #(
    parameter I2C_EEPROM_SLAVE_BASEADDR = 32'h0000_0000 // I2C对应SLAVE的BASEADDR
)(
    input  wire          clk                 ,
    input  wire          rstn                ,

    // AXI Master Interface
    output logic         MASTER_CLK          ,
    output logic         MASTER_RSTN         ,
    output logic [2-1:0] MASTER_WR_ADDR_ID   ,
    output logic [31:0]  MASTER_WR_ADDR      ,
    output logic [ 7:0]  MASTER_WR_ADDR_LEN  ,
    output logic [ 1:0]  MASTER_WR_ADDR_BURST,
    output logic         MASTER_WR_ADDR_VALID,
    input  logic         MASTER_WR_ADDR_READY,
    output logic [31:0]  MASTER_WR_DATA      ,
    output logic [ 3:0]  MASTER_WR_STRB      ,
    output logic         MASTER_WR_DATA_LAST ,
    output logic         MASTER_WR_DATA_VALID,
    input  logic         MASTER_WR_DATA_READY,
    input  logic [2-1:0] MASTER_WR_BACK_ID   ,
    input  logic [ 1:0]  MASTER_WR_BACK_RESP ,
    input  logic         MASTER_WR_BACK_VALID,
    output logic         MASTER_WR_BACK_READY,
    output logic [2-1:0] MASTER_RD_ADDR_ID   ,
    output logic [31:0]  MASTER_RD_ADDR      ,
    output logic [ 7:0]  MASTER_RD_ADDR_LEN  ,
    output logic [ 1:0]  MASTER_RD_ADDR_BURST,
    output logic         MASTER_RD_ADDR_VALID,
    input  logic         MASTER_RD_ADDR_READY,
    input  logic [2-1:0] MASTER_RD_BACK_ID   ,
    input  logic [31:0]  MASTER_RD_DATA      ,
    input  logic [ 1:0]  MASTER_RD_DATA_RESP ,
    input  logic         MASTER_RD_DATA_LAST ,
    input  logic         MASTER_RD_DATA_VALID,
    output logic         MASTER_RD_DATA_READY);

/*
在这里用作系统上电后自动从EEPROM中获取板卡的IP地址

读取的配置顺序
    // 写地址通道，id=0, addr=01, len=0, burst=01
    // 写数据通道，id=0, data={16'd1, 16'd7}, strb=1111
    //                   (读DUMMY为2字节，传输8字节有效数据)
    // 写地址通道，id=0, addr=03, len=5, burst=01
    // 写数据通道，id=0, data={24'h0, 8'h0},{24'h0, 8'h0}, strb=1111
    //                   (读DUMMY为0x00, 即读地址从0x00开始)
    // 写地址通道，id=0, addr=00, len=0, burst=01
    // 写数据通道，id=0, data={8'h1,8'h0,8'h1,1'b0,7'b1010_000}, strb=1111
    //                   (开启传输，I2C协议，读模式，I2C地址为1010_000)
    // 读地址通道，id=0, addr=04, len=3, burst=00 (读4字节数据)

    读地址通道，id=0, addr=32'hS0_A7_00_00, len=7, burst=00 (读8字节数据)
    读地址通道，接收8个32bit数据，低八位有效。
*/




endmodule //axi_master_auto_dma
