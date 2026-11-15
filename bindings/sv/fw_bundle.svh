// The initiator role of bundle type ``B``: members keep their declared
// directions.
//
// A mixin: it extends ``B``, so members are reached directly (``out.valid``)
// and the role is part of the static type. Connecting two initiators, or
// bundles of different types, does not compile.
//
// :param B: the bundle type, a subclass of :sv:class:`fw_bundle_base`
class fw_bundle #(type B = fw_bundle_base) extends B;

    // This class, for out-of-block method bodies.
    typedef fw_bundle #(B) this_t;

    // Creates the bundle, then calls its ``build``.
    //
    // :param name: the bundle name
    // :param parent: the owning component, or the bundle it is a member of
    // :returns: the new bundle
    extern static function this_t create(string name, fw_object parent);

    // Connects this initiator to a sibling's target, member by member. Valid
    // only in the connect phase, :sv:func:`fw_component::connect`.
    //
    // :param other: the target
    extern function void connect(fw_mirror #(B) other);

    // Pass-through: connects a child's initiator to its parent's initiator.
    // The child side calls it (``u.out.connect_up(out)``). Valid only in the
    // connect phase.
    //
    // :param outer: the parent's initiator
    extern function void connect_up(fw_bundle #(B) outer);

endclass
