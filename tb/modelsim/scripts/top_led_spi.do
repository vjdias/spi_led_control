# top_led_spi.do — usa o utilitário de log

# Pasta deste .do
set HERE [file normalize [file dirname [info script]]]
cd $HERE

# Carrega módulo de logging
do [file join $HERE utils utils_logging.do]

# Nome do TB e liga log
set TB "tb_top_led_spi"
set LOGFILE [setup_logging $TB $HERE]   ;# logs em ./logs/

# --- Include roots para resolver `include "src/..."` ---
# Como seu código usa includes que começam em "src/...",
# basta expor a RAIZ do projeto (3 níveis acima de scripts/)
set INCARGS "+incdir+../../../"

# Lib work
if {![file isdirectory work]} { vlib work }
vmap work work

# ------------------------------------------------------------------
# Compilação
# Observação importante:
#  - O top_led_spi.sv já faz `include de interfaces/pacotes/mensagens.
#  - Para evitar redefinições, NÃO compile esses headers/pacotes à parte.
#  - Compile apenas os módulos/arquivos que NÃO são headers "incluídos".
# ------------------------------------------------------------------

# TOP (inclui headers/pkgs via `include)
vlog $INCARGS -sv ../../../src/top/top_led_spi.sv

# Drivers / Services / Protocol (módulos)
vlog $INCARGS -sv ../../../src/drivers/spi_slave_8.sv
vlog $INCARGS -sv ../../../src/drivers/spi_stream_bridge.sv
vlog $INCARGS -sv ../../../src/services/led_service.sv
vlog $INCARGS -sv ../../../src/services/main_service.sv
vlog $INCARGS -sv ../../../src/protocol/protocol_rx.sv
vlog $INCARGS -sv ../../../src/protocol/protocol_tx.sv
vlog $INCARGS -sv ../../../src/protocol/codecs/codec_led.sv
vlog $INCARGS -sv ../../../src/protocol/formatters/tx_formatter_led.sv
vlog $INCARGS -sv ../../../src/protocol/formatters/tx_arbiter.sv
vlog $INCARGS -sv ../../../src/protocol/parsers/rx_router.sv
vlog $INCARGS -sv ../../../src/protocol/parsers/rx_parser_led.sv


#  ⚠️ NÃO compilar à parte estes arquivos porque já são incluídos pelo TOP:
#  ../../../src/protocol/interfaces/cmd_if_led.sv
#  ../../../src/protocol/interfaces/stream_if.sv
#  ../../../src/protocol/messages/msg_led.sv
#  ../../../src/protocol/framings/framing_pkg.sv
#  ../../../src/protocol/cmd/led_cmd_pkg.sv

# Testbench
vlog $INCARGS -sv ../${TB}.sv

# Simulação
vsim -c $TB -do "run -all"

# Desliga log
finish_logging
