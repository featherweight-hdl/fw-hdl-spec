# Diagnostics

Each diagnostic has a stable ID (`FW-<E|W|I>-<AREA>-<WHAT>`), a message and
a **path**: the full name of one object, given below for each ID.
Conformance compares (ID, path) pairs, never messages. Each pair is reported
once. `FW-E-` IDs are errors: elaboration fails. `FW-W-` IDs are warnings.
`FW-I-` IDs are information, compared like the others.

Implementations report *all* errors: an error stops only the call that
caused it, and an object rejected at creation is left out of the tree
(its subtree and its connections are then ignored silently).

| ID | Condition | Path |
|---|---|---|
| `FW-E-ELAB-LATE` | structural object created after the build phase | the full name it would have had |
| `FW-E-ELAB-NEW` | structural object not created by the factory, used by the API | the component whose phase method or constructor was running (`""` if none) |
| `FW-E-NAME-BAD` | name is not an identifier with optional `[index]` suffixes | the full name as given |
| `FW-E-NAME-DUP` | duplicate name under one parent | the full name (of the second) |
| `FW-E-NAME-FLAT` | two ports/signals/members of a component flatten to the same name | the one created later |
| `FW-E-PARAM-LATE` | override registered after a target was created | each such target |
| `FW-W-PARAM-UNUSED` | override matched nothing by the end of build | the registering component (`""` for global) |
| `FW-E-PARAM-WRITE` | component writes its params value (static front end) | the component |
| `FW-E-PARAM-NULL` | a null constructor factory is used (static front end) | the component whose code used it |
| `FW-E-PARAM-CTOR` | a constructor factory's realization is not a subclass of its base (SV: compile error) | the component whose params hold it |
| `FW-E-CONN-PHASE` | connect or tie outside `connect()`; `add_listener` outside a phase method (at run time) | the endpoint whose method was called (first of a `connect_all` pair); for `add_listener`, the sink |
| `FW-E-CONN-SCOPE` | endpoint outside the connecting component's scope | that endpoint |
| `FW-E-CONN-TYPE` | non-equivalent value types, different bundle types, or a signal with a bundle | the first endpoint |
| `FW-E-NET-MULTI` | more than one driver (source or tie) on a net | the least path among its sources and tied endpoints |
| `FW-E-NET-UNDRIVEN` | a net with sinks, no driver and no inout | the least sink path |
| `FW-E-IN-OPEN` | a child's effective input on no net of the parent's scope | that port |
| `FW-E-EXT-PIN` | pin name used twice (any implementation); module pin unmapped (header check) | the extern component |
| `FW-E-EXT-PORT` | `pin()` or `unused()` names an object that is not a port (or, for `unused()`, a bundle) of the extern; an unused port is an output or inout, or is also mapped by `pin()`; a port maps to a pin the module lacks (header check) | that object or port |
| `FW-E-EXT-PARAM` | a parameter the module lacks, or a value of the wrong kind or type for it (header check) | the extern component |
| `FW-E-EXT-DIR` | port and pin directions disagree (header check) | the port |
| `FW-E-EXT-WIDTH` | port and pin widths disagree (header check) | the port |
| `FW-E-RT-NONE` | no implementation registered | `""` |

Domains ([domains](domains.md)):

| ID | Condition | Path |
|---|---|---|
| `FW-E-DOM-PHASE` | `set`, `port_name` or `provides` outside the build phase; `drive` or `waive` outside the connect phase | the target, the component, the domain, or the waiver's first interface |
| `FW-E-DOM-BIND` | the same object, kind and name set twice | the target |
| `FW-E-DOM-OBJ` | `set` on an object that is not a direct child, the calling component or one of its interfaces; on a bundle member; a named association on an interface; `port_name` or `provides` on another component | the target |
| `FW-E-DOM-UNUSED` | a named association never read with `get` | the component |
| `FW-E-DOM-NONE` | a needed domain is `null`: a derivation source, an extern pin's domain, an argument of `relate` | the domain being created, the extern, or the calling component |
| `FW-E-DOM-KIND` | a derivation source not of the domain's kind; a reset's `clock` that is not a clock domain | the domain being created |
| `FW-E-DOM-DRIVER` | a domain with more than one driver | the domain |
| `FW-E-DOM-NODRIVER` | a realized domain with no driver | the domain |
| `FW-E-DOM-DERIV` | a stated derivation (`provides`) differs from the domain's | the component |
| `FW-E-DOM-PIN` | a driven signal wider than 1 bit; a pin or driver on a marker kind; a domain pin of the wrong direction or wider than 1 bit (header check) | the signal, or the extern |
| `FW-E-DOM-PORTNAME` | a generated domain port collides with a port of the module (static front end) | the class's first instance |
| `FW-E-DOM-CROSS`, `FW-W-DOM-CROSS`, `FW-I-DOM-CROSS` | a crossing, at its kind's severity for the relation | the lesser of the two interfaces |
| `FW-E-DOM-WAIVE` | a waiver with an empty reason | its first interface |
| `FW-W-DOM-WAIVE` | a waiver that matches no crossing | its first interface |
| `FW-W-DOM-STYLE` | a reset pin's required style differs from its domain's | the extern |
| `FW-W-DOM-RSTSYNC` | a component's reset is synchronous to a clock unrelated to its clock domain | the component where the mismatch starts |

Processes ([processes](processes.md)). A domain operation keyed by another
component's object is `FW-E-DOM-OBJ`, on a domain of the wrong kind
`FW-E-DOM-KIND`, on an unresolved domain `FW-E-DOM-NONE`; each on that
object.

| ID | Condition | Path |
|---|---|---|
| `FW-E-WRITE-IN` | `write()` to an effective input | the signal |
| `FW-E-WRITE-MULTI` | a signal written by more than one block (`step`, `comb`, task code), other than one `step` block and the task code of the same component; a component field written by blocks in two domains | the signal, or the component |
| `FW-E-STEP-DOMAINS` | a `step` block that writes signals of two clock domains | the component |
| `FW-E-COMB-LOOP` | a settle still changing after 64 passes (run time) | each signal changed in the last pass |
| `FW-E-CLOCK-NONE` | `tick` on a clock domain with no edges: no net, no `period`, or a derivation whose edges can't be computed | the object `tick` is keyed by |
| `FW-E-CLOCK-PERIOD` | a computed edge time (`mul` > 1, `phase`) that isn't a whole number of the time precision | the domain |
| `FW-E-RUN-SYNC-ACCESS` | task code touching a signal that is not its component's own or a direct child's port (static) | the signal |
| `FW-E-XING-DRIVE-TWICE` | a second task write of a crossing port sampled by the same edge (run time; ignored) | the signal |
| `FW-E-XING-SIDE` | a task-sync crossing's sync side used other than by its owner's sync code, or `take`/`give` outside a `step` block; its process side used from sync code | the crossing |
| `FW-E-XING-COMB` | `take` or `give` in a `comb` block | the crossing |
| `FW-E-EMIT-RUN` | a component that implements `run()` asked to be emitted (static front end) | the component |
| `FW-E-XING-LOWER` | a task-sync crossing use the static front end can't lower to ready/valid ports (processes.md, "Lowering") | the component |
| `FW-E-EMIT-TIME` | `fw_time` or a waiting domain operation in a lowered process (static front end) | the component |

Protocols ([protocols](protocols.md)). An endpoint bound outside
`connect()` is `FW-E-CONN-PHASE`; a crossing on a method-level connection
is `FW-*-DOM-CROSS`. Where the path is a class or a protocol, not an
object, it is the class's canonical type spelling ([netlist](netlist.md)):
the family name for `FW-E-PROTO-THIS` and `FW-E-PROTO-XTOR` (a check on
the class declaration), the specialization (a key of the netlist's
`protocols` table) for `FW-E-PROTO-API`.

| ID | Condition | Path |
|---|---|---|
| `FW-E-PROTO-THIS` | a `_param_utils` class whose `this_t` is not its own specialization (static front end) | the class |
| `FW-E-PROTO-API` | a protocol names the same API for both directions | the protocol |
| `FW-E-PROTO-XTOR` | a transactor or abstractor registered for a protocol it does not connect: the bundle or API side is missing ([protocols](protocols.md), "Converters"; static front end only, on every converter class) | the class |
| `FW-E-SOCK-UNBOUND` | a port, or a socket's port side, that resolves to no export after the connect phase | the port |
| `FW-E-SOCK-MULTI` | a port bound twice | the port |
| `FW-E-CFG-WRITE` | a write to a sink's `cfg` (static front end: any write target; run time: copy differs from the last push) | the sink |
| `FW-E-CFG-UNBOUND` | a sink that no source reaches after the connect phase | the sink |

`FW-E-NAME-BAD` is an addition to the initial list in core-layer1.md 3.10,
which requires legal names but gave no ID.
