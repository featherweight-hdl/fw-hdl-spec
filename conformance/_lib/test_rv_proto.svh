// A parameterized ready/valid test protocol, used at two widths: one
// family, one specialization per ``W``.
`ifndef TEST_RV_PROTO_SVH
`define TEST_RV_PROTO_SVH
`include "test_apis.svh"

// The protocol: one request API, ``test_put_if`` of a ``W``-bit word.
class test_rv_proto #(int W = 8) extends fw_protocol;
    typedef test_rv_proto #(W) this_t;
    `fw_protocol_param_utils(test_rv_proto, test_put_if #(logic [W-1:0]))
endclass

// Its bundle: ready/valid of a ``W``-bit word.
virtual class test_rv_bundle #(int W = 8) extends fw_rv_if #(logic [W-1:0]);
    `fw_bundle_utils(test_rv_bundle, test_rv_proto #(W))
endclass

`endif // TEST_RV_PROTO_SVH
