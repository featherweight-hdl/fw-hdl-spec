// FW-E-TASK-SIGNAL: task code neither reads nor writes signals
// (processes.md, "Task code"). w's run() writes its output o; r's export
// task put(), called from w's run(), reads its input i. Each is reported
// on the component whose code makes the access.
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;
    `include "test_proc.svh"
    `include "test_apis.svh"

    class w_c extends fw_component implements fw_run_if;
        `fw_component_utils(w_c)
        fw_output #(bit [7:0]) o;
        fw_port #(test_put_if #(bit [7:0])) p;
        virtual function void build();
            o = fw_output #(bit [7:0])::create("o", this);
            p = fw_port #(test_put_if #(bit [7:0]))::create("p", this);
        endfunction
        virtual task run();
            test_put_if #(bit [7:0]) i = p.get_if();
            // run() starts at edge 3, after reset (processes.md, R1)
            o.write(8'd5);
            i.put(8'd7);
        endtask
    endclass

    class r_c extends fw_component implements test_put_if #(bit [7:0]);
        `fw_component_utils(r_c)
        fw_input #(bit [7:0]) i;
        fw_export #(test_put_if #(bit [7:0])) e;
        bit [7:0] last;
        virtual function void build();
            i = fw_input #(bit [7:0])::create("i", this);
            e = fw_export #(test_put_if #(bit [7:0]))::create("e", this);
        endfunction
        virtual task put(bit [7:0] t);
            last = t + i.read();
        endtask
    endclass

    class top extends test_proc_top;
        `fw_component_utils(top)
        w_c w;
        r_c r;
        virtual function void build();
            super.build();
            w = w_c::create("w", this);
            r = r_c::create("r", this);
        endfunction
        virtual function void connect();
            super.connect();
            w.o.connect(r.i);
            w.p.connect(r.e);
        endfunction
    endclass

endpackage
