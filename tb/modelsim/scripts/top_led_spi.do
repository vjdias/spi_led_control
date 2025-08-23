# top_led_spi.do — usa o utilitário de log

# Pasta deste .do
set HERE [file normalize [file dirname [info script]]]
cd $HERE

# Carrega módulo de logging
do [file join $HERE utils utils_logging.do]

# Nome do TB e liga log
set TB "tb_top_led_spi"
set LOGFILE [setup_logging $TB $HERE]   ;# logs em ./logs/

# Lib work
if {![file isdirectory work]} { vlib work }
vmap work work

# Compila (ajuste a ordem se precisar)
# Include root to resolve `include"src/..."` directives
vlog +incdir+../../../ -sv ../../../src/top/top_led_spi.sv
vlog -sv ../../../src/drivers/spi_slave_8.sv
vlog -sv ../../../src/drivers/spi_stream_bridge.sv
vlog -sv ../../../src/services/led_service.sv
vlog -sv ../../../src/services/main_service.sv
vlog -sv ../../../src/protocol/protocol_rx.sv
vlog -sv ../../../src/protocol/protocol_tx.sv
vlog -sv ../../../src/protocol/formatters/tx_formatter_led.sv
vlog -sv ../../../src/protocol/formatters/tx_arbiter.sv
vlog -sv ../../../src/protocol/parsers/rx_router.sv
vlog -sv ../../../src/protocol/parsers/rx_parser_led.sv
vlog -sv ../../../src/protocol/codecs/codec_led.sv
vlog -sv ../../../src/protocol/interfaces/cmd_if_led.sv
vlog -sv ../../../src/protocol/interfaces/stream_if.sv
vlog -sv ../../../src/protocol/messages/msg_led.sv
vlog -sv ../../../src/protocol/framings/framing_pkg.sv
vlog -sv ../../../src/protocol/cmd/led_cmd_pkg.sv

# Testbench
vlog -sv ../${TB}.sv

# Simulação
vsim -c $TB -do "run -all; quit -f"

# Desliga log
finish_logging
