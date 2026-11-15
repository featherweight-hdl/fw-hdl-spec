// A component created in connect(), after the build phase: FW-E-ELAB-LATE,
// named by the full name it would have had.
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

    class top extends fw_component;
        `fw_component_utils(top)
        leaf late;
        virtual function void connect();
            late = leaf::create("late", this);
        endfunction
    endclass

endpackage
