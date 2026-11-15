// Type equivalence: a typedef of bit[7:0] connects to bit[7:0], and a packed
// struct keeps its typedef name. Type spellings in the netlist.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    typedef bit [7:0] u8_t;
    typedef struct packed { bit [3:0] hi; bit [3:0] lo; } pair_t;

    class sink extends fw_component;
        `fw_component_utils(sink)
        fw_input #(u8_t)   i;
        fw_input #(pair_t) p;
        virtual function void build();
            i = fw_input #(u8_t)::create("i", this);
            p = fw_input #(pair_t)::create("p", this);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_input #(bit [7:0]) a;
        fw_input #(pair_t)    pp;
        sink                  c;
        virtual function void build();
            a  = fw_input #(bit [7:0])::create("a", this);
            pp = fw_input #(pair_t)::create("pp", this);
            c  = sink::create("c", this);
        endfunction
        virtual function void connect();
            a.connect(c.i);
            pp.connect(c.p);
        endfunction
    endclass

endpackage
