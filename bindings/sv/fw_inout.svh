// An inout port: a signal on the component boundary.
//
// :param T: the value type, as for :sv:class:`fw_signal`
class fw_inout #(type T = bit) extends fw_signal #(T);

    // This class, for out-of-block method bodies.
    typedef fw_inout #(T) this_t;

    // Creates the port.
    //
    // :param name: the port name
    // :param parent: the owning component, or the bundle it is a member of
    // :returns: the new port
    extern static function this_t create(string name, fw_object parent);

endclass
