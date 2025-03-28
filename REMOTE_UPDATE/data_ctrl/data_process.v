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
module data_process
#(
parameter USER_BITSTREAM_CNT    = 2'd3              ,
parameter U_DLY                 = 1
)(
input               sys_clk                 ,
input               sys_rst_n               ,

input       [7:0]   rx_data                 ,
input               rx_valid                ,

output              flash_wr_en             ,
output              flash_rd_en             ,
output      [1:0]   bitstream_wr_num        ,
output      [1:0]   bitstream_rd_num        ,

input               clear_bs_done           ,
input       [1:0]   bs_crc32_ok             ,//[1]:valid   [0]:1'b0,OK  1'b1,error
input               crc_check_en            ,
input               write_sw_code_en        ,
input       [1:0]   write_sw_code_num       ,

input               data_status_rd_en       ,
output      [7:0]   data_status_erorr       ,// erorr info , uart read for debug

input               bitstream_fifo_rd_req   ,
output      [7:0]   bitstream_data          ,
output              bitstream_valid         ,
output              bitstream_eop           ,
output              bitstream_fifo_rd_rdy  
);
//-----------------------------------------------------------
localparam   HEAD_CODE  = 32'he7e7_e7e7         ;
localparam   TAIL_CODE  = 32'h7e7e_7e7e         ;


localparam   DATA_IDLE          = 5'b0_0001    ;
localparam   DATA_BITSTREAM     = 5'b0_0010    ;
localparam   DATA_FILL          = 5'b0_0100    ;
localparam   DATA_SWITCH_CODE   = 5'b0_1000    ;
localparam   DATA_DONE          = 5'b1_0000    ;
//-----------------------------------------------------------
// 
//-----------------------------------------------------------
reg         [4:0]   data_cur_state              ;
reg         [4:0]   data_nxt_state              ;

reg         [31:0]  rx_data_temp                ;
reg         [3:0]   rx_valid_temp               ;

reg         [7:0]   uart_rx_fifo_wr_data        ; 
reg                 uart_rx_fifo_wr_en          ;
wire                uart_rx_fifo_rd_en          ;
wire        [7:0]   uart_rx_fifo_rd_data        ;
wire                uart_rx_fifo_wr_full        ;
wire                uart_rx_fifo_wr_afull       ;
wire                uart_rx_fifo_rd_empty       ;

reg                 bitstream_wr_start_pre      ;
reg                 bitstream_wr_start_pre_dly  ;
reg         [3:0]   bitstream_wr_start          ;
reg                 bitstream_rd_start          ;
reg                 bitstream_end               ;
reg         [1:0]   bs_wr_num                   ;
reg         [1:0]   bs_rd_num                   ;
reg                 bitstream_wr_flag           ;

reg         [1:0]   bs_switch_open_cnt          ;

wire                open_sw_code_ind            ;
wire                write_sw_code_en_pos        ;
reg                 write_sw_code_en_dly        ; 
reg                 crc32_ok_ind                ;
reg                 init_done                   ;
reg         [3:0]   init_count                  ;

reg                 his_uart_rx_fifo_wr_full    ;
reg                 his_bs_fifo_wr_full         ;
reg                 his_bs_fifo_rd_err          ;

reg         [3:0]   subsector_page_cnt          ;
reg         [7:0]   bs_fifo_wr_cnt              ;
reg         [7:0]   bs_fifo_wr_data             ;
reg                 bs_fifo_wr_en               ;
wire                bs_fifo_wr_eop              ;
wire                bs_fifo_wr_full             ;
wire                bs_fifo_wr_afull            ;
wire                bs_fifo_rd_rdy              ;
wire                bs_fifo_rd_req              ;
wire                bs_fifo_rd_en               ;
wire                bs_fifo_rd_valid            ;
wire                bs_fifo_rd_eop              ;
wire                bs_fifo_rd_empty            ;
wire        [7:0]   bs_fifo_rd_data             ;
wire                bs_fifo_rd_err              ;
wire        [8:0]   bs_ram_wdata                ;
wire        [9:0]   bs_ram_waddr                ;
wire                bs_ram_wen                  ;
wire        [9:0]   bs_ram_raddr                ;
wire        [8:0]   bs_ram_rdata                ;
wire                bs_ram_rcken                ;

//----------------------------------------------------------------------------------------------------------------------------------------------------
assign flash_wr_en       = (bitstream_wr_start_pre == 1'b1 && bitstream_wr_start_pre_dly == 1'b0 && bs_wr_num <= USER_BITSTREAM_CNT) ? 1'b1 : 1'b0; 
assign flash_rd_en       = (bs_rd_num <= USER_BITSTREAM_CNT) ? bitstream_rd_start : 1'b0; 
assign data_status_erorr = {5'b0,his_uart_rx_fifo_wr_full,his_bs_fifo_wr_full,his_bs_fifo_rd_err};
//----------------------------------------------------------------------------------------------------------------------------------------------------
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
    begin
        his_uart_rx_fifo_wr_full    <=#U_DLY 1'b0;
        his_bs_fifo_wr_full         <=#U_DLY 1'b0;
        his_bs_fifo_rd_err          <=#U_DLY 1'b0;
    end
    else if(data_status_rd_en == 1'b1)
    begin
        his_uart_rx_fifo_wr_full    <=#U_DLY 1'b0;
        his_bs_fifo_wr_full         <=#U_DLY 1'b0;
        his_bs_fifo_rd_err          <=#U_DLY 1'b0;
    end
    else 
    begin
        if(uart_rx_fifo_wr_full == 1'b1)
            his_uart_rx_fifo_wr_full    <=#U_DLY 1'b1;
        else
            ;

        if(bs_fifo_wr_full == 1'b1)
            his_bs_fifo_wr_full    <=#U_DLY 1'b1;
        else
            ;

        if(bs_fifo_rd_err == 1'b1)
            his_bs_fifo_rd_err    <=#U_DLY 1'b1;
        else
            ;
    end
  

//-----------------------------------------------------------
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        rx_data_temp  <=#U_DLY 32'h0;
    else if(rx_valid == 1'b1) 
        rx_data_temp  <=#U_DLY {rx_data_temp[23:0],rx_data};
    else
        ;

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        rx_valid_temp  <=#U_DLY 4'h0;
    else  
        rx_valid_temp  <=#U_DLY {rx_valid_temp[2:0],rx_valid};
    

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
    begin
        bs_wr_num               <=#U_DLY 2'b0;
        bitstream_wr_start_pre  <=#U_DLY 1'b0;
    end
    else if(rx_data_temp[31:0] == HEAD_CODE && rx_data[7:4] == 4'h1 && rx_valid == 1'b1)// CPU wr bitstream start ind  
    begin
        bitstream_wr_start_pre  <=#U_DLY 1'b1;
        bs_wr_num               <=#U_DLY rx_data[1:0];                                  // addr : 0x11,0x12.0x13
    end
    else
    begin
        bs_wr_num               <=#U_DLY bs_wr_num;
        
        if(bitstream_wr_start[3] == 1'b1)
            bitstream_wr_start_pre <=#U_DLY 1'b0;
        else
            ;
    end

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        bitstream_wr_start_pre_dly  <=#U_DLY 1'b0;
    else
        bitstream_wr_start_pre_dly  <=#U_DLY bitstream_wr_start_pre;


always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
    begin
        bitstream_wr_start      <=#U_DLY 4'b0;
    end
    else if(rx_valid == 1'b1)
    begin   
        bitstream_wr_start      <=#U_DLY {bitstream_wr_start[2:0],bitstream_wr_start_pre};
    end
    else
        ;

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
    begin
        bs_rd_num           <=#U_DLY 2'b0;
        bitstream_rd_start  <=#U_DLY 1'b0;
    end
    else if(rx_data_temp[31:0] == HEAD_CODE && rx_data[7:4] == 4'h5 && rx_valid == 1'b1)// CPU rd bitstream start ind  
    begin
        bitstream_rd_start  <=#U_DLY 1'b1;
        bs_rd_num           <=#U_DLY rx_data[1:0];                                      // addr : 0x51,0x52.0x53
    end
    else
    begin
        bs_rd_num           <=#U_DLY bs_rd_num;
        bitstream_rd_start  <=#U_DLY 1'b0;
    end

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        bitstream_end  <=#U_DLY 1'b0;
    else if({rx_data_temp[23:0],rx_data} == TAIL_CODE && rx_valid == 1'b1)   
        bitstream_end  <=#U_DLY 1'b1;
    else
        bitstream_end  <=#U_DLY 1'b0;


always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        bitstream_wr_flag <= 1'b0;
    else if(bitstream_wr_start[3] == 1'b1 && bs_wr_num <= USER_BITSTREAM_CNT)
        bitstream_wr_flag <= 1'b1;
    else if(bitstream_end == 1'b1)
        bitstream_wr_flag <= 1'b0;
    else 
        ;

always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
    begin
        uart_rx_fifo_wr_data <=#U_DLY 8'b0;
        uart_rx_fifo_wr_en   <=#U_DLY 1'b0;
    end
    else if(bitstream_wr_flag == 1'b1 && clear_bs_done == 1'b1)
    begin
        uart_rx_fifo_wr_data <=#U_DLY rx_data_temp[31:24];
        uart_rx_fifo_wr_en   <=#U_DLY rx_valid_temp[3];
    end 
    else
    begin
        uart_rx_fifo_wr_data <=#U_DLY 8'b0;
        uart_rx_fifo_wr_en   <=#U_DLY 1'b0;
    end  
end    

asyn_fifo #(
    .U_DLY                      (1                           ),
    .DATA_WIDTH                 (8                           ),
    .DATA_DEEPTH                (8192                        ),
    .ADDR_WIDTH                 (13                          )
)u_uart_rx_fifo(
    .wr_clk                     (sys_clk                     ),
    .wr_rst_n                   (sys_rst_n                   ),
    .rd_clk                     (sys_clk                     ),
    .rd_rst_n                   (sys_rst_n                   ),
    .din                        (uart_rx_fifo_wr_data        ),
    .wr_en                      (uart_rx_fifo_wr_en          ),
    .rd_en                      (uart_rx_fifo_rd_en          ),
    .dout                       (uart_rx_fifo_rd_data        ),
    .full                       (uart_rx_fifo_wr_full        ),
    .prog_full                  (uart_rx_fifo_wr_afull       ),
    .empty                      (uart_rx_fifo_rd_empty       ),
    .prog_empty                 (                            ),
    .prog_full_thresh           (13'd8100                    ),
    .prog_empty_thresh          (13'd1                       )
);

assign uart_rx_fifo_rd_en = (init_done == 1'b1 && bs_fifo_wr_afull == 1'b0 && uart_rx_fifo_rd_empty == 1'b0 && data_cur_state == DATA_BITSTREAM) ? 1'b1 : 1'b0;

//--------------------------------------------------------------
//clear fifo and counter befor write bitstream 
always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        init_count <=#U_DLY 4'b0;
    else if(bitstream_wr_start_pre == 1'b1)
        init_count <=#U_DLY 4'b0;
    else if(init_count < 4'hf)
        init_count <=#U_DLY init_count + 1'b1;
    else
        ;
end

always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        init_done  <=#U_DLY 1'b0;
    else if(init_count < 4'hf)
        init_done <=#U_DLY 1'b0;
    else 
        init_done <=#U_DLY 1'b1;
end


//------------------------------------------------------------------------------------------------------------
always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        write_sw_code_en_dly <=#U_DLY 1'b0;
    else 
        write_sw_code_en_dly <=#U_DLY write_sw_code_en;
end

assign write_sw_code_en_pos = (write_sw_code_en == 1'b1 && write_sw_code_en_dly == 1'b0) ? 1'b1 : 1'b0;

always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        crc32_ok_ind <=#U_DLY 1'b0;
    else if(flash_rd_en == 1'b1)
        crc32_ok_ind <=#U_DLY 1'b0;
    else if(bs_crc32_ok[1] == 1'b1) //get crc32 verify result
        crc32_ok_ind <=#U_DLY ~bs_crc32_ok[0];
    else
        ;
end

assign open_sw_code_ind = (crc_check_en == 1'b1) ? crc32_ok_ind : 1'b1;
//-----------------------------------------------------------------------------------------------------------
always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        data_cur_state <=#U_DLY DATA_IDLE;
    else if(init_done == 1'b0)
        data_cur_state <=#U_DLY DATA_IDLE;
    else
        data_cur_state <=#U_DLY data_nxt_state;
end

always @(*)
begin
    case(data_cur_state)
        DATA_IDLE:
        begin
            if(bitstream_wr_flag == 1'b1 && clear_bs_done == 1'b1)
                data_nxt_state <=#U_DLY DATA_BITSTREAM;
            else if(write_sw_code_en_pos == 1'b1) 
                data_nxt_state <=#U_DLY DATA_SWITCH_CODE;
            else
                data_nxt_state <=#U_DLY DATA_IDLE;
        end
        DATA_BITSTREAM:
        begin
            if(bitstream_wr_flag == 1'b0)
            begin
                if(bs_fifo_wr_cnt == 8'd0 && subsector_page_cnt == 4'h0)
                    data_nxt_state <=#U_DLY DATA_DONE;
                else 
                    data_nxt_state <=#U_DLY DATA_FILL;
            end
            else
                data_nxt_state <=#U_DLY DATA_BITSTREAM;
        end
        DATA_FILL:
        begin
            if(bs_fifo_wr_cnt >= 8'd255 && subsector_page_cnt == 4'hf && bs_fifo_wr_afull == 1'b0)
                data_nxt_state <=#U_DLY DATA_DONE;
            else
                data_nxt_state <=#U_DLY DATA_FILL;
        end
        DATA_SWITCH_CODE:
        begin
            if(bs_fifo_wr_cnt >= 8'd255 && bs_switch_open_cnt >= USER_BITSTREAM_CNT)
                data_nxt_state <=#U_DLY DATA_DONE;
            else
                data_nxt_state <=#U_DLY DATA_SWITCH_CODE;
        end
        DATA_DONE:
        begin
            data_nxt_state <=#U_DLY DATA_IDLE;
        end
        default:data_nxt_state <=#U_DLY DATA_IDLE;
    endcase
end


//-------------------------------------------------------------
always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        bs_switch_open_cnt <=#U_DLY 2'b01;
    else if(data_cur_state == DATA_SWITCH_CODE)
    begin
        if(bs_fifo_wr_cnt >= 8'd255 && bs_switch_open_cnt < USER_BITSTREAM_CNT)
             bs_switch_open_cnt <=#U_DLY bs_switch_open_cnt + 2'b1;
        else
             ;
    end
    else
        bs_switch_open_cnt <=#U_DLY 2'b01;
end


always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
    begin
        bs_fifo_wr_data <=#U_DLY 8'b0;
        bs_fifo_wr_en   <=#U_DLY 1'b0;
    end
    else if(bs_fifo_wr_afull == 1'b0)
    begin
        case(data_cur_state)
            DATA_BITSTREAM:
            begin
                if(uart_rx_fifo_rd_empty == 1'b0)
                begin
                    bs_fifo_wr_data <=#U_DLY uart_rx_fifo_rd_data;
                    bs_fifo_wr_en   <=#U_DLY 1'b1;
                end
                else
                begin
                    bs_fifo_wr_data <=#U_DLY 8'b0;
                    bs_fifo_wr_en   <=#U_DLY 1'b0;
                end
            end
            DATA_FILL:
            begin
                bs_fifo_wr_data <=#U_DLY 8'hff;
                bs_fifo_wr_en   <=#U_DLY 1'b1;
            end
            DATA_SWITCH_CODE:
            begin
                if(bs_fifo_wr_cnt >= 8'd251 && open_sw_code_ind == 1'b1 && bs_switch_open_cnt == write_sw_code_num)//crc32 OK or crc32 check not enable,open switch code 
                begin
                    case(bs_fifo_wr_cnt)
                        8'd251  :bs_fifo_wr_data <=#U_DLY 8'h01;
                        8'd252  :bs_fifo_wr_data <=#U_DLY 8'h33;
                        8'd253  :bs_fifo_wr_data <=#U_DLY 8'h2d;
                        8'd254  :bs_fifo_wr_data <=#U_DLY 8'h94;
                        default :bs_fifo_wr_data <=#U_DLY 8'hff;
                    endcase
                end
                else
                    bs_fifo_wr_data <=#U_DLY 8'hff;
                    bs_fifo_wr_en   <=#U_DLY 1'b1;
            end
            default:
            begin
                bs_fifo_wr_data <=#U_DLY bs_fifo_wr_data;
                bs_fifo_wr_en   <=#U_DLY 1'b0;
            end
        endcase
    end 
    else
    begin
        bs_fifo_wr_data <=#U_DLY bs_fifo_wr_data;
        bs_fifo_wr_en   <=#U_DLY 1'b0;
    end 
         
end    

assign bs_fifo_wr_eop = (bs_fifo_wr_cnt == 8'd255) ? 1'b1 : 1'b0;

always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        bs_fifo_wr_cnt <=#U_DLY 8'b0;
    else if(bitstream_wr_start_pre == 1'b1)
        bs_fifo_wr_cnt <=#U_DLY 8'b0;
    else if(bs_fifo_wr_en == 1'b1)
        bs_fifo_wr_cnt <=#U_DLY bs_fifo_wr_cnt + 1'b1;
    else
        ;
end 

always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        subsector_page_cnt <=#U_DLY 4'b0;
    else if(bitstream_wr_start_pre == 1'b1)
        subsector_page_cnt <=#U_DLY 4'b0;
    else if(bs_fifo_wr_en == 1'b1 && bs_fifo_wr_cnt == 8'd255)
        subsector_page_cnt <=#U_DLY subsector_page_cnt + 1'b1;
    else
        ;
end 

//-------------------------------------------------------------------------------------------------------
//  bs_wr_num, 2'b01:wr bitstream0,2'b10:wr bitstream1,2'b11:wr bitstream2
//  bs_rd_num, 2'b01:rd bitstream0,2'b10:rd bitstream1,2'b11:rd bitstream2
//-------------------------------------------------------------------------------------------------------
assign bitstream_wr_num = bs_wr_num;
assign bitstream_rd_num = bs_rd_num;


cellfifo_logic #(
    .SYNC_NUM_W2R               (3                              ),
    .SYNC_NUM_R2W               (3                              ),
    .ASYNC_MODE                 (0                              ),//synchronous fifo
    .ADDR_SIZE                  (10                             ),
    .DATA_SIZE                  (8                              ),
    .MAX_LEN                    (260                            ),
    .AFULL_NUM                  (764                            ),
    .AEMPTY_NUM                 (1                              ),
    .RAM_LATENCY                (1                              ),
    .U_DLY                      (1                              )
)
u_bs_fifo(
    .rst_w_n                    (sys_rst_n&init_done            ),
    .clk_w                      (sys_clk                        ),
    .wr_vld                     (bs_fifo_wr_en                  ),
    .wr_data                    (bs_fifo_wr_data                ),
    .wr_eoc                     (bs_fifo_wr_eop                 ),
    .wr_drop                    (1'b0                           ),
    .wr_full                    (bs_fifo_wr_full                ),
    .wr_afull                   (bs_fifo_wr_afull               ),
    .wr_over                    (                               ),
    .wr_used                    (                               ),
    .rst_r_n                    (sys_rst_n&init_done            ),
    .clk_r                      (sys_clk                        ),
    .rd_rdy                     (bs_fifo_rd_rdy                 ),//bs_fifo_rd_rdy
    .rd_req                     (bs_fifo_rd_req                 ),
    .rd_vld                     (bs_fifo_rd_valid               ),
    .rd_eoc                     (bs_fifo_rd_eop                 ),
    .rd_data                    (bs_fifo_rd_data                ),
    .rd_empty                   (bs_fifo_rd_empty               ),
    .rd_aempty                  (                               ),
    .rd_used                    (                               ),
    .ram_wen                    (bs_ram_wen                     ),
    .ram_waddr                  (bs_ram_waddr                   ),
    .ram_wdata                  (bs_ram_wdata                   ),
    .ram_rcken                  (bs_ram_rcken                   ),
    .ram_raddr                  (bs_ram_raddr                   ),
    .ram_rdata                  (bs_ram_rdata                   ),
    .fifo_err                   (bs_fifo_rd_err                 )
);



bitstream_ram u_bs_1024x9_ram (
   .wr_data                    (bs_ram_wdata                   ),
   .wr_addr                    (bs_ram_waddr                   ),
   .wr_en                      (bs_ram_wen                     ),
   .wr_clk                     (sys_clk                        ),
   .wr_rst                     (~sys_rst_n                     ),
   .rd_addr                    (bs_ram_raddr                   ),
   .rd_data                    (bs_ram_rdata                   ),
   .rd_clk                     (sys_clk                        ),
   .rd_oce                     (bs_ram_rcken                   ),//bs_ram_rcken
   .rd_rst                     (~sys_rst_n                     )
   );


assign bitstream_data           = bs_fifo_rd_data;       
assign bitstream_valid          = bs_fifo_rd_valid;     
assign bitstream_eop            = bs_fifo_rd_eop;    
assign bitstream_fifo_rd_rdy    = bs_fifo_rd_rdy;
assign bs_fifo_rd_req           = bitstream_fifo_rd_req;


endmodule
