Domains
=======

A domain marks the parts of a design that share a clock, a reset, or any
other kind of domain. A component declares domain objects in its build
phase, associates its children and interfaces with them, and each child
reads its own with ``get``. A domain becomes a net only when an extern pin
is mapped to it or a signal drives it. The rules are in
``semantics/domains.md``.

Domain objects and their API
----------------------------

.. autosvclass:: fw_hdl_pkg::fw_domain
   :members:

.. autosvclass:: fw_hdl_pkg::fw_domain_base
   :members:

.. autosvsummary:: fw_*_domain
   :packages: fw_hdl_pkg
   :kinds: typedef

.. autosvsummary:: fw_domain_rel_e
   :packages: fw_hdl_pkg
   :kinds: typedef

.. autosvsummary:: fw_severity_e
   :packages: fw_hdl_pkg
   :kinds: typedef

Library kinds
-------------

.. autosvclass:: fw_hdl_pkg::fw_clock_kind
   :members:

.. autosvclass:: fw_hdl_pkg::fw_reset_kind
   :members:

Writing a kind
--------------

.. autosvclass:: fw_hdl_pkg::fw_domain_kind
   :members:

.. autosvclass:: fw_hdl_pkg::fw_domain_kind_type
   :members:

.. autosvclass:: fw_hdl_pkg::fw_domain_kind_type_of
   :members:
