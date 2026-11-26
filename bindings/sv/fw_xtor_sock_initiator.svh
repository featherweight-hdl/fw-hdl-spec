// The base class of an initiator transactor with a request and a response API for bundle type ``B``: it holds the pin
// side, ``pins``, as :sv:class:`fw_bundle`, and the method side, ``s``, a socket
// that provides the request API ``REQ`` and calls the response API ``RSP``,
// and states its role and protocol as static facts of the class. The
// APIs default to those its protocol names (:sv:macro:`fw_protocol_utils`,
// reached through the bundle's :sv:macro:`fw_bundle_utils`). The subclass
// implements the API it provides, and registers with
// :sv:macro:`fw_xtor_utils`::
//
//     class axi4_initiator extends fw_xtor_sock_initiator #(axi4_bundle)
//             implements axi4_req_if;
//         `fw_xtor_utils(axi4_initiator)
//         ...                      // s.get_if() delivers each response
//     endclass
//
// Written as ordinary SV, like the domain kinds: its members are its
// definition, the same in every tool.
//
// :param B: the bundle type
// :param REQ: the request API, which the transactor implements
// :param RSP: the response API, which the transactor calls
virtual class fw_xtor_sock_initiator #(type B = fw_bundle_base,
        type REQ = B::__fw_req_api,
        type RSP = B::__fw_rsp_api) extends fw_component;

    // The pin side, created by ``build`` as ``"pins"``.
    fw_bundle #(B) pins;

    // The method side: the transactor implements ``REQ`` and delivers
    // responses through ``RSP``.
    fw_socket #(RSP, REQ) s;

    // Returns the role: FW_ROLE_INITIATOR.
    //
    // :returns: the role
    static function fw_proto_role_e role();
        return FW_ROLE_INITIATOR;
    endfunction

    // Returns the protocol: ``B``'s.
    //
    // :returns: the protocol's handle
    static function fw_protocol_type protocol();
        return B::__fw_bundle_protocol();
    endfunction

    // Creates ``pins`` and the method side. A subclass that overrides it
    // calls ``super.build()`` first.
    virtual function void build();
        pins = fw_bundle #(B)::create("pins", this);
        s = fw_socket #(RSP, REQ)::create("s", this);
    endfunction

endclass
