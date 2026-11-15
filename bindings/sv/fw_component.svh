// The base class of every component.
//
// A component creates its children, signals, ports and bundles in its
// build phase, :sv:func:`fw_component::build`, and makes its connections in
// its connect phase, :sv:func:`fw_component::connect`. Each phase runs
// top-down: a component before its children, children in creation order.
//
// Every component has params. One with params of its own declares, inside
// the class:
//
// - ``params_t``, an unpacked struct whose members have no defaults;
// - ``mk_params``, a static function with one defaulted argument per field:
//   the one source of defaults;
// - :sv:macro:`fw_component_params` or :sv:macro:`fw_component_params_init`,
//   which declare the resolved value ``params``.
//
// A component without params of its own inherits ``params_t`` and
// ``mk_params`` from its base class; a subclass never redeclares them. A
// concrete component adds :sv:macro:`fw_component_utils`, which declares
// its ``create``::
//
//     class fifo #(type T = bit[7:0]) extends fw_component;
//         typedef struct { int depth; } params_t;
//         static function params_t mk_params(int depth = 2);
//             params_t p;
//             p.depth = depth;
//             return p;
//         endfunction
//         `fw_component_params
//         `fw_component_utils(fifo #(T))
//
//         fw_input #(bit) clk;
//
//         virtual function void build();
//             clk = fw_input #(bit)::create("clk", this);
//         endfunction
//     endclass
//
//     u = fifo #(T)::create("u", this, fifo #(T)::mk_params(.depth(4)));
virtual class fw_component extends fw_object;

    // The params of a component without params of its own: empty. SV has no
    // empty struct, so it has one unused member.
    typedef struct { bit unused; } params_t;

    // Returns the default params value.
    //
    // :returns: the default ``params_t``
    extern static function params_t mk_params();

    // The build phase: creates this component's children, signals, ports
    // and bundles, and registers params overrides for the subtree. Empty by
    // default. Creating a structural object after the build phase is an
    // error (``FW-E-ELAB-LATE``).
    extern virtual function void build();

    // The connect phase: connects and ties the ports and signals of this
    // component and of its direct children. Empty by default. Connecting or
    // tying anywhere else is an error (``FW-E-CONN-PHASE``).
    extern virtual function void connect();

    // Connects each pair, as if by calling ``connect`` on it. Valid only in
    // the connect phase::
    //
    //     connect_all('{ '{u[0].out, u[1].in},
    //                    '{u[1].out, out},
    //                    '{in,       u[0].in} });
    //
    // The compiler does not check the pairs' types; elaboration does, with
    // the same diagnostics as ``connect``.
    //
    // :param pairs: the pairs to connect
    extern function void connect_all(fw_pair_t pairs[]);

endclass
