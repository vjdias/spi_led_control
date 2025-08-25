`include "src/protocol/interfaces/stream_if.sv"
module spi_stream_bridge_tb(
  input logic clk,
  input logic rst_n
);
  logic        rx_byte_valid;
  logic [7:0]  rx_byte;
  logic        rx_byte_ready;
  logic        tx_byte_valid;
  logic [7:0]  tx_byte;
  logic        tx_byte_ready;
  stream_if rx_stream(clk, rst_n);
  stream_if tx_stream(clk, rst_n);

  spi_stream_bridge dut(
    .clk(clk), .rst_n(rst_n),
    .rx_byte_valid(rx_byte_valid), .rx_byte(rx_byte), .rx_byte_ready(rx_byte_ready),
    .tx_byte_valid(tx_byte_valid), .tx_byte(tx_byte), .tx_byte_ready(tx_byte_ready),
    .rx_stream(rx_stream.producer), .tx_stream(tx_stream.consumer)
  );
endmodule
