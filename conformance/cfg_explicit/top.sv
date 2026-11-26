// A two-port UART device with a cfg source per port; each port's transactor
// is bound explicitly to its port's source: two cfg bindings. Config
// binding is explicit connect only; there is no FW-E-CFG-AMBIG.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_uart_proto.svh"

    // A UART device: line pins and its configuration.
    class uart_dev extends fw_component;
        `fw_component_utils(uart_dev)
        fw_cfg_src #(uart_cfg_t)      c0;
        fw_cfg_src #(uart_cfg_t)      c1;
        fw_mirror #(test_uart_serial) p0;
        fw_mirror #(test_uart_serial) p1;
        virtual function void build();
            c0 = fw_cfg_src #(uart_cfg_t)::create("c0", this);
            c1 = fw_cfg_src #(uart_cfg_t)::create("c1", this);
            p0 = fw_mirror #(test_uart_serial)::create("p0", this);
            p1 = fw_mirror #(test_uart_serial)::create("p1", this);
        endfunction
    endclass

    // The initiator transactor: API in, pins out; its cfg sink is bound
    // explicitly by whoever connects it. Its own export of the API may
    // stay open: nothing in this scenario calls through it.
    class ux_init extends fw_xtor_initiator #(test_uart_serial) implements test_put_if #(uart_char_t);
        `fw_xtor_utils(ux_init)
        fw_cfg_sink #(uart_cfg_t) cfg;
        virtual function void build();
            super.build();
            cfg = fw_cfg_sink #(uart_cfg_t)::create("cfg", this);
        endfunction
        virtual task put(uart_char_t t);
        endtask
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        uart_dev dev;
        ux_init  x0, x1;
        virtual function void build();
            dev = uart_dev::create("dev", this);
            x0 = ux_init::create("x0", this);
            x1 = ux_init::create("x1", this);
        endfunction
        virtual function void connect();
            x0.pins.connect(dev.p0);
            x1.pins.connect(dev.p1);
            x0.cfg.connect(dev.c0);
            x1.cfg.connect(dev.c1);
        endfunction
    endclass

endpackage
