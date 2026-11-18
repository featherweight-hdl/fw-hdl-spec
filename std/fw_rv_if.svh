// The ready/valid bundle type, written from the initiator's view. It
// names the protocol :sv:class:`fw_rv_proto`.
//
// A bundle type is written with the API like a user's, so its
// :sv:func:`fw_rv_if::build` has a body::
//
//     fw_bundle #(fw_rv_if #(T)) out;    // drives valid and data
//     fw_mirror #(fw_rv_if #(T)) in;     // drives ready
//
// :param T: the payload type
virtual class fw_rv_if #(type T = bit) extends fw_bundle_base;
    `fw_bundle_protocol(fw_rv_proto #(T))

    // The initiator has a transfer to offer.
    fw_output #(bit) valid;

    // The target accepts the transfer.
    fw_input  #(bit) ready;

    // The payload.
    fw_output #(T)   data;

    // Creates ``valid``, ``ready`` and ``data``.
    virtual function void build();
        valid = fw_output #(bit)::create("valid", this);
        ready = fw_input  #(bit)::create("ready", this);
        data  = fw_output #(T)  ::create("data",  this);
    endfunction

endclass
