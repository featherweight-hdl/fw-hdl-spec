// A component that implements it has a behavioral process: ``run()``
// starts when its reset domain's reset deasserts, is killed (with the
// threads it forked) when the reset asserts and starts again at the next
// deassert (semantics/processes.md, R1-R3). It waits through the domain
// operations (:sv:func:`fw_domain::tick`, :sv:func:`fw_domain::wait_assert`) and
// :sv:class:`fw_time`. It runs after an edge's release, never inside one.
// It is task code (semantics/processes.md, "Task code"): it neither reads
// nor writes signals (``FW-E-TASK-SIGNAL``), and reaches sync code through
// task-sync crossings (:sv:class:`fw_to_sync`, :sv:class:`fw_from_sync`),
// component fields and port calls. It is simulation-only: fe-sv rejects a
// component with ``run()`` in what it emits (``FW-E-EMIT-RUN``), unless its
// ``run()`` only hands off::
//
//     class tgt extends fw_component implements fw_run_if;
//         fw_from_sync #(req_t) reqs;   // its step() fills it from the pins
//         fw_to_sync #(rsp_t)   rsps;   // its step() drives the pins from it
//         fw_port #(mem_if)     p;
//         ...
//         virtual task run();
//             forever begin
//                 req_t q;
//                 rsp_t r;
//                 reqs.get(q);
//                 p.get_if().access(q, r);
//                 rsps.put(r);
//             end
//         endtask
//     endclass
interface class fw_run_if;

    // The behavioral process. A task: it may wait.
    pure virtual task run();

endclass
