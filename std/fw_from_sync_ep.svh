// The outside of a lowered :sv:class:`fw_from_sync` (semantics/processes.md,
// "Lowering"): the process side of the crossing, on the ready/valid ports a
// static front end gives the crossing's owner (``<x>_valid``, ``<x>_data``
// in; ``<x>_ready``, ``<x>_wait`` out). Its own ``fw_from_sync`` of depth
// ``DEPTH`` is the crossing's queue, so a mixed simulation with the owner
// lowered keeps the class model's timing::
//
//     fw_from_sync_ep #(rsp_t) re;     // dut.rsps_* through fw_pin_bridge
//     ...
//     re.get(rsp);                     // in task code, as rsps.get(rsp)
//
// ``ready`` is the queue's ``ready()``: room, whether or not a ``get``
// waits, so an item given while none waits is queued, as in the class
// model. ``waiting`` is its ``waiting()``, for ``<x>_wait``.
// :sv:class:`fw_rv_get_ep` is ready only while a ``get`` waits, which is
// the outside of a crossing whose owner gives only when ``waiting()``.
//
// :param T: the item type
// :param DEPTH: the depth of the lowered crossing
class fw_from_sync_ep #(type T = bit, int DEPTH = 1) extends fw_component
        implements fw_get_if #(T), fw_comb_if, fw_step_if;
    typedef fw_from_sync_ep #(T, DEPTH) this_t;
    `fw_component_param_utils(fw_from_sync_ep)

    // The crossing's ports, in the target role: valid and data from the
    // owner, ready to it.
    fw_mirror #(fw_rv_if #(T)) pins;

    // To the owner's ``<x>_wait``: a ``get`` waits with nothing queued.
    fw_output #(bit) waiting;

    // The method side: the endpoint implements ``get``.
    fw_export #(fw_get_if #(T)) t;

    // The crossing's queue.
    fw_from_sync #(T) q;

    // Creates ``pins``, ``waiting``, ``t`` and ``q``.
    virtual function void build();
        pins    = fw_mirror #(fw_rv_if #(T))::create("pins", this);
        waiting = fw_output #(bit)::create("waiting", this);
        t       = fw_export #(fw_get_if #(T))::create("t", this);
        q       = fw_from_sync #(T)::create("q", this, DEPTH);
    endfunction

    // Returns the next item, as the crossing's ``get``.
    virtual task get(output T t);
        q.get(t);
    endtask

    // Returns 1 and the next item if one is queued, as ``try_get``.
    virtual function bit try_get(output T t);
        return q.try_get(t);
    endfunction

    // Ready on room; waiting while a ``get`` waits.
    virtual function void comb();
        pins.ready.write(q.ready());
        waiting.write(q.waiting());
    endfunction

    // Queues the item at the handshake.
    virtual function void step();
        if (pins.valid.read() && pins.ready.read()) void'(q.give(pins.data.read()));
    endfunction
endclass
