Processes
=========

A component describes behaviour by implementing process interfaces. Its
processes read and write signals with :sv:func:`fw_signal::read` and
:sv:func:`fw_signal::write` and wait through the domain operations of
:sv:class:`fw_domain`. Elaboration finds every process; there is no
registration call. The rules (settle, edge order, reset, time) are in
``semantics/processes.md``; the scenarios ``conformance/proc_*`` check them.

=============================  =================  =============  ==============================
Interface                      Method             Kind           fe-sv emits
=============================  =================  =============  ==============================
:sv:class:`fw_comb_if`         ``comb()``         combinational  ``always_comb``
:sv:class:`fw_step_if`         ``step()``         clocked        ``always_ff``
:sv:class:`fw_reset_state_if`  ``reset_state()``  reset values   the ``always_ff`` reset branch
:sv:class:`fw_run_if`          ``run()``          behavioral     nothing; simulation-only
=============================  =================  =============  ==============================

A component with more than one combinational or clocked block declares each
with :sv:macro:`fw_comb` or :sv:macro:`fw_step`.

Process interfaces
------------------

.. autosvclass:: fw_hdl_pkg::fw_comb_if
   :members:

.. autosvclass:: fw_hdl_pkg::fw_step_if
   :members:

.. autosvclass:: fw_hdl_pkg::fw_reset_state_if
   :members:

.. autosvclass:: fw_hdl_pkg::fw_run_if
   :members:

Task-sync crossings
-------------------

Task code reaches a component's sync code through a task-sync crossing it owns:
``fw_to_sync`` carries items from task code into ``step()`` and
``comb()``, ``fw_from_sync`` carries them back out. The task side only
hands off (``put``, ``get``); the owner's ``comb()`` looks
(``valid``/``peek``, ``ready``/``waiting``) and its ``step()`` moves items
(``take``, ``give``), so the pin timing stays in code that lowers. The
rules (X1 to X8) are in ``semantics/processes.md``, "Task-sync crossings".

.. autosvclass:: fw_hdl_pkg::fw_to_sync
   :members:

.. autosvclass:: fw_hdl_pkg::fw_from_sync
   :members:

Waiting and time
----------------

A ``run()`` task starts when its component's reset deasserts and is killed,
with the threads it forked, when the reset asserts; it starts again at the
next deassert, so it needs no :sv:func:`fw_domain::wait_reset_done`. It
waits on its domains with :sv:func:`fw_domain::tick` and
:sv:func:`fw_domain::wait_assert`;
``step()`` and ``comb()`` test reset with :sv:func:`fw_domain::in_reset`.
A root clock with a ``period`` (:sv:func:`fw_clock_kind::root`) is driven
by the simulation kernel, so a design runs with no testbench clock.

.. autosvclass:: fw_hdl_pkg::fw_time
   :members:
