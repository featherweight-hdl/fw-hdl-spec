// Two objects with the same name under one parent: FW-E-NAME-DUP on the
// second.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    class top extends fw_component;
        `fw_component_utils(top)
        fw_output #(bit) x, x2;
        virtual function void build();
            x  = fw_output #(bit)::create("x", this);
            x2 = fw_output #(bit)::create("x", this);
        endfunction
    endclass

endpackage
