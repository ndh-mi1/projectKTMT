#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
iverilog -g2012 -o sim.vvp ../rtl/pe.v ../rtl/systolic_array.v ../tb/tb_systolic.v
vvp sim.vvp
echo "VCD: $(pwd)/wave.vcd — mở bằng GTKWave"
