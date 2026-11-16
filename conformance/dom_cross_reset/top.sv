// Reset crossings: related resets (warning) and unrelated resets (error),
// all on one clock.
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
        fw_clock_domain clk;
        fw_reset_domain r0, r1, r2;
        src             a0, a1;
        snk             b0, b1;
        virtual function void build();
            clk = fw_clock_domain::create("clk", this);
            r0  = fw_reset_domain::create("r0", this);
            r1  = fw_reset_domain::create("r1", this, fw_reset_kind::synced(r0, clk));
            r2  = fw_reset_domain::create("r2", this);
            fw_clock_domain::set(this, clk);
            fw_reset_domain::set(this, r0);
            a0 = src::create("a0", this);
            a1 = src::create("a1", this);
            b0 = snk::create("b0", this);
            b1 = snk::create("b1", this);
            fw_reset_domain::set(b0, r1);
            fw_reset_domain::set(b1, r2);
        endfunction
        virtual function void connect();
            b0.i.connect(a0.o);
            b1.i.connect(a1.o);
        endfunction
    endclass

endpackage
