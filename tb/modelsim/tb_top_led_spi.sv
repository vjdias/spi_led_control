`timescale 1ns/1ps
module tb_top_led_spi;
  localparam int NUM_LEDS = 5;
  localparam bit CPOL = 1'b1;
  localparam bit CPHA = 1'b1;

  logic clk = 0;
  always #5 clk = ~clk;
  logic rst_n = 0;
  logic spi_sclk = 1'b1;
  logic spi_csn = 1'b1;
  logic spi_mosi = 1'b0;
  wire  spi_miso;
  wire [NUM_LEDS-1:0] leds;

  top_led_spi #(.CPOL(CPOL), .CPHA(CPHA), .NUM_LEDS(NUM_LEDS)) dut (
    .clk(clk), .rst_n(rst_n),
    .spi_sclk(spi_sclk), .spi_csn(spi_csn), .spi_mosi(spi_mosi), .spi_miso(spi_miso),
    .leds(leds)
  );

  task automatic spi_send_byte(input [7:0] data, output [7:0] miso);
    for (int i=7; i>=0; i--) begin
      spi_mosi = data[i];
      #5 spi_sclk = 1'b0;
      #5 begin
        spi_sclk = 1'b1;
        miso[i] = spi_miso;
      end
    end
  endtask

  task automatic spi_xfer(input byte tx_arr[], output byte rx_arr[], input int n);
    spi_csn = 1'b0;
    for (int j=0; j<n; j++) begin
      spi_send_byte(tx_arr[j], rx_arr[j]);
    end
    spi_csn = 1'b1;
    #20;
  endtask

  initial begin
    spi_sclk = 1'b1;
    spi_csn = 1'b1;
    spi_mosi = 1'b0;
    #20 rst_n = 1;
    byte req[6] = '{8'hAA,8'h30,8'h11,8'h02,8'h01,8'h55};
    byte dummy[6];
    spi_xfer(req, dummy, 6);
    #100;
    byte zeros[7];
    byte rsp[7];
    foreach (zeros[i]) zeros[i] = 8'h00;
    spi_xfer(zeros, rsp, 7);
    if (leds[2] !== 1'b1) $fatal("LED2 was not set");
    $finish;
  end
endmodule
