// fw_hdl_macros.svh: the user-facing macros of fw_hdl_pkg.
//
// The macro names, arguments and the members they declare are API. A tool
// provides its own fw_hdl_macros.svh with its expansions; an expansion may
// declare only the members documented here, plus names beginning `__fw_`.
// The expansions below are the minimum that compiles.
//
// The macros are orthogonal: one pair is about creation, the other about
// params. An abstract component with params uses only a params macro, its
// realizations use only a creation macro, and a concrete component with
// params uses both.
`ifndef FW_HDL_MACROS_SVH
`define FW_HDL_MACROS_SVH

// Declares ``create`` for concrete component ``T``. Every concrete component
// uses it (an extern uses :sv:macro:`fw_extern_utils` instead)::
//
//     static function T create(string name, fw_component parent,
//                              params_t p = mk_params());
//
// ``create`` makes a ``T`` named ``name`` under ``parent``, with params value
// ``p`` from the creator. The value is resolved against overrides before
// the constructor body runs; see :sv:class:`fw_param_override`.
//
// :param T: the class, with its parameters: ``fifo #(T)``
`define fw_component_utils(T) \
    typedef T __fw_self_t; \
    static function T create(string name, fw_component parent, \
                             params_t p = mk_params()); \
        T obj = new(); \
        return obj; \
    endfunction

// Declares ``create`` for concrete extern ``T``, as
// :sv:macro:`fw_component_utils` does, and implements
// :sv:func:`fw_extern_if::extern_module`::
//
//     virtual function string extern_module();    // returns MODULE
//
// :param T: the class, with its parameters
// :param MODULE: the RTL module's name, a string literal
`define fw_extern_utils(T, MODULE) \
    `fw_component_utils(T) \
    virtual function string extern_module(); \
        return MODULE; \
    endfunction

// Declares the resolved params value, in the class that declares
// ``params_t``::
//
//     params_t params;
//
// ``params`` is available from the start of the declaring class's
// constructor, and is read-only: writing it is an error
// (``FW-E-PARAM-WRITE``).
`define fw_component_params \
    params_t params;

// As :sv:macro:`fw_component_params`, for a class with a params-init
// function. ``FN`` runs last in params resolution, after the creator's value
// and every override. It fills in defaults that cannot be constants, such as
// a null constructor factory, and never changes a field already set::
//
//     `fw_component_params_init(init_params)
//
//     static function void init_params(ref params_t p);
//         if (p.fifo_h == null)
//             p.fifo_h = fw_ctor_of #(fifo_api #(T), rv_fifo #(T))::get();
//     endfunction
//
// :param FN: a static function of the class taking ``ref params_t``
`define fw_component_params_init(FN) \
    params_t params;

// Declares ``get_type`` for domain kind ``T``. Every kind uses it::
//
//     static function fw_domain_kind_type get_type();
//
// ``get_type`` returns the kind's handle, one object per kind: the key for
// associations, and the way code that does not know ``T`` reaches its
// rules. See :sv:class:`fw_domain_kind`.
//
// :param T: the kind class
`define fw_domain_kind_utils(T) \
    static function fw_domain_kind_type get_type(); \
        return fw_domain_kind_type_of #(T)::get(); \
    endfunction

// As :sv:macro:`fw_component_utils`, for a parameterized component ``C``
// that declares its own specialization as ``this_t``::
//
//     class fifo #(type T = bit) extends fw_component;
//         typedef fifo #(T) this_t;
//         `fw_component_param_utils(fifo)
//
// :param C: the class's bare name, without parameters
`define fw_component_param_utils(C) \
    `fw_component_utils(this_t)

// Declares ``get_type`` for protocol class ``C``, which has no
// parameters, and names its APIs. Every protocol uses it or
// :sv:macro:`fw_protocol_param_utils`::
//
//     static function fw_protocol_type get_type();
//
// ``get_type`` returns the protocol's handle, one object per class; see
// :sv:class:`fw_protocol`. ``REQ`` is the request API, called by the
// initiating side; ``RSP`` the response API, called back on it. A
// direction with no API is left out, or given as :sv:class:`fw_no_api`.
// The same API for both is ``FW-E-PROTO-API``. One API may belong to many
// protocols.
//
// :param C: the class's name
// :param REQ: the request API (an interface class, with its parameters)
// :param RSP: the response API
`define fw_protocol_utils(C, REQ=fw_hdl_pkg::fw_no_api, RSP=fw_hdl_pkg::fw_no_api) \
    typedef REQ __fw_req_api; \
    typedef RSP __fw_rsp_api; \
    static function fw_protocol_type get_type(); \
        return fw_protocol_type_of #(C)::get(`"C`"); \
    endfunction

// As :sv:macro:`fw_protocol_utils`, for a parameterized protocol class
// ``C`` that declares its own specialization as ``this_t``. ``C`` is used
// only as the family's name: inside the class, the bare name is the
// default specialization, not the current one::
//
//     class rv_proto #(int W = 8) extends fw_protocol;
//         typedef rv_proto #(W) this_t;
//         `fw_protocol_param_utils(rv_proto, fw_put_if #(logic [W-1:0]))
//
// :param C: the class's bare name, without parameters
// :param REQ: the request API
// :param RSP: the response API
`define fw_protocol_param_utils(C, REQ=fw_hdl_pkg::fw_no_api, RSP=fw_hdl_pkg::fw_no_api) \
    typedef REQ __fw_req_api; \
    typedef RSP __fw_rsp_api; \
    static function fw_protocol_type get_type(); \
        return fw_protocol_type_of #(this_t)::get(`"C`"); \
    endfunction

// Sets the prefix of a protocol's derived names, when its class name does
// not end in ``_proto``. Inside the protocol class, after its utils macro::
//
//     class link extends fw_protocol;
//         `fw_protocol_utils(link, link_if)
//         `fw_protocol_prefix("lnk")
//
// :param S: the prefix, a string literal
`define fw_protocol_prefix(S) \
    localparam string __fw_prefix = S;

// Declares ``create`` for transactor (or monitor) ``C``, as
// :sv:macro:`fw_component_utils` does, and registers ``C`` with its
// protocol. ``C`` extends :sv:class:`fw_xtor_initiator`,
// :sv:class:`fw_xtor_target` or :sv:class:`fw_xtor_monitor`, whose static
// ``protocol()`` and ``role()`` say what it is registered as.
//
// :param C: the class, without parameters
`define fw_xtor_utils(C) \
    `fw_component_utils(C)

// As :sv:macro:`fw_xtor_utils`, for a parameterized transactor ``C`` that
// declares its own specialization as ``this_t``::
//
//     class axi4_initiator_xtor #(type P = axi4_cfg)
//             extends fw_xtor_initiator #(axi4_if #(P));
//         typedef axi4_initiator_xtor #(P) this_t;
//         `fw_xtor_param_utils(axi4_initiator_xtor)
//
// :param C: the class's bare name, without parameters
`define fw_xtor_param_utils(C) \
    `fw_component_param_utils(C)

// Declares ``create`` for abstractor ``C``, as
// :sv:macro:`fw_component_utils` does, and registers ``C`` as a converter
// from protocol ``FROM`` (the lower level) to protocol ``TO``.
//
// :param C: the class, without parameters
// :param FROM: the lower protocol class, with its parameters
// :param TO: the upper protocol class, with its parameters
`define fw_abstractor_utils(C, FROM, TO) \
    `fw_component_utils(C) \
    static function fw_protocol_type __fw_abs_from(); \
        return FROM::get_type(); \
    endfunction \
    static function fw_protocol_type __fw_abs_to(); \
        return TO::get_type(); \
    endfunction

// As :sv:macro:`fw_abstractor_utils`, for a parameterized abstractor ``C``
// that declares its own specialization as ``this_t``.
//
// :param C: the class's bare name, without parameters
// :param FROM: the lower protocol class, with its parameters
// :param TO: the upper protocol class, with its parameters
`define fw_abstractor_param_utils(C, FROM, TO) \
    `fw_abstractor_utils(this_t, FROM, TO)

// Registers bundle class ``C`` with protocol ``PROTO``: the bundle is a
// physical form of ``PROTO``, in any role (the role is the mixin:
// fw_bundle, fw_mirror or fw_monitor). A protocol may have several bundle
// forms and names none of them. A parameterized bundle passes its bare
// name and ``PROTO`` with the bundle's parameters::
//
//     virtual class wb_bundle extends fw_bundle_base;
//         `fw_bundle_utils(wb_bundle, wb_proto)
//
//     virtual class fw_rv_if #(type T = bit) extends fw_bundle_base;
//         `fw_bundle_utils(fw_rv_if, fw_rv_proto #(T))
//
// :param C: the bundle class's bare name, without parameters
// :param PROTO: the protocol class, with its parameters
`define fw_bundle_utils(C, PROTO) \
    typedef PROTO __fw_proto; \
    typedef __fw_proto::__fw_req_api __fw_req_api; \
    typedef __fw_proto::__fw_rsp_api __fw_rsp_api; \
    static function fw_protocol_type __fw_bundle_protocol(); \
        return PROTO::get_type(); \
    endfunction

// Declares a combinational block that calls method ``name`` of the
// enclosing component, for a component with more than one: each block is a
// process of its own, as if a separate class implemented
// :sv:class:`fw_comb_if` (one ``always_comb`` each in fe-sv). ``name`` is a
// ``function void name()`` of the component. The component uses a creation
// macro (:sv:macro:`fw_component_utils` or one built on it)::
//
//     `fw_comb(next_state)
//     `fw_comb(outputs)
//
// :param name: the method's name
`define fw_comb(name) \
    class __fw_comb_``name implements fw_comb_if; \
        __fw_self_t __fw_p; \
        function new(__fw_self_t p); __fw_p = p; endfunction \
        virtual function void comb(); __fw_p.name(); endfunction \
    endclass \
    __fw_comb_``name __fw_comb_``name``_i = new(this);

// As :sv:macro:`fw_comb`, for a clocked block (:sv:class:`fw_step_if`,
// one ``always_ff`` each in fe-sv). A component whose interfaces are in
// two clock domains writes one block per domain::
//
//     `fw_step(wr_side)
//     `fw_step(rd_side)
//
// :param name: the method's name
`define fw_step(name) \
    class __fw_step_``name implements fw_step_if; \
        __fw_self_t __fw_p; \
        function new(__fw_self_t p); __fw_p = p; endfunction \
        virtual function void step(); __fw_p.name(); endfunction \
    endclass \
    __fw_step_``name __fw_step_``name``_i = new(this);

`endif // FW_HDL_MACROS_SVH
