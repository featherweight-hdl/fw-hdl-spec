// Back-to-back puts on a ready/valid bundle through std fw_rv_initiator
// (R2.4, core-layer2 5.2): a run() puts 1, 2, 3 through a port bound to the
// initiator's export. The initiator's comb() offers an item from the call
// on, and its step() takes it at the handshake, where put returns; so the
// puts take one cycle each, with no added latency. Task code touches no
// signal.
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;
    `include "test_proc.svh"

    // Task code: puts 1, 2, 3 through its port, back to back.
    class drv extends fw_component implements fw_run_if;
        `fw_component_utils(drv)
        fw_port #(fw_put_if #(bit [7:0])) p;
        virtual function void build();
            p = fw_port #(fw_put_if #(bit [7:0]))::create("p", this);
        endfunction
        virtual task run();
            fw_put_if #(bit [7:0]) i = p.get_if();
            for (int n = 1; n <= 3; n++)
                i.put(8'(n));
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
        drv                          d;
        fw_rv_initiator #(bit [7:0]) x;
        rv_snk                       k;
        virtual function void build();
            super.build();
            d = drv::create("d", this);
            x = fw_rv_initiator #(bit [7:0])::create("x", this);
            k = rv_snk::create("k", this);
        endfunction
        virtual function void connect();
            super.connect();
            d.p.connect(x.t);
            x.pins.connect(k.in);
        endfunction
    endclass

endpackage
