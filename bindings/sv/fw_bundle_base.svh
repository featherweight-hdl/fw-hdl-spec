// The base class of every bundle type.
//
// A bundle type is a named, ordered group of ports and nested bundles. It is
// a virtual class that extends this one, declares its members, and creates
// them in :sv:func:`fw_bundle_base::build`, with directions written from
// the initiator's view (see :sv:class:`fw_rv_if`). It is used only in a
// role: :sv:class:`fw_bundle` (initiator), :sv:class:`fw_mirror` (target)
// or :sv:class:`fw_monitor`.
virtual class fw_bundle_base extends fw_object;

    // Creates the members. The role's ``create`` calls it.
    extern virtual function void build();

endclass
