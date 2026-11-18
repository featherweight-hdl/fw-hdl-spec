// The zero-latency ready/valid initiator transactor (protocol-kit prep §6,
// core-layer2 §5.2). A call drives the pins in the cycle it is made and
// returns at the edge where ``valid && ready`` holds; nothing is buffered
// and no cycle is added. A back-to-back call keeps ``valid`` high::
//
//     fw_rv_initiator #(bit [7:0]) x;
//     ...
//     x.pins.connect(dut_in);          // in connect()
//     ...
//     x.put(8'h5a);                    // in a run() task
//
// ``put`` hands ``d`` to the transactor's own ``run()`` in zero time, so
// the pins are driven from the transactor's clock domain whoever calls it.
//
// :param T: the payload type
class fw_rv_initiator #(type T = bit) extends fw_component
        implements fw_put_if #(T), fw_run_if;
    typedef fw_rv_initiator #(T) this_t;
    `fw_xtor_param_utils(fw_rv_initiator, fw_rv_proto #(T))

    // The method side: the transactor implements ``put``.
    fw_export #(fw_put_if #(T)) t;

    // The pin side.
    fw_bundle #(fw_rv_if #(T)) pins;

    // Creates ``t`` and ``pins``.
    virtual function void build();
        t    = fw_export #(fw_put_if #(T))::create("t", this);
        pins = fw_bundle #(fw_rv_if #(T))::create("pins", this);
    endfunction

    mailbox #(T)   req = new(1);
    mailbox #(bit) ack = new(1);

    // Offers ``d`` and returns at the edge where it is accepted.
    virtual task put(input T d);
        bit b;
        req.put(d);
        ack.get(b);
    endtask

    // Drives each offered item until the handshake.
    virtual task run();
        T d;
        forever begin
            req.get(d);
            pins.valid.write(1);
            pins.data.write(d);
            do fw_clock_domain::tick(this);
            while (!pins.ready.read());
            pins.valid.write(0);
            ack.put(1);
        end
    endtask
endclass

// The ready/valid target transactor (protocol-kit prep §6, Inbound): each
// beat taken at the pins is passed on as a ``put`` call through ``p``.
// ``ready`` is high while the transactor is idle, so a callee that returns
// at once takes one beat per cycle; while the callee blocks, ``ready`` is
// low and the initiator stalls. Nothing is buffered::
//
//     fw_rv_target #(bit [7:0]) x;
//     ...
//     x.pins.connect(dut_out);         // in connect()
//     x.p.connect(sink.e);
//
// :param T: the payload type
class fw_rv_target #(type T = bit) extends fw_component implements fw_run_if;
    typedef fw_rv_target #(T) this_t;
    `fw_xtor_param_utils(fw_rv_target, fw_rv_proto #(T))

    // The method side: where each beat goes.
    fw_port #(fw_put_if #(T)) p;

    // The pin side.
    fw_mirror #(fw_rv_if #(T)) pins;

    // Creates ``p`` and ``pins``.
    virtual function void build();
        p    = fw_port #(fw_put_if #(T))::create("p", this);
        pins = fw_mirror #(fw_rv_if #(T))::create("pins", this);
    endfunction

    // Takes each beat at the handshake edge and puts it; ``ready`` is low
    // while the put blocks.
    virtual task run();
        fw_put_if #(T) i = p.get_if();
        T d;
        pins.ready.write(1);
        forever begin
            do fw_clock_domain::tick(this);
            while (!(pins.valid.read() && pins.ready.read()));
            d = pins.data.read();
            pins.ready.write(0);
            i.put(d);
            pins.ready.write(1);
        end
    endtask
endclass

// The pin core of :sv:class:`fw_rv_monitor`: per cycle, ``fire`` is the
// handshake (``valid && ready``) and ``first`` the first cycle of a
// transfer (``valid`` with no stalled beat before it). It lowers to RTL;
// the monitor's ``run()`` reads it at each edge.
//
// :param T: the payload type
class fw_rv_mon_core #(type T = bit) extends fw_component implements fw_step_if;
    typedef fw_rv_mon_core #(T) this_t;
    `fw_component_param_utils(fw_rv_mon_core)

    // The tapped link.
    fw_monitor #(fw_rv_if #(T)) p;

    // The handshake this cycle.
    fw_output #(bit) fire;

    // The first cycle of a transfer.
    fw_output #(bit) first;

    // A beat was offered and stalled last cycle.
    bit held;

    // Creates ``p``, ``fire`` and ``first``.
    virtual function void build();
        p     = fw_monitor #(fw_rv_if #(T))::create("p", this);
        fire  = fw_output #(bit)::create("fire", this);
        first = fw_output #(bit)::create("first", this);
    endfunction

    `fw_comb(flags)
    // Computes ``fire`` and ``first``.
    function void flags();
        fire.write(p.valid.read() && p.ready.read());
        first.write(p.valid.read() && !held);
    endfunction

    // Records a stalled beat.
    virtual function void step();
        held = p.valid.read() && !p.ready.read();
    endfunction
endclass

// What an :sv:class:`fw_rv_monitor` tells its listeners: the ``put`` call
// of :sv:class:`fw_rv_proto`'s API, ``put_pre`` at the first cycle of a
// transfer and ``put_post`` at the handshake, as the kit-generated
// ``fw_put_if_listener`` would (that lives in std's generated package, not
// visible here). A class, not an interface class: the kit would take an
// interface class here for an API and derive collateral for it. A user
// extends it and overrides what it needs.
//
// :param T: the payload type
virtual class fw_rv_mon_listener #(type T = bit);
    // The first cycle of a transfer of ``t``.
    virtual function void put_pre(input T t);
    endfunction

    // The handshake of ``t``.
    virtual function void put_post(input T t);
    endfunction
endclass

// The ready/valid monitor (protocol-kit prep §6). At each edge it calls
// ``pre`` for the first cycle of a transfer (``valid`` with no transfer
// pending) and ``post`` for the handshake (``valid && ready``); both for a
// transfer accepted in its first cycle. It never buffers and never drops a
// beat. A user extends it and overrides the hooks, or attaches listeners,
// which see the same calls as ``put_pre``/``put_post``::
//
//     m.p.connect(x.pins);             // tap a link
//     m.add_listener(l);
//
// It is the converter for a monitor tap of :sv:class:`fw_rv_proto`.
//
// :param T: the payload type
class fw_rv_monitor #(type T = bit) extends fw_component implements fw_run_if;
    typedef fw_rv_monitor #(T) this_t;
    `fw_xtor_param_utils(fw_rv_monitor, fw_rv_proto #(T))

    // The tapped link.
    fw_monitor #(fw_rv_if #(T)) p;

    // The pin core.
    fw_rv_mon_core #(T) c;

    // Creates ``p`` and ``c``.
    virtual function void build();
        p = fw_monitor #(fw_rv_if #(T))::create("p", this);
        c = fw_rv_mon_core #(T)::create("c", this);
    endfunction

    // Taps ``p`` with the core.
    virtual function void connect();
        c.p.connect(p);
    endfunction

    // Called for the first cycle of a transfer.
    virtual function void pre(T d);
    endfunction

    // Called for the handshake.
    virtual function void post(T d);
    endfunction

    // The attached listeners.
    fw_rv_mon_listener #(T) m_listeners[$];

    // Attaches ``l``.
    virtual function void add_listener(input fw_rv_mon_listener #(T) l);
        m_listeners.push_back(l);
    endfunction

    // Detaches ``l``.
    virtual function void remove_listener(input fw_rv_mon_listener #(T) l);
        foreach (m_listeners[i]) begin
            if (m_listeners[i] == l) begin
                m_listeners.delete(i);
                return;
            end
        end
    endfunction

    // Samples the link at each edge of its clock domain; the listeners are
    // called beside the hooks, so an override need not call ``super``.
    virtual task run();
        T d;
        forever begin
            fw_clock_domain::tick(this);
            d = p.data.read();
            if (c.first.read()) begin
                pre(d);
                foreach (m_listeners[i]) m_listeners[i].put_pre(d);
            end
            if (c.fire.read()) begin
                post(d);
                foreach (m_listeners[i]) m_listeners[i].put_post(d);
            end
        end
    endtask
endclass
