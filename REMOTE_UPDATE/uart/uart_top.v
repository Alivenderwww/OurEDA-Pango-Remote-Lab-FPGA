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
module uart_top #(
parameter   BAUDRATE    =  115200       , // 2400 , 4800 , 9600 , 19200 , 38400 , 115200
parameter   CLK_DIV     =  12'd868      , // (1000000000ns/10ns)/115200 = 868.06
parameter   PARITY_TYPE = "no parity"   , //"no parity" , "odd parity" , "even parity"
parameter   U_DLY       =  1
)(
input               sys_clk                 ,   
input               sys_rst_n               ,   

output     [7:0]    rx_data                 ,
output              rx_valid                ,

input      [7:0]    tx_data                 ,
input               tx_valid                ,
output              tx_ready                ,

input               uart_rx                 ,   
output              uart_tx                    
);

uart_tx_ctrl#(
    .BAUDRATE                   (BAUDRATE                   ),
    .CLK_DIV                    (CLK_DIV                    ),
    .PARITY_TYPE                (PARITY_TYPE                ),
    .U_DLY                      (U_DLY                      )
)
u_uart_tx(
    .sys_clk                    (sys_clk                    ),
    .sys_rst_n                  (sys_rst_n                  ),

    .tx_data                    (tx_data                    ),
    .tx_valid                   (tx_valid                   ),
    .tx_ready                   (tx_ready                   ),

    .uart_tx                    (uart_tx                    )
);

uart_rx_ctrl#(
    .BAUDRATE                   (BAUDRATE                   ),
    .CLK_DIV                    (CLK_DIV                    ),
    .PARITY_TYPE                (PARITY_TYPE                ),
    .U_DLY                      (U_DLY                      )
)
u_uart_rx(
    .sys_clk                    (sys_clk                    ),
    .sys_rst_n                  (sys_rst_n                  ),

    .rx_data                    (rx_data                    ),
    .rx_valid                   (rx_valid                   ),

    .uart_rx                    (uart_rx                    )
);

endmodule  



