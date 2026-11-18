// connect_all of two initiators of the same type: valid and data get two
// sources (FW-E-NET-MULTI) and ready none (FW-E-NET-UNDRIVEN).
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;

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

    class top extends fw_component;
        `fw_component_utils(top)
        src a, b;
        virtual function void build();
            a = src::create("a", this);
            b = src::create("b", this);
        endfunction
        virtual function void connect();
            connect_all('{ '{a.out, b.out} });
        endfunction
    endclass

endpackage
