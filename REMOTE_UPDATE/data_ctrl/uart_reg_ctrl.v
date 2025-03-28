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
module uart_reg_ctrl
#(
parameter FPGA_VESION           = 48'h2000_0101_1200,   // year,month,day,hour,minute;
parameter USER_BITSTREAM_CNT    = 2'd3              ,
parameter U_DLY                 = 1
)(
input               sys_clk                 ,
input               sys_rst_n               ,

input       [7:0]   rx_data                 ,
input               rx_valid                ,

output reg  [7:0]   tx_data                 ,
output reg          tx_valid                ,
input               tx_ready                ,

output              status_rd_en            ,
input       [15:0]  status_erorr            ,//other module erorr info , uart read for debug
//debug
input       [15:0]  flash_flag_status       ,
input               time_out_reg            ,

input               flash_rd_en             ,
input               flash_wr_en             ,

input       [7:0]   flash_rd_data           ,
input               flash_rd_valid          ,
output              flash_rd_data_fifo_afull,

output              clear_sw_en_out         ,
output              open_sw_en_out          ,
output      [1:0]   open_sw_num_out         ,
output              bitstream_up2cpu_en_out ,
output              crc_check_en_out        ,
input       [31:0]  bs_readback_crc         ,
input               bs_readback_crc_valid   ,
output      [1:0]   bs_crc32_ok             ,//[1]:valid   [0]:1'b0,OK  1'b1,error

output              flash_cfg_cmd_en        ,
output      [7:0]   flash_cfg_cmd           ,
output      [15:0]  flash_cfg_reg_wrdata    ,
input               flash_cfg_reg_rd_en     ,
input       [15:0]  flash_cfg_reg_rddata    ,

input               ipal_busy               ,
output              hotreset_en_out         ,
input               open_sw_code_done       ,
input               clear_sw_done           ,
input               clear_bs_done           ,
input               bitstream_wr_done       ,
input       [1:0]   bitstream_wr_num        ,     
input       [1:0]   bitstream_rd_num           
);
//-----------------------------------------------------------
// 
//-----------------------------------------------------------
localparam   HEAD_CODE  = 32'he7e7_e7e7         ;
localparam   TX_CODE    = 8'h55                 ;
//-----------------------------------------------------------
reg         [31:0]  crc32_temp                  ;
reg                 crc32_reg_ind               ;
reg         [3:0]   crc32_reg_valid             ;
reg                 crc32_error_ind             ;
reg                 bs_readback_crc_valid_1dly  ;
reg         [31:0]  bs_readback_crc_reg         ;
reg                 crc_check_en                ;
reg                 bitstream_up2cpu_en         ;

reg         [39:0]  uart_data_temp              ;

reg         [15:0]  rd_config_data              ;
reg                 rd_config_valid             ;

reg         [7:0]   uart_test_reg               ;
reg                 hotreset_en                 ;
reg         [1:0]   open_sw_num                 ;// 2'd1,2'd2,2d3 & open_sw_num<=USER_BITSTREAM_CNT
reg                 open_sw_en                  ;
reg                 clear_sw_en                 ;

reg                 clear_bs_done_dly           ;
reg                 bitstream_wr_done_dly       ;
reg                 time_out_reg_dly            ;
reg                 clear_sw_done_dly           ;
reg                 open_sw_code_done_dly       ;

reg                 cfg_cmd_en                  ;
reg         [7:0]   cfg_cmd                     ;
reg         [15:0]  cfg_reg_wrdata              ;

reg                 status_rd_en_pre2           ;
reg                 status_rd_en_pre1           ;

//------------------------------------------------------
reg         [7:0]   flash_rd_data_fifo_wr_data  ; 
reg                 flash_rd_data_fifo_wr_en    ;
wire                flash_rd_data_fifo_rd_en    ;
wire        [7:0]   flash_rd_data_fifo_rd_data  ;
wire                flash_rd_data_fifo_full     ;
wire                flash_rd_data_fifo_empty    ;

reg         [ 3:0]  uart_cfg_sned_cnt           ;
reg         [15:0]  uart_cfg_fifo_wr_data       ;
reg                 uart_cfg_fifo_wr_en         ;
reg                 uart_cfg_fifo_rd_en         ;
wire                uart_cfg_fifo_wr_full       ;
wire                uart_cfg_fifo_wr_afull      ;
wire                uart_cfg_fifo_rd_empty      ;
wire        [15:0]  uart_cfg_fifo_rd_data       ;

wire        [7:0]   status_reg                  ;
//------------------------------------------------------------------------------
assign flash_cfg_cmd_en             = cfg_cmd_en            ;    
assign flash_cfg_cmd                = cfg_cmd               ;       
assign flash_cfg_reg_wrdata         = cfg_reg_wrdata        ;
assign hotreset_en_out              = hotreset_en           ;
assign crc_check_en_out             = crc_check_en          ;
assign bitstream_up2cpu_en_out      = bitstream_up2cpu_en   ;
assign open_sw_num_out              = open_sw_num           ;
assign open_sw_en_out               = open_sw_en            ;
assign clear_sw_en_out              = clear_sw_en           ;
//------------------------------------------------------------------------------
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        uart_data_temp  <=#U_DLY 40'h0;
    else if(rx_valid == 1'b1) 
        uart_data_temp  <=#U_DLY {uart_data_temp[31:0],rx_data};
    else
        ;

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        status_rd_en_pre1 <=#U_DLY 1'b0;
    else
        status_rd_en_pre1 <=#U_DLY status_rd_en_pre2;

assign status_rd_en = (status_rd_en_pre2 == 1'b1 && status_rd_en_pre1 == 1'b0) ? 1'b1 : 1'b0;

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
    begin
        uart_test_reg       <=#U_DLY 8'b0;
        hotreset_en         <=#U_DLY 1'b0;
        crc_check_en        <=#U_DLY 1'b0;
        bitstream_up2cpu_en <=#U_DLY 1'b0; 
        open_sw_num         <=#U_DLY 2'b1;
        open_sw_en          <=#U_DLY 1'b0;
        clear_sw_en         <=#U_DLY 1'b0;

        status_rd_en_pre2   <=#U_DLY 1'b0;
        cfg_cmd             <=#U_DLY 8'b0;
        cfg_reg_wrdata      <=#U_DLY 16'b0;
    end
    else if(uart_data_temp[39:8] == HEAD_CODE && uart_data_temp[7] == 1'b0 && rx_valid == 1'b1) // CPU wr config reg 
    begin
        case(uart_data_temp[6:0])
            7'h02 : uart_test_reg           <=#U_DLY rx_data;
            7'h04 : hotreset_en             <=#U_DLY rx_data[0];
            7'h06 : crc_check_en            <=#U_DLY rx_data[0];
            7'h0c : bitstream_up2cpu_en     <=#U_DLY rx_data[0];
            7'h0e : {open_sw_en,clear_sw_en,open_sw_num}<=#U_DLY {rx_data[6],rx_data[4],rx_data[1:0]};

            7'h30 : status_rd_en_pre2       <=#U_DLY rx_data[0];
            7'h33 : cfg_cmd                 <=#U_DLY rx_data;
            7'h34 : cfg_reg_wrdata[7:0]     <=#U_DLY rx_data;
            7'h35 : cfg_reg_wrdata[15:8]    <=#U_DLY rx_data;
            default: ;
        endcase
    end
    else
        ;


always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        crc32_reg_ind      <=#U_DLY 1'b0;
    else if(uart_data_temp[31:0] == HEAD_CODE && rx_data == 8'h01 && rx_valid == 1'b1) 
        crc32_reg_ind      <=#U_DLY 1'b1;
    else
        crc32_reg_ind      <=#U_DLY 1'b0;

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cfg_cmd_en      <=#U_DLY 1'b0;
    else if(uart_data_temp[31:0] == HEAD_CODE && rx_data == 8'h33 && rx_valid == 1'b1) // CPU wr config reg 
        cfg_cmd_en      <=#U_DLY 1'b1;
    else
        cfg_cmd_en      <=#U_DLY 1'b0;


always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        crc32_reg_valid      <=#U_DLY 4'b0;
    else if(crc32_reg_ind == 1'b1)
        crc32_reg_valid      <=#U_DLY 4'b1;
    else if(rx_valid == 1'b1)
        crc32_reg_valid      <=#U_DLY {crc32_reg_valid[2:0],1'b0};
    else
        ;

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        crc32_temp      <=#U_DLY 32'b0;
    else if(crc32_reg_valid != 4'b0 && rx_valid == 1'b1)
        crc32_temp      <=#U_DLY {crc32_temp[23:0],rx_data};
    else
        ;

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        crc32_error_ind      <=#U_DLY 1'b0;
    else if(flash_rd_en == 1'b1)
        crc32_error_ind      <=#U_DLY 1'b0;
    else if(bs_readback_crc_valid == 1'b1)
    begin
        if(crc32_temp == bs_readback_crc || crc_check_en == 1'b0)//crc32 check ok,or crc32 check not enable(data_process.v line 419)
            crc32_error_ind      <=#U_DLY 1'b0;
        else
            crc32_error_ind      <=#U_DLY 1'b1;
    end
    else
        ;

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        bs_readback_crc_valid_1dly  <=#U_DLY 1'b0;
    else 
        bs_readback_crc_valid_1dly  <=#U_DLY bs_readback_crc_valid;

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        bs_readback_crc_reg  <=#U_DLY 32'b0;
    else if(bs_readback_crc_valid == 1'b1)
        bs_readback_crc_reg  <=#U_DLY bs_readback_crc;
    else
        ;

assign bs_crc32_ok = {bs_readback_crc_valid_1dly,crc32_error_ind};

//--------------------------------------------------------------------------------------
// UART read config info
//--------------------------------------------------------------------------------------
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
    begin
        rd_config_data      <=#U_DLY 16'b0;
        rd_config_valid     <=#U_DLY 1'b0;
    end
    else if(uart_data_temp[31:0] == HEAD_CODE && rx_data[7] == 1'b1 && rx_valid == 1'b1) // CPU rd config reg
    begin
        
        case(rx_data[6:0])
            
            7'h00 : 
            begin
                rd_config_data  <=#U_DLY {8'h00,FPGA_VESION[47:40]};                    // addr=8'h00  fpga_version
                rd_config_valid <=#U_DLY 1'b1;
            end
            7'h01 : 
            begin
                rd_config_data  <=#U_DLY {8'h01,crc32_temp[31:24]};                     // addr=8'h01  bitstream crc32
                rd_config_valid <=#U_DLY 1'b1;
            end
            7'h02 : 
            begin
                rd_config_data  <=#U_DLY {8'h02,uart_test_reg};                         // addr=8'h02  test register
                rd_config_valid <=#U_DLY 1'b1;
            end
            7'h03 : 
            begin
                rd_config_data  <=#U_DLY {8'h03,7'h0,crc32_error_ind};                  // addr=8'h03  crc32 error ind
                rd_config_valid <=#U_DLY 1'b1;
            end
            7'h04 : 
            begin 
                rd_config_data  <=#U_DLY {8'h04,7'b0,hotreset_en};                      // addr=8'h04  data={7'b0,hotreset_en}
                rd_config_valid <=#U_DLY 1'b1;
            end
            7'h05 : 
            begin
                rd_config_data  <=#U_DLY {8'h05,3'b0,bitstream_wr_done,time_out_reg,open_sw_code_done,clear_sw_done,clear_bs_done}; // addr=8'h05  data={7'b0,bitstream_wr_done}
                rd_config_valid <=#U_DLY 1'b1;
            end 
            7'h06 : 
            begin
                rd_config_data  <=#U_DLY {8'h06,7'b0,crc_check_en};    
                rd_config_valid <=#U_DLY 1'b1;
            end
            7'h07 : 
            begin
                rd_config_data  <=#U_DLY {8'h07,6'b0,USER_BITSTREAM_CNT};    
                rd_config_valid <=#U_DLY 1'b1;
            end
            7'h08 : 
            begin
                rd_config_data  <=#U_DLY {8'h08,bs_readback_crc_reg[7:0]};     
                rd_config_valid <=#U_DLY 1'b1;
            end
            7'h09 : 
            begin
                rd_config_data  <=#U_DLY {8'h09,bs_readback_crc_reg[15:8]};    
                rd_config_valid <=#U_DLY 1'b1;
            end
            7'h0a : 
            begin
                rd_config_data  <=#U_DLY {8'h0a,bs_readback_crc_reg[23:16]};     
                rd_config_valid <=#U_DLY 1'b1;
            end
            7'h0b : 
            begin
                rd_config_data  <=#U_DLY {8'h0b,bs_readback_crc_reg[31:24]};    
                rd_config_valid <=#U_DLY 1'b1;
            end
            7'h0c : 
            begin
                rd_config_data  <=#U_DLY {8'h0c,7'b0,bitstream_up2cpu_en};    
                rd_config_valid <=#U_DLY 1'b1;
            end
            7'h0d : 
            begin
                rd_config_data  <=#U_DLY {8'h0d,flash_rd_data_fifo_full,ipal_busy,2'b0,bitstream_wr_num,bitstream_rd_num};    // addr=8'h0d  data={4'b0,bitstream_wr_num,bitstream_rd_num}
                rd_config_valid <=#U_DLY 1'b1;
            end
            7'h0e : 
            begin
                rd_config_data  <=#U_DLY {8'h0e,1'b0,open_sw_en,1'b0,clear_sw_en,2'b0,open_sw_num}; 
                rd_config_valid <=#U_DLY 1'b1;
            end     
            7'h30 : 
            begin 
                rd_config_data  <=#U_DLY {8'h30,7'b0,status_rd_en_pre2};                // addr=8'h30  data={7'b0,status_rd_en_pre2}
                rd_config_valid <=#U_DLY 1'b1;
            end
            7'h31 : 
            begin
                rd_config_data  <=#U_DLY {8'h31,status_erorr[7:0]};                     // addr=8'h31  data={status_erorr[7:0]}
                rd_config_valid <=#U_DLY 1'b1;
            end
            7'h32 : 
            begin
                rd_config_data  <=#U_DLY {8'h32,status_erorr[15:8]};                    // addr=8'h32  data={status_erorr[15:8]}
                rd_config_valid <=#U_DLY 1'b1;
            end
            7'h33 : 
            begin
                rd_config_data  <=#U_DLY {8'h33,cfg_cmd};                               // addr=8'h33  data=cfg_cmd
                rd_config_valid <=#U_DLY 1'b1;
            end
            7'h34 : 
            begin
                rd_config_data  <=#U_DLY {8'h34,cfg_reg_wrdata[7:0]};                   // addr=8'h34  data=cfg_reg_wrdata[7:0]
                rd_config_valid <=#U_DLY 1'b1;
            end
            7'h35 : 
            begin
                rd_config_data  <=#U_DLY {8'h35,cfg_reg_wrdata[15:8]};                  // addr=8'h35  data=cfg_reg_wrdata[15:8]
                rd_config_valid <=#U_DLY 1'b1;
            end
            7'h36 : 
            begin
                rd_config_data  <=#U_DLY {8'h36,flash_cfg_reg_rddata[7:0]};             // addr=8'h36  data=flash_cfg_reg_rddata[7:0]
                rd_config_valid <=#U_DLY 1'b1;
            end
            7'h37 : 
            begin
                rd_config_data  <=#U_DLY {8'h37,flash_cfg_reg_rddata[15:8]};            // addr=8'h37  data=flash_cfg_reg_rddata[15:8]
                rd_config_valid <=#U_DLY 1'b1;
            end
            7'h38 : 
            begin
                rd_config_data  <=#U_DLY {8'h38,flash_flag_status[7:0]};     
                rd_config_valid <=#U_DLY 1'b1;
            end
            7'h39 : 
            begin
                rd_config_data  <=#U_DLY {8'h39,flash_flag_status[15:8]};    
                rd_config_valid <=#U_DLY 1'b1;
            end
            default:
            begin 
                rd_config_data  <=#U_DLY {8'hff,8'b0};                                  // read addr error
                rd_config_valid <=#U_DLY 1'b0;
            end  
        endcase 
    end
    else if(flash_cfg_reg_rd_en == 1'b1)
    begin
        rd_config_data      <=#U_DLY {8'h37,flash_cfg_reg_rddata[15:8]}; 
        rd_config_valid     <=#U_DLY 1'b1;
    end 
    else if(clear_bs_done_dly == 1'b0 && clear_bs_done == 1'b1)
    begin
        rd_config_data      <=#U_DLY {8'h05,8'h01};
        rd_config_valid     <=#U_DLY 1'b1;
    end
    else if(clear_sw_done_dly == 1'b0 && clear_sw_done == 1'b1)
    begin
        rd_config_data      <=#U_DLY {8'h05,8'h02};
        rd_config_valid     <=#U_DLY 1'b1;
    end
    else if(open_sw_code_done_dly == 1'b0 && open_sw_code_done == 1'b1)
    begin
        rd_config_data      <=#U_DLY {8'h05,8'h04};
        rd_config_valid     <=#U_DLY 1'b1;
    end
    else if(bitstream_wr_done_dly == 1'b0 && bitstream_wr_done == 1'b1)
    begin
        rd_config_data      <=#U_DLY {8'h05,8'h10};
        rd_config_valid     <=#U_DLY 1'b1;
    end
    else if(time_out_reg_dly == 1'b0 && time_out_reg == 1'b1)
    begin
        rd_config_data      <=#U_DLY {8'h05,8'h08};
        rd_config_valid     <=#U_DLY 1'b1;
    end
    else if(bs_readback_crc_valid == 1'b1)
    begin
        if(crc32_temp == bs_readback_crc)
            rd_config_data      <=#U_DLY {8'h03,8'h00};
        else 
            rd_config_data      <=#U_DLY {8'h03,8'h01};

        rd_config_valid     <=#U_DLY 1'b1;
    end  
    else
    begin
        rd_config_data      <=#U_DLY 16'b0;
        rd_config_valid     <=#U_DLY 1'b0;
    end

always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
    begin
        clear_bs_done_dly       <=#U_DLY 1'b0;
        bitstream_wr_done_dly   <=#U_DLY 1'b0;
        time_out_reg_dly        <=#U_DLY 1'b0;
        clear_sw_done_dly       <=#U_DLY 1'b0;
        open_sw_code_done_dly   <=#U_DLY 1'b0;
    end
    else
    begin
        clear_bs_done_dly       <=#U_DLY clear_bs_done;
        bitstream_wr_done_dly   <=#U_DLY bitstream_wr_done;
        time_out_reg_dly        <=#U_DLY time_out_reg;
        clear_sw_done_dly       <=#U_DLY clear_sw_done;
        open_sw_code_done_dly   <=#U_DLY open_sw_code_done;
    end
end


always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
    begin
        uart_cfg_fifo_wr_data   <=#U_DLY 16'b0;
        uart_cfg_fifo_wr_en     <=#U_DLY 1'b0;
    end
    else if(uart_cfg_fifo_wr_afull == 1'b0)
    begin
        uart_cfg_fifo_wr_data   <=#U_DLY rd_config_data;
        uart_cfg_fifo_wr_en     <=#U_DLY rd_config_valid;
    end 
    else
    begin
        uart_cfg_fifo_wr_data   <=#U_DLY 16'b0;
        uart_cfg_fifo_wr_en     <=#U_DLY 1'b0;
    end  
end    


asyn_fifo #(
    .U_DLY                      (U_DLY                       ),
    .DATA_WIDTH                 (16                          ),
    .DATA_DEEPTH                (32                          ),
    .ADDR_WIDTH                 (5                           )
)u_uart_tx_fifo(
    .wr_clk                     (sys_clk                     ),
    .wr_rst_n                   (sys_rst_n                   ),
    .rd_clk                     (sys_clk                     ),
    .rd_rst_n                   (sys_rst_n                   ),
    .din                        (uart_cfg_fifo_wr_data       ),
    .wr_en                      (uart_cfg_fifo_wr_en         ),
    .rd_en                      (uart_cfg_fifo_rd_en         ),
    .dout                       (uart_cfg_fifo_rd_data       ),
    .full                       (uart_cfg_fifo_wr_full       ),
    .prog_full                  (uart_cfg_fifo_wr_afull      ),
    .empty                      (uart_cfg_fifo_rd_empty      ),
    .prog_empty                 (                            ),
    .prog_full_thresh           (5'd28                       ),
    .prog_empty_thresh          (5'd1                        )
);

always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        uart_cfg_fifo_rd_en   <=#U_DLY 1'b0;
    else if(tx_ready == 1'b1 && uart_cfg_fifo_rd_empty == 1'b0 && ((uart_cfg_sned_cnt >= 4'd4 && uart_cfg_fifo_rd_data[15:8] >= 8'h2) || uart_cfg_sned_cnt >= 4'd8))
        uart_cfg_fifo_rd_en   <=#U_DLY 1'b1;
    else
        uart_cfg_fifo_rd_en   <=#U_DLY 1'b0;
end


always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        uart_cfg_sned_cnt   <=#U_DLY 4'b0;
    else if(tx_ready == 1'b1 && uart_cfg_fifo_rd_empty == 1'b0 && flash_rd_data_fifo_empty == 1'b1)
    begin
        if ((uart_cfg_sned_cnt >= 4'd4 && uart_cfg_fifo_rd_data[15:8] >= 8'h2) || uart_cfg_sned_cnt >= 4'd8)
            uart_cfg_sned_cnt   <=#U_DLY 4'b0;
        else 
            uart_cfg_sned_cnt   <=#U_DLY uart_cfg_sned_cnt +1'b1;
    end
    else
        ;
end

//-------------------------------------------------------------------------------------------------------

//read memory data or read flash id 
always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)   
    begin  
       flash_rd_data_fifo_wr_data   <=#U_DLY 8'b0; 
       flash_rd_data_fifo_wr_en     <=#U_DLY 1'b0;
    end 
    else 
    begin  
       flash_rd_data_fifo_wr_data   <=#U_DLY flash_rd_data; 
       flash_rd_data_fifo_wr_en     <=#U_DLY flash_rd_valid;
    end 
end

asyn_fifo #(
    .U_DLY                      (1                           ),
    .DATA_WIDTH                 (8                           ),
    .DATA_DEEPTH                (512                         ),
    .ADDR_WIDTH                 (9                           )
)u_rd_data_fifo(
    .wr_clk                     (sys_clk                     ),
    .wr_rst_n                   (sys_rst_n                   ),
    .rd_clk                     (sys_clk                     ),
    .rd_rst_n                   (sys_rst_n                   ),
    .din                        (flash_rd_data_fifo_wr_data  ),
    .wr_en                      (flash_rd_data_fifo_wr_en    ),
    .rd_en                      (flash_rd_data_fifo_rd_en    ),
    .dout                       (flash_rd_data_fifo_rd_data  ),
    .full                       (flash_rd_data_fifo_full     ),
    .prog_full                  (flash_rd_data_fifo_afull    ),
    .empty                      (flash_rd_data_fifo_empty    ),
    .prog_empty                 (                            ),
    .prog_full_thresh           (9'd256                      ),
    .prog_empty_thresh          (9'd1                        )
);

assign flash_rd_data_fifo_rd_en = (tx_ready == 1'b1 && flash_rd_data_fifo_empty == 1'b0) ? 1'b1 : 1'b0; // read flash_rd_data_fifo after uart_cfg_fifo is empty 

//-------------------------------------------------------------------------------------------------------

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
    begin
        tx_data   <=#U_DLY 8'b0;
        tx_valid  <=#U_DLY 1'b0;
    end
    else if(tx_ready == 1'b1 && flash_rd_data_fifo_empty == 1'b0)
    begin
        tx_data   <=#U_DLY flash_rd_data_fifo_rd_data;
        tx_valid  <=#U_DLY 1'b1;
    end
    else if(tx_ready == 1'b1 && uart_cfg_fifo_rd_empty == 1'b0)
    begin
        case(uart_cfg_sned_cnt)
            4'd1:// tx head 
            begin
                tx_data   <=#U_DLY TX_CODE;
                tx_valid  <=#U_DLY 1'b1;
            end
            4'd2:// reg addr 
            begin
                tx_data   <=#U_DLY uart_cfg_fifo_rd_data[15:8];
                tx_valid  <=#U_DLY 1'b1;
            end
            4'd3:// data byte 1 
            begin
                tx_data   <=#U_DLY uart_cfg_fifo_rd_data[7:0];
                tx_valid  <=#U_DLY 1'b1;
            end
            4'd4:
            begin
                if(uart_cfg_fifo_rd_data[15:8] == 8'hf)             //read flash config register
                    tx_data   <=#U_DLY flash_cfg_reg_rddata[7:0];
                else if(uart_cfg_fifo_rd_data[15:8] == 8'h0)        // read fpga version
                    tx_data   <=#U_DLY FPGA_VESION[39:32];
                else 
                    tx_data   <=#U_DLY crc32_temp[23:16];           // read crc temp

                if(uart_cfg_fifo_rd_data[15:8] <= 8'h1 || uart_cfg_fifo_rd_data[15:8] == 8'hf)// read fpga version or crc temp
                    tx_valid  <=#U_DLY 1'b1;
                else
                    tx_valid  <=#U_DLY 1'b0;
            end
            4'd5: 
            begin
                if(uart_cfg_fifo_rd_data[15:8] == 8'h0)             // read fpga version
                    tx_data   <=#U_DLY FPGA_VESION[31:24];
                else
                    tx_data   <=#U_DLY crc32_temp[15:8];            // read crc temp

                if(uart_cfg_fifo_rd_data[15:8] <= 8'h1)             // read fpga version or crc temp
                    tx_valid  <=#U_DLY 1'b1;
                else
                    tx_valid  <=#U_DLY 1'b0;
            end
            4'd6:
            begin
                if(uart_cfg_fifo_rd_data[15:8] == 8'h0)             // read fpga version
                    tx_data   <=#U_DLY FPGA_VESION[23:16];
                else
                    tx_data   <=#U_DLY crc32_temp[7:0];             // read crc temp

                if(uart_cfg_fifo_rd_data[15:8] <= 8'h1)             // read fpga version or crc temp
                    tx_valid  <=#U_DLY 1'b1;
                else
                    tx_valid  <=#U_DLY 1'b0;
            end
            4'd7:
            begin
                tx_data   <=#U_DLY FPGA_VESION[15:8];
                if(uart_cfg_fifo_rd_data[15:8] == 8'h0)             // read fpga version
                    tx_valid  <=#U_DLY 1'b1;
                else
                    tx_valid  <=#U_DLY 1'b0;
            end
            4'd8:
            begin
                tx_data   <=#U_DLY FPGA_VESION[7:0];
                if(uart_cfg_fifo_rd_data[15:8] == 8'h0)             // read fpga version
                    tx_valid  <=#U_DLY 1'b1;
                else
                    tx_valid  <=#U_DLY 1'b0;
            end
            default:
            begin
                tx_data   <=#U_DLY tx_data;
                tx_valid  <=#U_DLY 1'b0;
            end
        endcase
    end
    else
    begin
        tx_data   <=#U_DLY tx_data;
        tx_valid  <=#U_DLY 1'b0;
    end


endmodule
