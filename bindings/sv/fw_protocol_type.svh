// A protocol's handle: one object per specialization of a protocol class,
// returned by the class's ``get_type()`` (:sv:macro:`fw_protocol_utils`).
// It is the hub of the protocol: every part registers with it::
//
//     fw_protocol_type p = uart_proto #(P)::get_type();
//
// It has no query methods: what a protocol relates (its APIs, bundles and
// converters) is static, read by the tools from the source and the IR.
virtual class fw_protocol_type;
endclass
