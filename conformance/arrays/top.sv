// Arrays: a dynamic array of children chained in a loop, and an array of
// mirrors passed through to an array of children.
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
    // An initiator.
    class src extends fw_component;
        `fw_component_utils(src)
        fw_bundle #(fw_rv_if #(bit)) out;
        virtual function void build();
            out = fw_bundle #(fw_rv_if #(bit))::create("out", this);
        endfunction
    endclass

    // A target.
    class snk extends fw_component;
        `fw_component_utils(snk)
        fw_mirror #(fw_rv_if #(bit)) in;
        virtual function void build();
            in = fw_mirror #(fw_rv_if #(bit))::create("in", this);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_input  #(bit)             i;
        fw_output #(bit)             o;
        fw_mirror #(fw_rv_if #(bit)) in[2];
        leaf                         u[];
        snk                          r[2];
        virtual function void build();
            i = fw_input  #(bit)::create("i", this);
            o = fw_output #(bit)::create("o", this);
            foreach (in[j]) in[j] = fw_mirror #(fw_rv_if #(bit))::create($sformatf("in[%0d]", j), this);
            u = new[3];
            foreach (u[j]) u[j] = leaf::create($sformatf("u[%0d]", j), this);
            foreach (r[j]) r[j] = snk::create($sformatf("r[%0d]", j), this);
        endfunction
        virtual function void connect();
            i.connect(u[0].i);
            for (int j = 0; j + 1 < u.size(); j++) u[j].o.connect(u[j+1].i);
            u[u.size()-1].o.connect(o);
            foreach (r[j]) r[j].in.connect_up(in[j]);
        endfunction
    endclass

endpackage
