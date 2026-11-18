Protocols, transactors and configuration
========================================

A bundle carries an interface's pins; a *protocol* joins everything else
about the interface standard: the method-level APIs that model it, the
bundles that are its pin-level forms, the transactors that convert between
the two, and the configuration both ends share. The protocol class is a
hub. Every part registers with it, the protocol names none of them, and a
tool finds every part from the protocol. A third party can add a bundle
variant, a transactor or an abstractor without editing the protocol.

This guide builds a small UART kit, the one the conformance scenarios use
(``conformance/_lib/test_uart_proto.svh``), from the hub out to the
configuration. The API reference is :doc:`api/protocols`; the rules are in
``semantics/protocols.md``. Nothing in this layer is synthesized: a
method-level connection reaches pins only through a transactor.

The hub
-------

A protocol class extends :sv:class:`fw_protocol`, has only static members,
and declares ``get_type()`` with :sv:macro:`fw_protocol_utils`. Its
``declare()`` registers the APIs, at most one per direction:

.. code-block:: systemverilog

   class test_uart_proto extends fw_protocol;
       `fw_protocol_utils(test_uart_proto)

       static function void declare(fw_protocol_decl d);
           d.api(fw_api_type_of #(test_put_if #(uart_char_t))::get(), FW_PROTO_REQ);
       endfunction
       ...
   endclass

An API is an ordinary interface class, here a one-method ``put``. It
cannot register itself, so the protocol registers it, and one API may
belong to many protocols.

The macro takes the bare class name and nothing else: no user-written
strings. Derived names start with the family name less a trailing
``_proto`` (``axi4_proto`` gives ``axi4``); a protocol whose name does not
fit sets one with ``d.prefix("...")``.

A parameterized protocol declares its own specialization as ``this_t`` and
uses :sv:macro:`fw_protocol_param_utils`:

.. code-block:: systemverilog

   class rv_proto #(int W = 8) extends fw_protocol;
       typedef rv_proto #(W) this_t;
       `fw_protocol_param_utils(rv_proto)
   endclass

``P::get_type()`` is the specialization (``rv_proto #(16)``), and
``P::get_type().family()`` the class without parameters. Connection checks
and transactor choice key on the specialization; generators, rules and
naming key on the family. A ``this_t`` that is not the class's own
specialization is ``FW-E-PROTO-THIS``.

The bundle
----------

A bundle names its protocol with :sv:macro:`fw_bundle_protocol`. It is
written from the initiator's (here the transmitter's) view, as any bundle:

.. code-block:: systemverilog

   virtual class test_uart_serial extends fw_bundle_base;
       `fw_bundle_protocol(test_uart_proto)

       fw_output #(bit) tx;
       fw_input  #(bit) rx;

       virtual function void build();
           tx = fw_output #(bit)::create("tx", this);
           rx = fw_input  #(bit)::create("rx", this);
       endfunction
   endclass

A protocol may have several bundle forms. For any instance, in any role,
``fw_protocol::of(b)`` gives its protocol and ``fw_protocol::role_of(b)``
the role: initiator for an :sv:class:`fw_bundle`, target for an
:sv:class:`fw_mirror`, monitor for an :sv:class:`fw_monitor`.

Endpoints and sockets
---------------------

A component that works at method level declares endpoints.
:sv:class:`fw_port` is the required side (its owner calls the API) and
:sv:class:`fw_export` the provided side. When calls travel both ways, a
*socket* is typed by the pair: :sv:class:`fw_socket` ``#(OUT, IN)`` calls
``OUT`` and provides ``IN``, and its peer is ``fw_socket #(IN, OUT)``.
There is no separate target class; two identical full-duplex devices
connect socket to socket.

.. code-block:: systemverilog

   class src extends fw_component;
       `fw_component_utils(src)
       fw_port #(test_put_if #(uart_char_t)) p;
       virtual function void build();
           p = fw_port #(test_put_if #(uart_char_t))::create("p", this);
       endfunction
       virtual task run();
           p.get_if().put(c);
       endtask
   endclass

   class sink extends fw_component implements test_put_if #(uart_char_t);
       `fw_component_utils(sink)
       fw_export #(test_put_if #(uart_char_t)) e;
       virtual function void build();
           e = fw_export #(test_put_if #(uart_char_t))::create("e", this);
       endfunction
       virtual task put(uart_char_t t);
           ...
       endtask
   endclass

``sink`` implements the API itself, so it is its export's implementation
with no call. ``set_imp`` names another object instead. A port's
``get_if()`` returns the implementation it reaches. Endpoints are created
and connected like signals: in ``build()`` and in ``connect()``:

.. code-block:: systemverilog

   virtual function void connect();
       a.p.connect(k.e);       // a socket's connect binds both directions
   endfunction

A port binds once (``FW-E-SOCK-MULTI``); an export may serve many ports.
``connect_up`` passes a child's endpoint through the parent's endpoint of
the same type. After the connect phase every port must reach an export
(``FW-E-SOCK-UNBOUND``). Endpoints take domain associations as bundles do,
so a connection between two clock domains is reported as a crossing.

What is generated
-----------------

A kit's source is the protocol, its APIs, payload types and bundles.
Everything else is derived by a generator (fw-hdl-fe-sv's ``GenKit``)
into one package, ``<pkg>_gen_pkg``. The generators are tools; the shape
of what they derive is normative (``semantics/protocols.md``, "Derived
shapes"). For API ``<api>`` with method ``<m>``, and protocol prefix
``<p>``:

.. list-table::
   :header-rows: 1
   :widths: 30 70

   * - Class
     - What it is for
   * - ``<p>_req_if``, ``<p>_rsp_if``
     - the channel APIs of a bundle of channels: one task per channel,
       named as the channel
   * - ``<api>_base``
     - implements ``<api>``; each method reports an error until overridden
   * - ``<api>_listener``, ``_listener_base``, ``_listener_fanout``
     - ``<m>_pre`` and ``<m>_post`` callbacks around each call, and a
       fan-out to many listeners
   * - ``<api>_proxy``
     - forwards each call to a target, calling the listeners around it
   * - ``<api>_imp``
     - implements ``<api>`` by forwarding to a component's methods
   * - ``<api>_txn``, ``<api>_<m>_txn``, ``<api>_txn_sink``
     - one ``rand``-capable transaction per method, with ``sprint`` and
       ``compare``, and where recorded ones go
   * - ``<api>_txn_listener``, ``<api>_txn_driver``
     - record calls as transactions; replay transactions as calls
   * - ``<p>_payloads``
     - ``sprint``, ``compare`` and ``mask`` per struct channel payload
   * - ``<p>_pins``
     - ``flat(m, b, pre)``: the AXI-style pin-map preset, one pin per
       channel ``valid``, ``ready`` and payload field
   * - ``<p>_initiator``, ``<p>_target``, ``<p>_monitor``
     - for a bundle whose channels are all ``fw_rv_if``: the transactors
       (one :sv:class:`fw_rv_initiator` or :sv:class:`fw_rv_target` per
       channel, the direction from the bundle mixin, joined to the channel
       APIs by a socket) and a monitor (one :sv:class:`fw_rv_monitor` per
       channel; ``add_req_listener``/``add_rsp_listener`` attach a channel
       API's ``_listener``, whose ``<ch>_pre``/``<ch>_post`` are called at
       the channel's first cycle and handshake); all three are registered
       with the protocol

With ``<p>_pins``, an extern of an AXI-like module needs one line:

.. code-block:: systemverilog

   virtual function void extern_map(fw_extern_map m);
       void'(axi4_pins::flat(m, s, "s_axi_"));   // s_axi_awvalid, s_axi_awaddr, ...
   endfunction

Transactors
-----------

A transactor converts between the protocol's API and its bundle. It is a
component with an endpoint on one side and a bundle on the other, and it
registers with the hub with :sv:macro:`fw_xtor_utils` (which also declares
``create``). Its role is not stated: the bundle mixin gives it on the pin
side, and on the method side whether the protocol's request API goes out
or comes in:

.. code-block:: systemverilog

   class ux_init extends fw_component implements test_put_if #(uart_char_t);
       `fw_xtor_utils(ux_init, test_uart_proto)
       fw_export #(test_put_if #(uart_char_t)) t;     // the API, in
       fw_bundle #(test_uart_serial)           pins;  // the pins, out
       fw_cfg_sink #(uart_cfg_t)               cfg;
       ...
   endclass

A static front end checks the registration against the ports: a
transactor needs a bundle port of its protocol and an endpoint of its API
(``FW-E-PROTO-XTOR``). Finding the transactor for a bundle is static:
the tools go from the bundle to its protocol, to the registered
transactors, to the one whose pin side is the opposite mixin over the
same bundle type. In fw-hdl-fe-sv this is ``ScanResult.xtor_for(bundle,
kind)``: a ``bundle`` pin side finds the target, a ``mirror`` the
initiator.

A generated initiator and target run back to back, with no RTL, by
connecting their ``pins`` directly.

A monitor is a transactor too, registered in the monitor role (its pins
are an :sv:class:`fw_monitor`), so ``xtor_for(bundle, "monitor")`` finds
it. Its class side is a list of listeners rather than an endpoint: it
calls each listener at the first cycle of a transfer and at the
handshake. For :sv:class:`fw_rv_monitor` the listener extends
:sv:class:`fw_rv_mon_listener` and overrides ``put_pre``/``put_post``:

.. code-block:: systemverilog

   class in_seen extends fw_rv_mon_listener #(bit [7:0]);
       virtual function void put_post(input bit [7:0] t);
           $display("in: %0d", t);          // at the handshake edge
       endfunction
   endclass

   virtual function void connect();
       in_seen l = new();
       mon_in.add_listener(l);              // remove_listener(l) detaches it
   endfunction

A generated ``<p>_monitor`` has one :sv:class:`fw_rv_monitor` per channel
and a fan-out per channel API (``add_req_listener``,
``add_rsp_listener``) taking the kit's ``<api>_listener``.

Abstractors
-----------

When the abstract level is a protocol on its own (packets over a byte
PHY), there are two protocols and an *abstractor* between them, registered
with both by :sv:macro:`fw_abstractor_utils`. Neither protocol names the
other:

.. code-block:: systemverilog

   class pkt_over_phy extends fw_component implements test_put_if #(test_pkt_t);
       `fw_abstractor_utils(pkt_over_phy, test_phy_proto, test_pkt_proto)
       fw_export #(test_put_if #(test_pkt_t)) up;
       fw_bundle #(test_phy_bundle)           phy;
       ...
   endclass

``fw_protocol::abstractor_for(from, to)`` finds one in either direction.
It finds a single hop; chains are built by connecting abstractors. What
the upper level keeps is exactly its payload's fields, so what it drops
(UART bit timing) is dropped visibly.

Configuration
-------------

Configuration is a struct:

.. code-block:: systemverilog

   typedef struct packed {
       int unsigned baud;       // bits per second
       bit          parity;     // a parity bit follows the data
       bit [1:0]    stop_bits;  // 1 or 2
   } uart_cfg_t;

The owner of the configuration, typically the device, holds a
:sv:class:`fw_cfg_src`; each reader holds a :sv:class:`fw_cfg_sink` and
reads its ``cfg`` field directly. ``set(v)`` is the commit point: it
pushes a whole copy to every bound sink, so no sink sees a half-changed
value. A source also pushes when it is bound, so a ``set`` in the build
phase reaches every sink. A reader samples the fields it needs when a
transfer starts; a change takes effect on the next transfer. Only the
runtime writes a sink's ``cfg`` (``FW-E-CFG-WRITE``).

Configuration is a property of the endpoint, not of the protocol, and
each side of a link has its own. A sink is bound in ``connect()``:

.. code-block:: systemverilog

   virtual function void connect();
       x0.pins.connect(dev.p0);
       x1.pins.connect(dev.p1);
       x0.cfg.connect(dev.c0);
       x1.cfg.connect(dev.c1);
   endfunction

A sink that no source reaches is ``FW-E-CFG-UNBOUND``.

A sink passed up through a wrapper is joined with ``connect_up``, to an
endpoint of the same role on the wrapper; a source likewise. The value
then flows from the source, out along its ``connect_up`` chain, across
the one ``connect``, and in along the sink's chain. Only the innermost
sinks are reported unbound.

When configuration travels with an API, use a configured endpoint: a
port, export or socket that also carries the configuration, so one
``connect`` binds both.

=============  ===================================  ===================================
Endpoint       Sources the configuration            Sinks the configuration
=============  ===================================  ===================================
port           :sv:class:`fw_port_cfg_src`          :sv:class:`fw_port_cfg_sink`
export         :sv:class:`fw_export_cfg_src`        :sv:class:`fw_export_cfg_sink`
socket         :sv:class:`fw_socket_cfg_src`        :sv:class:`fw_socket_cfg_sink`
=============  ===================================  ===================================

``connect`` joins a source to a sink only (a port to an export, a socket
to the mirror socket); source to source, or sink to sink, does not
compile. ``connect_up`` joins an endpoint to its wrapper's endpoint of
the same kind and role. A configured endpoint does not connect to a plain
one. A second source reaching one sink is ``FW-E-SOCK-MULTI``.

A reader that must act on a change, not just sample at the next
transfer, implements :sv:class:`fw_cfg_listener_if` and registers with
``add_listener`` on its sink. ``changed(v)`` is called after each push,
including the one at bind:

.. code-block:: systemverilog

   class xtor extends fw_component implements uart_put_if,
           fw_cfg_listener_if #(uart_cfg_t);
       fw_export_cfg_sink #(uart_put_if, uart_cfg_t) e;
       virtual function void build();
           e = fw_export_cfg_sink #(uart_put_if, uart_cfg_t)::create("e", this);
           e.set_imp(this);
           e.add_listener(this);
       endfunction
       virtual function void changed(uart_cfg_t v);
           // recompute the bit period from v.baud
       endfunction
   endclass

Timing
------

A protocol carries no timing. The time a transfer takes, and what a
receiver sees when the two ends are configured differently, belong to
*channels*: kit components placed explicitly between two endpoints, with
the transfer time and the mismatch as their virtual methods. A kit
channel extends :sv:class:`fw_timed_channel`; elaboration never inserts
one, and a static front end records it as a plain component.

There are two kinds:

- a *forwarding* channel joins a device to a VIP. There is one
  configuration, the device's: the channel's export towards the device is
  a configured sink, its port towards the VIP a configured source, and it
  passes the device's configuration on. Each call waits the transfer time
  and is delivered as sent.
- a *sinking* channel joins two devices, each with its own configuration.
  Each device holds a :sv:class:`fw_socket_cfg_src`; the channel has a
  :sv:class:`fw_socket_cfg_sink` towards each. Each direction is timed by
  its sender's configuration, and ``mismatch`` gives the payload as the
  receiver sees it.

Both configurations are sampled when the transfer starts; a change during
a transfer takes effect on the next one. The caller blocks for the
transfer, then the channel delivers.

Two UART models joined by a sinking channel:

.. code-block:: systemverilog

   class uart_txrx_chan extends fw_timed_channel #(uart_cfg_t, uart_char_t);
       `fw_component_utils(uart_txrx_chan)
       fw_socket_cfg_sink #(uart_put_if, uart_put_if, uart_cfg_t) a, b;
       virtual function time xfer_time(uart_cfg_t cfg, uart_char_t t);
           return test_uart_proto::xfer_time(cfg, t) * 1ns;
       endfunction
       virtual function uart_char_t mismatch(uart_cfg_t tx_cfg,
               uart_cfg_t rx_cfg, uart_char_t t);
           return test_uart_proto::mismatch(tx_cfg, rx_cfg, t);  // sets frame_err
       endfunction
       ...
   endclass

   virtual function void connect();
       x.a.connect(ua.s);    // each model's socket sources its cfg registers
       x.b.connect(ub.s);
   endfunction

At 10 Mbaud on both sides each character takes 1000 ns; when ``ub``'s baud
register is changed, every character in either direction arrives with
``frame_err`` set. A class cannot implement the same API twice, so a
two-way channel serves each side through a small helper object.

Testbenches and bind modules
----------------------------

Since the transactor for each protocol port is found statically, a
testbench for a design can be generated. In fw-hdl-fe-sv:

.. code-block:: python

   from fw.hdl.fe.sv import elaborate
   from fw.hdl.fe.sv.scan import scan
   from fw.hdl.gen import gen_tb, gen_bind

   r = elaborate(["wrap_pkg.sv"], top="wrap_pkg::chain#(bit[7:0])", rtl=rtl)
   s = scan(["fw_hdl_std_pkg.sv"], incdirs=[...])   # where the transactors are
   tb_sv   = gen_tb(r, s, "chain", bind=True)
   bind_sv = gen_bind(r, s, "chain")

``gen_tb`` is called before the design is emitted. Its file holds:

- class ``<top>_tb_c``, a component with, per protocol port of the DUT, a
  pin bundle of the opposite mixin named as the port and the
  opposite-role transactor ``dut_<port>``; a clock domain ``clk`` and a
  reset domain ``rst``. A target transactor whose method port calls
  :sv:class:`fw_put_if` is bound to an :sv:class:`fw_inbox`
  ``dut_<port>_rx``. ``build`` and ``connect`` are split per concern
  (``build_domains``, ``build_xtors``, ``build_monitors`` and the
  ``connect_`` ones), so a subclass replaces one part.
- module ``<top>_tb #(type TB = <top>_tb_c)``: the DUT, one
  ``fw_pin_bridge`` per class pin, the clock and reset, and the
  class ``TB`` elaborated as ``top``. ``+fw_edges=N`` sets the run length
  (default 100 edges).

With ``bind=True`` the class also has, per port, an :sv:class:`fw_monitor`
pin bundle ``mon_<port>_pins`` and the monitor ``mon_<port>``.
``gen_bind`` writes module ``<top>_fw_mon``, whose ports are all inputs
named as the DUT's pins, with a bridge from each pin to the monitor's
pins, and the line ``bind <top> <top>_fw_mon u_fw_mon (...)``. The bound
module only samples, so the DUT's nets have no new driver.

A test extends the class and is selected by the module parameter; it
writes no pins and no bridges:

.. code-block:: systemverilog

   class test_c extends chain_tb_c implements fw_run_if;
       `fw_component_utils(test_c)
       virtual function void connect();
           super.connect();
           mon_out.add_listener(sb);          // a fw_rv_mon_listener
       endfunction
       virtual task run();
           bit [7:0] d;
           fw_reset_domain::wait_reset_done(this);
           dut_in.put(8'd17);                 // drives the DUT's in pins
           dut_out_rx.get(d);                 // what the DUT's out pins gave
       endtask
   endclass

   module top;
       chain_tb #(.TB(test_c)) tb();
   endmodule

The test is the same whether the DUT is emitted from fw-hdl or is
existing RTL. In fw-hdl-fe-sv's ``wrap_rtl`` example
(``tests/e2e/test_wrap_rtl_acceptance.py``), random traffic with input
gaps and output back-pressure, driven this way and scored on the bound
monitors' listeners, hand-shakes on the same cycles as an all-RTL
testbench driving the same sequence: the transactors add no latency.

Each generated testbench has one clock and at most one reset
(``FW-E-TB-DOMAINS`` otherwise), and binds one monitor per protocol
port; the bind module assumes one instance of the DUT module.
