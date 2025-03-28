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
module ipal_ctrl
#(
parameter USER_BITSTREAM_CNT    = 2'd3              ,   
parameter IPAL_DATA_WIDTH       = 8                 ,   // 32 16 8 
parameter USER_BITSTREAM1_ADDR  = 24'h20_b000       ,   // user bitstream1 start address  ---> [6*4KB+2068KB(2065),32MB- 2068KB(2065)],4KB align  // 24'h20_b000
parameter USER_BITSTREAM2_ADDR  = 24'h41_0000       ,   // user bitstream2 start address  ---> 24'h41_0000 
parameter USER_BITSTREAM3_ADDR  = 24'h61_5000       ,   // user bitstream3 start address  ---> 24'h61_5000
parameter U_DLY                 = 1                 
)(
input               sys_clk                 ,
input               sys_rst_n               ,

input       [1:0]   open_sw_num             ,
output              ipal_busy               ,
input               crc_check_en            ,
input       [1:0]   bs_crc32_ok             ,//[1]:valid   [0]:1'b0,OK  1'b1,error
input               hotreset_en             ,//uart cofig register
input               open_sw_code_done       
);
//--------------------------------------------------------------------------------------------
localparam FILL_DATA        = 32'hffff_ffff;
localparam SYNC_CODE        = 32'h0133_2d94;
localparam IRSTCTRLR        = 32'habc0_0001;
localparam IRSTCTRL_DATA    = 32'h0000_0000;
localparam IRSTADRR         = 32'hac00_0001;
localparam IRSTADR0_DATA    = 32'h0000_0000;
localparam CMDRADRR         = 32'ha880_0001;
localparam IRSTCMD_DATA     = 32'h0000_000f;
localparam NON_OP           = 32'ha000_0000;

//--------------------------------------------------------------------------------------------
reg     [6:0]                   data_cnt                ;
reg                             ipal_cs_n               ;//active low
reg     [IPAL_DATA_WIDTH-1:0]   ipal_data_in            ;
reg                             ipal_wr_rd              ;//1'b0:write , 1'b1:read
reg                             open_sw_code_done_1dly  ;
reg                             open_sw_code_done_2dly  ;
reg                             hotreset_en_1dly        ;
reg                             hotreset_en_2dly        ;
reg                             irsadr_sel              ;//1'b0:user bitstream  1'b1:golden bitstream 

reg     [23:0]                  user_bitstream_addr     ;
wire                            ipal_clk                ;

reg     [1:0]                   ipal_data_rd_cnt        ;
reg     [31:0]                  ipal_fifo_wr_data       ;
reg                             ipal_fifo_wr_en         ;  
wire                            ipal_fifo_rd_en         ;
wire    [31:0]                  ipal_fifo_rd_data       ;
wire                            ipal_fifo_wr_full       ;
wire                            ipal_fifo_wr_afull      ;
wire                            ipal_fifo_rd_empty      ;


//-------------------------------------------------------------------------------------------
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        irsadr_sel <= 1'b0;
    else if(crc_check_en == 1'b0)
        irsadr_sel <= 1'b0;
    else if(bs_crc32_ok[1] == 1'b1)
        irsadr_sel <= bs_crc32_ok[0];
    else 
        ;


always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
    begin
        open_sw_code_done_1dly  <= 1'b0;
        open_sw_code_done_2dly  <= 1'b0;
    end
    else 
    begin
        open_sw_code_done_1dly  <= open_sw_code_done;
        open_sw_code_done_2dly  <= open_sw_code_done_1dly;
    end

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
    begin
        hotreset_en_1dly  <= 1'b0;
        hotreset_en_2dly  <= 1'b0;
    end
    else
    begin
        hotreset_en_1dly  <= hotreset_en;
        hotreset_en_2dly  <= hotreset_en_1dly;
    end

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        data_cnt <= 7'd0;
    else if(data_cnt >= 7'd118)
        data_cnt <= data_cnt;
    else if(hotreset_en_2dly == 1'b1 && open_sw_code_done_2dly == 1'b1)
        data_cnt <= data_cnt + 7'd1;
    else
        ;

generate
    if(USER_BITSTREAM_CNT == 2'd3) 
    begin:USER_BS_CNT_3 
        always@(*)
        begin
            case(open_sw_num)
            2'b01   : user_bitstream_addr <= USER_BITSTREAM1_ADDR;
            2'b10   : user_bitstream_addr <= USER_BITSTREAM2_ADDR;
            2'b11   : user_bitstream_addr <= USER_BITSTREAM3_ADDR;
            default : user_bitstream_addr <= IRSTADR0_DATA;
            endcase
        end
    end
    else if(USER_BITSTREAM_CNT == 2'd2)
    begin:USER_BS_CNT_2
        always@(*)
        begin
            case(open_sw_num)
            2'b01   : user_bitstream_addr <= USER_BITSTREAM1_ADDR;
            2'b10   : user_bitstream_addr <= USER_BITSTREAM2_ADDR;
            default : user_bitstream_addr <= IRSTADR0_DATA;
            endcase
        end
    end
    else
    begin:USER_BS_CNT_1
        always@(*)
        begin
            case(open_sw_num)
            2'b01   : user_bitstream_addr <= USER_BITSTREAM1_ADDR;
            default : user_bitstream_addr <= IRSTADR0_DATA;
            endcase
        end
    end
endgenerate

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        ipal_fifo_wr_en   <= 1'b0;
    else if(data_cnt > 7'd0 && data_cnt <= 7'd117)
        ipal_fifo_wr_en   <= 1'b1;
    else
        ipal_fifo_wr_en   <= 1'b0;

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        ipal_fifo_wr_data   <= 32'h0;
    else if(hotreset_en_2dly == 1'b1 && open_sw_code_done_2dly == 1'b1)
    begin
        case(data_cnt)
        7'd000  :ipal_fifo_wr_data  <= FILL_DATA;
        7'd101  :ipal_fifo_wr_data  <= SYNC_CODE;
        7'd102  :ipal_fifo_wr_data  <= IRSTCTRLR;
        7'd103  :ipal_fifo_wr_data  <= IRSTCTRL_DATA;
        7'd104  :ipal_fifo_wr_data  <= IRSTADRR;
        7'd105  :
            begin 
            if(irsadr_sel == 1'b1)
                ipal_fifo_wr_data  <= IRSTADR0_DATA;             //golden bitstream
            else
                ipal_fifo_wr_data  <= {8'h0,user_bitstream_addr};//user bitstream 
            end
        7'd106  :ipal_fifo_wr_data  <= CMDRADRR;
        7'd107  :ipal_fifo_wr_data  <= IRSTCMD_DATA;
        7'd108  :ipal_fifo_wr_data  <= NON_OP;
        default :ipal_fifo_wr_data  <= ipal_fifo_wr_data;
        endcase
    end
    else
        ;

assign ipal_clk = ~sys_clk;

asyn_fifo #(
    .U_DLY                      (1                           ),
    .DATA_WIDTH                 (32                          ),
    .DATA_DEEPTH                (128                         ),
    .ADDR_WIDTH                 (7                           )
)u_ipal_fifo(
    .wr_clk                     (sys_clk                     ),
    .wr_rst_n                   (sys_rst_n                   ),
    .rd_clk                     (sys_clk                     ),
    .rd_rst_n                   (sys_rst_n                   ),
    .din                        (ipal_fifo_wr_data           ),
    .wr_en                      (ipal_fifo_wr_en             ),
    .rd_en                      (ipal_fifo_rd_en             ),
    .dout                       (ipal_fifo_rd_data           ),
    .full                       (ipal_fifo_wr_full           ),
    .prog_full                  (ipal_fifo_wr_afull          ),
    .empty                      (ipal_fifo_rd_empty          ),
    .prog_empty                 (                            ),
    .prog_full_thresh           (7'd120                      ),
    .prog_empty_thresh          (7'd1                        )
);

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
    begin
        ipal_cs_n   <= 1'b1;
        ipal_wr_rd  <= 1'b1;
    end
    else if(ipal_fifo_rd_empty == 1'b0)
    begin 
        ipal_cs_n   <= 1'b0;
        ipal_wr_rd  <= 1'b0;
    end
    else
    begin
        ipal_cs_n   <= 1'b1;
        ipal_wr_rd  <= 1'b1;
    end

generate
    if(IPAL_DATA_WIDTH == 8 || IPAL_DATA_WIDTH == 16) 
    begin : DATA_WIDTH_X8_X16
        always@(posedge sys_clk or negedge sys_rst_n)
            if(sys_rst_n == 1'b0)
                ipal_data_rd_cnt   <= 2'b0;
            else if(ipal_fifo_rd_empty == 1'b0)
                ipal_data_rd_cnt   <= ipal_data_rd_cnt + 1'b1;
            else
                ipal_data_rd_cnt   <= 2'b0;
    end
endgenerate

generate
    if(IPAL_DATA_WIDTH == 8) 
    begin : DATA_WIDTH_X8
        assign ipal_fifo_rd_en = (ipal_fifo_rd_empty == 1'b0 && ipal_data_rd_cnt == 2'b11) ? 1'b1 : 1'b0;
        
        always@(posedge sys_clk or negedge sys_rst_n)
            if(sys_rst_n == 1'b0)
                ipal_data_in   <= 32'h0;
            else 
            begin
                case(ipal_data_rd_cnt)
                2'b00   : ipal_data_in  <= ipal_fifo_rd_data[31:24];
                2'b01   : ipal_data_in  <= ipal_fifo_rd_data[23:16];
                2'b10   : ipal_data_in  <= ipal_fifo_rd_data[15: 8];
                2'b11   : ipal_data_in  <= ipal_fifo_rd_data[ 7: 0];
                default : ipal_data_in  <= ipal_data_in;
                endcase
            end
    end
    else if(IPAL_DATA_WIDTH == 16)
    begin : DATA_WIDTH_X16
        assign ipal_fifo_rd_en = (ipal_fifo_rd_empty == 1'b0 && ipal_data_rd_cnt[0] == 1'b1) ? 1'b1 : 1'b0;
        
        always@(posedge sys_clk or negedge sys_rst_n)
            if(sys_rst_n == 1'b0)
                ipal_data_in   <= 32'h0;
            else if(ipal_data_rd_cnt[0] == 1'b0) 
                ipal_data_in  <= ipal_fifo_rd_data[31:16];
            else  
                ipal_data_in  <= ipal_fifo_rd_data[15: 0];
    end
    else
    begin : DATA_WIDTH_X32
        assign ipal_fifo_rd_en = (ipal_fifo_rd_empty == 1'b0) ? 1'b1 : 1'b0;
        
        always@(posedge sys_clk or negedge sys_rst_n)
            if(sys_rst_n == 1'b0)
                ipal_data_in   <= 32'h0;
            else 
                ipal_data_in  <= ipal_fifo_rd_data;
    end
endgenerate


GTP_IPAL_E2 #(
    .DATA_WIDTH         ("X8"           ),
    .IDCODE             ('b10101010101010100101010101010101),
    .SIM_DEVICE         ("PG2L100H"     )
) GTP_IPAL_inst (
    .DO                 (               ),  // OUTPUT[31:0]  
    .ECC_INDEX          (               ),  // OUTPUT[11:0]  
    .SEU_COLUMN_ADDR    (               ),  // OUTPUT[7:0]  
    .SEU_COLUMN_NADDR   (               ),  // OUTPUT[7:0]  
    .SEU_FRAME_ADDR     (               ),  // OUTPUT[7:0]  
    .SEU_FRAME_NADDR    (               ),  // OUTPUT[7:0]  
    .SEU_REGION_ADDR    (               ),  // OUTPUT[4:0]  
    .SEU_REGION_NADDR   (               ),  // OUTPUT[4:0]  
    .DI                 (ipal_data_in   ),  // INPUT[31:0]  
    .DERROR             (               ),  // OUTPUT  
    .DRCFG_ERR          (               ),  // OUTPUT  
    .DRCFG_OVER         (               ),  // OUTPUT  
    .ECC_VALID          (ipal_busy      ),  // OUTPUT  
    .PRCFG_ERR          (               ),  // OUTPUT  
    .PRCFG_OVER         (               ),  // OUTPUT  
    .RBCRC_ERR          (               ),  // OUTPUT  
    .RBCRC_VALID        (               ),  // OUTPUT  
    .SERROR             (               ),  // OUTPUT  
    .CLK                (ipal_clk       ),  // INPUT  
    .CS_N               (ipal_cs_n      ),  // INPUT  
    .RST_N              (sys_rst_n      ),  // INPUT  
    .RW_SEL             (ipal_wr_rd     )   // INPUT  
);


endmodule
