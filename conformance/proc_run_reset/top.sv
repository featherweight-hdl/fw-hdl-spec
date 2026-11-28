// run() follows its reset (processes.md, Reset, R1-R3). w is in reset rst2,
// which test_rst_pulse pg asserts at edges 1-2 and 6-7. w's run() starts at
// edge 3 (R1), forks a thread that records the time every 2 edges, and
// waits 4 edges. At edge 6 the reset asserts: run() and the forked thread
// are killed mid-wait (R2), so the main thread's record due at edge 7 and
// the fork's at edge 7 never happen. At edge 8 run() starts again from the
// top (R3); the field n keeps its value, so it counts the starts. The
// recorders (_lib/test_rec.svh) are the top's, in rst, which is deasserted
// from edge 3 on.
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_proc.svh"
    `include "test_rec.svh"

    class wkr extends fw_component implements fw_run_if;
        `fw_component_utils(wkr)
        test_rec #(time)      st, f, m;     // the top's recorders
        test_rec #(bit [7:0]) ns;
        bit [7:0] n;                        // starts so far
        virtual task run();
            n++;
            st.put(fw_time::now());
            ns.put(n);
            fork
                forever begin
                    fw_clock_domain::tick(this, 2);
                    f.put(fw_time::now());
                end
            join_none
            fw_clock_domain::tick(this, 4);
            m.put(fw_time::now());
        endtask
    endclass

    class top extends test_proc_top;
        `fw_component_utils(top)
        fw_reset_domain       rst2;
        test_rst_pulse        pg;
        wkr                   w;
        test_rec #(time)      st, f, m;
        test_rec #(bit [7:0]) ns;
        virtual function void build();
            super.build();
            rst2 = fw_reset_domain::create("rst2", this,
                                           fw_reset_kind::root(fw_reset_kind::SYNC, clk));
            pg = test_rst_pulse::create("pg", this);
            w  = wkr::create("w", this);
            st = test_rec #(time)::create("st", this);
            f  = test_rec #(time)::create("f", this);
            m  = test_rec #(time)::create("m", this);
            ns = test_rec #(bit [7:0])::create("ns", this);
            fw_reset_domain::set(w, rst2);
        endfunction
        virtual function void connect();
            super.connect();
            rst2.drive(pg.rst_n, fw_reset_kind::active_low());
            w.st = st;
            w.f  = f;
            w.m  = m;
            w.ns = ns;
        endfunction
    endclass

endpackage
