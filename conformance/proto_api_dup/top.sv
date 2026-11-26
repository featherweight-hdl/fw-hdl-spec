// A protocol that names one API for both directions: FW-E-PROTO-API on
// the protocol.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;
    `include "test_apis.svh"

    class dup_proto extends fw_protocol;
        `fw_protocol_utils(dup_proto, test_put_if #(byte), test_put_if #(byte))
    endclass

    virtual class dup_bundle extends fw_rv_if #(byte);
        `fw_bundle_utils(dup_bundle, dup_proto)
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_bundle #(dup_bundle) out;
        virtual function void build();
            out = fw_bundle #(dup_bundle)::create("out", this);
        endfunction
    endclass

endpackage
