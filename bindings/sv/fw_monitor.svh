// The monitor role of bundle type ``B``: every member is an input, and it
// drives nothing.
//
// A mixin: it extends ``B``, so members are reached directly (``p.valid``)
// and the role is part of the static type.
//
// :param B: the bundle type, a subclass of :sv:class:`fw_bundle_base`
class fw_monitor #(type B = fw_bundle_base) extends B;

    // This class, for out-of-block method bodies.
    typedef fw_monitor #(B) this_t;

    // Creates the bundle, then calls its ``build``.
    //
    // :param name: the bundle name
    // :param parent: the owning component, or the bundle it is a member of
    // :returns: the new bundle
    extern static function this_t create(string name, fw_object parent);

    // Taps a bundle of the same type in either role: each member of the
    // monitor is a sink on the tapped member's net. Valid only in the
    // connect phase, :sv:func:`fw_component::connect`.
    //
    // :param other: the initiator or target to tap
    extern function void connect(B other);

endclass
