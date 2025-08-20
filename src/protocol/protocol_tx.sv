`ifndef PROTOCOL_TX_SV
`define PROTOCOL_TX_SV
/* =============================================================================
 * protocol_tx.sv — Subsystem de saída (Formatters + Árbiter)
 *   - Usa cmd_if_led.protocol_tx no porto para direção correta.
 * ============================================================================= */
`include "src/protocol/interfaces/stream_if.sv"
`include "src/protocol/interfaces/cmd_if_led.sv"
`include "src/protocol/cmd/led_cmd_pkg.sv"

module protocol_tx #(
  parameter bit ENABLE_LED = 1'b1
)(
  input  logic clk,
  input  logic rst_n,

  // Interfaces semânticas vindas dos serviços
  cmd_if_led.protocol_tx led_if,

  // Stream único para o driver/ponte SPI
  stream_if.producer tx_stream,

  // Sinal de término (para main_service)
  output logic led_fmt_done
);
  // Saída do formatter LED
  stream_if led_out(clk, rst_n);

  generate
    if (ENABLE_LED) begin : G_LED_FMT
      tx_formatter_led #(
        .CMD_P(led_cmd_pkg::CMD_LED)
      ) u_fmt_led (
        .clk(clk), .rst_n(rst_n),
        .led_if(led_if),
        .out_stream(led_out.producer),
        .fmt_done(led_fmt_done)
      );
    end else begin
      assign led_out.valid = 1'b0;
      assign led_out.data  = '0;
      assign led_fmt_done  = 1'b1;
    end
  endgenerate

  // Arbiter (pronto para múltiplos formatters)
  tx_arbiter u_arb (
    .clk(clk), .rst_n(rst_n),
    .led_stream(led_out.consumer),
    .out_stream(tx_stream)
  );
endmodule
`endif // PROTOCOL_TX_SV
