// FW-E-XING-RESET (X9), on the crossing. t owns crossings x and y and is in
// reset rst2, which test_rst_pulse pg asserts at edges 1-2 and 6-7; c is in
// the top's reset rst, deasserted from edge 3 on. c's run() forks a thread
// that gets from y at edge 3: it is blocked when rst2 asserts at edge 6, so
// it returns then (the crossing is emptied, X8) and records 60. c's run()
// puts 1 to x at edge 6, with rst2 asserted: the call returns at once and
// its item is dropped, recorded at 60. At edge 8, with rst2 deasserted, it
// puts 2: t's step takes it at edge 9, and got shows it from row 10.
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_proc.svh"
    `include "test_rec.svh"

    // Takes from x into got; never gives to y.
    class tgt extends fw_component implements fw_step_if;
        `fw_component_utils(tgt)
        fw_to_sync #(bit [7:0])   x;
        fw_from_sync #(bit [7:0]) y;
        fw_output #(bit [7:0])    got;
        virtual function void build();
            x   = fw_to_sync #(bit [7:0])::create("x", this);
            y   = fw_from_sync #(bit [7:0])::create("y", this);
            got = fw_output #(bit [7:0])::create("got", this);
        endfunction
        virtual function void step();
            bit [7:0] v;
            if (x.take(v))
                got.write(v);
        endfunction
    endclass

    class clr extends fw_component implements fw_run_if;
        `fw_component_utils(clr)
        tgt              t;
        test_rec #(time) g, p;
        virtual function void build();
            g = test_rec #(time)::create("g", this);
            p = test_rec #(time)::create("p", this);
        endfunction
        virtual task run();
            fork
                begin
                    bit [7:0] v;
                    t.y.get(v);                     // edge 3; returns at edge 6
                    g.put(fw_time::now());
                end
            join_none
            fw_clock_domain::tick(this, 3);         // edge 6
            t.x.put(8'd1);                          // rst2 asserted: returns
            p.put(fw_time::now());
            fw_clock_domain::tick(this, 2);         // edge 8
            t.x.put(8'd2);                          // taken at edge 9
        endtask
    endclass

    class top extends test_proc_top;
        `fw_component_utils(top)
        fw_reset_domain rst2;
        test_rst_pulse  pg;
        tgt             t;
        clr             c;
        virtual function void build();
            super.build();
            rst2 = fw_reset_domain::create("rst2", this,
                                           fw_reset_kind::root(fw_reset_kind::SYNC, clk));
            pg = test_rst_pulse::create("pg", this);
            t  = tgt::create("t", this);
            c  = clr::create("c", this);
            fw_reset_domain::set(t, rst2);
        endfunction
        virtual function void connect();
            super.connect();
            rst2.drive(pg.rst_n, fw_reset_kind::active_low());
            c.t = t;
        endfunction
    endclass

endpackage
