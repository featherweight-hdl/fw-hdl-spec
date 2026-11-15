# Elaboration

Normative semantics of fw-hdl layer 1. Binding-neutral: the SV spelling is in
`bindings/sv`. Related: [signals](signals.md), [bundles](bundles.md),
[connections](connections.md), [extern](extern.md), [params](params.md),
[diagnostics](diagnostics.md), [netlist](netlist.md).

## Objects and names

- Every structural object (component, signal, port, bundle) has a **name**
  and a **parent**. Only the top component has no parent.
- The **full name** (path) is the parent's full name, `.`, then the name.
  Bundle members are named through their bundle: `top.u0.out.valid`. The
  conformance runners create the top with the name `top`.
- A name is an SV identifier, optionally followed by one or more `[index]`
  suffixes with a decimal index, for array elements: `u[0]`, `p[1][2]`.
  Anything else is `FW-E-NAME-BAD`.
- Names are unique among the children of one parent (`FW-E-NAME-DUP`, on the
  second object).
- A **scope** is the component that owns an object: for a signal or port,
  its parent component; for a bundle member, the component that owns the
  outermost bundle.
- An object rejected at creation (a bad or duplicate name, late creation) is
  not in the tree: it is not in the netlist, and objects created under it,
  and connections to it, are ignored without further diagnostics.

## Creation

Every structural object is created through the factory: components,
signals, ports and bundles.

- The creation call names the type, the instance name, the parent and, for a
  component, optionally a params value. It is one call; there is no
  separate step to set parameters.
- The factory supplies the name, parent and params to the new object before
  its constructor body runs, so constructors take no arguments.
- An object constructed any other way is `FW-E-ELAB-NEW` when it is first
  used by the API: as a parent, as a connection or tie endpoint, or (a
  component with params) when its params would be resolved. The diagnostic
  names the component whose phase method (or constructor) was running.
- The netlist records each object's created type.

In layer 1 the factory creates exactly the type asked for. A realization is
chosen at build time by a constructor factory in the creator's params
([params](params.md)). The factory is where later layers attach type
substitution; because no user code calls `new` on a structural class,
adding it changes no user code.

## Phases

1. **Construct the top** through the factory. Its params are resolved like
   any other component's.
2. **Build, top-down.** `build()` runs on a component, then on each of its
   child components in creation order, each recursively. Children, signals,
   ports and bundles are created in `build()` or in a constructor. A
   bundle's members are created when the bundle is (its type's `build()`).
   Params overrides are registered in `build()` or a constructor, before
   the components they target are created.
3. **End of build.** Every override that matched no component is
   `FW-W-PARAM-UNUSED`.
4. **Connect, top-down**, in the same order. Connections and ties are made
   only here (`FW-E-CONN-PHASE` otherwise); every port of every child exists
   by now. Creating a structural object here or later is `FW-E-ELAB-LATE`.
5. **Resolve.** The implementation records every extern's pin map, forms
   the nets of every scope ([connections](connections.md)), and runs every
   check, reporting *all* errors, not only the first.
6. **Frozen.** After resolution the structure is immutable. If any `FW-E-`
   diagnostic was reported, elaboration fails.

Every implementation produces the same tree, nets and diagnostics for the
same input; the conformance suite checks this through the
[netlist](netlist.md). How an implementation walks the phases is its own
business: the reference runtime executes the code, the static front end
interprets it.
