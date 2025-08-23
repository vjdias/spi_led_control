`ifndef RX_ROUTER_SV
`define RX_ROUTER_SV
/* =============================================================================
 * rx_router.sv — Roteador de entrada (nunca escreve .ready de producer)
 * ============================================================================= */
`include "src/protocol/interfaces/stream_if.sv"
`include "src/protocol/framings/framing_pkg.sv"

module rx_router #(
  parameter logic [7:0] CMD_LED_P = 8'h30
)(
  input  logic       clk,
  input  logic       rst_n,

  // Stream bruto vindo do driver SPI
  stream_if.consumer in_stream,

  // Coordenação com main_service
  output logic       req_cmd_valid,
  output logic [7:0] req_cmd_code,
  input  logic       allow_grant,
  output logic       frame_done,

  // Porta roteada para o parser LED
  output logic       grant_led,
  output logic [7:0] led_cmd_code,
  stream_if.producer led_stream,
  input  logic       led_parser_done
);
  import framing_pkg::*;

  typedef enum logic [2:0] { S_IDLE, S_CMD, S_ROUTE, S_STREAM, S_WAIT_DONE } state_t;
  state_t st, nx;

  logic [7:0] cmd_latched;

  always_comb begin
    // defaults
    req_cmd_valid   = 1'b0;
    req_cmd_code    = 8'h00;
    grant_led       = 1'b0;
    led_cmd_code    = cmd_latched;
    frame_done      = 1'b0;

    led_stream.valid = 1'b0;
    led_stream.data  = in_stream.data;
    // NÃO escrever led_stream.ready (é input do producer)
    in_stream.ready  = 1'b0;

    nx = st;

    unique case (st)
      S_IDLE: if (in_stream.valid && in_stream.data == HDR_REQ) begin in_stream.ready = 1'b1; nx = S_CMD; end
      S_CMD:  if (in_stream.valid) begin in_stream.ready = 1'b1; req_cmd_valid = 1'b1; req_cmd_code = in_stream.data; nx = S_ROUTE; end
      S_ROUTE: if (allow_grant) begin
        if (cmd_latched == CMD_LED_P) begin
          grant_led = 1'b1;
          nx        = S_STREAM;
        end else begin
          // Comando desconhecido: não concede grant e encerra frame
          frame_done = 1'b1;
          nx         = S_IDLE;
        end
      end
      S_STREAM: begin
        grant_led        = 1'b1;
        led_stream.valid = in_stream.valid;
        led_stream.data  = in_stream.data;
        in_stream.ready  = led_stream.ready;  // lê o ready do consumidor
        if (led_parser_done) nx = S_WAIT_DONE;
      end
      S_WAIT_DONE: begin frame_done = 1'b1; nx = S_IDLE; end
      default: nx = S_IDLE;
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st <= S_IDLE;
      cmd_latched <= 8'h00;
    end else begin
      st <= nx;
      if (st == S_CMD && in_stream.valid) cmd_latched <= in_stream.data;
    end
  end

endmodule
`endif // RX_ROUTER_SV
