Generating the derived package
==============================

Step 4. fw-hdl-fe-sv's ``GenKit`` scans the hand-written package and
writes one SV package, ``<pkg>_gen_pkg``, holding every derived class.
For sbus, ``sbus_pkg`` gives ``sbus_pkg_gen_pkg``. Do not hand-write any
of the classes it derives; if it cannot derive something you need, that is
a generator gap to report, not code to put in the package.

Running GenKit
--------------

**In a flow.** After the package's ``fwHdlSource`` FileSet
(``docs/examples/sbus/flow.yaml``):

.. literalinclude:: ../examples/sbus/flow.yaml
   :language: yaml
   :dedent:
   :start-at: - name: kit

``dfm run kit-gen`` writes ``rundir/sbus.kit-gen/sbus_pkg_gen_pkg.sv``
(``sbus`` is the flow's package name).
The task:

- takes ``fwHdlSource`` FileSets (and passes them on, with any RTL), and
  outputs the generated package as a ``systemVerilogSource`` FileSet, so a
  simulator task downstream gets the source and the generated package in
  order;
- has two parameters: ``pkg_name`` (default ``<core pkg>_gen_pkg``) and
  ``spec`` (the fw-hdl-spec checkout, default ``$FW_HDL_SPEC``, else
  ``$IVPM_PACKAGES/fw-hdl-spec``), which supplies ``fw_hdl_pkg``, the
  macros and std;
- re-runs when its inputs or parameters change, and also when the
  generators change (a hash of their source, ``GEN_VERSION``).

``fw.hdl.fe.sv.Scan`` (``dfm run kit-scan``) writes only the protocol
table: ``scan.json`` (each protocol's family, parameters, prefix, APIs
with direction, bundles and converters, as the netlist's ``protocols``
table) and ``scan.zir`` (Zuspec IR of the APIs). ``Elaborate``
downstream of a ``Scan`` checks that elaboration agrees with it
(``FW-E-SCAN-STALE``).

**From Python** (``docs/examples/sbus/check.py``):

.. literalinclude:: ../examples/sbus/check.py
   :language: python
   :dedent:
   :start-at: s = scan([kit], incdirs=inc)
   :end-at: gen.write_text(gen_kit(s))

``scan(files, incdirs=..., defines=...)`` is in ``fw.hdl.fe.sv.scan``;
``r.ok`` is false on a compile or registration error, with the reasons in
``r.diags``. ``gen_kit(r, pkg_name=None, diags=None)`` is in ``fw.hdl.gen``;
it raises ``GenError`` (``FW-E-GEN-PKG``, ``FW-E-GEN-API``,
``FW-E-GEN-SCOPE``) for a package it cannot handle. Its warnings (what the
generated package leaves out: ``FW-W-SCAN-IR``, ``FW-W-GEN-UNSPEC``,
``FW-W-GEN-4STATE``) go to the list ``diags``, or are issued as Python
warnings; the dfm task reports them as markers. fw-hdl-fe-sv ``tests/e2e/test_genkit_flow.py`` checks that the dfm
task and the Python call give the same text.

Compiling
---------

The generated package imports ``fw_hdl_pkg``, your package and, when it
holds transactors, ``fw_hdl_std_pkg``, and it needs
``fw_hdl_macros.svh`` on the include path. Compile, in order:

1. the tool's ``fw_hdl_pkg`` (for simulation, fw-hdl-rt-sv
   ``sv/fw_hdl_pkg.sv``), and fw-hdl-rt-sv ``sv/fw_pin_bridge.sv`` if a
   module bridges pins to classes;
2. ``fw_hdl_std_pkg`` (``std/fw_hdl_std_pkg.sv``), and std's generated
   package if you use std's derived classes;
3. your package, then its generated package;
4. behaviour, then tests.

With include directories for rt-sv's ``sv/``, fw-hdl-spec's
``bindings/sv`` and ``std/``. The sbus build in Verilator:

.. literalinclude:: ../examples/sbus/check.py
   :language: python
   :dedent:
   :start-at: VLT = [
   :end-at: BASE = [

What is generated
-----------------

For API ``<api>`` with method ``<m>``, payload struct ``<n>_t`` and
protocol prefix ``<p>``. The names in the last column are sbus's.

.. list-table::
   :header-rows: 1
   :widths: 28 47 25

   * - Class
     - What it is for
     - sbus
   * - ``<p>_req_if``, ``<p>_rsp_if``
     - the channel APIs of a bundle of channels: one task per channel,
       named as the channel, taking its payload
     - ``sbus_req_if::req(t)``, ``sbus_rsp_if::rsp(t)``
   * - ``<api>_base``
     - a virtual class implementing ``<api>``: each method reports
       ``$error`` and zeroes its outputs until overridden. Extend it and
       override only what you need
     - ``sbus_if_base``, ``sbus_req_if_base``
   * - ``<api>_listener``
     - interface class with ``<m>_pre(inputs)`` (called before the call)
       and ``<m>_post(all args[, __ret])`` (after it). Functions: a
       listener cannot block or change the call
     - ``sbus_if_listener``
   * - ``<api>_listener_base``
     - implements the listener with empty bodies: extend it and override
       one callback
     - ``sbus_if_listener_base``
   * - ``<api>_listener_fanout``
     - a listener that forwards to many (``add_listener``,
       ``remove_listener``)
     - ``sbus_if_listener_fanout``
   * - ``<api>_proxy``
     - implements ``<api>`` by forwarding to a target (``new(target)``),
       calling each listener's ``<m>_pre`` before and ``<m>_post`` after
     - ``sbus_if_proxy``
   * - ``<api>_imp #(..., type IMP)``
     - implements ``<api>`` by forwarding to an ``IMP`` object's methods
       (``new(imp)``): for a component that must provide the API twice, or
       through a member
     - ``sbus_if_imp``
   * - ``<api>_txn``, ``<api>_<m>_txn``
     - one transaction class per method: a ``rand`` field per argument (and
       ``__ret``), ``sprint()`` and ``compare(o, diff)``
     - ``sbus_if_access_txn``, ``sbus_req_if_req_txn``
   * - ``<api>_txn_sink``
     - interface class with ``put(<api>_txn t)``: where recorded
       transactions go
     - ``sbus_if_txn_sink``
   * - ``<api>_txn_listener``
     - a listener that builds an ``<api>_<m>_txn`` at each ``<m>_post``
       and puts it to a sink (``new(sink)``)
     - ``sbus_if_txn_listener``
   * - ``<api>_txn_driver``
     - replays a transaction as a call on an ``<api>`` (``new(api)``,
       ``drive(t)``), storing outputs back in the transaction
     - ``sbus_if_txn_driver``
   * - ``<p>_payloads``
     - static ``<n>_sprint(v)``, ``<n>_compare(a, b, diff)`` and
       ``<n>_mask(v)`` per struct channel payload
     - ``sbus_payloads::sbus_req_sprint``
   * - ``<p>_pins``
     - static ``flat(m, b, pre)``: the pin-map preset for an extern
       (:doc:`testing`)
     - ``sbus_pins::flat``
   * - ``<p>_initiator``, ``<p>_target``
     - for a bundle whose channels are all ``fw_rv_if``: the transactors,
       registered with the protocol
     - ``sbus_initiator``, ``sbus_target``
   * - ``<p>_monitor``
     - the monitor of such a bundle, registered with the protocol
     - ``sbus_monitor``

The collateral rows (``_base`` to ``_txn_driver``) are made for every API:
the ones the package declares and the two channel APIs. A parameterized
API or bundle gives parameterized classes with the same parameters
(``test_ch_initiator #(W)``). The transactors also bring small helper
classes (``<p>_<ch>_sink``, ``<p>_<ch>_mon_listener``); they are internal.

The transactors
---------------

The initiator implements ``<p>_req_if`` and calls ``<p>_rsp_if`` for each
response beat; the target is its mirror image. Each extends the socket
base class of its role, :sv:class:`fw_xtor_sock_initiator` or
:sv:class:`fw_xtor_sock_target`, which holds ``pins`` for the pin side and
the socket ``s`` for the method side; it adds one std transactor per
channel (``<ch>_x``):

.. code-block:: systemverilog

   // excerpt of sbus_pkg_gen_pkg
   class sbus_initiator extends fw_xtor_sock_initiator #(sbus_bundle, sbus_req_if, sbus_rsp_if)
           implements sbus_req_if;
       fw_rv_initiator #(sbus_pkg::sbus_req_t) req_x;
       fw_rv_target #(sbus_pkg::sbus_rsp_t) rsp_x;
       ...
       `fw_xtor_utils(sbus_initiator)

   class sbus_target extends fw_xtor_sock_target #(sbus_bundle, sbus_req_if, sbus_rsp_if)
           implements sbus_rsp_if;
       fw_rv_initiator #(sbus_pkg::sbus_rsp_t) rsp_x;
       fw_rv_target #(sbus_pkg::sbus_req_t) req_x;
       ...
       `fw_xtor_utils(sbus_target)

   class sbus_monitor extends fw_xtor_monitor #(sbus_bundle);
       fw_rv_monitor #(sbus_pkg::sbus_req_t) req;
       fw_rv_monitor #(sbus_pkg::sbus_rsp_t) rsp;
       virtual function void add_req_listener(input sbus_req_if_listener l);
       virtual function void add_rsp_listener(input sbus_rsp_if_listener l);
       ...

To use them:

- connect a component's socket of the opposite type to ``s``
  (``fw_socket #(sbus_req_if, sbus_rsp_if)`` to the initiator's), and the
  pins to the other side's: another transactor's ``pins`` back to back, or
  a bundle passed up to the DUT's port;
- a call of ``req(t)`` on the initiator drives the channel in the cycle it
  is made and returns at the handshake edge; a response beat taken at the
  pins becomes a call of ``rsp(t)`` out through ``s``. Nothing is buffered
  and no cycle is added;
- the monitor's ``pins`` taps a link (``mon.pins.connect(xi.pins)``).
  ``add_req_listener``/``add_rsp_listener`` take the channel APIs'
  listeners; ``<ch>_pre`` is called at the first cycle a beat is offered
  and ``<ch>_post`` at its handshake. Each channel's ``fw_rv_monitor`` is
  also a member named as the channel, for an ``fw_rv_mon_listener``.

The std transactors they are built from (``fw_rv_initiator``,
``fw_rv_target``, ``fw_rv_monitor``) are in ``std/fw_rv_xtor.svh`` and
:doc:`../std`; :doc:`../protocols`, "Transactors", has the lookup rules.

Using the collateral
--------------------

The sbus back-to-back test (``docs/examples/sbus/tb/sbus_b2b.sv``) uses
most of it. A listener on the monitor, with the payload helpers:

.. literalinclude:: ../examples/sbus/tb/sbus_b2b.sv
   :language: systemverilog
   :dedent:
   :start-at: // Logs each beat
   :end-at: endclass

A proxy with a transaction recorder, and the payload ``compare``:

.. literalinclude:: ../examples/sbus/tb/sbus_b2b.sv
   :language: systemverilog
   :dedent:
   :start-at: // Keeps every recorded
   :end-at: endclass

.. literalinclude:: ../examples/sbus/tb/sbus_b2b.sv
   :language: systemverilog
   :dedent:
   :start-at: task check(
   :end-at: endtask

.. literalinclude:: ../examples/sbus/tb/sbus_b2b.sv
   :language: systemverilog
   :dedent:
   :start-at: virtual task run();
   :end-at: check(rsp, '{rdata: 0, err: 1});

Replaying a transaction through a driver:

.. literalinclude:: ../examples/sbus/tb/sbus_b2b.sv
   :language: systemverilog
   :dedent:
   :start-at: // A transaction, made by hand
   :end-at: endtask

Notes:

- A proxy is a plain class, not a component: make it in ``run()`` (or
  ``connect()``) over the implementation a port reaches
  (``p.get_if()``).
- ``<p>_payloads::<n>_mask(v)`` returns ``v`` today; it is the hook for
  optional fields (:doc:`reference`, "Known limits"). Call it where a link
  without pins must deliver what a link with pins would.
- A transaction's ``sprint()`` prints each argument with ``%p``; Verilator
  prints a packed struct that way as one number. Use ``<p>_payloads``
  ``<n>_sprint`` for a readable payload.
- ``compare`` (and the ``<p>_payloads`` field compare) uses ``!==``, so
  an X or Z bit in a 4-state value counts as a difference.

Next: :doc:`behaviour`.
