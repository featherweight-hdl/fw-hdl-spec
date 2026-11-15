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
