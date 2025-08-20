`ifndef SPI_SLAVE_8_SV
`define SPI_SLAVE_8_SV
// ============================================================================
// spi_slave_8.sv
// SPI Slave 8-bit, MSB-first, com recarga de MISO a cada byte (mesmo com CSN=0),
// suporte a CPOL/CPHA genérico e FIFOs internos simples de RX/TX.
// ============================================================================

module spi_slave_8 #(
  parameter bit         CPOL               = 1'b1,
  parameter bit         CPHA               = 1'b1,
  parameter int         RX_DEPTH           = 8,
  parameter int         TX_DEPTH           = 8,
  parameter logic [7:0] TX_UNDERFLOW_BYTE  = 8'h00
)(
  input  logic clk,
  input  logic rst_n,

  // Físico SPI
  input  logic spi_sclk,
  input  logic spi_csn,   // ativo baixo
  input  logic spi_mosi,
  output tri   spi_miso,  // tri-state quando CSN=1

  // RX (host -> FPGA)
  output logic        rx_byte_valid,
  output logic [7:0]  rx_byte,
  input  logic        rx_byte_ready,

  // TX (FPGA -> host)
  input  logic        tx_byte_valid,
  input  logic [7:0]  tx_byte,
  output logic        tx_byte_ready
);

  // -------------------- Sincronização p/ 'clk' --------------------
  logic sclk_meta,  sclk_sync,  sclk_prev;
  logic csn_meta,   csn_sync,   csn_prev;
  logic mosi_meta,  mosi_sync;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sclk_meta <= CPOL; sclk_sync <= CPOL; sclk_prev <= CPOL;
      csn_meta  <= 1'b1; csn_sync  <= 1'b1; csn_prev  <= 1'b1;
      mosi_meta <= 1'b0; mosi_sync <= 1'b0;
    end else begin
      sclk_meta <= spi_sclk; sclk_sync <= sclk_meta; sclk_prev <= sclk_sync;
      csn_meta  <= spi_csn;  csn_sync  <= csn_meta;  csn_prev  <= csn_sync;
      mosi_meta <= spi_mosi; mosi_sync <= mosi_meta;
    end
  end

  wire sclk_rise = (sclk_prev==1'b0) && (sclk_sync==1'b1);
  wire sclk_fall = (sclk_prev==1'b1) && (sclk_sync==1'b0);
  wire csn_fall  = (csn_prev==1'b1)  && (csn_sync==1'b0);
  wire csn_rise  = (csn_prev==1'b0)  && (csn_sync==1'b1);

  wire leading_edge  = (CPOL==1'b0) ? sclk_rise : sclk_fall;
  wire trailing_edge = (CPOL==1'b0) ? sclk_fall : sclk_rise;
  wire sample_edge   = (CPHA==1'b0) ? leading_edge  : trailing_edge;
  wire shift_edge    = (CPHA==1'b0) ? trailing_edge : leading_edge;

  // ------------------------------ FIFOs ---------------------------
  localparam int RX_AW = (RX_DEPTH<=2) ? 1 : $clog2(RX_DEPTH);
  localparam int TX_AW = (TX_DEPTH<=2) ? 1 : $clog2(TX_DEPTH);

  // RX FIFO
  logic [7:0]       rx_mem [RX_DEPTH-1:0];
  logic [RX_AW-1:0] rx_rd_ptr, rx_wr_ptr;
  logic [RX_AW:0]   rx_count;

  // TX FIFO
  logic [7:0]       tx_mem [TX_DEPTH-1:0];
  logic [TX_AW-1:0] tx_rd_ptr, tx_wr_ptr;
  logic [TX_AW:0]   tx_count;

  wire rx_empty = (rx_count == 0);
  wire rx_full  = (rx_count == RX_DEPTH);
  wire tx_empty = (tx_count == 0);
  wire tx_full  = (tx_count == TX_DEPTH);

  assign rx_byte_valid = ~rx_empty;
  assign tx_byte_ready = ~tx_full;

  // -------------------- Handshakes internos -----------------------
  // Motor SPI -> FIFOs
  logic        rx_push;
  logic [7:0]  rx_push_data;
  logic        tx_consume;        // consome 1 byte do FIFO TX

  // Peek combinacional do próximo byte de TX (sem alterar ponteiros)
  logic [7:0]  tx_peek_data;
  always_comb begin
    tx_peek_data = tx_empty ? TX_UNDERFLOW_BYTE : tx_mem[tx_rd_ptr];
  end

  // -------------------- RX FIFO (pop e push) ----------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_rd_ptr <= '0;
      rx_wr_ptr <= '0;
      rx_count  <= '0;
      rx_byte   <= 8'h00;
    end else begin
      // push vindo do motor SPI
      if (rx_push && !rx_full) begin
        rx_mem[rx_wr_ptr] <= rx_push_data;
        rx_wr_ptr         <= rx_wr_ptr + 1'b1;
        rx_count          <= rx_count  + 1'b1;
      end

      // apresenta topo
      if (!rx_empty)
        rx_byte <= rx_mem[rx_rd_ptr];

      // pop externo
      if (rx_byte_ready && !rx_empty) begin
        rx_rd_ptr <= rx_rd_ptr + 1'b1;
        rx_count  <= rx_count  - 1'b1;
      end
    end
  end

  // -------------------- TX FIFO (push externo e consume) ----------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_wr_ptr <= '0;
      tx_rd_ptr <= '0;
      tx_count  <= '0;
    end else begin
      // push externo
      if (tx_byte_valid && !tx_full) begin
        tx_mem[tx_wr_ptr] <= tx_byte;
        tx_wr_ptr         <= tx_wr_ptr + 1'b1;
        tx_count          <= tx_count  + 1'b1;
      end

      // consume solicitado pelo motor SPI
      if (tx_consume && !tx_empty) begin
        tx_rd_ptr <= tx_rd_ptr + 1'b1;
        tx_count  <= tx_count  - 1'b1;
      end
    end
  end

  // ---------------------- Motor SPI (MSB first) -------------------
  logic       active;
  logic [2:0] bit_cnt;
  logic [7:0] shreg_in;
  logic [7:0] shreg_out;
  logic       miso_bit;

  // Tri-state quando CSN=1
  assign spi_miso = csn_sync ? 1'bz : miso_bit;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      active     <= 1'b0;
      bit_cnt    <= 3'd7;
      shreg_in   <= 8'h00;
      shreg_out  <= 8'h00;
      miso_bit   <= 1'b0;
      rx_push    <= 1'b0;
      rx_push_data <= 8'h00;
      tx_consume <= 1'b0;
    end else begin
      // defaults
      rx_push    <= 1'b0;
      tx_consume <= 1'b0;

      if (csn_rise)
        active <= 1'b0;

      if (csn_fall) begin
        active    <= 1'b1;
        bit_cnt   <= 3'd7;
        shreg_in  <= 8'h00;

        // pega primeiro byte do TX (peek) e agenda consumo se existir
        shreg_out <= tx_peek_data;
        if (!tx_empty) tx_consume <= 1'b1;

        // em CPHA=0, apresente já o bit7 antes da primeira amostragem do mestre
        if (CPHA == 1'b0)
          miso_bit <= tx_peek_data[7];
      end

      if (active && (sample_edge || shift_edge)) begin
        // SHIFT-OUT (antes da amostragem)
        if (shift_edge) begin
          miso_bit  <= shreg_out[7];
          shreg_out <= {shreg_out[6:0], 1'b0};
        end

        // SHIFT-IN (amostra MOSI)
        if (sample_edge) begin
          logic [7:0] new_in;
          new_in   = {shreg_in[6:0], mosi_sync};
          shreg_in <= new_in;

          if (bit_cnt == 3'd0) begin
            // Fecha byte RX -> solicita push no FIFO RX
            if (!rx_full) begin
              rx_push      <= 1'b1;
              rx_push_data <= new_in;
            end
            // Recarrega próximo byte TX via peek; agenda consumo se houver
            shreg_out <= tx_peek_data;
            if (!tx_empty) tx_consume <= 1'b1;

            bit_cnt <= 3'd7;

            if (CPHA == 1'b0)
              miso_bit <= tx_peek_data[7];
          end else begin
            bit_cnt <= bit_cnt - 3'd1;
          end
        end
      end
    end
  end

endmodule
`endif
