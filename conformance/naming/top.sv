// Naming: full names through the hierarchy, port arrays p[i], child arrays
// u[i], a local signal. Unconnected outputs are legal.
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
        fw_input  #(bit) p[2];
        fw_signal #(bit) s;
        leaf             a;
        leaf             u[2];
        virtual function void build();
            foreach (p[k]) p[k] = fw_input #(bit)::create($sformatf("p[%0d]", k), this);
            s = fw_signal #(bit)::create("s", this);
            a = leaf::create("a", this);
            foreach (u[k]) u[k] = leaf::create($sformatf("u[%0d]", k), this);
        endfunction
        virtual function void connect();
            p[0].connect(a.i);
            a.o.connect(s);
            s.connect(u[0].i);
            u[1].i.connect(p[1]);
        endfunction
    endclass

endpackage
