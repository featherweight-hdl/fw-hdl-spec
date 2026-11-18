// The source of a configuration value of type ``T``, a struct. ``set`` is
// the commit point: it pushes the value to every bound
// :sv:class:`fw_cfg_sink`, and a sink bound later receives the last value
// when it is bound.
//
// :param T: the configuration struct
class fw_cfg_src #(type T = int) extends fw_object;

    typedef fw_cfg_src #(T) this_t;

    // Creates a source named ``name`` under ``parent``.
    //
    // :param name: the source's name
    // :param parent: the owner
    // :returns: the source
    extern static function this_t create(string name, fw_object parent);

    // Sets the value and pushes it to every sink.
    //
    // :param v: the value
    extern function void set(T v);

    // Returns the last value set.
    //
    // :returns: the value
    extern function T get();

    // Passes this source up through ``outer``, a source of the parent:
    // sinks bound to ``outer`` receive this source's value.
    //
    // :param outer: the parent's source
    extern function void connect_up(fw_cfg_src #(T) outer);

endclass
