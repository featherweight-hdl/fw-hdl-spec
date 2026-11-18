// Two test protocols for an abstractor: packets (upper) over a byte-wide
// physical link (lower).
`ifndef TEST_PKT_PHY_SVH
`define TEST_PKT_PHY_SVH
`include "test_apis.svh"

// One packet.
typedef struct packed {
    bit [31:0] addr;
    bit [7:0]  len;
} test_pkt_t;

// The upper protocol: packets, with no bundle of its own.
class test_pkt_proto extends fw_protocol;
    `fw_protocol_utils(test_pkt_proto)
    static function void declare(fw_protocol_decl d);
        d.api(fw_api_type_of #(test_put_if #(test_pkt_t))::get(), FW_PROTO_REQ);
    endfunction
endclass

// The lower protocol: bytes, sent and received.
class test_phy_proto extends fw_protocol;
    `fw_protocol_utils(test_phy_proto)
    static function void declare(fw_protocol_decl d);
        d.api(fw_api_type_of #(test_put_if #(byte))::get(), FW_PROTO_REQ);
        d.api(fw_api_type_of #(test_get_if #(byte))::get(), FW_PROTO_RSP);
    endfunction
endclass

// The lower protocol's bundle: ready/valid of a byte.
virtual class test_phy_bundle extends fw_rv_if #(byte);
    `fw_bundle_protocol(test_phy_proto)
endclass

`endif // TEST_PKT_PHY_SVH
