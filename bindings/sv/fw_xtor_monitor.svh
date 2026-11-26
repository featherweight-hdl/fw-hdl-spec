// The base class of a monitor transactor for bundle type ``B``: it holds the
// pin side, ``pins``, as :sv:class:`fw_monitor`, and states its role and
// protocol as static facts of the class. The subclass adds the method
// side (its endpoints) and registers with :sv:macro:`fw_xtor_utils`::
//
//     class my_xtor extends fw_xtor_monitor #(my_bundle);
//         `fw_xtor_utils(my_xtor)
//         virtual function void build();
//             super.build();      // creates pins
//             ...
//         endfunction
//     endclass
//
// Written as ordinary SV, like the domain kinds: its members are its
// definition, the same in every tool.
//
// :param B: the bundle type; it names its protocol with
//     :sv:macro:`fw_bundle_utils`
virtual class fw_xtor_monitor #(type B = fw_bundle_base) extends fw_component;

    // The pin side, created by ``build`` as ``"pins"``.
    fw_monitor #(B) pins;

    // Returns the role: FW_ROLE_MONITOR.
    //
    // :returns: the role
    static function fw_proto_role_e role();
        return FW_ROLE_MONITOR;
    endfunction

    // Returns the protocol: ``B``'s.
    //
    // :returns: the protocol's handle
    static function fw_protocol_type protocol();
        return B::__fw_bundle_protocol();
    endfunction

    // Creates ``pins``. A subclass that overrides it calls
    // ``super.build()`` first.
    virtual function void build();
        pins = fw_monitor #(B)::create("pins", this);
    endfunction

endclass
