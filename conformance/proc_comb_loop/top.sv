// FW-E-COMB-LOOP: a comb() that inverts its own output never settles; the run
// stops at the first edge.
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_proc.svh"

    class osc extends fw_component implements fw_comb_if;
        `fw_component_utils(osc)
        fw_output #(bit) a;
        virtual function void build();
            a = fw_output #(bit)::create("a", this);
        endfunction
        virtual function void comb();
            a.write(!a.read());
        endfunction
    endclass

    class top extends test_proc_top;
        `fw_component_utils(top)
        osc l;
        virtual function void build();
            super.build();
            l = osc::create("l", this);
        endfunction
    endclass

endpackage
