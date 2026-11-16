// The base class of every domain kind.
//
// A kind is a class with only static members, which extends
// ``fw_domain_kind`` and uses :sv:macro:`fw_domain_kind_utils`. Unlike the
// rest of the API, a kind's static functions have bodies: they are the
// kind's definition, and a user kind writes its own. A kind declares:
//
// - ``params_t``: an unpacked struct with the domain's properties and its
//   derivation. It has a member ``from``, a queue of
//   :sv:class:`fw_domain_base`: the domain's sources of the same kind, from
//   which relations are computed. Everything else in it is the kind's.
// - ``root()``, returning the ``params_t`` of a domain with no sources,
//   and one static function per derivation, returning a ``params_t``.
// - ``pin_attr_t`` and ``pin_default()``: the attributes of a domain pin or
//   a driven net (a reset's polarity). A 1-bit member named ``active_low``
//   is the polarity: emission connects a sink pin whose ``active_low``
//   differs from its net's to an inverted net.
// - ``severity(r)``: the default severity of a crossing with relation
//   ``r``.
// - ``physical()``: 1 when a domain is a 1-bit net when realized, 0 for a
//   marker kind.
// - ``port_name(assoc, attr)``: the name of a generated module port for
//   association ``assoc`` (``""`` for the default).
//
// This class declares each of them, for a marker kind with no properties.
// A kind that redeclares ``params_t`` also redeclares ``root``, and one that
// redeclares ``pin_attr_t`` also redeclares ``pin_default`` and
// ``port_name``::
//
//     class macro_kind extends fw_domain_kind;
//         `fw_domain_kind_utils(macro_kind)
//         static function fw_severity_e severity(fw_domain_rel_e r);
//             return (r == FW_DOMAIN_SAME) ? FW_SEV_NONE : FW_SEV_INFO;
//         endfunction
//     endclass
virtual class fw_domain_kind;

    // The derivations of a kind with only root domains.
    typedef enum { ROOT } deriv_e;

    // A domain's properties: its derivation and its sources.
    typedef struct {
        deriv_e        deriv;
        fw_domain_base from[$];
    } params_t;

    // A domain pin's attributes: none. SV has no empty struct, so it has
    // one unused member.
    typedef struct { bit unused; } pin_attr_t;

    // Returns the params of a domain with no sources.
    //
    // :returns: the params
    static function params_t root();
        params_t p;
        p.deriv = ROOT;
        return p;
    endfunction

    // Returns the attributes a domain pin has when the map gives none.
    //
    // :returns: the attributes
    static function pin_attr_t pin_default();
        pin_attr_t a;
        return a;
    endfunction

    // Returns the default severity of a crossing with relation ``r``: none
    // within a domain, information between related domains, a warning
    // between unrelated ones.
    //
    // :param r: the relation
    // :returns: the severity
    static function fw_severity_e severity(fw_domain_rel_e r);
        case (r)
            FW_DOMAIN_SAME:    return FW_SEV_NONE;
            FW_DOMAIN_RELATED: return FW_SEV_INFO;
            default:           return FW_SEV_WARNING;
        endcase
    endfunction

    // Returns 0: a domain of this kind is a marker, never a net.
    //
    // :returns: whether the kind has a physical form
    static function bit physical();
        return 0;
    endfunction

    // Returns the name of a generated port. A marker kind has none.
    //
    // :param assoc: the association's name, ``""`` for the default
    // :param attr: the port's attributes
    // :returns: the port name
    static function string port_name(string assoc, pin_attr_t attr);
        return "";
    endfunction

endclass
