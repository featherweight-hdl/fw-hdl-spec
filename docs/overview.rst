Overview
========

The API is declarations only
----------------------------

``fw_hdl_pkg`` declares classes, typedefs and macros, with no method bodies:
every method is an ``extern`` prototype or ``pure virtual``. The one
exception is :sv:class:`fw_rv_if`, a bundle type written *with* the API like
a user's.

Each tool (the reference runtime ``rt-sv``, the static front end ``fe-sv``)
provides its own ``fw_hdl_pkg``. It includes the spec's declarations
unchanged and supplies an out-of-block body for every ``extern`` method:

.. code-block:: systemverilog

   package fw_hdl_pkg;
       `include "fw_hdl_api.svh"              // the spec's, unchanged
       `include "rt_sv_bodies.svh"            // the tool's bodies
   endpackage

The files, in ``bindings/sv``:

``fw_hdl_pkg.sv``
   The package. The spec's has no bodies of its own.
``fw_hdl_api.svh``
   Every declaration, one class per included ``.svh``.
``fw_hdl_macros.svh``
   The user-facing macros. Their names, arguments and the members they
   declare are API; each tool supplies its own expansions.

The recipe
----------

User code follows one recipe:

- **Declare** fields and handles with the API classes:
  ``fw_input #(T)``, ``fw_mirror #(B)``, ``fifo #(T)``.
- **Create** anything with ``T::create``. The API classes declare it; user
  components get it from :sv:macro:`fw_component_utils`.

.. code-block:: systemverilog

   fw_input  #(bit)            clk;
   fw_mirror #(fw_rv_if #(T))  in;
   fifo      #(T)              u;

   clk = fw_input  #(bit)::create("clk", this);
   in  = fw_mirror #(fw_rv_if #(T))::create("in", this);
   u   = fifo #(T)::create("u", this, fifo #(T)::mk_params(.depth(4)));

Exceptions, none of them structural objects: the tool creates the extern
map and pin rules and hands them to ``extern_map()``; constructor factories
come from :sv:func:`fw_ctor_of::get`; edit overrides
(:sv:class:`fw_param_edit`) are created with ``new()``.

Elaboration
-----------

Elaboration runs these phases in order:

#. **Build**, top-down. :sv:func:`fw_component::build` creates children,
   signals, ports and bundles, and registers params overrides.
#. **Connect**, top-down. :sv:func:`fw_component::connect` makes
   connections and ties.
#. **Resolve.** The tool forms nets and checks them, reporting every
   error rather than only the first.

After resolution the structure is immutable. The full semantics, with the
diagnostic IDs (``FW-E-...``) quoted in this reference, are in the layer-1
design document, ``docs/design/core-layer1.md`` §3.

Rules for a tool
----------------

- **Add nothing to API classes.** A tool's state for an object hangs off
  one handle, :sv:obj:`fw_object::__fw_impl`, of the empty interface class
  :sv:class:`fw_impl_if`. The tool stores an object of its own class there
  and downcasts to it.
- **Names beginning** ``__fw_`` are reserved for the API and its macros. A
  macro expansion may declare only the members the macro documents, plus
  ``__fw_`` names.
- Methods that return a type built from class parameters return a class
  typedef (``this_t``, ``base_t``, ``ctor_t``), so out-of-block bodies can
  name it: ``function fw_mirror::this_t fw_mirror::create(...)``.

The spec compile-checks code written against the API without any tool: the
``sv-api-compile`` task generates a default body for every ``extern`` method
with an sv-weave weaver (``tools/fw_hdl_bodies.py``).
