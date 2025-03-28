///////////////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2019 PANGO MICROSYSTEMS, INC
// ALL RIGHTS REVERVED.
//
// THE SOURCE CODE CONTAINED HEREIN IS PROPRIETARY TO PANGO MICROSYSTEMS, INC.
// IT SHALL NOT BE REPRODUCED OR DISCLOSED IN WHOLE OR IN PART OR USED BY
// PARTIES WITHOUT WRITTEN AUTHORIZATION FROM THE OWNER.
//
///////////////////////////////////////////////////////////////////////////////
//
// Library:
// Filename:
///////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1 ns
module uart_rx_ctrl#(
parameter   BAUDRATE    =  115200       , // 2400 , 4800 , 9600 , 19200 , 38400 , 115200  
parameter   CLK_DIV     =  12'd868      , // (1000000000ns/10ns)/115200 = 868.06
parameter   PARITY_TYPE = "no parity"   , //"no parity" , "odd parity" , "even parity"
parameter   U_DLY       =  1
)(
input               sys_clk                 ,   
input               sys_rst_n               ,   

output reg [7:0]    rx_data                 ,
output reg          rx_valid                ,

input               uart_rx                    
);
//--------------------------- parameter define ---------------------------
localparam ST_RX_IDLE   = 3'b001; 
localparam ST_RX_START  = 3'b010;
localparam ST_RX_DATA   = 3'b100;

//--------------------------- reg define ---------------------------------
reg                 uart_rx_1dly            ;
reg                 uart_rx_2dly            ;
reg                 uart_rx_3dly            ;
reg                 uart_rx_neg             ;

reg  [2:0]          uart_rx_reg             ;
reg                 uart_rx_bit             ;

reg  [2:0]          rx_cur_state            ;
reg  [2:0]          rx_nxt_state            ;

reg  [15:0]         rx_baud_cnt             ; 
reg  [15:0]         rx_baudrate_num         ; 

reg                 rx_count_en             ; 
reg  [ 3:0]         recive_bit_cnt          ; 
reg  [ 7:0]         rx_data_reg             ;
reg                 recive_byte_done        ;

reg                 recive_start_err        ;

reg                 parity_bit              ;
reg                 parity_err_ind          ;

//--------------------------- wire define ---------------------------------




//--------------------------------------------------------------------
always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
    begin
        uart_rx_1dly <=#U_DLY 1'b0;
        uart_rx_2dly <=#U_DLY 1'b0;
        uart_rx_3dly <=#U_DLY 1'b0;
        uart_rx_neg  <=#U_DLY 1'b0;
    end
    else 
    begin
        uart_rx_1dly <=#U_DLY uart_rx;
        uart_rx_2dly <=#U_DLY uart_rx_1dly;
        uart_rx_3dly <=#U_DLY uart_rx_2dly;
        uart_rx_neg  <=#U_DLY (~uart_rx_1dly)&uart_rx_2dly;
    end        
end

always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        recive_start_err <=#U_DLY 1'b0;
    else if(uart_rx == 4'd1 && rx_baud_cnt < (rx_baudrate_num[15:1] + rx_baudrate_num[15:2]) && rx_baud_cnt > rx_baudrate_num[15:2])
        recive_start_err <=#U_DLY 1'b1; 
    else 
        recive_start_err <=#U_DLY 1'b0;     
end

always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        rx_cur_state <=#U_DLY ST_RX_IDLE;
    else 
        rx_cur_state <=#U_DLY rx_nxt_state;        
end

always @(*)
begin
    case(rx_cur_state)
    ST_RX_IDLE:
    begin
        if(uart_rx_neg == 1'b1)
            rx_nxt_state = ST_RX_START;
        else
            rx_nxt_state = ST_RX_IDLE; 
    end
    ST_RX_START:
    begin
        if(recive_bit_cnt == 4'd1)
            rx_nxt_state = ST_RX_DATA;
        else if(recive_start_err == 4'd1)//  jitter 
            rx_nxt_state = ST_RX_IDLE;
        else
            rx_nxt_state = ST_RX_START; 
    end
    ST_RX_DATA:
    begin
        if(recive_byte_done == 1'b1)
            rx_nxt_state = ST_RX_IDLE;
        else
            rx_nxt_state = ST_RX_DATA; 
    end
    default:rx_nxt_state = ST_RX_IDLE; 
    endcase       
end

//-------------------------------------------------------------------------


always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        rx_count_en <=#U_DLY 1'b0;
    else if(rx_cur_state == ST_RX_IDLE)
        rx_count_en <=#U_DLY 1'b0; 
    else
        rx_count_en <=#U_DLY 1'b1;  
end     

always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        rx_baud_cnt <=#U_DLY 16'h0;
    else if(rx_count_en == 1'b0 || rx_baud_cnt >= (rx_baudrate_num - 1'b1))
        rx_baud_cnt <=#U_DLY 16'h0; 
    else
        rx_baud_cnt <=#U_DLY rx_baud_cnt + 1'b1;  
end

always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        rx_baudrate_num <=#U_DLY 16'h0;  
    else
    begin
        case(BAUDRATE)
            2400    : rx_baudrate_num <=#U_DLY {CLK_DIV,4'b0};
            4800    : rx_baudrate_num <=#U_DLY {CLK_DIV,3'b0}; 
            9600    : rx_baudrate_num <=#U_DLY {CLK_DIV,2'b0}; 
            19200   : rx_baudrate_num <=#U_DLY {CLK_DIV,1'b0}; 
            38400   : rx_baudrate_num <=#U_DLY CLK_DIV; 
            115200  : rx_baudrate_num <=#U_DLY {4'h0,CLK_DIV};
            default : rx_baudrate_num <=#U_DLY {CLK_DIV,2'b0};
        endcase 
    end
end           

always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        recive_bit_cnt <=#U_DLY 4'h0;
    else if(rx_count_en == 1'b0)
        recive_bit_cnt <=#U_DLY 4'h0; 
    else if(rx_baud_cnt >= (rx_baudrate_num-1'b1))//
    begin
        if((recive_bit_cnt >= 4'd9 && PARITY_TYPE == "no parity") || (recive_bit_cnt > 4'd10 && PARITY_TYPE != "no parity"))
            recive_bit_cnt <=#U_DLY 4'h0; 
        else
            recive_bit_cnt <=#U_DLY recive_bit_cnt + 1'b1;
    end 
    else
        ;  
end

always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        recive_byte_done <=#U_DLY 1'b0;
    else if((recive_bit_cnt >= 4'd9 && PARITY_TYPE == "no parity") || (recive_bit_cnt >= 4'd10 && (PARITY_TYPE == "odd parity" || PARITY_TYPE == "even parity")))
        recive_byte_done <=#U_DLY 1'b1;
    else 
        recive_byte_done <=#U_DLY 1'b0;   
end

//-----------------------------------------------------------------------------
always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        uart_rx_reg <=#U_DLY 3'b0;
    else if(rx_baud_cnt == {2'b0,rx_baudrate_num[15:2]})//sampling rx bit 3 times at 1/4 1/2 3/4
        uart_rx_reg<=#U_DLY {uart_rx_reg[1:0],uart_rx_1dly};
    else if(rx_baud_cnt == {1'b0,rx_baudrate_num[15:1]})//sampling rx bit 3 times at 1/4 1/2 3/4
        uart_rx_reg<=#U_DLY {uart_rx_reg[1:0],uart_rx_1dly};
    else if(rx_baud_cnt == ({2'b0,rx_baudrate_num[15:2]} + {1'b0,rx_baudrate_num[15:1]}))//sampling rx bit 3 times at 1/4 1/2 3/4
        uart_rx_reg<=#U_DLY {uart_rx_reg[1:0],uart_rx_1dly};
    else
        ;
end

always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        uart_rx_bit <=#U_DLY 1'b0;
    else
    begin 
        case(uart_rx_reg)
            3'b000:uart_rx_bit<=#U_DLY 1'b0;
            3'b001:uart_rx_bit<=#U_DLY 1'b0;
            3'b010:uart_rx_bit<=#U_DLY 1'b0;
            3'b011:uart_rx_bit<=#U_DLY 1'b1;
            3'b100:uart_rx_bit<=#U_DLY 1'b0;
            3'b101:uart_rx_bit<=#U_DLY 1'b1;
            3'b110:uart_rx_bit<=#U_DLY 1'b1;
            3'b111:uart_rx_bit<=#U_DLY 1'b1;
            default:uart_rx_bit<=#U_DLY 1'b0;
        endcase
    end

end

always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        rx_data_reg <=#U_DLY 8'h0;
    else if(rx_baud_cnt == (rx_baudrate_num - 16'd2))
    begin
        case(recive_bit_cnt) 
            4'd1 : rx_data_reg[0] <=#U_DLY uart_rx_bit; 
            4'd2 : rx_data_reg[1] <=#U_DLY uart_rx_bit; 
            4'd3 : rx_data_reg[2] <=#U_DLY uart_rx_bit; 
            4'd4 : rx_data_reg[3] <=#U_DLY uart_rx_bit; 
            4'd5 : rx_data_reg[4] <=#U_DLY uart_rx_bit; 
            4'd6 : rx_data_reg[5] <=#U_DLY uart_rx_bit; 
            4'd7 : rx_data_reg[6] <=#U_DLY uart_rx_bit; 
            4'd8 : rx_data_reg[7] <=#U_DLY uart_rx_bit; 
            default: ;
        endcase
    end
    else
        ; 
end

always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        parity_bit <=#U_DLY 1'h0;
    else if(rx_baud_cnt == rx_baudrate_num && recive_bit_cnt == 4'd9)//sampling rx data at middle
        parity_bit <=#U_DLY uart_rx_bit;
    else
        ;
end

always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        parity_err_ind <=#U_DLY 1'b0;
    else if(recive_bit_cnt == 4'd10)
    begin
        if(PARITY_TYPE == "odd parity" && parity_bit != ~(^rx_data_reg))
            parity_err_ind <=#U_DLY 1'b1;
        else if(PARITY_TYPE == "even parity" && parity_bit != ^rx_data_reg)
            parity_err_ind <=#U_DLY 1'b1;
        else
            parity_err_ind <=#U_DLY 1'b0;
    end
    else 
        parity_err_ind <=#U_DLY 1'b0;

end

//---------------------------------------------------------------------------------------------
always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
    begin
        rx_valid <=#U_DLY 1'b0;
        rx_data  <=#U_DLY 8'h0;
    end
    else if(rx_baud_cnt >= (rx_baudrate_num - 1'b1) && recive_bit_cnt == 4'd8)
    begin
        rx_valid <=#U_DLY 1'b1;
        rx_data  <=#U_DLY rx_data_reg;
    end
    else
    begin
        rx_valid <=#U_DLY 1'b0;
        rx_data  <=#U_DLY rx_data;
    end
end


endmodule  



