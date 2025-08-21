@echo off
set bin_path=E:/modeltech64_10.5/win64
cd E:/JiChuang_2025/PDS_Project/axi_udp_ddr/pangu_-remote_-lab/examination/show_1_led_matrix/matrix_led/sim/behav
call "%bin_path%/modelsim"   -do "do {run_behav_compile.tcl};do {run_behav_simulate.tcl}" -l run_behav_simulate.log
if "%errorlevel%"=="1" goto END
if "%errorlevel%"=="0" goto SUCCESS
:END
exit 1
:SUCCESS
exit 0
