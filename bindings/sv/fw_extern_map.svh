// An extern's pin map: the module's parameters and how each of its pins
// connects. The tool creates it and passes it to
// :sv:func:`fw_extern_if::extern_map`.
//
// Class-side objects are handles; module-side names are strings. Each module
// pin is mapped exactly once (``FW-E-EXT-PIN``) and each port maps to a pin
// (``FW-E-EXT-PORT``) unless it is marked :sv:func:`fw_extern_map::unused`:
//
// - An unmapped port or bundle member maps to the pin with its flattened
//   name: ``in.data`` maps to pin ``in_data``.
// - Entries apply in order. A rule maps only members still unmapped, and an
//   explicit :sv:func:`fw_extern_map::pin` after a rule replaces the rule's
//   choice for that member.
//
// Clock and reset pins are mapped like any other pin in layer 1. The domain
// layer maps them through its own classes, without new methods here.
class fw_extern_map;

    // Sets a module parameter: a value of any type
    // (:sv:func:`fw_value::of`) or, for a ``parameter type``, a type
    // (:sv:func:`fw_type::get`)::
    //
    //     m.param("WIDTH",  fw_value #(int)::of($bits(T)));
    //     m.param("data_t", fw_type #(T)::get());
    //
    // :param name: the parameter name
    // :param value: its value
    extern function void param(string name, fw_param_arg value);

    // Maps a module pin to a port, or to a member of a bundle port.
    //
    // :param name: the pin name
    // :param s: the port
    extern function void pin(string name, fw_signal_base s);

    // Adds a naming rule for the members of a bundle.
    //
    // :param b: a bundle in a role
    // :param pre: the pin-name prefix
    // :returns: the rule, to add renames to
    extern function fw_pin_rule prefix(fw_object b, string pre);

    // Ties an input pin to a constant.
    //
    // :param name: the pin name
    // :param value: the constant
    extern function void tie(string name, logic [1023:0] value);

    // Leaves an output pin unconnected.
    //
    // :param name: the pin name
    extern function void open(string name);

    // Marks an input port, or every port of a bundle, as having no pin: the
    // module does not use it. A monitor of ``fw_rv_if`` that wraps a checker
    // without a data pin marks ``p.data`` unused. Only inputs may be unused:
    // an output with no pin would leave its net undriven (``FW-E-EXT-PORT``).
    //
    // :param o: a port or bundle of this extern
    extern function void unused(fw_object o);

endclass
