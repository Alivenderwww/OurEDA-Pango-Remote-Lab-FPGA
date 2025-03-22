`timescale 1ns/1ps
module axi_master_sim (
    input  wire        clk          ,
    input  wire        rst          ,

    output  reg [31:0] WR_ADDR      ,
    output  reg [ 7:0] WR_LEN       ,
    output  reg [ 1:0] WR_ID        ,
    output  reg        WR_ADDR_VALID,
    input  wire        WR_ADDR_READY,
      
    output  reg [31:0] WR_DATA      ,
    output  reg [ 3:0] WR_STRB      ,
    input  wire [ 1:0] WR_BACK_ID   ,
    output  reg        WR_DATA_VALID,
    input  wire        WR_DATA_READY,
    output  reg        WR_DATA_LAST ,
      
    output  reg [31:0] RD_ADDR      ,
    output  reg [ 7:0] RD_LEN       ,
    output  reg [ 1:0] RD_ID        ,
    output  reg        RD_ADDR_VALID,
    input  wire        RD_ADDR_READY,

    input  wire [31:0] RD_DATA      ,
    input  wire        RD_DATA_LAST ,
    input  wire [ 1:0] RD_BACK_ID   ,
    output  reg        RD_DATA_READY,
    input  wire        RD_DATA_VALID
);

///////////////////////////////////////////////////////////////
initial begin
    #50000
    send_wr_addr(32'h00000170, 111, 0);
    send_wr_data(32'h00000000, 100, 4'b1111, 0);
    send_rd_addr(32'h00000170, 111, 0);
    recv_rd_data(0);
end
///////////////////////////////////////////////////////////////

task send_wr_addr; //MASTER的写地址线通道传输一次。指定WR_ADDR，WR_LEN，WR_ID。
    input [31:0] wr_addr;
    input [ 7:0] wr_len;
    input [ 1:0] wr_id;
    begin
        @(posedge clk) begin
            WR_ADDR <= wr_addr;
            WR_LEN  <= wr_len;
            WR_ID   <= wr_id;
            WR_ADDR_VALID <= 1;
        end
        while(~(WR_ADDR_READY && WR_ADDR_VALID))begin
            @(posedge clk);
        end
        @(negedge clk) WR_ADDR_VALID <= 0;
    end
endtask

task send_rd_addr; //MASTER的读地址线通道传输一次。指定WR_ADDR，WR_LEN，WR_ID。
    input [31:0] rd_addr;
    input [ 7:0] rd_len;
    input [ 1:0] rd_id;
    begin
        @(posedge clk) begin
            RD_ADDR <= rd_addr;
            RD_LEN  <= rd_len;
            RD_ID   <= rd_id;
            RD_ADDR_VALID <= 1;
        end
        while(~(RD_ADDR_READY && RD_ADDR_VALID))begin
            @(posedge clk);
        end
        @(negedge clk) RD_ADDR_VALID <= 0;
    end
endtask

task send_wr_data; //MASTER的写数据线通道传输一次。指定起始数据，突发长度（禁止与之前设置的突发长度不一致），掩码，敏感ID号。
//数据格式是从start_data开始每一次+1
    input [31:0] start_data;
    input [ 7:0] len;
    input [ 3:0] strb;
    input [ 1:0] sensitive_id;
    reg   [ 7:0] trans_cnt;
    begin
        trans_cnt <= 0;
        @(posedge clk) begin
            WR_DATA       <= start_data;
            WR_STRB       <= strb;
            WR_DATA_VALID <= 1;
            WR_DATA_LAST  <= (trans_cnt == len);
        end
        while(~((sensitive_id == WR_BACK_ID) && WR_DATA_READY && WR_DATA_VALID && WR_DATA_LAST))begin
            WR_DATA_LAST <= (trans_cnt == len);
            @(posedge clk) if((sensitive_id == WR_BACK_ID) && WR_DATA_READY && WR_DATA_VALID) begin
                WR_DATA <= WR_DATA + 1;
                trans_cnt <= trans_cnt + 1;
            end
            WR_DATA_LAST <= (trans_cnt == len);
        end
        @(negedge clk) begin
            WR_DATA_VALID <= 0;
            WR_DATA_LAST <= 0;
        end
    end
endtask

task recv_rd_data; //MASTER的读数据线通道传输一次。指定敏感ID号。不存储收到的数据，收到LAST信号后结束。
    input [ 1:0] sensitive_id;
    begin
        @(posedge clk) begin
            RD_DATA_READY <= 1;
        end
        while(~((sensitive_id == RD_BACK_ID) && RD_DATA_READY && RD_DATA_VALID && RD_DATA_LAST))begin
            @(posedge clk);
        end
        @(negedge clk) begin
            RD_DATA_READY <= 0;
        end
    end
endtask

initial begin
    WR_ADDR       = 0;
    WR_LEN        = 0;
    WR_ID         = 0;
    WR_ADDR_VALID = 0;
    WR_DATA       = 0;
    WR_STRB       = 0;
    WR_DATA_VALID = 0;
    WR_DATA_LAST  = 0;
    RD_ADDR       = 0;
    RD_LEN        = 0;
    RD_ID         = 0;
    RD_ADDR_VALID = 0;
    RD_DATA_READY = 0;
end

endmodule