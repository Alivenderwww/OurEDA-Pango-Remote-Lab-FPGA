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
module spi_top
#(
parameter DEVICE                = "PG2L100H"        ,   // "PG2L200H":bitstream 8974KB;8c4_000 "PG2L100H":bitstream 3703KB;39e_000 "PG2L50H":bitstream 2065KB;204_400 "PG2L25H":bitstream 1168KB;124_000
parameter USER_BITSTREAM_CNT    = 2'd3              ,
parameter USER_BITSTREAM1_ADDR  = 24'h20_b000       ,   // user bitstream1 start address  ---> [6*4KB+2068KB(2065),32MB- 2068KB(2065)],4KB align  // 24'h20_b000
parameter USER_BITSTREAM2_ADDR  = 24'h41_0000       ,   // user bitstream2 start address  ---> 24'h41_0000 
parameter USER_BITSTREAM3_ADDR  = 24'h61_5000           // user bitstream3 start address  ---> 24'h61_5000
)(
input               sys_clk                 ,
input               sys_rst_n               ,
 
output              spi_cs                  ,
output              spi_clk_en              ,
input               spi_dq1                 ,
output              spi_dq0                 ,

//----- ctrl ----------------------------------
input               flash_wr_en             ,
input               flash_rd_en             ,
input       [1:0]   bitstream_wr_num        ,
input       [1:0]   bitstream_rd_num        ,
input               bitstream_up2cpu_en     ,
input               crc_check_en            ,
input               clear_sw_en             ,
input       [1:0]   bs_crc32_ok             ,//[1]:valid   [0]:1'b0,OK  1'b1,error
input               write_sw_code_en        ,
//------ debug --------------------------------
output      [15:0]  flash_flag_status       ,
output reg          time_out_reg            ,

input               flash_cfg_cmd_en        ,
input       [7:0]   flash_cfg_cmd           ,
input       [15:0]  flash_cfg_reg_wrdata    ,
output              flash_cfg_reg_rd_en     ,
output      [15:0]  flash_cfg_reg_rddata    ,
//---------------------------------------------

//----- read bitsream -------------------------
output      [7:0]   flash_rd_data_o         ,
output              flash_rd_valid_o        ,
input               flash_rd_data_fifo_afull,

output      [31:0]  bs_readback_crc         ,
output              bs_readback_crc_valid   ,

output reg          clear_sw_done           ,
output              clear_bs_done           ,
output reg          bitstream_wr_done       ,
output reg          bitstream_rd_done       ,
output reg          open_sw_code_done       ,

//----- write bitstream -----------------------
output              bitstream_fifo_rd_req   ,
input       [7:0]   bitstream_data          ,
input               bitstream_valid         ,
input               bitstream_eop           ,
input               bitstream_fifo_rd_rdy
);
//-----------------------------------------------------------
// 
//-----------------------------------------------------------
reg                 flash_cfg_reg_valid         ;
reg         [15:0]  flash_cfg_reg_data          ;
reg         [7:0]   flash_cfg_cmd_reg           ;

reg                 flash_wr_en_reg             ;
reg                 flash_wr_en_dly             ;
reg                 flash_rd_en_reg             ;
reg                 flash_rd_en_dly             ;
reg         [15:0]  flash_clear_mem_addr        ;//subsector align 
reg         [15:0]  flash_wr_mem_addr           ;//page align
reg         [15:0]  flash_rd_mem_addr           ;//page align

reg                 close_switch_code_ind       ;
reg                 open_switch_code_ind        ;
reg         [4:0]   open_switch_code_ind_dly    ;
reg         [1:0]   flash_cmd_wr_cnt            ;
reg         [15:0]  subsector_num               ;//4KB number
reg         [15:0]  sub_sector_clear_num        ;//4KB number
reg         [15:0]  sub_sector_wr_num           ;//4KB number
reg         [15:0]  sub_sector_rd_num           ;//4KB number
reg         [15:0]  sub_sector_wr_cnt           ;
reg         [15:0]  sub_sector_rd_cnt           ;

reg         [7:0]   spi_cur_state               ;
reg         [7:0]   spi_nxt_state               ;

reg                 clear_sw_cmd_done           ;
reg         [4:0]   clear_sw_cmd_done_dly       ;
reg                 flash_clear_done            ;
reg                 write_clear_cmd_done        ;
reg                 bitstream_wr_cmd_done       ;
reg                 bitstream_rd_cmd_done       ;

reg                 bitstream_rd_done_dly       ;
reg         [1:0]   bs_switch_open_cnt          ;

reg         [31:0]  f_crc32_temp                ;
reg                 bs_crc_ok_ind               ;
reg                 write_sw_code_en_1dly       ;
reg                 write_sw_code_en_2dly       ;
wire                write_sw_code               ;
reg                 clear_sw_en_dly             ;
wire                clear_sw_en_pos             ;

//-----------------------------------------------------------
reg         [27:0]  flash_cmd_fifo_wr_data      ; 
reg                 flash_cmd_fifo_wr_en        ;
wire                flash_cmd_fifo_rd_en        ;
wire        [27:0]  flash_cmd_fifo_rd_data      ;
wire                flash_cmd_fifo_wr_full      ;
wire                flash_cmd_fifo_wr_afull     ;
wire                flash_cmd_fifo_rd_empty     ;

wire        [3:0]   flash_cmd_type              ;//[3]: 1'b1,valid  1'b0,not valid ; [2]: 1'b1,wr  1'b0,rd  ; [1]: 1'b1,have data   1'b0,no data ; [0]: 1'b1,need addr  1'b0,no addr.  
wire        [7:0]   flash_cmd                   ;
wire        [23:0]  flash_addr                  ;

wire        [7:0]   flash_wr_data               ; 
wire                flash_wr_valid              ;
wire                flash_wr_data_eop           ;
wire                flash_wr_data_fifo_rdy      ;
wire                flash_wr_data_fifo_req      ;

wire                reg_fifo_clear              ;
wire                erase_time_out              ;
reg         [15:0]  open_switch_code_addr       ;
reg         [15:0]  close_switch_code_addr      ;

wire        [7:0]   flash_rd_data               ;
wire                flash_rd_valid              ;

wire                cfg_cmd_valid               ;
wire                cmd_done_ind                ;
reg                 cmd_done_ind_dly            ;
//-----------------------------------------------------------
//spi config reg
localparam          NVCR                = 16'hffc3      ;   //16'hafc3
localparam          VCR                 =  8'hfb        ;   //8'hab
localparam          VECR                =  8'hcf        ;

localparam          CMD_WREN            = 8'h06         ;   //write enable
localparam          CMD_RDWIP           = 8'h05         ;   //read status register
localparam          CMD_RDFLSR          = 8'h70         ;   //read flag status register
localparam          CMD_SSE             = 8'h20         ;   //subsector erase
localparam          CMD_SE              = 8'hd8         ;   //sector erase
localparam          CMD_BE              = 8'hc7         ;   //bulk erase
localparam          CMD_WRPAGE          = 8'h02         ;   //1 wire write page
localparam          CMD_READ            = 8'h03         ;   //1 wire read 

//spi ctrl state
localparam          SPI_IDLE            = 8'b0000_0001   ;
localparam          SPI_CFG_REG         = 8'b0000_0010   ;   //wr/rd cfg register
localparam          SPI_READ_DATA       = 8'b0000_0100   ;   //rd memory data
localparam          SPI_WRITE_DATA      = 8'b0000_1000   ;   //wr memory data
localparam          SPI_WRITE_CLEAR     = 8'b0001_0000   ;   //clear subsector before wr memory data
localparam          SPI_CLEAR_SW        = 8'b0010_0000   ;
localparam          SPI_OPEN_SWITCH     = 8'b0100_0000   ;
localparam          SPI_DONE            = 8'b1000_0000   ;

//-----------------------------------------------------------
always @ (posedge sys_clk or negedge sys_rst_n)
    if (sys_rst_n==1'b0)     
        bitstream_wr_done <= 1'b0;
    else if (flash_wr_en == 1'b1 && flash_wr_en_dly == 1'b0)     
        bitstream_wr_done <= 1'b0;
    else if(bitstream_wr_cmd_done == 1'b1 && flash_cmd_fifo_rd_empty == 1'b1) 
        bitstream_wr_done <= 1'b1;
    else
        ;

always @ (posedge sys_clk or negedge sys_rst_n)
    if (sys_rst_n==1'b0)     
        bitstream_rd_done <= 1'b0;
    else if (flash_rd_en == 1'b1 && flash_rd_en_dly == 1'b0)     
        bitstream_rd_done <= 1'b0;
    else if(bitstream_rd_cmd_done == 1'b1 && flash_cmd_fifo_rd_empty == 1'b1) 
        bitstream_rd_done <= 1'b1;
    else
        ;

always @ (posedge sys_clk or negedge sys_rst_n)
    if (sys_rst_n==1'b0)     
        open_sw_code_done <= 1'b0;
    else if (flash_wr_en == 1'b1 && flash_wr_en_dly == 1'b0)     
        open_sw_code_done <= 1'b0;
    else if(open_switch_code_ind_dly[4] == 1'b1 && flash_cmd_fifo_rd_empty == 1'b1) 
        open_sw_code_done <= 1'b1;
    else
        ;

always @ (posedge sys_clk or negedge sys_rst_n)
    if (sys_rst_n==1'b0)     
        time_out_reg <= 1'b0;
    else if (flash_wr_en == 1'b1 && flash_wr_en_dly == 1'b0)     
        time_out_reg <= 1'b0;
    else if(erase_time_out == 1'b1) 
        time_out_reg <= 1'b1;
    else
        ;

assign clear_bs_done     = flash_clear_done;
assign reg_fifo_clear    = (flash_wr_en == 1'b1 || flash_wr_en_dly == 1'b1) ? 1'b1 : 1'b0;
//-----------------------------------------------------------
always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
       subsector_num <= 16'd0; 
    else
    begin
        case(DEVICE)
            "PG2L200H": subsector_num <= 16'd2244; 
            "PG2L100H": subsector_num <= 16'd926; 
            "PG2L50H" : subsector_num <= 16'd517; 
            "PG2L25H" : subsector_num <= 16'd292; 
            "SIMULATE": subsector_num <= 16'd50; 
            default: subsector_num <= 16'd926; 
        endcase
    end
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
       sub_sector_clear_num <= 16'd0; 
    else if(flash_wr_en == 1'b1 && flash_wr_en_dly == 1'b0)
    begin
        case(bitstream_wr_num)
        2'b01   : sub_sector_clear_num <= USER_BITSTREAM1_ADDR[23:12] + subsector_num - 16'd1;
        2'b10   : sub_sector_clear_num <= USER_BITSTREAM2_ADDR[23:12] + subsector_num - 16'd1;
        2'b11   : sub_sector_clear_num <= USER_BITSTREAM3_ADDR[23:12] + subsector_num - 16'd1;
        default : sub_sector_clear_num <= 16'd0;
        endcase
    end
    else
        ;
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        sub_sector_wr_num <= 16'd0; 
    else if(flash_wr_en == 1'b1 && flash_wr_en_dly == 1'b0)
        sub_sector_wr_num <= subsector_num - 1'b1; 
    else
        ;
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
       sub_sector_rd_num <= 16'd0; 
    else if(flash_rd_en == 1'b1 && flash_rd_en_dly == 1'b0)
        sub_sector_rd_num <= subsector_num - 1'b1; 
    else
        ;
end

//--------------------------------------------------------------------------
// write or read  nvcr/vcr/vecr or cmd=0x9e/0x9f--->read flash id
assign cfg_cmd_valid = (((flash_cfg_cmd[7:4] == 4'hb || flash_cfg_cmd[7:4] == 4'h8 || flash_cfg_cmd[7:4] == 4'h6) && (flash_cfg_cmd[3:0] == 4'h5 || flash_cfg_cmd[3:0] == 4'h1)) || flash_cfg_cmd == 8'h9e) ? 1'b1 : 1'b0;

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        flash_cfg_reg_valid <= 1'b0; 
    else if(flash_cfg_cmd_en == 1'b1 && cfg_cmd_valid == 1'b1) 
        flash_cfg_reg_valid <= 1'b1; 
    else if(spi_cur_state == SPI_DONE)
        flash_cfg_reg_valid <= 1'b0; 
    else
        ;
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        flash_cfg_reg_data <= 16'b0; 
    else if(flash_cfg_cmd_en == 1'b1)
        flash_cfg_reg_data <= flash_cfg_reg_wrdata; 
    else
        ; 
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        flash_cfg_cmd_reg <= 8'b0; 
    else if(flash_cfg_cmd_en == 1'b1)
        flash_cfg_cmd_reg <= flash_cfg_cmd; 
    else
        ; 
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        flash_wr_en_dly <= 1'b0; 
    else 
        flash_wr_en_dly <= flash_wr_en;
end 

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        flash_wr_en_reg <= 1'b0; 
    else if(flash_wr_en_dly == 1'b1)
        flash_wr_en_reg <= 1'b1; 
    else if(sub_sector_wr_cnt >= sub_sector_wr_num && flash_wr_mem_addr[3:0] == 4'hf && flash_cmd_wr_cnt == 2'b11)
        flash_wr_en_reg <= 1'b0; 
    else
        ; 
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        flash_rd_en_reg <= 1'b0; 
    else if(flash_rd_en == 1'b1)
        flash_rd_en_reg <= 1'b1; 
    else if(sub_sector_rd_cnt >= sub_sector_rd_num && flash_rd_mem_addr[3:0] == 4'hf && flash_cmd_wr_cnt[0] == 1'b1)
        flash_rd_en_reg <= 1'b0; 
    else
        ; 
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        flash_rd_en_dly <= 1'b0; 
    else 
        flash_rd_en_dly <= flash_rd_en; 

end

//----------------------------------------------------------------------------

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        spi_cur_state <= SPI_IDLE;
    else if(reg_fifo_clear == 1'b1)
        spi_cur_state <= SPI_IDLE;
    else 
        spi_cur_state <= spi_nxt_state; 
end

always @ (*)
begin
    case(spi_cur_state)
        SPI_IDLE:
        begin
            if(flash_cfg_reg_valid == 1'b1) 
                spi_nxt_state = SPI_CFG_REG;
            else if(flash_wr_en_reg == 1'b1)
            begin
                if(write_clear_cmd_done == 1'b0) 
                    spi_nxt_state = SPI_WRITE_CLEAR;
                else
                    spi_nxt_state = SPI_WRITE_DATA;
            end
            else if(flash_rd_en_reg == 1'b1) 
                spi_nxt_state = SPI_READ_DATA;
            else if(write_sw_code == 1'b1)
                spi_nxt_state = SPI_OPEN_SWITCH;
            else if(clear_sw_en_pos == 1'b1)
                spi_nxt_state = SPI_CLEAR_SW;
            else
                spi_nxt_state = SPI_IDLE;
        end
        SPI_CFG_REG:
        begin
            if(flash_cmd_wr_cnt[0] == 1'b1)
                spi_nxt_state = SPI_DONE;
            else
                spi_nxt_state = SPI_CFG_REG;
        end
        SPI_READ_DATA:
        begin
            if(bitstream_rd_cmd_done == 1'b1)
                spi_nxt_state = SPI_DONE;
            else  
                spi_nxt_state = SPI_READ_DATA;
        end
        SPI_WRITE_CLEAR:
        begin
            if(flash_clear_mem_addr > sub_sector_clear_num)
                spi_nxt_state = SPI_DONE;
            else  
                spi_nxt_state = SPI_WRITE_CLEAR;
        end
        SPI_WRITE_DATA:
        begin
            if(sub_sector_wr_cnt >= sub_sector_wr_num && flash_wr_mem_addr[3:0] == 4'hf && flash_cmd_wr_cnt == 2'b11)
                spi_nxt_state = SPI_DONE;
            else 
                spi_nxt_state = SPI_WRITE_DATA;
        end
        SPI_OPEN_SWITCH:
        begin
            if(flash_cmd_wr_cnt == 2'b11 && bs_switch_open_cnt >= USER_BITSTREAM_CNT)
                spi_nxt_state = SPI_DONE;
            else 
                spi_nxt_state = SPI_OPEN_SWITCH;
        end
        SPI_CLEAR_SW:
        begin
            if(flash_cmd_wr_cnt == 2'b11 && bs_switch_open_cnt >= USER_BITSTREAM_CNT)
                spi_nxt_state = SPI_DONE;
            else 
                spi_nxt_state = SPI_CLEAR_SW;
        end
        SPI_DONE:
        begin
            if(flash_cmd_fifo_rd_empty == 1'b1 && cmd_done_ind_dly == 1'b1)// cmd finish 
                spi_nxt_state = SPI_IDLE;
            else 
                spi_nxt_state = SPI_DONE;
        end
        default:spi_nxt_state = SPI_IDLE;
    endcase
     
end

//-----------------------------------------------------------------------------------------------------
always @(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        bs_switch_open_cnt <= 2'b01;
    else if(spi_cur_state == SPI_OPEN_SWITCH || spi_cur_state == SPI_WRITE_CLEAR || spi_cur_state == SPI_CLEAR_SW)
    begin
        if(flash_cmd_wr_cnt == 2'b11 && bs_switch_open_cnt < USER_BITSTREAM_CNT)
             bs_switch_open_cnt <= bs_switch_open_cnt + 2'b1;
        else
             ;
    end
    else
        bs_switch_open_cnt <= 2'b01;
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        sub_sector_wr_cnt <= 16'b0;
    else if (flash_wr_en == 1'b1 && flash_wr_en_dly == 1'b0)     
        sub_sector_wr_cnt <= 16'b0;
    else if(spi_cur_state == SPI_WRITE_DATA && flash_wr_mem_addr[3:0] == 4'hf && flash_cmd_wr_cnt == 2'b11 && flash_cmd_fifo_wr_afull == 1'b0) 
        sub_sector_wr_cnt <= sub_sector_wr_cnt + 1'b1;
    else
        ;
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        sub_sector_rd_cnt <= 16'b0;
    else if (flash_rd_en == 1'b1 && flash_rd_en_dly == 1'b0)     
        sub_sector_rd_cnt <= 16'b0;
    else if(spi_cur_state == SPI_READ_DATA && flash_rd_mem_addr[3:0] == 4'hf && flash_cmd_wr_cnt[0] == 1'b1 && flash_cmd_fifo_wr_afull == 1'b0) 
        sub_sector_rd_cnt <= sub_sector_rd_cnt + 1'b1;
    else
        ;
end

//------------------------------------------------------------------------------------------------------

//cpu config clear_sw_en reg,to clear switch code 
always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        clear_sw_cmd_done <= 1'b0;
    else if (clear_sw_en == 1'b1 && clear_sw_en_dly == 1'b0)     
        clear_sw_cmd_done <= 1'b0;
    else if(spi_cur_state == SPI_CLEAR_SW && flash_cmd_wr_cnt == 2'b11 && bs_switch_open_cnt >= USER_BITSTREAM_CNT) 
        clear_sw_cmd_done <= 1'b1;
    else
        ;
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        clear_sw_cmd_done_dly <= 5'b0;
    else    
        clear_sw_cmd_done_dly <= {clear_sw_cmd_done_dly[3:0],clear_sw_cmd_done};
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        clear_sw_done <= 1'b0;
    else if (clear_sw_en == 1'b1 && clear_sw_en_dly == 1'b0)     
        clear_sw_done <= 1'b0;
    else if(clear_sw_cmd_done_dly[4] == 1'b1 &&  spi_cur_state == SPI_DONE && flash_cmd_fifo_rd_empty == 1'b1 && cmd_done_ind_dly == 1'b1)
        clear_sw_done <= 1'b1;
    else
        ;
end

//before write new bitstream,clear switch code and the old bitstream
always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        write_clear_cmd_done <= 1'b0;
    else if (flash_wr_en == 1'b1 && flash_wr_en_dly == 1'b0)     
        write_clear_cmd_done <= 1'b0;
    else if(flash_clear_mem_addr > sub_sector_clear_num) 
        write_clear_cmd_done <= 1'b1;
    else
        ;
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        flash_clear_done <= 1'b0;
    else if (flash_wr_en == 1'b1 && flash_wr_en_dly == 1'b0)     
        flash_clear_done <= 1'b0;
    else if(write_clear_cmd_done == 1'b1 &&  spi_cur_state == SPI_DONE && flash_cmd_fifo_rd_empty == 1'b1 && cmd_done_ind_dly == 1'b1)
        flash_clear_done <= 1'b1;
    else
        ;
end

//write bistream cmd done
always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        bitstream_wr_cmd_done <= 1'b0;
    else if (flash_wr_en == 1'b1 && flash_wr_en_dly == 1'b0)     
        bitstream_wr_cmd_done <= 1'b0;
    else if(sub_sector_wr_cnt >= sub_sector_wr_num && flash_wr_mem_addr[3:0] == 4'hf && flash_cmd_wr_cnt == 2'b11) 
        bitstream_wr_cmd_done <= 1'b1;
    else
        ;
end

//read bitstream cmd done
always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        bitstream_rd_cmd_done <= 1'b0;
    else if ((flash_rd_en == 1'b1 && flash_rd_en_dly == 1'b0) || (flash_wr_en == 1'b1 && flash_wr_en_dly == 1'b0))    
        bitstream_rd_cmd_done <= 1'b0;
    else if(sub_sector_rd_cnt >= sub_sector_rd_num && flash_rd_mem_addr[3:0] == 4'hf && flash_cmd_wr_cnt[0] == 1'b1) 
        bitstream_rd_cmd_done <= 1'b1;
    else
        ;
end

//------------------------------------------------------------------------------------------------------
always @ (posedge sys_clk or negedge sys_rst_n)//clear switch code 
begin
    if (sys_rst_n==1'b0)     
        close_switch_code_ind <= 1'b0;
    else if (flash_wr_en == 1'b1 && flash_wr_en_dly == 1'b0 && bitstream_wr_num != 2'b00)     
        close_switch_code_ind <= 1'b1;
    else if(spi_cur_state == SPI_WRITE_CLEAR && flash_cmd_wr_cnt == 2'b11 && bs_switch_open_cnt >= USER_BITSTREAM_CNT)
        close_switch_code_ind <= 1'b0;
    else
        ;
end


always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        flash_clear_mem_addr <= 16'h0; 
    else if(flash_wr_en == 1'b1 && flash_wr_en_dly == 1'b0)
    begin
        case(bitstream_wr_num)
            2'b01   :   flash_clear_mem_addr <= USER_BITSTREAM1_ADDR[23:12];      // replace bitstream0 ,start from addr {2*4KB+golden bitstream}
            2'b10   :   flash_clear_mem_addr <= USER_BITSTREAM2_ADDR[23:12];      // replace bitstream1 
            2'b11   :   flash_clear_mem_addr <= USER_BITSTREAM3_ADDR[23:12];      // replace bitstream2 
            default :   flash_clear_mem_addr <= 16'h0; 
        endcase
    end  
    else if(spi_cur_state == SPI_WRITE_CLEAR && flash_cmd_wr_cnt == 2'b11 && flash_cmd_fifo_wr_afull == 1'b0)
    begin
        if(close_switch_code_ind == 1'b1) 
            flash_clear_mem_addr <= flash_clear_mem_addr;           // clear switch code  
        else if(flash_clear_mem_addr[3:0] != 4'h0)   
            flash_clear_mem_addr <= flash_clear_mem_addr + 16'b1;   // subsector earse 
        else
            flash_clear_mem_addr <= flash_clear_mem_addr + 16'h10;  // sector earse 
    end
    else 
       ; 
end


always @ (posedge sys_clk or negedge sys_rst_n)//open switch code 
begin
    if (sys_rst_n==1'b0)     
        open_switch_code_ind <= 1'b0;
    else if (open_sw_code_done == 1'b1)     
        open_switch_code_ind <= 1'b0;
    else if(spi_cur_state == SPI_OPEN_SWITCH && flash_cmd_wr_cnt == 2'b11 && bs_switch_open_cnt >= USER_BITSTREAM_CNT)
        open_switch_code_ind <= 1'b1;
    else
        ;
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        open_switch_code_ind_dly <= 5'b0;
    else     
        open_switch_code_ind_dly <= {open_switch_code_ind_dly[3:0],open_switch_code_ind};
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        flash_wr_mem_addr <= 16'h0; 
    else if(flash_wr_en == 1'b1 && flash_wr_en_dly == 1'b0)
    begin
        case(bitstream_wr_num)
            2'b01   :   flash_wr_mem_addr <= {USER_BITSTREAM1_ADDR[23:12],4'h0};  // replace bitstream0 ,start from addr {2*4KB+golden bitstream}
            2'b10   :   flash_wr_mem_addr <= {USER_BITSTREAM2_ADDR[23:12],4'h0};  // replace bitstream1 
            2'b11   :   flash_wr_mem_addr <= {USER_BITSTREAM3_ADDR[23:12],4'h0};  // replace bitstream2 
            default :   flash_wr_mem_addr <= 16'h0; 
        endcase
    end  
    else if(spi_cur_state == SPI_WRITE_DATA && flash_cmd_wr_cnt == 2'b11 && flash_cmd_fifo_wr_afull == 1'b0)
        flash_wr_mem_addr <= flash_wr_mem_addr + 1'b1; // a page  
    else 
       ; 
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        flash_rd_mem_addr <= 16'h0; 
    else if(flash_rd_en == 1'b1 && flash_rd_en_dly == 1'b0)
    begin
        case(bitstream_rd_num)
            2'b01   :   flash_rd_mem_addr <= {USER_BITSTREAM1_ADDR[23:12],4'h0};  // read bitstream0 ,start from addr {2*4KB+golden bitstream}
            2'b10   :   flash_rd_mem_addr <= {USER_BITSTREAM2_ADDR[23:12],4'h0};  // read bitstream1 
            2'b11   :   flash_rd_mem_addr <= {USER_BITSTREAM3_ADDR[23:12],4'h0};  // read bitstream2 
            default :   flash_rd_mem_addr <= 16'h0; 
        endcase
    end  
    else if(spi_cur_state == SPI_READ_DATA && flash_cmd_wr_cnt[0] == 1'b1 && flash_cmd_fifo_wr_afull == 1'b0)
        flash_rd_mem_addr <= flash_rd_mem_addr + 1'b1; // a page  
    else 
       ; 
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        flash_cmd_wr_cnt <= 2'b0;
    else if(spi_cur_state != SPI_IDLE && spi_cur_state != SPI_DONE) 
    begin
        if(flash_cmd_fifo_wr_afull == 1'b0)
            flash_cmd_wr_cnt <= flash_cmd_wr_cnt + 1'b1;
        else
            ;
    end
    else 
        flash_cmd_wr_cnt <= 2'b0;
end  

//-------------------------------------------------------------------------------------------------------------
//switch code = 4KB = 16*256B=16 page,only need to write the 16th page,first page to 15th page is 0xff
// {switch_code1(4KB) + j_code1(4KB)} + {switch_code2(4KB) + j_code2(4KB)} + {switch_code3(4KB) + j_code3(4KB)}
//  ----> switch_code1_page_16th_addr = 16'hf ; ----> flash_addr={16'hf ,8'h0}
//  ----> switch_code2_page_16th_addr = 16'h2f; ----> flash_addr={16'h2f,8'h0}
//  ----> switch_code3_page_16th_addr = 16'h4f; ----> flash_addr={16'h4f,8'h0}
//-------------------------------------------------------------------------------------------------------------
always@(*)
begin
    if(spi_cur_state == SPI_OPEN_SWITCH)
    begin
        case(bs_switch_open_cnt)
            2'b01   : open_switch_code_addr <= 16'hf  ;
            2'b10   : open_switch_code_addr <= 16'h2f ;
            2'b11   : open_switch_code_addr <= 16'h4f ;
            default : open_switch_code_addr <= 16'hf  ;
        endcase
    end
    else
        open_switch_code_addr <= 16'h0  ;
end

always@(*)
begin
    if(spi_cur_state == SPI_WRITE_CLEAR || spi_cur_state == SPI_CLEAR_SW)
    begin
        case(bs_switch_open_cnt)
            2'b01   : close_switch_code_addr <= 16'h0;
            2'b10   : close_switch_code_addr <= 16'h20;
            2'b11   : close_switch_code_addr <= 16'h40;
            default : close_switch_code_addr <= 16'h0;
        endcase
    end
    else
        close_switch_code_addr <= 16'h0  ;
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0) 
    begin    
        flash_cmd_fifo_wr_en    <= 1'b0; 
        flash_cmd_fifo_wr_data  <= 28'b0;//{flash addr,cmd_type,cmd}
    end 
    else if(flash_cmd_fifo_wr_afull == 1'b0)
    begin
        case(spi_cur_state)
            SPI_CFG_REG:
            begin    
                if(flash_cmd_wr_cnt[0] == 1'b1 || flash_cfg_cmd_reg[3:0] == 4'h1)
                    flash_cmd_fifo_wr_en    <= 1'b1;
                else 
                    flash_cmd_fifo_wr_en    <= 1'b0;
                
                if(flash_cmd_wr_cnt[0] == 1'b0)
                    flash_cmd_fifo_wr_data  <= {16'b0,4'b1100,CMD_WREN};                            //write en cmd before write config register 
                else if(flash_cfg_cmd_reg[3:0] == 4'h5 || flash_cfg_cmd_reg == 9'h9e) 
                    flash_cmd_fifo_wr_data  <= {16'b0,4'b1010,flash_cfg_cmd_reg};                   //read config register or read flash id 
                else
                    flash_cmd_fifo_wr_data  <= {16'b0,4'b1110,flash_cfg_cmd_reg};                   //write config register 
            end
            SPI_WRITE_CLEAR:
            begin
                if(flash_cmd_wr_cnt == 2'b0) 
                    flash_cmd_fifo_wr_en    <= 1'b0;
                else    
                    flash_cmd_fifo_wr_en    <= 1'b1;

                case(flash_cmd_wr_cnt)
                    2'b01:flash_cmd_fifo_wr_data  <= {16'b0,4'b1100,CMD_WREN};                      //write en cmd
                    2'b10:                                                                          //write clear cmd
                    begin
                        if(close_switch_code_ind == 1'b1)
                            flash_cmd_fifo_wr_data  <= {close_switch_code_addr,4'b1101,CMD_SSE};    //write subsector clear cmd,clear switch code
                        else if(flash_clear_mem_addr[3:0] != 4'h0)
                            flash_cmd_fifo_wr_data  <= {flash_clear_mem_addr,4'b0,4'b1101,CMD_SSE}; //write subsector clear cmd
                        else
                            flash_cmd_fifo_wr_data  <= {flash_clear_mem_addr,4'b0,4'b1101,CMD_SE};  //write sector clear cmd
                    end
                    2'b11:flash_cmd_fifo_wr_data  <= {16'b0,4'b1010,CMD_RDWIP};                     //read wip bit
                    default:;
                endcase
            end
            SPI_CLEAR_SW:
            begin
                if(flash_cmd_wr_cnt == 2'b0) 
                    flash_cmd_fifo_wr_en    <= 1'b0;
                else    
                    flash_cmd_fifo_wr_en    <= 1'b1;

                case(flash_cmd_wr_cnt)
                    2'b01:flash_cmd_fifo_wr_data  <= {16'b0,4'b1100,CMD_WREN};                      //write en cmd
                    2'b10:flash_cmd_fifo_wr_data  <= {close_switch_code_addr,4'b1101,CMD_SSE};      //write subsector clear cmd,clear switch code 
                    2'b11:flash_cmd_fifo_wr_data  <= {16'b0,4'b1010,CMD_RDWIP};                     //read wip bit
                    default:;
                endcase
            end
            SPI_WRITE_DATA:
            begin    
                if(flash_cmd_wr_cnt == 2'b0)    
                    flash_cmd_fifo_wr_en    <= 1'b0;
                else    
                    flash_cmd_fifo_wr_en    <= 1'b1;

                case(flash_cmd_wr_cnt)
                    2'b01:flash_cmd_fifo_wr_data  <= {16'b0,4'b1100,CMD_WREN};                      //write en cmd
                    2'b10:flash_cmd_fifo_wr_data  <= {flash_wr_mem_addr,4'b1111,CMD_WRPAGE};        //write page cmd
                    2'b11:flash_cmd_fifo_wr_data  <= {16'b0,4'b1010,CMD_RDWIP};                     //read wip bit ,p_e_ctrl_bit = ~wip
                    default:;
                endcase
            end
            SPI_OPEN_SWITCH: 
            begin            
                if(flash_cmd_wr_cnt == 2'b0)  
                    flash_cmd_fifo_wr_en    <= 1'b0;
                else    
                    flash_cmd_fifo_wr_en    <= 1'b1;

                case(flash_cmd_wr_cnt)
                    2'b01:flash_cmd_fifo_wr_data  <= {16'b0,4'b1100,CMD_WREN};                      //write en cmd
                    2'b10:flash_cmd_fifo_wr_data  <= {open_switch_code_addr,4'b1111,CMD_WRPAGE};    //write page cmd,open switch code
                    2'b11:flash_cmd_fifo_wr_data  <= {16'b0,4'b1010,CMD_RDWIP};                     //read wip bit ,p_e_ctrl_bit = ~wip
                    default:;
                endcase
            end
            SPI_READ_DATA:
            begin
                if(flash_cmd_wr_cnt[0] == 1'b1)    
                    flash_cmd_fifo_wr_en    <= 1'b1;
                else    
                    flash_cmd_fifo_wr_en    <= 1'b0;    

                flash_cmd_fifo_wr_data  <= {flash_rd_mem_addr,4'b1011,CMD_READ};//read page cmd
            end
            default:flash_cmd_fifo_wr_en    <= 1'b0;
        endcase
    end 
    else
    begin    
        flash_cmd_fifo_wr_en    <= 1'b0; 
        flash_cmd_fifo_wr_data  <= flash_cmd_fifo_wr_data;
    end 
end

asyn_fifo #(
    .U_DLY                      (1                           ),
    .DATA_WIDTH                 (28                          ),
    .DATA_DEEPTH                (128                         ),
    .ADDR_WIDTH                 (7                           )
)u_flash_cmd_fifo(
    .wr_clk                     (sys_clk                     ),
    .wr_rst_n                   (sys_rst_n&(~reg_fifo_clear) ),
    .rd_clk                     (sys_clk                     ),
    .rd_rst_n                   (sys_rst_n&(~reg_fifo_clear) ),
    .din                        (flash_cmd_fifo_wr_data      ),
    .wr_en                      (flash_cmd_fifo_wr_en        ),
    .rd_en                      (flash_cmd_fifo_rd_en        ),
    .dout                       (flash_cmd_fifo_rd_data      ),
    .full                       (flash_cmd_fifo_wr_full      ),
    .prog_full                  (flash_cmd_fifo_wr_afull     ),
    .empty                      (flash_cmd_fifo_rd_empty     ),
    .prog_empty                 (                            ),
    .prog_full_thresh           (7'd120                      ),
    .prog_empty_thresh          (7'd1                        )
);

assign flash_cmd_fifo_rd_en = (flash_cmd_fifo_rd_empty == 1'b0 && cmd_done_ind == 1'b1) ? 1'b1 : 1'b0;

assign flash_cmd_type       = {(~flash_cmd_fifo_rd_empty)&flash_cmd_fifo_rd_data[11],flash_cmd_fifo_rd_data[10:8]};
assign flash_cmd            = flash_cmd_fifo_rd_data[7:0];
assign flash_addr           = {flash_cmd_fifo_rd_data[27:12],8'h0};

spi_driver u_spi_driver(
    .sys_clk                    (sys_clk                    ),
    .sys_rst_n                  (sys_rst_n                  ),
 
    .spi_cs                     (spi_cs                     ),
    .spi_clk_en                 (spi_clk_en                 ),
    .spi_dq1                    (spi_dq1                    ),
    .spi_dq0                    (spi_dq0                    ),

    .flash_cmd_type             (flash_cmd_type             ),
    .flash_cmd                  (flash_cmd                  ),
    .flash_addr                 (flash_addr                 ),
    .flash_wr_status            (flash_cfg_reg_data         ),
    .flash_rd_status            (flash_cfg_reg_rddata       ),
    .flash_rd_status_en         (flash_cfg_reg_rd_en        ),

    .flash_wr_data              (flash_wr_data              ),
    .flash_wr_valid             (flash_wr_valid             ),
    .flash_wr_data_eop          (flash_wr_data_eop          ),
    .flash_wr_data_fifo_rdy     (flash_wr_data_fifo_rdy     ),
    .flash_wr_data_fifo_req     (flash_wr_data_fifo_req     ),

    .flash_rd_data              (flash_rd_data              ),
    .flash_rd_valid             (flash_rd_valid             ),
    .flash_rd_data_fifo_afull   (flash_rd_data_fifo_afull   ),

    .flash_flag_status          (flash_flag_status          ),
    .erase_time_out             (erase_time_out             ),
    .reg_fifo_clear             (reg_fifo_clear             ),
    .cmd_done_ind               (cmd_done_ind               )
);

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        cmd_done_ind_dly <= 1'b0;
    else
        cmd_done_ind_dly <= cmd_done_ind;
end

assign bitstream_fifo_rd_req    = flash_wr_data_fifo_req    ;
assign flash_wr_data            = bitstream_data            ;      
assign flash_wr_valid           = bitstream_valid           ;     
assign flash_wr_data_eop        = bitstream_eop             ;       
assign flash_wr_data_fifo_rdy   = bitstream_fifo_rd_rdy     ;

assign flash_rd_valid_o         = ((flash_cmd == 8'h03 && bitstream_up2cpu_en == 1'b1) || flash_cmd == 8'h9e) ? flash_rd_valid : 1'b0;//READ CMD or read flash id;
assign flash_rd_data_o          = flash_rd_data ;
//------------------------------------------------------------------------------
//CRC32
//------------------------------------------------------------------------------

localparam              DE_SYNC_CODE    = 64'hA8800001_0000000B;
reg         [63:0]      de_sync_reg     ;
reg                     bs_stop_ind     ;
reg         [8:0]       bs_non_cnt      ;

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        bs_non_cnt <= 9'h1ff;
    else if(flash_rd_en == 1'b1 && flash_rd_en_dly == 1'b0)
        bs_non_cnt <= 9'h1ff;
    else if(de_sync_reg == DE_SYNC_CODE)
        bs_non_cnt <= 9'h0;
    else if(bs_non_cnt < 9'h1ff && flash_rd_valid == 1'b1)
        bs_non_cnt <= bs_non_cnt + 1'b1;
    else
        ;
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        bs_stop_ind <= 1'b0;
    else if(flash_rd_en == 1'b1 && flash_rd_en_dly == 1'b0)
        bs_stop_ind <= 1'b0;
    else if(bs_non_cnt == 9'd399)
        bs_stop_ind <= 1'b1;
    else
        ;
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        de_sync_reg <= 64'h0;
    else if(flash_rd_en == 1'b1 && flash_rd_en_dly == 1'b0)
        de_sync_reg <= 32'h0;
    else if(flash_rd_valid == 1'b1)
        de_sync_reg <= {de_sync_reg[55:0],flash_rd_data};
    else
        ;
end


always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        f_crc32_temp <= 32'hffff_ffff;
    else if(flash_rd_en == 1'b1 && flash_rd_en_dly == 1'b0)
        f_crc32_temp <= 32'hffff_ffff;
    else if(flash_rd_valid == 1'b1 && bs_stop_ind == 1'b0)
        f_crc32_temp <= f_crc(flash_rd_data,f_crc32_temp,"NORMAL","CRC_32",8);
    else
        ;
end

always @ (posedge sys_clk or negedge sys_rst_n)
    if (sys_rst_n==1'b0)     
        bitstream_rd_done_dly <= 1'b0;
    else
        bitstream_rd_done_dly <= bitstream_rd_done;

assign bs_readback_crc_valid = (bitstream_rd_done == 1'b1 && bitstream_rd_done_dly == 1'b0) ? 1'b1 : 1'b0;
assign bs_readback_crc       = f_crc32_temp;

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        bs_crc_ok_ind <= 1'b0;
    else if(crc_check_en == 1'b0) 
        bs_crc_ok_ind <= 1'b1;
    else if((flash_rd_en == 1'b1 && flash_rd_en_dly == 1'b0) || (flash_wr_en == 1'b1 && flash_wr_en_dly == 1'b0))
        bs_crc_ok_ind <= 1'b0;
    else if(bs_crc32_ok[1] == 1'b1)
        bs_crc_ok_ind <= 1'b1;
    else
        ;
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0) 
    begin    
        write_sw_code_en_1dly <= 1'b0;
        write_sw_code_en_2dly <= 1'b0;
    end
    else 
    begin    
        write_sw_code_en_1dly <= write_sw_code_en;
        write_sw_code_en_2dly <= write_sw_code_en_1dly;
    end
end

assign write_sw_code = (write_sw_code_en_2dly == 1'b0 && write_sw_code_en_1dly == 1'b1 && bs_crc_ok_ind == 1'b1) ? 1'b1 : 1'b0;

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)   
        clear_sw_en_dly <= 1'b0;
    else 
        clear_sw_en_dly <= clear_sw_en;
end

assign clear_sw_en_pos = (clear_sw_en_dly == 1'b0 && clear_sw_en == 1'b1) ? 1'b1 : 1'b0;
//---------------------------------------------------------------------------------------------------------------------------
function [31:0] f_crc;
input [31:0]   din;       // the width of data is [DW-1:0], 0<DW<32
input [31:0]   cin;       // last crc result, width is [CW-1:0], depend on crc type
input [55:0]   bit_order; // "REVERSE" or "NORMAL"
input [71:0]   crc_type;  // "CRC_32", "CRC_META", "CRC_CCITT", "CRC_24", "CRC_16", "CRC_12", "CRC_8", "CRC_7", "CRC_4"
input [5:0]    DW;        // 0<DW<=32

reg   [31:0]   ge;
reg   [31:0]   ct;
reg            fb;
reg   [31:0]   co;
integer        i;
integer        j;
integer        CW;

begin
    if (crc_type=="CRC_32")
    begin
        ge[31:0] = 32'b0000_0100_1100_0001_0001_1101_1011_0111;
        CW       = 32;
    end
    else if (crc_type=="CRC_META")
    begin
        ge[31:0] = 32'b0001_1110_1101_1100_0110_1111_0100_0001;
        CW       = 32;
    end
    else if (crc_type=="CRC_CCITT")
    begin
        ge[15:0] = 16'b0001_0000_0010_0001;
        CW       = 16;
    end
    else if (crc_type=="CRC_24")
    begin
        ge[23:0] = 24'b0011_0010_1000_1011_0110_0011;
        CW       = 24;
    end
    else if (crc_type=="CRC_16")
    begin
        ge[15:0] = 16'b1000_0000_0000_0101;
        CW       = 16;
    end
    else if (crc_type=="CRC_12")
    begin
        ge[11:0] = 12'b1000_0000_1111;
        CW       = 12;
    end
    else if (crc_type=="CRC_8")
    begin
        ge[7:0]  = 8'b0000_0111;
        CW       = 8;
    end
    else if (crc_type=="CRC_7")
    begin
        ge[6:0]  = 7'b000_1001;
        CW       = 7;
    end
    else if (crc_type=="CRC_4")
    begin
        ge[3:0]  = 4'b0011;
        CW       = 4;
    end
    else
    begin
        $display("function f_crc has a error parameter for 'crc_type'");
        ge[31:0] = 32'b0000_0100_1100_0001_0001_1101_1011_0111;
        CW       = 32;
    end

    if (bit_order=="NORMAL")
        ct = cin;
    else if (bit_order=="REVERSE")
    begin
        for (i=0; i<CW; i=i+1)
            ct[i] = cin[CW-1-i];
    end
    else
        $display("function f_crc has a error parameter for 'bit_order'");

    for (i=DW-1; i>=0; i=i-1)
    begin
        if (bit_order=="NORMAL")
            fb = ct[CW-1] ^ din[i];
        else
            fb = ct[CW-1] ^ din[DW-1-i];
        for (j=CW-1; j>0; j=j-1)
            ct[j] = ct[j-1] ^ (fb&ge[j]);
        ct[0] = fb;
    end

    if (bit_order=="NORMAL")
        co = ct;
    else begin
        for (i=0; i<CW; i=i+1)
            co[i] = ct[CW-1-i];
    end
    f_crc = co;
end
endfunction

endmodule
