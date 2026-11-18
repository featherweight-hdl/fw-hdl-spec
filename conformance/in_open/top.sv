// Unconnected, untied child inputs, including the effective inputs of a
// mirror: FW-E-IN-OPEN on each. The mirror's ready (an output) is not
// reported.
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
        fw_mirror #(fw_rv_if #(bit)) in;
        virtual function void build();
            in = fw_mirror #(fw_rv_if #(bit))::create("in", this);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        leaf c;
        rx   k;
        virtual function void build();
            c = leaf::create("c", this);
            k = rx::create("k", this);
        endfunction
    endclass

endpackage
