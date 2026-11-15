// A constructor factory: creates some realization of component type ``B``.
//
// A params struct carries one when a component's implementation is chosen
// at build time. Get one from :sv:func:`fw_ctor_of::get`; the field's
// default in ``mk_params`` is null, and the component's init function
// (:sv:macro:`fw_component_params_init`) supplies the default realization::
//
//     fw_ctor #(fifo_api #(T)) fifo_h;                     // a params_t field
//     p.fifo_h = fw_ctor_of #(fifo_api #(T), rv_fifo #(T))::get();
//     u = params.fifo_h.create("u", this, p);
//
// Using a constructor factory that is still null is an error
// (``FW-E-PARAM-NULL``).
//
// :param B: the component type it creates; a realization is any subclass
interface class fw_ctor #(type B = fw_component);

    // Creates a realization of ``B``, as its ``create`` would.
    //
    // :param name: the instance name
    // :param parent: the parent component
    // :param p: the creator's params value
    // :returns: the new component
    pure virtual function B create(string name, fw_component parent, B::params_t p);

endclass
