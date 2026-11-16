// Header checks on domain pins: an input domain pin on an output, a domain
// pin on a 2-bit input, a domain pin the module lacks, an output domain pin
// on an input.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    class e_dir extends fw_component implements fw_extern_if;
        `fw_extern_utils(e_dir, "m_dir")
        virtual function void extern_map(fw_extern_map m);
            fw_clock_domain::pin(m, "clk");
        endfunction
    endclass

    class e_width extends fw_component implements fw_extern_if;
        `fw_extern_utils(e_width, "m_width")
        virtual function void extern_map(fw_extern_map m);
            fw_clock_domain::pin(m, "clk");
        endfunction
    endclass

    class e_missing extends fw_component implements fw_extern_if;
        `fw_extern_utils(e_missing, "m_missing")
        virtual function void extern_map(fw_extern_map m);
            fw_clock_domain::pin(m, "clk");
            fw_clock_domain::pin(m, "nope");
        endfunction
    endclass

    class e_out extends fw_component implements fw_extern_if;
        `fw_extern_utils(e_out, "m_out")
        virtual function void extern_map(fw_extern_map m);
            fw_clock_domain::pin(m, "clk");
            fw_clock_domain::pin_out(m, "clk_o", fw_clock_domain::get(this, "out"));
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_input #(bit) clk_i;
        fw_clock_domain clk, d4;
        e_dir           e1;
        e_width         e2;
        e_missing       e3;
        e_out           e4;
        virtual function void build();
            clk_i = fw_input #(bit)::create("clk_i", this);
            clk   = fw_clock_domain::create("clk", this);
            d4    = fw_clock_domain::create("d4", this, fw_clock_kind::derived(clk, .div(4)));
            fw_clock_domain::set(this, clk);
            e1 = e_dir::create("e1", this);
            e2 = e_width::create("e2", this);
            e3 = e_missing::create("e3", this);
            e4 = e_out::create("e4", this);
            fw_clock_domain::set(e4, d4, "out");
        endfunction
        virtual function void connect();
            clk.drive(clk_i);
        endfunction
    endclass

endpackage
