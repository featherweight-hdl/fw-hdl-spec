// FW-E-WRITE-MULTI with task code: o is written by a comb block and by
// run() of the same component (a task drive into comb logic is not a
// default). p, written by a step block and run() of the same component,
// is a default and a drive (C5): no error.
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_proc.svh"

    class both extends fw_component implements fw_comb_if, fw_step_if, fw_run_if;
        `fw_component_utils(both)
        fw_output #(bit) o, p;
        virtual function void build();
            o = fw_output #(bit)::create("o", this);
            p = fw_output #(bit)::create("p", this);
        endfunction
        virtual function void comb();
            o.write(p.read());
        endfunction
        virtual function void step();
            p.write(0);
        endfunction
        virtual task run();
            fw_reset_domain::wait_reset_done(this);
            o.write(1);
            p.write(1);
        endtask
    endclass

    class top extends test_proc_top;
        `fw_component_utils(top)
        both b;
        virtual function void build();
            super.build();
            b = both::create("b", this);
        endfunction
    endclass

endpackage
