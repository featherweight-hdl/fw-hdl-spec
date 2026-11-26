// A parameterized protocol whose this_t is the default specialization,
// not its own: FW-E-PROTO-THIS on the class. It compiles in SV.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;
    `include "test_apis.svh"

    class bad_proto #(int W = 8) extends fw_protocol;
        typedef bad_proto #() this_t;           // should be bad_proto #(W)
        `fw_protocol_param_utils(bad_proto, test_put_if #(logic [W-1:0]))
    endclass

    virtual class bad_bundle #(int W = 8) extends fw_rv_if #(logic [W-1:0]);
        `fw_bundle_utils(bad_bundle, bad_proto #(W))
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_bundle #(bad_bundle #(16)) out;
        virtual function void build();
            out = fw_bundle #(bad_bundle #(16))::create("out", this);
        endfunction
    endclass

endpackage
