// The outside of a lowered :sv:class:`fw_to_sync` (semantics/processes.md,
// "Lowering"): the process side of the crossing, on the ready/valid ports a
// static front end gives the crossing's owner (``<x>_valid``, ``<x>_data``
// out to it; ``<x>_ready`` in). Its own ``fw_to_sync`` of depth ``DEPTH``
// is the crossing's queue, so a mixed simulation with the owner lowered
// keeps the class model's timing::
//
//     fw_to_sync_ep #(req_t) ri;       // dut.reqs_* through fw_pin_bridge
//     ...
//     ri.put(req);                     // in task code, as reqs.put(req)
//
// ``valid`` and ``data`` are the queue's ``valid()`` and ``peek()``; the
// head is taken at the handshake. With depth 1 it behaves as
// :sv:class:`fw_rv_initiator`.
//
// :param T: the item type
// :param DEPTH: the depth of the lowered crossing
class fw_to_sync_ep #(type T = bit, int DEPTH = 1) extends fw_component
        implements fw_put_if #(T), fw_comb_if, fw_step_if;
    typedef fw_to_sync_ep #(T, DEPTH) this_t;
    `fw_component_param_utils(fw_to_sync_ep)

    // The crossing's ports, in the initiator role: valid and data to the
    // owner, ready from it.
    fw_bundle #(fw_rv_if #(T)) pins;

    // The method side: the endpoint implements ``put``.
    fw_export #(fw_put_if #(T)) t;

    // The crossing's queue.
    fw_to_sync #(T) q;

    // Creates ``pins``, ``t`` and ``q``.
    virtual function void build();
        pins = fw_bundle #(fw_rv_if #(T))::create("pins", this);
        t    = fw_export #(fw_put_if #(T))::create("t", this);
        q    = fw_to_sync #(T)::create("q", this, DEPTH);
    endfunction

    // Queues ``d``, as the crossing's ``put``.
    virtual task put(input T d);
        q.put(d);
    endtask

    // Queues ``d`` if there is room, as ``try_put``; 1 if queued.
    virtual function bit try_put(input T d);
        return q.try_put(d);
    endfunction

    // Offers the head item.
    virtual function void comb();
        pins.valid.write(q.valid());
        pins.data.write(q.peek());
    endfunction

    // Takes it at the handshake.
    virtual function void step();
        T d;
        if (pins.valid.read() && pins.ready.read()) void'(q.take(d));
    endfunction
endclass
