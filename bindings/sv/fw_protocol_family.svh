// A protocol family: a protocol class without its parameters, one object
// per class. It is what code written for any specialization keys on: the
// testbench and bind generators, rules and coverage written for any width,
// naming and the netlist. See :sv:func:`fw_protocol_type::family`.
class fw_protocol_family;

    // Returns the family's name: the protocol class's name, without
    // parameters (``axi4_proto``).
    //
    // :returns: the name
    extern function string name();

    // Returns the prefix of the names derived from the family: the name
    // with a trailing ``_proto`` removed (``axi4``), or the prefix that the
    // protocol's ``declare()`` set (:sv:func:`fw_protocol_decl::prefix`).
    //
    // :returns: the prefix
    extern function string prefix();

endclass
