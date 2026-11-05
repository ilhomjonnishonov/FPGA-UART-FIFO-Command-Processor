@echo off
REM Day03_FIFO loyihasini GitHub ga yuklash uchun tezkor CMD buyrug'i
cd /d "D:\FPGA_projects\Day03_FIFO"
powershell -ExecutionPolicy Bypass -File "D:\FPGA_projects\Day03_FIFO\push_to_github.ps1" %*
pause
