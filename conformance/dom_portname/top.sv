// FW-E-DOM-PORTNAME: a class whose subtree realizes its default clock gets
// a generated input port clk, which collides with a port it declares.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    class ext extends fw_component implements fw_extern_if;
        `fw_extern_utils(ext, "ext_mod")
        virtual function void extern_map(fw_extern_map m);
            fw_clock_domain::pin(m, "clk");
        endfunction
    endclass

    class blk extends fw_component;
        `fw_component_utils(blk)
        fw_input #(bit) clk;
        ext             e;
        virtual function void build();
            clk = fw_input #(bit)::create("clk", this);
            e   = ext::create("e", this);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_input #(bit) clk_i, x;
        fw_clock_domain clk;
        blk             u;
        virtual function void build();
            clk_i = fw_input #(bit)::create("clk_i", this);
            x     = fw_input #(bit)::create("x", this);
            clk   = fw_clock_domain::create("clk", this);
            fw_clock_domain::set(this, clk);
            u = blk::create("u", this);
        endfunction
        virtual function void connect();
            clk.drive(clk_i);
            u.clk.connect(x);
        endfunction
    endclass

endpackage
