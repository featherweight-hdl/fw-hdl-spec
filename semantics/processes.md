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
- **Request-update.** `write(v)` stores a pending value. It becomes
  visible at the update point of the writer's process kind (below), never
  part-way through an edge's phase.

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
  Only `run()` waits, through the domain operations and `fw_time`.

## Register or wire

A signal's kind follows from its writer; nothing marks it:

- written by a `step` block or by `run()`: a **register**, visible after
  the next commit (as a nonblocking assignment);
- written by a `comb` block: a **wire**, visible to the reads of the same
  settle;
- written by no process of the class tree: driven from outside (a port
  input, an extern pin, a tie), as in layer 1.

A signal with more than one writing block (two `step` blocks, a `step` and
a `comb` block, a block and `run()`) is `FW-E-WRITE-MULTI`, on the signal.
Writes by one block from several call sites, or several writes in one
call, are one writer; the last write of the call wins. The same holds for
component fields a block writes; a field written by blocks in two domains
is `FW-E-WRITE-MULTI` on the component. A static front end finds writers
from the code; a run-time implementation at the first write of the second
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
- A block that reads an interface of another domain than its own is a
  crossing inside the component, which is its crossing element; it is
  allowed and listed in the netlist with the other crossings.
- A domain a process uses is **realized**: the component's module gets its
  clock and reset ports.

## The edge

Each realized clock domain has an edge loop. At each active edge, in order:

1. **Commit:** pending register writes of this domain become visible.
2. **Settle:** every `comb` block that reads a signal of this domain runs,
   in whole passes, until a pass changes no wire. A settle that still
   changes after 64 passes is `FW-E-COMB-LOOP`, on each signal that changed
   in the last pass; the run stops.
3. **Step:** while the block's reset domain is asserted, its part of
   `reset_state()`; otherwise each `step` block of this domain. The order
   among blocks is unspecified: a block reads only committed and settled
   values, so the order is not observable.
4. **Run:** `run()` tasks waiting on this edge resume. A `run()` reads the
   values `step` read; its writes are committed at the next edge's
   commit, so peers see them during the following cycle.

A component with both `step` blocks and `run()` is allowed; at one edge its
`step` blocks run before its `run()`, so values shared through component
state are deterministic.

## Reset

- A component that implements `fw_reset_state_if` has `reset_state()`
  called at each edge while its reset domain is asserted, in place of its
  `step` blocks. Without it, `step()` runs in reset and handles reset
  itself, with `in_reset(this)`.
- No implementation forces the outputs of a component in reset: a
  component that drives a protocol sets its outputs in `reset_state()`.

## Domain operations

Static operations of `fw_domain`, keyed by `obj`: the calling component or
one of its own ports or bundles in a role. Each acts on the domain `obj`
resolves to (`get(obj)`), and using it realizes that domain.

- `tick(obj, n = 1)` (task): waits for `n` active edges of the clock
  domain; returns in that edge's run phase.
- `in_reset(obj)`: 1 while the reset domain is asserted.
- `wait_reset_done(obj)` (task): returns at the first edge with the reset
  domain deasserted, at once if it is already deasserted.
- `wait_assert(obj)` (task): returns when the reset domain is next
  asserted.

`obj` of another component is `FW-E-DOM-OBJ`; a domain that does not
resolve is `FW-E-DOM-NONE`; `tick` on a domain that is not a clock domain,
or a reset operation on one that is not a reset domain, is
`FW-E-DOM-KIND`, each on `obj`. A clock domain with no driver, no extern
pin and no `period` (below) has no edges: `tick` on it is
`FW-E-CLOCK-NONE`, on `obj`.

## Time

- Time is simulation time. `fw_time::now()` returns it;
  `fw_time::delay(d)` (task) waits for `d`. `time` values follow the
  compilation unit's time unit; the library units use 1ns/1ps.
- A root clock domain may have a `period` (clock kind root params, 0 for
  none). With it and no driver, a run-time implementation generates the
  domain's edges itself; derived domains tick from their source.
- A root clock domain with a `period` and no driver is driven by the
  implementation: it is not `FW-E-DOM-NODRIVER`. A run-time
  implementation puts its first edge at `period`, then one every
  `period`. A static front end gives the top module an input pin for it
  (named as a domain pin is), which the test bench drives.

## Lowering

A static front end lowers `step` blocks, `comb` blocks and `reset_state()`
to RTL. It does not lower:

- `run()`: asked to emit a component that implements `fw_run_if` is
  `FW-E-EMIT-RUN`, on the component;
- `fw_time`, or a waiting domain operation, in a lowered process:
  `FW-E-EMIT-TIME`, on the component. `in_reset` is lowered in `step()`
  and `comb()`.
