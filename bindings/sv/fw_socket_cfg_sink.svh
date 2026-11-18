// A :sv:class:`fw_socket` that carries configuration. It sinks the
// configuration ``CFG``: its owner reads ``cfg``, a copy the source pushes,
// and may listen for changes. A sink that no source reaches is ``FW-E-CFG-
// UNBOUND``. Its peer is ``fw_socket_cfg_src #(IN, OUT, CFG)``; any other
// connection does not compile.
//
// :param OUT: the API it calls
// :param IN: the API it provides
// :param CFG: the configuration struct
class fw_socket_cfg_sink #(type OUT = int, type IN = int, type CFG = int) extends fw_object;

    typedef fw_socket_cfg_sink #(OUT, IN, CFG) this_t;

    // The last value pushed. Read-only (``FW-E-CFG-WRITE``).
    CFG cfg;

    // Creates a socket named ``name`` under ``parent``.
    //
    // :param name: the endpoint's name
    // :param parent: the owner
    // :returns: the endpoint
    extern static function this_t create(string name, fw_object parent);

    // Connects this socket to ``peer``, in both directions, and the
    // configuration from source to sink. A socket binds once
    // (``FW-E-SOCK-MULTI``).
    //
    // :param peer: the peer socket
    extern function void connect(fw_socket_cfg_src #(IN, OUT, CFG) peer);

    // Passes this socket up through ``outer``, a socket of the parent with
    // the same role.
    //
    // :param outer: the parent's socket
    extern function void connect_up(fw_socket_cfg_sink #(OUT, IN, CFG) outer);

    // As :sv:func:`fw_socket::set_imp`.
    //
    // :param imp: the implementation
    extern function void set_imp(IN imp);

    // As :sv:func:`fw_socket::get_if`.
    //
    // :returns: the implementation, or null when it resolves to none
    extern function OUT get_if();

    // Adds ``l``, called with the new value after each push to this
    // sink, the first at binding. A sink with no listener pays nothing.
    //
    // :param l: the listener
    extern function void add_listener(fw_cfg_listener_if #(CFG) l);

endclass
