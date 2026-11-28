// Recorder: how a process scenario's task code shows a value in the trace
// (conformance/README.md). Task code doesn't write signals; it puts the
// value to the recorder's fw_to_sync, and the recorder's step() takes one
// item per edge and writes it to its output o:
//
//     test_rec #(time) t;
//     ...
//     t = test_rec #(time)::create("t", this);   // in build()
//     ...
//     t.put(fw_time::now());                     // in task code
//
// A value put at edge k (or between edges k - 1 and k) is taken by step()
// at edge k + 1 (or k) and so shows in row k + 2 (or k + 1): one edge later
// than a task write of o would have. o holds the last value taken. The
// crossing has depth 4, so put() returns at once unless 4 items wait; puts
// made at one edge show in successive rows. The recorder is in its parent's
// domains; it has no reset branch, and its crossing is emptied while the
// reset is asserted (X8), so a scenario records only after the reset's
// last asserted edge (edge 2 of test_proc_top).
//
// :param T: the recorded value's type
class test_rec #(type T = bit [7:0]) extends fw_component implements fw_step_if;
    typedef test_rec #(T) this_t;
    `fw_component_param_utils(test_rec)
    fw_to_sync #(T) in;
    fw_output #(T)  o;
    virtual function void build();
        in = fw_to_sync #(T)::create("in", this, 4);
        o  = fw_output #(T)::create("o", this);
    endfunction
    // Records v.
    virtual task put(input T v);
        in.put(v);
    endtask
    virtual function void step();
        T v;
        if (in.take(v))
            o.write(v);
    endfunction
endclass
