// A value for one parameter of an extern's module: what
// :sv:func:`fw_extern_map::param` takes. Create one with
// :sv:func:`fw_value::of` (a value of any type) or :sv:func:`fw_type::get`
// (a type, for a ``parameter type``). It carries its type, so a tool can
// write the value as the module expects it (an enum by its label, a type by
// its name) and check it against the module's parameter.
virtual class fw_param_arg;
endclass
