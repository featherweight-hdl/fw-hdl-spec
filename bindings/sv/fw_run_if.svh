// A component that implements it has a behavioral process: ``run()``
// starts once, after elaboration, and waits through the domain operations
// (:sv:func:`fw_domain::tick`, :sv:func:`fw_domain::wait_reset_done`) and
// :sv:class:`fw_time`. Signals it writes are registers, as for
// :sv:class:`fw_step_if`. It is simulation-only: fe-sv rejects a
// component with ``run()`` in what it emits (``FW-E-EMIT-RUN``)::
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
