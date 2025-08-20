`ifndef FRAMING_PKG_SV
`define FRAMING_PKG_SV
package framing_pkg;
  localparam logic [7:0] HDR_REQ  = 8'hAA;
  localparam logic [7:0] TAIL_REQ = 8'h55;
  localparam logic [7:0] HDR_RSP  = 8'hAB;
  localparam logic [7:0] TAIL_RSP = 8'h54;
endpackage
`endif
