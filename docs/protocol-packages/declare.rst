Declaring a protocol
====================

Steps 1 to 3: the hand-written source of a protocol package. It is one SV
package holding the payload types, the APIs, the protocol class and its
bundles. For sbus it is all of ``docs/examples/sbus/src/sbus_pkg.sv``.

The package
-----------

.. literalinclude:: ../examples/sbus/src/sbus_pkg.sv
   :language: systemverilog
   :dedent:
   :start-at: `include
   :end-at: import fw_hdl_std_pkg

- Put the protocol, its bundles, every API and every payload type in
  this one package. GenKit derives the package it writes from it; parts
  spread over several packages, or declared outside a package, are
  ``FW-E-GEN-PKG``.
- Include ``fw_hdl_macros.svh`` before the package and import
  ``fw_hdl_pkg``. Import ``fw_hdl_std_pkg`` for ``fw_rv_if``, the neutral
  APIs and the std transactors.
- Keep behaviour (adapters, models) and tests in other packages that import
  this one and the generated one. The generated package imports this one,
  so this one cannot use anything generated.

Payload types
-------------

One packed struct per channel payload:

.. literalinclude:: ../examples/sbus/src/sbus_pkg.sv
   :language: systemverilog
   :dedent:
   :start-at: // One request beat
   :end-at: } sbus_rsp_t;

- **Member names** are the protocol's names without the channel prefix
  (``addr``, not ``reqaddr``). The pin map adds the channel name, so the
  pins come out as ``reqaddr``, ``reqwdata``, ``rsprdata`` and so on.
- **Packing order** is the order on the wire: the transactors put the
  struct on the data pins as one value, and a formal harness or an RTL
  struct port sees the same layout. Pick it once.
- **Name it** ``<n>_t``: the payload helpers are named after it less the
  ``_t`` (``sbus_payloads::sbus_req_sprint``).
- **Use 2-state members** (``bit``). A struct with a ``logic`` member is
  taken as a plain vector: it gets no payload helpers and one pin for the
  whole payload, and GenKit warns ``FW-W-GEN-4STATE`` (:doc:`reference`,
  "Known limits").
- **Two channels that differ in one width need two structs.**
- A payload need not be a struct. ``logic [W-1:0]`` is one pin,
  ``<ch>data``, and is how a payload width follows a protocol parameter
  (``test_ch_bundle`` in fw-hdl-fe-sv ``tests/unit/gen/src/proto_chan``).
  A struct's widths cannot follow a parameter yet: the struct must be a
  package-level typedef; one declared inside a class is
  ``FW-E-GEN-SCOPE`` (:doc:`reference`, "Known limits").

The APIs
--------

An API is an ordinary interface class. sbus has one transaction-level
API, a blocking access:

.. literalinclude:: ../examples/sbus/src/sbus_pkg.sv
   :language: systemverilog
   :dedent:
   :start-at: // The transaction-level API
   :end-at: endclass

The channel APIs (one task per channel, ``sbus_req_if`` and
``sbus_rsp_if``) are derived from the bundle; write only the
transaction-level ones. A method signature follows these rules, so that the
derived classes and foreign bindings can be generated from it:

- a **task** if it may block, else a **function** (a function may return
  a value; its listeners and transactions get it as ``__ret``);
- arguments are ``input`` or ``output`` only: no ``ref``, no ``inout``, no
  events, no class handles;
- argument types are packed types (structs, vectors, enums) and queues of
  them;
- use the **payload types** in the protocol's own API, so a new payload
  field reaches it with no other edit;
- the std APIs put **outputs first** (``rsp = access(req)``); follow them.

**Split by direction or block.** Where the protocol allows several
transfers in flight (AXI4, AXI4-Lite), write a request interface the
initiator calls and a response interface the target calls back: a request
returns once it is accepted, and responses arrive as calls. A blocking form
is a shim on top. Where there is one transfer in flight (APB, sbus), one
blocking method with its response (``access(rsp, req)``) is enough.

**Neutral APIs.** std has four protocol-neutral APIs (:doc:`../std`):
``fw_put_if``, ``fw_get_if``, ``fw_reqrsp_if`` and ``fw_mem_if``. A
protocol may register one of them instead of its own, as ``fw_rv_proto``
registers ``fw_put_if``; a model written against a neutral API then works
over any protocol that declares it. Their derived classes
(``fw_put_if_proxy`` and the rest) are in std's generated package,
``fw_hdl_std_pkg_gen_pkg``, not in yours: generate it from fw-hdl-spec's
``std-src`` task and compile it before your package.

An API cannot register itself: the protocol registers it, and one API may
belong to many protocols. Every interface class declared in the package
gets the derived classes, whether or not a protocol registers it.

The protocol
------------

A class extending ``fw_protocol``, with only static members:

.. literalinclude:: ../examples/sbus/src/sbus_pkg.sv
   :language: systemverilog
   :dedent:
   :start-at: class sbus_proto
   :end-before: // The pins

- ```fw_protocol_utils(C)`` declares ``get_type()``. It takes the bare
  class name: no names are ever written as strings.
- ``declare()`` registers the APIs with ``d.api(h, dir)``, at most one per
  direction, ``FW_PROTO_REQ`` (the initiator calls it) and
  ``FW_PROTO_RSP`` (the target calls it back). Two for one direction, or
  one twice, is ``FW-E-PROTO-API``.
- The **prefix** of every derived name is the class name less a trailing
  ``_proto`` (``sbus_proto`` gives ``sbus``). A protocol whose name does
  not fit sets one with ``d.prefix("...")`` in ``declare()``.
- Static helper functions of the protocol go here too: the UART protocol
  of the conformance library has ``xfer_time(cfg, t)`` and
  ``mismatch(tx, rx, t)``, which its timed channels call.

Parameterized protocols
~~~~~~~~~~~~~~~~~~~~~~~

Width parameters live on the protocol and its bundles. A parameterized
protocol declares its own specialization as ``this_t`` and uses
```fw_protocol_param_utils``, as std's ready/valid protocol does:

.. literalinclude:: ../../std/fw_rv_proto.svh
   :language: systemverilog
   :dedent:
   :start-at: class fw_rv_proto

``this_t`` must be the class's own specialization, its parameters in
order. A missing one does not compile; a wrong one compiles in SV and is
``FW-E-PROTO-THIS`` in fe-sv. A protocol has two identities:
``P::get_type()`` is the specialization (``fw_rv_proto #(byte)``), which
connection checks and transactor choice key on, and the class without
parameters is the family, which generators and naming key on.

Every registration macro comes in the same two forms, ``_utils`` for a
plain class and ``_param_utils`` (with ``this_t``) for a parameterized
one:

=============================  ======================================  ===============================
Class                          Plain                                   Parameterized
=============================  ======================================  ===============================
protocol                       ```fw_protocol_utils(C)``               ```fw_protocol_param_utils(C)``
transactor                     ```fw_xtor_utils(C)``                   ```fw_xtor_param_utils(C)``
abstractor                     ```fw_abstractor_utils(C, F, T)``       ```fw_abstractor_param_utils(C, F, T)``
component                      ```fw_component_utils(C)``              ```fw_component_param_utils(C)``
bundle (names its protocol)    ```fw_bundle_protocol(P)``              the same, ``P`` specialized
=============================  ======================================  ===============================

The bundles
-----------

A bundle is the protocol's pin-level form. It extends ``fw_bundle_base``,
names its protocol with ```fw_bundle_protocol``, and is written from the
initiator's view. For a handshaked protocol make it a **bundle of
channels**: one ``fw_rv_if`` member per channel, ``fw_bundle`` for a
channel the initiator drives and ``fw_mirror`` for one it receives:

.. literalinclude:: ../examples/sbus/src/sbus_pkg.sv
   :language: systemverilog
   :dedent:
   :start-at: virtual class sbus_bundle
   :end-at: endclass

The member type is all that is written: the mixin gives the direction, the
``fw_rv_if`` type parameter the payload, the member name the channel name.
From them GenKit derives:

- a channel API per direction: ``<p>_req_if`` with one task per
  ``fw_bundle`` channel and ``<p>_rsp_if`` with one per ``fw_mirror``
  channel, each task named as its channel (``req(t)``, ``rsp(t)``);
- the pin map: ``<pre><ch>valid``, ``<pre><ch>ready`` and one pin
  ``<pre><ch><field>`` per payload field;
- the transactors and monitor, one std ready/valid transactor per channel.

So name channels as the protocol does (AXI4: ``aw``, ``w``, ``b``,
``ar``, ``r``), and not ``pins``, ``s``, ``p`` or ``t``, which the
generated transactors use for their own members.

A **parameterized bundle** names its protocol's specialization and passes
its parameters on:

.. code-block:: systemverilog

   virtual class test_ch_bundle #(int W = 8) extends fw_bundle_base;
       `fw_bundle_protocol(test_ch_proto #(W))
       fw_bundle #(fw_rv_if #(logic [W-1:0])) req;
       fw_mirror #(fw_rv_if #(test_ch_rsp_t)) rsp;
       ...
   endclass

GenKit sees a parameterized class only through a specialization that the
scanned source names. Name one in the package (``typedef test_ch_bundle
#(8) test_ch_bundle_8_t;``, or a member of that type), or the bundle has
no channel APIs and no transactors (:doc:`reference`, "Known limits").

Rules for bundles:

- **Roles.** The same bundle type is the initiator side as an
  ``fw_bundle``, the target side as an ``fw_mirror`` and a tap as an
  ``fw_monitor``; the mixin is the role, and the bundle type names the
  protocol.
- **No clock or reset.** They come from the domain of the component that
  holds the transactor (:doc:`../domains`). A device's pin names and
  polarity go in its pin map (:doc:`../wrapping`).
- **No cross-channel facts.** AXI4's ``len``\ +1 W beats per AW is a
  check (a listener or a formal property), not a bundle member.
- **Several forms.** A protocol may have several bundles (pin-level
  variants); it names none of them. A third party can add one.
- **A bundle of plain signals** (the UART serial line, APB) is written
  like any bundle, with ``fw_output``/``fw_input`` members. It has no
  channels, so GenKit derives no channel APIs and no transactors for it,
  and the transactor is written by hand (:doc:`behaviour`).
- **One protocol variant per bundle.** For AXI4-Lite write its own
  bundle; don't model it as AXI4 with absent fields (``len``, ``size``,
  ``burst`` and ``last`` are not optional in AXI4).

That is the whole source. The next step generates the rest:
:doc:`generate`.
