// A protocol's bundle in all three roles: an initiator, a target (mirror)
// and a monitor tap.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;
    `include "test_rv_proto.svh"

    class src extends fw_component;
        `fw_component_utils(src)
        fw_bundle #(test_rv_bundle #(8)) out;
        virtual function void build();
            out = fw_bundle #(test_rv_bundle #(8))::create("out", this);
        endfunction
    endclass

    class snk extends fw_component;
        `fw_component_utils(snk)
        fw_mirror #(test_rv_bundle #(8)) in;
        virtual function void build();
            in = fw_mirror #(test_rv_bundle #(8))::create("in", this);
        endfunction
    endclass

    class mon extends fw_component;
        `fw_component_utils(mon)
        fw_monitor #(test_rv_bundle #(8)) p;
        virtual function void build();
            p = fw_monitor #(test_rv_bundle #(8))::create("p", this);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        src s;
        snk k;
        mon m;
        virtual function void build();
            s = src::create("s", this);
            k = snk::create("k", this);
            m = mon::create("m", this);
        endfunction
        virtual function void connect();
            s.out.connect(k.in);
            m.p.connect(s.out);
        endfunction
    endclass

endpackage
