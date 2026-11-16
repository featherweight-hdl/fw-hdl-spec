// A divide-by-2 wrapper drives its parent's derived clock through an output
// pin, and states the derivation it produces (provides), which matches. A
// second extern runs on the divided clock.
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

    class sink extends fw_component implements fw_extern_if;
        `fw_extern_utils(sink, "sink_mod")
        virtual function void extern_map(fw_extern_map m);
            fw_clock_domain::pin(m, "clk");
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_input #(bit) clk_i;
        fw_clock_domain clk, slow;
        div2            u;
        sink            e;
        virtual function void build();
            clk_i = fw_input #(bit)::create("clk_i", this);
            clk   = fw_clock_domain::create("clk", this);
            slow  = fw_clock_domain::create("slow", this, fw_clock_kind::derived(clk, .div(2)));
            fw_clock_domain::set(this, clk);
            u = div2::create("u", this);
            fw_clock_domain::set(u, slow, "out");
            e = sink::create("e", this);
            fw_clock_domain::set(e, slow);
        endfunction
        virtual function void connect();
            clk.drive(clk_i);
        endfunction
    endclass

endpackage
