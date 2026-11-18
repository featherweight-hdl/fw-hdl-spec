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

    // Returns the value of this signal's net, as of the last update: legal
    // on every direction. A tied signal reads as its constant.
    //
    // :returns: the value
    extern function T read();

    // Writes the whole value; it becomes visible at the update point of the
    // writing process (layer 2): at once in the settle for ``comb()``, after
    // the edge for ``step()`` and ``run()``. Writing an effective input is
    // ``FW-E-WRITE-IN``; a signal written by two processes is
    // ``FW-E-WRITE-MULTI``.
    //
    // :param v: the value
    extern function void write(T v);

endclass
