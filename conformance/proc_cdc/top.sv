// A two-flop synchronizer written as one component in two clocks (core-layer2
// 4.4): its step block writes q, in clk_b (period 17), and reads a, in clk
// (period 10). The trace is sampled at clk_b's edges (17, 34, ...). The
// periods are chosen so that no clk_b edge falls between t's write (edge 40)
// and its commit (edge 50); see conformance/README.md.
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_proc.svh"

    // t rises at the edge at 40 and stays high.
    class pulse extends fw_component implements fw_step_if;
        `fw_component_utils(pulse)
        fw_output #(bit)       t;
        fw_output #(bit [3:0]) n;
        virtual function void build();
            t = fw_output #(bit)::create("t", this);
            n = fw_output #(bit [3:0])::create("n", this);
        endfunction
        virtual function void step();
            if (n.read() != 4'd15)
                n.write(n.read() + 4'd1);
            t.write(n.read() >= 4'd3);
        endfunction
    endclass

    class sync2 extends fw_component;
        `fw_component_utils(sync2)
        fw_input  #(bit) a;
        fw_output #(bit) q;
        bit s1;
        virtual function void build();
            a = fw_input  #(bit)::create("a", this);
            q = fw_output #(bit)::create("q", this);
            fw_clock_domain::set(q, fw_clock_domain::get(this, "b"));
        endfunction
        `fw_step(sync)
        function void sync();
            q.write(s1);
            s1 = a.read();
        endfunction
    endclass

    class top extends test_proc_top;
        `fw_component_utils(top)
        fw_clock_domain clk_b;
        pulse           p;
        sync2           x;
        virtual function void build();
            super.build();
            clk_b = fw_clock_domain::create("clk_b", this, fw_clock_kind::root(17ns));
            p = pulse::create("p", this);
            x = sync2::create("x", this);
            fw_clock_domain::set(x, clk_b, "b");
        endfunction
        virtual function void connect();
            super.connect();
            x.a.connect(p.t);
        endfunction
    endclass

endpackage
