// A port constructed with new() instead of the factory, then connected: FW-
// E-ELAB-NEW, named by the component whose phase method used it.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    class top extends fw_component;
        `fw_component_utils(top)
        fw_input  #(bit) x;
        fw_output #(bit) y;
        virtual function void build();
            x = new();
            y = fw_output #(bit)::create("y", this);
        endfunction
        virtual function void connect();
            y.connect(x);
        endfunction
    endclass

endpackage
