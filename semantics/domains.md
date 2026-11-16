# Domains

Normative semantics of the domain layer, on top of layer 1. Binding-neutral:
the SV spelling is in `bindings/sv` (`fw_domain.svh`, the kind classes).
Related: [elaboration](elaboration.md), [connections](connections.md),
[extern](extern.md), [diagnostics](diagnostics.md), [netlist](netlist.md).

A **domain** is a structural marker on components and interfaces: the clock
a block runs on, the reset it obeys. It is declared once, associated with
the parts of the tree it covers, and found by lookup. A domain becomes a net
only when something uses it physically: an extern pin mapped to it, or a
signal driving it.

## Kinds

- A **kind** is a class that extends `fw_domain_kind`, has only static
  members, and declares `get_type()` with `` `fw_domain_kind_utils(T) ``.
  `get_type()` returns the kind's **handle**, one object per kind. The
  handle is the kind's identity: the key of every association, and its
  name in the netlist is the kind class's canonical type spelling
  (`fw_clock_kind`).
- A kind declares, as static members: `params_t` (the domain's properties
  and derivation, with a member `from`: the domain's sources of the same
  kind); `root()` and one function per derivation, each returning a
  `params_t`; `pin_attr_t` and `pin_default()`; `severity(r)`;
  `physical()`; `port_name(assoc, attr)`. `fw_domain_kind` declares each
  for a marker kind with no properties, so a kind redeclares only what it
  changes.
- A kind's static functions are ordinary code with bodies, in the spec for
  the library kinds and in user code for a user kind. A kind defined only
  in user code is associated, looked up, checked at connections and listed
  in the netlist like a library kind.
- A kind is **physical** when `physical()` is 1: its domains are 1-bit nets
  when realized. A **marker kind** (`physical()` 0) never has a net.
- The library kinds are `fw_clock_kind` and `fw_reset_kind`, below.

## Domain objects

- `fw_domain #(K)::create(name, parent, p = K::root())` creates a domain
  object of kind `K` with params `p`, under component `parent`, in the
  build phase. It is a structural object: named like a port
  (`FW-E-NAME-BAD`, `FW-E-NAME-DUP` among the parent's children, ports and
  signals), and `FW-E-ELAB-LATE` when created after the build phase. It is
  not a signal, port or child component.
- **Sources.** `p.from` lists the domain's sources of kind `K`. A source
  that is not a domain of kind `K` is `FW-E-DOM-KIND`; a `null` source is
  `FW-E-DOM-NONE`. Both stop the call: the domain is not created, and the
  diagnostic names the full name it would have had. A domain with no
  sources is a **root domain**.
- A kind may name domains of other kinds in its params (a reset's `clock`).
  They are not sources. `fw_reset_kind` requires its `clock` to be a clock
  domain or `null` (`FW-E-DOM-KIND`).

## Association

Associations are made per kind `K`, by `fw_domain #(K)::set(obj, dom, name
= "")`, in the build phase of the **calling component** (the component whose
`build()` is running):

- `obj` is a direct child of the calling component, created before the
  call; or the calling component itself; or a port, or a bundle in a role,
  of the calling component. A bundle is one interface: setting a member of
  a bundle is `FW-E-DOM-OBJ`. Any other `obj` (a grandchild, a child's
  port, a sibling) is `FW-E-DOM-OBJ`, on `obj`.
- `name` is `""` for the **default association**; any other name makes a
  **named association**, which only a component has (`FW-E-DOM-OBJ` on an
  interface).
- The same object, kind and name set twice is `FW-E-DOM-BIND`, on the
  object. Outside the build phase, `FW-E-DOM-PHASE`, on the object. Each
  stops the call.

Since build runs top-down, a parent's associations on a child are made
before the child's `build()` runs.

## Lookup

`fw_domain #(K)::get(obj, name = "")` returns the domain `obj` resolves to,
for kind `K`:

- a component's **default**: its own default association; else its
  parent's default, resolved the same way, up to the top; else `null`.
- a component's **named** association `name`: its own association of that
  name; else the component's resolved default.
- an **interface** (a port or bundle in a role): its own association; else
  that of each enclosing bundle, innermost first; else its component's
  resolved default. `name` must be `""` (`FW-E-DOM-OBJ`).

`get` is legal in any phase and reads the associations made so far.
Reading a component's named association marks it **read**. A named
association that was never read by the end of elaboration (after the
extern maps) is `FW-E-DOM-UNUSED`, on the component.

`null` is legal until something needs the domain: `relate`, an extern pin,
`drive` on it. Those report `FW-E-DOM-NONE`, on the object that needed it.

## Relation

`fw_domain #(K)::relate(a, b)` returns:

- `FW_DOMAIN_SAME` when `a` and `b` are the same domain object;
- `FW_DOMAIN_RELATED` when they share a root domain: the root domains
  reached from each by following `from`, transitively, intersect;
- `FW_DOMAIN_UNRELATED` otherwise.

The relation depends only on the domains' declarations, so it is available
in `build()`, and every implementation and pass computes the same one. A
`null` argument is `FW-E-DOM-NONE`, on the calling component, and the call
returns `FW_DOMAIN_UNRELATED`.

## Drivers and realization

A **driver** produces a domain's net. There are two:

- `dom.drive(sig, attr = K::pin_default())`, in the connect phase: `sig`
  is the net. `sig` is a port or local signal of the calling component, or
  a port of one of its direct children (`FW-E-CONN-SCOPE` otherwise, on
  `sig`). `attr` is the net's attributes: a reset's polarity.
- `fw_domain #(K)::pin_out(m, name, dom, attr = K::pin_default())`, in an
  extern map: the module's output pin `name` is the net.

A domain is **realized** when an extern pin is mapped to it (`pin` or
`pin_out`) or a signal drives it. A domain of a marker kind is never
realized: a pin, `pin_out` or `drive` on one is `FW-E-DOM-PIN`.

Checks, at the end of elaboration:

- A domain with more than one driver is `FW-E-DOM-DRIVER`, on the domain.
- A realized domain with no driver is `FW-E-DOM-NODRIVER`, on the domain.
- `drive` outside the connect phase is `FW-E-DOM-PHASE`, on the domain;
  `sig` wider than 1 bit is `FW-E-DOM-PIN`, on `sig`. Each stops the call.

Drivers do not change relations: those come only from declarations.

A driver component may state the derivation it produces for one of its
associations: `fw_domain #(K)::provides(this, assoc, p)`, in its build
phase. When the domain that `assoc` resolves to has params different from
`p` (compared as their netlist values), it is `FW-E-DOM-DERIV`, on the
component. When it resolves to `null`, there is nothing to check.

`provides` and `port_name` (see Emission) are made by a component about
itself: a `comp` other than the calling component is `FW-E-DOM-OBJ`, and a
call outside the build phase `FW-E-DOM-PHASE`, each on `comp`.

## Extern pins

In `extern_map`:

- `fw_domain #(K)::pin(m, name, dom = null, attr = K::pin_default())` maps
  input pin `name` to `dom`; `null` means the extern's own default of `K`
  (`get(extern)`). `attr` is what the pin expects.
- `fw_domain #(K)::pin_out(m, name, dom, attr = K::pin_default())` maps
  output pin `name` as the driver of `dom` (above). `attr` is the net's.
- A domain that resolves to `null` is `FW-E-DOM-NONE`, on the extern.
- Domain pins are pins of the map: a pin name used twice, by any mix of
  `pin`, `tie`, `open`, the port rules and domain pins, is `FW-E-EXT-PIN`,
  on the extern.
- **Header checks** (static only): a domain pin the module lacks is
  `FW-E-EXT-PIN`; a domain pin whose direction is wrong (`pin` on an
  output, `pin_out` on an input) or that is wider than 1 bit is
  `FW-E-DOM-PIN`. Both on the extern. Domain pins count toward "every
  module pin is accounted for".

## Crossings

A **crossing** is a net whose interface endpoints are in different domains.

- The **interface endpoints** of a net are its endpoints that are ports:
  the scope's own ports and its children's ports, bundle members included.
  Local signals are transparent: two children's ports joined through a
  local signal are one net with two interface endpoints.
- An endpoint's **interface** is its outermost enclosing bundle, or the
  port itself when it is in none. Its domain of kind `K` is `get` of the
  port, for each kind with an association anywhere in the design.
- For each net with a source endpoint, and each other interface endpoint
  on it, and each kind `K` for which both domains are non-null and differ,
  the relation of the two selects the kind's severity. A pair of
  interfaces is reported once per kind, on the lesser of the two interface
  paths (code-point order), whichever nets it spans: `FW-E-DOM-CROSS` for
  an error, `FW-W-DOM-CROSS` for a warning, `FW-I-DOM-CROSS` for
  information; nothing for none.
- An interface whose domain of `K` is `null` is not checked for `K`.
- A component whose interfaces are in different domains is the **crossing
  element**, a synchronizer or a dual-clock FIFO. That is not a crossing:
  crossings are only on nets.
- **Severities** come from the kind's `severity(r)`, and are configurable
  per kind and relation by an elaboration option of each implementation.
  The conformance suite uses the defaults.
- **Waivers.** `fw_domain #(K)::waive(a, b, reason)`, in the connect phase
  of the component whose scope holds the net, waives the crossing of kind
  `K` between interfaces `a` and `b` (in either order). A waived crossing
  is not reported. An empty reason is `FW-E-DOM-WAIVE`; a waiver that
  matches no crossing is `FW-W-DOM-WAIVE`; outside the connect phase,
  `FW-E-DOM-PHASE`. Each on `a`.

## The clock kind

`fw_clock_kind`:

- Derivations: `root()`; `derived(from, div = 1, mul = 1)`; `phase(from,
  deg)`; `gated(from)`; `muxed(from[])`. Each lists its clock sources in
  `from`.
- No pin attributes.
- Severity: same none; related information; unrelated error.
- Physical. Port name `clk`, or `<assoc>_clk`.

## The reset kind

`fw_reset_kind`:

- Params: the derivation and `from`; `clock`, the clock domain the reset is
  synchronous to, or `null` (not a source); `style`, the flop it is meant
  for, `ASYNC` or `SYNC`.
- Derivations: `root(style = ASYNC, clock = null)`; `synced(from, clock,
  style = ASYNC)`; `combined(from[], style = ASYNC, clock = null)`;
  `software(from, clock = null, style = ASYNC)`.
- Pin attributes: `active_low` and `style`; `active_low(style = ANY)` and
  `active_high(style = ANY)` make them. `pin_default()` is active high, any
  style. On `pin` they are what the pin expects; on `pin_out` and `drive`,
  the net's polarity (its style is ignored).
- Severity: same none; related warning; unrelated error.
- Physical. Port name `rst` or `<assoc>_rst`, with `_n` when active low.
- **Polarity** is not a diagnostic: a sink pin that expects the other
  polarity from its net gets an inverted net in the emitted RTL.
- **Style.** A domain pin whose expected style is not `ANY` and differs
  from its domain's style is `FW-W-DOM-STYLE`, on the extern.
- **Synchronization.** A component whose resolved default reset domain has
  a `clock` unrelated to its resolved default clock domain (both non-null)
  is `FW-W-DOM-RSTSYNC`, on the component, when it is the top or its
  parent's pair of resolved domains differs from its own: each place a
  mismatch starts is reported once, not every component below it.

## Emission

Emission is not part of the netlist, but every static implementation emits
the same module interfaces:

- One module per class. An **association is realized in a class** when
  something in the class's subtree realizes a domain through it: an extern
  pin mapped to it, a driver of it, or a child's port or pin whose
  association resolves to it, in any instance of the class and in any
  generated arm or iteration. An association the subtree never reaches is
  not realized, even when it resolves to the same domain as one that is.
- Each realized association with no driver inside the subtree is an
  **input port** of the class's module; each driven inside the subtree (a
  `pin_out` or a `drive` there, or a child's output port) is an **output
  port**. The port is named by `fw_domain #(K)::port_name(this, assoc,
  port)` when the class's code called it, else `K::port_name(assoc,
  attr)`.
- A named association the class reads and its parent does not set is
  still a port; the parent connects it to the domain it falls back to.
- Two associations that resolve to the same domain at an instance are two
  ports; the instantiating module connects both to the domain's net.
- A domain created in a class and realized only inside it is a local net.
- An association is the one the class's code named. When two of them
  give the same domain (`get(this, "wr")` and `get(this)` at an instance),
  the one the code read the domain through is the one realized.
- A reset port's polarity is a property of the class: the polarity its
  subtree's sinks expect when they all agree, else active high. Where a net
  meets a port or pin of the other polarity, the module that makes the
  connection declares one inverted net per domain and uses it for every
  such sink. The polarity is the `pin_attr_t` member `active_low`, so a
  user kind with one is inverted the same way.
- A generated port name that collides with another port of the module is
  `FW-E-DOM-PORTNAME`, on the class's first instance (least path). Ports
  are never renamed silently.
- Marker kinds, and domains never realized, emit nothing.

## Netlist

Domain objects are objects of kind `domain`; associations, drivers, domain
pins, waivers, port names and stated derivations are listed on the objects
that hold them ([netlist](netlist.md)). The domain each object resolves to
is derived, not listed; realization and generated ports are emission, not
netlist.
