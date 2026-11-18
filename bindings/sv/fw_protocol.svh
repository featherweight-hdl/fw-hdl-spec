// The base class of every protocol class: the hub that a protocol's APIs,
// bundles, transactors and abstractors register with.
//
// A protocol class has only static members. It extends ``fw_protocol``,
// uses :sv:macro:`fw_protocol_utils` (or, with parameters, a ``this_t``
// typedef and :sv:macro:`fw_protocol_param_utils`), and registers its APIs
// in ``declare()``::
//
//     class uart_proto #(int W = 8) extends fw_protocol;
//         typedef uart_proto #(W) this_t;
//         `fw_protocol_param_utils(uart_proto)
//         static function void declare(fw_protocol_decl d);
//             d.api(fw_api_type_of #(fw_put_if #(logic [W-1:0]))::get(), FW_PROTO_REQ);
//         endfunction
//     endclass
//
// Transactors register with the protocol (:sv:macro:`fw_xtor_utils`);
// finding the transactor for a bundle is static, done by the tools, not a
// run-time query. Configuration travels with endpoints
// (:sv:class:`fw_cfg_src`, :sv:class:`fw_cfg_sink`), and timing with
// channels, not with the protocol.
//
// The queries are static functions here, never methods on the parts.
virtual class fw_protocol;

    // Registers the protocol's APIs. A protocol class redeclares it; this
    // one registers nothing.
    //
    // :param d: what to register with
    extern static function void declare(fw_protocol_decl d);

    // Returns the protocol of ``x``: a bundle in any role, a transactor,
    // an abstractor's side or an endpoint. ``null`` when it has none.
    //
    // :param x: the object
    // :returns: the protocol's handle
    extern static function fw_protocol_type of(fw_object x);

    // Returns the role that bundle ``b`` plays: initiator for an
    // :sv:class:`fw_bundle`, target for an :sv:class:`fw_mirror`, monitor
    // for an :sv:class:`fw_monitor`.
    //
    // :param b: the bundle
    // :returns: the role
    extern static function fw_proto_role_e role_of(fw_object b);

    // Returns a constructor of the abstractor from protocol ``from`` to
    // protocol ``to``, or ``null``.
    //
    // :param from: the lower protocol
    // :param to: the upper protocol
    // :returns: the constructor
    extern static function fw_ctor #(fw_component) abstractor_for(fw_protocol_type from,
                                                                  fw_protocol_type to);

endclass
