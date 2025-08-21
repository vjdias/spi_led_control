vlib work
vlog ../../src/drivers/spi_slave_8.sv
vlog ../tb_spi_slave.sv
vsim -c tb_spi_slave -do "run -all; quit"
