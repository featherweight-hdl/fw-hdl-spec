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
  (``FW-E-SOCK-UNBOUND``). ``connect_up`` passes a child's endpoint
  through its parent's.
- Endpoints take domain associations as bundles do, so a method-level
  connection between two clock domains is reported as a crossing.

Hand-written transactors
------------------------

A bundle whose channels are all ``fw_rv_if`` gets its transactors from
GenKit. Any other bundle (APB, a UART line, a bus sampled every cycle)
needs one written by hand. std's ready/valid initiator is the shape:

.. literalinclude:: ../../std/fw_rv_xtor.svh
   :language: systemverilog
   :dedent:
   :start-at: class fw_rv_initiator
   :end-before: // The ready/valid target transactor

A transactor:

- is a component registered with ```fw_xtor_utils(C, PROTO)`` (or
  ``_param_utils`` with ``this_t``), which also declares ``create``;
- has a **pin side**, one member of the protocol's bundle type: an
  ``fw_bundle`` for an initiator, an ``fw_mirror`` for a target, an
  ``fw_monitor`` for a monitor. Its role is derived from this member only
  and is never stated;
- has a **method side**: an export of the protocol's request API for an
  initiator, a port of it for a target, listeners for a monitor. This is
  the usual shape, not a rule: the method side does not set the role and
  is not checked against the pin side;
- runs in ``run()`` (it implements ``fw_run_if``), waits for edges with
  ``fw_clock_domain::tick(this)``, and reads and writes pins with
  ``read()`` and ``write()``. Clock and reset come from its component's
  domains;
- **adds no latency**: a call drives the pins in the cycle it is made and
  returns at the handshake edge; nothing is buffered;
- hands calls to its own ``run()`` (``fw_rv_initiator::put`` through two
  mailboxes), so the pins are driven from the transactor's clock domain
  whoever calls it.

A monitor is a transactor whose pins are an ``fw_monitor`` and whose method
side is a list of listeners: it calls ``<m>_pre`` at the first cycle of a
transfer and ``<m>_post`` at its end, and never drives a pin. Keep its
per-cycle logic in a small component of ``fw_comb``/``step`` blocks (as
``fw_rv_mon_core``), which lowers to RTL and can be proved formally
(:doc:`testing`). The conformance scenario ``proto_xtor`` has an
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
``fw_protocol::abstractor_for(from, to)`` finds one hop in either
direction. What the upper level keeps is exactly its payload's fields, so
what it drops is dropped visibly. See :doc:`../protocols`, "Abstractors",
and the conformance scenarios ``proto_abs`` and ``proto_abs_query``. The
query looks among the classes the design names (a parameterized
abstractor: the specializations its source names), in fe-sv and rt-sv
alike.

Next: :doc:`testing`.
