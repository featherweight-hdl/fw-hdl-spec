// FW-E-DOM-PHASE: set and port_name in the connect phase; drive and waive
// in the build phase.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    // A leaf with one output.
    class src extends fw_component;
        `fw_component_utils(src)
        fw_output #(bit) o;
        virtual function void build();
            o = fw_output #(bit)::create("o", this);
        endfunction
    endclass

    // A leaf with one input.
    class snk extends fw_component;
        `fw_component_utils(snk)
        fw_input #(bit) i;
        virtual function void build();
            i = fw_input #(bit)::create("i", this);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_input #(bit) clk_i, d_i;
        fw_clock_domain clk;
        src             u0;
        snk             u1;
        virtual function void build();
            clk_i = fw_input #(bit)::create("clk_i", this);
            d_i   = fw_input #(bit)::create("d_i", this);
            clk   = fw_clock_domain::create("clk", this);
            u0    = src::create("u0", this);
            u1    = snk::create("u1", this);
            clk.drive(clk_i);
            // Children build after this, so waive names top's own ports.
            fw_clock_domain::waive(d_i, clk_i, "too early");
        endfunction
        virtual function void connect();
            u1.i.connect(u0.o);
            fw_clock_domain::set(u0, clk);
            fw_clock_domain::port_name(this, "", "ck");
        endfunction
    endclass

endpackage
