`ifndef TX_ARBITER_SV
`define TX_ARBITER_SV
`include "src/protocol/interfaces/stream_if.sv"
module tx_arbiter (
  input  logic clk, rst_n,
  stream_if.consumer led_stream,
  stream_if.producer out_stream
);
  always_comb begin
    out_stream.valid = led_stream.valid;
    out_stream.data  = led_stream.data;
    led_stream.ready = out_stream.ready;
  end
endmodule
`endif
