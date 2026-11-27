---
name: fw-hdl
description: Model hardware with Featherweight-HDL (fw-hdl) — SystemVerilog classes written
  against fw-hdl-spec's API (fw_hdl_pkg, fw_hdl_std_pkg) that describe a design as a tree of
  components with typed ports and bundles, sync behavior in step()/comb() blocks, clock and
  reset domains, method-level APIs (fw_port/fw_export), protocols and transactors. One
  description is simulated on fw-hdl-rt-sv and statically elaborated/lowered to Verilog by
  fw-hdl-fe-sv (dfm tasks fw.hdl.fe.sv.Scan, Elaborate, EmitSV). Use when writing or reading
  fw-hdl models, wrappers of existing RTL, transactors, or testbenches of fw-hdl components.
---

# Featherweight-HDL: modeling

fw-hdl describes hardware as SV classes, and one description serves three packages.
**fw-hdl-spec** is the API (`fw_hdl_pkg`, declarations only) and the standard library
(`fw_hdl_std_pkg`); **fw-hdl-rt-sv** runs a model in a simulator; **fw-hdl-fe-sv**
elaborates it statically, checks it, and lowers `step()`/`comb()` to Verilog.

A model package: `` `include "fw_hdl_macros.svh" `` before `package my_pkg;`, then
`import fw_hdl_pkg::*; import fw_hdl_std_pkg::*;`.

Write only what can't be derived: wiring of clocks/resets follows from domains,
register vs. wire from who writes a signal, module ports from bundles, transactor
choice from the protocol. If you find yourself spelling something the tools could
work out, look for the API that derives it.

## 1. Components, creation, phases

- Declare handles with API classes; **create everything with `T::create(name, parent[, params])`**,
  never `new` (`FW-E-ELAB-NEW`). Constructors take no arguments.
- A concrete component uses `` `fw_component_utils(T) `` (parameterized:
  `typedef c #(T) this_t;` + `` `fw_component_param_utils(c) ``).
- Phases run top-down: `build()` creates children, signals, ports, bundles, domains;
  `connect()` connects and ties (only there). Resolution then reports *all* errors.

**Params** (counts, depths, modes, realization choice) are a struct per component;
class parameters are for types/shapes:

```systemverilog
class fifo #(type T = bit[7:0]) extends fw_component;
    typedef struct { int depth; } params_t;           // no defaults here
    static function params_t mk_params(int depth = 2); // the one source of defaults
        params_t p; p.depth = depth; return p;
    endfunction
    `fw_component_params                               // declares read-only `params`
    `fw_component_utils(fifo #(T))                     // declares create()
    ...
endclass
u = fifo #(T)::create("u", this, fifo #(T)::mk_params(.depth(4)));
```

- Realization choice: a param of type `fw_ctor #(Base)`, filled with
  `fw_ctor_of #(Base, Impl)::get()` (a per-type factory handle) and used as
  `params.fifo_h.create("u", this, ...)`. Non-constant defaults go in an
  `init_params` function named by `` `fw_component_params_init(init_params) ``.
- An integrator overrides from above, in `build()` before the target is created:
  `fw_param_override #(P)::set(this, "chain.u[0]", v)` or `::edit(this, "**", e)`
  (globs over instance paths; `e` extends `fw_param_edit #(P)` and overrides `apply`).

Worked example of all of this: fw-hdl-spec `tests/sv/smoke/smoke_pkg.sv`.

## 2. Signals, bundles, connections

- Ports: `fw_input #(T)`, `fw_output #(T)`, `fw_inout #(T)`; a local signal is
  `fw_signal #(T)`. `T` is packed (bit/logic vectors, packed structs/unions, enums).
  Types must be equivalent across a connection: no implicit width change.
- A **bundle type** extends `fw_bundle_base`, declares members from the
  *initiator's* view, creates them in its `build()`, and names its protocol with
  `` `fw_bundle_utils(C, PROTO) ``. A bundle is never used bare; each use picks a role:
  `fw_bundle #(B)` (initiator), `fw_mirror #(B)` (target: directions flipped),
  `fw_monitor #(B)` (every member an input; for checkers and taps).
- Connections, in `connect()`, only among the component's own ports/bundles/locals
  and its *direct* children's (`FW-E-CONN-SCOPE`):

| Call | Use |
|---|---|
| `a.out.connect(b.in)` | sibling initiator to mirror (symmetric) |
| `u.in.connect_up(in)` | pass a child's endpoint up through the parent's of the same role |
| `mon.p.connect(u.out)` | tap any role with a monitor |
| `connect_all('{ '{u.clk, clk}, '{u.rst, rst} })` | many pairs at once |
| `s.tie(v)` / `chain.in.valid.tie(0)` | constant driver |

Checked: one driver per net, no undriven net, no open child input
(`FW-E-NET-MULTI`, `-NET-UNDRIVEN`, `-IN-OPEN`). Bundles flatten to `<bundle>_<member>` ports.

## 3. Behavior: step, comb, reset_state, run

A component gets processes by **implementing** interfaces; nothing registers them:

| Implements | Method | Kind | Lowers to |
|---|---|---|---|
| `fw_step_if` | `function void step()` | clocked | `always_ff` |
| `fw_comb_if` | `function void comb()` | combinational | `always_comb` |
| `fw_reset_state_if` | `function void reset_state()` | reset values | the reset branch |
| `fw_run_if` | `task run()` | behavioral | nothing (simulation only; `FW-E-EMIT-RUN` if emitted) |

- `s.read()` on any direction; `s.write(v)` (whole value) not on an effective input.
- **Register or wire follows from the writer**: written in `step()` it is a register
  (visible after the edge, like `<=`); in `comb()` a wire (visible in the same
  settle). Two writing blocks is `FW-E-WRITE-MULTI`. A comb loop that doesn't
  settle in 64 passes is `FW-E-COMB-LOOP`.
- At an edge: every `step` reads pre-edge values, then registers update, then
  `comb` blocks settle. While the reset domain is asserted, `reset_state()` runs
  instead of `step()`; without it, `step()` handles reset with
  `fw_reset_domain::in_reset(this)`. A component driving a protocol sets its
  outputs in `reset_state()`.
- More than one block: `` `fw_step(name) `` / `` `fw_comb(name) `` in the class body,
  each a separate process calling `function void name()`. A `step` that writes
  signals of two clock domains must be split this way (`FW-E-STEP-DOMAINS`).

```systemverilog
class cnt extends fw_component implements fw_step_if, fw_reset_state_if;
    `fw_component_utils(cnt)
    fw_output #(bit [7:0]) q;
    virtual function void build();       q = fw_output #(bit [7:0])::create("q", this); endfunction
    virtual function void reset_state(); q.write(8'h5a);              endfunction
    virtual function void step();        q.write(q.read() + 8'd1);    endfunction
endclass
```

**Task code** (`run()`, export tasks) is simulation-only and never runs inside an
edge. It waits with `fw_clock_domain::tick(this, n)`,
`fw_reset_domain::wait_reset_done(this)`, `wait_assert(this)`, `fw_time::delay(d)`.
Keep protocol timing out of it: task code hands work to sync code through
**task-sync crossings** (§6), which lower to ready/valid ports.

## 4. Domains: clock and reset

No clock or reset is wired by hand. A component creates domains in `build()`,
associates them with `set`, and everything not set inherits from its parent
(a port from its component). One `set(this, clk)` at the top covers the design.

```systemverilog
virtual function void build();
    clk = fw_clock_domain::create("clk", this, fw_clock_kind::root(10ns)); // period: rt-sv makes the edges
    rst = fw_reset_domain::create("rst", this, fw_reset_kind::root(fw_reset_kind::SYNC, clk));
    fw_clock_domain::set(this, clk);
    fw_reset_domain::set(this, rst);
    fw_clock_domain::set(out, clk_b);              // one interface in another domain
endfunction
virtual function void connect();
    rst.drive(rg.rst_n, fw_reset_kind::active_low()); // a net driver, with polarity
    clk_b.drive(clk_b_i);
endfunction
```

- Derivations: `fw_clock_kind::derived(clk, .div(2))`, `phase`, `gated`, `muxed`;
  `fw_reset_kind::synced(por, clk)`, `combined`, `software`. Relations
  (`FW_DOMAIN_SAME/RELATED/UNRELATED`) are computed from sources;
  `fw_clock_domain::relate(a, b)` in `build()` lets structure depend on them
  (plain FIFO vs. dual-clock FIFO).
- A child in several domains of one kind reads named associations,
  `fw_clock_domain::get(this, "wr")`; the parent sets them with
  `set(child, wr_clk, "wr")`.
- Connections across domains are checked (`FW-E/W/I-DOM-CROSS`); a component whose
  own interfaces differ in domain is the crossing element. Waive a safe one in
  `connect()`: `fw_clock_domain::waive(a, b, "reason")`.
- Custom kinds: `extends fw_domain_kind` + `` `fw_domain_kind_utils `` (`docs/domains.rst`).

## 5. Method level: APIs, ports, exports, configuration

- An **API** is a plain interface class of tasks/functions, ideally with no fw-hdl
  dependency (wb_xtor's `wb_if` lives in its own package). Outputs lead:
  `task access(output rsp_t rsp, input req_t req)`.
- `fw_port #(API)` is the required side; `p.get_if()` returns what it reaches.
  `fw_export #(API)` is the provided side: a component that `implements API` is its
  own export's implementation, no call needed (`set_imp(obj)` names another).
  `fw_socket #(OUT, IN)` carries calls both ways and connects to `fw_socket #(IN, OUT)`.
- Connect like signals: `drv.p.connect(x.t)`, `connect_up` through a parent. A port
  binds once (`FW-E-SOCK-MULTI`); every port must reach an export (`FW-E-SOCK-UNBOUND`).
- Configuration is a struct on endpoints, not on the protocol: the owner holds
  `fw_cfg_src #(T)` (`set(v)` pushes a whole copy), readers `fw_cfg_sink #(T)`.

## 6. Protocols, std and transactors

A **protocol** class is a hub of static facts; APIs, bundles and transactors
register with it and it names none of them:

```systemverilog
class wb_proto #(int AW = 32, int DW = 32) extends fw_protocol;
    typedef wb_proto #(AW, DW) this_t;
    `fw_protocol_param_utils(wb_proto, wb_if #(AW, DW))   // REQ API [, RSP API]
endclass
virtual class wb_bundle #(int AW = 32, int DW = 32) extends fw_bundle_base;
    `fw_bundle_utils(wb_bundle, wb_proto #(AW, DW))
    fw_output #(bit [AW-1:0]) adr;  ...  fw_input #(bit) ack;
    ...
endclass
```

Non-parameterized: `` `fw_protocol_utils(C, REQ, RSP) ``. Lookups key on type handles
(`P::get_type()`, `fw_api_type_of #(API)::get()`, `fw_ctor_of #(B, D)::get()`),
never on type-name strings.

**std (`fw_hdl_std_pkg`)** — use these before writing your own:

| Class | What |
|---|---|
| `fw_put_if`, `fw_get_if`, `fw_reqrsp_if`, `fw_mem_if` | protocol-neutral APIs |
| `fw_rv_proto #(T)`, `fw_rv_if #(T)` | ready/valid protocol and bundle (`valid`, `ready`, `data`) |
| `fw_rv_initiator #(T)` | `put(d)` drives the beat; returns at the handshake; no added cycle |
| `fw_rv_target #(T)` | each beat becomes a `put` through its port `p` |
| `fw_rv_get_ep #(T)` | pull side: `get(d)` raises `ready` only while called |
| `fw_rv_monitor #(T)` + `fw_rv_mon_listener` | `put_pre`/`put_post` at first cycle / handshake; `add_listener(l)` |
| `fw_to_sync_ep`, `fw_from_sync_ep` | the outside of a lowered crossing (mixed sim) |
| `fw_inbox #(T)` | a put/get queue for tests; `stall` back-pressures |
| `fw_timed_channel` | base of a kit's timed channel |

Back to back with no RTL: `xi.pins.connect(xt.pins)`, a monitor taps the same bundle.

**Transactors** are one class each: the API on one side, the bundle on the other.
Extend `fw_xtor_initiator #(B)` (gives `fw_bundle pins` and `fw_export t`),
`fw_xtor_target #(B)` (`fw_mirror pins`, `fw_port p`) or `fw_xtor_monitor #(B)`
(`fw_monitor pins`), register with `` `fw_xtor_utils(C) `` /
`` `fw_xtor_param_utils(C) ``, and call `super.build()` first.

**Pins are driven by `step()`/`comb()`, never by `run()`.** The API task only hands
off through `fw_to_sync #(T)` / `fw_from_sync #(T)` (created in `build()`):

| | Task side | Sync side |
|---|---|---|
| `fw_to_sync` | `put` (blocking), `try_put` | `valid()`, `peek()`, `take(t)` (step only) |
| `fw_from_sync` | `get` (blocking), `try_get` | `ready()`, `waiting()`, `give(v)` (step only) |

From fw-hdl `examples/wb_xtor/src/wb_pkg.sv` (no thread at all):

```systemverilog
class wb_initiator #(int AW = 32, int DW = 32) extends fw_xtor_initiator #(wb_bundle #(AW, DW))
        implements wb_if #(AW, DW), fw_comb_if, fw_step_if;
    typedef wb_initiator #(AW, DW) this_t;
    `fw_xtor_param_utils(wb_initiator)
    fw_to_sync #(req_t) reqs;  fw_from_sync #(rsp_t) rsps;   // created in build()
virtual task access(output rsp_t rsp, input req_t req);
    reqs.put(req);  rsps.get(rsp);                 // hand off, wait
endtask
virtual function void comb();                      // drive the bus from the waiting request
    req_t r = reqs.peek();
    bit   v = reqs.valid() && rsps.ready();
    pins.cyc.write(v);  pins.stb.write(v);  pins.adr.write(r.adr);  ...
endfunction
virtual function void step();                      // at the termination edge
    req_t r; rsp_t p;
    if (pins.stb.read() && (pins.ack.read() || pins.err.read())) begin
        void'(reqs.take(r));
        p.dat = pins.dat_r.read();  p.err = pins.err.read();
        void'(rsps.give(p));
    end
endfunction
```

(A class implementing an interface class doesn't inherit its typedefs, so the
transactor re-declares `typedef wb_if #(AW, DW)::req_t req_t;`.)

A target that calls out through its port keeps a `run()` *only* to make that call
(`reqs.get(r); i.access(s, r); rsps.put(s);`); its pin timing stays in
`step()`/`comb()`. A class with `run()` can't be lowered. `take`/`give` in `comb()`
is `FW-E-XING-COMB`; task code touching signals beyond its own and its children's is
`FW-E-RUN-SYNC-ACCESS`.

**Writing a protocol kit** (protocol + APIs + payloads + bundles, with GenKit deriving
proxies, listeners, transactions, pin maps and rv transactors): use the
**fw-proto-kit** skill. Don't hand-write what GenKit derives.

## 7. Wrapping existing RTL

A wrapper implements `fw_extern_if`, uses `` `fw_extern_utils(T, "module_name") ``
instead of `fw_component_utils`, declares ports/bundles in `build()`, and maps
them in `extern_map(fw_extern_map m)`:

```systemverilog
virtual function void extern_map(fw_extern_map m);
    m.param("DEPTH", fw_value #(int)::of(params.depth));
    fw_clock_domain::pin(m, "clk");                    // the wrapper's domains
    fw_reset_domain::pin(m, "rst_n", null, fw_reset_kind::active_low());
    void'(m.prefix(in, "in_").rename("valid", "vld").rename("ready", "rdy"));
    // anything unmapped: pin named by its flattened name (in_data)
endfunction
```

Also `m.pin(name, sig)`, `m.tie(name, v)`, `m.open(name)`, `m.unused(obj)`. With
the module's source available, fe-sv checks every pin, direction and width
(`FW-E-EXT-*`). Guide: `docs/wrapping.rst`.

## 8. Scan, elaborate, emit, run

Model sources are dfm FileSets of type **`fwHdlSource`**; RTL of externs is
`systemVerilogSource`. fe-sv tasks (package `fw.hdl.fe.sv`):

- `Scan`: no top; finds protocols, bundles and transactors (`scan.json`, `scan.zir`).
- `Elaborate` (`with: {top: "pkg::chain#(bit[7:0])"}`): elaborates, checks, maps to IR;
  then `EmitSV` (`top_module`) writes Verilog.
- `GenKit`: a kit's derived classes (fw-proto-kit). `GenAcc`: optional debug accessors.

```yaml
- {name: src, uses: std.FileSet, with: {type: fwHdlSource, base: src, include: [wb_pkg.sv]}}
- {root: scan, uses: fw.hdl.fe.sv.Scan, needs: [src]}
```

- A scan sees a parameterized class only through a specialization, so scan a
  source that names one (a bench or a typedef).
- `Elaborate` maps to IR for emission, so a top with `run()` fails there
  (`FW-E-EMIT-RUN`). Elaborate testbench tops with rt-sv instead.
- Running on rt-sv: compile the dfm fileset `fw.hdl.rt.sv.fw_hdl_pkg` before your
  sources. `fw_elab #(T)` elaborates `T` as `top` (netlist with
  `+fw_netlist=<path>`) but doesn't run it; rt-sv has no public elaborate-and-run
  entry yet, so copy wb_xtor's `tb/wb_xtor_tb_top.sv` and don't build on its
  internal calls. `fw_pin_bridge #(type T, "top.path")` joins a class signal
  (or a clock domain) to a module pin for mixed class/RTL simulation.
  fe-sv's `gen_tb`/`gen_bind` generate a bench and bind monitors for std
  ready/valid DUT ports (`docs/protocols.rst`, "Testbenches and bind modules").

A bench's top component creates a root clock with a period (`fw_clock_kind::root(10ns)`;
nothing else drives it), `set`s it on itself, creates the driver, transactors and
models, and connects them: wb_xtor's `tb/wb_xtor_tb.sv`, class `top_c`.

## 9. Where to look (fw-hdl-spec, `$IVPM_PACKAGES/fw-hdl-spec`)

- Guides (`docs/`): `overview.rst` (recipe, phases), `wrapping.rst`, `domains.rst`,
  `protocols.rst`, `std.rst`, `api/processes.rst`; API reference under `docs/api/`.
- Rules (`semantics/`): `elaboration`, `params`, `signals`, `bundles`, `connections`,
  `processes` (edges, crossings, lowering), `domains`, `protocols`, `diagnostics` (`FW-E-...`).

Declarations with doc comments: `bindings/sv/*.svh`, `bindings/sv/fw_hdl_macros.svh`,
`std/*.svh`. Small runnable models for any one rule: `conformance/<scenario>/top.sv`.
Worked examples: `tests/sv/smoke/smoke_pkg.sv` (params, ctor factories, overrides,
externs) and fw-hdl's `examples/wb_xtor` (protocol, bundle, transactors, bench, mixed
sim, scan). Some prose in `docs/protocols.rst` predates the macros; where it differs,
`bindings/sv` and `std/` are authoritative.
