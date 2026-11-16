// FW-E-DOM-NONE: a derivation with a null source; relate() with a null
// argument; an extern pin whose domain resolves to none.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    class ext extends fw_component implements fw_extern_if;
        `fw_extern_utils(ext, "ext_mod")
        virtual function void extern_map(fw_extern_map m);
            fw_clock_domain::pin(m, "clk");
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_clock_domain clk, nul, bad;
        ext             e;
        virtual function void build();
            clk = fw_clock_domain::create("clk", this);
            nul = fw_clock_domain::get(this);
            bad = fw_clock_domain::create("bad", this, fw_clock_kind::derived(nul));
            if (fw_clock_domain::relate(nul, clk) != FW_DOMAIN_UNRELATED)
                clk = null;
            e = ext::create("e", this);
        endfunction
    endclass

endpackage
