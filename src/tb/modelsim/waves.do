# Abre/ativa a janela de ondas
view wave

# Config do painel de ondas
configure wave -signalnamewidth 1

# -------------------- CLK / RESET --------------------
add wave -divider {CLK/RESET}
add wave -radix binary sim:/tb_top/clk
add wave -radix binary sim:/tb_top/rst_n

# -------------------- SPI (TB) -----------------------
add wave -divider {SPI bus}
add wave -radix binary sim:/tb_top/spi_bus/csn
add wave -radix binary sim:/tb_top/spi_bus/sclk
add wave -radix hex    sim:/tb_top/spi_bus/mosi
add wave -radix hex    sim:/tb_top/spi_bus/miso

# -------------------- DUT ----------------------------
add wave -divider {DUT}
add wave -radix hex sim:/tb_top/dut/leds

# -------------------- Streams ------------------------
# (comente se não existir na sua hierarquia)
add wave -divider {Streams}
add wave -radix hex sim:/tb_top/dut/rx_s/valid
add wave -radix hex sim:/tb_top/dut/rx_s/ready
add wave -radix hex sim:/tb_top/dut/rx_s/data
add wave -radix hex sim:/tb_top/dut/tx_s/valid
add wave -radix hex sim:/tb_top/dut/tx_s/ready
add wave -radix hex sim:/tb_top/dut/tx_s/data

# -------------------- cmd_if_led ---------------------
add wave -divider {cmd_if_led}
add wave -radix hex sim:/tb_top/dut/led_if/req_valid
add wave -radix hex sim:/tb_top/dut/led_if/req_ready
add wave -radix hex sim:/tb_top/dut/led_if/req
add wave -radix hex sim:/tb_top/dut/led_if/rsp_valid
add wave -radix hex sim:/tb_top/dut/led_if/rsp_ready
add wave -radix hex sim:/tb_top/dut/led_if/rsp

# Radix default e zoom
radix -hexadecimal
wave zoomfull
