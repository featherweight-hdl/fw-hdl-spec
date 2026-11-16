// A domain kind's handle: one object per kind, returned by the kind's
// ``get_type()`` (:sv:macro:`fw_domain_kind_utils`).
//
// The handle is the kind's identity: the key for associations, and the way
// code that does not know the kind class ``K`` statically reaches its
// rules::
//
//     fw_domain_kind_type k = fw_clock_kind::get_type();
virtual class fw_domain_kind_type;

    // Returns the kind's name: the kind class's canonical type spelling,
    // as the netlist writes it (``fw_clock_kind``).
    //
    // :returns: the name
    pure virtual function string name();

    // Returns the default severity of a crossing between two domains of
    // this kind with relation ``r``.
    //
    // :param r: the relation of the two domains
    // :returns: the severity; ``FW_SEV_NONE`` is not a crossing
    pure virtual function fw_severity_e severity(fw_domain_rel_e r);

    // Returns 1 when a domain of this kind is a 1-bit net when realized,
    // 0 for a marker kind, which is never realized.
    //
    // :returns: whether the kind has a physical form
    pure virtual function bit physical();

endclass
