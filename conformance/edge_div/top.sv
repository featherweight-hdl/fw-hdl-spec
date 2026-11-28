// Edges of a derived domain (processes.md, Edges and The edge). clk2 is clk
// divided by 2: its edge j is clk's edge 2j (20, 40, ...), fixed from time
// 0. Each tkr's run() starts at 30, after reset (processes.md, R1: clk's
// edge 3, between clk2's edges 1 and 2). t1 ticks clk2 from 30 and returns
// at clk2's next edge, 40, not 2 clk edges after the call; t2 ticks from
// 40, at clk2's edge 2, and returns at its edge 3, 60.
// clk and clk2 edge together at 20, 40, ...: one group, so h, a step block
// in clk2, reads clk's register n as it was before the shared edge. Each
// tkr records the time through a recorder (_lib/test_rec.svh), taken at
// clk2's edge after the tick: 60 and 80.
// h.n reading c.n is a crossing of related domains: FW-I-DOM-CROSS.
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_proc.svh"
    `include "test_rec.svh"

    // In clk: n counts clk's edges (reads k - 1 at clk's edge k).
    class cnt extends fw_component implements fw_step_if;
        `fw_component_utils(cnt)
        fw_output #(bit [7:0]) n;
        virtual function void build();
            n = fw_output #(bit [7:0])::create("n", this);
        endfunction
        virtual function void step();
            n.write(n.read() + 8'd1);
        endfunction
    endclass

    // In clk2: s registers n.
    class half extends fw_component implements fw_step_if;
        `fw_component_utils(half)
        fw_input  #(bit [7:0]) n;
        fw_output #(bit [7:0]) s;
        virtual function void build();
            n = fw_input  #(bit [7:0])::create("n", this);
            s = fw_output #(bit [7:0])::create("s", this);
        endfunction
        virtual function void step();
            s.write(n.read());
        endfunction
    endclass

    // In clk2: after a delay of d, ticks once and records the time in a.
    class tkr extends fw_component implements fw_run_if;
        `fw_component_utils(tkr)
        test_rec #(time) a;
        time d;
        virtual function void build();
            a = test_rec #(time)::create("a", this);
        endfunction
        virtual task run();
            if (d != 0)
                fw_time::delay(d);
            fw_clock_domain::tick(this);
            a.put(fw_time::now());
        endtask
    endclass

    class top extends test_proc_top;
        `fw_component_utils(top)
        fw_clock_domain clk2;
        cnt  c;
        half h;
        tkr  t1, t2;
        virtual function void build();
            super.build();
            clk2 = fw_clock_domain::create("clk2", this,
                                           fw_clock_kind::derived(clk, .div(2)));
            c  = cnt::create("c", this);
            h  = half::create("h", this);
            t1 = tkr::create("t1", this);
            t2 = tkr::create("t2", this);
            t2.d = 10ns;
            fw_clock_domain::set(h, clk2);
            fw_clock_domain::set(t1, clk2);
            fw_clock_domain::set(t2, clk2);
        endfunction
        virtual function void connect();
            super.connect();
            h.n.connect(c.n);
        endfunction
    endclass

endpackage
