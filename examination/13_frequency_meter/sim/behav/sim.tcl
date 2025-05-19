quit -sim                  
                           
if {[file exists work]} {
  file delete -force work
}                          
                           
vlib work              
vmap work work         
                           
vlib work
vmap  usim        "../../prj/frequency_meter/pango_sim_libraries/usim"
vmap  adc_e2      "../../prj/frequency_meter/pango_sim_libraries/adc_e2"
vmap  ddc_e2      "../../prj/frequency_meter/pango_sim_libraries/ddc_e2"
vmap  dll_e2      "../../prj/frequency_meter/pango_sim_libraries/dll_e2"
vmap  hsstlp_lane "../../prj/frequency_meter/pango_sim_libraries/hsstlp_lane"
vmap  hsstlp_pll  "../../prj/frequency_meter/pango_sim_libraries/hsstlp_pll"
vmap  iolhr_dft   "../../prj/frequency_meter/pango_sim_libraries/iolhr_dft"
vmap  ipal_e1     "../../prj/frequency_meter/pango_sim_libraries/ipal_e1"
vmap  ipal_e2     "../../prj/frequency_meter/pango_sim_libraries/ipal_e2"
vmap  iserdes_e2  "../../prj/frequency_meter/pango_sim_libraries/iserdes_e2"
vmap  oserdes_e2  "../../prj/frequency_meter/pango_sim_libraries/oserdes_e2"
vmap  pciegen2    "../../prj/frequency_meter/pango_sim_libraries/pciegen2"
vlog -sv -work work -mfcu -incr -suppress 2902 -f sim_file_list.f
vsim -suppress 3486,3680,3781 -voptargs="+acc" +nowarn1 -c -sva \
     frequency_meter_tb
add wave *
view wave
view structure
view signals
run 20000ns
