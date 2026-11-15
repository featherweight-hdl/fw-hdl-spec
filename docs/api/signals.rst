Signals and ports
=================

Connections follow the locality rule: a component connects only its own
ports and local signals and those of its direct children
(``FW-E-CONN-SCOPE``). Connected endpoints form one net, which must have
exactly one source if it has any sink (``FW-E-NET-MULTI``,
``FW-E-NET-UNDRIVEN``). An unconnected input that is not tied is an error
(``FW-E-IN-OPEN``).

.. autosvclass:: fw_hdl_pkg::fw_signal
   :members:

.. autosvclass:: fw_hdl_pkg::fw_input
   :members:

.. autosvclass:: fw_hdl_pkg::fw_output
   :members:

.. autosvclass:: fw_hdl_pkg::fw_inout
   :members:

.. autosvclass:: fw_hdl_pkg::fw_signal_base
