// FW-E-EXT-PIN: a domain pin with the name of a tied pin.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    class ext extends fw_component implements fw_extern_if;
        `fw_extern_utils(ext, "ext_mod")
        virtual function void extern_map(fw_extern_map m);
            m.tie("clk", 0);
            fw_clock_domain::pin(m, "clk");
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_input #(bit) clk_i;
        fw_clock_domain clk;
        ext             e;
        virtual function void build();
            clk_i = fw_input #(bit)::create("clk_i", this);
            clk   = fw_clock_domain::create("clk", this);
            fw_clock_domain::set(this, clk);
            e = ext::create("e", this);
        endfunction
        virtual function void connect();
            clk.drive(clk_i);
        endfunction
    endclass

endpackage
