// An edit override: changes some fields of a params value and keeps the
// rest. Register one with :sv:func:`fw_param_override::edit`.
//
// Not a structural object: create one with ``new()``::
//
//     class deepen extends fw_param_edit #(fifo_api #(bit[7:0])::params_t);
//         virtual function params_t apply(params_t p);
//             p.depth = 2 * p.depth;
//             return p;
//         endfunction
//     endclass
//
// :param P: the params type it edits
virtual class fw_param_edit #(type P = int);

    // ``P``, for subclasses.
    typedef P params_t;

    // Returns the edited value. Edits compose in precedence order: each
    // sees the result of the sources below it.
    //
    // :param p: the value so far
    // :returns: the edited value
    pure virtual function P apply(P p);

endclass
