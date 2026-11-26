// FW-E-XING-COMB (X2), on the crossing: take (reqs) and give (rsps) in a
// comb block, which runs at every settle.
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;
    `include "test_proc.svh"

    class xc extends fw_component;
        `fw_component_utils(xc)
        fw_to_sync #(bit [7:0])   reqs;
        fw_from_sync #(bit [7:0]) rsps;
        fw_output #(bit) t, g;
        virtual function void build();
            reqs = fw_to_sync #(bit [7:0])::create("reqs", this);
            rsps = fw_from_sync #(bit [7:0])::create("rsps", this);
            t    = fw_output #(bit)::create("t", this);
            g    = fw_output #(bit)::create("g", this);
        endfunction
        `fw_comb(look)
        function void look();
            bit [7:0] d;
            t.write(reqs.take(d));
            g.write(rsps.give(8'd1));
        endfunction
    endclass

    class top extends test_proc_top;
        `fw_component_utils(top)
        xc x;
        virtual function void build();
            super.build();
            x = xc::create("x", this);
        endfunction
    endclass

endpackage
