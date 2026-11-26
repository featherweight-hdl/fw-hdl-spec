// A domain of kind ``K``, and the API that declares, associates, queries
// and realizes domains of that kind. The API is static functions that take
// core objects: nothing is added to components, ports or the pin map.
//
// A component declares domain objects in its build phase and associates
// its children with them; each child reads its own with ``get``. A
// domain is a marker until something uses it physically: an extern pin
// mapped to it, or a signal driving it::
//
//     class top extends fw_component;
//         `fw_component_utils(top)
//         fw_input #(bit)  clk_i, rst_ni;
//         fw_clock_domain  clk;
//         fw_reset_domain  rst;
//         fifo             u;
//
//         virtual function void build();
//             clk_i = fw_input #(bit)::create("clk_i", this);
//             rst_ni = fw_input #(bit)::create("rst_ni", this);
//             clk   = fw_clock_domain::create("clk", this);
//             rst   = fw_reset_domain::create("rst", this,
//                         fw_reset_kind::root(.clock(clk)));
//             fw_clock_domain::set(this, clk);
//             fw_reset_domain::set(this, rst);
//             u = fifo::create("u", this);      // u inherits clk and rst
//         endfunction
//
//         virtual function void connect();
//             clk.drive(clk_i);
//             rst.drive(rst_ni, fw_reset_kind::active_low());
//         endfunction
//     endclass
//
// :param K: the kind class: :sv:class:`fw_clock_kind`,
//     :sv:class:`fw_reset_kind`, or a user kind
class fw_domain #(type K = fw_domain_kind) extends fw_domain_base;

    typedef fw_domain #(K) this_t;
    typedef K::params_t    params_t;
    typedef K::pin_attr_t  pin_attr_t;

    // Creates a domain object named ``name`` under ``parent``, in the build
    // phase. It is named like a port: a duplicate name is
    // ``FW-E-NAME-DUP``, creation after the build phase ``FW-E-ELAB-LATE``.
    // A source in ``p.from`` that is not of kind ``K`` is ``FW-E-DOM-KIND``.
    //
    // :param name: the name
    // :param parent: the component that declares it
    // :param p: its params: ``K::root()`` or a derivation
    // :returns: the domain
    extern static function this_t create(string name, fw_component parent,
                                         params_t p = K::root());

    // Associates ``obj`` with ``dom``, in the build phase:
    //
    // - a direct child, after its ``create``, in the parent's build phase;
    //   or the calling component itself;
    // - a port or a bundle in a role of the calling component. A bundle is
    //   one interface: its members follow it.
    //
    // ``name`` makes a named association, which only a component has; the
    // component's code reads it with ``get(this, name)``. Anything else is
    // ``FW-E-DOM-OBJ``; the same object, kind and name set twice is
    // ``FW-E-DOM-BIND``; outside the build phase, ``FW-E-DOM-PHASE``.
    //
    // :param obj: the component or interface
    // :param dom: the domain
    // :param name: ``""`` for the default association, else its name
    extern static function void set(fw_object obj, this_t dom, string name = "");

    // Returns the domain ``obj`` resolves to: its own association, else
    // (for a named association) its default, else the enclosing bundle's or
    // component's, up to the root. ``null`` when none is set: legal until
    // the domain is needed (``FW-E-DOM-NONE``).
    //
    // :param obj: a component or interface
    // :param name: ``""`` for the default association, else its name
    // :returns: the domain, or ``null``
    extern static function this_t get(fw_object obj, string name = "");

    // Returns the relation of two domains: the same object, related (they
    // share a root through their sources), or unrelated. Available in the
    // build phase, to choose structure. A ``null`` argument is
    // ``FW-E-DOM-NONE``.
    //
    // :param a: a domain
    // :param b: a domain
    // :returns: the relation
    extern static function fw_domain_rel_e relate(this_t a, this_t b);

    // Maps input pin ``name`` of an extern's module to a domain, in
    // :sv:func:`fw_extern_if::extern_map`. The pin counts toward the map's
    // own rules: a pin mapped twice is ``FW-E-EXT-PIN``.
    //
    // :param m: the map
    // :param name: the pin name
    // :param dom: the domain; ``null`` for the extern's own (``get``)
    // :param attr: what the pin expects: a reset's polarity and style
    extern static function void pin(fw_extern_map m, string name, this_t dom = null,
                                    pin_attr_t attr = K::pin_default());

    // Maps output pin ``name`` of an extern's module as the driver of
    // ``dom``, in :sv:func:`fw_extern_if::extern_map`: a clock divider's
    // output, a reset synchronizer's.
    //
    // :param m: the map
    // :param name: the pin name
    // :param dom: the domain the pin drives; usually a named association
    //     of the extern, ``get(this, "out")``
    // :param attr: the net's attributes: a reset's polarity
    extern static function void pin_out(fw_extern_map m, string name, this_t dom,
                                        pin_attr_t attr = K::pin_default());

    // Waives the crossing of kind ``K`` between ``a`` and ``b``, in the
    // connect phase of the component that connects them. An empty reason
    // is ``FW-E-DOM-WAIVE``; a waiver that matches no crossing is
    // ``FW-W-DOM-WAIVE``.
    //
    // :param a: an interface
    // :param b: the interface connected to it
    // :param reason: why the crossing is safe
    extern static function void waive(fw_object a, fw_object b, string reason);

    // Names the module port generated for association ``assoc`` of the
    // calling component's class, in its build phase, in place of
    // ``K::port_name``. It applies to every instance of the class.
    //
    // :param comp: the calling component, ``this``
    // :param assoc: ``""`` for the default association, else its name
    // :param port: the port name
    extern static function void port_name(fw_component comp, string assoc, string port);

    // States the derivation that the calling component produces for
    // association ``assoc``, in its build phase: a divide-by-2 wrapper
    // states that its ``out`` domain is derived from its own, divided by
    // 2. A domain set for ``assoc`` whose derivation differs is
    // ``FW-E-DOM-DERIV``::
    //
    //     fw_clock_domain::provides(this, "out",
    //         fw_clock_kind::derived(fw_clock_domain::get(this), .div(2)));
    //
    // :param comp: the calling component, ``this``
    // :param assoc: the association it drives
    // :param p: the derivation
    extern static function void provides(fw_component comp, string assoc, params_t p);

    // Drives this domain from ``sig``, a 1-bit port or local signal of the
    // calling component, in its connect phase. The domain is realized, and
    // ``sig`` is its net. A second driver is ``FW-E-DOM-DRIVER``.
    //
    // :param sig: the signal
    // :param attr: the net's attributes: a reset's polarity
    extern function void drive(fw_signal_base sig, pin_attr_t attr = K::pin_default());

    // Returns this domain's params.
    //
    // :returns: the params given to ``create``
    extern function params_t params();

    // The operations below are for processes (layer 2): a ``run()`` task
    // waits on its component's domains through them. Each is keyed by
    // ``obj``: the calling component, or one of its own ports or bundles in
    // a role, and acts on the domain ``obj`` resolves to (``get(obj)``).
    // An object of another component is ``FW-E-DOM-OBJ``; a domain that
    // does not resolve is ``FW-E-DOM-NONE``. ``tick`` is for clock domains
    // and the rest for reset domains; any other kind is ``FW-E-DOM-KIND``.
    // Using a domain this way realizes it. fe-sv lowers none of them in a
    // task, and ``in_reset`` only in ``step()`` and ``comb()``.

    // Waits for ``n`` edges of the clock domain of ``obj``, counted from
    // the call, and returns after the last one's update and settle. Edges
    // are counted, not timed: a derived domain's edges are fixed from time
    // 0. A domain with no edges (no net, no ``period``, or a derivation
    // whose edges can't be computed) is ``FW-E-CLOCK-NONE``.
    //
    // :param obj: the calling component, or one of its interfaces
    // :param n: the number of edges, 1 or more
    extern static task tick(fw_object obj, int n = 1);

    // Returns 1 while the reset domain of ``obj`` is asserted.
    //
    // :param obj: the calling component, or one of its interfaces
    // :returns: 1 in reset
    extern static function bit in_reset(fw_object obj);

    // Returns when the reset domain of ``obj`` is not asserted: at once if
    // it is not, else at its deassertion.
    //
    // :param obj: the calling component, or one of its interfaces
    extern static task wait_reset_done(fw_object obj);

    // Returns at the next assertion of the reset domain of ``obj``. A model
    // that restarts on reset waits on it.
    //
    // :param obj: the calling component, or one of its interfaces
    extern static task wait_assert(fw_object obj);

endclass
