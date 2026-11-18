// One inbound channel of a scripted endpoint: a queue that the endpoint's
// put fills and a test drains with get. ``stall`` makes put block (at pin
// level, the receiver holding READY low), which is how a test holds one
// channel while checking that the others still flow.
//
// :param T: the item type
class fw_inbox #(type T = int) implements fw_put_if #(T), fw_get_if #(T);
    T            q[$];
    bit          stall;
    int unsigned n_recv;

    // Queues ``t``; blocks while ``stall`` is set.
    virtual task put(input T t);
        wait (!stall);
        q.push_back(t);
        n_recv++;
    endtask

    // Returns the oldest queued item; blocks while the queue is empty.
    virtual task get(output T t);
        wait (q.size() > 0);
        t = q.pop_front();
    endtask

    function int size();
        return q.size();
    endfunction

    function void clear();
        q.delete();
        stall  = 0;
        n_recv = 0;
    endfunction
endclass
