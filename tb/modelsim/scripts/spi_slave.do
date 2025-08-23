# spi_slave.do — usa o utilitário de log

set HERE [file normalize [file dirname [info script]]]
cd $HERE

do [file join $HERE utils utils_logging.do]

set TB "tb_spi_slave"
set LOGFILE [setup_logging $TB $HERE]

if {![file isdirectory work]} { vlib work }
vmap work work

vlog -sv ../../../src/drivers/spi_slave_8.sv
vlog -sv ../${TB}.sv

vsim -c $TB -do "run -all; quit -f"

finish_logging
