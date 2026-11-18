// A source and its sink in unrelated clock domains: FW-E-DOM-CROSS
// on the lesser path.
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
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_clock_domain c0, c2;
        owner  o;
        reader r;
        virtual function void build();
            c0 = fw_clock_domain::create("c0", this);
            c2 = fw_clock_domain::create("c2", this);
            fw_clock_domain::set(this, c0);
            o = owner::create("o", this);
            r = reader::create("r", this);
            fw_clock_domain::set(r, c2);
        endfunction
        virtual function void connect();
            r.c.connect(o.p);
        endfunction
    endclass

endpackage
