// T2: run() starts at edge 3 (30), after reset (processes.md, R1). A
// delay that ends at the time of a generated edge (50, edge 5) resumes
// after that edge's release, so the run() is at edge 5 whatever the order
// of processes: what it puts to a recorder (_lib/test_rec.svh) then is
// taken at edge 6, not 5. A delay to 55 leaves it between edges 5 and 6: a
// put is taken at edge 6 too. tick() from there returns at edge 6, and a
// put then is taken at edge 7. Each shows from the row after the edge that
// takes it.
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_proc.svh"
    `include "test_rec.svh"

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
        test_rec #(time) a, b, t;
        virtual function void build();
            a = test_rec #(time)::create("a", this);
            b = test_rec #(time)::create("b", this);
            t = test_rec #(time)::create("t", this);
        endfunction
        virtual task run();
            fw_time::delay(20ns);           // from 30 (edge 3) to edge 5
            a.put(fw_time::now());          // taken at edge 6
            fw_time::delay(5ns);            // 55: between edges 5 and 6
            b.put(fw_time::now());          // taken at edge 6
            fw_clock_domain::tick(this);    // edge 6
            t.put(fw_time::now());          // taken at edge 7
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
    endclass

endpackage
