// FW-E-DOM-NODRIVER: a domain realized by an extern pin with no driver. A
// domain nothing uses physically needs none.
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
        fw_clock_domain clk, marker;
        ext             e;
        virtual function void build();
            clk    = fw_clock_domain::create("clk", this);
            marker = fw_clock_domain::create("marker", this);
            fw_clock_domain::set(this, clk);
            e = ext::create("e", this);
        endfunction
    endclass

endpackage
