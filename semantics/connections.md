# Connections

## Locality

The **connecting component** (the scope of a connection) is the component
whose `connect()` is running. It may connect only:

- its own ports, bundles and local signals, and
- the ports and bundles of its *direct* children.

Anything else, including a child's local signal or a grandchild's port, is
`FW-E-CONN-SCOPE`, on that endpoint. This keeps every connection inside one
module of the emitted RTL.

## Calls

- `a.connect(b)`, `connect_up`, `connect_all` pairs and the bundle-role
  `connect` methods all record a connection between two endpoints in the
  current scope. Connections are symmetric: which side calls does not
  matter.
- `s.tie(v)` records a tie of `s` to the constant `v` in the current scope.
- Checks at the call, in this order, each stopping the call: an endpoint
  not created by the factory (`FW-E-ELAB-NEW`, naming the scope); a call
  outside `connect()` (`FW-E-CONN-PHASE`, on the endpoint whose method was
  called, or the first of a `connect_all` pair); a signal paired with a
  bundle, non-equivalent value types, or bundles of different types
  (`FW-E-CONN-TYPE`, on the first endpoint); an endpoint out of scope
  (`FW-E-CONN-SCOPE`, on that endpoint).
- A bundle connection is expanded member-wise, by member name, recursively
  through nested bundles, into signal-level connections. The bundle types
  must be the same; roles are not checked here: a wrong pairing (an
  initiator to an initiator) shows up as a net with two sources and a net
  with none.

## Endpoint roles

Seen from the scope, each signal-level endpoint is a source, a sink, a
local signal, or an inout. `dir` is the endpoint's effective direction
([bundles](bundles.md)):

| Endpoint | Role in the scope |
|---|---|
| own port, `in` | source |
| own port, `out` | sink |
| own local signal | signal (it is the net) |
| child's port, `out` | source |
| child's port, `in` (including every monitor member) | sink |
| any `inout` | inout (both) |

## Nets

- In each scope, connected endpoints form nets: connections are symmetric
  and transitive (union-find). A tied endpoint is on a net even if nothing
  else connects to it. Nets are per scope: a child's port is a sink in the
  parent's scope and a source in the child's own scope, so a connection
  path that crosses a hierarchy level gives one net in each scope.
- The **drivers** of a net are its sources plus its ties. A tie is a source;
  a tied endpoint may not also be driven.
- More than one driver: `FW-E-NET-MULTI`, on the least path among the net's
  source endpoints and tied endpoints.
- At least one sink, no driver and no inout: `FW-E-NET-UNDRIVEN`, on the
  least sink path.
- A net with an inout endpoint and no driver is legal (the inout drives
  it); nets of inouts only are exempt.
- All endpoints of a net have equivalent types (enforced at each call,
  above). There is no implicit extension or truncation.
- An own `in` port connected straight to an own `out` port is legal; it
  becomes an `assign` in emitted RTL.

## Bundle connections

| Connect | Where | Typical use |
|---|---|---|
| child initiator <-> child mirror | siblings | initiator to target |
| own initiator <-> child initiator | pass-through | re-export a child's initiator side |
| own mirror <-> child mirror | pass-through | re-export a child's target side |
| child monitor <-> any role of the same type | anywhere in scope | tap a link; monitor members are sinks |

## Unconnected endpoints

Checked in each scope, for the ports of each direct child:

- a child's effective input that is on no net of the scope (neither
  connected nor tied) is `FW-E-IN-OPEN`, on that port;
- an unconnected output or inout is legal.

The top component's own ports are its module's ports and are never open.
A component's own unconnected `out` port is legal (an extern's RTL drives
it).
