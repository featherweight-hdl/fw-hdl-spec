// The handle of API ``API``, an interface class. A protocol registers its
// APIs with it, in ``declare()``::
//
//     d.api(fw_api_type_of #(fw_put_if #(uart_char_t))::get(), FW_PROTO_REQ);
//
// :param API: the API interface class, with its parameters
class fw_api_type_of #(type API = int) extends fw_api_type;

    typedef fw_api_type_of #(API) this_t;

    // Returns the one handle of ``API``.
    //
    // :returns: the handle
    extern static function this_t get();

endclass
