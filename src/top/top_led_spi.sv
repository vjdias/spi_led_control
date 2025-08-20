`ifndef TOP_LED_SPI_SV
`define TOP_LED_SPI_SV
`include "src/protocol/interfaces/stream_if.sv"
`include "src/protocol/interfaces/cmd_if_led.sv"
`include "src/protocol/framings/framing_pkg.sv"
`include "src/protocol/cmd/led_cmd_pkg.sv"

module top_led_spi #(parameter bit CPOL = 1'b1, parameter bit CPHA = 1'b1, parameter int NUM_LEDS = 5)(
  input  logic clk, rst_n,
  input  logic spi_sclk, input  logic spi_csn, input  logic spi_mosi, output logic spi_miso,
  output logic [NUM_LEDS-1:0] leds
);
  import led_cmd_pkg::*;
  logic        rx_byte_valid; logic [7:0]  rx_byte; logic rx_byte_ready;
  logic        tx_byte_valid; logic [7:0]  tx_byte; logic tx_byte_ready;

// === SPI slave 100% RTL (sem IP Gowin) ===
spi_slave_8 #(
  .CPOL(CPOL),   // ou 1'b0
  .CPHA(CPHA)    // ou 1'b0
) u_spi (
  .clk           (clk),
  .rst_n         (rst_n),
  .spi_sclk      (spi_sclk),
  .spi_csn       (spi_csn),
  .spi_mosi      (spi_mosi),
  .spi_miso      (spi_miso),

  // RX (host -> FPGA)
  .rx_byte_valid (rx_byte_valid),
  .rx_byte       (rx_byte),
  .rx_byte_ready (rx_byte_ready),

  // TX (FPGA -> host)
  .tx_byte_valid (tx_byte_valid),
  .tx_byte       (tx_byte),
  .tx_byte_ready (tx_byte_ready)
);

  stream_if rx_s(clk, rst_n); stream_if tx_s(clk, rst_n);
  spi_stream_bridge u_bridge (.clk(clk), .rst_n(rst_n),
    .rx_byte_valid(rx_byte_valid), .rx_byte(rx_byte), .rx_byte_ready(rx_byte_ready),
    .tx_byte_valid(tx_byte_valid), .tx_byte(tx_byte), .tx_byte_ready(tx_byte_ready),
    .rx_stream(rx_s.producer), .tx_stream(tx_s.consumer)
  );

  cmd_if_led led_if(clk, rst_n);

  logic       req_cmd_valid; logic [7:0] req_cmd_code; logic allow_grant; logic frame_done;
  protocol_rx u_proto_rx (.clk(clk), .rst_n(rst_n), .rx_stream(rx_s.consumer),
    .req_cmd_valid(req_cmd_valid), .req_cmd_code(req_cmd_code),
    .allow_grant(allow_grant), .frame_done(frame_done), .led_if(led_if.protocol_rx)
  );

  logic led_fmt_done;
  protocol_tx u_proto_tx (.clk(clk), .rst_n(rst_n), .led_if(led_if.protocol_tx), .tx_stream(tx_s.producer), .led_fmt_done(led_fmt_done));

  main_service #(.CMD_LED_P(CMD_LED)) u_main (.clk(clk), .rst_n(rst_n),
    .req_cmd_valid(req_cmd_valid), .req_cmd_code(req_cmd_code), .allow_grant(allow_grant),
    .frame_done(frame_done), .led_rsp_done(led_fmt_done), .active_cmd()
  );

  led_service #(.NUM_LEDS(NUM_LEDS)) u_led (.clk(clk), .rst_n(rst_n), .led_if(led_if.service), .leds(leds), .service_done());

endmodule
`endif
