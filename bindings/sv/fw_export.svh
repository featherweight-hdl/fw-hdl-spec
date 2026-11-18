// The provided side of a method-level API: the component that owns it
// implements ``API``, normally with a derived ``<api>_imp``.
//
// :param API: the API interface class
class fw_export #(type API = int) extends fw_object;

    typedef fw_export #(API) this_t;

    // Creates an export named ``name`` under ``parent``. If ``parent``
    // implements ``API``, it is the implementation, with no further call.
    //
    // :param name: the export's name
    // :param parent: the owner
    // :returns: the export
    extern static function this_t create(string name, fw_object parent);

    // Sets the implementation that the export provides, when it is not
    // the parent (a member object, say). Overrides the derived one.
    //
    // :param imp: the implementation
    extern function void set_imp(API imp);

    // Provides ``outer``, an export of the parent, with this export.
    //
    // :param outer: the parent's export
    extern function void connect_up(fw_export #(API) outer);

endclass
