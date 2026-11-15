# Extern

An **extern** is a component realized by an existing RTL module. It declares
ports and bundles like any component and supplies a **pin map**. It has no
children and no behavior.

The pin map, as data:

- **Module name.** File paths are not in the class: the build system
  supplies sources through filesets, and the module is found by name.
- **Parameters**: `param(name, v)`, where `v` is `fw_value #(T)::of(x)` (a
  value of type `T`: integral, string, enum or packed struct) or
  `fw_type #(T)::get()` (the type `T`, for a `parameter type`). A value may
  be computed from the component's params. Setting one name twice keeps
  the later value. The value carries its type, so a tool writes it as the
  module expects (an enum by its label, a type by name) and can check it.
- **Pins.** For every module pin, exactly one of: a port or bundle member of
  the extern; a tie to a constant (an input pin); open (an output pin).
  Slices and packed-pin slots are reserved for when a wrapped module needs
  them.

## Mapping rules

Entries apply in call order; then the default rule.

1. `pin(name, s)` maps port `s` (a port or bundle member of this extern) to
   pin `name`, replacing any earlier choice for `s`. Naming anything that is
   not a port of this extern is `FW-E-EXT-PORT`, on that object.
2. `prefix(b, pre)` adds a rule for bundle `b`: each member of `b` (each
   leaf port below it, in creation order) not yet mapped maps to `pre` +
   its part, where the part is the member's path within `b` with `.`
   replaced by `_`, unless `rename(member, part)` gave one for that member
   path (`rename("valid", "vld")`, `rename("aw.addr", "awaddr")`).
3. **Default rule.** A port still unmapped maps to the pin with its flattened
   name: its path relative to the extern with `.` replaced by `_` (`in.data`
   maps to `in_data`).
4. `tie(name, value)` ties input pin `name`; `open(name)` leaves output pin
   `name` unconnected.
5. `unused(o)` marks port `o`, or every leaf port of bundle `o`, as having
   no pin: the module does not use it. Rules 2 and 3 skip unused ports, so
   the order of `unused` among the other entries does not matter. It is
   `FW-E-EXT-PORT`, on the object, when `o` is not a port or bundle of this
   extern, when an unused port's effective direction (seen from the
   extern) is `out` or `inout` (its net would have no driver in the
   emitted RTL), or when `pin()` also maps it. A typical use: a monitor of
   `fw_rv_if` wrapping a checker that has no data pin marks `p.data`
   unused.

A pin name used twice, by two ports or by a port and a tie or open, is
`FW-E-EXT-PIN`, on the extern. This needs no module header.

## Header checks

These need the module header, so a static implementation does them; the
reference runtime records the map but cannot check it. Conformance scenarios
that need them are marked `static-only`.

- Every module pin is accounted for exactly once (`FW-E-EXT-PIN`, on the
  extern).
- Every port that is not unused maps to a pin the module has
  (`FW-E-EXT-PORT`, on the port).
- Directions agree (`FW-E-EXT-DIR`, on the port): an `in` port maps to an
  input pin, `out` to an output, `inout` to an inout. Ports are compared
  with their effective direction as seen from the extern.
- Widths agree after the parameter values are applied (`FW-E-EXT-WIDTH`, on
  the port).
- Every parameter set exists in the module and fits it (`FW-E-EXT-PARAM`, on
  the extern): a value for a value parameter, a type for a `parameter
  type`; a string only for a `string` parameter; an enum value only for a
  parameter of an equivalent enum type; otherwise a value assignment-
  compatible with the parameter's type.

## Abstract realization

An extern may extend an abstract component that declares only ports and
params. The creator chooses the realization, RTL or (later) a model, through
a constructor factory in its params ([params](params.md)). This is why
"extern" is an interface the class implements rather than a base class.

The netlist records the map as the component's `extern` object
([netlist](netlist.md)).
