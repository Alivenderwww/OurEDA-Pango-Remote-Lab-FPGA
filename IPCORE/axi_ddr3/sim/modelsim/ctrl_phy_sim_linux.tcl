quit -sim
if {[file exists work]} {
  file delete -force work  
}
vlib work
vmap work work

vlog -sv \
-f ../modelsim/sim_file_list.f \

vsim ddr3_test_top_tb -suppress 3009 -voptargs="+acc" -debugDB -sva +nowarn1 -pli /mnt/edatool/tool/synopsys/verdi/Q-2020.03-SP2/share/PLI/MODELSIM/linux64/novas_fli.so
log -r sim:/ddr3_test_top_tb/*
run -all
