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
// ``put`` hands ``d`` to the sync code through a :sv:class:`fw_to_sync`
// (semantics/processes.md, "Task-sync crossings"). ``comb()`` drives
// ``valid`` and ``data`` from it, so the item is on the pins from the edge
// after the call; ``step()`` takes it at the handshake, and ``put``
// returns at that edge. There is no thread.
//
// :param T: the payload type
class fw_rv_initiator #(type T = bit) extends fw_xtor_initiator #(fw_rv_if #(T))
        implements fw_put_if #(T), fw_comb_if, fw_step_if;
    typedef fw_rv_initiator #(T) this_t;
    `fw_xtor_param_utils(fw_rv_initiator)

    // The item being offered.
    fw_to_sync #(T) req;

    // Creates ``pins`` and ``t`` (the base: an export of ``put``), and
    // ``req``.
    virtual function void build();
        super.build();
        req = fw_to_sync #(T)::create("req", this);
    endfunction

    // Offers ``d`` and returns at the edge where it is accepted.
    virtual task put(input T d);
        req.put(d);
    endtask

    // Offers the waiting item, if any.
    virtual function void comb();
        pins.valid.write(req.valid());
        pins.data.write(req.peek());
    endfunction

    // Takes the item at the handshake.
    virtual function void step();
        T d;
        if (pins.valid.read() && pins.ready.read()) void'(req.take(d));
    endfunction
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
// The pin timing is sync code: ``comb()`` raises ``ready`` while ``run()``
// waits for a beat (:sv:func:`fw_from_sync::waiting`), and ``step()``
// gives the beat at the handshake. ``run()`` only makes the call.
//
// :param T: the payload type
class fw_rv_target #(type T = bit) extends fw_xtor_target #(fw_rv_if #(T))
        implements fw_run_if, fw_comb_if, fw_step_if;
    typedef fw_rv_target #(T) this_t;
    `fw_xtor_param_utils(fw_rv_target)

    // The beats taken, for ``run()``.
    fw_from_sync #(T) beats;

    // Creates ``pins`` and ``p`` (the base: a port of ``put``), and
    // ``beats``.
    virtual function void build();
        super.build();
        beats = fw_from_sync #(T)::create("beats", this);
    endfunction

    // Puts each beat.
    virtual task run();
        fw_put_if #(T) i = p.get_if();
        T d;
        forever begin
            beats.get(d);
            i.put(d);
        end
    endtask

    // Ready while ``run()`` waits for a beat.
    virtual function void comb();
        pins.ready.write(beats.waiting());
    endfunction

    // Takes the beat at the handshake.
    virtual function void step();
        if (pins.valid.read() && pins.ready.read()) void'(beats.give(pins.data.read()));
    endfunction
endclass

// The ready/valid get endpoint (sync-task-domains.md §5.1): the receiving
// counterpart of :sv:class:`fw_rv_initiator`. ``get`` raises ``ready`` in
// the cycle it is called and returns the beat at the edge where ``valid &&
// ready`` holds. ``ready`` is low while no ``get`` is pending, so nothing
// is taken early and nothing is buffered; a back-to-back ``get`` keeps it
// high::
//
//     fw_rv_get_ep #(bit [7:0]) x;
//     ...
//     x.pins.connect(dut_out);         // in connect()
//     ...
//     x.get(d);                        // in a run() task
//
// Unlike :sv:class:`fw_rv_target`, which pushes each beat to a ``put``
// callee, the caller pulls. It isn't a converter of
// :sv:class:`fw_rv_proto` (whose API is ``put``), so it registers as a
// component. ``get`` waits on a :sv:class:`fw_from_sync`; ``comb()``
// raises ``ready`` while it waits, and ``step()`` gives the beat at the
// handshake. There is no thread.
//
// :param T: the payload type
class fw_rv_get_ep #(type T = bit) extends fw_component
        implements fw_get_if #(T), fw_comb_if, fw_step_if;
    typedef fw_rv_get_ep #(T) this_t;
    `fw_component_param_utils(fw_rv_get_ep)

    // The pin side, in the target role.
    fw_mirror #(fw_rv_if #(T)) pins;

    // The method side: the endpoint implements ``get``.
    fw_export #(fw_get_if #(T)) t;

    // The beat being returned.
    fw_from_sync #(T) rsp;

    // Creates ``pins``, ``t`` and ``rsp``.
    virtual function void build();
        pins = fw_mirror #(fw_rv_if #(T))::create("pins", this);
        t    = fw_export #(fw_get_if #(T))::create("t", this);
        rsp  = fw_from_sync #(T)::create("rsp", this);
    endfunction

    // Returns the next beat, at the edge where it is taken.
    virtual task get(output T t);
        rsp.get(t);
    endtask

    // Ready while a ``get`` waits.
    virtual function void comb();
        pins.ready.write(rsp.waiting());
    endfunction

    // Takes the beat at the handshake.
    virtual function void step();
        if (pins.valid.read() && pins.ready.read()) void'(rsp.give(pins.data.read()));
    endfunction
endclass

// The pin core of :sv:class:`fw_rv_monitor`: per cycle, ``fire`` is the
// handshake (``valid && ready``) and ``first`` the first cycle of a
// transfer (``valid`` with no stalled beat before it). It lowers to RTL;
// the monitor's ``step()`` reads it at each edge.
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
//     m.pins.connect(x.pins);          // tap a link
//     m.add_listener(l);
//
// It is the converter for a monitor tap of :sv:class:`fw_rv_proto`.
//
// :param T: the payload type
class fw_rv_monitor #(type T = bit) extends fw_xtor_monitor #(fw_rv_if #(T))
        implements fw_step_if;
    typedef fw_rv_monitor #(T) this_t;
    `fw_xtor_param_utils(fw_rv_monitor)

    // The pin core.
    fw_rv_mon_core #(T) c;

    // Creates ``pins`` (the base, the tapped link) and ``c``.
    virtual function void build();
        super.build();
        c = fw_rv_mon_core #(T)::create("c", this);
    endfunction

    // Taps ``pins`` with the core.
    virtual function void connect();
        c.p.connect(pins);
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

    // At each edge of its clock domain, reports the cycle before it; the
    // listeners are called beside the hooks, so an override need not call
    // ``super``.
    virtual function void step();
        T d = pins.data.read();
        if (c.first.read()) begin
            pre(d);
            foreach (m_listeners[i]) m_listeners[i].put_pre(d);
        end
        if (c.fire.read()) begin
            post(d);
            foreach (m_listeners[i]) m_listeners[i].put_post(d);
        end
    endfunction
endclass
