// A sink's cfg passed as a const ref argument: a read, so no
// diagnostic. Static only: it checks the front end's write analysis.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_uart_proto.svh"

    // Owns the configuration; sets it in build().
    class owner extends fw_component;
        `fw_component_utils(owner)
        fw_cfg_src #(uart_cfg_t) p;
        virtual function void build();
            p = fw_cfg_src #(uart_cfg_t)::create("p", this);
            p.set('{baud: 9600, parity: 0, stop_bits: 1});
        endfunction
    endclass

    // Reads the configuration.
    class reader extends fw_component;
        `fw_component_utils(reader)
        fw_cfg_sink #(uart_cfg_t) c;
        virtual function void build();
            c = fw_cfg_sink #(uart_cfg_t)::create("c", this);
        endfunction
        function int unsigned bits(const ref uart_cfg_t v);
            return 1 + 8 + v.parity + v.stop_bits;
        endfunction
        function int unsigned frame();
            return bits(c.cfg);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        owner  o;
        reader r;
        virtual function void build();
            o = owner::create("o", this);
            r = reader::create("r", this);
        endfunction
        virtual function void connect();
            r.c.connect(o.p);
        endfunction
    endclass

endpackage
