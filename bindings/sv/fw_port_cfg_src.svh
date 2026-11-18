// A :sv:class:`fw_port` that carries configuration. It sources the
// configuration ``CFG``: its owner sets it, a device from its configuration
// registers. It connects only to a :sv:class:`fw_export_cfg_sink` of the
// same ``API`` and ``CFG``; any other connection does not compile.
//
// :param API: the API interface class
// :param CFG: the configuration struct
class fw_port_cfg_src #(type API = int, type CFG = int) extends fw_object;

    typedef fw_port_cfg_src #(API, CFG) this_t;

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
    extern function void connect(fw_export_cfg_sink #(API, CFG) exp);

    // Passes this port up through ``outer``, a port of the parent with the
    // same role.
    //
    // :param outer: the parent's port
    extern function void connect_up(fw_port_cfg_src #(API, CFG) outer);

    // As :sv:func:`fw_port::get_if`.
    //
    // :returns: the implementation, or null when the port resolves to none
    extern function API get_if();

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
