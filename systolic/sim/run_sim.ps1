# Chay mo phong Icarus Verilog (can iverilog trong PATH). Chay: .\run_sim.ps1
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
iverilog -g2012 -o sim.vvp ../rtl/pe.v ../rtl/systolic_array.v ../tb/tb_systolic.v
vvp sim.vvp
Write-Host "Xong. Neu testbench co dump VCD thi mo wave.vcd bang GTKWave."
