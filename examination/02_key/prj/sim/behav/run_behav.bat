@echo off
set bin_path=E:/modeltech64_10.5/win64
cd D:/pango_fire/PG2L100H/10_key_filter/pds_prj/sim/behav
call "%bin_path%/modelsim"   -do "do {run_behav_compile.tcl};do {run_behav_simulate.tcl}" -l run_behav_simulate.log
if "%errorlevel%"=="1" goto END
if "%errorlevel%"=="0" goto SUCCESS
:END
exit 1
:SUCCESS
exit 0
