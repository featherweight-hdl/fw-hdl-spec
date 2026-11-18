// Simulation time, for behavioral models: a ``run()`` task delays a
// delivery by a time with no clock at all. Values follow the compilation
// unit's timescale; multiply by a unit (``10 * 1ns``) to be safe. It is
// simulation-only: fe-sv rejects it in anything it emits
// (``FW-E-EMIT-TIME``).
class fw_time;

    // Returns the current simulation time.
    //
    // :returns: the time
    extern static function time now();

    // Waits for ``d``.
    //
    // :param d: the delay
    extern static task delay(time d);

endclass
