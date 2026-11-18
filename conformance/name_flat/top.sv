// A port out_valid and a bundle out whose member valid flattens to the same
// name: FW-E-NAME-FLAT on the object created later.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;

    class top extends fw_component;
        `fw_component_utils(top)
        fw_output #(bit)            out_valid;
        fw_bundle #(fw_rv_if #(bit)) out;
        virtual function void build();
            out_valid = fw_output #(bit)::create("out_valid", this);
            out       = fw_bundle #(fw_rv_if #(bit))::create("out", this);
        endfunction
    endclass

endpackage
