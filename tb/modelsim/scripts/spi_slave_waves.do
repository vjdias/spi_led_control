# Waveform setup for tb_spi_slave
# Adiciona sinais de interesse

# Testbench clock/reset
add wave -divider "Testbench"
add wave -radix binary sim:/tb_spi_slave/clk
add wave -radix binary sim:/tb_spi_slave/rst_n

# SPI interface
add wave -divider "SPI"
add wave -radix binary sim:/tb_spi_slave/spi_sclk
add wave -radix binary sim:/tb_spi_slave/spi_csn
add wave -radix binary sim:/tb_spi_slave/spi_mosi
add wave -radix binary sim:/tb_spi_slave/spi_miso

# RX/TX handshake
add wave -divider "RX"
add wave -radix hex    sim:/tb_spi_slave/rx_byte
add wave -radix binary sim:/tb_spi_slave/rx_byte_valid
add wave -radix binary sim:/tb_spi_slave/rx_byte_ready

add wave -divider "TX"
add wave -radix hex    sim:/tb_spi_slave/tx_byte
add wave -radix binary sim:/tb_spi_slave/tx_byte_valid
add wave -radix binary sim:/tb_spi_slave/tx_byte_ready

# Internals do DUT
add wave -divider "DUT internals"
add wave -radix binary sim:/tb_spi_slave/dut/*
