`include "src/protocol/interfaces/stream_if.sv"
module spi_stream_bridge_tb(
  input  logic clk,
  input  logic rst_n,
  input  logic        rx_byte_valid,
  input  logic [7:0]  rx_byte,
  output logic        rx_byte_ready,
  output logic        tx_byte_valid,
  output logic [7:0]  tx_byte,
  input  logic        tx_byte_ready
);
  stream_if #(8) rx_stream_if(clk, rst_n);
  stream_if #(8) tx_stream_if(clk, rst_n);
  spi_stream_bridge dut(
    .clk(clk),
    .rst_n(rst_n),
    .rx_byte_valid(rx_byte_valid),
    .rx_byte(rx_byte),
    .rx_byte_ready(rx_byte_ready),
    .tx_byte_valid(tx_byte_valid),
    .tx_byte(tx_byte),
    .tx_byte_ready(tx_byte_ready),
    .rx_stream(rx_stream_if.producer),
    .tx_stream(tx_stream_if.consumer)
  );
endmodule
