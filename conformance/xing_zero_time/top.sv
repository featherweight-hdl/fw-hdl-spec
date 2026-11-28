// T3: task code resumed by other task code in the same time step is at the
// same edge. At edge 4, src calls dst.put() through a port; put() records
// the item in x and hands it through a mailbox to dst's own run(), which
// resumes in the same time step and records item + 1 in z. Both puts are at
// edge 4: the recorders (_lib/test_rec.svh) take them at edge 5, so both
// show from row 6.
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;
    `include "test_proc.svh"
    `include "test_apis.svh"
    `include "test_rec.svh"

    // m counts edges: it reads k - 1 at edge k.
    class cnt extends fw_component implements fw_step_if;
        `fw_component_utils(cnt)
        fw_output #(bit [7:0]) m;
        virtual function void build();
            m = fw_output #(bit [7:0])::create("m", this);
        endfunction
        virtual function void step();
            m.write(m.read() + 8'd1);
        endfunction
    endclass

    class src extends fw_component implements fw_run_if;
        `fw_component_utils(src)
        fw_port #(test_put_if #(bit [7:0])) p;
        virtual function void build();
            p = fw_port #(test_put_if #(bit [7:0]))::create("p", this);
        endfunction
        virtual task run();
            test_put_if #(bit [7:0]) i = p.get_if();
            // run() starts at edge 3, after reset (processes.md, R1)
            fw_clock_domain::tick(this);              // edge 4
            i.put(8'd7);
        endtask
    endclass

    class dst extends fw_component implements fw_run_if, test_put_if #(bit [7:0]);
        `fw_component_utils(dst)
        fw_export #(test_put_if #(bit [7:0])) e;
        test_rec #(bit [7:0])  x, z;
        mailbox #(bit [7:0])   mb = new();
        virtual function void build();
            e = fw_export #(test_put_if #(bit [7:0]))::create("e", this);
            x = test_rec #(bit [7:0])::create("x", this);
            z = test_rec #(bit [7:0])::create("z", this);
        endfunction
        virtual task put(bit [7:0] t);
            x.put(t);
            mb.put(t);
        endtask
        virtual task run();
            bit [7:0] t;
            mb.get(t);
            z.put(t + 8'd1);
        endtask
    endclass

    class top extends test_proc_top;
        `fw_component_utils(top)
        cnt c;
        src s;
        dst d;
        virtual function void build();
            super.build();
            c = cnt::create("c", this);
            s = src::create("s", this);
            d = dst::create("d", this);
        endfunction
        virtual function void connect();
            super.connect();
            s.p.connect(d.e);
        endfunction
    endclass

endpackage
