// The ready/valid protocol: one request API, ``fw_put_if`` of the payload.
// :sv:class:`fw_rv_if` names it, so every ready/valid bundle carries it.
//
// :param T: the payload type
class fw_rv_proto #(type T = bit) extends fw_protocol;
    typedef fw_rv_proto #(T) this_t;
    // One request API: the initiator puts a ``T``.
    `fw_protocol_param_utils(fw_rv_proto, fw_put_if #(T))
endclass
