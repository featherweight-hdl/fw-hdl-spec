Wrapping and assembling RTL
===========================

This guide shows the everyday use of layer 1: take RTL modules you already
have, give each a component with typed ports, and connect them with
bundles instead of wires. A static front end then generates plain Verilog
in which every wrapper is replaced by its module.

Wrap a module
-------------

A wrapper is a component that implements ``fw_extern_if``. It declares its
ports in ``build()`` like any component, and maps them onto the module's
pins in ``extern_map()``:

.. code-block:: systemverilog

   class rv_fifo #(type T = bit[7:0]) extends fw_component implements fw_extern_if;
       typedef struct { int depth; } params_t;
       static function params_t mk_params(int depth = 2);
           params_t p;
           p.depth = depth;
           return p;
       endfunction
       `fw_component_params
       `fw_extern_utils(rv_fifo #(T), "fw_rv_fifo")

       fw_mirror #(fw_rv_if #(T))  in;
       fw_bundle #(fw_rv_if #(T))  out;

       virtual function void build();
           in  = fw_mirror #(fw_rv_if #(T))::create("in",  this);
           out = fw_bundle #(fw_rv_if #(T))::create("out", this);
       endfunction

       virtual function void extern_map(fw_extern_map m);
           m.param("WIDTH", fw_value #(int)::of($bits(T)));
           m.param("DEPTH", fw_value #(int)::of(params.depth));
           fw_clock_domain::pin(m, "clk");          // the wrapper's clock domain
           fw_reset_domain::pin(m, "rst");          // its reset, active high
           void'(m.prefix(in,  "in_").rename("valid", "vld").rename("ready", "rdy"));
           void'(m.prefix(out, "out_").rename("valid", "vld").rename("ready", "rdy"));
       endfunction
   endclass

The map, in order of precedence:

``pin(name, port)``
   Maps one module pin to one port.
``prefix(bundle, pre)`` and ``rename(member, part)``
   Maps every member of a bundle to ``pre`` plus its name, with renames.
   One rule covers any protocol, because a bundle's members come from its
   type.
``fw_clock_domain::pin(m, name)``, ``fw_reset_domain::pin(m, name, ...)``
   A clock or reset pin, connected to the wrapper's domain of that kind
   (:doc:`domains`). It is not a port: nothing wires it by hand.
``tie(name, value)`` / ``open(name)``
   An input pin driven with a constant; an output pin left unconnected.
The default rule
   Any port still unmapped goes to the pin with its flattened name:
   ``in_data``.

A tool that has the module's source checks the map against the module
header: every pin is accounted for exactly once (``FW-E-EXT-PIN``), every
port reaches a pin (``FW-E-EXT-PORT``), and directions and widths agree
(``FW-E-EXT-DIR``, ``FW-E-EXT-WIDTH``).

Choose the bundle roles
-----------------------

A bundle type, such as ``fw_rv_if``, writes directions from its
initiator's side. Each use picks a role:

* ``fw_bundle #(B)``: the initiator side (a producer's output stream);
* ``fw_mirror #(B)``: the target side, all directions flipped (a
  consumer's input stream);
* ``fw_monitor #(B)``: every member an input, for checkers and taps.

Assemble
--------

The assembly is an ordinary component. It creates children in ``build()``
and connects them in ``connect()``:

.. code-block:: systemverilog

   virtual function void connect();
       fifo.in.connect_up(in);       // a child's target side, passed up
       fifo.out.connect(slice.s);    // initiator to target, between siblings
       slice.m.connect_up(out);      // a child's initiator side, passed up
   endfunction

The compiler checks that the bundle types and roles fit each other.
Elaboration checks the rest: one driver per net (``FW-E-NET-MULTI``), no
undriven net (``FW-E-NET-UNDRIVEN``), and no input left open
(``FW-E-IN-OPEN``).

Clocks and resets
-----------------

The assembly creates a clock and a reset domain, makes them its defaults
(its children inherit them), and drives them from its inputs. No clock or
reset is connected by hand:

.. code-block:: systemverilog

   virtual function void build();
       clk_i = fw_input #(bit)::create("clk_i", this);
       rst_i = fw_input #(bit)::create("rst_i", this);
       clk   = fw_clock_domain::create("clk", this);
       rst   = fw_reset_domain::create("rst", this, fw_reset_kind::root(.clock(clk)));
       fw_clock_domain::set(this, clk);
       fw_reset_domain::set(this, rst);
       ...
   endfunction

   virtual function void connect();
       clk.drive(clk_i);
       rst.drive(rst_i);             // an active-high net
       ...
   endfunction

If two wrapped modules disagree on reset polarity, each maps its pin with
the polarity it expects (``fw_reset_kind::active_low()``), and the
generated Verilog inverts where a pin differs from its net. Several clocks,
derived clocks and the crossing check are in :doc:`domains`.

What the generated Verilog looks like
-------------------------------------

Each generated module has the assembly's ports with bundles flattened
(``in_valid``, ``in_ready``, ``in_data``) and one instance per wrapper, of
the wrapped module itself. The domains are nets assigned from the
assembly's inputs, with an inverted reset for the active-low pin:

.. code-block:: systemverilog

   assign clk = clk_i;
   assign rst = rst_i;
   assign rst_inv = ~rst;

   fw_rv_fifo #(.WIDTH(8), .DEPTH(4)) fifo (
     .clk(clk), .rst(rst),
     .in_data(in_data), .in_vld(in_valid), .in_rdy(in_ready),
     .out_data(fifo_out_data), .out_vld(fifo_out_valid), .out_rdy(slice_s_ready));

   axis_reg #(.DATA_W(8)) slice (
     .aclk(clk), .aresetn(rst_inv),
     ...
