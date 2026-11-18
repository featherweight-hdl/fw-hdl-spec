// A component that implements it has a clocked process: ``step()`` runs
// at each active edge of one clock domain, after the edge's ``comb()``
// settle. Elaboration finds it; there is no registration call. Signals and
// fields it writes are registers: other processes see the new values after
// the edge. Its clock domain follows from what it writes: the domain of the
// interfaces whose signals it writes, else the component's. Writing signals
// of two clock domains is ``FW-E-STEP-DOMAINS``; split the block with
// :sv:macro:`fw_step`. fe-sv emits it as an ``always_ff``::
//
//     class counter extends fw_component implements fw_step_if;
//         `fw_component_utils(counter)
//         fw_output #(bit [7:0]) count;
//
//         virtual function void build();
//             count = fw_output #(bit [7:0])::create("count", this);
//         endfunction
//
//         virtual function void step();
//             count.write(count.read() + 1);
//         endfunction
//     endclass
interface class fw_step_if;

    // The clocked process. A function: it cannot wait.
    pure virtual function void step();

endclass
