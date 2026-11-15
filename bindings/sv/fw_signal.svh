// A local signal: a net inside its component, not visible outside it. The
// ports extend it.
//
// :param T: the value type: a packed type (a ``bit`` or ``logic`` vector,
//     packed struct, packed union or enum)
class fw_signal #(type T = bit) extends fw_signal_base;

    // This class, for out-of-block method bodies.
    typedef fw_signal #(T) this_t;

    // Creates a signal. Arrays are made by calling it in a loop with names
    // ``name[i]``.
    //
    // :param name: the signal name
    // :param parent: the owning component
    // :returns: the new signal
    extern static function this_t create(string name, fw_object parent);

    // Connects this signal to ``other``: they become one net. Valid only in
    // the connect phase, :sv:func:`fw_component::connect`. The compiler
    // checks that the value types match; elaboration checks directions and
    // drivers.
    //
    // :param other: a signal or port in the connecting component's scope
    extern function void connect(fw_signal #(T) other);

    // Drives this signal with a constant. A tie is a source, so a tied
    // signal may not also be driven. Valid only in the connect phase.
    //
    // :param value: the constant
    extern function void tie(T value);

endclass
