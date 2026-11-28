# Processes

Normative semantics of processes (layer 2): signal values, the `step`,
`comb` and `run` processes, reset of state, and time. Binding-neutral: the
SV spelling is in `bindings/sv` (`fw_signal.svh`, `fw_step_if.svh`,
`fw_comb_if.svh`, `fw_run_if.svh`, `fw_reset_state_if.svh`,
`fw_time.svh`, the domain operations in `fw_domain.svh`, the
`` `fw_comb ``/`` `fw_step `` macros in `fw_hdl_macros.svh`).
Related: [signals](signals.md), [domains](domains.md),
[elaboration](elaboration.md), [diagnostics](diagnostics.md).

A **process** is code that runs after elaboration: `step()` and `comb()`
are functions called by the kernel at a clock edge; `run()` is a task that
waits on its component's domains. A static front end lowers `step()` and
`comb()` to RTL; `run()` is simulation-only.

## Signal values

- `read()` returns a signal's value; it is legal on every direction.
  `write(v)` sets it; writing an **effective** input (the direction after
  mirror flips, so a mirror's `valid` of a ready/valid bundle) is
  `FW-E-WRITE-IN`, on the signal. A static front end reports it from the
  code; a run-time implementation at the write. The write is ignored.
- A connected net has one value: `read()` on any member of the net returns
  it. A tied endpoint reads as its constant. Before any write, a signal
  reads as its type's default (0 for a 2-state type).
- A value is written whole: there is no masked or per-field write of a
  packed value.
- **Request-update.** A `write(v)` from a `step` block stores a pending
  value, which becomes visible at the edge's update (below); one from a
  `comb` block is visible to the rest of the settle. Neither is ever
  visible part-way through the evaluate phase. Task code reads and writes
  no signal ([Task code](#task-code)).

## Process kinds

- A component that implements `fw_step_if` has one `step()` block; one that
  implements `fw_comb_if` one `comb()` block; one that implements
  `fw_run_if` one `run()` task; one that implements `fw_reset_state_if` a
  `reset_state()` function. Implementation registers the process:
  elaboration finds it by the interface, with no further call.
- `` `fw_step(name) `` and `` `fw_comb(name) ``, in a component's class
  body, declare a further `step` or `comb` block that calls the
  component's function `name()`. Each macro use is its own block, as if it
  were the `step()` or `comb()` of a separate component in the same
  domains: its own writers (below), its own domain, and for a static front
  end its own `always_ff` or `always_comb`. A component may combine the
  interface and any number of macro blocks; block names are unique per
  class (a duplicate is a compile error in the binding).
- `step()`, `comb()` and `reset_state()` are functions: they cannot wait.
  Only task code waits, through the domain operations and `fw_time`.

## Register or wire

A signal's kind follows from its writer; nothing marks it:

- written by a `step` block: a **register**, visible after the edge's
  update (as a nonblocking assignment);
- written by a `comb` block: a **wire**, visible to the reads of the same
  settle;
- written by no process of the class tree: driven from outside (a port
  input, an extern pin, a tie), as in layer 1.

A signal with more than one writing block (two `step` blocks, a `step` and
a `comb` block, blocks of two components) is `FW-E-WRITE-MULTI`, on the
signal. Writes by one block from several call sites, or several writes in one call, are
one writer; the last write of the call wins. The same holds for component
fields a block writes; a field written by blocks in two domains is
`FW-E-WRITE-MULTI` on the component. A static front end finds writers from
the code; a run-time implementation at the first write of the second
writer.

Bundle members follow these rules on their effective direction: a mirror's
`comb()` may write `ready` and read `valid` and `data` in the same edge.

## Domain of a process

A component's processes run in its resolved domains
([domains](domains.md)) and in every further domain its interfaces resolve
to.

- A **`step` block** runs in one clock domain, derived from what it writes:
  the clock domain of the interfaces whose signals it writes, or, when it
  writes none (only component state), the component's clock domain. A block
  that writes signals of two clock domains is `FW-E-STEP-DOMAINS`, on the
  component; the user splits it with `` `fw_step(name) ``. The block's
  registers reset with the reset domain of the same interfaces (or the
  component's).
- **`reset_state()`** is split by what each assignment writes, per the
  same rule: the part that writes a block's registers runs while that
  block's reset domain is asserted.
- A **`comb` block** has no domain: it runs in every settle of each clock
  domain whose signals it reads.
- **Task code** has no domain of its own and touches no signal: it reaches
  a domain through the domain operations and the task-sync crossings of
  its component ([Task code](#task-code)).
- A block that reads an interface of another domain than its own is a
  crossing inside the component, which is its crossing element; it is
  allowed and listed in the netlist with the other crossings.
- A domain a process uses is **realized**: the component's module gets its
  clock and reset ports.

## Edges

Each clock domain that has edges numbers them 1, 2, … from time 0. Which
domains have edges, and when:

- **A domain with a net** (a driver or an extern pin; [domains](domains.md),
  Drivers): each transition of the net to 1, from any other value. A net
  that goes 0, X, 1 has one edge. Counting starts at time 0, whatever
  elaboration is doing then.
- **A root with a `period` and no driver:** edge *k* at time *k* ×
  `period` (Time, below).
- **A derived domain with no driver of its own**, from its source *s*:
  - `derived(s, div)`: edge *j* is edge *j* × `div` of *s*, so its phase
    is fixed from time 0: the first is at *s*'s edge `div`;
  - `gated(s)`: the edges of *s* (the gate's enable is not modelled; a
    gate that matters is a driver);
  - `derived(s, div, mul)` with `mul` > 1, and `phase(s, deg)`: from the
    period *P* of *s*, which needs a `period` root: edges at *j* × *P* ×
    `div` / `mul`, or at *j* × *P* + *P* × `deg` / 360, for *j* = 1, 2,
    … (a 90° phase's first edge is at 1.25 × *P*);
  - `muxed(s[])`: none.

  A derived domain whose edges can't be computed (`mul` > 1 or `phase`
  from a source with no period, `muxed`) has no edges: `tick` on it is
  `FW-E-CLOCK-NONE`. A computed time that isn't a whole number of the
  simulation's time precision is `FW-E-CLOCK-PERIOD`, on the domain, at
  the end of elaboration.

A derived domain with a net of its own (the output of a clock divider in
RTL) takes its edges from the net, not from its declaration. It stays
*related* to its source ([domains](domains.md), Relations).

## The edge

At a time *t*, the edges of each **group** are processed together. A
group is the domains whose edges at *t* are computed from one root: the
root, if it has an edge at *t*, and each domain derived from it, with no
net of its own, that has an edge at *t*. A domain with a net of its own
is the root of its own group.

For each group, in order:

1. **Evaluate:** for each domain of the group, while a block's reset domain
   is asserted, its part of `reset_state()`; otherwise each `step` block of
   the domain. Every block reads the values from before the group's edge,
   including the registers of the other domains of the group, and its
   writes are pending. The order among blocks is unspecified and not
   observable.
2. **Update:** every pending register write of the group becomes visible.
3. **Settle:** every `comb` block that reads a changed signal runs, in
   whole passes, until a pass changes no wire. A settle that still changes
   after 64 passes is `FW-E-COMB-LOOP`, on each signal that changed in the
   last pass; the run stops.
4. **Release:** each domain of the group counts the edge. Then the task
   code waiting on those domains resumes ([Domain operations](#domain-operations)).

After a group, registers and the comb logic computed from them both show
the new values, as in RTL. A signal driven from outside the class tree (an
extern pin) that changes between edges, and a task-sync crossing changed
by task code (X3), settle the comb blocks that read them at once.

Order at one time:
- Groups of unrelated roots at the same time run in an unspecified order:
  a crossing between them is a clock-domain crossing.
- A domain whose net is driven by logic clocked from another domain (a
  divider) runs its group after that domain's at a shared time, because
  its net changes as a result of the other's edge.
- A signal that a flop on the same edge drives from outside the class tree
  (RTL in the same simulation) changes after the group's update, as in
  RTL. One that changes at the same time for another reason is a race, as
  in RTL.

### Replacing a sync subtree

An implementation may run a subtree of components that has only `step` and
`comb` blocks as something else, such as a compiled model or a Verilated
module of its generated RTL, put in place through the factory. The
replacement takes part in the edge as one block would. At each edge of its
domain it:

- reads its inputs as they were before the group's edge (Evaluate);
- computes its next state, and makes it visible at Update;
- settles its outputs at Settle, as its `comb` blocks would;

and, when one of its comb inputs changes between edges, settles the outputs
that depend on it at once. Such a replacement is not observable, except
through time and introspection ([`fw_acc`](acc.md)).

## Reset

- A component that implements `fw_reset_state_if` has `reset_state()`
  called at each edge while its reset domain is asserted, in place of its
  `step` blocks. Without it, `step()` runs in reset and handles reset
  itself, with `in_reset(this)`.
- No implementation forces the outputs of a component in reset: a
  component that drives a protocol sets its outputs in `reset_state()`.

A reset domain **asserts** at an edge whose blocks read it asserted after
one (or the start) that read it deasserted, and deasserts the other way.
Task code reads it as `in_reset` does: at an edge, the value that edge's
blocks read (T1); between edges, its driver's current value.

- **R1 `run()` starts after reset.** A component's `run()` starts where
  `wait_reset_done(this)` returns: when the run starts (time 0) if its
  reset domain is deasserted then, else at the first edge with it
  deasserted, after that edge's release (at that edge, T1).
  `wait_reset_done(this)` at the top of `run()` is redundant, and legal.
- **R2 Reset kills it.** At the edge where the reset domain asserts,
  `run()` and every thread it forked are killed, before anything that edge
  releases resumes. A call blocked on one of those threads dies with it,
  including in a callee reached through a port (a target's API task runs
  on its caller's thread) and in a crossing: it never returns. Component
  fields keep their values unless `reset_state()` sets them.
- **R3 And restarts it.** At the next edge with the reset deasserted,
  `run()` starts again from the top, as in R1.
- A component with no reset domain (simulation only: [domains](domains.md))
  starts `run()` when the run starts, and it is never killed.
- A `run()` that must act during its reset (drive a software reset, log
  it) belongs to a component in an outer reset domain.

## Domain operations

Static operations of `fw_domain`, keyed by `obj`: `this` of the code making
the call, or one of its own ports or bundles in a role. That is the
component whose method is running, not the component whose `run()` the
thread belongs to: a target's API task, running on its caller's thread,
passes its own `this` and waits on its own clock. Each acts on the domain
`obj` resolves to (`get(obj)`), and using it realizes that domain.

Task code is at an edge or between edges (T1, [Task code](#task-code)).

- `tick(obj, n = 1)` (task): waits for *n* edges of the clock domain,
  counted from the call: at edge *k*, it returns at edge *k* + *n*;
  between edges *k* and *k* + 1, at edge *k* + *n*. It returns after
  that edge's release. It counts edges; it never compares times.
- `in_reset(obj)`: 1 while the reset domain is asserted.
- `wait_reset_done(obj)` (task): returns at the first edge with the reset
  domain deasserted, after its release, or at once if the reset is
  already deasserted.
- `wait_assert(obj)` (task): returns when the reset domain is next
  asserted.

`obj` of another component than the calling code's is `FW-E-DOM-OBJ`, a
static rule: a static front end checks it from the code, and a run-time
implementation, which can't tell whose method is running, doesn't. A
domain that does not resolve is `FW-E-DOM-NONE`; `tick` on a domain that
is not a clock domain, or a reset operation on one that is not a reset
domain, is `FW-E-DOM-KIND`, each on `obj`. A clock domain with no edges
(Edges, above) has nothing to wait for: `tick` on it is
`FW-E-CLOCK-NONE`, on `obj`.

Open: a domain operation whose `obj` is in another clock domain than the
thread's `run()` (a callee in another clock, called through a port) is a
clock crossing; its rule is not decided.

## Task code

**Task code** is `run()`, the threads it forks, and the tasks and
functions they call (an export's API task, say). It runs on threads of its
own, never inside an edge, and is simulation-only.

Task code neither reads nor writes signals. It uses its component's
task-sync crossings (below), component fields, the domain operations,
`fw_time` and port calls; the protocol timing stays in `step` and `comb`
blocks, which lower. A `read()` or `write()` of a signal from task code is
`FW-E-TASK-SIGNAL`, on the component whose code makes it: a static front
end reports it from the code; a run-time implementation at the access, and
ignores the write.

For a clock domain *d*:

- **T1 Position.** Task code is **at edge *k*** of *d* when *d* released
  edge *k* in the current time step, and **between edges** of *d*
  otherwise. It runs after a group's release or between edges, never in
  one. An operation that must act at an edge waits for one first (`tick`,
  a blocking crossing call), as a synchronizer does: entering a clock
  domain from task code costs the wait to its next edge.
- **T2 Order.** A group's release comes before the task code it resumes,
  and an implementation that generates edges (a `period` root and the
  domains computed from it) processes them before a `fw_time::delay` that
  ends at the same time resumes. So whether task code is at an edge
  doesn't depend on the order of processes. A delay that ends at the time
  of an edge from a net is a race, as in RTL.
- **T3 Zero time stays at the edge.** `tick`, and a crossing call that an
  edge releases (X5), return after the edge's release; code after them is
  at that edge until it consumes time. Task code resumed by other task
  code in the same time step (a port call's return, a mailbox, an event)
  is at the same edges as that code. A wait that consumes time leaves the
  edge.

## Task-sync crossings

`fw_to_sync #(T)` carries items from task code into sync code, and
`fw_from_sync #(T)` carries them from sync code out to task code. Each is
created in `build()` and belongs to its component, the **owner**; its clock
and reset domains are the owner's. Each has two sides:

| | Process side (task code) | Sync side (the owner's `step` and `comb`) |
|---|---|---|
| `fw_to_sync` | `put` (blocking), `try_put` | `valid`, `peek`; `take` (`step` only) |
| `fw_from_sync` | `get` (blocking), `try_get` | `ready`, `waiting`; `give` (`step` only) |

They are the way a transactor's task-level calls reach its protocol logic
without task code touching signals: the protocol timing stays in `step`
and `comb` blocks, which lower.

- **X1 Sides.** Only the owner's sync code uses the sync side; task code,
  from any thread, uses the process side. Anything else, and `take` or
  `give` outside a `step` block, is `FW-E-XING-SIDE`, on the crossing.
- **X2 Comb only looks.** `take` or `give` in a `comb` block is
  `FW-E-XING-COMB`, on the crossing: a comb block runs at every settle.
- **X3 A process-side change re-evaluates the owner.** A process-side call
  that changes a crossing (an item put or got, a `get` starting or
  stopping to wait) takes effect at once, and the owner's comb blocks
  settle on it. That is the timing of a register written at that edge:
  `comb` shows it at once, and `step` blocks read it from the next edge.
- **X4 Sync reads the state before the edge.** At edge *k*, a `step`
  block sees each crossing as it was before *k*.
- **X5 Sync-side changes act at the edge.** A `take` or `give` at edge *k*
  takes effect in *k*'s update. A process-side call it releases resumes
  after *k*'s release, at edge *k* (T2, T3).
- **X6 Blocking.** `fw_to_sync::put` waits while the crossing is full. With
  depth 1 (the default) it returns at the edge where its item is taken;
  with a larger depth, once the item is queued. `fw_from_sync::get` waits
  for an item. `waiting()` is true while a `get` waits with no item queued
  for it, so a `give` then is taken at this edge with nothing buffered.
- **X7 Items, not values.** Each item is separate: several puts sampled by
  one edge are not an error.
- **X8 Reset.** At each edge where the owner's reset domain is asserted,
  its crossings are emptied (items queued or given are dropped), in the
  edge's update: `comb()` sees nothing during reset and drives no
  transfer. A call blocked on the crossing from the owner's reset domain is
  killed with its thread (R2).
- **X9 No calls into reset.** A process-side call (`put`, `get`,
  `try_put`, `try_get`) while the owner's reset domain is asserted, or one
  blocked at the edge where it asserts, comes from a thread of another
  reset domain (a thread of the owner's is killed, R2) or of none. It is
  `FW-E-XING-RESET`, on the crossing, and returns at once (a blocked call
  at that edge, after its release): `try_*` returns 0; `get`'s item is the
  type default; a `put`'s item is dropped. A run-time check.

A target transactor, which calls out through a port, still has a `run()`
for that call: it gets each request from a `fw_from_sync`, calls the port,
and puts the response to a `fw_to_sync`. The pin timing stays in sync code.

## Time

- Time is simulation time. `fw_time::now()` returns it;
  `fw_time::delay(d)` (task) waits for `d`. `time` values follow the
  compilation unit's time unit; the library units use 1ns/1ps.
- A root clock domain may have a `period` (clock kind root params, 0 for
  none). With it and no driver, a run-time implementation generates the
  domain's edges itself, and the edges of the domains derived from it
  (Edges, above). Edge times are exact: edge *k* is at *k* × `period` in
  the simulation's time precision, never accumulated in floating point.
- A root clock domain with a `period` and no driver is driven by the
  implementation: it is not `FW-E-DOM-NODRIVER`. A run-time
  implementation puts its first edge at `period`. A static front end gives
  the top module an input pin for it (named as a domain pin is), which the
  test bench drives.

## Lowering

A static front end lowers `step` blocks, `comb` blocks and `reset_state()`
to RTL. It does not lower:

- `run()`: asked to emit a component that implements `fw_run_if` is
  `FW-E-EMIT-RUN`, on the component, unless its `run()` only hands off.
  A hand-off `run()` uses only the process side of the component's
  task-sync crossings, calls through the component's own API ports, and
  locals: it reads and writes no component state and no signal, and uses
  no time. It is left out of the module, as other task code is: its
  crossings lower to ports (below), and whatever drives them stands for it
  (a target transactor's `run()`, which gets a request, calls its port and
  puts the response);
- `fw_time`, or a waiting domain operation, in a lowered process:
  `FW-E-EMIT-TIME`, on the component. `in_reset` is lowered in `step()`
  and `comb()`.

Task code other than `run()` (an export's task, say) is not lowered
either; it is left out of the module, which is not an error.

### Task-sync crossings

A component's task-sync crossing `x` lowers to ready/valid ports of its
module; the queue is not in the module, and `depth` belongs to whatever
drives the ports (in a mixed simulation, the task side):

| | Ports | Sync side |
|---|---|---|
| `fw_to_sync #(T)` | in `x_valid`, in `T x_data`, out `x_ready` | `valid()` is `x_valid`; `peek()` is `x_valid ? x_data : T'(0)`; `take(t)` is `x_valid`, sets `t` to `peek()`'s value, and makes `x_ready` 1 |
| `fw_from_sync #(T)` | out `x_valid`, out `T x_data`, in `x_ready`; in `x_wait` if `waiting()` is called | `ready()` is `x_ready`; `waiting()` is `x_wait`; `give(v)` is `x_ready`, and makes `x_valid` 1 and `x_data` `v` |

- An item moves at the edge where `x_valid && x_ready`, as X5.
- `x_ready` of a `fw_to_sync` and `x_valid`, `x_data` of a `fw_from_sync`
  are combinational: 1 (and `v`) when, evaluated before the edge, the
  owner's `step` reaches the call (its conditions, with the locals and
  plain state variables it has written by then); 0 (and `T'(0)`)
  otherwise, and while the step's reset branch is taken. Their values
  don't depend on `x_ready` of the same `fw_from_sync`: a `give` without
  room transfers nothing.
- Whatever drives the ports holds the queue and stands for the process
  side: for a `fw_to_sync`, `x_valid` and `x_data` are `valid()` and
  `peek()` of its queue; for a `fw_from_sync`, `x_ready` is `ready()`
  (room in its queue, not a waiting `get`: an item given while no `get`
  waits is queued) and `x_wait` is `waiting()` (X6). std's
  `fw_to_sync_ep` and `fw_from_sync_ep` are these outsides. Emptying in
  reset (X8) and `FW-E-XING-RESET` (X9) are the outside's too.
- A child's task-sync crossing ports become ports of its parent,
  `<child>_<port>`, up to the top.
- A step block takes or gives at most once per crossing per edge (one
  port moves one item). A crossing use the front end can't lower
  (`take` into something other than a local of the block, `take` or
  `give` in a loop, two step blocks handing off on one crossing) is
  `FW-E-XING-LOWER`, on the component.
