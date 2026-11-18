// A UART test protocol: a configuration, a timed transfer, a mismatch
// rule, a serial bundle and one request API.
`ifndef TEST_UART_PROTO_SVH
`define TEST_UART_PROTO_SVH
`include "test_apis.svh"

// The line configuration, shared by both ends.
typedef struct packed {
    int unsigned baud;       // bits per second
    bit          parity;     // a parity bit follows the data
    bit [1:0]    stop_bits;  // 1 or 2
} uart_cfg_t;

// One character, as sent or as received.
typedef struct packed {
    bit [7:0] data;
    bit       frame_err;     // set by the receiver on a framing error
} uart_char_t;

// The protocol.
class test_uart_proto extends fw_protocol;
    `fw_protocol_utils(test_uart_proto)

    typedef uart_cfg_t cfg_t;

    static function void declare(fw_protocol_decl d);
        d.api(fw_api_type_of #(test_put_if #(uart_char_t))::get(), FW_PROTO_REQ);
    endfunction

    // The time one character takes on the line, in ns: start, data,
    // parity and stop bits at ``c.baud``.
    static function time xfer_time(cfg_t c, uart_char_t t);
        int unsigned bits = 1 + 8 + c.parity + c.stop_bits;
        if (c.baud == 0)
            return 0;
        return time'(bits) * 64'd1_000_000_000 / c.baud;
    endfunction

    // The character as a receiver configured with ``rx`` sees ``t``, sent
    // with ``tx``: unchanged when they agree, else with ``frame_err`` set.
    static function uart_char_t mismatch(cfg_t tx, cfg_t rx, uart_char_t t);
        uart_char_t r = t;
        if (tx != rx)
            r.frame_err = 1;
        return r;
    endfunction
endclass

// The serial bundle, from the transmitter's view.
virtual class test_uart_serial extends fw_bundle_base;
    `fw_bundle_protocol(test_uart_proto)

    fw_output #(bit) tx;
    fw_input  #(bit) rx;

    virtual function void build();
        tx = fw_output #(bit)::create("tx", this);
        rx = fw_input  #(bit)::create("rx", this);
    endfunction
endclass

`endif // TEST_UART_PROTO_SVH
