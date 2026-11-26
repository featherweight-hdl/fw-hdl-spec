// A crossing from sync code out to task code (semantics/processes.md,
// "Task-sync crossings"). The owning component's ``step()`` gives items on
// the **sync side**; task code gets them on the **process side**. A
// process-side change (a ``get`` starting to wait, an item got)
// re-evaluates the owner's comb blocks at once, so ``comb()`` can raise a
// ``ready`` only while a ``get`` waits::
//
//     fw_from_sync #(rsp_t) rsp;
//     ...
//     rsp = fw_from_sync #(rsp_t)::create("rsp", this);  // in build()
//     ...
//     task access(...);  ...; rsp.get(p);                // process side
//     function void step();  if (done) void'(rsp.give(p)); ...
//
// :param T: the item type
class fw_from_sync #(type T = bit) extends fw_object;

    typedef fw_from_sync #(T) this_t;

    // Creates a crossing named ``name`` under ``parent``, its owner.
    //
    // :param name: the crossing's name
    // :param parent: the owning component
    // :param depth: how many items it holds (>= 1)
    // :returns: the crossing
    extern static function this_t create(string name, fw_object parent, int depth = 1);

    // Process side. Returns the oldest item, waiting for one. A wait that
    // ends returns at the edge where the sync side gave the item.
    //
    // :param t: the item
    extern task get(output T t);

    // Process side. Gets the oldest item if there is one.
    //
    // :param t: the item
    // :returns: 1 if an item was got
    extern function bit try_get(output T t);

    // Sync side (``step()`` or ``comb()``). Whether there is room for an
    // item.
    //
    // :returns: 1 if ``give`` would succeed
    extern function bit ready();

    // Sync side (``step()`` or ``comb()``). Whether a ``get`` is waiting
    // with no item queued for it: an item given now is taken at this edge,
    // with nothing buffered.
    //
    // :returns: 1 if a ``get`` is waiting
    extern function bit waiting();

    // Sync side (``step()`` only). Gives ``t`` if there is room; the change
    // takes effect in the edge's update, and a waiting ``get`` returns at
    // this edge.
    //
    // :param t: the item
    // :returns: 1 if ``t`` was given
    extern function bit give(input T t);

endclass
