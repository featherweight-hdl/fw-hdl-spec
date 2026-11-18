// A protocol that registers two APIs for the request direction:
// FW-E-PROTO-API on the protocol.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;
    `include "test_apis.svh"

    class dup_proto extends fw_protocol;
        `fw_protocol_utils(dup_proto)
        static function void declare(fw_protocol_decl d);
            d.api(fw_api_type_of #(test_put_if #(byte))::get(), FW_PROTO_REQ);
            d.api(fw_api_type_of #(test_get_if #(byte))::get(), FW_PROTO_REQ);
        endfunction
    endclass

    virtual class dup_bundle extends fw_rv_if #(byte);
        `fw_bundle_protocol(dup_proto)
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_bundle #(dup_bundle) out;
        virtual function void build();
            out = fw_bundle #(dup_bundle)::create("out", this);
        endfunction
    endclass

endpackage
