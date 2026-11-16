// Domain objects: a root of each library kind, every derivation of each,
// and their netlist form. Unused domains are markers: no diagnostics.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    class top extends fw_component;
        `fw_component_utils(top)
        fw_clock_domain clk, alt, div2, x2, q90, gclk, mux;
        fw_reset_domain por, srst, comb, swr, sync_root;

        virtual function void build();
            clk  = fw_clock_domain::create("clk", this);
            alt  = fw_clock_domain::create("alt", this, fw_clock_kind::root());
            div2 = fw_clock_domain::create("div2", this, fw_clock_kind::derived(clk, .div(2)));
            x2   = fw_clock_domain::create("x2", this, fw_clock_kind::derived(clk, .mul(2)));
            q90  = fw_clock_domain::create("q90", this, fw_clock_kind::phase(clk, 90));
            gclk = fw_clock_domain::create("gclk", this, fw_clock_kind::gated(div2));
            mux  = fw_clock_domain::create("mux", this, fw_clock_kind::muxed('{clk, alt}));
            por  = fw_reset_domain::create("por", this);
            srst = fw_reset_domain::create("srst", this, fw_reset_kind::synced(por, .clock(clk)));
            comb = fw_reset_domain::create("comb", this,
                       fw_reset_kind::combined('{por, srst}, .style(fw_reset_kind::SYNC), .clock(clk)));
            swr  = fw_reset_domain::create("swr", this, fw_reset_kind::software(srst, .clock(clk)));
            sync_root = fw_reset_domain::create("sync_root", this,
                       fw_reset_kind::root(fw_reset_kind::SYNC, alt));
        endfunction
    endclass

endpackage
