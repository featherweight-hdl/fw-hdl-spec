// A step() counter that clears itself with in_reset(); the reset is held for
// edges 1-2.
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_proc.svh"

    class counter extends fw_component implements fw_step_if;
        `fw_component_utils(counter)
        fw_output #(bit [3:0]) count;
        virtual function void build();
            count = fw_output #(bit [3:0])::create("count", this);
        endfunction
        virtual function void step();
            if (fw_reset_domain::in_reset(this))
                count.write(0);
            else
                count.write(count.read() + 4'd1);
        endfunction
    endclass

    class top extends test_proc_top;
        `fw_component_utils(top)
        counter c;
        virtual function void build();
            super.build();
            c = counter::create("c", this);
        endfunction
    endclass

endpackage
