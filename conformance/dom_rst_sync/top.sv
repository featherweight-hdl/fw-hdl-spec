// FW-W-DOM-RSTSYNC: a child put on a clock unrelated to the clock of the
// reset it inherits; reported where the mismatch starts, not on the child's
// own child. A child on a related clock is fine.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    class leaf extends fw_component;
        `fw_component_utils(leaf)
    endclass

    class mid extends fw_component;
        `fw_component_utils(mid)
        leaf v;
        virtual function void build();
            v = leaf::create("v", this);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_clock_domain c0, c0d, c1;
        fw_reset_domain por, r;
        mid             u, w;
        virtual function void build();
            c0  = fw_clock_domain::create("c0", this);
            c0d = fw_clock_domain::create("c0d", this, fw_clock_kind::derived(c0, .div(2)));
            c1  = fw_clock_domain::create("c1", this);
            por = fw_reset_domain::create("por", this);
            r   = fw_reset_domain::create("r", this, fw_reset_kind::synced(por, c0));
            fw_clock_domain::set(this, c0);
            fw_reset_domain::set(this, r);
            u = mid::create("u", this);
            w = mid::create("w", this);
            fw_clock_domain::set(u, c1);
            fw_clock_domain::set(w, c0d);
        endfunction
    endclass

endpackage
