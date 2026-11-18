// fw_hdl_api.svh: the declarations of fw_hdl_pkg: layer 1, domains,
// processes and protocols. Included inside package fw_hdl_pkg (see
// fw_hdl_pkg.sv).
//
// Rules for a tool:
// - Include this file unchanged and supply a body for every `extern`
//   method, out of block. Add nothing else to API classes.
// - A tool's state for an object hangs off fw_object::__fw_impl: an object
//   of the tool's own class implementing fw_impl_if, which the bodies
//   downcast to.
// - Names beginning `__fw_` are reserved for the API and its macros.
//
// The recipe for users: declare fields with the API classes, and create
// anything with T::create:
//     clk = fw_input #(bit)::create("clk", this);
//     u   = fifo #(T)::create("u", this, fifo #(T)::mk_params(.depth(4)));

typedef class fw_object;
typedef class fw_component;
typedef class fw_bundle;
typedef class fw_mirror;
typedef class fw_pin_rule;

// A pair of objects to connect: two ports or signals, or two bundles in
// roles. :sv:func:`fw_component::connect_all` takes a list of them.
typedef fw_object fw_pair_t[2];

// The relation of two domains of one kind: the same domain object; related
// (they share a root domain through their sources); or unrelated. See
// :sv:func:`fw_domain::relate`.
typedef enum { FW_DOMAIN_SAME, FW_DOMAIN_RELATED, FW_DOMAIN_UNRELATED } fw_domain_rel_e;

// The severity of a domain crossing. ``FW_SEV_NONE`` is not a crossing.
typedef enum { FW_SEV_NONE, FW_SEV_INFO, FW_SEV_WARNING, FW_SEV_ERROR } fw_severity_e;

`include "fw_impl_if.svh"

`include "fw_object.svh"
`include "fw_component.svh"
`include "fw_ctor.svh"
`include "fw_ctor_of.svh"
`include "fw_param_edit.svh"
`include "fw_param_override.svh"

`include "fw_signal_base.svh"
`include "fw_signal.svh"
`include "fw_input.svh"
`include "fw_output.svh"
`include "fw_inout.svh"

`include "fw_bundle_base.svh"
`include "fw_bundle.svh"
`include "fw_mirror.svh"
`include "fw_monitor.svh"

`include "fw_param_arg.svh"
`include "fw_value.svh"
`include "fw_type.svh"
`include "fw_pin_rule.svh"
`include "fw_extern_map.svh"
`include "fw_extern_if.svh"

`include "fw_domain_kind_type.svh"
`include "fw_domain_base.svh"
`include "fw_domain_kind.svh"
`include "fw_domain_kind_type_of.svh"
`include "fw_domain.svh"
`include "fw_clock_kind.svh"
`include "fw_reset_kind.svh"

// A clock domain: :sv:class:`fw_domain` of :sv:class:`fw_clock_kind`.
typedef fw_domain #(fw_clock_kind) fw_clock_domain;

// A reset domain: :sv:class:`fw_domain` of :sv:class:`fw_reset_kind`.
typedef fw_domain #(fw_reset_kind) fw_reset_domain;

`include "fw_step_if.svh"
`include "fw_comb_if.svh"
`include "fw_run_if.svh"
`include "fw_reset_state_if.svh"
`include "fw_time.svh"

typedef class fw_protocol;
typedef class fw_protocol_type;
typedef class fw_api_type;
typedef class fw_export;
typedef class fw_cfg_src;
typedef class fw_export_cfg_src;
typedef class fw_export_cfg_sink;
typedef class fw_socket_cfg_src;
typedef class fw_socket_cfg_sink;

// The direction of a protocol's API: the request, from the initiator, or
// the response, from the target. See :sv:func:`fw_protocol_decl::api`.
typedef enum { FW_PROTO_REQ, FW_PROTO_RSP } fw_proto_dir_e;

// The role a bundle or a transactor plays in a protocol.
typedef enum { FW_ROLE_INITIATOR, FW_ROLE_TARGET, FW_ROLE_MONITOR } fw_proto_role_e;

// A list of protocol handles, as :sv:func:`fw_api_type::protocols` returns.
typedef fw_protocol_type fw_protocol_type_q[$];

// A list of API handles, as :sv:func:`fw_protocol_type::apis` returns.
typedef fw_api_type fw_api_type_q[$];

// A list of names, as :sv:func:`fw_protocol_type::bundles` returns.
typedef string fw_string_q[$];

// A list of component constructors, as
// :sv:func:`fw_protocol_type::abstractors` returns.
typedef fw_ctor #(fw_component) fw_component_ctor_q[$];

`include "fw_protocol_family.svh"
`include "fw_api_type.svh"
`include "fw_protocol_type.svh"
`include "fw_protocol_decl.svh"
`include "fw_protocol.svh"
`include "fw_api_type_of.svh"
`include "fw_protocol_type_of.svh"
`include "fw_port.svh"
`include "fw_export.svh"
`include "fw_socket.svh"
`include "fw_cfg_listener_if.svh"
`include "fw_cfg_src.svh"
`include "fw_cfg_sink.svh"
`include "fw_port_cfg_src.svh"
`include "fw_port_cfg_sink.svh"
`include "fw_export_cfg_src.svh"
`include "fw_export_cfg_sink.svh"
`include "fw_socket_cfg_src.svh"
`include "fw_socket_cfg_sink.svh"
