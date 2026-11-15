// A connection made in build(): FW-E-CONN-PHASE on the endpoint whose
// connect was called.
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
        fw_input  #(bit) x;
        fw_output #(bit) y;
        leaf             c;
        virtual function void build();
            x = fw_input  #(bit)::create("x", this);
            y = fw_output #(bit)::create("y", this);
            c = leaf::create("c", this);
            y.connect(x);         // too early
        endfunction
        virtual function void connect();
            x.connect(c.i);
        endfunction
    endclass

endpackage
