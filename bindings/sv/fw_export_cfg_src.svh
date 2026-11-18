// A :sv:class:`fw_export` that carries configuration. It sources the
// configuration ``CFG``: its owner sets it, a device from its configuration
// registers. A :sv:class:`fw_port_cfg_sink` of the same ``API`` and ``CFG``
// connects to it.
//
// :param API: the API interface class
// :param CFG: the configuration struct
class fw_export_cfg_src #(type API = int, type CFG = int) extends fw_object;

    typedef fw_export_cfg_src #(API, CFG) this_t;

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
    extern function void connect_up(fw_export_cfg_src #(API, CFG) outer);

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
