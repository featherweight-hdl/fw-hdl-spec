// A :sv:class:`fw_socket` that carries configuration. It sources the
// configuration ``CFG``: its owner sets it, a device from its configuration
// registers. Its peer is ``fw_socket_cfg_sink #(IN, OUT, CFG)``; any other
// connection does not compile.
//
// :param OUT: the API it calls
// :param IN: the API it provides
// :param CFG: the configuration struct
class fw_socket_cfg_src #(type OUT = int, type IN = int, type CFG = int) extends fw_object;

    typedef fw_socket_cfg_src #(OUT, IN, CFG) this_t;

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
    extern function void connect(fw_socket_cfg_sink #(IN, OUT, CFG) peer);

    // Passes this socket up through ``outer``, a socket of the parent with
    // the same role.
    //
    // :param outer: the parent's socket
    extern function void connect_up(fw_socket_cfg_src #(OUT, IN, CFG) outer);

    // As :sv:func:`fw_socket::set_imp`.
    //
    // :param imp: the implementation
    extern function void set_imp(IN imp);

    // As :sv:func:`fw_socket::get_if`.
    //
    // :returns: the implementation, or null when it resolves to none
    extern function OUT get_if();

    // Sets the configuration and pushes it to every sink this source
    // reaches. A source keeps the value and pushes it at binding, so a
    // ``set`` in ``build()`` reaches every sink.
    //
    // :param v: the value
    extern function void set(CFG v);

    // Returns the last value set.
    //
    // :returns: the value
    extern function CFG get();

endclass
