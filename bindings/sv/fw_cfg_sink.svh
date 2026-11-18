// A reader of a configuration value of type ``T``. It reads ``cfg``
// directly, a copy that the source pushes. Writing ``cfg`` is an error
// (``FW-E-CFG-WRITE``). An unbound sink is an error
// (``FW-E-CFG-UNBOUND``).
//
// :param T: the configuration struct
class fw_cfg_sink #(type T = int) extends fw_object;

    typedef fw_cfg_sink #(T) this_t;

    // The last value pushed. Read-only.
    T cfg;

    // Creates a sink named ``name`` under ``parent``.
    //
    // :param name: the sink's name
    // :param parent: the owner
    // :returns: the sink
    extern static function this_t create(string name, fw_object parent);

    // Binds the sink to source ``s``, in ``connect()``. ``s`` pushes its
    // value at once.
    //
    // :param s: the source
    extern function void connect(fw_cfg_src #(T) s);

    // Passes this sink up through ``outer``, a sink of the parent: this
    // sink receives what ``outer`` is bound to.
    //
    // :param outer: the parent's sink
    extern function void connect_up(fw_cfg_sink #(T) outer);

    // Adds ``l``, called with the new value after each push to this
    // sink, the first at binding. A sink with no listener pays nothing.
    //
    // :param l: the listener
    extern function void add_listener(fw_cfg_listener_if #(T) l);

endclass
