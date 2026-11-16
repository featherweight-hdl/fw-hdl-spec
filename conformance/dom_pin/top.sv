// Extern domain pins: the default clock, a named clock and an active-low
// reset expecting an asynchronous reset, next to an ordinary port mapped by
// the default rule.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    class dc extends fw_component implements fw_extern_if;
        `fw_extern_utils(dc, "dc_mod")
        fw_input #(bit) d;
        virtual function void build();
            d = fw_input #(bit)::create("d", this);
        endfunction
        virtual function void extern_map(fw_extern_map m);
            fw_clock_domain::pin(m, "clk");
            fw_clock_domain::pin(m, "wr_clk", fw_clock_domain::get(this, "wr"));
            fw_reset_domain::pin(m, "rst_n", null,
                                 fw_reset_kind::active_low(fw_reset_kind::ASYNC));
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_input #(bit) clk_i, wclk_i, rst_i;
        fw_clock_domain clk, wclk;
        fw_reset_domain rst;
        dc              e;
        virtual function void build();
            clk_i  = fw_input #(bit)::create("clk_i", this);
            wclk_i = fw_input #(bit)::create("wclk_i", this);
            rst_i  = fw_input #(bit)::create("rst_i", this);
            clk    = fw_clock_domain::create("clk", this);
            wclk   = fw_clock_domain::create("wclk", this);
            rst    = fw_reset_domain::create("rst", this, fw_reset_kind::root(.clock(clk)));
            fw_clock_domain::set(this, clk);
            fw_reset_domain::set(this, rst);
            e = dc::create("e", this);
            fw_clock_domain::set(e, wclk, "wr");
        endfunction
        virtual function void connect();
            clk.drive(clk_i);
            wclk.drive(wclk_i);
            rst.drive(rst_i);
            e.d.tie(0);
        endfunction
    endclass

endpackage
