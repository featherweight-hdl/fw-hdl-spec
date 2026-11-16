// FW-E-DOM-OBJ: set on a grandchild, a child's port and a bundle member; a
// named association on a port; port_name for another component. The
// grandchild and the child's port are created in constructors, so they exist
// during the top's build.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    class early_src extends fw_component;
        `fw_component_utils(early_src)
        fw_output #(bit) o;
        function new();
            o = fw_output #(bit)::create("o", this);
        endfunction
    endclass

    class mid extends fw_component;
        `fw_component_utils(mid)
        early_src l;
        function new();
            l = early_src::create("l", this);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_input   #(bit)            p;
        fw_monitor #(fw_rv_if #(bit)) b;
        fw_clock_domain              clk;
        mid                          m;
        early_src                    u;
        virtual function void build();
            p   = fw_input #(bit)::create("p", this);
            b   = fw_monitor #(fw_rv_if #(bit))::create("b", this);
            clk = fw_clock_domain::create("clk", this);
            m   = mid::create("m", this);
            u   = early_src::create("u", this);
            fw_clock_domain::set(m.l, clk);
            fw_clock_domain::set(u.o, clk);
            fw_clock_domain::set(b.valid, clk);
            fw_clock_domain::set(p, clk, "x");
            fw_clock_domain::port_name(u, "", "ck");
        endfunction
    endclass

endpackage
