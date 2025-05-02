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
module spi_top(
input               sys_clk                 ,
input               sys_rst_n               ,
 
output              spi_cs                  ,
output              spi_clk_en              ,
input               spi_dq1                 ,
output              spi_dq0                 ,

//----- ctrl ----------------------------------

input               flash_wr_en             ,
input       [11:0]  start_wr_sector         ,
input       [15:0]  wr_sector_num           ,
output reg          flash_wr_done           ,
output reg          flash_clear_done        ,

input               flash_rd_en             ,
input       [11:0]  start_rd_sub_sector     ,
input       [15:0]  rd_sector_num           ,
output reg          flash_rd_done           ,

input               bitstream_up2cpu_en     ,
input               crc_check_en            ,
input       [1:0]   bs_crc32_ok             ,//[1]:valid   [0]:1'b0,OK  1'b1,error
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

reg         [1:0]   flash_cmd_wr_cnt            ;
reg         [15:0]  sub_sector_clear_num        ;//4KB number
reg         [15:0]  sub_sector_wr_num           ;//4KB number
reg         [15:0]  sub_sector_rd_num           ;//4KB number
reg         [15:0]  sub_sector_wr_cnt           ;
reg         [15:0]  sub_sector_rd_cnt           ;

reg         [5:0]   spi_cur_state               ;
reg         [5:0]   spi_nxt_state               ;

reg                 write_clear_cmd_done        ;
reg                 bitstream_wr_cmd_done       ;
reg                 bitstream_rd_cmd_done       ;

reg                 bitstream_rd_done_dly       ;

reg         [31:0]  f_crc32_temp                ;
reg                 bs_crc_ok_ind               ;

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
localparam          SPI_IDLE            = 6'b00_0001   ;
localparam          SPI_CFG_REG         = 6'b00_0010   ;   //wr/rd cfg register
localparam          SPI_READ_DATA       = 6'b00_0100   ;   //rd memory data
localparam          SPI_WRITE_DATA      = 6'b00_1000   ;   //wr memory data
localparam          SPI_WRITE_CLEAR     = 6'b01_0000   ;   //clear subsector before wr memory data
localparam          SPI_DONE            = 6'b10_0000   ;

//-----------------------------------------------------------
always @ (posedge sys_clk or negedge sys_rst_n)
    if (sys_rst_n==1'b0)     
        flash_wr_done <= 1'b0;
    else if (flash_wr_en == 1'b1 && flash_wr_en_dly == 1'b0)     
        flash_wr_done <= 1'b0;
    else if(bitstream_wr_cmd_done == 1'b1 && flash_cmd_fifo_rd_empty == 1'b1) 
        flash_wr_done <= 1'b1;
    else
        ;

always @ (posedge sys_clk or negedge sys_rst_n)
    if (sys_rst_n==1'b0)     
        flash_rd_done <= 1'b0;
    else if (flash_rd_en == 1'b1 && flash_rd_en_dly == 1'b0)     
        flash_rd_done <= 1'b0;
    else if(bitstream_rd_cmd_done == 1'b1 && flash_cmd_fifo_rd_empty == 1'b1) 
        flash_rd_done <= 1'b1;
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

assign reg_fifo_clear    = (flash_wr_en == 1'b1 || flash_wr_en_dly == 1'b1) ? 1'b1 : 1'b0;
//-----------------------------------------------------------

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
       sub_sector_clear_num <= 16'd0; 
    else if(flash_wr_en == 1'b1 && flash_wr_en_dly == 1'b0)
       sub_sector_clear_num <= start_wr_sector + wr_sector_num - 1'b1;
    else
        ;
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        sub_sector_wr_num <= 16'd0; 
    else if(flash_wr_en == 1'b1 && flash_wr_en_dly == 1'b0)
        sub_sector_wr_num <= wr_sector_num - 1'b1; 
    else
        ;
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
       sub_sector_rd_num <= 16'd0; 
    else if(flash_rd_en == 1'b1 && flash_rd_en_dly == 1'b0)
        sub_sector_rd_num <= rd_sector_num - 1'b1; 
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
always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        flash_clear_mem_addr <= 16'h0; 
    else if(flash_wr_en == 1'b1 && flash_wr_en_dly == 1'b0)
        flash_clear_mem_addr <= start_wr_sector;
    else if(spi_cur_state == SPI_WRITE_CLEAR && flash_cmd_wr_cnt == 2'b11 && flash_cmd_fifo_wr_afull == 1'b0)
    begin
        if(flash_clear_mem_addr[3:0] != 4'h0)   
            flash_clear_mem_addr <= flash_clear_mem_addr + 16'b1;   // subsector earse 
        else
            flash_clear_mem_addr <= flash_clear_mem_addr + 16'h10;  // sector earse 
    end
    else 
       ;
end



always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        flash_wr_mem_addr <= 16'h0; 
    else if(flash_wr_en == 1'b1 && flash_wr_en_dly == 1'b0)
        flash_wr_mem_addr <= {start_wr_sector,4'h0};
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
        flash_rd_mem_addr <= {start_rd_sub_sector,4'h0};
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
                        if(flash_clear_mem_addr[3:0] != 4'h0)
                            flash_cmd_fifo_wr_data  <= {flash_clear_mem_addr,4'b0,4'b1101,CMD_SSE}; //write subsector clear cmd
                        else
                            flash_cmd_fifo_wr_data  <= {flash_clear_mem_addr,4'b0,4'b1101,CMD_SE};  //write sector clear cmd
                    end
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
        bitstream_rd_done_dly <= flash_rd_done;

assign bs_readback_crc_valid = (flash_rd_done == 1'b1 && bitstream_rd_done_dly == 1'b0) ? 1'b1 : 1'b0;
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
