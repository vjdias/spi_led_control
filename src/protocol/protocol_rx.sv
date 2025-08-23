`ifndef PROTOCOL_RX_SV
`define PROTOCOL_RX_SV
/* =============================================================================
 * protocol_rx.sv — Subsystem de entrada (Router + Parsers)
 *   - Usa cmd_if_led.protocol_rx no porto para direção correta.
 * ============================================================================= */
`include "src/protocol/interfaces/stream_if.sv"
`include "src/protocol/interfaces/cmd_if_led.sv"
`include "src/protocol/cmd/led_cmd_pkg.sv"

module protocol_rx #(
  parameter bit ENABLE_LED = 1'b1
)(
  input  logic clk,
  input  logic rst_n,

  // Stream bruto vindo da ponte SPI
  stream_if.consumer rx_stream,

  // Coordenação com o serviço principal
  output logic       req_cmd_valid,
  output logic [7:0] req_cmd_code,
  input  logic       allow_grant,
  output logic       frame_done,

  // Interfaces semânticas para serviços
  cmd_if_led.protocol_rx led_if
);
  // Router ↔ Parser LED
  stream_if led_in(clk, rst_n);
  logic       grant_led;
  logic [7:0] led_cmd_code;
  logic       led_parser_done;
  logic       led_parser_done_q;

  // Registramos o sinal de conclusão do parser para
  // evitar laços combinacionais entre o roteador e o parser.
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      led_parser_done_q <= 1'b0;
    else
      led_parser_done_q <= led_parser_done;
  end

  rx_router #(
    .CMD_LED_P(led_cmd_pkg::CMD_LED)
  ) u_router (
    .clk(clk), .rst_n(rst_n),
    .in_stream(rx_stream),
    .req_cmd_valid(req_cmd_valid),
    .req_cmd_code(req_cmd_code),
    .allow_grant(allow_grant),
    .frame_done(frame_done),
    .grant_led(grant_led),
    .led_cmd_code(led_cmd_code),
    .led_stream(led_in.producer),
    .led_parser_done(led_parser_done_q)
  );

  generate
    if (ENABLE_LED) begin : G_LED_PARSER
      rx_parser_led u_p_led (
        .clk(clk), .rst_n(rst_n),
        .cmd_code(led_cmd_code),
        .grant(grant_led),
        .in_stream(led_in.consumer),
        .led_if(led_if),
        .parser_done(led_parser_done)
      );
    end else begin
      // Sem LED: não gera reqs e sinaliza done imediatamente
      assign led_if.req_valid = 1'b0;
      assign led_if.req       = '0;
      assign led_parser_done  = 1'b1;
    end
  endgenerate
endmodule
`endif // PROTOCOL_RX_SV
