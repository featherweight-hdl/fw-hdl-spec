# Signals and ports

- A **signal** carries a value of a packed type `T`: `bit`/`logic` vectors,
  packed structs, packed unions or enums. The default is `bit`. Its width is
  `$bits(T)`. Unpacked and class types are not signals.
- A **local signal** belongs to a component and is not visible outside it:
  only its own component may connect it ([connections](connections.md)). In
  emitted RTL it is a net inside the module.
- A **port** is a signal on the component boundary, with a declared
  direction: `in`, `out` or `inout`. In emitted RTL it is a module port.
- A port declared inside a bundle has a declared direction relative to the
  bundle's initiator; its **effective** direction is computed along the path
  ([bundles](bundles.md)).
- **Arrays.** A signal, port or bundle may be created as `N` elements of one
  type, named `p[0]`..`p[N-1]`. Each element is an object of its own.
- **Types** are compared by SV type equivalence (IEEE 1800-2017 6.22.2): a
  typedef of `bit [7:0]` is `bit [7:0]`. The netlist spells types
  canonically (see [netlist](netlist.md)).

## Clock and reset

Layer 1 has no clock or reset classes. A clock or reset pin of wrapped RTL
is an ordinary 1-bit input port, connected explicitly like any other. The
domain layer replaces this. It maps clock and reset pins through its own
classes and adds no methods to the extern map. There is no implicit clock
or reset connection.

## Reserved (layer 2)

Signal values (`read()`, `write(v)`) and their timing come with processes in
layer 2. Reading will be legal on every direction, writing an effective
input illegal. A tool keeps value storage behind the object's implementation
handle, so adding them adds methods but changes no layer-1 declaration.
