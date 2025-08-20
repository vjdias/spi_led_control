`ifndef CODEC_LED_PKG_SV
`define CODEC_LED_PKG_SV
`include "src/protocol/messages/msg_led.sv"

package codec_led_pkg;
  import msg_led::*;

  function automatic set_led_req_t unpack_req(
    input  logic [7:0] id_b,
    input  logic [7:0] idx_b,
    input  logic [7:0] val_b
  );
    set_led_req_t r;
    r.id      = id_b;
    r.led_idx = idx_b[2:0];
    r.led_val = val_b[0];
    return r;
  endfunction

  function automatic void pack_rsp(
    input  set_led_rsp_t rsp,
    output logic [7:0]   id_b,
    output logic [7:0]   idx_b,
    output logic [7:0]   val_b,
    output logic [7:0]   ok_b
  );
    id_b  = rsp.id;
    idx_b = {5'b0, rsp.led_idx};
    val_b = {7'b0, rsp.led_val};
    ok_b  = {7'b0, rsp.ok};
  endfunction
endpackage
`endif // CODEC_LED_PKG_SV
