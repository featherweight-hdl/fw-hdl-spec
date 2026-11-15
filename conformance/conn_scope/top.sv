// Endpoints outside the connecting component's scope: a child's local
// signal, and a grandchild's port. FW-E-CONN-SCOPE on each.
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

    class mid extends fw_component;
        `fw_component_utils(mid)
        fw_input  #(bit) i;
        fw_signal #(bit) s;
        leaf             l;
        virtual function void build();
            i = fw_input  #(bit)::create("i", this);
            s = fw_signal #(bit)::create("s", this);
            l = leaf::create("l", this);
        endfunction
        virtual function void connect();
            i.connect(l.i);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_input  #(bit) x;
        fw_output #(bit) y;
        mid              m;
        virtual function void build();
            x = fw_input  #(bit)::create("x", this);
            y = fw_output #(bit)::create("y", this);
            m = mid::create("m", this);
        endfunction
        virtual function void connect();
            x.connect(m.i);
            x.connect(m.s);       // a child's local signal
            y.connect(m.l.o);     // a grandchild's port
        endfunction
    endclass

endpackage
