// Two ports of an extern mapped to the same module pin: FW-E-EXT-PIN on the
// extern. Needs no module header.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    class ext extends fw_component implements fw_extern_if;
        `fw_extern_utils(ext, "dup_mod")
        fw_input #(bit) a, b;
        virtual function void build();
            a = fw_input #(bit)::create("a", this);
            b = fw_input #(bit)::create("b", this);
        endfunction
        virtual function void extern_map(fw_extern_map m);
            m.pin("x", a);
            m.pin("x", b);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        ext e;
        virtual function void build();
            e = ext::create("e", this);
        endfunction
        virtual function void connect();
            e.a.tie(0);
            e.b.tie(0);
        endfunction
    endclass

endpackage
