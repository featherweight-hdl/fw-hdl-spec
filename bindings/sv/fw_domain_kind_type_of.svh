// The handle of kind ``T``: what ``T::get_type()`` returns
// (:sv:macro:`fw_domain_kind_utils`). It forwards
// :sv:func:`fw_domain_kind_type::severity` and
// :sv:func:`fw_domain_kind_type::physical` to ``T``'s static functions.
//
// :param T: the kind class
class fw_domain_kind_type_of #(type T = fw_domain_kind) extends fw_domain_kind_type;

    typedef fw_domain_kind_type_of #(T) this_t;

    // Returns the one handle of ``T``.
    //
    // :returns: the handle
    extern static function this_t get();

    // Returns ``T``'s canonical type spelling.
    //
    // :returns: the name
    extern virtual function string name();

    // Returns ``T::severity(r)``.
    //
    // :param r: the relation
    // :returns: the severity
    virtual function fw_severity_e severity(fw_domain_rel_e r);
        return T::severity(r);
    endfunction

    // Returns ``T::physical()``.
    //
    // :returns: whether the kind has a physical form
    virtual function bit physical();
        return T::physical();
    endfunction

endclass
