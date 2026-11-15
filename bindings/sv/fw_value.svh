// A module parameter value of type ``T``: an integral value, a string, an
// enum, a packed struct::
//
//     m.param("WIDTH", fw_value #(int)::of($bits(T)));
//     m.param("NAME",  fw_value #(string)::of("u0_check"));
//     m.param("MODE",  fw_value #(mode_e)::of(MODE_FAST));
class fw_value #(type T = int) extends fw_param_arg;

    typedef fw_value #(T) this_t;

    // Makes a value.
    //
    // :param value: the value
    // :returns: it, to pass to :sv:func:`fw_extern_map::param`
    extern static function this_t of(T value);

endclass
