// The handle of API ``API``, an interface class: the key the tools use
// for the APIs a protocol names in :sv:macro:`fw_protocol_utils`.
//
// :param API: the API interface class, with its parameters
class fw_api_type_of #(type API = int) extends fw_api_type;

    typedef fw_api_type_of #(API) this_t;

    // Returns the one handle of ``API``.
    //
    // :returns: the handle
    extern static function this_t get();

endclass
