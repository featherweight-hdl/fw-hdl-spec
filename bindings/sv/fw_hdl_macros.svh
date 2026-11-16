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

`endif // FW_HDL_MACROS_SVH
