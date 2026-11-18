Protocols
=========

A protocol class is the hub of one interface standard: its APIs, bundles,
transactors and abstractors register with it, and every part is found from
it. A component reaches a protocol's APIs through endpoints and sockets,
and its run-time configuration through sources and sinks. The rules
are in ``semantics/protocols.md``; the guide is :doc:`../protocols`.

Protocol classes and their handles
----------------------------------

.. autosvclass:: fw_hdl_pkg::fw_protocol
   :members:

.. autosvclass:: fw_hdl_pkg::fw_protocol_decl
   :members:

.. autosvclass:: fw_hdl_pkg::fw_protocol_type
   :members:

.. autosvclass:: fw_hdl_pkg::fw_protocol_type_of
   :members:

.. autosvclass:: fw_hdl_pkg::fw_protocol_family
   :members:

.. autosvsummary:: fw_proto_*_e
   :packages: fw_hdl_pkg
   :kinds: typedef

APIs
----

.. autosvclass:: fw_hdl_pkg::fw_api_type
   :members:

.. autosvclass:: fw_hdl_pkg::fw_api_type_of
   :members:

Endpoints and sockets
---------------------

.. autosvclass:: fw_hdl_pkg::fw_port
   :members:

.. autosvclass:: fw_hdl_pkg::fw_export
   :members:

.. autosvclass:: fw_hdl_pkg::fw_socket
   :members:

Configuration
-------------

.. autosvclass:: fw_hdl_pkg::fw_cfg_src
   :members:

.. autosvclass:: fw_hdl_pkg::fw_cfg_sink
   :members:

.. autosvclass:: fw_hdl_pkg::fw_cfg_listener_if
   :members:

.. autosvclass:: fw_hdl_pkg::fw_port_cfg_src
   :members:

.. autosvclass:: fw_hdl_pkg::fw_port_cfg_sink
   :members:

.. autosvclass:: fw_hdl_pkg::fw_export_cfg_src
   :members:

.. autosvclass:: fw_hdl_pkg::fw_export_cfg_sink
   :members:

.. autosvclass:: fw_hdl_pkg::fw_socket_cfg_src
   :members:

.. autosvclass:: fw_hdl_pkg::fw_socket_cfg_sink
   :members:
