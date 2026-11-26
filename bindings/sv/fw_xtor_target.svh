// The base class of a target transactor with one API for bundle type ``B``: it holds the pin
// side, ``pins``, as :sv:class:`fw_mirror`, and the method side, ``p``, a port of
// the request API ``API``, which it calls for each request,
// and states its role and protocol as static facts of the class. The
// APIs default to those its protocol names (:sv:macro:`fw_protocol_utils`,
// reached through the bundle's :sv:macro:`fw_bundle_utils`). The subclass
// implements the API it provides, and registers with
// :sv:macro:`fw_xtor_utils`::
//
//     class wb_target extends fw_xtor_target #(wb_bundle);
//         `fw_xtor_utils(wb_target)
//         virtual task run();   // calls p.get_if().access(...)
//         ...
//     endclass
//
// Written as ordinary SV, like the domain kinds: its members are its
// definition, the same in every tool.
//
// :param B: the bundle type
// :param API: the request API, which the transactor calls
virtual class fw_xtor_target #(type B = fw_bundle_base,
        type API = B::__fw_req_api) extends fw_component;

    // The pin side, created by ``build`` as ``"pins"``.
    fw_mirror #(B) pins;

    // The method side: where each request goes. Not created when the
    // protocol has no request API.
    fw_port #(API) p;

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
        fw_api_type api = fw_api_type_of #(API)::get(), none = fw_api_type_of #(fw_no_api)::get();
        pins = fw_mirror #(B)::create("pins", this);
        if (api != none) p = fw_port #(API)::create("p", this);
    endfunction

endclass
