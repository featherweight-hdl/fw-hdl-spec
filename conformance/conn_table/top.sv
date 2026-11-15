// Every legal row of the connection table: own in to child in, child out to
// child in (siblings), child out to own out, own in to own out, a local
// signal on a net, and inout to inout. An unconnected output and an
// unconnected inout are legal.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

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

    // An inout port only.
    class bidir extends fw_component;
        `fw_component_utils(bidir)
        fw_inout #(bit) io;
        virtual function void build();
            io = fw_inout #(bit)::create("io", this);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_input  #(bit) a_in, b_in;
        fw_output #(bit) y_out, z_out;
        fw_inout  #(bit) io;
        fw_signal #(bit) s;
        leaf             c1, c2, c3;
        bidir            b1, b2;
        virtual function void build();
            a_in  = fw_input  #(bit)::create("a_in", this);
            b_in  = fw_input  #(bit)::create("b_in", this);
            y_out = fw_output #(bit)::create("y_out", this);
            z_out = fw_output #(bit)::create("z_out", this);
            io    = fw_inout  #(bit)::create("io", this);
            s     = fw_signal #(bit)::create("s", this);
            c1 = leaf::create("c1", this);
            c2 = leaf::create("c2", this);
            c3 = leaf::create("c3", this);
            b1 = bidir::create("b1", this);
            b2 = bidir::create("b2", this);
        endfunction
        virtual function void connect();
            a_in.connect(c1.i);     // own in -> child in
            c1.o.connect(c2.i);     // child out -> child in
            c2.o.connect(y_out);    // child out -> own out
            b_in.connect(z_out);    // own in -> own out
            a_in.connect(s);        // a local signal on the a_in net
            s.connect(c3.i);
            io.connect(b1.io);      // inout <-> inout
        endfunction
    endclass

endpackage
