interface leds_if #(parameter int N = 5) ();
  logic [N-1:0] leds;
  // Monitor (somente leitura do TB)
  modport mon (input leds);
endinterface
