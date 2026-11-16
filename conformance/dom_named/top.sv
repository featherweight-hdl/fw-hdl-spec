// Named associations: a component reads two names that are set and one that
// is not (it falls back to the component's default). Named associations are
// not inherited: the child sees its parent's default.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    class leaf extends fw_component;
        `fw_component_utils(leaf)
        fw_clock_domain seen;
        virtual function void build();
            seen = fw_clock_domain::create("seen", this,
                       fw_clock_kind::derived(fw_clock_domain::get(this)));
        endfunction
    endclass

    class dual extends fw_component;
        `fw_component_utils(dual)
        fw_clock_domain seen_wr, seen_rd, seen_aux;
        leaf            k;
        virtual function void build();
            seen_wr  = fw_clock_domain::create("seen_wr", this,
                           fw_clock_kind::derived(fw_clock_domain::get(this, "wr")));
            seen_rd  = fw_clock_domain::create("seen_rd", this,
                           fw_clock_kind::derived(fw_clock_domain::get(this, "rd")));
            seen_aux = fw_clock_domain::create("seen_aux", this,
                           fw_clock_kind::derived(fw_clock_domain::get(this, "aux")));
            k = leaf::create("k", this);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_clock_domain c0, c1, c2;
        dual            d;
        virtual function void build();
            c0 = fw_clock_domain::create("c0", this);
            c1 = fw_clock_domain::create("c1", this);
            c2 = fw_clock_domain::create("c2", this);
            fw_clock_domain::set(this, c0);
            d = dual::create("d", this);
            fw_clock_domain::set(d, c1);
            fw_clock_domain::set(d, c0, "wr");
            fw_clock_domain::set(d, c2, "rd");
        endfunction
    endclass

endpackage
