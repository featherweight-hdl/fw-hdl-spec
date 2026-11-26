# Elaborated netlist

The netlist is the normalized JSON form of an elaborated design, defined by
[netlist.schema.json](netlist.schema.json), which is normative for every
string format (type spellings, values, paths) and every ordering rule. It is
the conformance artifact: every implementation's runner produces it and the
suite compares it with each scenario's `expect.json`. It is a specification
artifact, not a tool format; emitted RTL does not depend on it.

Summary of the decisions a second implementation must reproduce:

- **Objects** are every structural object in the tree, sorted by path
  (code-point order). Components carry `params` and `param_src`
  ([params](params.md)) and, for externs, `extern` ([extern](extern.md)).
  Ports carry their *effective* direction seen from their scope
  ([bundles](bundles.md)).
- **Domains** ([domains](domains.md)) are objects of kind `domain`, with
  their params and drivers. The objects that hold them list associations
  (`assoc`), domain pins (`domain_pins`, on the extern), waivers, port
  names and stated derivations; each key appears only when it has
  entries, so a design without domains has none of them. Domain handles
  in a value are written as paths.
- **Protocols** ([protocols](protocols.md)) are a top-level `protocols`
  table keyed by specialization (family, params, APIs with direction,
  bundle types, converters). Bundle instances carry `protocol` and `role`.
  API endpoints and sockets are objects of kind `api_endpoint`;
  configuration sources and sinks of kind `cfg_src` and
  `cfg_sink`. A top-level `bindings` list holds their links: kind
  `api` (port to export) and kind `cfg` (source to sink). A top-level
  `listeners` list holds one record per `add_listener` made in a
  component's phase method: `sink` (the sink or configured endpoint),
  `order` (the call's position on that sink from 0, the order `changed`
  runs in), `scope` (the component that made the call) and `listener`
  (the listening object's path when it is an fw object, such as a
  component or endpoint, else null). A plain object held in a member or
  a local has no path, and a run-time implementation cannot name its
  class, so it is known by sink, order and scope alone. Sorted by sink,
  then order. Each of these appears only when it has entries, so a
  design without protocols has none of them.
- **Types** are spelled canonically: class name without package, every
  parameter value in declaration order including defaults, no spaces;
  vectors as `bit[7:0]`; struct/enum typedefs by name; struct values as
  `'{16,2}`.
- **Nets** are listed per scope, with every key present: `source` (or null),
  `tie` (or null), and sorted `sinks`, `signals`, `inouts`. Sorted by
  scope, then by the least endpoint path.
- **Values** (ties) are `'h` + lowercase hex without leading zeros.
- **Diagnostics** are (id, path) pairs, unique, sorted by path then id.

## Conformance comparison

A scenario's `expect.json` is either a full netlist (it has `objects`),
compared whole, or `{"diagnostics": [...]}`, of which only the diagnostics
are compared. In both cases the elaboration must fail exactly when an
`FW-E-` diagnostic is expected. Canonical text for byte comparison: keys
sorted, two-space indent, a trailing newline (Python
`json.dumps(x, indent=2, sort_keys=True) + "\n"`).

**Type text at run time is informative.** A run-time implementation
(one that elaborates in a simulator) has no portable way to spell a type:
SV's `$typename` and `%p` are informative, tool-specific text, and
nothing in the netlist may depend on them. So for a run-time
implementation the comparison masks **type text**: an object's `type`,
`top`, an object's `protocol`, the `protocols` table's keys and its
records' `family`, `params`, `apis[].type`, `bundles` and converter
`type`/`from`/`to`, domain kind names (`assoc` keys, extern
`domain_pins[].kind`) and an extern parameter's `type`. When the
implementation is given a static front end's names for the design's
types, its type text is canonical and is compared too. **Value text**
(`params`, `param_src`, domain `params`, `attr`, `provides`, extern
parameter values, ties) is always compared: it is formatted from the
types' static structure (field by field), never from `%p`.
