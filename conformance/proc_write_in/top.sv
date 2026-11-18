// FW-E-WRITE-IN: a write to an input port, and to a mirror's valid (an
// effective input). Each write is ignored.
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;
    `include "test_proc.svh"

    class bad extends fw_component implements fw_step_if;
        `fw_component_utils(bad)
        fw_input  #(bit) i;
        fw_mirror #(fw_rv_if #(bit [7:0])) in;
        virtual function void build();
            i  = fw_input  #(bit)::create("i", this);
            in = fw_mirror #(fw_rv_if #(bit [7:0]))::create("in", this);
        endfunction
        virtual function void step();
            i.write(1);
            in.valid.write(1);
            in.ready.write(1);
        endfunction
    endclass

    class top extends test_proc_top;
        `fw_component_utils(top)
        bad k;
        virtual function void build();
            super.build();
            k = bad::create("k", this);
        endfunction
        virtual function void connect();
            super.connect();
            k.i.tie(0);
            k.in.valid.tie(0);
            k.in.data.tie(0);
        endfunction
    endclass

endpackage
