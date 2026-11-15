// The constructor factory for realization ``D`` of ``B``: its
// :sv:func:`fw_ctor_of::create` calls ``D::create``.
//
// :param B: the component type the factory creates
// :param D: the realization; extends ``B``, and so has ``B``'s ``params_t``
class fw_ctor_of #(type B = fw_component, type D = B) implements fw_ctor #(B);

    // ``B``, for out-of-block method bodies.
    typedef B           base_t;

    // The :sv:class:`fw_ctor` of ``B``, for out-of-block method bodies.
    typedef fw_ctor #(B) ctor_t;

    // Returns the constructor factory for ``D``. There is one instance per
    // ``(B, D)``.
    //
    // :returns: the factory, as a :sv:class:`fw_ctor` of ``B``
    extern static function ctor_t get();

    // Creates a ``D`` with ``D::create``.
    //
    // :param name: the instance name
    // :param parent: the parent component
    // :param p: the creator's params value
    // :returns: the new component
    extern virtual function base_t create(string name, fw_component parent, B::params_t p);

endclass
