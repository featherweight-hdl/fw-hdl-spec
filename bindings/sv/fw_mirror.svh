// The target role of bundle type ``B``: member directions are flipped.
//
// A mixin: it extends ``B``, so members are reached directly (``in.valid``)
// and the role is part of the static type.
//
// :param B: the bundle type, a subclass of :sv:class:`fw_bundle_base`
class fw_mirror #(type B = fw_bundle_base) extends B;

    // This class, for out-of-block method bodies.
    typedef fw_mirror #(B) this_t;

    // Creates the bundle, then calls its ``build``.
    //
    // :param name: the bundle name
    // :param parent: the owning component, or the bundle it is a member of
    // :returns: the new bundle
    extern static function this_t create(string name, fw_object parent);

    // Connects this target to a sibling's initiator, member by member. Valid
    // only in the connect phase, :sv:func:`fw_component::connect`.
    //
    // :param other: the initiator
    extern function void connect(fw_bundle #(B) other);

    // Pass-through: connects a child's target to its parent's target. The
    // child side calls it (``u.in.connect_up(in)``). Valid only in the
    // connect phase.
    //
    // :param outer: the parent's target
    extern function void connect_up(fw_mirror #(B) outer);

endclass
