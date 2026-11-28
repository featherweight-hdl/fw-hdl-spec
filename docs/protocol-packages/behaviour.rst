Writing the behaviour
=====================

Step 5. What cannot be derived is written by hand, against the generated
package: adapters between the protocol's own API and its channels, a
reference model, a transactor where the pins are not ready/valid, and, when
the protocol needs them, configuration and timed channels. All of it is
ordinary fw-hdl components (:doc:`../overview`). For sbus it is
``docs/examples/sbus/src/sbus_behav_pkg.sv``.

Adapters
--------

An adapter is a plain component that provides a higher-level API and
drives a lower one: one call becomes channel beats, and response beats
become the call's results. It adds no pins and no transactor, and adapters
stack (bursts over single beats). sbus has one per side.

The initiator side provides ``sbus_if`` and holds a socket to the channel
APIs, which a generated initiator serves:

.. literalinclude:: ../examples/sbus/src/sbus_behav_pkg.sv
   :language: systemverilog
   :dedent:
   :start-at: // Initiator side
   :end-at: endclass

The target side takes request beats from a generated target, runs each as
an ``sbus_if`` call on a model, and sends the response back:

.. literalinclude:: ../examples/sbus/src/sbus_behav_pkg.sv
   :language: systemverilog
   :dedent:
   :start-at: // Target side
   :end-at: endclass

Rules for this layer:

- **A response may arrive inside its request's call.** Be ready for it
  before calling: ``sbus_host`` queues responses rather than waiting for
  one after ``req`` returns.
- **Response calls may block.** Queue them and send from one loop per
  response channel (``sbus_dev::run``), so a stalled response never holds
  up the call that receives requests.
- **Pass payloads through unchanged.** Where a configuration leaves fields
  off the pins, zero them with ``<p>_payloads::<n>_mask``, so a link with
  pins and one without deliver the same beats.
- **Match responses to requests** by ID where the protocol has IDs, by
  order where it does not.
- A protocol-independent API (``fw_mem_if``, or sbus's ``sbus_if``) lets
  models and tests pick a protocol by picking its adapter.

A reference model
-----------------

The model implements the target-side API and nothing else: no pins, no
time. sbus's is a memory that answers an error above ``0xF0``:

.. literalinclude:: ../examples/sbus/src/sbus_behav_pkg.sv
   :language: systemverilog
   :dedent:
   :start-at: // The reference model
   :end-at: endclass

The same model then answers the generated transactors back to back, and is
what an RTL implementation is checked against (:doc:`testing`).

Endpoints and sockets
---------------------

The adapters above use the three endpoint kinds. In short (the rules are
in :doc:`../protocols`, "Endpoints and sockets"):

- ``fw_port #(API)`` is the side that calls: ``p.get_if().m(...)``.
  ``fw_export #(API)`` is the side that provides. ``fw_socket #(OUT, IN)``
  calls ``OUT`` and provides ``IN``; its peer is ``fw_socket #(IN, OUT)``,
  and one ``connect`` binds both directions.
- A component that implements the API is its export's implementation, with
  no call (``sbus_mem`` for ``t``, ``sbus_host`` for ``t`` and for ``s``'s
  ``IN``). ``set_imp(obj)`` names another object; ``<api>_imp #(IMP)``
  forwards to one, for a component that must provide the same API twice.
- Endpoints are created in ``build()`` and bound in ``connect()``
  (elsewhere ``FW-E-CONN-PHASE``). A port binds once
  (``FW-E-SOCK-MULTI``); an export may serve many ports; every port must
  reach an export by the end of the connect phase
  (``FW-E-SOCK-UNBOUND``); when lowering, a target's port that only its
  hand-off ``run()`` calls through may stay unbound. ``connect_up`` passes a child's endpoint
  through its parent's.
- Endpoints take domain associations as bundles do, so a method-level
  connection between two clock domains is reported as a domain crossing.

Hand-written transactors
------------------------

A bundle whose channels are all ``fw_rv_if`` gets its transactors from
GenKit. Any other bundle (APB, a UART line, a bus sampled every cycle)
needs them written by hand. The worked example is *apb*, an APB-style bus
with one transfer in flight, in ``docs/examples/apb/`` of fw-hdl-spec:

.. list-table::
   :header-rows: 1
   :widths: 35 65

   * - File
     - What it is
   * - ``src/apb_pkg.sv``
     - the whole package: payloads, the API ``apb_if``, the protocol, the
       bundle, and the initiator and target transactors
   * - ``tb/apb_tb.sv``, ``tb/apb_tb_top.sv``
     - the two back to back over one bundle, with a memory model, a
       driver and a pin-level checker; ``+mut`` swaps in a broken
       initiator, which must fail
   * - ``tb/apb_emit.sv``
     - both transactors on a top's pins, for lowering to SV
   * - ``check.py``, ``flow.yaml``
     - runs it all (``dfm run check``): the bench and its mutant in
       rt-sv, the bench in fe-sv's static elaboration, and the lowered
       transactors linted

.. code-block:: shell

   direnv exec . python packages/fw-hdl-spec/docs/examples/apb/check.py build/apb

The declarations are those of :doc:`declare`: payload structs and the API
at package level, the protocol naming its API in its macro, and the bundle
naming its protocol:

.. literalinclude:: ../examples/apb/src/apb_pkg.sv
   :language: systemverilog
   :dedent:
   :start-at: // One request
   :end-before: // The initiator.

**Task code never touches signals.** A transactor has two kinds of code:
*task code* (its API task, its ``run()``), which only hands items through
task-sync crossings, and *sync code* (``comb()`` and ``step()``), which is
the only code that reads and writes pins. An ``fw_to_sync #(T)`` carries
items from task code into sync code, an ``fw_from_sync #(T)`` carries them
out; the task side calls ``put`` and ``get``, the sync side looks with
``valid``/``peek`` or ``ready``/``waiting`` in ``comb()`` and moves items
with ``take``/``give`` in ``step()`` (rules X1-X8 in
``semantics/processes.md``, "Task-sync crossings"). The protocol timing is
then all in sync code, which lowers to RTL; the crossings lower to
ready/valid ports of the module.

The initiator implements the API. ``access`` puts the request and gets the
response, and that is all; ``comb()`` drives the transfer from the waiting
request, and ``step()`` moves it through the setup and access phases and,
at the edge where PREADY is high, takes the request and gives the
response, so ``access`` returns at that edge:

.. literalinclude:: ../examples/apb/src/apb_pkg.sv
   :language: systemverilog
   :dedent:
   :start-at: class apb_initiator
   :end-at: endclass

The target calls the API through its port, so it has a ``run()``, which
only hands off: it gets each request from a ``fw_from_sync``, makes the
port call, and puts the response to a ``fw_to_sync``. ``step()`` gives the
request at the setup edge and takes the response at the edge that ends the
transfer; ``comb()`` raises PREADY while a response waits:

.. literalinclude:: ../examples/apb/src/apb_pkg.sv
   :language: systemverilog
   :dedent:
   :start-at: class apb_target
   :end-at: endclass

A transactor:

- extends the base class of its role over the protocol's bundle type,
  ``fw_xtor_initiator``, ``fw_xtor_target`` or ``fw_xtor_monitor``, and
  registers with ```fw_xtor_utils(C)`` (or ``_param_utils`` with
  ``this_t``), which also declares ``create``;
- has a **pin side**, the base's ``pins``: an ``fw_bundle`` for an
  initiator, an ``fw_mirror`` for a target, an ``fw_monitor`` for a
  monitor, created by the base's ``build()`` (an override calls
  ``super.build()`` first, then creates its crossings). Its role and
  protocol are the base's, static facts of the class;
- has a **method side**: the base's export ``t`` of the protocol's request
  API for an initiator (the transactor implements the API), its port ``p``
  for a target. This is the usual shape, not a rule: the method side does
  not set the role and is not checked against the pin side;
- drives and samples the pins only in ``comb()`` and ``step()``, with
  ``write()`` and ``read()``; clock and reset come from its component's
  domains, and ``reset_state()`` resets its own state;
- hands every call through task-sync crossings: an API task only puts and
  gets, a ``run()`` only gets, calls its port and puts. Its task code
  neither reads nor writes a signal and has no ``tick`` of its own: it blocks only in the
  crossings, which return at an edge;
- **adds no latency**: a call drives the pins from the edge it is made at
  and returns at the edge that ends the transfer; nothing is buffered
  (depth-1 crossings).

A ``run()`` that only hands off is left out of the RTL when the
transactor is lowered, as an API task is; one that does more is
``FW-E-EMIT-RUN`` (:doc:`reference`). std's ready/valid initiator and
target (``std/fw_rv_xtor.svh``) have the same shape over one ready/valid
channel, and fw-hdl ``examples/wb_xtor`` is a larger one (Wishbone, with a
generated shell and bridges).

Monitors are covered later: their pin-to-listener side waits for a
sync-to-task crossing. The conformance scenario ``proto_xtor`` has an
initiator, a target and a monitor of one protocol registered by hand.

The tools find a transactor statically: from a bundle, its protocol, its
registered transactors, and the one whose pin side is the opposite mixin
of the same bundle type (``ScanResult.xtor_for(bundle, kind)`` in
fw-hdl-fe-sv). A parameterized transactor is found only through a
specialization the scanned source names; fw-hdl-fe-sv
``tests/unit/gen/src/proto_chan/xtor_use.sv`` names its ``#(8)`` ones with
typedefs for this.

Configuration
-------------

A protocol that is configured (baud, parity, stop bits) carries the
configuration as a struct on the endpoints, never on the protocol, and
each side of a link has its own:

- the owner (the device) holds an ``fw_cfg_src #(CFG)`` and commits a new
  value with ``set(v)``, which pushes a whole copy to every bound sink;
- each reader holds an ``fw_cfg_sink #(CFG)`` and reads its ``cfg``
  field, sampling it when a transfer starts. Only the runtime writes it
  (``FW-E-CFG-WRITE``), and a sink no source reaches is
  ``FW-E-CFG-UNBOUND``;
- when the configuration travels with an API, use a configured endpoint
  (``fw_port_cfg_src``, ``fw_export_cfg_sink``, ``fw_socket_cfg_sink``
  and the rest), so one ``connect`` binds both;
- a reader that must act on a change implements ``fw_cfg_listener_if`` and
  registers with ``add_listener`` on its sink.

:doc:`../protocols`, "Configuration", has the full rules and the UART
example. fe-sv's static elaboration records the source to sink bindings
but not values or listeners (:doc:`reference`, "Known limits").

Timed channels
--------------

A protocol carries no timing. Where a method-level link should take wire
time (a UART character time), the package provides a *timed channel*: a
component extending ``fw_timed_channel #(CFG, T)`` that the user places
between two endpoints. Elaboration never inserts one. The channel defines
``xfer_time(cfg, t)`` and, when the two ends can disagree,
``mismatch(tx_cfg, rx_cfg, t)``; the base supplies ``xfer_fwd`` and
``xfer_sink``, which wait the transfer time. A forwarding channel, between
a device and a VIP, from the conformance library
(``conformance/_lib/test_uart_chan.svh``):

.. literalinclude:: ../../conformance/_lib/test_uart_chan.svh
   :language: systemverilog
   :dedent:
   :start-at: class uart_tx_chan
   :end-at: endclass

A *sinking* channel joins two devices, each with its own configuration;
each direction is timed by its sender's and ``mismatch`` gives what the
receiver sees (``uart_txrx_chan`` in the same file, and
:doc:`../protocols`, "Timing"). Timed channels are simulation only: they use
``fw_time``. The conformance scenario ``proto_timed`` places both kinds,
and fw-hdl-fe-sv ``tests/e2e/test_timed_chan.py`` checks that static
elaboration records them as plain components.

Abstractors
-----------

When the abstract level is a protocol on its own (packets over a byte
PHY), there are two protocols and an *abstractor* between them: a
component with an endpoint or bundle of each, registered with both by
```fw_abstractor_utils(C, FROM, TO)``. Neither protocol names the other.
It converts one hop. What the upper level keeps is exactly its payload's
fields, so what it drops is dropped visibly. See :doc:`../protocols`,
"Abstractors", and the conformance scenario ``proto_abs``.

Next: :doc:`testing`.
