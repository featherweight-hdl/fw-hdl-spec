Clocks, resets and other domains
================================

A wrapped module's clock and reset pins are not ports to wire by hand.
They belong to *domains*: a component creates its clock and reset domains,
says which children and interfaces are in which, and each wrapper maps its
pins to the domains it is in. The tools check every connection between
domains, and the generated Verilog gets the clock and reset ports, nets and
inverters each module needs.

The API reference is :doc:`api/domains`; the rules are in
``semantics/domains.md``. Two complete examples are in fw-hdl-fe-sv:
``examples/wrap_rtl`` and ``examples/domains``.

Create domains and set them
---------------------------

A domain is an object of a *kind*: :sv:class:`fw_clock_kind` and
:sv:class:`fw_reset_kind` come with the library, as the typedefs
``fw_clock_domain`` and ``fw_reset_domain``. A component creates domains in
``build()`` and associates them with itself, its children and its
interfaces with ``set``:

.. code-block:: systemverilog

   virtual function void build();
       clk_a_i = fw_input #(bit)::create("clk_a_i", this);
       clk_b_i = fw_input #(bit)::create("clk_b_i", this);
       rst_ni  = fw_input #(bit)::create("rst_ni",  this);
       out     = fw_bundle #(fw_rv_if #(T))::create("out", this);

       clk_a = fw_clock_domain::create("clk_a", this);
       clk_b = fw_clock_domain::create("clk_b", this);
       slow  = fw_clock_domain::create("slow", this,
                   fw_clock_kind::derived(clk_a, .div(2)));
       rst   = fw_reset_domain::create("rst", this);

       fw_clock_domain::set(this, clk_a);     // the default for soc and below
       fw_reset_domain::set(this, rst);
       fw_clock_domain::set(out, clk_b);      // this interface is in clk_b
       ...
   endfunction

``set`` takes the component itself, a direct child (after its
``create``), or one of the component's own ports or bundles; a bundle is
one interface, and its members follow it. Anything that is not set looks
up: a port takes its component's domain, a component its parent's. So one
``set(this, clk)`` at the top puts the whole design in ``clk``.

A child reads its own domain with ``get``:

.. code-block:: systemverilog

   fw_clock_domain my_clk = fw_clock_domain::get(this);

Derivations
-----------

A domain made with ``K::root()`` (the default) has no sources. Any other
derivation names its sources: ``fw_clock_kind::derived(clk_a, .div(2))``,
``fw_reset_kind::synced(por, clk)``. The tools compute how two domains
relate from their sources:

``FW_DOMAIN_SAME``
   the same domain object;
``FW_DOMAIN_RELATED``
   they share a root through their sources (``clk_a`` and ``slow``);
``FW_DOMAIN_UNRELATED``
   they do not (``clk_a`` and ``clk_b``).

A wrong-kind source is ``FW-E-DOM-KIND``.

Drive a domain
--------------

A domain becomes a net when something drives it. A component drives one
from a 1-bit port or signal of its own, in ``connect()``. A reset's driver
states its polarity:

.. code-block:: systemverilog

   virtual function void connect();
       clk_a.drive(clk_a_i);
       clk_b.drive(clk_b_i);
       rst.drive(rst_ni, fw_reset_kind::active_low());
       ...
   endfunction

A wrapped module can drive a domain too: a clock divider's output, a reset
synchronizer's. See ``pin_out`` below. A domain with two drivers is
``FW-E-DOM-DRIVER``; one that some pin needs but nothing drives is
``FW-E-DOM-NODRIVER``.

Map a wrapper's pins
--------------------

In ``extern_map()``, a wrapper maps its module's clock and reset pins to
domains instead of ports. With no domain given, a pin is in the wrapper's
own domain of that kind:

.. code-block:: systemverilog

   virtual function void extern_map(fw_extern_map m);
       fw_clock_domain::pin(m, "clk");
       fw_reset_domain::pin(m, "rst");                    // expects active high
       void'(m.prefix(in,  "in_").rename("valid", "vld").rename("ready", "rdy"));
       void'(m.prefix(out, "out_").rename("valid", "vld").rename("ready", "rdy"));
   endfunction

A reset pin states the polarity it expects,
``fw_reset_kind::active_low()`` or ``active_high()`` (the default). It may
also state the style it requires (``ASYNC``, ``SYNC``); a reset domain of
another style is ``FW-W-DOM-STYLE``. Where a pin's polarity differs from
its net's, the generated Verilog inverts.

Named associations
------------------

A component in more than one domain of a kind names them. Its parent sets
each name; its own code reads them with ``get(this, name)``. A dual-clock
FIFO's wrapper:

.. code-block:: systemverilog

   class cdc_fifo #(type T = bit[7:0]) extends fw_component implements fw_extern_if;
       `fw_extern_utils(cdc_fifo #(T), "async_fifo")
       fw_mirror #(fw_rv_if #(T))  in;
       fw_bundle #(fw_rv_if #(T))  out;

       virtual function void build();
           in  = fw_mirror #(fw_rv_if #(T))::create("in",  this);
           out = fw_bundle #(fw_rv_if #(T))::create("out", this);
           fw_clock_domain::set(in,  fw_clock_domain::get(this, "wr"));
           fw_clock_domain::set(out, fw_clock_domain::get(this, "rd"));
       endfunction

       virtual function void extern_map(fw_extern_map m);
           fw_clock_domain::pin(m, "wr_clk", fw_clock_domain::get(this, "wr"));
           fw_clock_domain::pin(m, "rd_clk", fw_clock_domain::get(this, "rd"));
           fw_reset_domain::pin(m, "wr_rst_n", null, fw_reset_kind::active_low());
           fw_reset_domain::pin(m, "rd_rst_n", null, fw_reset_kind::active_low());
           ...
       endfunction
   endclass

and its parent:

.. code-block:: systemverilog

   af = cdc_fifo #(T)::create("af", this);
   fw_clock_domain::set(af, wr_clk, "wr");
   fw_clock_domain::set(af, rd_clk, "rd");

A name the parent does not set falls back to the component's default. A
name set but never read by the component is ``FW-E-DOM-UNUSED``.

A wrapper that produces a domain drives one of its named associations from
an output pin, and can state the derivation it provides, which is checked
against the domain its parent sets (``FW-E-DOM-DERIV``):

.. code-block:: systemverilog

   class div2 extends fw_component implements fw_extern_if;
       `fw_extern_utils(div2, "clk_div2")
       virtual function void build();
           fw_clock_domain::provides(this, "out",
               fw_clock_kind::derived(fw_clock_domain::get(this), .div(2)));
       endfunction
       virtual function void extern_map(fw_extern_map m);
           fw_clock_domain::pin(m, "clk_i");
           fw_reset_domain::pin(m, "rst_ni", null, fw_reset_kind::active_low());
           fw_clock_domain::pin_out(m, "clk_o", fw_clock_domain::get(this, "out"));
       endfunction
   endclass

   // in the parent's build():
   div = div2::create("div", this);
   fw_clock_domain::set(div, slow, "out");

Choose structure by how domains relate
--------------------------------------

``relate`` works in ``build()``, so a component can build what its domains
need. A block that moves a stream from its ``wr`` clock to its ``rd``
clock uses a plain FIFO when they are one clock, and a dual-clock FIFO
otherwise:

.. code-block:: systemverilog

   fw_clock_domain wr = fw_clock_domain::get(this, "wr");
   fw_clock_domain rd = fw_clock_domain::get(this, "rd");
   if (fw_clock_domain::relate(wr, rd) == FW_DOMAIN_SAME) begin
       sf = rv_fifo #(T)::create("sf", this);
       fw_clock_domain::set(sf, wr);
   end else begin
       af = cdc_fifo #(T)::create("af", this);
       fw_clock_domain::set(af, wr, "wr");
       fw_clock_domain::set(af, rd, "rd");
   end

Crossings
---------

Every connection between two interfaces is checked, for each kind. When
their domains differ, the kind's severity for the relation decides what is
reported, on the connection's first endpoint:

=========  =====  ========  =========
Kind       same   related   unrelated
=========  =====  ========  =========
clock      none   info      error
reset      none   warning   error
=========  =====  ========  =========

``FW-E-DOM-CROSS`` (error), ``FW-W-DOM-CROSS`` (warning) or
``FW-I-DOM-CROSS`` (information); the message names the kind and both
domains::

   FW-E-DOM-CROSS: top.out: fw_clock_kind crossing from top.clk_a to top.clk_b (top.x1.out)

A component whose own interfaces are in different domains, such as the
dual-clock FIFO above, is a *crossing element*: connecting to it is not a
crossing. An interface with no domain of a kind is not checked for that
kind.

A crossing known to be safe is waived in ``connect()`` of the component
that makes the connection, with a reason:

.. code-block:: systemverilog

   fw_clock_domain::waive(cfg.o, core.mode_i, "quasi-static: written only in reset");

An empty reason is ``FW-E-DOM-WAIVE``; a waiver that matches no crossing is
``FW-W-DOM-WAIVE``.

Changing the severities
~~~~~~~~~~~~~~~~~~~~~~~

Each tool takes an option that overrides a kind's severities, by kind name
and relation. A relation is ``same``, ``related`` or ``unrelated``; a
severity is ``none``, ``info``, ``warning`` or ``error``, and ``none``
silences.

fe-sv (the dfm task ``fw.hdl.fe.sv.Elaborate``):

.. code-block:: yaml

   - name: elab
     uses: fw.hdl.fe.sv.Elaborate
     with:
       top: "my_pkg::soc"
       domain_severity:
         fw_reset_kind: {unrelated: warning}

rt-sv (a plusarg of the elaboration run)::

   +fw_dom_sev=fw_reset_kind.unrelated=warning,fw_clock_kind.related=none

What the generated Verilog gets
-------------------------------

A static front end turns domains into ordinary ports, nets and assigns.
One module is generated per class, so a module's domain ports are a
property of its class:

- A class gets an input port for each association its subtree uses, named
  by the kind: ``clk``, ``wr_clk``, ``rst``, ``rst_n``. An association
  that something in the subtree drives (a divider's ``out``) is an output
  port. ``fw_domain #(K)::port_name(this, assoc, "my_clk")`` names a
  class's port; a generated name that collides with another port is
  ``FW-E-DOM-PORTNAME``.
- A reset port's polarity is what its subtree's pins expect, when they
  agree; otherwise active high.
- A domain the class creates is a net named after it, assigned from its
  driver: ``assign clk_a = clk_a_i;``.
- Where a pin or port expects the other polarity from its net, the module
  declares one inverted net and connects it: ``assign rst_inv = ~rst;``.

For ``examples/domains``, the top:

.. code-block:: systemverilog

   logic clk_a;
   logic clk_b;
   logic rst;
   logic slow;
   logic rst_inv;

   assign clk_a = clk_a_i;
   assign clk_b = clk_b_i;
   assign rst = rst_ni;
   assign rst_inv = ~rst;

   clk_div2 div (
     .clk_i(clk_a),
     .rst_ni(rst),
     .clk_o(slow)
   );

   xfer #(.T(T)) x1 (
     .wr_clk(clk_a),
     .rst(rst_inv),
     ...

   xfer__1 #(.T(T)) x2 (
     .rd_clk(slow),
     .wr_clk(clk_a),
     .rst_n(rst),
     ...

``x1`` joins ``clk_a`` to itself and builds the single-clock FIFO, whose
reset is active high; ``x2`` crosses and builds the dual-clock one. The two
structures are two classes, ``xfer`` and ``xfer__1``.

A domain that nothing drives and no pin reads emits nothing.

Writing a kind
--------------

Clock and reset are kinds written with the same API a user has. A kind is
a class of static members that extends :sv:class:`fw_domain_kind` and uses
:sv:macro:`fw_domain_kind_utils`. It redeclares only what it changes; the
base declares a *marker* kind, with no properties and no net. A kind for
tracking which hard macro each part of a design belongs to, where a
connection between macros is worth knowing about but not an error:

.. code-block:: systemverilog

   class macro_kind extends fw_domain_kind;
       `fw_domain_kind_utils(macro_kind)
       static function fw_severity_e severity(fw_domain_rel_e r);
           return (r == FW_DOMAIN_SAME) ? FW_SEV_NONE : FW_SEV_INFO;
       endfunction
   endclass

   typedef fw_domain #(macro_kind) macro_domain;

``macro_domain`` objects are created, set, looked up, checked at
connections and listed in the netlist like clocks and resets, with no
change to the tools. A marker kind emits nothing. What a kind can declare:

``params_t``, ``root()`` and derivations
   The domain's properties. ``params_t`` has ``from``, the sources of the
   same kind, from which relations are computed; each derivation is a
   static function returning a ``params_t``.
``pin_attr_t``, ``pin_default()``
   What a pin or a driver states. A 1-bit member named ``active_low`` is
   the polarity, which emission inverts for.
``severity(r)``
   The default severity of a crossing for each relation.
``physical()``
   1 for a kind whose domains are 1-bit nets (clock, reset): it can have
   pins and drivers, and emission makes ports and nets for it.
``port_name(assoc, attr)``
   The generated port name for an association and a pin's attributes.
