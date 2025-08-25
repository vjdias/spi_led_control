# Waveform setup for tb_spi_stream_bridge

# Testbench clock
add wave -divider "TB"
add wave -radix binary sim:/tb_spi_stream_bridge/clk
add wave -radix binary sim:/tb_spi_stream_bridge/rst_n

# RX byte side
add wave -divider "RX byte"
add wave -radix hex sim:/tb_spi_stream_bridge/rx_byte
add wave -radix binary sim:/tb_spi_stream_bridge/rx_byte_valid
add wave -radix binary sim:/tb_spi_stream_bridge/rx_byte_ready

# RX stream interface
add wave -divider "RX stream"
add wave -radix hex sim:/tb_spi_stream_bridge/rx_stream_if/data
add wave -radix binary sim:/tb_spi_stream_bridge/rx_stream_if/valid
add wave -radix binary sim:/tb_spi_stream_bridge/rx_stream_if/ready

# TX stream interface
add wave -divider "TX stream"
add wave -radix hex sim:/tb_spi_stream_bridge/tx_stream_if/data
add wave -radix binary sim:/tb_spi_stream_bridge/tx_stream_if/valid
add wave -radix binary sim:/tb_spi_stream_bridge/tx_stream_if/ready

# TX byte side
add wave -divider "TX byte"
add wave -radix hex sim:/tb_spi_stream_bridge/tx_byte
add wave -radix binary sim:/tb_spi_stream_bridge/tx_byte_valid
add wave -radix binary sim:/tb_spi_stream_bridge/tx_byte_ready

# Internal signals
add wave -divider "DUT"
add wave -radix binary sim:/tb_spi_stream_bridge/dut/*
