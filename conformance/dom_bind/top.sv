// FW-E-DOM-BIND: the same object, kind and name set twice: a child, the
// component itself, its own port. Setting a different kind, or a different
// name, is not a second binding.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    // A leaf with one output.
    class src extends fw_component;
        `fw_component_utils(src)
        fw_output #(bit) o;
        virtual function void build();
            o = fw_output #(bit)::create("o", this);
        endfunction
    endclass

    // A leaf with one input.
    class snk extends fw_component;
        `fw_component_utils(snk)
        fw_input #(bit) i;
        virtual function void build();
            i = fw_input #(bit)::create("i", this);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_input #(bit) p;
        fw_clock_domain c0, c1;
        fw_reset_domain r0;
        snk             u;
        virtual function void build();
            p  = fw_input #(bit)::create("p", this);
            c0 = fw_clock_domain::create("c0", this);
            c1 = fw_clock_domain::create("c1", this);
            r0 = fw_reset_domain::create("r0", this);
            u  = snk::create("u", this);
            fw_clock_domain::set(u, c0);
            fw_reset_domain::set(u, r0);
            fw_clock_domain::set(u, c1);
            fw_clock_domain::set(this, c0);
            fw_clock_domain::set(this, c0);
            fw_clock_domain::set(p, c0);
            fw_clock_domain::set(p, c1);
        endfunction
        virtual function void connect();
            u.i.connect(p);
        endfunction
    endclass

endpackage
