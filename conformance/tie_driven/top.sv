// A child input that is both connected to a source and tied: FW-E-NET-MULTI,
// named by the first of the net's sources and tied endpoints in path order.
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
        fw_input #(bit) x;
        leaf            c;
        virtual function void build();
            x = fw_input #(bit)::create("x", this);
            c = leaf::create("c", this);
        endfunction
        virtual function void connect();
            x.connect(c.i);
            c.i.tie(1);
        endfunction
    endclass

endpackage
