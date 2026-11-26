acc: access to types and values
===============================

acc ("access") is optional run-time access to a design's types and values,
for testing, debug and reporting. It is part of ``fw_hdl_pkg``, but
optional by registration: a static front end generates the accessors
(fe-sv: ``fw.hdl.gen.acc``, dfm task ``GenAcc``) and they register here;
with none registered, every query returns null. Nothing in a design refers
to acc, and a tool's elaboration never calls it: it keeps typed values and
asks acc for their text only when it reports them (a netlist, debug output,
a test). See ``semantics/acc.md``.

Most of it is plain SV, the same in every tool. Only what needs a tool's
elaboration data is ``extern``: :sv:func:`fw_acc::path`,
:sv:func:`fw_acc_value_of::get` and :sv:func:`fw_acc_value_of::set` (the
tool links an accessor to the values it holds), and
:sv:func:`fw_acc_component::params` and
:sv:func:`fw_acc_component::param_src` (the tool's params values).

Generated accessors come in packages: ``<pkg>_acc`` per package (names and
value access for its classes and typedefs) and an optional per-design one
(the specializations, built-in types and constructor factories the design
uses). Each registers by static initialization and has an idempotent
``init()``::

    initial begin
        top_c_acc::init();      // per design; runs the per-package init()s
        ...
        fw_acc_component h = fw_acc::component(t.h1);
        fw_acc_field f[$];
        if (h != null && h.params(f)) foreach (f[i]) $display("%s = %s", f[i].name, f[i].text);
    end

Registry
--------

.. autosvclass:: fw_hdl_pkg::fw_acc
   :members:

.. autosvclass:: fw_hdl_pkg::fw_acc_field

Types and values
----------------

.. autosvclass:: fw_hdl_pkg::fw_acc_type
   :members:

.. autosvclass:: fw_hdl_pkg::fw_acc_value_of
   :members:

.. autosvclass:: fw_hdl_pkg::fw_acc_ctor_names
   :members:

Components
----------

.. autosvclass:: fw_hdl_pkg::fw_acc_component
   :members:

.. autosvclass:: fw_hdl_pkg::fw_acc_component_of
   :members:
