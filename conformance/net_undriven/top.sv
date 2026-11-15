// A local signal fans out to two child inputs with nothing driving it: FW-E-
// NET-UNDRIVEN, named by the first sink in path order.
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
        fw_signal #(bit) s;
        leaf             c1, c2;
        virtual function void build();
            s  = fw_signal #(bit)::create("s", this);
            c1 = leaf::create("c1", this);
            c2 = leaf::create("c2", this);
        endfunction
        virtual function void connect();
            s.connect(c1.i);
            s.connect(c2.i);
        endfunction
    endclass

endpackage
