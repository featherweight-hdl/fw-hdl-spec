// Two child outputs drive one child input: FW-E-NET-MULTI, named by the
// first source in path order.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    // A leaf: one input, one output.
    class leaf extends fw_component;
        `fw_component_utils(leaf)
        fw_input  #(bit) i;
        fw_output #(bit) o;
        virtual function void build();
            i = fw_input  #(bit)::create("i", this);
            o = fw_output #(bit)::create("o", this);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        leaf c1, c2, c3;
        virtual function void build();
            c1 = leaf::create("c1", this);
            c2 = leaf::create("c2", this);
            c3 = leaf::create("c3", this);
        endfunction
        virtual function void connect();
            c1.i.tie(0);
            c2.i.tie(0);
            c1.o.connect(c3.i);
            c2.o.connect(c3.i);
        endfunction
    endclass

endpackage
