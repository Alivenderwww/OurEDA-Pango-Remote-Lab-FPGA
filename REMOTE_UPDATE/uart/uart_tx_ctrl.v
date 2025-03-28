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
module uart_tx_ctrl#(
parameter   BAUDRATE    =  115200       , // 2400 , 4800 , 9600 , 19200 , 38400 , 115200 
parameter   CLK_DIV     =  12'd868      , // (1000000000ns/10ns)/115200 = 868.06
parameter   PARITY_TYPE = "no parity"   , //"no parity" , "odd parity" , "even parity"
parameter   U_DLY       =  1
)(
input               sys_clk                 ,   
input               sys_rst_n               ,   

input  [7:0]        tx_data                 ,
input               tx_valid                ,
output              tx_ready                ,

output reg          uart_tx                    
);
//--------------------------- parameter define ---------------------------
localparam TX_IDLE   = 2'b01;
localparam TX_SEND   = 2'b10;

//--------------------------- reg define ---------------------------------
reg  [1:0]          tx_cur_state            ;
reg  [1:0]          tx_nxt_state            ;

reg  [15:0]         tx_baud_cnt             ; 
reg  [15:0]         tx_baudrate_num         ; 

reg                 tx_count_en             ; 
reg  [ 3:0]         send_bit_cnt            ; 

reg  [ 7:0]         tx_data_reg             ;
reg                 send_byte_done          ;

reg  [ 7:0]         tx_fifo_wr_data         ;
reg                 tx_fifo_wr_en           ;
reg                 tx_fifo_rd_en           ;
//--------------------------- wire define ---------------------------------
wire                tx_fifo_wr_full         ;
wire                tx_fifo_wr_afull        ;
wire                tx_fifo_rd_empty        ;
wire [ 7:0]         tx_fifo_rd_data         ; 


//-------------------------------------------------------------------------
always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
    begin
        tx_fifo_wr_data <=#U_DLY 8'b0;
        tx_fifo_wr_en   <=#U_DLY 1'b0;
    end
    else 
    begin
        tx_fifo_wr_data <=#U_DLY tx_data;
        tx_fifo_wr_en   <=#U_DLY tx_valid;
    end 
end    

assign tx_ready = (tx_fifo_wr_afull == 1'b0) ? 1'b1 : 1'b0;

asyn_fifo #(
    .U_DLY                      (U_DLY                      ),
    .DATA_WIDTH                 (8                          ),
    .DATA_DEEPTH                (128                        ),
    .ADDR_WIDTH                 (7                          )
)u_uart_tx_fifo(
    .wr_clk                     (sys_clk                     ),
    .wr_rst_n                   (sys_rst_n                   ),
    .rd_clk                     (sys_clk                     ),
    .rd_rst_n                   (sys_rst_n                   ),
    .din                        (tx_fifo_wr_data             ),
    .wr_en                      (tx_fifo_wr_en               ),
    .rd_en                      (tx_fifo_rd_en               ),
    .dout                       (tx_fifo_rd_data             ),
    .full                       (tx_fifo_wr_full             ),
    .prog_full                  (tx_fifo_wr_afull            ),
    .empty                      (tx_fifo_rd_empty            ),
    .prog_empty                 (                            ),
    .prog_full_thresh           (7'd120                      ),
    .prog_empty_thresh          (7'd1                        )
);

always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        tx_fifo_rd_en <=#U_DLY 1'b0;
    else if(tx_cur_state == TX_IDLE && tx_nxt_state == TX_SEND && tx_fifo_rd_empty == 1'b0)
        tx_fifo_rd_en <=#U_DLY 1'b1; 
    else
        tx_fifo_rd_en <=#U_DLY 1'b0;  
end     

//--------------------------------------------------------------------------
always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        tx_count_en <=#U_DLY 1'b0;
    else if(tx_cur_state == TX_IDLE || tx_nxt_state == TX_IDLE)
        tx_count_en <=#U_DLY 1'b0; 
    else
        tx_count_en <=#U_DLY 1'b1;  
end     

always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        tx_baud_cnt <=#U_DLY 16'h0;
    else if(tx_count_en == 1'b0 || tx_baud_cnt >= (tx_baudrate_num - 1'b1))
        tx_baud_cnt <=#U_DLY 16'h0; 
    else
        tx_baud_cnt <=#U_DLY tx_baud_cnt + 1'b1;  
end

always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        tx_baudrate_num <=#U_DLY 16'h0;  
    else
    begin
        case(BAUDRATE)
            2400    : tx_baudrate_num <=#U_DLY {CLK_DIV,4'b0};
            4800    : tx_baudrate_num <=#U_DLY {CLK_DIV,3'b0}; 
            9600    : tx_baudrate_num <=#U_DLY {CLK_DIV,2'b0}; 
            19200   : tx_baudrate_num <=#U_DLY {CLK_DIV,1'b0}; 
            38400   : tx_baudrate_num <=#U_DLY CLK_DIV; 
            115200  : tx_baudrate_num <=#U_DLY {4'h0,CLK_DIV}; 
            default : tx_baudrate_num <=#U_DLY {CLK_DIV,2'b0};
        endcase 
    end
end             

always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        send_bit_cnt <=#U_DLY 4'h0;
    else if(tx_baud_cnt >= (tx_baudrate_num-1'b1))
    begin
        if((send_bit_cnt >= 4'd9 && PARITY_TYPE == "no parity") || (send_bit_cnt >= 4'd10 && PARITY_TYPE != "no parity"))
            send_bit_cnt <=#U_DLY 4'h0; 
        else
            send_bit_cnt <=#U_DLY send_bit_cnt + 1'b1;
    end 
    else
        ;  
end

//--------------------------------------------------------------------
always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        tx_cur_state <=#U_DLY TX_IDLE;
    else 
        tx_cur_state <=#U_DLY tx_nxt_state;        
end

always @(*)
begin
    case(tx_cur_state)
    TX_IDLE:
    begin
    if(tx_fifo_rd_empty == 1'b0)
        tx_nxt_state = TX_SEND;
    else
        tx_nxt_state = TX_IDLE; 
    end
    TX_SEND:
    begin
    if(send_byte_done == 1'b1)
        tx_nxt_state = TX_IDLE;
    else
        tx_nxt_state = TX_SEND; 
    end
    default:tx_nxt_state = TX_IDLE; 
    endcase       
end

//-------------------------------------------------------------------------
always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        send_byte_done <=#U_DLY 1'b0;
    else if((tx_baud_cnt >= (tx_baudrate_num-1'b1)) && ((send_bit_cnt >= 4'd9 && PARITY_TYPE == "no parity") || (send_bit_cnt >= 4'd10 && (PARITY_TYPE == "odd parity" || PARITY_TYPE == "even parity"))))
        send_byte_done <=#U_DLY 1'b1;
    else 
        send_byte_done <=#U_DLY 1'b0;   
end

always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        tx_data_reg <=#U_DLY 8'h0;
    else if(tx_cur_state == TX_IDLE && tx_nxt_state == TX_SEND && tx_fifo_rd_empty == 1'b0) 
        tx_data_reg <=#U_DLY tx_fifo_rd_data; 
    else
        ;
end

always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        uart_tx <=#U_DLY 1'h1;
    else if(tx_count_en == 1'b1 && tx_cur_state == TX_SEND && tx_nxt_state == TX_SEND)
    begin
        if(PARITY_TYPE == "no parity")
        begin
            case(send_bit_cnt)
                4'd0:uart_tx <=#U_DLY 1'b0;//start
                4'd1:uart_tx <=#U_DLY tx_data_reg[0];//bit 0
                4'd2:uart_tx <=#U_DLY tx_data_reg[1];//bit 1 
                4'd3:uart_tx <=#U_DLY tx_data_reg[2];//bit 2 
                4'd4:uart_tx <=#U_DLY tx_data_reg[3];//bit 3 
                4'd5:uart_tx <=#U_DLY tx_data_reg[4];//bit 4  
                4'd6:uart_tx <=#U_DLY tx_data_reg[5];//bit 5 
                4'd7:uart_tx <=#U_DLY tx_data_reg[6];//bit 6 
                4'd8:uart_tx <=#U_DLY tx_data_reg[7];//bit 7 
                4'd9:uart_tx <=#U_DLY 1'b1;//stop 
                default:uart_tx <=#U_DLY 1'b1;
            endcase
        end
        else
        begin
            case(send_bit_cnt)
                4'd0:uart_tx <=#U_DLY 1'b0;//start
                4'd1:uart_tx <=#U_DLY tx_data_reg[0];//bit 0
                4'd2:uart_tx <=#U_DLY tx_data_reg[1];//bit 1 
                4'd3:uart_tx <=#U_DLY tx_data_reg[2];//bit 2 
                4'd4:uart_tx <=#U_DLY tx_data_reg[3];//bit 3 
                4'd5:uart_tx <=#U_DLY tx_data_reg[4];//bit 4  
                4'd6:uart_tx <=#U_DLY tx_data_reg[5];//bit 5 
                4'd7:uart_tx <=#U_DLY tx_data_reg[6];//bit 6 
                4'd8:uart_tx <=#U_DLY tx_data_reg[7];//bit 7 
                4'd9:
                begin
                    if(PARITY_TYPE == "odd parity")
                        uart_tx <=#U_DLY ~(^tx_data_reg);// odd parity
                    else
                        uart_tx <=#U_DLY ^tx_data_reg;// even parity
                end
                4'd10:uart_tx <=#U_DLY 1'b1;//stop 
                default:uart_tx <=#U_DLY 1'b1;
            endcase
        end
    end 
    else
        uart_tx <=#U_DLY 1'h1;    
end


endmodule  



