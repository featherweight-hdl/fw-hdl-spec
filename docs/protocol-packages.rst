Writing a protocol package
==========================

This guide walks through building a protocol package: the SV package that
carries one interface standard (ready/valid, Wishbone, AXI4, AXI4-Lite,
APB) so that components can talk it at the method level and RTL at the pin
level. It is a how-to; the reference material (the protocol hub, bundles,
sockets, the full table of generated classes, transactors, abstractors,
configuration, timing, testbenches) is in :doc:`protocols`, and the guide
links there rather than repeating it.

The worked example is the standard ready/valid protocol in ``std/``:
``fw_rv_proto.svh`` (the protocol), ``fw_rv_if.svh`` (the bundle) and
``fw_rv_xtor.svh`` (initiator, target, monitor). A protocol whose bundle is
a bundle of channels is in fw-hdl-fe-sv,
``tests/unit/gen/src/proto_chan/top.sv``.

The idea in one paragraph
-------------------------

You write a short source by hand: the protocol class, its method-level
APIs, its payload types and its pin-level bundles, in one SV package. The
fw-hdl-fe-sv generator ``GenKit`` reads that package and writes the rest
into ``<pkg>_gen_pkg``: channel APIs, bases, listeners and fan-outs,
proxies, imps, transactions, payload helpers, the pin map and, for a bundle
of ready/valid channels, the initiator, target and monitor transactors. You
then write only what cannot be derived: adapters from a higher-level API to
the channels, a reference model, and tests. The test of the split: adding a
field to a payload is a one-line change to the source.

0. Check the protocol fits
--------------------------

Split the protocol into its **independent activity streams**: each
direction with its own handshake that advances on its own is one channel.

.. list-table::
   :header-rows: 1

   * - Question
     - AXI4
     - AXI4-Lite
     - APB
   * - Channels
     - 5 (AW, W, B, AR, R), ready/valid
     - 5, ready/valid
     - 1 request/response phase pair (PSEL, PENABLE, PREADY)
   * - Transactors generated
     - yes
     - yes
     - no: only bundles whose channels are all ``fw_rv_if``

If every channel is ready/valid, everything below applies as is. If not,
the class side (steps 1-3, 5, 6) still works; the pin-level transactor is
written by hand (step 4).

Channels that are logically coupled stay separate channels (AXI4: W follows
AW, B completes the write). The coupling is a higher-level method
(``write()``) that an adapter composes from the channels (step 5).

1. The protocol
---------------

A class extending ``fw_protocol`` with only static members. Its
``declare()`` registers the APIs, at most one per direction. A
parameterized protocol declares ``this_t`` and uses
```fw_protocol_param_utils``:

.. code-block:: systemverilog

   class axi4_proto #(int AW = 32, int DW = 32) extends fw_protocol;
       typedef axi4_proto #(AW, DW) this_t;
       `fw_protocol_param_utils(axi4_proto)
       static function void declare(fw_protocol_decl d);
           d.api(fw_api_type_of #(axi4_mem_if #(AW, DW))::get(), FW_PROTO_REQ);
       endfunction
   endclass

Derived names start with the family name less a trailing ``_proto``
(``axi4``); set another with ``d.prefix("...")``. Never write names as
strings. Width parameters live on the protocol and the bundle: connection
checks and transactor choice key on the specialization, generators and
naming on the family. See :doc:`protocols`, "The hub".

2. Payloads and the bundle
--------------------------

**Payloads.** One packed struct per channel payload. Member names are the
protocol's names without the channel prefix (``addr``, not ``awaddr``).
Struct packing is the order the transactors put on the wire; pick it once.
Two channels that differ in one width need two structs. The generator
derives ``sprint``, ``compare`` and ``mask`` for each (``<p>_payloads``).

**The bundle.** It names its protocol with ```fw_bundle_protocol`` and is
written from the initiator's view. For a handshaked protocol make it a
**bundle of channels**: one ``fw_rv_if`` member per channel, ``fw_bundle``
for a channel the initiator drives, ``fw_mirror`` for one it receives. The
member type gives the direction; nothing else is tagged:

.. code-block:: systemverilog

   virtual class test_ch_bundle #(int W = 8) extends fw_bundle_base;
       `fw_bundle_protocol(test_ch_proto #(W))
       fw_bundle #(fw_rv_if #(logic [W-1:0])) req;   // initiator -> target
       fw_mirror #(fw_rv_if #(test_ch_rsp_t)) rsp;   // target -> initiator
       ...
   endclass

A protocol may have several bundle forms. Cross-channel facts (AXI4:
``len``\ +1 W beats per AW) do not go in the bundle; they are checks
(step 6). Clock and reset do not go in the bundle either: they come from
the domain of the component that holds the transactor (:doc:`domains`), and
a device's pin names and polarity go in its pin map. See :doc:`protocols`,
"The bundle".

For AXI4-Lite give it its own bundle; don't model it as AXI4 with absent
fields (``len``, ``size``, ``burst``, ``last`` are not optional in AXI4).

3. The APIs
-----------

Ordinary interface classes. An API cannot register itself: the protocol
registers it, and one API may belong to many protocols. The channel APIs
(``<p>_req_if``, ``<p>_rsp_if``, one task per channel) are derived from the
bundle; you write only the transaction-level ones.

- **Split by direction**: a request interface the initiator calls and a
  response interface the target calls back, where the protocol allows
  several transfers in flight (AXI4, AXI4-Lite). A request returns once
  accepted; responses arrive as calls. A blocking form is a shim on top.
  For APB, with one transfer in flight, one blocking request with its
  response (``read(addr, data, err)``) is enough.
- **Use the payload types** in the protocol's own API, so a new payload
  field reaches it with no other edit.
- A task if it may block, else a function; ``input`` and ``output`` only; no
  ``ref``, events or class handles; packed types and queues of them.

4. Generate
-----------

``GenKit`` scans the package and writes ``<pkg>_gen_pkg.sv``, which
imports ``fw_hdl_pkg`` and your package. In a flow, after the package's
``fwHdlSource`` FileSet:

.. code-block:: yaml

   - name: kit
     uses: std.FileSet
     with: {type: fwHdlSource, base: src, include: [axi4_pkg.sv]}
   - name: kit-gen
     uses: fw.hdl.fe.sv.GenKit        # optional: pkg_name
     needs: [kit]

It re-runs when its inputs or the generators change. ``fw.hdl.fe.sv.Scan``
writes the protocol table alone (``scan.json``, ``scan.zir``). From Python:
``gen_kit(scan([...], incdirs=[...]))`` (``fw.hdl.gen``,
``fw.hdl.fe.sv.scan``). fw-hdl-fe-sv ``tests/e2e/test_genkit_flow.py`` runs
it through dfm.

The full list of derived classes is in :doc:`protocols`, "What is
generated". Do not hand-write any of them; if the generator cannot derive
something you need, that is a generator gap to report, not code to put in
the package.

**Pin-level transactors.** For a bundle whose channels are all
``fw_rv_if`` there is nothing to write: ``<p>_initiator``, ``<p>_target``
and ``<p>_monitor`` are generated from the std ready/valid transactors, one
per channel, and registered with the protocol. A protocol with other pins
(APB, a UART line) needs a hand-written transactor: a component with an
endpoint on one side and the bundle on the other, registered with
```fw_xtor_utils(<xtor>, <proto>)``; ``std/fw_rv_xtor.svh`` is the shape.
See :doc:`protocols`, "Transactors".

5. Behaviour
------------

Hand-written, on the generated ``_base`` classes:

- **Adapters**: a plain component that provides a higher-level API and
  holds a port to the channel APIs, translating one call into channel
  beats and responses back up (matched per ID where the protocol has
  them). Adapters stack. A protocol-independent API such as ``fw_mem_if``
  (``std/fw_mem_if.svh``) lets models and tests pick a protocol by picking
  its adapter.
- **A reference model** behind the target-side API (a memory or a register
  file).
- **Abstractors**, when the abstract level is itself a protocol (packets
  over a byte PHY), registered with both protocols by
  ```fw_abstractor_utils`` (:doc:`protocols`, "Abstractors").

Rules for this layer:

- Pass payloads through unchanged; zero fields a configuration leaves off
  the pins with ``<p>_payloads`` ``mask``, so a link with pins and one
  without deliver the same beats.
- A response may arrive inside its request's call; be ready for it before
  calling.
- Response calls may block: queue them and send from one loop per response
  channel, so a stalled response never holds up the request loop.
- A method-level link that should take wire time gets an explicit channel
  extending ``fw_timed_channel`` (:doc:`protocols`, "Timing"); elaboration
  never inserts one.

6. Tests
--------

Every suite needs teeth: run it once with a planted bug and check it fails.

.. list-table::
   :header-rows: 1

   * - Layer
     - Write
     - Example (fw-hdl-fe-sv)
   * - Back to back
     - generated initiator and target with their pins connected; traffic
       through the initiator's API against a model behind the target's;
       backpressure on both sides; every response variant; a listener on
       the monitor sees every beat
     - ``tests/unit/gen/src/proto_chan/xtor_b2b.sv``
   * - Against RTL
     - wrap the RTL (``<p>_pins::flat`` makes the extern map one line),
       elaborate and emit it; ``gen_tb`` generates the testbench (the
       opposite-role transactor per DUT port) and ``gen_bind`` the bound
       monitors; you write a subclass whose ``run()`` puts and gets
     - ``examples/wrap_rtl/``, ``tests/e2e/test_gen_tb.py``,
       ``test_gen_bind.py``
   * - Formal
     - protocol invariants as synthesizable checkers on the RTL: handshake
       stability, no phantom transfer, ordering and integrity with an
       ``(* anyconst *)`` index; immediate asserts with ``$past`` guarded
       by a past-valid reg; a ``cover`` per property
     - ``tests/e2e/sv/rv_formal.sv``

Run class and RTL tests over several parameter sets: the minimum (absent
fields everywhere), the default, and a wide set with distinct widths per
optional field so mix-ups show. See :doc:`protocols`, "Testbenches and
bind modules", and :doc:`wrapping` for wrapping RTL.

7. Wrapping a reference IP
--------------------------

A wrapper component names the module, its parameters, clock and reset, and
maps each port's bundle onto the module's pins (:doc:`wrapping`). Pick IPs
that stress something: two pin naming styles, both reset polarities, a
packed-vector port, something that reorders responses.
