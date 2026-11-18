// A comb() mux: y = sel ? a : b, with b tied; inputs from a step() source.
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_proc.svh"

    // Free-running: n counts edges, sel toggles; no reset.
    class src extends fw_component implements fw_step_if;
        `fw_component_utils(src)
        fw_output #(bit [7:0]) n;
        fw_output #(bit)       sel;
        virtual function void build();
            n   = fw_output #(bit [7:0])::create("n", this);
            sel = fw_output #(bit)::create("sel", this);
        endfunction
        virtual function void step();
            n.write(n.read() + 8'd1);
            sel.write(!sel.read());
        endfunction
    endclass

    class mux extends fw_component implements fw_comb_if;
        `fw_component_utils(mux)
        fw_input  #(bit)       sel;
        fw_input  #(bit [7:0]) a, b;
        fw_output #(bit [7:0]) y;
        virtual function void build();
            sel = fw_input  #(bit)::create("sel", this);
            a   = fw_input  #(bit [7:0])::create("a", this);
            b   = fw_input  #(bit [7:0])::create("b", this);
            y   = fw_output #(bit [7:0])::create("y", this);
        endfunction
        virtual function void comb();
            y.write(sel.read() ? a.read() : b.read());
        endfunction
    endclass

    class top extends test_proc_top;
        `fw_component_utils(top)
        src s;
        mux m;
        virtual function void build();
            super.build();
            s = src::create("s", this);
            m = mux::create("m", this);
        endfunction
        virtual function void connect();
            super.connect();
            m.sel.connect(s.sel);
            m.a.connect(s.n);
            m.b.tie(8'hf0);
        endfunction
    endclass

endpackage
