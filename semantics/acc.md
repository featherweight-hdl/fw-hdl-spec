# acc: access to types and values

acc ("access") is optional run-time access to a design's types and values
(SV binding: `fw_acc.svh`, part of `fw_hdl_pkg`). It serves testing, debug
and reporting: visibility, not modeling.

- **Optional by registration.** A static front end generates accessors
  from its view of the source; they register with `fw_acc`. With none
  registered, every query returns null and a report has no text for that
  name or value (display text, or `null` in a netlist).
- **Elaboration never uses it.** An implementation keeps typed values while
  it elaborates (a component's params value after each source, a domain's
  params, pin attributes, extern parameter values) and asks acc for their
  text only when it reports them. Whether accessors are registered never
  changes elaboration, its diagnostics or its structure.
- **Separate from the description.** Nothing in a design, the modeling
  classes or their macros refers to acc; generated accessors are kept
  apart from the user's description.
- **No lookup by text.** Accessors are found by type (`fw_acc_value_of #(T)`)
  or by `$cast` (`fw_acc::component`, the most derived registered class
  that accepts the object), never by a type's name.
- **What it gives:** a type's canonical spelling ([netlist](netlist.md)); a
  value's text (JSON, as the netlist writes values) and its top-level
  fields; an extern parameter's value as SV literal text; a component's
  params and, for each field a source set, the last source that set it
  (`param_src`, [params](params.md)); an fw object's path; a constructor
  factory's realization.

acc's text is informative, except where the [netlist](netlist.md) makes
value text normative: a run-time implementation's `params`, `param_src`,
domain `params`, `attr`, `provides` and extern parameter values are
compared in conformance, so its acc text for them must follow the
netlist's rules.
