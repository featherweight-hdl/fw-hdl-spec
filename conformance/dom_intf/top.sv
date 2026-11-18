// Interfaces: a port and a bundle set to a domain; a bundle member follows
// its bundle; an unset port follows its component; a child's port follows
// the child. Probe domains record what get() returned.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;

    class leaf extends fw_component;
        `fw_component_utils(leaf)
        fw_input #(bit) i;
        fw_clock_domain seen;
        virtual function void build();
            i    = fw_input #(bit)::create("i", this);
            seen = fw_clock_domain::create("seen", this,
                       fw_clock_kind::derived(fw_clock_domain::get(i)));
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_input   #(bit)             p_in, q;
        fw_monitor #(fw_rv_if #(bit)) b;
        fw_clock_domain               clk_a, clk_b, seen_p, seen_q, seen_b, seen_bv;
        leaf                          u;
        virtual function void build();
            p_in  = fw_input #(bit)::create("p_in", this);
            q     = fw_input #(bit)::create("q", this);
            b     = fw_monitor #(fw_rv_if #(bit))::create("b", this);
            clk_a = fw_clock_domain::create("clk_a", this);
            clk_b = fw_clock_domain::create("clk_b", this);
            fw_clock_domain::set(this, clk_a);
            fw_clock_domain::set(p_in, clk_b);
            fw_clock_domain::set(b, clk_b);
            seen_p  = fw_clock_domain::create("seen_p", this,
                          fw_clock_kind::derived(fw_clock_domain::get(p_in)));
            seen_q  = fw_clock_domain::create("seen_q", this,
                          fw_clock_kind::derived(fw_clock_domain::get(q)));
            seen_b  = fw_clock_domain::create("seen_b", this,
                          fw_clock_kind::derived(fw_clock_domain::get(b)));
            seen_bv = fw_clock_domain::create("seen_bv", this,
                          fw_clock_kind::derived(fw_clock_domain::get(b.valid)));
            u = leaf::create("u", this);
            fw_clock_domain::set(u, clk_b);
        endfunction
        virtual function void connect();
            u.i.connect(p_in);
        endfunction
    endclass

endpackage
