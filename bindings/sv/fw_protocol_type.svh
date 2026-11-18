// A protocol's handle: one object per specialization of a protocol class,
// returned by the class's ``get_type()`` (:sv:macro:`fw_protocol_utils`).
// It is the hub of the protocol: every part registers with it, and every
// part is found from it::
//
//     fw_protocol_type p = uart_proto #(P)::get_type();
//     fw_api_type req = p.api(FW_PROTO_REQ);
virtual class fw_protocol_type;

    // Returns the protocol's name: its canonical type spelling, with
    // parameters, as the netlist writes it.
    //
    // :returns: the name
    extern function string name();

    // Returns the protocol's family: the class without its parameters.
    //
    // :returns: the family
    extern function fw_protocol_family family();

    // Returns the specialization's parameters, for reporting
    // (``"P='{DATA_W:32, ...}"``); ``""`` for a class without parameters.
    //
    // :returns: the parameters
    extern function string params();

    // Returns the API registered for direction ``dir``, or ``null``.
    //
    // :param dir: the direction
    // :returns: the API's handle
    extern function fw_api_type api(fw_proto_dir_e dir);

    // Returns every registered API, in registration order.
    //
    // :returns: the APIs' handles
    extern function fw_api_type_q apis();

    // Returns the bundle types that name the protocol
    // (:sv:macro:`fw_bundle_protocol`), as canonical type spellings.
    //
    // :returns: the bundle types
    extern function fw_string_q bundles();

    // Returns constructors of the abstractors with the protocol on either
    // side (:sv:macro:`fw_abstractor_utils`).
    //
    // :returns: the constructors
    extern function fw_component_ctor_q abstractors();

endclass
