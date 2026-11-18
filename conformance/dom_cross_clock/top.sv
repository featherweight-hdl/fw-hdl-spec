// Clock crossings: same domain (none), related (information), unrelated
// (error); unrelated through a local signal; a bundle connection across
// unrelated clocks, reported once on the lesser interface.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;

    // A leaf with one output.
    class src extends fw_component;
        `fw_component_utils(src)
        fw_output #(bit) o;
        virtual function void build();
            o = fw_output #(bit)::create("o", this);
        endfunction
    endclass

    // A leaf with one input.
    class snk extends fw_component;
        `fw_component_utils(snk)
        fw_input #(bit) i;
        virtual function void build();
            i = fw_input #(bit)::create("i", this);
        endfunction
    endclass

    class bsrc extends fw_component;
        `fw_component_utils(bsrc)
        fw_bundle #(fw_rv_if #(bit)) out;
        virtual function void build();
            out = fw_bundle #(fw_rv_if #(bit))::create("out", this);
        endfunction
    endclass

    class bsnk extends fw_component;
        `fw_component_utils(bsnk)
        fw_mirror #(fw_rv_if #(bit)) in;
        virtual function void build();
            in = fw_mirror #(fw_rv_if #(bit))::create("in", this);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_clock_domain  c0, c1, c2;
        fw_signal #(bit) s;
        src              a0, a1, a2, a3;
        snk              b0, b1, b2, b3;
        bsrc             a4;
        bsnk             b4;
        virtual function void build();
            c0 = fw_clock_domain::create("c0", this);
            c1 = fw_clock_domain::create("c1", this, fw_clock_kind::derived(c0, .div(2)));
            c2 = fw_clock_domain::create("c2", this);
            fw_clock_domain::set(this, c0);
            s  = fw_signal #(bit)::create("s", this);
            a0 = src::create("a0", this);
            a1 = src::create("a1", this);
            a2 = src::create("a2", this);
            a3 = src::create("a3", this);
            a4 = bsrc::create("a4", this);
            b0 = snk::create("b0", this);
            b1 = snk::create("b1", this);
            b2 = snk::create("b2", this);
            b3 = snk::create("b3", this);
            b4 = bsnk::create("b4", this);
            fw_clock_domain::set(b1, c1);
            fw_clock_domain::set(b2, c2);
            fw_clock_domain::set(b3, c2);
            fw_clock_domain::set(b4, c2);
        endfunction
        virtual function void connect();
            b0.i.connect(a0.o);
            b1.i.connect(a1.o);
            b2.i.connect(a2.o);
            s.connect(a3.o);
            b3.i.connect(s);
            b4.in.connect(a4.out);
        endfunction
    endclass

endpackage
