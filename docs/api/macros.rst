Macros
======

Include ``fw_hdl_macros.svh`` outside the package that uses them. Each
macro's name, arguments and the members it declares are API; the expansion
is each tool's own.

=========================================  ==================================  ==================================
Macro                                      Used in                             Declares
=========================================  ==================================  ==================================
:sv:macro:`fw_component_utils`             every concrete component            ``create``
:sv:macro:`fw_extern_utils`                every concrete extern               ``create``, ``extern_module``
:sv:macro:`fw_component_params`            the class declaring ``params_t``    ``params``
:sv:macro:`fw_component_params_init`       the same, with an init function     ``params``
:sv:macro:`fw_domain_kind_utils`           every domain kind                   ``get_type``
:sv:macro:`fw_protocol_utils`              every protocol class                ``get_type``
:sv:macro:`fw_protocol_param_utils`        a parameterized protocol class      ``get_type``
:sv:macro:`fw_xtor_utils`                  every transactor and monitor        ``create``
:sv:macro:`fw_xtor_param_utils`            a parameterized transactor          ``create``
:sv:macro:`fw_abstractor_utils`            every abstractor                    ``create``
:sv:macro:`fw_abstractor_param_utils`      a parameterized abstractor          ``create``
:sv:macro:`fw_bundle_protocol`             a bundle type of a protocol         nothing; names the protocol
:sv:macro:`fw_comb`                        several combinational blocks        one comb process each
:sv:macro:`fw_step`                        several clocked blocks              one step process each
=========================================  ==================================  ==================================

.. autosvsummary::
   :kinds: macro
   :exclude: FW_HDL_MACROS_SVH
