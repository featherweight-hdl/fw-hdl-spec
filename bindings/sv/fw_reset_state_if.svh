// A component that implements it states the reset values of its
// registers: ``reset_state()`` is called while a reset domain of the
// component is asserted, instead of ``step()``, and writes the registers of
// that domain. fe-sv emits it as the reset branch of the ``always_ff``.
// A component without it handles reset in ``step()`` through
// :sv:func:`fw_domain::in_reset`.
interface class fw_reset_state_if;

    // Writes the reset values. A function: it cannot wait.
    pure virtual function void reset_state();

endclass
