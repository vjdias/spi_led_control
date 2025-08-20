`timescale 1ns/1ps
`ifndef TB_PKG_SV
`define TB_PKG_SV

package tb_pkg;

  // Simple alias
  typedef byte byte_t;

  // Protocol constants (mirror RTL)
  localparam byte_t HDR_REQ  = 8'hAA;
  localparam byte_t TAIL_REQ = 8'h55;
  localparam byte_t HDR_RSP  = 8'hAB;
  localparam byte_t TAIL_RSP = 8'h54;
  localparam byte_t CMD_LED  = 8'h30;

  // ------------------------------------------------------------
  // Transaction: LED command item
  // ------------------------------------------------------------
  class led_cmd_item;
    rand byte_t id;
    rand byte_t idx;
    rand bit    val;
    bit         exp_ok;

    function new(byte_t id = 8'h01, byte_t idx = 0, bit val = 1);
      this.id    = id;
      this.idx   = idx & 8'h07;
      this.val   = val & 1'b1;
      this.exp_ok = (idx < 8);
    endfunction

    function void build_req_bytes(ref byte req[$]);
      req.delete();
      req.push_back(HDR_REQ);
      req.push_back(CMD_LED);
      req.push_back(byte'(id));
      req.push_back(byte'(idx));
      req.push_back(byte'({7'b0, val}));
      req.push_back(TAIL_REQ);
    endfunction

    function void build_exp_rsp_body(ref byte body[$]);
      body.delete();
      body.push_back(CMD_LED);
      body.push_back(byte'(id));
      body.push_back(byte'(idx & 8'h07));
      body.push_back(byte'({7'b0, val}));
      body.push_back(byte'({7'b0, exp_ok}));
    endfunction
  endclass : led_cmd_item

  // ------------------------------------------------------------
  // SPI master BFM (uses full interface, no modport)
  // ------------------------------------------------------------
  class spi_master_bfm;
    virtual spi_if vif;

    function new(virtual spi_if vif);
      this.vif = vif;
    endfunction

    task automatic init();
      vif.init_bus();
    endtask

    // First SPI transaction: send request frame
    task automatic send_led_req(led_cmd_item tr);
      byte req[$];
      tr.build_req_bytes(req);
      vif.cs_low();
      vif.write_bytes(req);
      vif.cs_high();
    endtask

    // Second SPI transaction: read response frame
    task automatic read_led_rsp(output byte rsp[$], input int max_frames = 64);
      byte first; rsp.delete();

      for (int f = 0; f < max_frames; f++) begin
        #(200ns);              // pequeno intervalo entre tentativas
        vif.cs_low();
          vif.xfer_byte(8'h00, first);
        vif.cs_high();

        if (first == HDR_RSP) begin
          byte body[$];
          #(100ns);            // gap curto
          vif.cs_low();
            vif.read_n_bytes(6, body); // CMD, ID, IDX, VAL, OK, TAIL
          vif.cs_high();

          rsp.push_back(first);
          foreach (body[i]) rsp.push_back(body[i]);
          return;
        end
      end

      $error("[SPI BFM] Timeout esperando HDR_RSP (0x%02h) em %0d frames.", HDR_RSP, max_frames);
    endtask
  endclass : spi_master_bfm

  // ------------------------------------------------------------
  // Scoreboard
  // ------------------------------------------------------------
  class led_scoreboard;
    virtual leds_if.mon v_leds;
    mailbox exp_mb;
    mailbox got_mb;

    function new(virtual leds_if.mon v_leds);
      this.v_leds = v_leds;
      this.exp_mb = new();
      this.got_mb = new();
    endfunction

    task automatic check_one(led_cmd_item tr, byte rsp[$]);
      bit led_hw;

      if (rsp.size() != 7) begin
        $error("[SCB] Response size invalid: %0d", rsp.size());
        return;
      end
      if (rsp[0] != HDR_RSP) $error("[SCB] HDR invalid: 0x%02h", rsp[0]);
      if (rsp[1] != CMD_LED) $error("[SCB] CMD invalid: 0x%02h", rsp[1]);
      if (rsp[2] != tr.id)   $error("[SCB] ID invalid: 0x%02h (exp=0x%02h)", rsp[2], tr.id);
      if ((rsp[3] & 8'h07) != (tr.idx & 8'h07))
        $error("[SCB] IDX invalid: 0x%02h (exp=0x%02h)", rsp[3], tr.idx & 8'h07);
      if ((rsp[4] & 8'h01) != (tr.val & 1))
        $error("[SCB] VAL invalid: 0x%02h (exp=%0d)", rsp[4], tr.val);
      if ((rsp[5] & 8'h01) != (tr.exp_ok & 1))
        $error("[SCB] OK invalid: 0x%02h (exp=%0d)", rsp[5], tr.exp_ok);
      if (rsp[6] != TAIL_RSP) $error("[SCB] TAIL invalid: 0x%02h", rsp[6]);

      // Simple settle time for LED reflection
      #40ns;
      led_hw = v_leds.leds[tr.idx];
      if (led_hw != tr.val)
        $error("[SCB] LED[%0d] HW=%0d differs from expected %0d", tr.idx, led_hw, tr.val);
      else
        $display("[SCB] OK: LED[%0d]=%0d, ID=0x%02h.", tr.idx, tr.val, tr.id);
    endtask

    task automatic run();
      led_cmd_item tr;
      byte rsp[$];
      forever begin
        exp_mb.get(tr);
        got_mb.get(rsp);
        check_one(tr, rsp);
      end
    endtask
  endclass : led_scoreboard

  // ------------------------------------------------------------
  // Environment
  // ------------------------------------------------------------
  class led_env;
    spi_master_bfm bfm;
    led_scoreboard scb;

    function new(virtual spi_if vif, virtual leds_if.mon v_leds);
      bfm = new(vif);
      scb = new(v_leds);
    endfunction

    task automatic build();
      bfm.init();
      fork
        begin
          scb.run();
        end
      join_none
    endtask

    task automatic do_led(led_cmd_item tr);
      byte rsp[$];
      scb.exp_mb.put(tr);
      bfm.send_led_req(tr);
      bfm.read_led_rsp(rsp);
      scb.got_mb.put(rsp);
    endtask
  endclass : led_env

  // ------------------------------------------------------------
  // Test
  // ------------------------------------------------------------
  class led_test;
    led_env env;

    function new(led_env env);
      this.env = env;
    endfunction

    task automatic run();
      led_cmd_item t;
      int i;
      byte_t id_vec [5] = '{8'hA1, 8'hA2, 8'hA3, 8'hA4, 8'hA5};
      byte_t idx_vec[5] = '{8'd0,  8'd3,  8'd3,  8'd4,  8'd8 };
      bit    val_vec[5] = '{1,     1,     0,     1,     1    };

      env.build();

      for (i = 0; i < 5; i++) begin
        t = new(id_vec[i], idx_vec[i], val_vec[i]);
        env.do_led(t);
      end

      #2us;
      $display("[TEST] Finished.");
      $finish;
    endtask
  endclass : led_test

endpackage
`endif
