// A module ``parameter type`` value: the type ``T``::
//
//     m.param("data_t", fw_type #(T)::get());
class fw_type #(type T = int) extends fw_param_arg;

    typedef fw_type #(T) this_t;

    // Returns the type, to pass to :sv:func:`fw_extern_map::param`.
    //
    // :returns: an object standing for ``T``
    extern static function this_t get();

endclass
