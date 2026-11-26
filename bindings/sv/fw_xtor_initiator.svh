// The base class of an initiator transactor with one API for bundle type ``B``: it holds the pin
// side, ``pins``, as :sv:class:`fw_bundle`, and the method side, ``t``, an export of
// the request API ``API``,
// and states its role and protocol as static facts of the class. The
// APIs default to those its protocol names (:sv:macro:`fw_protocol_utils`,
// reached through the bundle's :sv:macro:`fw_bundle_utils`). The subclass
// implements the API it provides, and registers with
// :sv:macro:`fw_xtor_utils`::
//
//     class wb_initiator extends fw_xtor_initiator #(wb_bundle) implements wb_if;
//         `fw_xtor_utils(wb_initiator)
//         virtual task access(...);   // wb_if
//         ...
//     endclass
//
// Written as ordinary SV, like the domain kinds: its members are its
// definition, the same in every tool.
//
// :param B: the bundle type
// :param API: the request API, which the transactor implements
virtual class fw_xtor_initiator #(type B = fw_bundle_base,
        type API = B::__fw_req_api) extends fw_component;

    // The pin side, created by ``build`` as ``"pins"``.
    fw_bundle #(B) pins;

    // The method side: the transactor implements ``API``. Not created
    // when the protocol has no request API.
    fw_export #(API) t;

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
        fw_api_type api = fw_api_type_of #(API)::get(), none = fw_api_type_of #(fw_no_api)::get();
        pins = fw_bundle #(B)::create("pins", this);
        if (api != none) t = fw_export #(API)::create("t", this);
    endfunction

endclass
