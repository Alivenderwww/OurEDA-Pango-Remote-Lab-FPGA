../../../DSO/*.v
../dso_test.sv
../hdmi_rtl/*.v

../../../IPCORE/DSO/dso_ram_2port/rtl/dso_ram_2port_init_param.v
../../../IPCORE/DSO/dso_ram_2port/rtl/dso_ram_2port_Reset_Value.v
../../../IPCORE/DSO/dso_ram_2port/rtl/ipm2l_sdpram_v1_10_dso_ram_2port.v
../../../IPCORE/DSO/dso_ram_2port/dso_ram_2port.v


+incdir+../../../DDR3/sim_file
+incdir+../../../JTAG
+define+IPS_DDR_SPEEDUP_SIM  
+define+RTL_SIM 
+define+den4096Mb   
+define+x16         
+define+sg25E       
-sv