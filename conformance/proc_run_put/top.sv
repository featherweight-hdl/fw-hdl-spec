// A run() initiator puts 1, 2, 3 back to back on a ready/valid bundle (R2.4,
// core-layer2 5.2): a write in the run phase of edge k is committed at edge
// k+1, and a put completes at the edge where ready is seen, so the puts take
// one cycle each, with no added latency.
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;
    `include "test_proc.svh"

    class drv extends fw_component implements fw_run_if;
        `fw_component_utils(drv)
        fw_bundle #(fw_rv_if #(bit [7:0])) out;
        virtual function void build();
            out = fw_bundle #(fw_rv_if #(bit [7:0]))::create("out", this);
        endfunction
        virtual task run();
            fw_reset_domain::wait_reset_done(this);
            for (int i = 1; i <= 3; i++) begin
                out.valid.write(1);
                out.data.write(8'(i));
                do fw_clock_domain::tick(this);
                while (!out.ready.read());
            end
            out.valid.write(0);
        endtask
    endclass

    // Always ready; counts and records what it accepts.
    class rv_snk extends fw_component implements fw_step_if;
        `fw_component_utils(rv_snk)
        fw_mirror #(fw_rv_if #(bit [7:0])) in;
        fw_output #(bit [7:0]) got, n;
        virtual function void build();
            in  = fw_mirror #(fw_rv_if #(bit [7:0]))::create("in", this);
            got = fw_output #(bit [7:0])::create("got", this);
            n   = fw_output #(bit [7:0])::create("n", this);
        endfunction
        `fw_comb(rdy)
        function void rdy();
            in.ready.write(in.valid.read());
        endfunction
        virtual function void step();
            if (in.valid.read() && in.ready.read()) begin
                got.write(in.data.read());
                n.write(n.read() + 8'd1);
            end
        endfunction
    endclass

    class top extends test_proc_top;
        `fw_component_utils(top)
        drv    d;
        rv_snk k;
        virtual function void build();
            super.build();
            d = drv::create("d", this);
            k = rv_snk::create("k", this);
        endfunction
        virtual function void connect();
            super.connect();
            d.out.connect(k.in);
        endfunction
    endclass

endpackage
