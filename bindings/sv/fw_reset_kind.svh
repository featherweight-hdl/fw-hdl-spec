// The reset kind. A reset domain is a root reset, or is derived from other
// reset domains; resets derived from one root are related. A reset
// domain has a style, the kind of flop it is meant for (``ASYNC`` or
// ``SYNC``), and may name the clock it is synchronous to.
//
// Polarity belongs to nets and pins, not to the domain: a driver states
// its net's polarity, each sink pin states the polarity it expects
// (:sv:func:`fw_reset_kind::active_low`), and emission inverts where they
// differ. A generated port is named ``rst`` or ``<assoc>_rst``, with
// ``_n`` appended when it is active low.
//
// Use its domains through :sv:type:`fw_reset_domain`::
//
//     por = fw_reset_domain::create("por", this);
//     rst = fw_reset_domain::create("rst", this,
//               fw_reset_kind::synced(por, .clock(clk)));
class fw_reset_kind extends fw_domain_kind;

    // Returns the kind's handle. (The expansion of
    // :sv:macro:`fw_domain_kind_utils`, written out.)
    //
    // :returns: the handle
    static function fw_domain_kind_type get_type();
        return fw_domain_kind_type_of #(fw_reset_kind)::get();
    endfunction

    // How a reset domain is derived.
    typedef enum { ROOT, SYNCED, COMBINED, SOFTWARE } deriv_e;

    // The kind of flop a reset is meant for. ``ANY`` is used only by pins:
    // a pin that accepts either.
    typedef enum { ASYNC, SYNC, ANY } style_e;

    // A reset domain's properties. ``from`` holds the source resets;
    // ``clock`` is the clock domain the reset is synchronous to, or
    // ``null``. The clock is not a source.
    typedef struct {
        deriv_e        deriv;
        fw_domain_base from[$];
        fw_domain_base clock;
        style_e        style;
    } params_t;

    // A reset pin's or net's attributes: its polarity and, for a sink pin,
    // the style it requires.
    typedef struct {
        bit     active_low;
        style_e style;
    } pin_attr_t;

    // A root reset.
    //
    // :param style: the style
    // :param clock: the clock domain it is synchronous to, or ``null``
    // :returns: the params
    static function params_t root(style_e style = ASYNC, fw_domain_base clock = null);
        params_t p;
        p.deriv = ROOT;
        p.clock = clock;
        p.style = style;
        return p;
    endfunction

    // ``from``, synchronized to ``clock``: asserted with ``from``,
    // deasserted on ``clock``.
    //
    // :param from: the source reset domain
    // :param clock: the clock domain
    // :param style: the style
    // :returns: the params
    static function params_t synced(fw_domain_base from, fw_domain_base clock,
                                    style_e style = ASYNC);
        params_t p = root(style, clock);
        p.deriv = SYNCED;
        p.from.push_back(from);
        return p;
    endfunction

    // A reset asserted when any of ``from`` is.
    //
    // :param from: the source reset domains
    // :param style: the style
    // :param clock: the clock domain it is synchronous to, or ``null``
    // :returns: the params
    static function params_t combined(fw_domain_base from[$], style_e style = ASYNC,
                                      fw_domain_base clock = null);
        params_t p = root(style, clock);
        p.deriv = COMBINED;
        p.from = from;
        return p;
    endfunction

    // A reset that software asserts, and that ``from`` also asserts.
    //
    // :param from: the source reset domain
    // :param clock: the clock domain of the register that asserts it
    // :param style: the style
    // :returns: the params
    static function params_t software(fw_domain_base from, fw_domain_base clock = null,
                                      style_e style = ASYNC);
        params_t p = root(style, clock);
        p.deriv = SOFTWARE;
        p.from.push_back(from);
        return p;
    endfunction

    // An active-low pin or net.
    //
    // :param style: the style a sink pin requires
    // :returns: the attributes
    static function pin_attr_t active_low(style_e style = ANY);
        pin_attr_t a;
        a.active_low = 1;
        a.style = style;
        return a;
    endfunction

    // An active-high pin or net.
    //
    // :param style: the style a sink pin requires
    // :returns: the attributes
    static function pin_attr_t active_high(style_e style = ANY);
        pin_attr_t a;
        a.active_low = 0;
        a.style = style;
        return a;
    endfunction

    // Returns the attributes a reset pin has when the map gives none:
    // active high, any style.
    //
    // :returns: the attributes
    static function pin_attr_t pin_default();
        return active_high();
    endfunction

    // Returns the default severity of a reset crossing: none within a
    // domain, a warning between related resets, an error between unrelated
    // ones.
    //
    // :param r: the relation
    // :returns: the severity
    static function fw_severity_e severity(fw_domain_rel_e r);
        case (r)
            FW_DOMAIN_SAME:    return FW_SEV_NONE;
            FW_DOMAIN_RELATED: return FW_SEV_WARNING;
            default:           return FW_SEV_ERROR;
        endcase
    endfunction

    // Returns 1: a reset domain is a net when realized.
    //
    // :returns: 1
    static function bit physical();
        return 1;
    endfunction

    // Returns the name of a generated reset port: ``rst`` or
    // ``<assoc>_rst``, with ``_n`` when active low.
    //
    // :param assoc: the association's name, ``""`` for the default
    // :param attr: the port's attributes
    // :returns: the port name
    static function string port_name(string assoc, pin_attr_t attr);
        string n = (assoc == "") ? "rst" : {assoc, "_rst"};
        return attr.active_low ? {n, "_n"} : n;
    endfunction

endclass
