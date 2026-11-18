// An unparameterized protocol with one request API, and a bundle that names
// it. The top's own initiator bundle puts the protocol in the netlist.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;
    `include "test_apis.svh"

    class basic_proto extends fw_protocol;
        `fw_protocol_utils(basic_proto)
        static function void declare(fw_protocol_decl d);
            d.api(fw_api_type_of #(test_put_if #(byte))::get(), FW_PROTO_REQ);
        endfunction
    endclass

    virtual class basic_bundle extends fw_rv_if #(byte);
        `fw_bundle_protocol(basic_proto)
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_bundle #(basic_bundle) out;
        virtual function void build();
            out = fw_bundle #(basic_bundle)::create("out", this);
        endfunction
    endclass

endpackage
