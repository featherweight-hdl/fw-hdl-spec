// Ties: on a child input, on mirror members, on an own output, and on a
// local signal that fans out. A tie is the net's source.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;

    // A leaf: one input, one output.
    class leaf extends fw_component;
        `fw_component_utils(leaf)
        fw_input  #(bit) i;
        fw_output #(bit) o;
        virtual function void build();
            i = fw_input  #(bit)::create("i", this);
            o = fw_output #(bit)::create("o", this);
        endfunction
    endclass

    class rx extends fw_component;
        `fw_component_utils(rx)
        fw_input  #(bit)                   i;
        fw_mirror #(fw_rv_if #(bit [7:0])) in;
        virtual function void build();
            i  = fw_input  #(bit)::create("i", this);
            in = fw_mirror #(fw_rv_if #(bit [7:0]))::create("in", this);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_output #(bit) y;
        fw_signal #(bit) s;
        leaf             c2;
        rx               r;
        virtual function void build();
            y  = fw_output #(bit)::create("y", this);
            s  = fw_signal #(bit)::create("s", this);
            c2 = leaf::create("c2", this);
            r  = rx::create("r", this);
        endfunction
        virtual function void connect();
            y.tie(1);
            r.i.tie(0);
            r.in.valid.tie(1);
            r.in.data.tie(8'h5a);
            s.tie(1);
            s.connect(c2.i);
        endfunction
    endclass

endpackage
