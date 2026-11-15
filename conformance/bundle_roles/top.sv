// Bundle roles: a child initiator to a sibling's target, a pass-through of
// an own target to a child's target, and of a child's initiator to an own
// initiator. Member directions are effective directions.
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

    // A target and an initiator, with nothing inside.
    class pipe extends fw_component;
        `fw_component_utils(pipe)
        fw_mirror #(fw_rv_if #(bit)) in;
        fw_bundle #(fw_rv_if #(bit)) out;
        virtual function void build();
            in  = fw_mirror #(fw_rv_if #(bit))::create("in", this);
            out = fw_bundle #(fw_rv_if #(bit))::create("out", this);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_mirror #(fw_rv_if #(bit)) in;
        fw_bundle #(fw_rv_if #(bit)) out;
        src  s;
        snk  k;
        pipe p;
        virtual function void build();
            in  = fw_mirror #(fw_rv_if #(bit))::create("in", this);
            out = fw_bundle #(fw_rv_if #(bit))::create("out", this);
            s = src::create("s", this);
            k = snk::create("k", this);
            p = pipe::create("p", this);
        endfunction
        virtual function void connect();
            s.out.connect(k.in);      // child initiator <-> child target
            p.in.connect_up(in);      // own target <-> child target
            p.out.connect_up(out);    // own initiator <-> child initiator
        endfunction
    endclass

endpackage
