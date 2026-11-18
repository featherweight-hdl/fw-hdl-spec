// A parameterized ready/valid test protocol, used at two widths: one
// family, one specialization per ``W``.
`ifndef TEST_RV_PROTO_SVH
`define TEST_RV_PROTO_SVH
`include "test_apis.svh"

// The protocol: one request API, ``test_put_if`` of a ``W``-bit word.
class test_rv_proto #(int W = 8) extends fw_protocol;
    typedef test_rv_proto #(W) this_t;
    `fw_protocol_param_utils(test_rv_proto)
    static function void declare(fw_protocol_decl d);
        d.api(fw_api_type_of #(test_put_if #(logic [W-1:0]))::get(), FW_PROTO_REQ);
    endfunction
endclass

// Its bundle: ready/valid of a ``W``-bit word.
virtual class test_rv_bundle #(int W = 8) extends fw_rv_if #(logic [W-1:0]);
    `fw_bundle_protocol(test_rv_proto #(W))
endclass

`endif // TEST_RV_PROTO_SVH
