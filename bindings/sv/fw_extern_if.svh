// Implemented by an extern: a component realized by an existing RTL module.
//
// An extern declares ports and bundles like any component, has no children,
// and supplies a pin map. :sv:macro:`fw_extern_utils` declares
// :sv:func:`fw_extern_if::extern_module`, and the class writes
// :sv:func:`fw_extern_if::extern_map`::
//
//     class rv_fifo #(type T = bit[7:0]) extends fifo_api #(T) implements fw_extern_if;
//         `fw_extern_utils(rv_fifo #(T), "fw_rv_fifo")
//
//         virtual function void extern_map(fw_extern_map m);
//             m.param("DEPTH", fw_value #(int)::of(params.depth));
//             void'(m.prefix(in, "in_").rename("valid", "vld"));
//         endfunction
//     endclass
//
// Extern is an interface rather than a base class so an extern can extend
// an abstract component (``fifo_api`` above), whose creator chooses the
// realization.
interface class fw_extern_if;

    // Returns the name of the RTL module. Source files are not named here:
    // the build system supplies them, and the module is found by name.
    //
    // :returns: the module name
    pure virtual function string extern_module();

    // Fills in the pin map.
    //
    // :param m: the map, created by the tool
    pure virtual function void   extern_map(fw_extern_map m);

endclass
