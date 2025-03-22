quit -sim                  
                           
if {[file exists work]} {
  file delete -force work
}                          
                           
vlib work              
vmap work work         
                           
vlib work
vlog -sv -work work -mfcu -incr -suppress 2902 -f sim_file_list.f
vsim -suppress 3486,3680,3781 -voptargs="+acc" +nowarn1 -c -sva \
     axi_master_sim_tb usim.GTP_GRS
add wave *
view wave
view structure
view signals
run 20000ns
