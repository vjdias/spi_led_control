// tb/spi_if.sv
interface spi_if #(
  parameter bit  CPOL    = 1'b1,
  parameter bit  CPHA    = 1'b1,
  parameter time T_HALF  = 50ns,
  parameter time T_CSS   = 200ns,
  parameter time T_SETUP = 10ns
);
  timeunit 1ns; timeprecision 1ps;

  // Sinais físicos
  logic sclk;
  logic csn;    // ativo em 0
  logic mosi;
  wire  miso;

  // --------- Tarefas do BFM (master) ----------
  task automatic init_bus();
    sclk = CPOL;
    csn  = 1'b1;
    mosi = 1'b0;
    #1ns;
  endtask

  task automatic cs_low();  csn = 1'b0; #(T_CSS); endtask
  task automatic cs_high(); csn = 1'b1; #(T_CSS); endtask

  task automatic xfer_bit(input  bit mosi_bit, output bit miso_bit);
    if (CPHA == 1'b0) begin
      mosi = mosi_bit;      #(T_SETUP);
      sclk = ~CPOL;         #(T_HALF);  miso_bit = miso;
      sclk = CPOL;          #(T_HALF);
    end else begin
      sclk = ~CPOL;         #(T_HALF);  mosi = mosi_bit;
      sclk = CPOL;          #(T_HALF);  miso_bit = miso;
    end
  endtask

  task automatic xfer_byte(input byte tx, output byte rx);
    for (int i = 7; i >= 0; i--) begin
      bit m;
      xfer_bit(tx[i], m);
      rx[i] = m;
    end
  endtask

  task automatic write_bytes(input byte tx_q[$]);
    byte dummy;
    foreach (tx_q[i]) xfer_byte(tx_q[i], dummy);
  endtask

  task automatic read_n_bytes(input int n, output byte rx_q[$]);
    byte rxb; rx_q.delete();
    for (int k = 0; k < n; k++) begin
      xfer_byte(8'h00, rxb);
      rx_q.push_back(rxb);
    end
  endtask

  task automatic poll_for_header(input byte hdr, input int max_try,
                                 output bit found, output byte rx_first);
    byte rxb; found = 0; rx_first = 8'h00;
    for (int t = 0; t < max_try; t++) begin
      xfer_byte(8'h00, rxb);
      if (rxb == hdr) begin
        found    = 1;
        rx_first = rxb;
        break;
      end
    end
  endtask
endinterface
