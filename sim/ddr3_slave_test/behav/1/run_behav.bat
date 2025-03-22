@echo off
set bin_path=C:/modeltech64_2020.4/win64
cd C:/_Project/Verilog_AXI4/ddr_axi_test/sim/behav
call "%bin_path%/modelsim"   -do "do {run_behav_compile.tcl};do {run_behav_simulate.tcl}" -l run_behav_simulate.log
if "%errorlevel%"=="1" goto END
if "%errorlevel%"=="0" goto SUCCESS
:END
exit 1
:SUCCESS
exit 0
