// A two-way method-level endpoint: it calls ``OUT`` and provides ``IN``.
// Its peer is ``fw_socket #(IN, OUT)``, the mirror image, so there is no
// separate target class; two identical full-duplex devices
// (``fw_socket #(fw_put_if #(T), fw_put_if #(T))``) connect socket to
// socket. ``IN`` is implemented as an export's is: by the parent, or by
// :sv:func:`fw_socket::set_imp`.
//
// Against a protocol, the socket's role is derived from which way the
// protocol's APIs travel: an outbound request (or inbound response) makes
// it an initiator, an outbound response (or inbound request) a target.
//
// :param OUT: the API it calls
// :param IN: the API it provides
class fw_socket #(type OUT = int, type IN = int) extends fw_object;

    typedef fw_socket #(OUT, IN) this_t;

    // Creates a socket named ``name`` under ``parent``. If ``parent``
    // implements ``IN``, it is the implementation, with no further call.
    //
    // :param name: the socket's name
    // :param parent: the owner
    // :returns: the socket
    extern static function this_t create(string name, fw_object parent);

    // Connects this socket to ``peer``, in both directions. A socket
    // binds once (``FW-E-SOCK-MULTI``).
    //
    // :param peer: the peer socket
    extern function void connect(fw_socket #(IN, OUT) peer);

    // Passes this socket up through ``outer``, a socket of the parent.
    //
    // :param outer: the parent's socket
    extern function void connect_up(fw_socket #(OUT, IN) outer);

    // Sets the implementation of ``IN``, when it is not the parent.
    // Overrides the derived one.
    //
    // :param imp: the implementation
    extern function void set_imp(IN imp);

    // The implementation of ``OUT`` that this socket reaches, as
    // :sv:func:`fw_port::get_if`.
    //
    // :returns: the implementation, or null when it resolves to none
    extern function OUT get_if();

endclass
