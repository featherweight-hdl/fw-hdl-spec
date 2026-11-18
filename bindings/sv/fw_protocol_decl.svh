// What a protocol's ``declare()`` registers with: its APIs, and a prefix
// when the derived one does not fit. See :sv:class:`fw_protocol`.
class fw_protocol_decl;

    // Registers API ``h`` for direction ``dir``. A protocol has at most one
    // API per direction (``FW-E-PROTO-API``).
    //
    // :param h: the API's handle, ``fw_api_type_of #(API)::get()``
    // :param dir: the direction
    extern function void api(fw_api_type h, fw_proto_dir_e dir);

    // Sets the prefix of the protocol's derived names, when the protocol's
    // class name does not end in ``_proto``.
    //
    // :param s: the prefix
    extern function void prefix(string s);

endclass
