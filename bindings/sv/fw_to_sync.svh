// A crossing from task code into sync code (semantics/processes.md,
// "Task-sync crossings"). Task code puts items on the **process side**;
// the owning component's ``step()`` takes them on the **sync side**, and
// its ``comb()`` may look at the oldest. A process-side change (an item
// put) re-evaluates the owner's comb blocks at once, so ``comb()`` shows
// it straight away; ``step()`` sees it from the next edge::
//
//     fw_to_sync #(req_t) req;
//     ...
//     req = fw_to_sync #(req_t)::create("req", this);   // in build()
//     ...
//     task access(...);  req.put(r); ...                 // process side
//     function void comb();  pins.valid.write(req.valid()); ...
//     function void step();  if (fire) void'(req.take(r)); ...
//
// :param T: the item type
class fw_to_sync #(type T = bit) extends fw_object;

    typedef fw_to_sync #(T) this_t;

    // Creates a crossing named ``name`` under ``parent``, its owner.
    //
    // :param name: the crossing's name
    // :param parent: the owning component
    // :param depth: how many items it holds (>= 1)
    // :returns: the crossing
    extern static function this_t create(string name, fw_object parent, int depth = 1);

    // Process side. Puts ``t``, waiting while the crossing is full. With
    // ``depth`` 1 it returns at the edge where the sync side takes ``t``;
    // with a larger depth, once ``t`` is queued.
    //
    // :param t: the item
    extern task put(input T t);

    // Process side. Puts ``t`` if there is room.
    //
    // :param t: the item
    // :returns: 1 if ``t`` was put
    extern function bit try_put(input T t);

    // Sync side (``step()`` or ``comb()``). Whether an item is waiting.
    //
    // :returns: 1 if an item is waiting
    extern function bit valid();

    // Sync side (``step()`` or ``comb()``). The oldest item; the type's
    // default when none is waiting.
    //
    // :returns: the oldest item
    extern function T peek();

    // Sync side (``step()`` only). Takes the oldest item not yet taken in
    // this call; the change takes effect in the edge's update, and the
    // ``put`` it releases returns at this edge.
    //
    // :param t: the item taken
    // :returns: 1 if an item was taken
    extern function bit take(output T t);

endclass
