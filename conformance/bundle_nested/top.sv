// Nested bundles: pair_if holds an initiator req and a mirror rsp. In the
// target (a mirror of pair_if), rsp is a mirror inside a mirror, so its
// members keep their declared directions. A monitor of pair_if makes every
// nested member an input.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    virtual class ch_if extends fw_bundle_base;
        fw_output #(bit) valid;
        fw_input  #(bit) ready;
        virtual function void build();
            valid = fw_output #(bit)::create("valid", this);
            ready = fw_input  #(bit)::create("ready", this);
        endfunction
    endclass

    virtual class pair_if extends fw_bundle_base;
        fw_output #(bit)   en;
        fw_bundle #(ch_if) req;
        fw_mirror #(ch_if) rsp;
        virtual function void build();
            en  = fw_output #(bit)::create("en", this);
            req = fw_bundle #(ch_if)::create("req", this);
            rsp = fw_mirror #(ch_if)::create("rsp", this);
        endfunction
    endclass

    class ini extends fw_component;
        `fw_component_utils(ini)
        fw_bundle #(pair_if) m;
        virtual function void build();
            m = fw_bundle #(pair_if)::create("m", this);
        endfunction
    endclass

    class tgt extends fw_component;
        `fw_component_utils(tgt)
        fw_mirror #(pair_if) s;
        virtual function void build();
            s = fw_mirror #(pair_if)::create("s", this);
        endfunction
    endclass

    class tap extends fw_component;
        `fw_component_utils(tap)
        fw_monitor #(pair_if) p;
        virtual function void build();
            p = fw_monitor #(pair_if)::create("p", this);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        ini a;
        tgt b;
        tap t;
        virtual function void build();
            a = ini::create("a", this);
            b = tgt::create("b", this);
            t = tap::create("t", this);
        endfunction
        virtual function void connect();
            a.m.connect(b.s);
            t.p.connect(a.m);
        endfunction
    endclass

endpackage
