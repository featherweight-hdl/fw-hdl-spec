# Diagnostics

Each diagnostic has a stable ID (`FW-<E|W>-<AREA>-<WHAT>`), a message and a
**path**: the full name of one object, given below for each ID. Conformance
compares (ID, path) pairs, never messages. Each pair is reported once.
`FW-E-` IDs are errors: elaboration fails. `FW-W-` IDs are warnings.

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
| `FW-E-CONN-PHASE` | connect or tie outside `connect()` | the endpoint whose method was called (first of a `connect_all` pair) |
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

`FW-E-NAME-BAD` is an addition to the initial list in core-layer1.md 3.10,
which requires legal names but gave no ID.
