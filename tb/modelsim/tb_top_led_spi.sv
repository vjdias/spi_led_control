`timescale 1ns/1ps
module tb_top_led_spi;
  localparam int NUM_LEDS = 5;
  localparam bit CPOL = 1'b1;
  localparam bit CPHA = 1'b1;

  logic clk = 0;
  always #5 clk = ~clk;

  logic rst_n = 0;
  logic spi_sclk = CPOL;   // idle = CPOL
  logic spi_csn  = 1'b1;
  logic spi_mosi = 1'b0;
  wire  spi_miso;
  wire [NUM_LEDS-1:0] leds;

  byte req[6];
  byte dummy[6];
  byte zeros[7];
  byte rsp[7];

  top_led_spi #(.CPOL(CPOL), .CPHA(CPHA), .NUM_LEDS(NUM_LEDS)) dut (
    .clk(clk), .rst_n(rst_n),
    .spi_sclk(spi_sclk), .spi_csn(spi_csn), .spi_mosi(spi_mosi), .spi_miso(spi_miso),
    .leds(leds)
  );

  // SPI transaction helper aligned with CPOL=1/CPHA=1 timing
  // Data is presented before the leading edge, then the clock toggles
  // low/high with two system-clock cycles between edges so the DUT's
  // synchronizers can capture each transition.
  task automatic spi_send_byte(input [7:0] data, output [7:0] miso);
    for (int i = 7; i >= 0; i--) begin
      spi_mosi = data[i];
      repeat (2) @(posedge clk);
      spi_sclk = ~spi_sclk;  // leading edge (shift)
      repeat (2) @(posedge clk);
      spi_sclk = ~spi_sclk;  // trailing edge (sample)
      repeat (2) @(posedge clk);
      miso[i] = spi_miso;
    end
  endtask

  initial begin
    rst_n = 0;
    repeat (5) @(posedge clk);
    rst_n = 1;

    // Envia comando para acender o LED de índice 2 (ID=0x02)
    req[0]=8'hAA; req[1]=8'h30; req[2]=8'h02; req[3]=8'h02; req[4]=8'h01; req[5]=8'h55;
    spi_csn = 0;
    for (int j=0; j<6; j++) spi_send_byte(req[j], dummy[j]);
    spi_csn = 1;

    repeat (20) @(posedge clk);

    for (int k=0; k<7; k++) zeros[k]=8'h00;
    spi_csn = 0;
    for (int j=0; j<7; j++) spi_send_byte(zeros[j], rsp[j]);
    spi_csn = 1;

    repeat (20) @(posedge clk);
    if (leds[2] !== 1'b1)
      $display("FAIL: LED2 not set - leds=%b", leds);
    else
      $display("PASS: LED2 set correctly");
    $finish;
  end
endmodule
