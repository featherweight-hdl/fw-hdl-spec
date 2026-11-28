Writing a protocol package
==========================

A protocol package is the SV package that carries one interface standard
(ready/valid, Wishbone, AXI4, AXI4-Lite, APB, a UART line) so that
components can talk it at the method level and RTL at the pin level. This
guide builds one from nothing. It is a how-to: the reference material (the
protocol hub, bundles, sockets, transactors, abstractors, configuration,
timing, generated testbenches) is in :doc:`protocols`, and the normative
rules are in ``semantics/protocols.md``. The guide links there rather than
repeating them.

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

The worked example: sbus
------------------------

One example runs through the whole guide: *sbus*, a small memory bus with
a request channel (address, write data, write enable) and a response
channel (read data, error), each with its own ready/valid handshake. Its
files are in ``docs/examples/sbus/`` of fw-hdl-spec, and every SV snippet
in the guide that names ``sbus`` is included from them, or copied from
the package GenKit generates from them:

.. list-table::
   :header-rows: 1
   :widths: 35 65

   * - File
     - What it is
   * - ``src/sbus_pkg.sv``
     - the hand-written source: payloads, API, protocol, bundle
       (:doc:`protocol-packages/declare`)
   * - ``flow.yaml``
     - ``GenKit`` and ``Scan`` as dfm tasks
       (:doc:`protocol-packages/generate`)
   * - ``src/sbus_behav_pkg.sv``
     - the behaviour: two adapters and a memory model
       (:doc:`protocol-packages/behaviour`)
   * - ``tb/sbus_b2b.sv``, ``tb/sbus_b2b_top.sv``
     - the class-level test: generated initiator and target back to back
       (:doc:`protocol-packages/testing`)
   * - ``rtl/sbus_mem_rtl.sv``, ``src/sbus_wrap_pkg.sv``,
       ``tb/sbus_rtl_tb.sv``
     - an existing RTL memory with sbus pins, its wrapper, and the same
       test against it, on the testbench gen_tb and gen_bind generate
   * - ``check.py``
     - builds and runs it all: GenKit, the back-to-back test in Verilator
       and in fe-sv's static elaboration, then the RTL test

Run it from the workspace root:

.. code-block:: shell

   direnv exec . python packages/fw-hdl-spec/docs/examples/sbus/check.py build/sbus

Other packages to read beside it:

- *apb*, in ``docs/examples/apb/``: an APB-style bus on plain signals,
  whose package is written entirely by hand, transactors included
  (task-sync crossings; :doc:`protocol-packages/behaviour`,
  "Hand-written transactors"). Its ``check.py`` simulates it back to back,
  with a mutant that must fail, and lowers the transactors to SV.
- the **std ready/valid protocol** in ``std/`` (``fw_rv_proto.svh``,
  ``fw_rv_if.svh``, ``fw_rv_xtor.svh``): one channel, a parameterized
  protocol, and the hand-written transactors that every generated one is
  built from. It is the reference package (:doc:`std`).
- fw-hdl-fe-sv ``tests/unit/gen/src/proto_chan/``: a parameterized bundle
  of channels (``test_ch_proto #(W)``) with its back-to-back test.
- the conformance library ``conformance/_lib/``: a UART protocol with
  plain-signal pins, configuration and timed channels
  (``test_uart_proto.svh``, ``test_uart_chan.svh``).
- fw-hdl-fe-sv ``examples/wrap_rtl/``: existing RTL with std ready/valid
  ports, a generated testbench and bound monitors.

The steps
---------

=====  ========================================  ======================================
Step   What                                      Page
=====  ========================================  ======================================
0      check the protocol fits                   below
1      declare the protocol                      :doc:`protocol-packages/declare`
2      payloads and bundles                      :doc:`protocol-packages/declare`
3      the APIs                                  :doc:`protocol-packages/declare`
4      generate                                  :doc:`protocol-packages/generate`
5      behaviour, transactors, configuration     :doc:`protocol-packages/behaviour`
6      tests                                     :doc:`protocol-packages/testing`
7      wrap a reference IP                       :doc:`protocol-packages/testing`
\-     diagnostics, known limits                 :doc:`protocol-packages/reference`
=====  ========================================  ======================================

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
     - UART line
   * - Channels
     - 5 (AW, W, B, AR, R), ready/valid
     - 5, ready/valid
     - 1 request/response phase pair (PSEL, PENABLE, PREADY)
     - none: a serial bit stream
   * - Bundle
     - a bundle of channels
     - a bundle of channels
     - plain signals
     - plain signals
   * - Transactors generated
     - yes
     - yes
     - no: written by hand
     - no: written by hand

GenKit generates transactors only for a bundle whose channels are all
``fw_rv_if``. If every channel is ready/valid, everything in this guide
applies as is. If not, the class side (declaring, generating the
method-level collateral, behaviour, class-level tests) still works, and the
pin-level transactor is written by hand
(:doc:`protocol-packages/behaviour`, "Hand-written transactors").

Channels that are logically coupled stay separate channels (AXI4: W
follows AW, B completes the write). The coupling is a higher-level method
(``write()``) that an adapter composes from the channels.

Then ask:

- **Is there a method level of its own?** If the abstract level exists
  without this protocol (packets over a byte PHY), there are two protocols
  and an abstractor between them (:doc:`protocols`, "Abstractors").
- **Does it carry configuration** (baud rate, parity)? Configuration is a
  struct on the endpoints, not on the protocol
  (:doc:`protocol-packages/behaviour`, "Configuration").
- **Does a transfer take time** that is not a clock handshake (a UART
  character time)? That is a timed channel the user places
  (:doc:`protocol-packages/behaviour`, "Timed channels").
- **Does it need what is not supported yet?** Optional fields selected by
  a parameter (AXI ``AWLOCK``, ``QOS``, ``USER``), 4-state payload
  fields, struct-valued parameters, and payload struct widths that follow a
  parameter are listed in :doc:`protocol-packages/reference`, "Known
  limits". Check them before you start.

.. toctree::
   :maxdepth: 2

   protocol-packages/declare
   protocol-packages/generate
   protocol-packages/behaviour
   protocol-packages/testing
   protocol-packages/reference
