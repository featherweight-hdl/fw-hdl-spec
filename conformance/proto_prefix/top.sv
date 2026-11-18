// A protocol whose name does not end in _proto sets its prefix in
// declare().
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;
    `include "test_apis.svh"

    class pfx_link_protocol extends fw_protocol;
        `fw_protocol_utils(pfx_link_protocol)
        static function void declare(fw_protocol_decl d);
            d.prefix("lnk");
            d.api(fw_api_type_of #(test_put_if #(byte))::get(), FW_PROTO_REQ);
        endfunction
    endclass

    virtual class lnk_bundle extends fw_rv_if #(byte);
        `fw_bundle_protocol(pfx_link_protocol)
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_bundle #(lnk_bundle) out;
        virtual function void build();
            out = fw_bundle #(lnk_bundle)::create("out", this);
        endfunction
    endclass

endpackage
