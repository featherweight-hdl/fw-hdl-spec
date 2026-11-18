// reset_state() sets the reset value while the reset is asserted (edges 1-2);
// step() runs only out of reset.
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_proc.svh"

    class cnt extends fw_component implements fw_step_if, fw_reset_state_if;
        `fw_component_utils(cnt)
        fw_output #(bit [7:0]) q;
        virtual function void build();
            q = fw_output #(bit [7:0])::create("q", this);
        endfunction
        virtual function void reset_state();
            q.write(8'h5a);
        endfunction
        virtual function void step();
            q.write(q.read() + 8'd1);
        endfunction
    endclass

    class top extends test_proc_top;
        `fw_component_utils(top)
        cnt c;
        virtual function void build();
            super.build();
            c = cnt::create("c", this);
        endfunction
    endclass

endpackage
