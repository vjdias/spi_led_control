`ifndef RX_PARSER_LED_SV
`define RX_PARSER_LED_SV
/* =============================================================================
 * rx_parser_led.sv — Parser do comando LED (gera req_* e nunca dirige rsp_*)
 * ============================================================================= */
`include "src/protocol/interfaces/stream_if.sv"
`include "src/protocol/framings/framing_pkg.sv"
`include "src/protocol/interfaces/cmd_if_led.sv"
`include "src/protocol/codecs/codec_led.sv"

module rx_parser_led (
  input  logic       clk,
  input  logic       rst_n,
  input  logic [7:0] cmd_code,
  input  logic       grant,
  stream_if.consumer in_stream,
  cmd_if_led.protocol_rx led_if,   // <- usa o modport RX
  output logic       parser_done
);
  import framing_pkg::*;
  import msg_led::*;
  import codec_led_pkg::*;

  typedef enum logic [2:0] {
    S_WAIT_ID, S_WAIT_IDX, S_WAIT_VAL, S_WAIT_TAIL, S_EMIT_REQ, S_DONE
  } state_t;

  state_t   st, nx;
  logic [7:0] id_b, idx_b, val_b;

  always_comb begin
    // defaults
    in_stream.ready  = 1'b0;
    led_if.req_valid = 1'b0;
    led_if.req       = '0;
    // NUNCA dirigir led_if.rsp_ready aqui
    parser_done      = 1'b0;
    nx               = st;

    unique case (st)
      S_WAIT_ID:   if (grant && in_stream.valid) begin in_stream.ready = 1'b1; nx = S_WAIT_IDX; end
      S_WAIT_IDX:  if (in_stream.valid)          begin in_stream.ready = 1'b1; nx = S_WAIT_VAL; end
      S_WAIT_VAL:  if (in_stream.valid)          begin in_stream.ready = 1'b1; nx = S_WAIT_TAIL; end
      S_WAIT_TAIL: if (in_stream.valid)          begin in_stream.ready = 1'b1; nx = S_EMIT_REQ; end

      S_EMIT_REQ: begin
        led_if.req       = codec_led_pkg::unpack_req(id_b, idx_b, val_b);
        led_if.req_valid = 1'b1;
        if (led_if.req_ready) nx = S_DONE;
      end

      S_DONE:    begin parser_done = 1'b1; nx = S_WAIT_ID; end
      default:   nx = S_WAIT_ID;
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st    <= S_WAIT_ID;
      id_b  <= '0;
      idx_b <= '0;
      val_b <= '0;
    end else begin
      st <= nx;
      if (st == S_WAIT_ID  && grant && in_stream.valid) id_b  <= in_stream.data;
      if (st == S_WAIT_IDX && in_stream.valid)          idx_b <= in_stream.data;
      if (st == S_WAIT_VAL && in_stream.valid)          val_b <= in_stream.data;
    end
  end
endmodule
`endif // RX_PARSER_LED_SV
