`ifndef STREAM_IF_SV
`define STREAM_IF_SV
interface stream_if #(parameter int WIDTH = 8) (input logic clk, input logic rst_n);
  logic                valid;
  logic                ready;
  logic [WIDTH-1:0]    data;
  modport producer (input clk, rst_n, output valid, data, input  ready);
  modport consumer (input clk, rst_n, input  valid, data, output ready);
endinterface
`endif
