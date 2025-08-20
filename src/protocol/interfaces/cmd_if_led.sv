`ifndef CMD_IF_LED_SV
`define CMD_IF_LED_SV
/* =============================================================================
 * cmd_if_led.sv — Contrato semântico (Req/Rsp) do serviço LED
 *  - Três modports para eliminar drivers múltiplos e direção incorreta:
 *      * service     : lado do serviço (consome req_*, produz rsp_*)
 *      * protocol_rx : lado do parser (produz req_*, NÃO dirige rsp_*)
 *      * protocol_tx : lado do formatter (consome rsp_*, dirige rsp_ready)
 * ============================================================================= */
`include "src/protocol/messages/msg_led.sv"

interface cmd_if_led (input logic clk, input logic rst_n);
  import msg_led::*;

  // Requisição (parser -> serviço)
  logic           req_valid;
  logic           req_ready;
  set_led_req_t   req;

  // Resposta (serviço -> formatter)
  logic           rsp_valid;
  logic           rsp_ready;
  set_led_rsp_t   rsp;

  // Serviço (lógica de negócio)
  modport service (
    input  clk, rst_n,
    input  req_valid, req,
    output req_ready,
    output rsp_valid, rsp,
    input  rsp_ready
  );

  // Protocolo (lado RX / parser): produz req_*, NÃO dirige rsp_*
  modport protocol_rx (
    input  clk, rst_n,
    output req_valid, req,
    input  req_ready,
    input  rsp_valid, rsp,
    input  rsp_ready
  );

  // Protocolo (lado TX / formatter): consome rsp_*, dirige rsp_ready
  modport protocol_tx (
    input  clk, rst_n,
    input  req_valid, req,
    input  req_ready,
    input  rsp_valid, rsp,
    output rsp_ready
  );
endinterface
`endif // CMD_IF_LED_SV
