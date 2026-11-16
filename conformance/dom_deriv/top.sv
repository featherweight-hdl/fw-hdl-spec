// FW-E-DOM-DERIV: a divide-by-2 wrapper states the derivation it produces,
// but its parent sets its output to a clock divided by 4.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    class div2 extends fw_component implements fw_extern_if;
        `fw_extern_utils(div2, "clk_div2")
        virtual function void build();
            fw_clock_domain::provides(this, "out",
                fw_clock_kind::derived(fw_clock_domain::get(this), .div(2)));
        endfunction
        virtual function void extern_map(fw_extern_map m);
            fw_clock_domain::pin(m, "clk_i");
            fw_clock_domain::pin_out(m, "clk_o", fw_clock_domain::get(this, "out"));
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_input #(bit) clk_i;
        fw_clock_domain clk, slow;
        div2            u;
        virtual function void build();
            clk_i = fw_input #(bit)::create("clk_i", this);
            clk   = fw_clock_domain::create("clk", this);
            slow  = fw_clock_domain::create("slow", this, fw_clock_kind::derived(clk, .div(4)));
            fw_clock_domain::set(this, clk);
            u = div2::create("u", this);
            fw_clock_domain::set(u, slow, "out");
        endfunction
        virtual function void connect();
            clk.drive(clk_i);
        endfunction
    endclass

endpackage
