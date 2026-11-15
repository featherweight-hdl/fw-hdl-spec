// unused() misused: on an output (its net would have no driver in the
// emitted RTL), and on a port pin() also maps. Both FW-E-EXT-PORT, on the
// port.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    class ext extends fw_component implements fw_extern_if;
        `fw_extern_utils(ext, "ext_mod")

        fw_input  #(bit) a, b;
        fw_output #(bit) y;

        virtual function void build();
            a = fw_input  #(bit)::create("a", this);
            b = fw_input  #(bit)::create("b", this);
            y = fw_output #(bit)::create("y", this);
        endfunction

        virtual function void extern_map(fw_extern_map m);
            m.unused(y);
            m.pin("B", b);
            m.unused(b);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_input  #(bit) a, b;
        fw_output #(bit) y;
        ext              e;
        virtual function void build();
            a = fw_input  #(bit)::create("a", this);
            b = fw_input  #(bit)::create("b", this);
            y = fw_output #(bit)::create("y", this);
            e = ext::create("e", this);
        endfunction
        virtual function void connect();
            e.a.connect(a);
            e.b.connect(b);
            y.connect(e.y);
        endfunction
    endclass

endpackage
