Params and constructor factories
================================

A component's params value is resolved when it is created, from these
sources, lowest precedence first:

#. the defaults of ``mk_params``;
#. the value the creator passed to ``create``;
#. overrides registered by ancestors, from the nearest to the farthest
   (:sv:class:`fw_param_override`);
#. global overrides;
#. the component's init function (:sv:macro:`fw_component_params_init`),
   which fills in defaults that cannot be constants.

.. autosvclass:: fw_hdl_pkg::fw_param_override
   :members:

.. autosvclass:: fw_hdl_pkg::fw_param_edit
   :members:

.. autosvclass:: fw_hdl_pkg::fw_ctor
   :members:

.. autosvclass:: fw_hdl_pkg::fw_ctor_of
   :members:
