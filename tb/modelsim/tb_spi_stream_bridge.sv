`timescale 1ns/1ps
`include "src/protocol/interfaces/stream_if.sv"

module tb_spi_stream_bridge;
  // Clock and reset (though design is combinational, interfaces expect them)
  logic clk = 0;
  always #5 clk = ~clk;
  logic rst_n = 1;

  // Byte-side handshake
  logic        rx_byte_valid;
  logic [7:0]  rx_byte;
  logic        rx_byte_ready;
  logic        tx_byte_valid;
  logic [7:0]  tx_byte;
  logic        tx_byte_ready;

  // Stream interfaces
  stream_if #(8) rx_stream_if(clk, rst_n);
  stream_if #(8) tx_stream_if(clk, rst_n);

  // DUT
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

  // Test sequence
  initial begin
    // initialise
    rx_byte_valid = 0;
    rx_byte = '0;
    tx_stream_if.valid = 0;
    tx_stream_if.data = '0;
    tx_byte_ready = 0;
    rx_stream_if.ready = 0;

    // wait some cycles
    repeat (2) @(posedge clk);

    // RX path: byte -> stream
    rx_byte = 8'hA5;
    rx_byte_valid = 1;
    rx_stream_if.ready = 1;
    @(posedge clk);
    assert(rx_byte_ready) else $fatal("rx_byte_ready not asserted");
    assert(rx_stream_if.valid && rx_stream_if.data == 8'hA5)
      else $fatal("RX stream mismatch");
    rx_byte_valid = 0;
    rx_stream_if.ready = 0;

    // TX path: stream -> byte
    tx_stream_if.data = 8'h3C;
    tx_stream_if.valid = 1;
    tx_byte_ready = 1;
    @(posedge clk);
    assert(tx_byte_valid && tx_byte == 8'h3C)
      else $fatal("TX byte mismatch");
    tx_stream_if.valid = 0;
    tx_byte_ready = 0;

    $display("tb_spi_stream_bridge passed");
    $finish;
  end
endmodule
