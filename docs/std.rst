The standard library
====================

``fw_hdl_std_pkg`` (``std/``) is written against ``fw_hdl_pkg`` like any
user's package, and is shipped as hand-written source only. Its derived
collateral (bases, listeners, proxies, transactions; see
:doc:`protocols`, "What is generated") is generated from it at build
time by the kit stage, so a design imports both:

.. code-block:: systemverilog

   import fw_hdl_pkg::*;
   import fw_hdl_std_pkg::*;

The protocol-neutral APIs
-------------------------

APIs that many protocols share, so that a model written against one
works with any protocol that declares it.

.. autosvclass:: fw_hdl_std_pkg::fw_put_if
   :members:

.. autosvclass:: fw_hdl_std_pkg::fw_get_if
   :members:

.. autosvclass:: fw_hdl_std_pkg::fw_reqrsp_if
   :members:

.. autosvclass:: fw_hdl_std_pkg::fw_mem_if
   :members:

Ready/valid
-----------

The ready/valid protocol and its bundle type. A channel of a bundle of
channels is an ``fw_rv_if`` member; the kit derives the channel APIs
and the pin-map preset from them.

.. autosvclass:: fw_hdl_std_pkg::fw_rv_proto
   :members:

.. autosvclass:: fw_hdl_std_pkg::fw_rv_if
   :members:

The zero-latency initiator and target transactors and the monitor. The monitor's pin
logic is the core ``fw_rv_mon_core``, which lowers to RTL; its ``run()``
reads the core at each edge.

.. autosvclass:: fw_hdl_std_pkg::fw_rv_initiator
   :members:

.. autosvclass:: fw_hdl_std_pkg::fw_rv_target
   :members:

The get endpoint is the pull counterpart of the initiator: a task calls
``get``, which raises ``ready`` for the call and returns the beat at its
handshake edge. Unlike the target, it takes nothing until a ``get`` is
pending.

.. autosvclass:: fw_hdl_std_pkg::fw_rv_get_ep
   :members:

The crossing endpoints are the outside of a task-sync crossing that a
static front end has lowered to ready/valid ports (``semantics/processes.md``,
"Lowering"): in a mixed simulation, task code calls them where it called the
crossing. ``fw_from_sync_ep`` is ready on room, with ``waiting`` for the
owner's ``<x>_wait``; ``fw_rv_get_ep`` is ready only while a ``get`` waits.

.. autosvclass:: fw_hdl_std_pkg::fw_to_sync_ep
   :members:

.. autosvclass:: fw_hdl_std_pkg::fw_from_sync_ep
   :members:

.. autosvclass:: fw_hdl_std_pkg::fw_rv_monitor
   :members:

.. autosvclass:: fw_hdl_std_pkg::fw_rv_mon_listener
   :members:

.. autosvclass:: fw_hdl_std_pkg::fw_rv_mon_core
   :members:

The pair runs back to back with no RTL: an initiator's ``pins`` connect
straight to a target's (``xi.pins.connect(xt.pins)``), a monitor taps the
same bundle, and the root clock is ticked by the runtime. At full rate the
target delivers one beat per cycle; a stalled beat is reported by the
monitor from its first offer to its handshake. ``fw_rv_mon_core`` is also
proved with SymbiYosys (bounded model check and cover of a stalled beat).

Timed channels
--------------

The base of a kit's timed channel (see :doc:`protocols`, "Timing"). A kit
channel extends it, gives the transfer time and, for a channel between
two configured devices, the mismatch rule.

.. autosvclass:: fw_hdl_std_pkg::fw_timed_channel
   :members:

Runtime pieces
--------------

.. autosvclass:: fw_hdl_std_pkg::fw_inbox
   :members:
