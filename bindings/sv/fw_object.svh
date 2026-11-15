// The base of every structural object: component, signal, port and bundle.
//
// Every structural object is created with ``T::create``, which supplies its
// name, parent and params before its constructor body runs, so constructors
// take no arguments. Constructing a structural object with ``new()`` is an
// error (``FW-E-ELAB-NEW``).
virtual class fw_object;

    // The tool's state for this object; see :sv:class:`fw_impl_if`. Reserved
    // for the tool: user code never reads or writes it.
    protected fw_impl_if __fw_impl;

endclass
