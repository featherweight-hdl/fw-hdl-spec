// relate() in the build phase choosing structure: a child is created for
// each relation that holds. Relations follow sources through derivations,
// including a muxed clock with two roots.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    class leaf extends fw_component;
        `fw_component_utils(leaf)
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_clock_domain c0, c1, c2, c3, mx;
        leaf            same_ok, rel_ok, chain_ok, unrel_ok, mux_ok, wrong;
        virtual function void build();
            c0 = fw_clock_domain::create("c0", this);
            c1 = fw_clock_domain::create("c1", this, fw_clock_kind::derived(c0, .div(2)));
            c2 = fw_clock_domain::create("c2", this);
            c3 = fw_clock_domain::create("c3", this, fw_clock_kind::gated(c1));
            mx = fw_clock_domain::create("mx", this, fw_clock_kind::muxed('{c1, c2}));
            if (fw_clock_domain::relate(c0, c0) == FW_DOMAIN_SAME)
                same_ok = leaf::create("same_ok", this);
            if (fw_clock_domain::relate(c0, c1) == FW_DOMAIN_RELATED)
                rel_ok = leaf::create("rel_ok", this);
            if (fw_clock_domain::relate(c3, c0) == FW_DOMAIN_RELATED)
                chain_ok = leaf::create("chain_ok", this);
            if (fw_clock_domain::relate(c1, c2) == FW_DOMAIN_UNRELATED)
                unrel_ok = leaf::create("unrel_ok", this);
            if (fw_clock_domain::relate(mx, c0) == FW_DOMAIN_RELATED
                    && fw_clock_domain::relate(mx, c2) == FW_DOMAIN_RELATED)
                mux_ok = leaf::create("mux_ok", this);
            if (fw_clock_domain::relate(c2, c3) != FW_DOMAIN_UNRELATED)
                wrong = leaf::create("wrong", this);
        endfunction
    endclass

endpackage
