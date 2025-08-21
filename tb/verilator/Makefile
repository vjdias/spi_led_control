ROOT := $(abspath ../..)
VERILOG_SRCS := \
 $(ROOT)/src/top/top_led_spi.sv \
 $(ROOT)/src/drivers/spi_slave_8.sv \
 $(ROOT)/src/drivers/spi_stream_bridge.sv \
 $(ROOT)/src/services/led_service.sv \
 $(ROOT)/src/services/main_service.sv \
 $(ROOT)/src/protocol/protocol_rx.sv \
 $(ROOT)/src/protocol/protocol_tx.sv \
 $(ROOT)/src/protocol/formatters/tx_formatter_led.sv \
 $(ROOT)/src/protocol/formatters/tx_arbiter.sv \
 $(ROOT)/src/protocol/parsers/rx_router.sv \
 $(ROOT)/src/protocol/parsers/rx_parser_led.sv \
 $(ROOT)/src/protocol/codecs/codec_led.sv \
 $(ROOT)/src/protocol/interfaces/cmd_if_led.sv \
 $(ROOT)/src/protocol/interfaces/stream_if.sv \
 $(ROOT)/src/protocol/messages/msg_led.sv \
 $(ROOT)/src/protocol/framings/framing_pkg.sv \
 $(ROOT)/src/protocol/cmd/led_cmd_pkg.sv

.PHONY: lint format test wave

lint:
	verilator --lint-only -Wall -Wno-fatal -I$(ROOT) $(VERILOG_SRCS)

format:
	uncrustify -c $(ROOT)/uncrustify.cfg --no-backup $(VERILOG_SRCS)

test:
	pytest -q

wave:
	gtkwave sim_build/*/dump.vcd
