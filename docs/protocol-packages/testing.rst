Testing a protocol package
==========================

Steps 6 and 7. A protocol package is tested at three levels: its classes
back to back with no RTL, the same tests against RTL, and its pin-level
invariants formally. Every suite needs teeth: run it once with a planted
bug and check that it fails. (Changing sbus_mem_rtl's write response to
``~s_reqwdata`` makes the sbus RTL test report ``E mismatch: rdata:
0x21524110 != 0xdeadbeef`` and ``FAIL``.)

.. list-table::
   :header-rows: 1
   :widths: 18 52 30

   * - Layer
     - Write
     - Example
   * - Back to back
     - generated initiator and target with their pins connected; traffic
       through the initiator's API against a model behind the target's;
       backpressure on both sides; every response variant; a listener on
       the monitor sees every beat
     - sbus ``tb/sbus_b2b.sv``; fw-hdl-fe-sv
       ``tests/unit/gen/src/proto_chan/xtor_b2b.sv``
   * - Static checks
     - the same composition through fe-sv's elaboration: unbound ports,
       phase and type errors, domain crossings, before any simulation
     - sbus ``check.py``
   * - Against RTL
     - the RTL wrapped, emitted, and driven by the same transactors and
       adapters; monitors on its pins
     - sbus ``tb/sbus_rtl_tb.sv``; fw-hdl-fe-sv ``examples/wrap_rtl``
   * - Formal
     - protocol invariants as synthesizable checkers: handshake stability,
       no phantom transfer, ordering and integrity; a ``cover`` per
       property
     - fw-hdl-fe-sv ``tests/e2e/sv/rv_formal.sv``

Run class and RTL tests over several parameter sets: the minimum, the
default, and a wide set with distinct widths per field so mix-ups show.

Back to back
------------

No RTL: the generated initiator drives the generated target's pins
directly, and the root clock's period drives the run. sbus's top:

.. literalinclude:: ../examples/sbus/tb/sbus_b2b.sv
   :language: systemverilog
   :dedent:
   :start-at: class top_c
   :end-at: endclass

- The top creates a **clock domain with a period**
  (``fw_clock_kind::root(10ns)``) and sets it as its default; every
  transactor below ticks on it. Without one, ``tick`` is
  ``FW-E-CLOCK-NONE``.
- Monitor listeners can be added in ``connect()``: the generated
  monitor's fan-outs exist from its ``build()``.

The module elaborates the top in rt-sv and runs it:

.. literalinclude:: ../examples/sbus/tb/sbus_b2b_top.sv
   :language: systemverilog
   :dedent:
   :start-at: module sbus_b2b

``__fw_rt::elaborate`` returns the number of errors and leaves the
diagnostics in ``__fw_rt::diags``; ``__fw_rt_kern::run()`` runs the
``run()`` tasks for ``+fw_edges=N`` edges of the root clock. Build it with
the Verilator command of :doc:`generate`, "Compiling", ``--top-module
sbus_b2b``, and run the binary with ``+fw_edges=40``. What the monitor sees (one
access every two cycles: the request handshakes at one edge, its response
at the next):

.. code-block:: text

   M req addr=0x10 wdata=0xdeadbeef we=0x1 @1
   M rsp rdata=0xdeadbeef err=0x0 @2
   M req addr=0x10 wdata=0x0 we=0x0 @3
   M rsp rdata=0xdeadbeef err=0x0 @4
   M req addr=0xf4 wdata=0x0 we=0x0 @5
   M rsp rdata=0x0 err=0x1 @6
   M req addr=0x10 wdata=0x0 we=0x0 @7
   M rsp rdata=0xdeadbeef err=0x0 @8
   PASS

**Static checks.** The same top goes through fe-sv's elaboration, which
reports what rt-sv would only find at run time (and some it would not):

.. literalinclude:: ../examples/sbus/check.py
   :language: python
   :dedent:
   :start-at: r = elaborate(b2b
   :end-at: sys.exit(f"FAIL: elaborate b2b

Elaborate only the package code, not the module: rt-sv's ``__fw_rt`` is
not part of the API.

Against RTL
-----------

**Wrap the RTL.** An extern component names the module and maps each
port's bundle onto its pins (:doc:`../wrapping`). The generated
``<p>_pins::flat`` makes the protocol port one line:

.. literalinclude:: ../examples/sbus/src/sbus_wrap_pkg.sv
   :language: systemverilog
   :dedent:
   :start-at: class sbus_mem_w
   :end-at: endclass

``flat(m, s, "s_")`` maps ``s.req.valid`` to ``s_reqvalid``,
``s.req.data.addr`` to ``s_reqaddr`` and so on. It returns the pin rule,
so further ``rename`` calls can follow it for a device with other names.
Clock and reset are domain pins, here an active-low reset
(:doc:`../domains`, "Map a wrapper's pins"). fe-sv checks the map against
the module header (``FW-E-EXT-*``).

**Assemble and emit.** A design component holds the wrapper, passes its
port up and drives the clock and reset domains from two inputs
(``sbus_sys`` in the same file). fe-sv elaborates it and emits Verilog
with the wrapper replaced by its module, in a flow
(``fw.hdl.fe.sv.Elaborate`` then ``fw.hdl.fe.sv.EmitSV``, as
fw-hdl-fe-sv ``examples/wrap_rtl/flow.yaml``) or from Python:

.. literalinclude:: ../examples/sbus/check.py
   :language: python
   :dedent:
   :start-at: r = elaborate([kit
   :end-at: res = emit_sv(

The emitted module keeps the protocol port as one struct port per channel
payload:

.. code-block:: systemverilog

   // excerpt of the emitted sbus_sys.sv
   module sbus_sys(
     input logic clk_i,
     input logic rst_i,
     input logic s_req_valid,
     output logic s_req_ready,
     input sbus_sys_types_pkg::sbus_req_t s_req_data,
     output logic s_rsp_valid,
     input logic s_rsp_ready,
     output sbus_sys_types_pkg::sbus_rsp_t s_rsp_data
   );
     ...
     sbus_mem_rtl mem (
       .clk(clk),
       .rst_n(rst_inv),
       .s_reqvalid(s_req_valid),
       ...
       .s_reqaddr(s_req_data.addr),

**Drive it.** fw-hdl-fe-sv generates the testbench from the elaborated
design and a scan of the kit's packages: a class holding, per DUT port, a
bundle of the opposite mixin and the opposite-role transactor; a module
joining the class's pins to the DUT's with one ``fw_pin_bridge`` per pin;
and, with monitors, a bind module that feeds each monitor from the DUT's
own nets. sbus's ``check.py``:

.. literalinclude:: ../examples/sbus/check.py
   :language: python
   :dedent:
   :start-at: xs = scan([kit
   :end-at: bd.write_text(

``r`` is the elaborated design and ``xs`` a scan of the packages that hold
the transactors: here the kit and its generated package. The class
``<top>_tb_c`` (``sbus_sys_tb_c``) holds, per DUT port ``<port>``, the
bundle ``<port>``, the transactor ``dut_<port>`` and, for a target
transactor whose port calls ``fw_put_if``, an inbox ``dut_<port>_rx``;
with ``bind=True`` a monitor ``mon_<port>``. ``build`` and ``connect`` are
split per concern (``build_xtors``, ``connect_monitors``, ...) so a
subclass replaces one part.

A port is walked as a tree of bundles. Its transactor and monitor are the
ones of the **outermost** level that carries a protocol: for sbus's port
``s``, a ``fw_mirror #(sbus_bundle)``, that is ``sbus_initiator`` and
``sbus_monitor``, not a ready/valid transactor per channel. If the scan has
no transactor (or monitor) of that protocol and role, ``gen_tb`` and
``gen_bind`` stop with ``FW-E-TB-XTOR`` (``FW-E-TB-MON``), naming the
protocol, the role and the port. Each pin is named by its member path
joined with ``_`` (``s_rsp_valid``) and bridged in its direction for the
DUT, reversed at each ``fw_mirror`` on the path: ``s.req.valid`` is driven
by the class, ``s.rsp.valid`` (``rsp`` is mirrored) by the DUT.

The test extends the generated class and hands it to the generated module.
For sbus it reuses the back-to-back test's adapter and counts beats on the
monitor:

.. literalinclude:: ../examples/sbus/tb/sbus_rtl_tb.sv
   :language: systemverilog
   :dedent:
   :start-at: class tb_c extends
   :end-at: endfunction

.. literalinclude:: ../examples/sbus/tb/sbus_rtl_tb.sv
   :language: systemverilog
   :start-at: module sbus_rtl_tb;
   :end-at: endmodule

The generated module's bridges, from ``sbus_sys_tb.sv``:

.. code-block:: systemverilog

   fw_pin_bridge #(bit, "top.clk") b_clk(.i(clk), .o());
   fw_pin_bridge #(bit, "top.rst_i") b_rst(.i(rst), .o());
   fw_pin_bridge #(bit, "top.s.req.valid") b_s_req_valid(.i('0), .o(s_req_valid));
   fw_pin_bridge #(bit, "top.s.req.ready") b_s_req_ready(.i(s_req_ready), .o());
   fw_pin_bridge #(sbus_pkg::sbus_req_t, "top.s.req.data") b_s_req_data(.i('0), .o(s_req_data));
   fw_pin_bridge #(bit, "top.s.rsp.valid") b_s_rsp_valid(.i(s_rsp_valid), .o());
   fw_pin_bridge #(bit, "top.s.rsp.ready") b_s_rsp_ready(.i('0), .o(s_rsp_ready));
   fw_pin_bridge #(sbus_pkg::sbus_rsp_t, "top.s.rsp.data") b_s_rsp_data(.i(s_rsp_data), .o());

Each bridge carries one signal between a module net and the class signal
at a path: ``.i(net)`` for a pin the DUT drives, ``.o(net)`` for one the
class drives. The ``top.clk`` bridge drives the class's clock domain from
the module clock and starts the ``run()`` tasks; the module counts
``+fw_edges=N`` edges (default 100) and releases reset after three. The
class package imports the kit's packages; the module names payload types
with their package.

fw-hdl-fe-sv ``examples/wrap_rtl`` (README) and ``tests/e2e/test_gen_tb.py``,
``test_gen_bind.py``, ``test_gen_tb_sbus.py`` and
``test_wrap_rtl_acceptance.py`` are the worked cases; :doc:`../protocols`,
"Testbenches and bind modules", has the rules.

Bind monitors
~~~~~~~~~~~~~

``gen_bind`` writes module ``<top>_fw_mon``, whose ports are all inputs
named as the DUT's pins, with a bridge from each to the pins of the
testbench's monitor, and the line ``bind <top> <top>_fw_mon u_fw_mon
(...)``. The bound module only samples, so the DUT's nets get no new
driver, and the monitors see the DUT wherever it is instantiated. A test
attaches listeners in ``connect()``, after ``super.connect()``, as sbus's
``tb_c`` above does (``mon_s.add_req_listener(cnt)``). Compile the bind
file with the bench; nothing instantiates it.

Formal
------

Write the protocol's invariants as a synthesizable harness on the RTL, or
on the lowered pin core of a monitor, and prove them with SymbiYosys:

- free inputs with ``(* anyseq *)``, a free index with
  ``(* anyconst *)``, and assumptions only for what the protocol requires
  of the other side (a stalled beat keeps ``valid`` and its data);
- immediate asserts in ``always @(*)``, with ``$past`` guarded by a
  past-valid register: handshake is ``valid && ready``, one ``pre`` before
  each ``post``, one ``pre`` per transfer, and the beat at the free index
  keeps the data it was offered with;
- a ``cover`` per property, so the proof is not vacuous, and one planted
  bug to show it has teeth.

fw-hdl-fe-sv ``tests/e2e/sv/rv_formal.sv`` proves std's
``fw_rv_mon_core`` this way, after fe-sv lowers it to Verilog
(``test_proc_emit.py::test_rv_formal``, BMC depth 20 and cover with
``smtbmc z3``):

.. code-block:: systemverilog

   always @(*) begin
     if (!f_past) assume(!valid);                         // held has no reset
     assert(fire == (valid && ready));                    // one post per handshake
     if (fire) assert(first || open);                     // pre before post
     if (first) assert(!open);                            // one pre per transfer
     if (fire && !first && n == idx) assert(data == d0);  // data integrity
     cover(fire && !first && n == 2);                     // a stalled beat accepted
   end

The lowered core has a type parameter (``parameter type T``), which Yosys
cannot read; the test rewrites it to a width parameter by hand
(:doc:`reference`, "Known limits").

7. Wrapping a reference IP
--------------------------

Prove the package on real RTL: wrap one or more existing IPs that speak
the protocol, run the RTL tests against them, and compare with the
reference model. Pick IPs that stress something: two pin naming styles,
both reset polarities, a packed-vector port, an IP that reorders
responses. A wrapper names the module, its parameters, clock and reset,
and maps each port's bundle onto its pins (:doc:`../wrapping`); ``tie``
and ``open`` handle pins outside the bundle.

Next: :doc:`reference`.
