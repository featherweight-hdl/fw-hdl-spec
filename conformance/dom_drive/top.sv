// Drivers: the top drives its root clock and reset from its input ports,
// the reset active low; a derived clock is driven by a child's output port.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    class gen extends fw_component;
        `fw_component_utils(gen)
        fw_output #(bit) o;
        virtual function void build();
            o = fw_output #(bit)::create("o", this);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_input #(bit) clk_i, rst_ni;
        fw_clock_domain clk, d2;
        fw_reset_domain rst;
        gen             g;
        virtual function void build();
            clk_i  = fw_input #(bit)::create("clk_i", this);
            rst_ni = fw_input #(bit)::create("rst_ni", this);
            clk    = fw_clock_domain::create("clk", this);
            d2     = fw_clock_domain::create("d2", this, fw_clock_kind::derived(clk, .div(2)));
            rst    = fw_reset_domain::create("rst", this, fw_reset_kind::root(.clock(clk)));
            g      = gen::create("g", this);
        endfunction
        virtual function void connect();
            clk.drive(clk_i);
            rst.drive(rst_ni, fw_reset_kind::active_low());
            d2.drive(g.o);
        endfunction
    endclass

endpackage
