// A listener for configuration changes: a sink calls ``changed`` after
// each push, with the new value (``add_listener`` on any sink). A VIP uses
// it to check, once per change, that it supports a configuration; a
// channel, to flag a mismatch at the register write that causes it.
//
// :param T: the configuration struct
interface class fw_cfg_listener_if #(type T = int);

    // Called after a push.
    //
    // :param v: the new value
    pure virtual function void changed(T v);

endclass
