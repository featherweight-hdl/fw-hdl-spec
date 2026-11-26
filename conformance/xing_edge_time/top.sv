// C1 and C4: a delay that ends at the time of a generated edge (30, edge 3)
// resumes after that edge's release, so the run() is at edge 3 whatever
// the order of processes: its read of n returns the value from before edge
// 3, and its write is sampled by edge 4. A delay to 35 leaves it between
// edges: a read returns the current value, and a write is sampled by the
// next edge, 4. tick() from there returns at edge 4.
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_proc.svh"

    // n counts edges: it reads k - 1 at edge k.
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

    class timed extends fw_component implements fw_run_if;
        `fw_component_utils(timed)
        fw_input  #(bit [7:0]) n;
        fw_output #(bit [7:0]) a, r, b, q;
        fw_output #(time)      t;
        virtual function void build();
            n = fw_input  #(bit [7:0])::create("n", this);
            a = fw_output #(bit [7:0])::create("a", this);
            r = fw_output #(bit [7:0])::create("r", this);
            b = fw_output #(bit [7:0])::create("b", this);
            q = fw_output #(bit [7:0])::create("q", this);
            t = fw_output #(time)::create("t", this);
        endfunction
        virtual task run();
            fw_time::delay(30ns);           // edge 3
            a.write(1);
            r.write(n.read());              // before edge 3: 2
            fw_time::delay(5ns);            // 35: between edges 3 and 4
            b.write(1);
            q.write(n.read());              // now: 3
            fw_clock_domain::tick(this);    // edge 4
            t.write(fw_time::now());
        endtask
    endclass

    class top extends test_proc_top;
        `fw_component_utils(top)
        cnt   c;
        timed d;
        virtual function void build();
            super.build();
            c = cnt::create("c", this);
            d = timed::create("d", this);
        endfunction
        virtual function void connect();
            super.connect();
            d.n.connect(c.n);
        endfunction
    endclass

endpackage
