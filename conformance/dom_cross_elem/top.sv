// A crossing element: a component whose input and output ports are in
// unrelated clock domains is not a crossing; the nets on each side stay in
// one domain. Its parent's own ports take part like children's.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

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

    // Ports in two domains: a synchronizer.
    class sync2 extends fw_component;
        `fw_component_utils(sync2)
        fw_input  #(bit) i;
        fw_output #(bit) o;
        virtual function void build();
            i = fw_input  #(bit)::create("i", this);
            o = fw_output #(bit)::create("o", this);
            fw_clock_domain::set(i, fw_clock_domain::get(this, "src"));
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_input  #(bit) p;
        fw_output #(bit) q;
        fw_clock_domain  c0, c1;
        src              a;
        sync2            x;
        snk              b;
        virtual function void build();
            p  = fw_input  #(bit)::create("p", this);
            q  = fw_output #(bit)::create("q", this);
            c0 = fw_clock_domain::create("c0", this);
            c1 = fw_clock_domain::create("c1", this);
            fw_clock_domain::set(this, c1);
            fw_clock_domain::set(p, c0);
            a = src::create("a", this);
            x = sync2::create("x", this);
            b = snk::create("b", this);
            fw_clock_domain::set(a, c0);
            fw_clock_domain::set(x, c0, "src");
        endfunction
        virtual function void connect();
            x.i.connect(a.o);
            b.i.connect(x.o);
            q.connect(x.o);
        endfunction
    endclass

endpackage
