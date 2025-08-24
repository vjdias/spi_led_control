`timescale 1ns/1ps
module tb_spi_slave;
  localparam bit CPOL = 1'b1;
  localparam bit CPHA = 1'b1;

  logic clk = 0;
  always #5 clk = ~clk;

  logic rst_n = 0;
  logic spi_sclk = CPOL;   // idle conforme CPOL
  logic spi_csn  = 1'b1;
  logic spi_mosi = 1'b0;
  wire  spi_miso;

  logic        rx_byte_ready = 1'b0;
  wire         rx_byte_valid;
  wire [7:0]   rx_byte;
  logic        tx_byte_valid = 1'b0;
  logic [7:0]  tx_byte = '0;
  wire         tx_byte_ready;
  logic [7:0]  miso;

  spi_slave_8 #(.CPOL(CPOL), .CPHA(CPHA)) dut (
    .clk(clk), .rst_n(rst_n),
    .spi_sclk(spi_sclk), .spi_csn(spi_csn), .spi_mosi(spi_mosi), .spi_miso(spi_miso),
    .rx_byte_valid(rx_byte_valid), .rx_byte(rx_byte), .rx_byte_ready(rx_byte_ready),
    .tx_byte_valid(tx_byte_valid), .tx_byte(tx_byte), .tx_byte_ready(tx_byte_ready)
  );

  // SPI byte transfer helper following CPOL=1/CPHA=1 timing
  task automatic spi_send_byte(input [7:0] data, output [7:0] miso);
    for (int i = 7; i >= 0; i--) begin
      spi_mosi = data[i];
      repeat (2) @(posedge clk);
      spi_sclk = ~spi_sclk;  // leading edge
      repeat (2) @(posedge clk);
      spi_sclk = ~spi_sclk;  // trailing edge
      repeat (2) @(posedge clk);
      miso[i] = spi_miso;
    end
  endtask

  initial begin
    #20 rst_n = 1;

    // preload TX FIFO
    tx_byte = 8'hA5;
    tx_byte_valid = 1;
    @(posedge clk);
    wait (tx_byte_ready);
    tx_byte_valid = 0;

    // envia um byte
    spi_csn = 0;
    spi_send_byte(8'h3C, miso);
    spi_csn = 1;

    repeat (10) @(posedge clk);

    if (!rx_byte_valid) $fatal(1, "RX byte not captured");
    else $display("RX=%h MISO=%h", rx_byte, miso);

    $finish;
  end
endmodule
