`ifndef MAIN_SERVICE_SV
`define MAIN_SERVICE_SV
/* =============================================================================
 * main_service.sv — FSM principal (agora com default no case)
 * ============================================================================= */
`include "src/protocol/framings/framing_pkg.sv"

module main_service #(
  parameter logic [7:0] CMD_LED_P = 8'h30
)(
  input  logic clk,
  input  logic rst_n,

  // Sinais do RX subsystem
  input  logic       req_cmd_valid,
  input  logic [7:0] req_cmd_code,
  output logic       allow_grant,
  input  logic       frame_done,

  // Término de formatters
  input  logic       led_rsp_done,

  // Diagnóstico
  output logic [7:0] active_cmd
);
  typedef enum logic [2:0] { S_IDLE, S_START, S_EXEC, S_RESP, S_DONE } state_t;
  state_t st, nx;

  logic [7:0] cmd_q;

  always_comb begin
    allow_grant = 1'b0;
    active_cmd  = cmd_q;
    nx          = st;

    unique case (st)
      S_IDLE:  if (req_cmd_valid) nx = S_START;
      S_START: begin allow_grant = 1'b1; nx = S_EXEC; end
      S_EXEC:  if (frame_done) nx = S_RESP;
      S_RESP:  begin
        if (cmd_q == CMD_LED_P) begin
          if (led_rsp_done) nx = S_DONE;
        end else nx = S_DONE;
      end
      S_DONE:  nx = S_IDLE;
      default: nx = S_IDLE;
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st    <= S_IDLE;
      cmd_q <= 8'h00;
    end else begin
      st <= nx;
      if (st == S_IDLE && req_cmd_valid) cmd_q <= req_cmd_code;
    end
  end
endmodule
`endif // MAIN_SERVICE_SV
