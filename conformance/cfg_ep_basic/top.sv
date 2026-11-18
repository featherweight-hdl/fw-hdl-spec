// Configured endpoints: a device sources the configuration on a port and
// on a socket; a transactor sinks it on an export, passed up through its
// wrapper's export, and on the mirror socket, also passed up. Each
// connect and connect_up records an api binding and a cfg binding, the
// cfg one from source to sink.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_apis.svh"
    `include "test_uart_proto.svh"

    // Owns the configuration, on both of its endpoints.
    class dev extends fw_component implements test_get_if #(byte);
        `fw_component_utils(dev)
        fw_port_cfg_src #(test_put_if #(byte), uart_cfg_t) p;
        fw_socket_cfg_src #(test_put_if #(byte), test_get_if #(byte), uart_cfg_t) s;
        virtual function void build();
            p = fw_port_cfg_src #(test_put_if #(byte), uart_cfg_t)::create("p", this);
            s = fw_socket_cfg_src #(test_put_if #(byte), test_get_if #(byte), uart_cfg_t)::create("s", this);
            p.set('{baud: 9600, parity: 0, stop_bits: 1});
            s.set('{baud: 19200, parity: 1, stop_bits: 2});
        endfunction
        virtual task get(output byte t);
        endtask
    endclass

    // Reads the configuration on both endpoints, and listens for changes.
    class xtor extends fw_component implements test_put_if #(byte),
            fw_cfg_listener_if #(uart_cfg_t);
        `fw_component_utils(xtor)
        fw_export_cfg_sink #(test_put_if #(byte), uart_cfg_t) e;
        fw_socket_cfg_sink #(test_get_if #(byte), test_put_if #(byte), uart_cfg_t) t;
        int n;
        virtual function void build();
            e = fw_export_cfg_sink #(test_put_if #(byte), uart_cfg_t)::create("e", this);
            t = fw_socket_cfg_sink #(test_get_if #(byte), test_put_if #(byte), uart_cfg_t)::create("t", this);
            e.add_listener(this);
            t.add_listener(this);
        endfunction
        virtual task put(byte t);
        endtask
        virtual function void changed(uart_cfg_t v);
            n++;
        endfunction
    endclass

    // Passes the transactor's export and socket up as its own.
    class wrap extends fw_component;
        `fw_component_utils(wrap)
        xtor x;
        fw_export_cfg_sink #(test_put_if #(byte), uart_cfg_t) e;
        fw_socket_cfg_sink #(test_get_if #(byte), test_put_if #(byte), uart_cfg_t) t;
        virtual function void build();
            x = xtor::create("x", this);
            e = fw_export_cfg_sink #(test_put_if #(byte), uart_cfg_t)::create("e", this);
            t = fw_socket_cfg_sink #(test_get_if #(byte), test_put_if #(byte), uart_cfg_t)::create("t", this);
        endfunction
        virtual function void connect();
            x.e.connect_up(e);
            x.t.connect_up(t);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        dev  d;
        wrap w;
        virtual function void build();
            d = dev::create("d", this);
            w = wrap::create("w", this);
        endfunction
        virtual function void connect();
            d.p.connect(w.e);
            w.t.connect(d.s);
        endfunction
    endclass

endpackage
