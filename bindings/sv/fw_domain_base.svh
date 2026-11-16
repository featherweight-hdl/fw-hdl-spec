// A domain object of any kind: the base of :sv:class:`fw_domain`.
//
// A domain object is a structural object, named and created in the build
// phase like a port, but it is not a signal, port or child component. Code
// that does not know the kind holds it by this class: a kind's derivation
// names its sources as ``fw_domain_base`` handles.
virtual class fw_domain_base extends fw_object;

    // Returns the kind of this domain.
    //
    // :returns: the kind's handle
    extern function fw_domain_kind_type kind();

endclass
