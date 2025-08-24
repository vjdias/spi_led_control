`include "src/protocol/interfaces/cmd_if_led.sv"
module led_service_tb #(parameter int NUM_LEDS = 5)(
  input  logic clk,
  input  logic rst_n,
  output logic [NUM_LEDS-1:0] leds
);
  cmd_if_led led_if(clk, rst_n);
  logic service_done;
  led_service #(.NUM_LEDS(NUM_LEDS)) dut(
    .clk(clk), .rst_n(rst_n),
    .led_if(led_if.service),
    .leds(leds),
    .service_done(service_done)
  );
endmodule
