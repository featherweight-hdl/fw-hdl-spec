// FW-E-RUN-SYNC-ACCESS: task code may touch its own component's signals and
// its direct children's ports. top's run() writes its child c's input i
// (allowed) and its grandchild c.g's output o (not allowed).
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_proc.svh"

    class leaf extends fw_component;
        `fw_component_utils(leaf)
        fw_output #(bit) o;
        virtual function void build();
            o = fw_output #(bit)::create("o", this);
        endfunction
    endclass

    class mid extends fw_component;
        `fw_component_utils(mid)
        fw_input #(bit) i;
        leaf g;
        virtual function void build();
            i = fw_input #(bit)::create("i", this);
            g = leaf::create("g", this);
        endfunction
    endclass

    class top extends test_proc_top implements fw_run_if;
        `fw_component_utils(top)
        mid c;
        virtual function void build();
            super.build();
            c = mid::create("c", this);
        endfunction
        virtual task run();
            fw_reset_domain::wait_reset_done(this);
            c.i.write(1);
            c.g.o.write(1);
        endtask
    endclass

endpackage
