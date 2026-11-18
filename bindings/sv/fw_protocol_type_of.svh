// The handle of protocol class ``P``: what ``P::get_type()`` returns
// (:sv:macro:`fw_protocol_utils`). The first ``get`` runs
// ``P::declare()``.
//
// :param P: the protocol class, with its parameters
class fw_protocol_type_of #(type P = fw_protocol) extends fw_protocol_type;

    typedef fw_protocol_type_of #(P) this_t;

    // Returns the one handle of ``P``. Called only by the registration
    // macros, which stringify the class name; user code calls
    // ``P::get_type()`` and never writes the family string.
    //
    // :param family: ``P``'s class name, without parameters
    // :returns: the handle
    extern static function this_t get(string family);

endclass
