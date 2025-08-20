`ifndef SPI_STREAM_BRIDGE_SV
`define SPI_STREAM_BRIDGE_SV
`include "src/protocol/interfaces/stream_if.sv"
module spi_stream_bridge (
  input  logic clk, rst_n,
  input  logic        rx_byte_valid, input  logic [7:0]  rx_byte, output logic rx_byte_ready,
  output logic        tx_byte_valid, output logic [7:0]  tx_byte, input  logic tx_byte_ready,
  stream_if.producer  rx_stream, stream_if.consumer  tx_stream
);
  always_comb begin rx_stream.valid = rx_byte_valid; rx_stream.data  = rx_byte; rx_byte_ready   = rx_stream.ready; end
  always_comb begin tx_byte_valid   = tx_stream.valid; tx_byte         = tx_stream.data; tx_stream.ready = tx_byte_ready; end
endmodule
`endif
