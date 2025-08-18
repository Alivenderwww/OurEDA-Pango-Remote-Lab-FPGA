`timescale 1ns/1ps
module DDR_axi_sim(
    //DDR时钟/复位/初始化接口
    input  wire          ddr_ref_clk            ,
    input  wire          rst_n                  ,
    output logic         DDR_SLAVE_CLK          ,
    output logic         DDR_SLAVE_RSTN         ,

    input  logic [4-1:0] DDR_SLAVE_WR_ADDR_ID   ,
    input  logic [31:0]  DDR_SLAVE_WR_ADDR      ,
    input  logic [ 7:0]  DDR_SLAVE_WR_ADDR_LEN  ,
    input  logic [ 1:0]  DDR_SLAVE_WR_ADDR_BURST, // no use
    input  logic         DDR_SLAVE_WR_ADDR_VALID,
    output logic         DDR_SLAVE_WR_ADDR_READY,

    input  logic [31:0]  DDR_SLAVE_WR_DATA      ,
    input  logic [ 3:0]  DDR_SLAVE_WR_STRB      , // no use
    input  logic         DDR_SLAVE_WR_DATA_LAST ,
    input  logic         DDR_SLAVE_WR_DATA_VALID,
    output logic         DDR_SLAVE_WR_DATA_READY,

    output logic [4-1:0] DDR_SLAVE_WR_BACK_ID   ,
    output logic [ 1:0]  DDR_SLAVE_WR_BACK_RESP ,
    output logic         DDR_SLAVE_WR_BACK_VALID,
    input  logic         DDR_SLAVE_WR_BACK_READY,

    input  logic [4-1:0] DDR_SLAVE_RD_ADDR_ID   ,
    input  logic [31:0]  DDR_SLAVE_RD_ADDR      ,
    input  logic [ 7:0]  DDR_SLAVE_RD_ADDR_LEN  ,
    input  logic [ 1:0]  DDR_SLAVE_RD_ADDR_BURST, // no use
    input  logic         DDR_SLAVE_RD_ADDR_VALID,
    output logic         DDR_SLAVE_RD_ADDR_READY,

    output logic [4-1:0] DDR_SLAVE_RD_BACK_ID   ,
    output logic [31:0]  DDR_SLAVE_RD_DATA      ,
    output logic [ 1:0]  DDR_SLAVE_RD_DATA_RESP ,
    output logic         DDR_SLAVE_RD_DATA_LAST ,
    output logic         DDR_SLAVE_RD_DATA_VALID,
    input  logic         DDR_SLAVE_RD_DATA_READY
);

initial begin
    DDR_SLAVE_CLK = 1'b0; // Initialize DDR clock
    DDR_SLAVE_RSTN = 1'b0; // Initialize DDR reset
    while (!rst_n) begin
        #100; // Wait for reset to be released
    end
    #1000000;
    $display("start DDR_axi_sim");
    DDR_SLAVE_RSTN = 1'b1; // Release DDR reset
end
always #3 DDR_SLAVE_CLK = ~DDR_SLAVE_CLK; // Generate clock signal

reg [19:0] DDR_wrptr;
reg [19:0] DDR_rdptr;
reg [7:0] DDR_rd_len;
reg [3:0] wr_back_id, rd_back_id;
logic [31:0] DDR [0:(20'hFFF_FF)]; // DDR memory array, 0x0000000 to 0xFFFFFFF

initial begin
    DDR_SLAVE_WR_ADDR_READY <= 1'b0;
    DDR_SLAVE_WR_DATA_READY <= 1'b0;
    DDR_SLAVE_WR_BACK_ID <= 4'b0;
    DDR_SLAVE_WR_BACK_RESP <= 2'b00; // OKAY response
    DDR_SLAVE_WR_BACK_VALID <= 1'b0;
    DDR_wrptr <= 0;
    DDR_rdptr <= 0;
    DDR_rd_len <= 8'h0;
    wr_back_id <= 4'b0;
    rd_back_id <= 4'b0;
    DDR_SLAVE_RD_ADDR_READY <= 1'b0;
    DDR_SLAVE_RD_DATA_RESP <= 2'b00; // OKAY response
    DDR_SLAVE_RD_DATA_VALID <= 1'b0;
end

always begin: write_channel
    @(posedge DDR_SLAVE_CLK) begin
        DDR_SLAVE_WR_ADDR_READY <= 1'b1;
        DDR_SLAVE_WR_DATA_READY <= 1'b0;
        DDR_SLAVE_WR_BACK_VALID <= 1'b0;
    end
    while(~(DDR_SLAVE_WR_ADDR_VALID && DDR_SLAVE_WR_ADDR_READY)) @(posedge DDR_SLAVE_CLK);
    @(negedge DDR_SLAVE_CLK) begin
        DDR_SLAVE_WR_ADDR_READY <= 1'b0;
        DDR_SLAVE_WR_DATA_READY <= 1'b1;
        DDR_wrptr <= DDR_SLAVE_WR_ADDR[19:0];
        wr_back_id <= DDR_SLAVE_WR_ADDR_ID;
    end
    while(~(DDR_SLAVE_WR_DATA_VALID && DDR_SLAVE_WR_DATA_READY && DDR_SLAVE_WR_DATA_LAST)) begin
        @(posedge DDR_SLAVE_CLK) if(DDR_SLAVE_WR_DATA_VALID && DDR_SLAVE_WR_DATA_READY) begin
            DDR_wrptr <= DDR_wrptr + 1;
            DDR[DDR_wrptr] <= DDR_SLAVE_WR_DATA;
        end
    end
    @(negedge DDR_SLAVE_CLK) begin
        DDR_SLAVE_WR_BACK_ID <= wr_back_id;
        DDR_SLAVE_WR_BACK_VALID <= 1'b1;
        DDR_SLAVE_WR_DATA_READY <= 1'b0;
        DDR_SLAVE_WR_BACK_RESP <= 2'b00; // OKAY response
    end
    while(~(DDR_SLAVE_WR_BACK_READY && DDR_SLAVE_WR_BACK_VALID)) @(posedge DDR_SLAVE_CLK);
    @(negedge DDR_SLAVE_CLK) begin
        DDR_SLAVE_WR_ADDR_READY <= 1'b1;
        DDR_SLAVE_WR_BACK_VALID <= 1'b0;
    end
end

always begin: read_channel
    @(posedge DDR_SLAVE_CLK) begin
        DDR_SLAVE_RD_ADDR_READY <= 1'b1;
        DDR_SLAVE_RD_DATA_RESP <= 2'b00; // OKAY response
        DDR_SLAVE_RD_DATA_VALID <= 1'b0;
    end
    while(~(DDR_SLAVE_RD_ADDR_VALID && DDR_SLAVE_RD_ADDR_READY)) @(posedge DDR_SLAVE_CLK);
    @(negedge DDR_SLAVE_CLK) begin
        DDR_SLAVE_RD_ADDR_READY <= 1'b0;
        DDR_SLAVE_RD_DATA_VALID <= 1'b1;
        DDR_rdptr <= DDR_SLAVE_RD_ADDR[19:0];
        DDR_SLAVE_RD_DATA <= DDR[DDR_SLAVE_RD_ADDR[19:0]];
        rd_back_id <= DDR_SLAVE_RD_ADDR_ID;
        DDR_rd_len <= DDR_SLAVE_RD_ADDR_LEN;
    end
    while(~(DDR_SLAVE_RD_DATA_VALID && DDR_SLAVE_RD_DATA_READY && DDR_SLAVE_RD_DATA_LAST)) begin
        @(posedge DDR_SLAVE_CLK) if(DDR_SLAVE_RD_DATA_VALID && DDR_SLAVE_RD_DATA_READY) begin
            DDR_rdptr <= DDR_rdptr + 1;
            DDR_rd_len <= DDR_rd_len - 1;
        end
        @(negedge DDR_SLAVE_CLK) begin
            DDR_SLAVE_RD_DATA <= DDR[DDR_rdptr];
        end
    end
    @(negedge DDR_SLAVE_CLK) begin
        DDR_SLAVE_RD_ADDR_READY <= 1'b1;
        DDR_SLAVE_RD_DATA_RESP <= 2'b00;
        DDR_SLAVE_RD_DATA_VALID <= 1'b0;
    end
end
assign DDR_SLAVE_RD_DATA_LAST = DDR_SLAVE_RD_DATA_VALID && DDR_SLAVE_RD_DATA_READY && (DDR_rd_len == 0);
assign DDR_SLAVE_RD_BACK_ID = rd_back_id;

endmodule //DDR_axi_sim
