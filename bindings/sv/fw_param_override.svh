// Params overrides for components whose params type is ``P``.
//
// Register an override in :sv:func:`fw_component::build`, or in a
// constructor, before its targets are created; one that matches a component
// already created is an error (``FW-E-PARAM-LATE``), and one that matches
// nothing by the end of build is a warning (``FW-W-PARAM-UNUSED``).
//
// ``scope`` is the registering component, and ``glob`` is a path relative
// to it. A null ``scope`` makes a global override, and ``glob`` is then a
// full path. In a glob, ``*`` matches within one path segment and ``**``
// matches any number of segments::
//
//     fw_param_override #(fifo_api #(T)::params_t)::set (this, "u[0]", p);
//     fw_param_override #(fifo_api #(T)::params_t)::edit(this, "**", d);
//
// Overrides from ancestors apply from the nearest ancestor to the farthest,
// so the outermost has the last word; global overrides apply after them.
// Within one registering component, a later registration wins.
//
// :param P: the params type of the components it applies to
class fw_param_override #(type P = int);

    // Registers an override that replaces the whole value.
    //
    // :param scope: the registering component, or null for a global override
    // :param glob: the target paths
    // :param value: the new value
    extern static function void set(fw_component scope, string glob, P value);

    // Registers an override that modifies the value with ``e``.
    //
    // :param scope: the registering component, or null for a global override
    // :param glob: the target paths
    // :param e: the edit
    extern static function void edit(fw_component scope, string glob, fw_param_edit #(P) e);

endclass
