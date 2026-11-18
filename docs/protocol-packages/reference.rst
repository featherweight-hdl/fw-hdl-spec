Diagnostics and known limits
============================

Diagnostics you will meet
-------------------------

Each diagnostic has a stable ID and a path (``semantics/diagnostics.md``
has the full list). These are the ones a protocol package and its tests
run into, where they come from, and the usual fix.

.. list-table::
   :header-rows: 1
   :widths: 24 16 60

   * - ID
     - From
     - Meaning and fix
   * - ``FW-E-SV``
     - fe-sv scan, elaborate
     - the source does not compile; the message is the SV compiler's
   * - ``FW-E-ELAB``
     - fe-sv
     - an error while running the source statically. ``fe-sv does not
       implement <class>::<method>`` means a call that only rt-sv supports
       (see Known limits)
   * - ``FW-E-GEN-PKG``
     - GenKit
     - the protocols, bundles, APIs and payloads are in several packages,
       a protocol or bundle is declared outside a package, or nothing of
       the kit is in a package of its own. Put them in one package
   * - ``FW-E-GEN-API``
     - GenKit
     - a registered API is not in the scanned source
   * - ``FW-E-GEN-SCOPE``
     - GenKit
     - a channel's payload type is a typedef declared inside a class (the
       bundle's); the message names the bundle, channel and type. Declare
       it at package level
   * - ``FW-W-GEN-UNSPEC``
     - GenKit
     - a parameterized bundle of channels that the scanned source never
       specializes gets no channel APIs and no transactors; the message
       names it. Name a specialization in the kit's package
       (``typedef my_bundle #(8) my_bundle_8_t;``)
   * - ``FW-W-GEN-4STATE``
     - GenKit
     - a channel's payload struct has a ``logic`` member: no
       ``<p>_payloads`` helpers and one pin for the whole payload. Use
       ``bit`` members
   * - ``FW-W-SCAN-IR``
     - Scan, GenKit, ``to_ir``
     - a type could not be mapped to Zuspec IR; the derived classes that
       need it may be missing
   * - ``FW-E-SCAN-STALE``
     - Elaborate after Scan
     - the elaborated protocol table differs from the scan: re-run Scan
   * - ``FW-E-PROTO-THIS``
     - fe-sv
     - a ``_param_utils`` class whose ``this_t`` is not its own
       specialization, parameters in order
   * - ``FW-E-PROTO-API``
     - fe-sv, rt-sv
     - ``declare()`` registers two APIs for one direction, or one twice
   * - ``FW-E-PROTO-XTOR``
     - fe-sv, rt-sv
     - a transactor with no bundle port of its protocol, or (not a monitor)
       no endpoint of one of the protocol's APIs or channel APIs; an
       abstractor with no endpoint or bundle port of one of its sides. On
       the class (its family name)
   * - ``FW-E-CONN-PHASE``
     - fe-sv, rt-sv
     - an endpoint, bundle or cfg sink bound outside ``connect()``
   * - ``FW-E-CONN-TYPE``
     - fe-sv, rt-sv
     - two bundles of different types connected (for example a mirror of
       ``sbus_bundle`` to a bundle of another protocol)
   * - ``FW-E-SOCK-UNBOUND``
     - fe-sv, rt-sv
     - a port, or a socket's port side, reaches no export: a transactor's
       ``s`` or an adapter's port left unconnected
   * - ``FW-E-SOCK-MULTI``
     - fe-sv, rt-sv
     - a port bound twice, or a second cfg source on one sink
   * - ``FW-E-CFG-WRITE``
     - fe-sv, rt-sv
     - code other than the runtime wrote a cfg sink's ``cfg``
   * - ``FW-E-CFG-UNBOUND``
     - fe-sv, rt-sv
     - a cfg sink no source reaches
   * - ``FW-*-DOM-CROSS``
     - fe-sv, rt-sv
     - an endpoint or bundle connection between two clock or reset domains
   * - ``FW-E-CLOCK-NONE``
     - rt-sv
     - a transactor ticks on a clock domain with no driver, pin or period:
       give the back-to-back top a ``root(period)`` clock
   * - ``FW-E-EXT-PIN``, ``-PORT``, ``-DIR``, ``-WIDTH``, ``-PARAM``
     - fe-sv
     - a wrapper's pin map does not match the module header: a pin unmapped
       or used twice, a port with no pin, directions or widths that
       disagree (:doc:`../wrapping`)
   * - ``FW-E-EMIT-RUN``
     - fe-sv
     - a component with ``run()`` (a transactor, an adapter) asked to be
       emitted; only the design is emitted
   * - ``FW-E-PIN-PATH``
     - rt-sv
     - an ``fw_pin_bridge`` path names no signal of the class top
   * - ``FW-E-TB-DOMAINS``
     - gen_tb
     - the design has more than one clock, or more than one reset
   * - ``FW-E-TB-XTOR``, ``FW-E-TB-MON``
     - gen_tb, gen_bind
     - no transactor (monitor) of the opposite role for the protocol of a
       DUT port's outermost protocol level among the scanned classes; the
       message names the protocol, the role and the port. Scan the
       generated package too, and name a specialization of a parameterized
       transactor. The inner channels' transactors are never used instead
   * - ``FW-E-TB-NOPROTO``
     - gen_tb, gen_bind
     - a DUT port's own bundle has no protocol but bundles inside it do. A
       port is one protocol: give its bundle one
       (`` `fw_bundle_protocol``), or make each protocol bundle its own
       port

Known limits
------------

What the current tools do not do, as of fw-hdl-fe-sv and fw-hdl-rt-sv of
2026-11. The ``#`` column is the item in the protocol-kit follow-up plan
(``docs/design/protocol-kit-followups.md`` of the fw-hdl workspace).

.. list-table::
   :header-rows: 1
   :widths: 6 44 50

   * - #
     - Limit
     - Effect and workaround
   * - F4
     - fe-sv connects configuration but does not run it (by design):
       ``set`` stores on the source only, sinks are not pushed and
       listeners are not called. The IR records each binding, each sink's
       resolved source and each ``add_listener``; the netlist has the
       bindings only
     - values and change actions are seen only in simulation (rt-sv);
       don't make structure depend on a sink's ``cfg`` or on a listener
       call
   * - F6
     - a lowered class with ``type T`` emits ``parameter type T`` unless
       width lowering is asked for. Yosys, SymbiYosys and Verilog-2005
       tools cannot read it. Width lowering turns only packed integer type
       parameters into widths (``T_W``); struct and enum type parameters
       are kept, with a warning
     - for formal, set ``width_params`` on the EmitSV task
       (``emit_sv(..., width_params=True)``) and override ``.T_W(n)`` in
       the harness, as ``test_proc_emit.py::test_rv_formal`` does
   * - F8
     - optional fields (``fw_opt``) are not supported: the attribute is
       ignored, and ``<n>_mask`` returns its argument
     - a protocol with parameter-selected optional signals (AXI
       ``AWLOCK``, ``QOS``, ``USER``) cannot drop them yet; declare them
       always present
   * - F8
     - 4-state payload fields: Zuspec IR models 4-state (``logic``
       types map without a warning), but the generated classes do not use
       it: a struct with a ``logic`` member gets no ``<p>_payloads``
       helpers and one pin for the whole payload (warning
       ``FW-W-GEN-4STATE``)
     - use ``bit`` members. A non-struct 4-state payload (``logic
       [W-1:0]``) is accepted, and a ``logic`` type in an API (std's
       ``fw_mem_if`` defaults) is kept as written
   * - F8
     - struct-valued parameters and class-local typedefs: a payload struct
       declared inside a class (to take the protocol's widths) is rejected
       (``FW-E-GEN-SCOPE``)
     - payload structs are package-level, so their widths are fixed. A
       width that follows a parameter is a non-struct payload
       (``logic [W-1:0]``)
   * - F8
     - the emitter puts functions before tasks in a class
     - none needed; matters only for diffs against hand-written code
   * - \-
     - a parameterized bundle or transactor is seen by Scan and GenKit only
       through a specialization the scanned source names
     - name one (``typedef my_bundle #(8) my_bundle_8_t;``), else the bundle
       gets no channel APIs or transactors (warning ``FW-W-GEN-UNSPEC``),
       and ``xtor_for`` finds none
   * - \-
     - ``gen_tb`` and ``gen_bind`` take a DUT port's transactor and monitor
       from the outermost level of its bundle tree that carries a protocol.
       A port whose own bundle has no protocol gets no transactor and no
       bridges; an array of bundle ports has not been tried
     - give the port's bundle a protocol with transactors, or write the
       bench for that port by hand
   * - \-
     - ``gen_tb`` binds an inbox only to a target transactor whose port
       calls ``fw_put_if``
     - bind other method ports in a subclass's ``connect()``
   * - \-
     - a transaction's ``sprint()`` prints arguments with ``%p``; Verilator
       prints a packed struct as one number
     - print payloads with ``<p>_payloads::<n>_sprint``
   * - \-
     - Verilator 5.055 has internal faults on some class-scoped types used
       as type parameters
     - follow the std and sbus patterns: package-level payload typedefs,
       ``this_t`` typedefs, no ``$cast`` to an interface class

Checklist
---------

A new protocol package, in the order this guide builds it:

#. The fit check: channels, roles, configuration, timing, known limits.
#. ``<p>_pkg.sv``: payload structs (``bit`` members), APIs, the protocol
   with ``declare()``, the bundle(s); a typedef naming one specialization
   of each parameterized bundle.
#. ``flow.yaml``: the ``fwHdlSource`` FileSet and ``fw.hdl.fe.sv.GenKit``.
#. Behaviour package: adapters, reference model, hand-written transactors
   for non-ready/valid pins, timed channels if needed.
#. Back-to-back test with the generated transactors and monitor, run in
   rt-sv and elaborated in fe-sv.
#. A wrapped RTL implementation, emitted, with the same test against it
   and monitors on its pins.
#. Formal checks of the pin-level invariants.
#. Teeth: one planted bug per suite, seen to fail.
