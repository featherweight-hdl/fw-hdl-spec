// fw_time in run(): a delay of 25 off the root clock's period of 10; a write
// at 25 is committed at the edge at 30; tick() then returns at 30.
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_proc.svh"

    class timed extends fw_component implements fw_run_if;
        `fw_component_utils(timed)
        fw_output #(bit)  flag;
        fw_output #(time) t0, t1;
        virtual function void build();
            flag = fw_output #(bit)::create("flag", this);
            t0   = fw_output #(time)::create("t0", this);
            t1   = fw_output #(time)::create("t1", this);
        endfunction
        virtual task run();
            fw_time::delay(25ns);
            flag.write(1);
            t0.write(fw_time::now());
            fw_clock_domain::tick(this);
            t1.write(fw_time::now());
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
