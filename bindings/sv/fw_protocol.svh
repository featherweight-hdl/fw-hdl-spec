// The base class of every protocol class: the hub that a protocol's APIs,
// bundles, transactors and abstractors register with.
//
// A protocol class has only static members. It extends ``fw_protocol`` and
// uses :sv:macro:`fw_protocol_utils` (or, with parameters, a ``this_t``
// typedef and :sv:macro:`fw_protocol_param_utils`), which names its APIs:
// the request API (``REQ``), called by the initiating side, and the
// response API (``RSP``), called back on it. Either may be omitted::
//
//     class wb_proto extends fw_protocol;
//         `fw_protocol_utils(wb_proto, wb_if)
//     endclass
//
//     class axi4_proto extends fw_protocol;
//         `fw_protocol_utils(axi4_proto, axi4_req_if, axi4_rsp_if)
//     endclass
//
//     class uart_proto #(int W = 8) extends fw_protocol;
//         typedef uart_proto #(W) this_t;
//         `fw_protocol_param_utils(uart_proto, fw_put_if #(logic [W-1:0]))
//     endclass
//
// Transactors extend a role base class (:sv:class:`fw_xtor_initiator`,
// :sv:class:`fw_xtor_target`, :sv:class:`fw_xtor_monitor`), which names the
// protocol through the bundle type, and register (:sv:macro:`fw_xtor_utils`);
// finding the transactor for a bundle is static, done by the tools, not a
// run-time query. Configuration travels with endpoints
// (:sv:class:`fw_cfg_src`, :sv:class:`fw_cfg_sink`), and timing with
// channels, not with the protocol. There are no run-time queries: what a
// protocol relates is static, read by the tools.
virtual class fw_protocol;

    // The prefix of the protocol's derived names; "" for the default (the
    // family name without ``_proto``). Set with
    // :sv:macro:`fw_protocol_prefix`.
    localparam string __fw_prefix = "";

    // The request and response APIs; :sv:macro:`fw_protocol_utils`
    // redeclares them.
    typedef fw_no_api __fw_req_api;
    typedef fw_no_api __fw_rsp_api;

endclass
