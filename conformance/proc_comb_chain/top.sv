// Two comb() stages created in reverse order (settle needs two passes), and a
// step() register that reads the end of the chain: step sees settled values.
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

    class inc extends fw_component implements fw_comb_if;
        `fw_component_utils(inc)
        fw_input  #(bit [7:0]) i;
        fw_output #(bit [7:0]) o;
        virtual function void build();
            i = fw_input  #(bit [7:0])::create("i", this);
            o = fw_output #(bit [7:0])::create("o", this);
        endfunction
        virtual function void comb();
            o.write(i.read() + 8'd1);
        endfunction
    endclass

    class dbl extends fw_component implements fw_comb_if;
        `fw_component_utils(dbl)
        fw_input  #(bit [7:0]) i;
        fw_output #(bit [7:0]) o;
        virtual function void build();
            i = fw_input  #(bit [7:0])::create("i", this);
            o = fw_output #(bit [7:0])::create("o", this);
        endfunction
        virtual function void comb();
            o.write(i.read() * 8'd2);
        endfunction
    endclass

    class reg8 extends fw_component implements fw_step_if;
        `fw_component_utils(reg8)
        fw_input  #(bit [7:0]) d;
        fw_output #(bit [7:0]) q;
        virtual function void build();
            d = fw_input  #(bit [7:0])::create("d", this);
            q = fw_output #(bit [7:0])::create("q", this);
        endfunction
        virtual function void step();
            q.write(d.read());
        endfunction
    endclass

    class top extends test_proc_top;
        `fw_component_utils(top)
        src  s;
        dbl  d2;
        inc  i1;
        reg8 r;
        virtual function void build();
            super.build();
            s  = src::create("s", this);
            d2 = dbl::create("d2", this);
            i1 = inc::create("i1", this);
            r  = reg8::create("r", this);
        endfunction
        virtual function void connect();
            super.connect();
            i1.i.connect(s.n);
            d2.i.connect(i1.o);
            r.d.connect(d2.o);
        endfunction
    endclass

endpackage
