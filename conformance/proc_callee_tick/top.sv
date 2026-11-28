// A domain operation is keyed by `this` of the code making it, not by the
// thread's component (processes.md, Domain operations). s's run() calls
// d.put() through a port at edge 3; put(), running on s's thread, waits 2
// edges of its own clock with tick(this) (no FW-E-DOM-OBJ) and records the
// time, 50, through its recorder (_lib/test_rec.svh): taken at edge 6,
// shown from row 7. s records when the call returns: also 50.
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_proc.svh"
    `include "test_apis.svh"
    `include "test_rec.svh"

    class src extends fw_component implements fw_run_if;
        `fw_component_utils(src)
        fw_port #(test_put_if #(bit [7:0])) p;
        test_rec #(time) r;
        virtual function void build();
            p = fw_port #(test_put_if #(bit [7:0]))::create("p", this);
            r = test_rec #(time)::create("r", this);
        endfunction
        virtual task run();
            test_put_if #(bit [7:0]) i = p.get_if();
            i.put(8'd7);                            // edge 3; returns at 5
            r.put(fw_time::now());
        endtask
    endclass

    class dst extends fw_component implements test_put_if #(bit [7:0]);
        `fw_component_utils(dst)
        fw_export #(test_put_if #(bit [7:0])) e;
        test_rec #(time) r;
        virtual function void build();
            e = fw_export #(test_put_if #(bit [7:0]))::create("e", this);
            r = test_rec #(time)::create("r", this);
        endfunction
        virtual task put(bit [7:0] t);
            fw_clock_domain::tick(this, 2);         // d's clock, on s's thread
            r.put(fw_time::now());
        endtask
    endclass

    class top extends test_proc_top;
        `fw_component_utils(top)
        src s;
        dst d;
        virtual function void build();
            super.build();
            s = src::create("s", this);
            d = dst::create("d", this);
        endfunction
        virtual function void connect();
            super.connect();
            s.p.connect(d.e);
        endfunction
    endclass

endpackage
