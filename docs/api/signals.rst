Signals and ports
=================

Connections follow the locality rule: a component connects only its own
ports and local signals and those of its direct children
(``FW-E-CONN-SCOPE``). Connected endpoints form one net, which must have
exactly one source if it has any sink (``FW-E-NET-MULTI``,
``FW-E-NET-UNDRIVEN``). An unconnected input that is not tied is an error
(``FW-E-IN-OPEN``).

Processes (:doc:`processes`) read and write signals with ``read`` and
``write``; whether a write is a wire or a register follows from the
process that makes it (``semantics/processes.md``).

.. autosvclass:: fw_hdl_pkg::fw_signal
   :members:

.. autosvclass:: fw_hdl_pkg::fw_input
   :members:

.. autosvclass:: fw_hdl_pkg::fw_output
   :members:

.. autosvclass:: fw_hdl_pkg::fw_inout
   :members:

.. autosvclass:: fw_hdl_pkg::fw_signal_base
