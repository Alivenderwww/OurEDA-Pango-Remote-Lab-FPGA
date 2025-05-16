file delete -force work
vlib  work
vmap  work work
vlog -incr +define+IPM_HSST_SPEEDUP_SIM \
C:/pango/PDS_2022.2-SP6.4/ip/module_ip/ipm2l_flex_hsstlp/ipm2l_hsstlp_eval/ipm2l_hsstlp/../../../../../arch/vendor/pango/verilog/simulation/GTP_CLKBUFG.v \
C:/pango/PDS_2022.2-SP6.4/ip/module_ip/ipm2l_flex_hsstlp/ipm2l_hsstlp_eval/ipm2l_hsstlp/../../../../../arch/vendor/pango/verilog/simulation/modelsim10.2c/hsstlp_lane_source_codes/*.vp\
C:/pango/PDS_2022.2-SP6.4/ip/module_ip/ipm2l_flex_hsstlp/ipm2l_hsstlp_eval/ipm2l_hsstlp/../../../../../arch/vendor/pango/verilog/simulation/modelsim10.2c/hsstlp_pll_source_codes/*.vp\
C:/pango/PDS_2022.2-SP6.4/ip/module_ip/ipm2l_flex_hsstlp/ipm2l_hsstlp_eval/ipm2l_hsstlp/../../../../../arch/vendor/pango/verilog/simulation/modelsim10.2c/common_lib/*.vp\
C:/pango/PDS_2022.2-SP6.4/ip/module_ip/ipm2l_flex_hsstlp/ipm2l_hsstlp_eval/ipm2l_hsstlp/../../../../../arch/vendor/pango/verilog/simulation/GTP_HSSTLP_LANE.v \
C:/pango/PDS_2022.2-SP6.4/ip/module_ip/ipm2l_flex_hsstlp/ipm2l_hsstlp_eval/ipm2l_hsstlp/../../../../../arch/vendor/pango/verilog/simulation/GTP_HSSTLP_PLL.v \
C:/pango/PDS_2022.2-SP6.4/ip/module_ip/ipm2l_flex_hsstlp/ipm2l_hsstlp_eval/ipm2l_hsstlp/../../../../../arch/vendor/pango/verilog/simulation/GTP_IOBUF.v \
-f ./pango_hsstlp_top_filelist.f -l vlog.log
vsim -novopt +define+IPM_HSST_SPEEDUP_SIM work.hsst_top_tb -l vsim.log
do pango_hsstlp_top_wave.do
run -all
