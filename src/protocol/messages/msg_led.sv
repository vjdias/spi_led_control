`ifndef MSG_LED_SV
`define MSG_LED_SV
package msg_led;
  typedef struct packed { logic [7:0] id; logic [2:0] led_idx; logic led_val; } set_led_req_t;
  typedef struct packed { logic [7:0] id; logic [2:0] led_idx; logic led_val; logic ok; } set_led_rsp_t;
endpackage
`endif
