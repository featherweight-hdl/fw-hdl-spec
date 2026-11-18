// The test UART's kit channels (protocol-kit prep §3.5), over the std
// fw_timed_channel: a one-way forwarding channel (a device and a VIP, the
// device's configuration) and a two-way sinking channel (two devices, each
// with its own). The user places a channel in the topology; elaboration
// inserts none. Needs fw_hdl_std_pkg imported.
`ifndef TEST_UART_CHAN_SVH
`define TEST_UART_CHAN_SVH
`include "test_uart_proto.svh"

typedef test_put_if #(uart_char_t) uart_put_if;

// Forwarding: the device's port connects to ``dev``; ``vip`` connects to the
// VIP's export and carries the device's configuration to it. Each character
// takes its transfer time under the device's configuration, then reaches
// the VIP as sent.
class uart_tx_chan extends fw_timed_channel #(uart_cfg_t, uart_char_t)
        implements uart_put_if, fw_cfg_listener_if #(uart_cfg_t);
    `fw_component_utils(uart_tx_chan)
    fw_export_cfg_sink #(uart_put_if, uart_cfg_t) dev;
    fw_port_cfg_src #(uart_put_if, uart_cfg_t)    vip;

    virtual function void build();
        dev = fw_export_cfg_sink #(uart_put_if, uart_cfg_t)::create("dev", this);
        vip = fw_port_cfg_src #(uart_put_if, uart_cfg_t)::create("vip", this);
        dev.set_imp(this);
        dev.add_listener(this);
    endfunction

    virtual function time xfer_time(uart_cfg_t cfg, uart_char_t t);
        return test_uart_proto::xfer_time(cfg, t) * 1ns;   // the protocol's is in ns
    endfunction

    // The device's configuration, passed on to the VIP.
    virtual function void changed(uart_cfg_t v);
        vip.set(v);
    endfunction

    virtual task put(uart_char_t t);
        xfer_fwd(dev.cfg, t);
        vip.get_if().put(t);
    endtask
endclass

typedef class uart_txrx_chan;

// One side of a uart_txrx_chan: the export its device's socket calls.
class uart_txrx_side implements uart_put_if;
    uart_txrx_chan c;
    bit            from_b;
    function new(uart_txrx_chan c, bit from_b);
        this.c = c;
        this.from_b = from_b;
    endfunction
    virtual task put(uart_char_t t);
        c.xfer(from_b, t);
    endtask
endclass

// Sinking: two devices' sockets connect to ``a`` and ``b``. A character
// takes its transfer time under the sender's configuration and reaches the
// other device with ``frame_err`` set when the two configurations differ
// (test_uart_proto::mismatch), both sampled when the character starts.
class uart_txrx_chan extends fw_timed_channel #(uart_cfg_t, uart_char_t);
    `fw_component_utils(uart_txrx_chan)
    fw_socket_cfg_sink #(uart_put_if, uart_put_if, uart_cfg_t) a;
    fw_socket_cfg_sink #(uart_put_if, uart_put_if, uart_cfg_t) b;

    virtual function void build();
        uart_txrx_side sa = new(this, 0);
        uart_txrx_side sb = new(this, 1);
        a = fw_socket_cfg_sink #(uart_put_if, uart_put_if, uart_cfg_t)::create("a", this);
        b = fw_socket_cfg_sink #(uart_put_if, uart_put_if, uart_cfg_t)::create("b", this);
        a.set_imp(sa);
        b.set_imp(sb);
    endfunction

    virtual function time xfer_time(uart_cfg_t cfg, uart_char_t t);
        return test_uart_proto::xfer_time(cfg, t) * 1ns;   // the protocol's is in ns
    endfunction

    virtual function uart_char_t mismatch(uart_cfg_t tx_cfg, uart_cfg_t rx_cfg, uart_char_t t);
        return test_uart_proto::mismatch(tx_cfg, rx_cfg, t);
    endfunction

    // A character from a (from_b 0) to b, or from b to a.
    virtual task xfer(bit from_b, uart_char_t t);
        uart_char_t rx;
        if (!from_b) begin
            xfer_sink(a.cfg, b.cfg, t, rx);
            b.get_if().put(rx);
        end else begin
            xfer_sink(b.cfg, a.cfg, t, rx);
            a.get_if().put(rx);
        end
    endtask
endclass

`endif // TEST_UART_CHAN_SVH
