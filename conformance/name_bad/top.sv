// A name that is not an identifier with optional [index] suffixes: FW-E-
// NAME-BAD.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    class top extends fw_component;
        `fw_component_utils(top)
        fw_output #(bit) x;
        virtual function void build();
            x = fw_output #(bit)::create("x.y", this);
        endfunction
    endclass

endpackage
