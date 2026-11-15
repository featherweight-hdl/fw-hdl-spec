Bundles
=======

A bundle type is written once, from the initiator's view, and used in one
of three roles:

=========================  ===================  ========================================
Role                       Meaning              A member declared ``fw_output`` is ...
=========================  ===================  ========================================
:sv:class:`fw_bundle`      initiator            an output
:sv:class:`fw_mirror`      target               an input
:sv:class:`fw_monitor`     observer             an input; every member is an input
=========================  ===================  ========================================

Bundles nest: a member may itself be a bundle in a role. Each mirror on the
path flips the effective direction, and a monitor anywhere on the path makes
every member below it an input. An ``fw_inout`` member stays inout in every
role.

.. autosvclass:: fw_hdl_pkg::fw_bundle_base
   :members:

.. autosvclass:: fw_hdl_pkg::fw_bundle
   :members:

.. autosvclass:: fw_hdl_pkg::fw_mirror
   :members:

.. autosvclass:: fw_hdl_pkg::fw_monitor
   :members:

.. autosvclass:: fw_hdl_pkg::fw_rv_if
   :members:
