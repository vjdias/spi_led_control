# spi_stream_bridge.do — script to run tb_spi_stream_bridge in ModelSim

# Close any existing simulation
quietly catch { quit -sim }

# Directory containing this .do
set HERE [file normalize [file dirname [info script]]]
cd $HERE

# Logging utilities
do [file join $HERE utils utils_logging.do]

# Testbench and log
set TB "tb_spi_stream_bridge"
set LOGFILE [setup_logging $TB $HERE]

# Include root for `include "src/..."`
set INCARGS "+incdir+../../../"

# Prepare work library
if {![file isdirectory work]} { vlib work }
vmap work work

# Compilation
vlog $INCARGS -sv ../../../src/protocol/interfaces/stream_if.sv
vlog $INCARGS -sv ../../../src/drivers/spi_stream_bridge.sv
vlog $INCARGS -sv ../${TB}.sv

# Simulation
vsim -c $TB -do "run -all"

# Finish logging
finish_logging
