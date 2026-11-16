// Waivers: a waived crossing is not reported; a waiver with an empty reason
// is an error and waives nothing; a waiver that matches no crossing is a
// warning.
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

    class top extends fw_component;
        `fw_component_utils(top)
        fw_clock_domain c0, c2;
        src             a0, a1, a2;
        snk             b0, b1, b2;
        virtual function void build();
            c0 = fw_clock_domain::create("c0", this);
            c2 = fw_clock_domain::create("c2", this);
            fw_clock_domain::set(this, c0);
            a0 = src::create("a0", this);
            a1 = src::create("a1", this);
            a2 = src::create("a2", this);
            b0 = snk::create("b0", this);
            b1 = snk::create("b1", this);
            b2 = snk::create("b2", this);
            fw_clock_domain::set(b0, c2);
            fw_clock_domain::set(b1, c2);
        endfunction
        virtual function void connect();
            b0.i.connect(a0.o);
            b1.i.connect(a1.o);
            b2.i.connect(a2.o);
            fw_clock_domain::waive(b0.i, a0.o, "quasi-static configuration bit");
            fw_clock_domain::waive(b1.i, a1.o, "");
            fw_clock_domain::waive(a2.o, b2.i, "not a crossing");
        endfunction
    endclass

endpackage
