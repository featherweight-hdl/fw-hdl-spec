// A :sv:class:`fw_port` that carries configuration. It sinks the
// configuration ``CFG``: its owner reads ``cfg``, a copy the source pushes,
// and may listen for changes. A sink that no source reaches is ``FW-E-CFG-
// UNBOUND``. It connects only to a :sv:class:`fw_export_cfg_src` of the
// same ``API`` and ``CFG``; any other connection does not compile.
//
// :param API: the API interface class
// :param CFG: the configuration struct
class fw_port_cfg_sink #(type API = int, type CFG = int) extends fw_object;

    typedef fw_port_cfg_sink #(API, CFG) this_t;

    // The last value pushed. Read-only (``FW-E-CFG-WRITE``).
    CFG cfg;

    // Creates a port named ``name`` under ``parent``.
    //
    // :param name: the endpoint's name
    // :param parent: the owner
    // :returns: the endpoint
    extern static function this_t create(string name, fw_object parent);

    // Binds this port to ``exp``, for both the API and the configuration.
    // A port binds once (``FW-E-SOCK-MULTI``).
    //
    // :param exp: the export
    extern function void connect(fw_export_cfg_src #(API, CFG) exp);

    // Passes this port up through ``outer``, a port of the parent with the
    // same role.
    //
    // :param outer: the parent's port
    extern function void connect_up(fw_port_cfg_sink #(API, CFG) outer);

    // As :sv:func:`fw_port::get_if`.
    //
    // :returns: the implementation, or null when the port resolves to none
    extern function API get_if();

    // Adds ``l``, called with the new value after each push to this
    // sink, the first at binding. A sink with no listener pays nothing.
    //
    // :param l: the listener
    extern function void add_listener(fw_cfg_listener_if #(CFG) l);

endclass
