# Protocols

Normative semantics of the protocol layer, on top of layer 1 and the domain
layer. Binding-neutral: the SV spelling is in `bindings/sv`
(`fw_protocol.svh`, `fw_protocol_type.svh`, `fw_port.svh`,
`fw_socket.svh`, `fw_cfg_src.svh` and their neighbours, and the
macros in `fw_hdl_macros.svh`).
Related: [bundles](bundles.md), [connections](connections.md),
[domains](domains.md), [diagnostics](diagnostics.md),
[netlist](netlist.md).

A **protocol** joins the parts of one interface standard: its method-level
APIs, its pin-level bundles, and the transactors and abstractors that
convert between them. The protocol class is a **hub**: every part
registers with it, it names none of them except its hand-written APIs, and
the tools find every part from it. Nothing in this layer is synthesized; a
method-level connection becomes pins only through a transactor.

## Protocols and identity

- A **protocol class** extends `fw_protocol`, has only static members,
  and declares `get_type()` with `` `fw_protocol_utils(C) ``. A
  parameterized one declares `typedef C #(...) this_t;` and uses
  `` `fw_protocol_param_utils(C) ``.
- A protocol has an identity at two levels:
  - its **family**, the class without parameters, one per class. Code
    written for any specialization keys on it (generators, rules,
    coverage, naming);
  - its **specialization**, the class with its parameters: the
    `fw_protocol_type` handle `get_type()` returns, one object per
    specialization. Connection checks and transactor choice key on it.
  An API has the same two levels: the interface class, and the handle
  `fw_api_type_of #(API)::get()` of a specialization.
- **No user-written strings.** Every registration macro takes the bare
  class name and only stringifies it, for the family name. The type comes
  from `C` in the plain form and from `this_t` in the `_param` form; the
  bare name is never used as a type, because inside a parameterized class
  it means the default specialization. `fw_protocol_type_of::get(family)`
  takes the family string, but only the macros call it; user code calls
  `P::get_type()`. (A tool's expansion may use the bare name as a type to
  key the family, which every specialization shares.)
- **`this_t` is checked.** A missing `this_t` is a compile error. One that
  is not the class's own specialization (its parameters, in order)
  compiles in SV, and is `FW-E-PROTO-THIS` in a static front end.
- **The prefix rule.** The prefix of derived names is the family name with
  a trailing `_proto` removed (`axi4_proto` → `axi4`). A protocol whose
  name does not fit sets one with `` `fw_protocol_prefix(s) ``. It is the
  only name a user ever writes.
- The same `this_t` rule and the same two forms hold for every
  registration macro: transactors (`` `fw_xtor_utils ``) and abstractors
  (`` `fw_abstractor_utils ``).

## Registration

Every registration points at the hub, so a kit builds in order (core
first, generated code after), has no cycles, and a third party can add a
bundle variant, transactor or abstractor without editing the protocol.

- **APIs.** The protocol's registration macro names its APIs:
  `` `fw_protocol_utils(C, REQ, RSP) `` (or
  `` `fw_protocol_param_utils ``). `REQ` is the request API, called by the
  initiating side; `RSP` the response API, called back on it. Either may
  be left out (or given as `fw_no_api`), so a protocol has at most one API
  per direction. The same API for both is `FW-E-PROTO-API`, on the
  protocol. An interface class cannot register itself, so the protocol
  names it; one API may belong to many protocols (the std neutral `put`
  and `mem` APIs).
- **Bundles.** A bundle class names its protocol with
  `` `fw_bundle_utils(C, PROTO) ``. A protocol may have several bundle
  forms (pin-level variants) and names none of them.
- **Converters.** A transactor extends one of the role base classes,
  each over its bundle type `B`, and registers with
  `` `fw_xtor[_param]_utils(C) ``. The base holds the pin side, `pins`
  (`fw_bundle`, `fw_mirror` or `fw_monitor #(B)`), and the method side,
  both created by its `build()`, and states the role (static `role()`)
  and the protocol (static `protocol()`, `B`'s). The method side's APIs
  default to the protocol's (`B` re-exports them from
  `` `fw_bundle_utils ``):

  | Base | Role | Method side |
  |---|---|---|
  | `fw_xtor_initiator #(B, API = REQ)` | initiator | `fw_export #(API) t`: the transactor implements the request API |
  | `fw_xtor_target #(B, API = REQ)` | target | `fw_port #(API) p`: the transactor calls it for each request |
  | `fw_xtor_sock_initiator #(B, REQ, RSP)` | initiator | `fw_socket #(RSP, REQ) s`: implements `REQ`, delivers responses through `RSP` |
  | `fw_xtor_sock_target #(B, REQ, RSP)` | target | `fw_socket #(REQ, RSP) s`: passes requests on through `REQ`, implements `RSP` |
  | `fw_xtor_monitor #(B)` | monitor | none; the subclass adds its own |

  A one-API base whose `API` is `fw_no_api` creates no endpoint. An
  abstractor registers with
  `` `fw_abstractor[_param]_utils(C, FROM, TO) ``. Both are one
  registration kind, a **converter** with two sides and a direction; a
  transactor is the converter whose two sides are the same protocol, the
  API on one and the bundle on the other. A static front end checks the
  registration against the converter class's ports (a check on the class
  declaration; a runtime does not make it): a transactor needs,
  unless it is a monitor (see "Derived shapes"), an endpoint of one of
  its protocol's APIs or of its channel APIs (`<p>_req_if`,
  `<p>_rsp_if`); an abstractor an endpoint or bundle of each side
  (`FW-E-PROTO-XTOR`, on the class). A transactor's bundle port is
  always there: it is the base's `pins`.
- **Completeness.** The registered converters are the classes the
  design names: every converter class without parameters, and each
  specialization of a parameterized one that the source names (a member,
  typedef, type parameter or base class), whether or not it is created;
  a specialization nothing names is not in it. Generators look
  converters up statically, over every registration macro in the source;
  generated testbench and bind code names each specialization it needs,
  so those are in the set.
- **Roles come from the base class, never registered.** A transactor's
  role is its base class's: `fw_xtor_initiator` (pins `fw_bundle`),
  `fw_xtor_target` (`fw_mirror`), `fw_xtor_monitor` (`fw_monitor`). It
  is a static fact of the class, known whether or not it is created. The
  method side has no role rule: its endpoints are whatever the
  protocol's APIs need (std's `fw_rv_initiator` takes requests in
  through an export), and they are not compared with the pin side.
- **Finding a transactor is static.** From a bundle: its protocol, the
  protocol's registered transactors, and the one whose pin side is the
  opposite mixin over the same bundle type (a monitor tap: the monitor).
  It is done by the tools, in IR; there is no run-time query.

## Queries

The protocol layer has no run-time queries. What a protocol relates (its
APIs, bundles, transactors and abstractors, a bundle's protocol and role)
is static: the tools read it from the source and the IR (fw-hdl-fe-sv's
scan, `ScanResult.xtor_for`, and the IR's protocol hubs). The handles
(`fw_protocol_type`, `fw_api_type`) exist to be registered and compared.

## API conventions

An API is an interface class. A protocol's APIs follow these rules, so that
derived code and foreign bindings (Python) can be generated from them:

- **Split by direction.** A request method returns once the request is
  accepted; responses arrive as calls on the response API. A response may
  arrive inside its request's call, so a caller is ready for responses
  before it calls. A blocking form is a shim over the split API.
- **Signatures.** A method is a task if it may block, else a function.
  Arguments are `input` or `output`; no `ref`, events or class handles;
  argument types are packed types and queues of them. A named argument
  or payload type is a typedef at package level, in the kit's package
  (`sbus_req_t`), not one declared inside a class.
- **Parameters.** A parameterized protocol, API or bundle takes plain
  parameters: a type (`#(type T)`, as std's `fw_rv_proto` and `fw_put_if`)
  or a value (`#(int W)`). Each derived class takes the parameters of the
  API or bundle it is derived from. A width that follows a parameter is
  written on a non-struct type (`logic [W-1:0]`); a struct payload has
  fixed widths.
- **Channel APIs** have one method per channel, named as the channel. That
  name is the only link a transactor needs between a method and its pins.

## Derived shapes

The generators are tools, not part of this specification. The shape of
what they derive is normative, because users extend and rely on it. For
API `<api>` with method `<m>`, and protocol prefix `<p>`:

| Class | Shape |
|---|---|
| `<api>_base` | implements `<api>`; each method reports an error (it is not implemented) and zeroes its outputs and return value |
| `<api>_listener` | a function `<m>_pre(inputs)` and `<m>_post(inputs, outputs)` per method; with `_listener_base` (empty bodies) and `_listener_fanout` (to many) |
| `<api>_proxy` | implements `<api>`: calls each listener's `<m>_pre`, forwards to its target, then calls each `<m>_post` |
| `<api>_imp #(..., IMP)` | `<api>`'s parameters, then `IMP`: implements `<api>` by forwarding to `IMP`'s methods; how a component implements an export |
| `<api>_txn`, `<api>_<m>_txn` | a virtual base, and one transaction class per method: its inputs and outputs, `rand`-capable, with `sprint` and `compare` |
| `<api>_txn_sink` | an interface class with `put(<api>_txn t)`: where recorded transactions go |
| `<api>_txn_listener` | a listener that emits a `<api>_<m>_txn` to a sink at `<m>_post` |
| `<api>_txn_driver` | takes transactions and makes the calls on an `<api>` handle |
| `<p>_req_if`, `<p>_rsp_if` | the channel APIs, derived from the bundle; the transactions of one direction are theirs (`<p>_req_if_txn`) |
| `<p>_payloads` | static `<n>_sprint`, `<n>_compare` and `<n>_mask` per struct channel payload `<n>_t` |
| `<p>_pins` | static `flat(m, b, pre)`: the prefix rule for bundle `b` with flat pins `<pre><c>valid`, `<pre><c>ready` and `<pre><c><f>` per payload field (`awaddr`); see extern rule 2 |

- **Calling order.** On a proxy, every listener's `<m>_pre` is called
  before the call is forwarded, and every `<m>_post` after it returns.
  On a pin-level monitor, `<m>_pre` is at the first cycle with `valid`,
  and `<m>_post` at the handshake.
- Listener callbacks are functions: a listener cannot block or change the
  call. A monitor role has no API of its own; it emits listener calls.
- Payload structs stay the wire-level value; a transaction class wraps
  them.

## Endpoints and sockets

- **Endpoints.** `fw_port #(API)` is the required side: its owner
  calls `API` through it, on the implementation `get_if()` returns.
  `fw_export #(API)` is the provided side. Both are structural objects:
  created through the factory (`create(name, parent)`) in the build
  phase, with the layer-1 naming and phase rules
  ([elaboration](elaboration.md)).
- **Sockets.** `fw_socket #(OUT, IN)` calls `OUT` (as a port, through
  `get_if()`) and provides `IN` (as an export). Its peer is
  `fw_socket #(IN, OUT)`. A socket is its own endpoint class, not a port
  and an export. A socket has no role against a protocol: roles belong
  to converters and come from their pin side (Registration).
- **Implementation.** An export's implementation is derived: when its
  parent implements `API`, the parent is the implementation, with no
  call; a socket's `IN` is derived the same way. `set_imp(imp)` sets
  another one (a member object) and overrides the derived one. A component implements an API with a derived
  `<api>_imp`, never with a macro.
- **Binding**, in `connect()` only, as signal connections
  ([connections](connections.md)); elsewhere `FW-E-CONN-PHASE`:
  - `port.connect(export)` binds a port to an export; a port binds once
    (`FW-E-SOCK-MULTI`, on the port). An export may serve many ports.
  - `socket.connect(peer)` binds both directions of a socket pair; the
    peer's type is the swap, `fw_socket #(IN, OUT)`.
  - `connect_up(outer)` passes a child's endpoint through a parent's
    endpoint of the same type: a port or socket up to the parent's, an
    export to provide the parent's.
  - The endpoint types must match exactly: same API, or the swapped API
    pair.
- **Resolution.** After the connect phase every port resolves, through
  any `connect_up` chain, to one export, and through it to an
  implementation, once. A port that resolves to no export is
  `FW-E-SOCK-UNBOUND`, on the port; calls through a resolved port reach
  the implementation directly. Simulation, and any elaboration that is
  not for lowering (a netlist, say), requires every port to resolve.
  At a lowering top, a port may stay unbound when its component's `run()`
  is hand-off only ([processes](processes.md), "Lowering") and no `step`
  or `comb` code calls through it: lowering drops the task code that
  uses it, and the port's boundary is the crossings' ports, which lower
  to module ports. A static front end is told the top is a lowering
  top; it then decides an unbound port of a component that implements
  `run()` when it lowers, not when it elaborates.
- **Domains.** Endpoints and sockets are interfaces of the domain layer:
  they take associations as bundles do ([domains](domains.md)). A
  connection whose two ends resolve to different domains of a kind is a
  crossing, reported as `FW-*-DOM-CROSS` on the lesser path.
- **Simulation only.** A static front end records endpoints and their
  connections in the netlist, but lowers none of them to hardware.

## Abstraction levels

- **One protocol, two levels.** A protocol's API is its method level and
  its bundle its pin level; the **transactor** converts between them.
  When the abstract level is this protocol's own transactions (UART bytes
  over a serial line, AXI4 bursts over beats), there is one protocol.
- **Two protocols.** When the abstract level exists on its own (a packet
  protocol over two PHYs), there are two protocols and an **abstractor**,
  registered with both. Neither protocol names the other.
- **One hop.** An abstractor converts between two protocols. Chains are
  built by connecting abstractors; path search across several is not
  defined.
- **Declared loss.** What an abstract level keeps is exactly its payload's
  fields. What it drops (UART bit timing) is dropped visibly, by not being
  in the payload, never silently.
- **Timing.** A converter adds no cycles beyond the protocol's own
  transfer time: no FIFO and no added latency. For a ready/valid protocol
  the transfer time is the handshake cycle; for a configured protocol it
  is given by the configuration (UART: the frame time).
- A pin-level monitor feeding an upward converter produces API-level
  listener calls, so a checker written for the API runs on a class model
  and on RTL alike.

## Configuration

- Configuration is a struct (packed where it fits), never a class
  handle. It is a property of the endpoint, not of the protocol: each
  side of a link has its own.
- `fw_cfg_src #(T)` belongs to the owner of the configuration.
  `set(v)` is the **commit point**: it stores `v` and pushes a copy to
  every bound sink; `get()` returns the last value set. Sinks see only
  whole values, never a half-changed one.
- `fw_cfg_sink #(T)` holds `cfg`, its copy, read directly. A source
  pushes its value to a sink **when it is bound**, so a `set()` in the
  build phase reaches every sink, and no sink reads a default by
  accident.
- **Snapshot at transfer start.** A `set()` may land during a transfer. A
  sink reads the fields it needs when a transfer starts and uses them
  for that transfer; a change takes effect on the next one.
- **No client writes.** Code other than the runtime never writes a
  sink's `cfg`: no assignment to it or into it, no `ref` argument
  (`const ref` is allowed). A static front end reports any such write; a
  run-time implementation compares each sink's copy with the last
  value pushed before each push, and reports a difference. Both are
  `FW-E-CFG-WRITE`, on the sink.
- **Binding.** `sink.connect(src)`, in `connect()`, binds a sink. A sink
  that no source reaches after the connect phase is `FW-E-CFG-UNBOUND`.
- **Static view.** A sink's `cfg` has one writer, the source's
  push, and any number of readers: the shape of a single-driver
  connection updated on an event. It is listed as a connection, takes part
  in the crossing check, and lowers in hardware to wires from the
  configuration registers. The no-write rule is what makes the
  single-writer claim hold. The pushes above happen at run time. A
  static front end records each binding, each sink's resolved source and
  each `add_listener`, linking a change to the action that runs on it.
  It neither pushes values nor calls listeners.

## Timing

- A protocol carries no timing. The time a transfer takes, and what a
  receiver sees when the two ends are configured differently, belong to
  **channels**: kit components placed explicitly between two endpoints,
  with the transfer time and the mismatch as virtual methods. Nothing is
  inserted by elaboration.

## Netlist

The netlist ([netlist](netlist.md)) lists the protocols of the design in a
`protocols` table, keyed by specialization: family, parameters, APIs with
direction, bundle types, and converters (sides, direction, role). Bundle
instances carry `protocol` and `role`. Endpoints and sockets are objects of
kind `api_endpoint`, sources and sinks of kind `cfg_src` and
`cfg_sink`. Their links are in a top-level `bindings` list: kind `api`
from port side to export side (each `connect` and `connect_up`), kind
`cfg` from source to sink. `add_listener` is structural, like a
connection: it is made in a phase method, and one made later (at run
time) is `FW-E-CONN-PHASE`. Each `add_listener` is a record in a
top-level `listeners` list: the sink, the call's order on it, the
component that made the call, and the listener's path (null for a plain
object). Each appears only when the design has one,
so a design without protocols has none of them. Both implementations must
agree on the table: that is how conformance checks the queries.
