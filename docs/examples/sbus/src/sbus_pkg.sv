// sbus: a small request/response bus, the worked example of
// docs/protocol-packages.rst. This file is the whole hand-written source of
// the protocol package: payloads, the transaction-level API, the protocol
// and its bundle. GenKit derives sbus_pkg_gen_pkg from it.
`include "fw_hdl_macros.svh"

package sbus_pkg;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;

    // One request beat. Member names carry no channel prefix: the pin map
    // adds it (reqaddr, reqwdata, reqwe).
    typedef struct packed {
        bit [7:0]  addr;
        bit [31:0] wdata;
        bit        we;
    } sbus_req_t;

    // One response beat.
    typedef struct packed {
        bit [31:0] rdata;
        bit        err;
    } sbus_rsp_t;

    // The transaction-level API: one access and its response. The bus has
    // one access in flight, so a blocking call is enough. Outputs lead.
    interface class sbus_if;
        pure virtual task access(output sbus_rsp_t rsp, input sbus_req_t req);
    endclass

    // The protocol: the hub every other part registers with.
    class sbus_proto extends fw_protocol;
        `fw_protocol_utils(sbus_proto, sbus_if)
    endclass

    // The pins, from the initiator's view: a bundle of two ready/valid
    // channels. req is driven by the initiator, rsp by the target.
    virtual class sbus_bundle extends fw_bundle_base;
        `fw_bundle_utils(sbus_bundle, sbus_proto)
        fw_bundle #(fw_rv_if #(sbus_req_t)) req;
        fw_mirror #(fw_rv_if #(sbus_rsp_t)) rsp;
        virtual function void build();
            req = fw_bundle #(fw_rv_if #(sbus_req_t))::create("req", this);
            rsp = fw_mirror #(fw_rv_if #(sbus_rsp_t))::create("rsp", this);
        endfunction
    endclass
endpackage
