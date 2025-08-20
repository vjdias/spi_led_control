`timescale 1ns/1ps

// Inclui tuas unidades de design necessárias (ajuste caminhos ao teu projeto)
`include "protocol/interfaces/stream_if.sv"
`include "protocol/interfaces/cmd_if_led.sv"
`include "protocol/framings/framing_pkg.sv"
`include "protocol/cmd/led_cmd_pkg.sv"
`include "protocol/codecs/codec_led.sv"
`include "protocol/parsers/rx_parser_led.sv"
`include "protocol/parsers/rx_router.sv"
`include "protocol/formatters/tx_formatter_led.sv"
`include "protocol/formatters/tx_arbiter.sv"
`include "protocol/protocol_rx.sv"
`include "protocol/protocol_tx.sv"
`include "services/main_service.sv"
`include "services/led_service.sv"
`include "drivers/spi_slave_8.sv"
`include "drivers/spi_stream_bridge.sv"
`include "top/top_led_spi.sv"

// Interfaces de TB
`include "tb/spi_if.sv"
`include "tb/leds_if.sv"
// Pacote de classes
`include "tb/tb_pkg.sv"

module tb_top;
  // ---------------- Clocks & Reset ----------------
  logic clk;
  logic rst_n;

  localparam time T_CLK = 10ns; // 100 MHz

  initial begin
    clk = 0;
    forever #(T_CLK/2) clk = ~clk;
  end

  initial begin
    rst_n = 0;
    #200ns;
    rst_n = 1;
  end

  // ---------------- Barramento SPI (modo 3) ----------------
  spi_if #(
    .CPOL(1'b1), .CPHA(1'b1),
    .T_HALF(50ns), .T_CSS(200ns), .T_SETUP(10ns)
  ) spi_bus();

  // LEDs monitor
  localparam int NUM_LEDS = 5;
  leds_if #(NUM_LEDS) leds_mon();

  // ---------------- DUT ----------------
  wire spi_miso;
  wire [NUM_LEDS-1:0] leds;

  top_led_spi #(
    .CPOL(1'b1),
    .CPHA(1'b1),
    .NUM_LEDS(NUM_LEDS)
  ) dut (
    .clk      (clk),
    .rst_n    (rst_n),
    .spi_sclk (spi_bus.sclk),
    .spi_csn  (spi_bus.csn),
    .spi_mosi (spi_bus.mosi),
    .spi_miso (spi_miso),
    .leds     (leds)
  );

  // Conectar MISO ao interface SPI e LEDs ao monitor
  assign spi_bus.miso = spi_miso;
  assign leds_mon.leds = leds;

  // ---------------- Rodar teste ----------------
  tb_pkg::led_env  env;
  tb_pkg::led_test test;

  initial begin
    env  = new(spi_bus, leds_mon);
    test = new(env);

    // Espera reset
    @(posedge rst_n);
    repeat (5) @(posedge clk);

    test.run();
  end


endmodule
