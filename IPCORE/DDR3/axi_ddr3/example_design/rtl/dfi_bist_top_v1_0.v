////////////////////////////////////////////////////////////////
// Copyright (c) 2021 PANGO MICROSYSTEMS, INC
// ALL RIGHTS REVERVED.
////////////////////////////////////////////////////////////////
//Description:
//Author:
//History: v1.0
////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
module dfi_bist_top_v1_0 #(
    parameter          TRFC                 = 16,      //tRFC/4 + 1
    parameter          TRCD                 = 2 ,      //tRCD/4 + 1
    parameter          TREFI                = 580,     //tREFI/4 + 1
    parameter          DATA_MASK_EN         = 0,
    parameter          CTRL_ADDR_WIDTH      = 28,
    parameter          DATA_PATTERN0        = 8'h55,
    parameter          DATA_PATTERN1        = 8'haa,
    parameter          DATA_PATTERN2        = 8'h7f,
    parameter          DATA_PATTERN3        = 8'h80,
    parameter          DATA_PATTERN4        = 8'h55,
    parameter          DATA_PATTERN5        = 8'haa,
    parameter          DATA_PATTERN6        = 8'h7f,
    parameter          DATA_PATTERN7        = 8'h80,
    parameter          MEM_ROW_ADDR_WIDTH   = 14   ,
    parameter          MEM_COL_ADDR_WIDTH   = 10   ,
    parameter          TOTAL_ADDR_WIDTH     = 16   ,
    parameter          MEM_BANKADDR_WIDTH   = 3    ,
    parameter          MEM_BANKGROUP_WIDTH  = 0    ,
    parameter          MEM_DQS_WIDTH        = 2    ,
    parameter          MEM_DM_WIDTH         = 2    ,
    parameter          MEM_DQ_WIDTH         = 16   ,
    parameter          GATE_ACT_PRE_EN      = 1 ,
    parameter          MEM_SPACE_AW         = 18
)(
   input               core_clk        ,
   input               core_clk_rst_n  ,
   input [5:0]         mc_wl           ,
   input [1:0]         wr_mode         ,
   input [1:0]         data_mode       ,
   input               len_random_en   ,
   input [3:0]         fix_wr_len      ,
   input               bist_stop       ,
   input               ddrphy_init_done,
   input [3:0]         read_repeat_num ,
   input               data_order      ,
   input [7:0]         dq_inversion    ,
   input               insert_err      ,
   input               manu_clear      ,
   output              bist_run_led    ,
   output   [3:0]      test_main_state ,
   output   [2:0]      test_cmd_state  ,
   output   [2:0]      test_rd_state   ,

   output                             dfi_reset_n     ,
   output [4*TOTAL_ADDR_WIDTH-1:0]    dfi_address     ,
   output [4*MEM_BANKADDR_WIDTH-1:0]  dfi_bank        ,
   output [4-1:0]                     dfi_cs_n        ,
   `ifdef IPS2T_DDR4
   output [4*MEM_BANKGROUP_WIDTH-1:0] dfi_bg          ,
   output [4-1:0]                     dfi_act_n       ,
   `else
   output [4-1:0]                     dfi_ras_n       ,
   output [4-1:0]                     dfi_cas_n       ,
   output [4-1:0]                     dfi_we_n        ,
   `endif
   output [4-1:0]                     dfi_cke         ,
   output [4-1:0]                     dfi_odt         ,
   output [2*4*MEM_DQ_WIDTH-1:0]      dfi_wrdata      ,
   output [4-1:0]                     dfi_wrdata_en   ,
   output [2*4*MEM_DQ_WIDTH/8-1:0]    dfi_wrdata_mask ,
   input  [2*4*MEM_DQ_WIDTH-1:0]      dfi_rddata      ,
   input                              dfi_rddata_valid,
   input                              dfi_phyupd_req     ,
   output                             dfi_phyupd_ack     ,
   input                              ddrphy_update_done ,
   `ifdef IPS2T_DDR4
   output [MEM_BANKADDR_WIDTH-1:0]    upd_act_ba      ,
   output [MEM_BANKGROUP_WIDTH-1:0]   upd_act_bg      ,
   `endif
   output   [7:0]                     err_cnt        ,
   output                             err_flag_led   ,
   output   [MEM_DQ_WIDTH*8-1:0]      err_data_out   ,
   output   [MEM_DQ_WIDTH*8-1:0]      err_flag_out   ,
   output   [MEM_DQ_WIDTH*8-1:0]      exp_data_out   ,
   output                             next_err_flag  ,
   output   [MEM_DQS_WIDTH-1:0]       err_flag_out_group,
   output   [15:0]                    result_bit_out ,
   output   [MEM_DQ_WIDTH*8-1:0]      next_err_data  ,
   output   [MEM_DQ_WIDTH*8-1:0]      err_data_pre   ,
   output   [MEM_DQ_WIDTH*8-1:0]      err_data_aft
   );

   wire pattern_en    ;
   wire random_data_en;
   wire read_repeat_en;
   wire stress_test   ;
   wire write_to_read ;

   wire [CTRL_ADDR_WIDTH-1:0] random_rw_addr;
//   wire [3:0] random_axi_id;
   wire [3:0] random_len;
//   wire       random_axi_ap;

   wire       init_start   ;
   wire       init_done    ;
   wire       write_en     ;
   wire       write_done_p ;
   wire       read_en      ;
   wire       read_done_p  ;

   reg        data_order_d0;
   reg        data_order_d1;
   reg [7:0]  dq_inversion_d0;
   reg [7:0]  dq_inversion_d1;
   reg [3:0]  read_repeat_num_d0;
   reg [3:0]  read_repeat_num_d1;
   wire       cmd_rd_start;
   wire       read_finished;
   reg        bist_stop_d0;
   reg        bist_stop_d1;

  always @(posedge core_clk or negedge core_clk_rst_n)
  begin
    if (!core_clk_rst_n)begin
    	data_order_d0 <= 0;
    	data_order_d1 <= 0;
    end
    else begin
    	data_order_d0 <= data_order;
    	data_order_d1 <= data_order_d0;
    end
  end

  always @(posedge core_clk or negedge core_clk_rst_n)
  begin
    if (!core_clk_rst_n)begin
    	dq_inversion_d0 <= 8'd0;
    	dq_inversion_d1 <= 8'd0;
    end
    else begin
    	dq_inversion_d0 <= dq_inversion;
    	dq_inversion_d1 <= dq_inversion_d0;
    end
  end

always @(posedge core_clk or negedge core_clk_rst_n)
begin
  if (!core_clk_rst_n)begin
   	read_repeat_num_d0 <= 4'd0;
   	read_repeat_num_d1 <= 4'd0;
  end
  else begin
  	read_repeat_num_d0 <= read_repeat_num;
   	read_repeat_num_d1 <= read_repeat_num_d0;
  end
end

  always @(posedge core_clk or negedge core_clk_rst_n)
  begin
    if (!core_clk_rst_n)begin
    	bist_stop_d0 <= 0;
    	bist_stop_d1 <= 0;
    end
    else begin
    	bist_stop_d0 <= bist_stop;
    	bist_stop_d1 <= bist_stop_d0;
    end
  end

test_main_ctrl_v1_0 #(
  .CTRL_ADDR_WIDTH            (CTRL_ADDR_WIDTH        ),
  .MEM_DQ_WIDTH               (MEM_DQ_WIDTH           ),
  .MEM_SPACE_AW               (MEM_SPACE_AW           )
) u_test_main_ctrl (
  .clk                        (core_clk               ),
  .rst_n                      (core_clk_rst_n         ),
  .wr_mode                    (wr_mode                ),
  .data_mode                  (data_mode              ),
  .len_random_en              (len_random_en          ),
  .fix_axi_len                (fix_wr_len             ),
  .bist_stop                  (bist_stop_d1           ),
  .random_rw_addr             (random_rw_addr         ),
  .random_axi_id              (                   ),
  .random_axi_len             (random_len         ),
  .random_axi_ap              (                   ),
  .pattern_en                 (pattern_en             ),
  .random_data_en             (random_data_en         ),
  .read_repeat_en             (read_repeat_en         ),
  .stress_test                (stress_test            ),
  .write_to_read              (write_to_read          ),
  .ddrc_init_done             (ddrphy_init_done       ),
  .init_start                 (init_start             ),
  .init_done                  (init_done              ),
  .write_en                   (write_en               ),
  .write_done_p               (write_done_p           ),
  .read_en                    (read_en                ),
  .read_done_p                (read_done_p            ),
  .bist_run_led               (bist_run_led           ),
  .test_main_state            (test_main_state        )
);

dfi_cmd_gen_v1_0 #(
  .TRFC                    (TRFC                   ),   //tRFC/4 + 1
  .TRCD                    (TRCD                   ),   //tRCD/4 + 1
  .TREFI                   (TREFI                  ),   //tREFI/4 + 1
  .DATA_PATTERN0           (DATA_PATTERN0          ),
  .DATA_PATTERN1           (DATA_PATTERN1          ),
  .DATA_PATTERN2           (DATA_PATTERN2          ),
  .DATA_PATTERN3           (DATA_PATTERN3          ),
  .DATA_PATTERN4           (DATA_PATTERN4          ),
  .DATA_PATTERN5           (DATA_PATTERN5          ),
  .DATA_PATTERN6           (DATA_PATTERN6          ),
  .DATA_PATTERN7           (DATA_PATTERN7          ),
  .DATA_MASK_EN            (DATA_MASK_EN           ),
  .CTRL_ADDR_WIDTH         (CTRL_ADDR_WIDTH        ),
  .MEM_ROW_ADDR_WIDTH      (MEM_ROW_ADDR_WIDTH     ),
  .MEM_COL_ADDR_WIDTH      (MEM_COL_ADDR_WIDTH     ),
  .TOTAL_ADDR_WIDTH        (TOTAL_ADDR_WIDTH       ),
  .MEM_BANKADDR_WIDTH      (MEM_BANKADDR_WIDTH     ),
  .MEM_BANKGROUP_WIDTH     (MEM_BANKGROUP_WIDTH    ),
  .MEM_DQS_WIDTH           (MEM_DQS_WIDTH          ),
  .MEM_DM_WIDTH            (MEM_DM_WIDTH           ),
  .MEM_DQ_WIDTH            (MEM_DQ_WIDTH           ),
  .GATE_ACT_PRE_EN         (GATE_ACT_PRE_EN        ),
  .MEM_SPACE_AW            (MEM_SPACE_AW           )
)u_dfi_cmd_gen(
  .clk                  (core_clk            ),
  .rst_n                (core_clk_rst_n      ),
  .mc_wl                (mc_wl               ),
  .init_start           (init_start          ),
  .write_en             (write_en            ),
  .read_en              (read_en             ),
  .insert_err           (insert_err          ),
  .write_done_p         (write_done_p        ),
  .read_done_p          (read_done_p         ),
  .read_finished        (read_finished       ),
  .init_done            (init_done           ),
  .pattern_en           (pattern_en          ),
  .random_data_en       (random_data_en      ),
  .stress_test          (stress_test         ),
  .write_to_read        (write_to_read       ),
  .read_repeat_en       (read_repeat_en      ),
  .data_order           (data_order_d1       ),
  .dq_inversion         (dq_inversion_d1     ),
  .read_repeat_num      (read_repeat_num_d1  ),
  .random_rw_addr       (random_rw_addr      ),
  .random_len           (random_len          ),
  .dfi_phyupd_req       (dfi_phyupd_req      ),
  .dfi_phyupd_ack       (dfi_phyupd_ack      ),
  .ddrphy_update_done   (ddrphy_update_done  ),
  .state                (test_cmd_state      ),
  .cmd_rd_start         (cmd_rd_start        ),

  .dfi_reset_n          (dfi_reset_n       ),
  .dfi_address          (dfi_address       ),
  .dfi_bank             (dfi_bank          ),
  .dfi_cs_n             (dfi_cs_n          ),
  `ifdef IPS2T_DDR4
  .dfi_bg               (dfi_bg            ),
  .dfi_act_n            (dfi_act_n         ),
  `else
  .dfi_ras_n            (dfi_ras_n         ),
  .dfi_cas_n            (dfi_cas_n         ),
  .dfi_we_n             (dfi_we_n          ),
  `endif
  .dfi_cke              (dfi_cke           ),
  .dfi_odt              (dfi_odt           ),
  .dfi_wrdata           (dfi_wrdata        ),
  .dfi_wrdata_en        (dfi_wrdata_en     ),
  .dfi_wrdata_mask      (dfi_wrdata_mask   )
  `ifdef IPS2T_DDR4
  ,
  .upd_act_ba           (upd_act_ba        ),
  .upd_act_bg           (upd_act_bg        )
  `endif
);

 dfi_rddata_check_v1_0 #(
  .DATA_PATTERN0          (DATA_PATTERN0         ),
  .DATA_PATTERN1          (DATA_PATTERN1         ),
  .DATA_PATTERN2          (DATA_PATTERN2         ),
  .DATA_PATTERN3          (DATA_PATTERN3         ),
  .DATA_PATTERN4          (DATA_PATTERN4         ),
  .DATA_PATTERN5          (DATA_PATTERN5         ),
  .DATA_PATTERN6          (DATA_PATTERN6         ),
  .DATA_PATTERN7          (DATA_PATTERN7         ),
  .DATA_MASK_EN           (DATA_MASK_EN          ),
  .CTRL_ADDR_WIDTH        (CTRL_ADDR_WIDTH       ),
  .MEM_ROW_ADDR_WIDTH     (MEM_ROW_ADDR_WIDTH    ),
  .MEM_COL_ADDR_WIDTH     (MEM_COL_ADDR_WIDTH    ),
  .MEM_BANKADDR_WIDTH     (MEM_BANKADDR_WIDTH    ),
  .MEM_BANKGROUP_WIDTH    (MEM_BANKGROUP_WIDTH   ),
  .MEM_DQS_WIDTH          (MEM_DQS_WIDTH         ),
  .MEM_DM_WIDTH           (MEM_DM_WIDTH          ),
  .MEM_DQ_WIDTH           (MEM_DQ_WIDTH          )
 )u_dfi_rddata_check(
  .clk                (core_clk          ),
  .rst_n              (core_clk_rst_n    ),
  .cmd_rd_start       (cmd_rd_start      ),
  .read_finished      (read_finished     ),
  .pattern_en         (pattern_en        ),
  .random_data_en     (random_data_en    ),
  .stress_test        (stress_test       ),
  .write_to_read      (write_to_read     ),
  .read_repeat_en     (read_repeat_en    ),
  .data_order         (data_order_d1     ),
  .dq_inversion       (dq_inversion_d1   ),
  .read_repeat_num    (read_repeat_num_d1),
  .random_rw_addr     (random_rw_addr    ),
  .random_len         (random_len        ),
  .dfi_rddata         (dfi_rddata        ),
  .dfi_rddata_valid   (dfi_rddata_valid  ),
  .err_flag_out_group (err_flag_out_group),
  .err_cnt            (err_cnt           ),
  .err_flag_led       (err_flag_led      ),
  .err_data_out       (err_data_out      ),
  .err_flag_out       (err_flag_out      ),
  .exp_data_out       (exp_data_out      ),
  .manu_clear         (manu_clear        ),
  .next_err_flag      (next_err_flag     ),
  .result_bit_out     (result_bit_out    ),
  .state              (test_rd_state     ),
  .next_err_data      (next_err_data     ),
  .err_data_pre       (err_data_pre      ),
  .err_data_aft       (err_data_aft      )
 );

endmodule