# Parameters

There are two ways to parameterize a component; the split keeps class
(template) parameters to a minimum.

| Kind | Set by | Used for |
|---|---|---|
| **Class parameters**: value parameters (scalars or struct *shapes*), plus type parameters where a payload type is generic | the type name, at compile time | physical type shape only: anything that reaches a signal's or bundle's type |
| **Params value**: a struct per component | the creator, procedurally, and overrides | everything else: counts, depths, modes, child parameters, extern parameters, conditional structure, realization choice |

A value that reaches a signal's type must be a class parameter. Group widths
into one struct-valued class parameter (a shape) rather than many scalars.

## The params value

- A component with params declares a struct type `params_t` (members without
  defaults) and a params function `mk_params` with one defaulted argument
  per field: the one source of defaults.
- Every component has params: one without params of its own inherits the
  empty value of the base component. The netlist writes `params: {}` for
  it.
- A subclass inherits its parent's `params_t` and `mk_params` and redeclares
  neither, so every realization of an abstract component takes the same
  params.
- The resolved value is available, read-only, from the start of the
  constructor of the class that declares `params_t`. Writing it is
  `FW-E-PARAM-WRITE` (detected by the static front end, on the component).

## Constructor factories

A params field may hold a constructor factory: a typed handle that creates
some realization of base type `B`. The component creates through it instead
of naming a class. Its default in `mk_params` is null; an optional
**params-initialization function** (`init_params`), named when the params
are declared, runs last in resolution and fills defaults that cannot be
constants, such as the default realization. By rule it changes only fields
still null or at another sentinel.

- Using a factory that is still null is `FW-E-PARAM-NULL`, on the component
  whose code used it (static front end; in a simulator it is a null
  dereference).
- A factory whose realization is not a subclass of the expected base is
  `FW-E-PARAM-CTOR`. In the SV binding this is a compile error.
- The netlist writes a factory as the canonical type of the realization it
  creates, or null.

## Resolution

A component's params value is computed when it is created, from these
sources in order; each sees the result of the ones before:

1. `default`: the value of `mk_params()` with no arguments;
2. `creator`: the value the creator passed (when it passed none, the
   default again);
3. `override`: overrides registered by ancestors, nearest ancestor first,
   farthest last, so the outermost has the last word; within one
   registering component, in registration order (a later one wins);
4. `global`: global overrides, in registration order;
5. `init`: the params-initialization function, if any.

**Field sources.** The netlist's `param_src` names, for each field, the last
source whose step changed that field's value (compared field by field, by
netlist value). A field no step changed is absent, even if the creator
passed it explicitly with its default value.

## Overrides

An override is registered by a component (or globally, with no component)
and has three parts:

- **Target**: a path glob. For a registered override it is relative to the
  registering component and matches only strict descendants; a global
  override's glob is matched against full paths. Segments are separated by
  `.`; `*` matches any characters within one segment (`u[*]`); a `**`
  segment matches zero or more whole segments (`**`, `mid.**`, `top.**`).
- **Params type**: the override applies only to components whose params type
  is the override's type, exactly (a realization inherits its base's
  `params_t`, so an override for the base's params type applies to it).
- **Action**: *set* replaces the whole value; *edit* is a function from value
  to value.

An override that matches a component already created when it is registered
is `FW-E-PARAM-LATE`, on that component. An override that matches nothing by
the end of build is `FW-W-PARAM-UNUSED`, on the registering component (path
`""` for a global override).
