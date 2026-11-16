// FW-E-DOM-KIND: a clock derived from a reset domain, and a reset whose
// clock is a reset domain.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    class top extends fw_component;
        `fw_component_utils(top)
        fw_clock_domain clk, bad_clk;
        fw_reset_domain por, bad_rst;

        virtual function void build();
            clk     = fw_clock_domain::create("clk", this);
            por     = fw_reset_domain::create("por", this);
            bad_clk = fw_clock_domain::create("bad_clk", this, fw_clock_kind::derived(por));
            bad_rst = fw_reset_domain::create("bad_rst", this, fw_reset_kind::synced(por, .clock(por)));
        endfunction
    endclass

endpackage
