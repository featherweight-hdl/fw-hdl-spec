// test_rv_proto at two widths: one family, two specializations.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;
    `include "test_rv_proto.svh"

    class top extends fw_component;
        `fw_component_utils(top)
        fw_bundle #(test_rv_bundle #(8))  a;
        fw_mirror #(test_rv_bundle #(16)) b;
        virtual function void build();
            a = fw_bundle #(test_rv_bundle #(8))::create("a", this);
            b = fw_mirror #(test_rv_bundle #(16))::create("b", this);
        endfunction
    endclass

endpackage
