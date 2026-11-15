// The module that scenario extern_params wraps.
`include "prm_types.svh"

module prm_mod import prm_pkg::*; #(
    parameter int          OFS    = 0,
    parameter logic [39:0] K      = '0,
    parameter string       NAME   = "x",
    parameter mode_e       MODE   = MODE_SLOW,
    parameter cfg_t        CFG    = '0,
    parameter type         data_t = logic,
    parameter type         cfg_tt = logic
) (
    input data_t d
);
endmodule
