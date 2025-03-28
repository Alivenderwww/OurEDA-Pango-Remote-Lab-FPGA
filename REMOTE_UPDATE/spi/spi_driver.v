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
module spi_driver(
input               sys_clk                 ,
input               sys_rst_n               ,
 
output              spi_cs                  ,
output              spi_clk_en              ,
input               spi_dq1                 ,
output              spi_dq0                 ,

input       [3:0]   flash_cmd_type          ,//[3]: 1'b1,valid  1'b0,not valid ; [2]: 1'b1,wr  1'b0,rd  ; [1]: 1'b1,have data   1'b0,no data ; [0]: 1'b1,need addr  1'b0,no addr.
input       [7:0]   flash_cmd               ,
input       [23:0]  flash_addr              ,
input       [15:0]  flash_wr_status         ,
output      [15:0]  flash_rd_status         ,
output              flash_rd_status_en      ,

input       [7:0]   flash_wr_data           ,
input               flash_wr_valid          ,
input               flash_wr_data_eop       ,
input               flash_wr_data_fifo_rdy  ,
output              flash_wr_data_fifo_req  ,

output      [7:0]   flash_rd_data           ,
output              flash_rd_valid          ,
input               flash_rd_data_fifo_afull,

output      [15:0]  flash_flag_status       ,
output              erase_time_out          ,
input               reg_fifo_clear          ,
output              cmd_done_ind                
);
//-----------------------------------------------------------
// 
//-----------------------------------------------------------
reg                 spi_cs_reg                  ;
reg                 spi_clk_out_en              ;
reg                 spi_dq0_reg                 ;

reg         [7:0]   temp_rd_data                ;
reg                 temp_data_valid             ;
//p_e_bit = ~wip_bit
reg                 wip_bit                     ;//wip_bit = status[0],1'b0:device is ready , 1'b1:device is busy.
reg                 p_e_bit                     ;//p_e_bit = flag_status[7],1'b1:device is ready , 1'b0:device is busy.

reg         [4:0]   cmd_addr_bit_cnt            ;
reg         [3:0]   byte_bit_cnt                ;
reg         [7:0]   page_byte_cnt               ;
reg         [7:0]   read_data_len               ;
reg         [7:0]   write_data_len              ;

reg         [5:0]   driver_cur_state            ;
reg         [5:0]   driver_nxt_state            ;

reg         [15:0]  flash_rd_status_reg         ;
reg                 flash_rd_status_en_reg      ;

wire                write_data_done             ;
reg                 read_data_done              ;
reg         [26:0]  cnt_3s                      ;
reg         [15:0]  flag_status                 ;
reg                 time_out_ind                ;

//-----------------------------------------------------------
//spi driver state
localparam          IDLE                = 6'b00_0001    ;
localparam          SEND_CMD            = 6'b00_0010    ; 
localparam          SEND_ADDR           = 6'b00_0100    ;
localparam          READ_DATA           = 6'b00_1000    ;
localparam          WRITE_DATA          = 6'b01_0000    ;
localparam          CMD_DONE            = 6'b10_0000    ; 

localparam          TIME_3S             = 27'd75100000  ;//25MHz,sector erase max 3s

localparam          CMD_RDWIP           = 8'h05         ;//read status register
localparam          CMD_RDFLSR          = 8'h70         ;//read flag status register
//-----------------------------------------------------------
always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        driver_cur_state <= IDLE; 
    else if(reg_fifo_clear == 1'b1)
        driver_cur_state <= IDLE; 
    else 
        driver_cur_state <= driver_nxt_state; 
end

always @ (*)
begin
    case(driver_cur_state)
        IDLE:
        begin
            if(flash_cmd_type[3] == 1'b1)
            begin   // read memory data && flash_rd_data_fifo_afull=1'b1 ----> wait for fifo not afull ; write memory data && flash_wr_data_fifo_rdy=1'b0 ----> wait for data fifo ready
                if((flash_cmd_type[2:0] == 3'b011 && flash_rd_data_fifo_afull == 1'b1) || (flash_cmd_type[2:0] == 3'b111 && flash_wr_data_fifo_rdy == 1'b0))
                    driver_nxt_state = IDLE;
                else
                    driver_nxt_state = SEND_CMD;
            end
            else
                driver_nxt_state = IDLE;
        end
        SEND_CMD:
        begin
            if(cmd_addr_bit_cnt >= 5'd7)
            begin
                if(flash_cmd_type[0] == 1'b1)           //have addr ---> read/write memory or clear 
                    driver_nxt_state = SEND_ADDR;
                else if(flash_cmd_type[1] == 1'b0)      //no addr & no data ---> write en or clear status ... 
                    driver_nxt_state = CMD_DONE;
                else if(flash_cmd_type[2] == 1'b1)      //no addr & have data & write ---> write register 
                    driver_nxt_state = WRITE_DATA;
                else                                    //no addr & have data & read ---> read register  or read flash id                           
                    driver_nxt_state = READ_DATA;          
            end 
            else  
                driver_nxt_state = SEND_CMD;
        end
        SEND_ADDR:
        begin
            if(cmd_addr_bit_cnt >= 5'd31)
            begin
                if(flash_cmd_type[1] == 1'b0)           // no data ---> clear cmd 
                    driver_nxt_state = CMD_DONE;
                else if(flash_cmd_type[2] == 1'b0)      //read memory 
                    driver_nxt_state = READ_DATA;
                else                                    //write memory 
                    driver_nxt_state = WRITE_DATA;
            end
            else  
                driver_nxt_state = SEND_ADDR;
        end
        READ_DATA:
        begin
            if(read_data_done == 1'b1)
                driver_nxt_state = CMD_DONE;
            else  
                driver_nxt_state = READ_DATA;
        end
        WRITE_DATA:
        begin
            if(write_data_done == 1'b1)
                driver_nxt_state = CMD_DONE;
            else  
                driver_nxt_state = WRITE_DATA;
        end
        CMD_DONE:
        begin
            driver_nxt_state = IDLE;
        end
        default:driver_nxt_state = IDLE;
    endcase
     
end

assign write_data_done = (page_byte_cnt >= write_data_len && byte_bit_cnt[2:0] == 3'd7) ? 1'b1 : 1'b0;
assign erase_time_out  = time_out_ind;

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        read_data_done <= 1'b0;
    else if(driver_cur_state == READ_DATA)
    begin
        if(flash_cmd == CMD_RDWIP)
            read_data_done <=(~wip_bit)|time_out_ind;
        else if(page_byte_cnt >= read_data_len && byte_bit_cnt[2:0] == 3'd7)
            read_data_done <= 1'b1;
        else        
            ;
    end
    else
        read_data_done <= 1'b0;
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        write_data_len <= 8'b0;
    else if(driver_cur_state == SEND_CMD)
    begin
        if(flash_cmd_type[2:0] == 3'b110)           //write cfg register
        begin
            if(flash_cmd == 8'hb1)
                write_data_len <= 8'd1;             //write non volatile cfg register, 2 bytes
            else
                write_data_len <= 8'd0;             //write volatile cfg register, 1 byte
        end
        else
            write_data_len <= 8'd255;
    end
    else if(driver_cur_state == CMD_DONE)
        write_data_len <= 8'b0;
    else
        ;
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        read_data_len <= 8'b0;
    else if(driver_cur_state == SEND_CMD)
    begin
        if(flash_cmd_type[2:0] == 3'b010)
        begin
            if(flash_cmd == 8'h9e)                  //read flash id
                read_data_len <= 8'd19;
            else
                read_data_len <= 8'd1;              //read cfg register
        end
        else
            read_data_len <= 8'd255;
    end
    else if(driver_cur_state == CMD_DONE)
        read_data_len <= 8'b0;
    else
        ;
end

//------------------------------------------------------------------------------------
always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        cmd_addr_bit_cnt <= 5'b0;
    else if(driver_cur_state == SEND_CMD || driver_cur_state == SEND_ADDR)
        cmd_addr_bit_cnt <= cmd_addr_bit_cnt + 1'b1;
    else
        cmd_addr_bit_cnt <= 5'b0;
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        byte_bit_cnt <= 4'b0;
    else if(driver_cur_state == READ_DATA || driver_cur_state == WRITE_DATA)
        byte_bit_cnt <= byte_bit_cnt + 1'b1;
    else
        byte_bit_cnt <= 4'b0;
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)     
        page_byte_cnt <= 8'b0;
    else if(driver_cur_state == READ_DATA || driver_cur_state == WRITE_DATA)
    begin
        if(byte_bit_cnt[2:0] == 3'd7)
            page_byte_cnt <= page_byte_cnt + 1'b1;
        else
            ;
    end
    else
        page_byte_cnt <= 8'b0;
end

//-----------------------------------------------------------------------------------
assign spi_cs       = spi_cs_reg;
assign spi_dq0      = spi_dq0_reg;
assign spi_clk_en   = spi_clk_out_en;

//----------------------------------------------------------------------------------
always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)   
        temp_rd_data <= 8'b0;
    else if(driver_cur_state ==READ_DATA)// latch read data 
        temp_rd_data <= {temp_rd_data[6:0],spi_dq1};
    else
        ;
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)   
        temp_data_valid <= 1'b0;
    else if(driver_cur_state ==READ_DATA && byte_bit_cnt[2:0] == 3'd7)
        temp_data_valid <= 1'b1;
    else
        temp_data_valid <= 1'b0;
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)   
        flash_rd_status_reg <= 16'b0;
    else if(temp_data_valid == 1'b1 && flash_cmd_type[2:0] == 3'b010)//read cfg register
        flash_rd_status_reg <= {flash_rd_status_reg[7:0],temp_rd_data};
    else
        ;
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)   
        flash_rd_status_en_reg <= 1'b0;
    else if(temp_data_valid == 1'b1 && flash_cmd_type[2:0] == 3'b010 && read_data_done == 1'b1 && flash_cmd != 8'h9e)//read cfg register
        flash_rd_status_en_reg <= 1'b1;
    else
        flash_rd_status_en_reg <= 1'b0;
end

assign flash_rd_status_en   = flash_rd_status_en_reg    ;
assign flash_rd_status      = flash_rd_status_reg       ;
assign flash_rd_data        = temp_rd_data              ; 
assign flash_rd_valid       = temp_data_valid           ;

// get status register 
always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)   
        wip_bit <= 1'b1;
    else if(driver_cur_state == CMD_DONE)
        wip_bit <= 1'b1;
    else if(driver_cur_state == READ_DATA && byte_bit_cnt == 4'd15) //READ STATUS CMD
        wip_bit <= spi_dq1;
    else
        ;
end

// get flag status register 
always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)   
        p_e_bit <= 1'b0;
    else if(driver_cur_state == CMD_DONE)
        p_e_bit <= 1'b0;
    else if(driver_cur_state == READ_DATA && byte_bit_cnt[2:0] == 3'd0) //READ FLAG STATUS CMD
        p_e_bit <= spi_dq1;
    else
        ;
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)   
        cnt_3s <= 27'b0;
    else if(driver_cur_state == IDLE)
        cnt_3s <= 27'b0;
    else if(driver_cur_state == READ_DATA) 
        cnt_3s <= cnt_3s + 1'b1;
    else
        ;
end

always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)   
        time_out_ind <= 1'b0;
    else if(driver_cur_state == IDLE)
        time_out_ind <= 1'b0;
    else if(driver_cur_state == READ_DATA && cnt_3s >= TIME_3S && flash_cmd == CMD_RDWIP) 
        time_out_ind <= 1'b1;
    else
        ;
end


always @ (posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0)   
        flag_status <= 16'b0;
    else if(temp_data_valid == 1'b1 && flash_cmd == CMD_RDWIP)
        flag_status <= {flag_status[7:0],temp_rd_data};
    else
        ;
end

assign flash_flag_status = flag_status;

//------------------------------------------------------------------------
assign flash_wr_data_fifo_req = (driver_cur_state ==WRITE_DATA && byte_bit_cnt[2:0] == 3'd7 && flash_wr_data_fifo_rdy == 1'b1) ? 1'b1 : 1'b0;// 3'd6

always @ (negedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n==1'b0) 
    begin    
        spi_clk_out_en  <= 1'b1; 
        spi_dq0_reg     <= 1'b1;
        spi_cs_reg      <= 1'b1;
    end 
    else
    begin 
        case(driver_cur_state)
        SEND_CMD: 
            begin
                spi_cs_reg      <= 1'b0;
                spi_clk_out_en  <= 1'b0; 
                spi_dq0_reg     <= flash_cmd[7-cmd_addr_bit_cnt];
            end
        SEND_ADDR: 
            begin
                spi_cs_reg      <= 1'b0;
                spi_clk_out_en  <= 1'b0; 
                spi_dq0_reg     <= flash_addr[31-cmd_addr_bit_cnt]; 
            end
        READ_DATA:
            begin
                spi_cs_reg      <= 1'b0;
                spi_clk_out_en  <= 1'b0; 
                spi_dq0_reg     <= 1'b1;
            end
        WRITE_DATA: 
            begin
                spi_cs_reg      <= 1'b0;
                spi_clk_out_en  <= 1'b0;

                if(flash_cmd_type[2:0] == 3'b110) //write cfg register
                begin
                    if(page_byte_cnt == 8'd0)
                       spi_dq0_reg <= flash_wr_status[7-byte_bit_cnt[2:0]];
                    else
                       spi_dq0_reg <= flash_wr_status[15-byte_bit_cnt[2:0]];
                end
                else 
                    spi_dq0_reg     <= flash_wr_data[7-byte_bit_cnt[2:0]]; 
            end
        default:
            begin
                spi_clk_out_en  <= 1'b1; 
                spi_dq0_reg     <= 1'b1;
                spi_cs_reg      <= 1'b1;
            end
        endcase
    end
end

assign cmd_done_ind = (driver_cur_state == CMD_DONE) ? 1'b1 : 1'b0;

endmodule
