// The ready/valid protocol: one request API, ``fw_put_if`` of the payload.
// :sv:class:`fw_rv_if` names it, so every ready/valid bundle carries it.
//
// :param T: the payload type
class fw_rv_proto #(type T = bit) extends fw_protocol;
    typedef fw_rv_proto #(T) this_t;
    `fw_protocol_param_utils(fw_rv_proto)

    // One request API: the initiator puts a ``T``.
    static function void declare(fw_protocol_decl d);
        d.api(fw_api_type_of #(fw_put_if #(T))::get(), FW_PROTO_REQ);
    endfunction
endclass
