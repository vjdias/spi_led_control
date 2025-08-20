`ifndef TX_FORMATTER_LED_SV
`define TX_FORMATTER_LED_SV
/* =============================================================================
 * tx_formatter_led.sv — Formatter da resposta LED (dirige apenas rsp_ready)
 * ============================================================================= */
`include "src/protocol/interfaces/stream_if.sv"
`include "src/protocol/framings/framing_pkg.sv"
`include "src/protocol/interfaces/cmd_if_led.sv"
`include "src/protocol/codecs/codec_led.sv"

module tx_formatter_led #(
  parameter logic [7:0] CMD_P = 8'h30
)(
  input  logic        clk,
  input  logic        rst_n,
  cmd_if_led.protocol_tx led_if,   // <- usa o modport TX
  stream_if.producer  out_stream,
  output logic        fmt_done
);
  import framing_pkg::*;
  import msg_led::*;
  import codec_led_pkg::*;

  typedef enum logic [3:0] {
    S_IDLE, S_HDR, S_CMD, S_ID, S_IDX, S_VAL, S_OK, S_TAIL, S_DONE
  } state_t;

  state_t    st, nx;
  logic [7:0] b_id, b_idx, b_val, b_ok;

  always_comb begin
    // defaults
    out_stream.valid = 1'b0;
    out_stream.data  = 8'h00;
    // Pulso de aceite da resposta em S_IDLE
    led_if.rsp_ready = (st == S_IDLE) && led_if.rsp_valid;
    fmt_done         = 1'b0;
    nx               = st;

    unique case (st)
      S_IDLE: if (led_if.rsp_valid) nx = S_HDR;

      S_HDR:  begin out_stream.valid = 1'b1; out_stream.data = HDR_RSP; if (out_stream.ready) nx = S_CMD; end
      S_CMD:  begin out_stream.valid = 1'b1; out_stream.data = CMD_P;   if (out_stream.ready) nx = S_ID;  end
      S_ID:   begin out_stream.valid = 1'b1; out_stream.data = b_id;    if (out_stream.ready) nx = S_IDX; end
      S_IDX:  begin out_stream.valid = 1'b1; out_stream.data = b_idx;   if (out_stream.ready) nx = S_VAL; end
      S_VAL:  begin out_stream.valid = 1'b1; out_stream.data = b_val;   if (out_stream.ready) nx = S_OK;  end
      S_OK:   begin out_stream.valid = 1'b1; out_stream.data = b_ok;    if (out_stream.ready) nx = S_TAIL;end
      S_TAIL: begin out_stream.valid = 1'b1; out_stream.data = TAIL_RSP;if (out_stream.ready) nx = S_DONE;end
      S_DONE: begin fmt_done = 1'b1; nx = S_IDLE; end
      default: nx = S_IDLE;
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st    <= S_IDLE;
      b_id  <= '0;
      b_idx <= '0;
      b_val <= '0;
      b_ok  <= '0;
    end else begin
      st <= nx;
      if (st == S_IDLE && led_if.rsp_valid) begin
        codec_led_pkg::pack_rsp(led_if.rsp, b_id, b_idx, b_val, b_ok);
      end
    end
  end
endmodule
`endif // TX_FORMATTER_LED_SV
