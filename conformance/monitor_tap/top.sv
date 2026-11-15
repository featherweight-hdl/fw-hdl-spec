// Monitor taps: one monitor taps the initiator side of a link, another the
// target side. Each monitor member is a sink on the tapped member's net.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    // An initiator.
    class src extends fw_component;
        `fw_component_utils(src)
        fw_bundle #(fw_rv_if #(bit)) out;
        virtual function void build();
            out = fw_bundle #(fw_rv_if #(bit))::create("out", this);
        endfunction
    endclass

    // A target.
    class snk extends fw_component;
        `fw_component_utils(snk)
        fw_mirror #(fw_rv_if #(bit)) in;
        virtual function void build();
            in = fw_mirror #(fw_rv_if #(bit))::create("in", this);
        endfunction
    endclass

    // Observes a link.
    class mon extends fw_component;
        `fw_component_utils(mon)
        fw_monitor #(fw_rv_if #(bit)) p;
        virtual function void build();
            p = fw_monitor #(fw_rv_if #(bit))::create("p", this);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        src s;
        snk k;
        mon m1, m2;
        virtual function void build();
            s  = src::create("s", this);
            k  = snk::create("k", this);
            m1 = mon::create("m1", this);
            m2 = mon::create("m2", this);
        endfunction
        virtual function void connect();
            s.out.connect(k.in);
            m1.p.connect(s.out);
            m2.p.connect(k.in);
        endfunction
    endclass

endpackage
