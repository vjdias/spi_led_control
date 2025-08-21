`ifndef LED_SERVICE_SV
`define LED_SERVICE_SV
`include "src/protocol/interfaces/cmd_if_led.sv"
module led_service #(parameter int NUM_LEDS = 5, parameter bit LED_ACTIVE_HIGH = 1'b1)(
  input  logic clk, rst_n,
  cmd_if_led.service led_if,
  output logic [NUM_LEDS-1:0] leds,
  output logic                service_done
);
  import msg_led::*;
  typedef enum logic [1:0] {S_IDLE, S_APPLY, S_EMIT, S_WAIT_ACK} state_t; state_t st, nx;
  set_led_req_t req_q; set_led_rsp_t rsp_q;
  always_comb begin
    led_if.req_ready = 1'b0; led_if.rsp_valid = 1'b0; led_if.rsp = rsp_q; service_done = 1'b0; nx = st;
    unique case (st)
      S_IDLE:     if (led_if.req_valid) begin led_if.req_ready = 1'b1; nx = S_APPLY; end
      S_APPLY:    nx = S_EMIT;
      S_EMIT:     begin led_if.rsp_valid = 1'b1; if (led_if.rsp_ready) nx = S_WAIT_ACK; end
      S_WAIT_ACK: begin service_done = 1'b1; nx = S_IDLE; end
    endcase
  end
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin st <= S_IDLE; leds <= '0; req_q <= '0; rsp_q <= '0; end
    else begin
      st <= nx;
      if (st == S_IDLE && led_if.req_valid) req_q <= led_if.req;
      if (st == S_APPLY) begin
        rsp_q.id <= req_q.id; rsp_q.led_idx <= req_q.led_idx; rsp_q.led_val <= req_q.led_val;
        if (int'(req_q.led_idx) < NUM_LEDS) begin
          leds[req_q.led_idx] <= (LED_ACTIVE_HIGH) ? req_q.led_val : ~req_q.led_val; rsp_q.ok <= 1'b1;
        end else rsp_q.ok <= 1'b0;
      end
    end
  end
endmodule
`endif // LED_SERVICE_SV
