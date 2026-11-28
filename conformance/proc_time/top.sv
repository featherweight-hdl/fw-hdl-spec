// fw_time in run(): run() starts at 30, after reset (processes.md, R1); a
// delay of 25 off the root clock's period of 10 ends at 55; tick() from 55
// returns at 60. run() records through recorders (_lib/test_rec.svh): what
// it puts at 55 is taken at the edge at 60, what it puts at 60 at the edge
// at 70.
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_proc.svh"
    `include "test_rec.svh"

    class timed extends fw_component implements fw_run_if;
        `fw_component_utils(timed)
        test_rec #(bit)  flag;
        test_rec #(time) t0, t1;
        virtual function void build();
            flag = test_rec #(bit)::create("flag", this);
            t0   = test_rec #(time)::create("t0", this);
            t1   = test_rec #(time)::create("t1", this);
        endfunction
        virtual task run();
            fw_time::delay(25ns);
            flag.put(1);
            t0.put(fw_time::now());
            fw_clock_domain::tick(this);
            t1.put(fw_time::now());
        endtask
    endclass

    class top extends test_proc_top;
        `fw_component_utils(top)
        timed d;
        virtual function void build();
            super.build();
            d = timed::create("d", this);
        endfunction
    endclass

endpackage
