// Task-sync crossings used from their sides (X1-X6): a run() puts 1, 2, 3
// to a child's fw_to_sync and gets each answer from its fw_from_sync; the
// child's comb() shows the head item, and its step() takes an item and
// gives back item + 100 in the same edge. The run() records each answer
// through a recorder (_lib/test_rec.svh), one edge after it gets it.
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;
    `include "test_proc.svh"
    `include "test_rec.svh"

    // Owns the crossings: its sync side.
    class xc extends fw_component implements fw_step_if;
        `fw_component_utils(xc)
        fw_to_sync #(bit [7:0])   reqs;
        fw_from_sync #(bit [7:0]) rsps;
        fw_output #(bit)       v;
        fw_output #(bit [7:0]) d;
        virtual function void build();
            reqs = fw_to_sync #(bit [7:0])::create("reqs", this);
            rsps = fw_from_sync #(bit [7:0])::create("rsps", this);
            v    = fw_output #(bit)::create("v", this);
            d    = fw_output #(bit [7:0])::create("d", this);
        endfunction
        `fw_comb(look)
        function void look();
            v.write(reqs.valid());
            d.write(reqs.peek());
        endfunction
        virtual function void step();
            bit [7:0] t;
            if (rsps.ready() && reqs.take(t))
                void'(rsps.give(t + 8'd100));
        endfunction
    endclass

    // Task code: the process side of its child's crossings.
    class drv extends fw_component implements fw_run_if;
        `fw_component_utils(drv)
        xc x;
        test_rec #(bit [7:0]) got;
        virtual function void build();
            x   = xc::create("x", this);
            got = test_rec #(bit [7:0])::create("got", this);
        endfunction
        virtual task run();
            bit [7:0] r;
            for (int i = 1; i <= 3; i++) begin
                x.reqs.put(8'(i));
                x.rsps.get(r);
                got.put(r);
            end
        endtask
    endclass

    class top extends test_proc_top;
        `fw_component_utils(top)
        drv dr;
        virtual function void build();
            super.build();
            dr = drv::create("dr", this);
        endfunction
    endclass

endpackage
