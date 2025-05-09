quit -sim                  
                           
if {[file exists work]} {
  file delete -force work
}                          
                           
vlib work              
vmap work work         
                           
vlib work
vmap  work ./work
vmap  usim "E:/JiChuang_2025/ebf_pg2l100h_tutorial_code_20231227/47_eth_udp_loop/pds_prj/pango_sim_libraries/usim"
vmap  adc_e2 "E:/JiChuang_2025/ebf_pg2l100h_tutorial_code_20231227/47_eth_udp_loop/pds_prj/pango_sim_libraries/adc_e2"
vmap  ddc_e2 "E:/JiChuang_2025/ebf_pg2l100h_tutorial_code_20231227/47_eth_udp_loop/pds_prj/pango_sim_libraries/ddc_e2"
vmap  dll_e2 "E:/JiChuang_2025/ebf_pg2l100h_tutorial_code_20231227/47_eth_udp_loop/pds_prj/pango_sim_libraries/dll_e2"
vmap  hsstlp_lane "E:/JiChuang_2025/ebf_pg2l100h_tutorial_code_20231227/47_eth_udp_loop/pds_prj/pango_sim_libraries/hsstlp_lane"
vmap  hsstlp_pll "E:/JiChuang_2025/ebf_pg2l100h_tutorial_code_20231227/47_eth_udp_loop/pds_prj/pango_sim_libraries/hsstlp_pll"
vmap  iolhr_dft "E:/JiChuang_2025/ebf_pg2l100h_tutorial_code_20231227/47_eth_udp_loop/pds_prj/pango_sim_libraries/iolhr_dft"
vmap  ipal_e1 "E:/JiChuang_2025/ebf_pg2l100h_tutorial_code_20231227/47_eth_udp_loop/pds_prj/pango_sim_libraries/ipal_e1"
vmap  ipal_e2 "E:/JiChuang_2025/ebf_pg2l100h_tutorial_code_20231227/47_eth_udp_loop/pds_prj/pango_sim_libraries/ipal_e2"
vmap  iserdes_e2 "E:/JiChuang_2025/ebf_pg2l100h_tutorial_code_20231227/47_eth_udp_loop/pds_prj/pango_sim_libraries/iserdes_e2"
vmap  oserdes_e2 "E:/JiChuang_2025/ebf_pg2l100h_tutorial_code_20231227/47_eth_udp_loop/pds_prj/pango_sim_libraries/oserdes_e2"
vmap  pciegen2 "E:/JiChuang_2025/ebf_pg2l100h_tutorial_code_20231227/47_eth_udp_loop/pds_prj/pango_sim_libraries/pciegen2"
vlog -sv -work work -mfcu -incr -suppress 2902 -f sim_file_list.f
vsim -suppress 3486,3680,3781 -voptargs="+acc" +nowarn1 -c -sva \
     -L work -L usim -L adc_e2 -L ddc_e2 -L dll_e2 -L hsstlp_lane -L hsstlp_pll -L iolhr_dft -L ipal_e1 -L ipal_e2 -L iserdes_e2 -L oserdes_e2 -L pciegen2\
     dso_test usim.GTP_GRS
add wave *
view wave
view structure
view signals
