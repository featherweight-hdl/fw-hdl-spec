// Lookup of default associations: the top's clock inherited three levels
// down; a middle level setting one child's clock and the reset set on the
// middle level only. Each component records what get() returned as the
// source of a probe domain (seen, rseen).
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    class leaf extends fw_component;
        `fw_component_utils(leaf)
        fw_clock_domain seen;
        fw_reset_domain rseen;
        virtual function void build();
            seen  = fw_clock_domain::create("seen", this,
                        fw_clock_kind::derived(fw_clock_domain::get(this)));
            rseen = fw_reset_domain::create("rseen", this,
                        fw_reset_kind::synced(fw_reset_domain::get(this), fw_clock_domain::get(this)));
        endfunction
    endclass

    class mid extends fw_component;
        `fw_component_utils(mid)
        fw_clock_domain clk_c, seen;
        fw_reset_domain rseen;
        leaf            l0, l1;
        virtual function void build();
            seen  = fw_clock_domain::create("seen", this,
                        fw_clock_kind::derived(fw_clock_domain::get(this)));
            rseen = fw_reset_domain::create("rseen", this,
                        fw_reset_kind::synced(fw_reset_domain::get(this), fw_clock_domain::get(this)));
            clk_c = fw_clock_domain::create("clk_c", this,
                        fw_clock_kind::derived(fw_clock_domain::get(this), .div(2)));
            l0 = leaf::create("l0", this);
            l1 = leaf::create("l1", this);
            fw_clock_domain::set(l1, clk_c);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_clock_domain clk_a, seen;
        fw_reset_domain por;
        mid             m;
        virtual function void build();
            clk_a = fw_clock_domain::create("clk_a", this);
            por   = fw_reset_domain::create("por", this);
            fw_clock_domain::set(this, clk_a);
            seen  = fw_clock_domain::create("seen", this,
                        fw_clock_kind::derived(fw_clock_domain::get(this)));
            m = mid::create("m", this);
            fw_reset_domain::set(m, por);
        endfunction
    endclass

endpackage
