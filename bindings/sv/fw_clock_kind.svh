// The clock kind. A clock domain is a root clock, or is derived from
// another clock domain; domains derived from one root are related.
// Clocks have no pin attributes. A generated port is named ``clk``, or
// ``<assoc>_clk`` for a named association.
//
// Like every kind, this is a class with only static members, written as
// ordinary SV (see :sv:class:`fw_domain_kind`). Use its domains through
// :sv:type:`fw_clock_domain`::
//
//     clk  = fw_clock_domain::create("clk", this);
//     div2 = fw_clock_domain::create("div2", this,
//                fw_clock_kind::derived(clk, .div(2)));
class fw_clock_kind extends fw_domain_kind;

    // Returns the kind's handle. (The expansion of
    // :sv:macro:`fw_domain_kind_utils`, written out.)
    //
    // :returns: the handle
    static function fw_domain_kind_type get_type();
        return fw_domain_kind_type_of #(fw_clock_kind)::get();
    endfunction

    // How a clock domain is derived.
    typedef enum { ROOT, DERIVED, PHASE, GATED, MUXED } deriv_e;

    // A clock domain's properties. ``from`` holds the source clocks.
    typedef struct {
        deriv_e        deriv;
        fw_domain_base from[$];
        int            div;
        int            mul;
        int            phase_deg;
    } params_t;

    // A clock pin has no attributes.
    typedef struct { bit unused; } pin_attr_t;

    // A root clock.
    //
    // :returns: the params
    static function params_t root();
        params_t p;
        p.deriv = ROOT;
        p.div = 1;
        p.mul = 1;
        p.phase_deg = 0;
        return p;
    endfunction

    // A clock derived from ``from`` with frequency multiplied by ``mul``
    // and divided by ``div``.
    //
    // :param from: the source clock domain
    // :param div: the divisor
    // :param mul: the multiplier
    // :returns: the params
    static function params_t derived(fw_domain_base from, int div = 1, int mul = 1);
        params_t p = root();
        p.deriv = DERIVED;
        p.from.push_back(from);
        p.div = div;
        p.mul = mul;
        return p;
    endfunction

    // ``from`` shifted by ``deg`` degrees.
    //
    // :param from: the source clock domain
    // :param deg: the phase shift
    // :returns: the params
    static function params_t phase(fw_domain_base from, int deg);
        params_t p = root();
        p.deriv = PHASE;
        p.from.push_back(from);
        p.phase_deg = deg;
        return p;
    endfunction

    // ``from``, gated.
    //
    // :param from: the source clock domain
    // :returns: the params
    static function params_t gated(fw_domain_base from);
        params_t p = root();
        p.deriv = GATED;
        p.from.push_back(from);
        return p;
    endfunction

    // A clock selected from ``from``.
    //
    // :param from: the source clock domains
    // :returns: the params
    static function params_t muxed(fw_domain_base from[$]);
        params_t p = root();
        p.deriv = MUXED;
        p.from = from;
        return p;
    endfunction

    // Returns the attributes of a clock pin: none.
    //
    // :returns: the attributes
    static function pin_attr_t pin_default();
        pin_attr_t a;
        return a;
    endfunction

    // Returns the default severity of a clock crossing: none within a
    // domain, information between related clocks, an error between
    // unrelated ones.
    //
    // :param r: the relation
    // :returns: the severity
    static function fw_severity_e severity(fw_domain_rel_e r);
        case (r)
            FW_DOMAIN_SAME:    return FW_SEV_NONE;
            FW_DOMAIN_RELATED: return FW_SEV_INFO;
            default:           return FW_SEV_ERROR;
        endcase
    endfunction

    // Returns 1: a clock domain is a net when realized.
    //
    // :returns: 1
    static function bit physical();
        return 1;
    endfunction

    // Returns the name of a generated clock port: ``clk``, or
    // ``<assoc>_clk``.
    //
    // :param assoc: the association's name, ``""`` for the default
    // :param attr: the port's attributes
    // :returns: the port name
    static function string port_name(string assoc, pin_attr_t attr);
        return (assoc == "") ? "clk" : {assoc, "_clk"};
    endfunction

endclass
