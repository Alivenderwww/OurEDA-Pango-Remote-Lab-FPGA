`timescale 1ns/1ps
module rgmii_sim #(
    parameter [31:0] BOARD_IP  = 32'hEA_00_A8_C0,
    parameter [47:0] BOARD_MAC = 48'hBC_9A_78_56_34_12
)(
    input wire rgmii_rxc_x2,

    output             rgmii_rxc   ,
    output reg         rgmii_rx_ctl,
    output      [3:0]  rgmii_rxd   ,
    input              rgmii_txc   ,
    input              rgmii_tx_ctl,
    input       [3:0]  rgmii_txd    

);

initial rgmii_rx_ctl   = 0;

reg [3:0] trans_bit4;
initial trans_bit4 = 0;

task automatic send_wr_addr;
    input [ 1:0] id;
    input [ 1:0] burst;
    input [ 2:0] len;//突发长度，仿真阶段最大7突发（32*8bit）
    input [31:0] addr;
    @(negedge rgmii_rxc_x2);
    send_to_udp_high(7,{{{8'h00},{burst,id,1'b0,1'b0,1'b0,1'b1},{5'b0,len},8'h0},addr,32'h0,32'h0,32'h0,32'h0,32'h0,32'h0});
    $display("%m: at time %0t INFO: send wr addr.", $time);
endtask

task automatic send_rd_addr;
    input [ 1:0] id;
    input [ 1:0] burst;
    input [ 2:0] len;//突发长度，仿真阶段最大7突发（32*8bit）
    input [31:0] addr;
    @(negedge rgmii_rxc_x2);
    send_to_udp_high(7,{{{8'h00},{burst,id,1'b0,1'b0,1'b0,1'b0},{5'b0,len},8'h0},addr,32'h0,32'h0,32'h0,32'h0,32'h0,32'h0});
    $display("%m: at time %0t INFO: send rd addr.", $time);
endtask

task automatic send_wr_data;
    input [ 7:0] len;//突发长度，仿真阶段最大7突发（32*8bit）
    input [31:0] start_data;//起始数据，后面的默认+1
    @(negedge rgmii_rxc_x2);
    send_to_udp_high((4+(len+1)*4-1),{{8'hFF,24'h00},start_data,start_data+1,start_data+2,start_data+3,start_data+4,start_data+5,start_data+6});
    $display("%m: at time %0t INFO: send wr data.", $time);
endtask

task automatic send_to_udp_low;
    input [     7:0] byte_num; //最大支持32字节，实际上是比总线最大支持1024字节少的，仿真限制一下大小。
    input [32*8-1:0] trans_data;
    reg   [32*8-1:0] trans_data_reg;
    reg   [ 400-1:0] fixed_trans_data;
    reg   [    47:0] board_mac;
    reg   [    31:0] board_ip;
    integer i;
    begin
        for(i=0; i<48; i=i+4) board_mac[(47-i)-:4] = BOARD_MAC[i+:4];
        for(i=0; i<32; i=i+4)  board_ip[(31-i)-:4] =  BOARD_IP[i+:4];
        @(negedge rgmii_rxc_x2) begin
            trans_data_reg = trans_data;
            fixed_trans_data = {16'h00_00,{(byte_num+8'd1+8'd8),8'h00},32'hD2_04_D2_04,board_ip,192'h91_00_A8_C0_00_00_11_80_00_00_00_5F_3C_00_00_45_00_08_2D_DB_4A_5E_D5_E0,board_mac,64'hD5_55_55_55_55_55_55_55};
            rgmii_rx_ctl = 0;
        end
        for(i=0; i<(400)/4; i=i+1) begin
            @(negedge rgmii_rxc_x2) begin
                 rgmii_rx_ctl = 1;
                 trans_bit4 = fixed_trans_data[3:0];
                 fixed_trans_data = fixed_trans_data >> 4;
             end
        end
        for(i=0; i<((32*8-(byte_num+1)*8)/4); i=i+1) trans_data_reg = trans_data_reg << 4;
        for(i=0; i<(((byte_num+1)*8)/4)/2; i=i+1) begin
            @(negedge rgmii_rxc_x2) begin
                 trans_bit4 = trans_data_reg[(32*8-1-4)-:(4)];
             end
            @(negedge rgmii_rxc_x2) begin
                 trans_bit4 = trans_data_reg[(32*8-1)-:(4)];
                 trans_data_reg = trans_data_reg << 8;
             end
        end
        @(negedge rgmii_rxc_x2) rgmii_rx_ctl = 0;
    end
endtask

task automatic send_to_udp_high;
    input [     7:0] byte_num; //最大支持32字节，实际上是比总线最大支持1024字节少的，仿真限制一下大小。
    input [32*8-1:0] trans_data;
    reg   [32*8-1:0] trans_data_reg;
    reg   [ 400-1:0] fixed_trans_data;
    reg   [    47:0] board_mac;
    reg   [    31:0] board_ip;
    integer i;
    begin
        for(i=0; i<48; i=i+8) board_mac[(47-i)-:8] = BOARD_MAC[i+:8];
        for(i=0; i<32; i=i+8)  board_ip[(31-i)-:8] =  BOARD_IP[i+:8];
        @(negedge rgmii_rxc_x2) begin
            trans_data_reg = trans_data;
            fixed_trans_data = {16'h00_00,{(byte_num+8'd1+8'd8),8'h00},32'hD2_04_D2_04,board_ip,192'h91_00_A8_C0_00_00_11_80_00_00_00_5F_3C_00_00_45_00_08_2D_DB_4A_5E_D5_E0,board_mac,64'hD5_55_55_55_55_55_55_55};
            rgmii_rx_ctl = 0;
        end
        for(i=0; i<(400)/4; i=i+1) begin
            @(negedge rgmii_rxc_x2) begin
                 rgmii_rx_ctl = 1;
                 trans_bit4 = fixed_trans_data[3:0];
                 fixed_trans_data = fixed_trans_data >> 4;
             end
        end
        for(i=0; i<(((byte_num+1)*8)/4)/2; i=i+1) begin
            @(negedge rgmii_rxc_x2) begin
                 trans_bit4 = trans_data_reg[(32*8-1-4)-:(4)];
             end
            @(negedge rgmii_rxc_x2) begin
                 trans_bit4 = trans_data_reg[(32*8-1)-:(4)];
                 trans_data_reg = trans_data_reg << 8;
             end
        end
        @(negedge rgmii_rxc_x2) rgmii_rx_ctl = 0;
    end
endtask
assign rgmii_rxd = (rgmii_rx_ctl)?(trans_bit4):(0);


endmodule //udp_axi_master_sim
