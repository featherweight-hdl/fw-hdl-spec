// Crossing ports (processes.md, Crossings): a run() reads and writes signals
// at the edges it ticks to. At edge k a read returns the value from before
// k (C2), even of a port it has just written; a write is seen by comb logic
// at once and by step blocks from edge k + 1 (C3). Several ports at one
// edge (C6).
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_proc.svh"

    // n counts edges (reads k - 1 at edge k); got registers d.
    class cnt extends fw_component implements fw_step_if;
        `fw_component_utils(cnt)
        fw_input  #(bit [7:0]) d;
        fw_output #(bit [7:0]) n, got;
        virtual function void build();
            d   = fw_input  #(bit [7:0])::create("d", this);
            n   = fw_output #(bit [7:0])::create("n", this);
            got = fw_output #(bit [7:0])::create("got", this);
        endfunction
        virtual function void step();
            n.write(n.read() + 8'd1);
            got.write(d.read());
        endfunction
    endclass

    // e = 2 * a, a wire.
    class dbl extends fw_component implements fw_comb_if;
        `fw_component_utils(dbl)
        fw_input  #(bit [7:0]) a;
        fw_output #(bit [7:0]) e;
        virtual function void build();
            a = fw_input  #(bit [7:0])::create("a", this);
            e = fw_output #(bit [7:0])::create("e", this);
        endfunction
        virtual function void comb();
            e.write(a.read() << 1);
        endfunction
    endclass

    // At edges 3, 4 and 5: records n, drives d = n + 100, then reads d back.
    class tsk extends fw_component implements fw_run_if;
        `fw_component_utils(tsk)
        fw_input  #(bit [7:0]) n;
        fw_output #(bit [7:0]) d, seen, back;
        virtual function void build();
            n    = fw_input  #(bit [7:0])::create("n", this);
            d    = fw_output #(bit [7:0])::create("d", this);
            seen = fw_output #(bit [7:0])::create("seen", this);
            back = fw_output #(bit [7:0])::create("back", this);
        endfunction
        virtual task run();
            fw_reset_domain::wait_reset_done(this);
            repeat (3) begin
                seen.write(n.read());
                d.write(n.read() + 8'd100);
                back.write(d.read());
                fw_clock_domain::tick(this);
            end
        endtask
    endclass

    class top extends test_proc_top;
        `fw_component_utils(top)
        cnt c;
        dbl g;
        tsk t;
        virtual function void build();
            super.build();
            c = cnt::create("c", this);
            g = dbl::create("g", this);
            t = tsk::create("t", this);
        endfunction
        virtual function void connect();
            super.connect();
            c.d.connect(t.d);
            g.a.connect(t.d);
            t.n.connect(c.n);
        endfunction
    endclass

endpackage
