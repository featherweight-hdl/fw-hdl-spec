// A :sv:class:`fw_export` that carries configuration. It sinks the
// configuration ``CFG``: its owner reads ``cfg``, a copy the source pushes,
// and may listen for changes. A sink that no source reaches is ``FW-E-CFG-
// UNBOUND``. A :sv:class:`fw_port_cfg_src` of the same ``API`` and ``CFG``
// connects to it.
//
// :param API: the API interface class
// :param CFG: the configuration struct
class fw_export_cfg_sink #(type API = int, type CFG = int) extends fw_object;

    typedef fw_export_cfg_sink #(API, CFG) this_t;

    // The last value pushed. Read-only (``FW-E-CFG-WRITE``).
    CFG cfg;

    // Creates an export named ``name`` under ``parent``.
    //
    // :param name: the endpoint's name
    // :param parent: the owner
    // :returns: the endpoint
    extern static function this_t create(string name, fw_object parent);

    // As :sv:func:`fw_export::set_imp`.
    //
    // :param imp: the implementation
    extern function void set_imp(API imp);

    // Provides ``outer``, an export of the parent with the same role,
    // with this export.
    //
    // :param outer: the parent's export
    extern function void connect_up(fw_export_cfg_sink #(API, CFG) outer);

    // Adds ``l``, called with the new value after each push to this
    // sink, the first at binding. A sink with no listener pays nothing.
    //
    // :param l: the listener
    extern function void add_listener(fw_cfg_listener_if #(CFG) l);

endclass
