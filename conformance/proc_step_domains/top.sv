// FW-E-STEP-DOMAINS: one step() writes outputs in two clock domains.
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_proc.svh"

    class both extends fw_component implements fw_step_if;
        `fw_component_utils(both)
        fw_output #(bit) o0, o1;
        virtual function void build();
            o0 = fw_output #(bit)::create("o0", this);
            o1 = fw_output #(bit)::create("o1", this);
            fw_clock_domain::set(o1, fw_clock_domain::get(this, "b"));
        endfunction
        virtual function void step();
            o0.write(!o0.read());
            o1.write(!o1.read());
        endfunction
    endclass

    class top extends test_proc_top;
        `fw_component_utils(top)
        fw_clock_domain clk_b;
        both            x;
        virtual function void build();
            super.build();
            clk_b = fw_clock_domain::create("clk_b", this, fw_clock_kind::root(17ns));
            x = both::create("x", this);
            fw_clock_domain::set(x, clk_b, "b");
        endfunction
    endclass

endpackage
