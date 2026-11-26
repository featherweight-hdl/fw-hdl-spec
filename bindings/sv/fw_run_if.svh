// A component that implements it has a behavioral process: ``run()``
// starts once, after elaboration, and waits through the domain operations
// (:sv:func:`fw_domain::tick`, :sv:func:`fw_domain::wait_reset_done`) and
// :sv:class:`fw_time`. It runs after an edge's update, never inside one.
// A signal it reads or writes is a crossing port: a read at an edge returns
// the value from before the edge, and a write lands just after it, with
// register timing (semantics/processes.md, Crossings). It is
// simulation-only: fe-sv rejects a component with ``run()`` in what it
// emits (``FW-E-EMIT-RUN``)::
//
//     class rv_src extends fw_component implements fw_run_if;
//         ...
//         virtual task run();
//             fw_reset_domain::wait_reset_done(this);
//             forever begin
//                 fw_clock_domain::tick(this);
//                 ...
//             end
//         endtask
//     endclass
interface class fw_run_if;

    // The behavioral process. A task: it may wait.
    pure virtual task run();

endclass
