// The base class of a target transactor with a request and a response API for bundle type ``B``: it holds the pin
// side, ``pins``, as :sv:class:`fw_mirror`, and the method side, ``s``, a socket
// that calls the request API ``REQ`` and provides the response API ``RSP``,
// and states its role and protocol as static facts of the class. The
// APIs default to those its protocol names (:sv:macro:`fw_protocol_utils`,
// reached through the bundle's :sv:macro:`fw_bundle_utils`). The subclass
// implements the API it provides, and registers with
// :sv:macro:`fw_xtor_utils`::
//
//     class axi4_target extends fw_xtor_sock_target #(axi4_bundle)
//             implements axi4_rsp_if;
//         `fw_xtor_utils(axi4_target)
//         ...                      // s.get_if() passes each request on
//     endclass
//
// Written as ordinary SV, like the domain kinds: its members are its
// definition, the same in every tool.
//
// :param B: the bundle type
// :param REQ: the request API, which the transactor calls
// :param RSP: the response API, which the transactor implements
virtual class fw_xtor_sock_target #(type B = fw_bundle_base,
        type REQ = B::__fw_req_api,
        type RSP = B::__fw_rsp_api) extends fw_component;

    // The pin side, created by ``build`` as ``"pins"``.
    fw_mirror #(B) pins;

    // The method side: the transactor passes each request on through
    // ``REQ`` and implements ``RSP``.
    fw_socket #(REQ, RSP) s;

    // Returns the role: FW_ROLE_TARGET.
    //
    // :returns: the role
    static function fw_proto_role_e role();
        return FW_ROLE_TARGET;
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
        pins = fw_mirror #(B)::create("pins", this);
        s = fw_socket #(REQ, RSP)::create("s", this);
    endfunction

endclass
