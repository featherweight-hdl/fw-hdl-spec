// The required side of a method-level API: a component calls ``API``'s
// methods through it. Created through the factory and connected in
// ``connect()``, as signals are; an unbound port is an error
// (``FW-E-SOCK-UNBOUND``).
//
// :param API: the API interface class
class fw_port #(type API = int) extends fw_object;

    typedef fw_port #(API) this_t;

    // Creates a port named ``name`` under ``parent``.
    //
    // :param name: the port's name
    // :param parent: the owner
    // :returns: the port
    extern static function this_t create(string name, fw_object parent);

    // Binds this port to ``exp``. A port binds once (``FW-E-SOCK-MULTI``).
    //
    // :param exp: the export that provides the API
    extern function void connect(fw_export #(API) exp);

    // Passes this port up through ``outer``, a port of the parent.
    //
    // :param outer: the parent's port
    extern function void connect_up(fw_port #(API) outer);

    // The implementation this port reaches: through any ``connect_up``
    // chain to an export, then inward to the export that has one. Call
    // the API's methods on it, after the connect phase.
    //
    // :returns: the implementation, or null when the port resolves to none
    extern function API get_if();

endclass
