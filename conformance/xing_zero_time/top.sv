// C7: task code resumed by other task code in the same time step is at the
// same edge. At edge 4, src calls dst.put() through a port; put() writes
// x and reads m, and hands the item through a mailbox to dst's own run(),
// which resumes in the same time step and writes z and w. All four are at
// edge 4: reads return the values from before edge 4, and the writes are
// sampled by edge 5.
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;
    `include "test_proc.svh"
    `include "test_apis.svh"

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
            fw_reset_domain::wait_reset_done(this);   // edge 3
            fw_clock_domain::tick(this);              // edge 4
            i.put(8'd7);
        endtask
    endclass

    class dst extends fw_component implements fw_run_if, test_put_if #(bit [7:0]);
        `fw_component_utils(dst)
        fw_export #(test_put_if #(bit [7:0])) e;
        fw_input  #(bit [7:0]) m;
        fw_output #(bit [7:0]) x, y, z, w;
        mailbox #(bit [7:0])   mb = new();
        virtual function void build();
            e = fw_export #(test_put_if #(bit [7:0]))::create("e", this);
            m = fw_input  #(bit [7:0])::create("m", this);
            x = fw_output #(bit [7:0])::create("x", this);
            y = fw_output #(bit [7:0])::create("y", this);
            z = fw_output #(bit [7:0])::create("z", this);
            w = fw_output #(bit [7:0])::create("w", this);
        endfunction
        virtual task put(bit [7:0] t);
            x.write(t);
            y.write(m.read());
            mb.put(t);
        endtask
        virtual task run();
            bit [7:0] t;
            mb.get(t);
            z.write(t + 8'd1);
            w.write(m.read());
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
            d.m.connect(c.m);
        endfunction
    endclass

endpackage
