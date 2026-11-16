// fw_hdl_api.svh: the declarations of fw_hdl_pkg: layer 1 and domains. Included inside
// package fw_hdl_pkg (see fw_hdl_pkg.sv).
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
`include "fw_rv_if.svh"

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
