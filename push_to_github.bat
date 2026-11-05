@echo off
REM Automated single-command Git initialization and GitHub publisher
cd /d "D:\FPGA_projects\Day03_FIFO"
powershell -ExecutionPolicy Bypass -File "D:\FPGA_projects\Day03_FIFO\push_to_github.ps1" %*
pause
