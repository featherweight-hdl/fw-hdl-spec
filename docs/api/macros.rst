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
=========================================  ==================================  ==================================

.. autosvsummary::
   :kinds: macro
   :exclude: FW_HDL_MACROS_SVH
