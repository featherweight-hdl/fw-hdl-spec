// Configuration listeners in the netlist: a component listening on its own
// sink, a plain object held in a member and one held in a local, and a
// sibling component registered by the parent in connect(). Sink r.c has
// three listeners, numbered in call order; r.d has one.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_uart_proto.svh"

    // A plain object, not an fw object: it has no path.
    class counter implements fw_cfg_listener_if #(uart_cfg_t);
        int n;
        virtual function void changed(uart_cfg_t v);
            n++;
        endfunction
    endclass

    // Owns the configuration; sets it in build().
    class owner extends fw_component;
        `fw_component_utils(owner)
        fw_cfg_src #(uart_cfg_t) p;
        virtual function void build();
            p = fw_cfg_src #(uart_cfg_t)::create("p", this);
            p.set('{baud: 9600, parity: 0, stop_bits: 1});
        endfunction
    endclass

    // Listens on its own sink c, and registers plain objects on c and d.
    class reader extends fw_component implements fw_cfg_listener_if #(uart_cfg_t);
        `fw_component_utils(reader)
        fw_cfg_sink #(uart_cfg_t) c;
        fw_cfg_sink #(uart_cfg_t) d;
        counter cnt;
        int n;
        virtual function void build();
            counter tmp;
            c = fw_cfg_sink #(uart_cfg_t)::create("c", this);
            d = fw_cfg_sink #(uart_cfg_t)::create("d", this);
            cnt = new;
            tmp = new;
            c.add_listener(this);
            c.add_listener(cnt);
            d.add_listener(tmp);
        endfunction
        virtual function void changed(uart_cfg_t v);
            n++;
        endfunction
    endclass

    // A component that listens on another component's sink.
    class watcher extends fw_component implements fw_cfg_listener_if #(uart_cfg_t);
        `fw_component_utils(watcher)
        int n;
        virtual function void changed(uart_cfg_t v);
            n++;
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        owner   o;
        reader  r;
        watcher w;
        virtual function void build();
            o = owner::create("o", this);
            r = reader::create("r", this);
            w = watcher::create("w", this);
        endfunction
        virtual function void connect();
            r.c.connect(o.p);
            r.d.connect(o.p);
            r.c.add_listener(w);
        endfunction
    endclass

endpackage
