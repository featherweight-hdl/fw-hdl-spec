// FW-E-XING-SIDE (X1), on the crossing: the process side used from sync
// code (x.a: try_put in x's step), the sync side used by sync code of a
// component that is not the owner (x.b: valid in p's step), and the sync
// side used from task code (x.c: ready in p's run()).
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;
    `include "test_proc.svh"

    class xc extends fw_component implements fw_step_if;
        `fw_component_utils(xc)
        fw_to_sync #(bit [7:0])   a, b;
        fw_from_sync #(bit [7:0]) c;
        virtual function void build();
            a = fw_to_sync #(bit [7:0])::create("a", this);
            b = fw_to_sync #(bit [7:0])::create("b", this);
            c = fw_from_sync #(bit [7:0])::create("c", this);
        endfunction
        virtual function void step();
            void'(a.try_put(8'd1));
        endfunction
    endclass

    class par extends fw_component implements fw_step_if, fw_run_if;
        `fw_component_utils(par)
        xc x;
        fw_output #(bit) v, r;
        virtual function void build();
            x = xc::create("x", this);
            v = fw_output #(bit)::create("v", this);
            r = fw_output #(bit)::create("r", this);
        endfunction
        virtual function void step();
            v.write(x.b.valid());
        endfunction
        virtual task run();
            r.write(x.c.ready());
        endtask
    endclass

    class top extends test_proc_top;
        `fw_component_utils(top)
        par p;
        virtual function void build();
            super.build();
            p = par::create("p", this);
        endfunction
    endclass

endpackage
