// FW-E-XING-DRIVE-TWICE (C5): two task writes of one crossing port sampled
// by the same edge. a is written twice at edge 3; b at edge 3 and again at
// 35, between edges 3 and 4, so both are sampled by edge 4. Each second
// write is ignored. c is written at edge 3 and at edge 4: sampled by edges
// 4 and 5, no error. u is written 1, then 0 at edge 3: the second restores
// the value from before the first, so it undoes it (no error); the third,
// 5, is then the edge's only task write of u.
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_proc.svh"

    class twice extends fw_component implements fw_run_if;
        `fw_component_utils(twice)
        fw_output #(bit [3:0]) a, b, c, u;
        virtual function void build();
            a = fw_output #(bit [3:0])::create("a", this);
            b = fw_output #(bit [3:0])::create("b", this);
            c = fw_output #(bit [3:0])::create("c", this);
            u = fw_output #(bit [3:0])::create("u", this);
        endfunction
        virtual task run();
            fw_reset_domain::wait_reset_done(this);   // edge 3
            a.write(1);
            a.write(2);
            b.write(1);
            c.write(1);
            u.write(1);
            u.write(0);                               // undoes 1
            u.write(5);
            fw_time::delay(5ns);                      // 35
            b.write(2);
            fw_clock_domain::tick(this);              // edge 4
            c.write(2);
        endtask
    endclass

    class top extends test_proc_top;
        `fw_component_utils(top)
        twice t;
        virtual function void build();
            super.build();
            t = twice::create("t", this);
        endfunction
    endclass

endpackage
