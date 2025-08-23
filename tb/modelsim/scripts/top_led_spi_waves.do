# Waveform setup for tb_top_led_spi
# Adiciona sinais de interesse

# Testbench clock/reset
add wave -divider "Testbench"
add wave -radix binary sim:/tb_top_led_spi/clk
add wave -radix binary sim:/tb_top_led_spi/rst_n

# SPI signals
add wave -divider "SPI"
add wave -radix binary sim:/tb_top_led_spi/spi_sclk
add wave -radix binary sim:/tb_top_led_spi/spi_csn
add wave -radix binary sim:/tb_top_led_spi/spi_mosi
add wave -radix binary sim:/tb_top_led_spi/spi_miso

# LEDs
add wave -divider "LEDs"
add wave -radix binary sim:/tb_top_led_spi/leds

# Internal DUT (se quiser explorar dentro do top_led_spi)
add wave -divider "DUT internals"
add wave -radix binary sim:/tb_top_led_spi/dut/*
