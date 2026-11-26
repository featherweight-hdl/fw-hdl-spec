// A default and an explicit drive at one edge (C5): the initiator's step
// block drops valid after each handshake (the default), and its run()
// raises it again at the same edge for the next put (the explicit drive,
// which wins). Puts 1, 2, 3 go back to back, with one stall: the sink's
// ready is low for the cycle before edge 5, where valid holds. No idle
// cycle is added and no beat is repeated.
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
        // The default: valid drops after a handshake.
        `fw_step(dflt)
        function void dflt();
            if (out.valid.read() && out.ready.read())
                out.valid.write(0);
        endfunction
        // Returns at the handshake edge.
        task put(bit [7:0] d);
            out.valid.write(1);
            out.data.write(d);
            do fw_clock_domain::tick(this);
            while (!(out.valid.read() && out.ready.read()));
        endtask
        virtual task run();
            fw_reset_domain::wait_reset_done(this);
            for (int i = 1; i <= 3; i++)
                put(8'(i));
        endtask
    endclass

    // Takes a beat when valid and ready; ready is low while s is 1, which
    // is between edges 4 and 5.
    class rv_snk extends fw_component implements fw_step_if;
        `fw_component_utils(rv_snk)
        fw_mirror #(fw_rv_if #(bit [7:0])) in;
        fw_output #(bit [7:0]) got, n;
        fw_output #(bit [3:0]) c;
        fw_output #(bit)       s;
        virtual function void build();
            in  = fw_mirror #(fw_rv_if #(bit [7:0]))::create("in", this);
            got = fw_output #(bit [7:0])::create("got", this);
            n   = fw_output #(bit [7:0])::create("n", this);
            c   = fw_output #(bit [3:0])::create("c", this);
            s   = fw_output #(bit)::create("s", this);
        endfunction
        `fw_comb(rdy)
        function void rdy();
            in.ready.write(in.valid.read() && !s.read());
        endfunction
        virtual function void step();
            c.write(c.read() + 4'd1);
            s.write(c.read() == 4'd3);
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
