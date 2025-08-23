# spi_slave.do — usa o utilitário de log (com proteção para sim ativa)

# Se houver uma simulação carregada, descarrega antes de qualquer cd/mapeamento
quietly catch { quit -sim }

# Diretório deste .do
set HERE [file normalize [file dirname [info script]]]
cd $HERE

# Utilitário de log
do [file join $HERE utils utils_logging.do]

# Testbench e log
set TB "tb_spi_slave"
set LOGFILE [setup_logging $TB $HERE]

# Include root (para `include "src/..."`)
set INCARGS "+incdir+../../../"

# Lib work
if {![file isdirectory work]} { vlib work }
vmap work work

# Compilação
vlog $INCARGS -sv ../../../src/drivers/spi_slave_8.sv
vlog $INCARGS -sv ../${TB}.sv

# Simulação (fecha a sim ao final)
vsim -c $TB -do "run -all"

# Fecha transcript/log
finish_logging
