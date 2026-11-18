// A component that implements it has a combinational process: ``comb()``
// runs in each settle of every clock domain whose signals it reads, until
// no signal changes. Elaboration finds it; there is no registration call.
// Signals it writes are wires: visible to the rest of the settle at once.
// A settle that does not converge is ``FW-E-COMB-LOOP``. More than one
// block in a component: :sv:macro:`fw_comb`. fe-sv emits it as an
// ``always_comb``::
//
//     class mux extends fw_component implements fw_comb_if;
//         ...
//         virtual function void comb();
//             y.write(sel.read() ? b.read() : a.read());
//         endfunction
//     endclass
interface class fw_comb_if;

    // The combinational process. A function: it cannot wait.
    pure virtual function void comb();

endclass
