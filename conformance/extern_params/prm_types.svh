// Types shared by scenario extern_params and the module it wraps.
`ifndef PRM_TYPES_SVH
`define PRM_TYPES_SVH
package prm_pkg;
    typedef enum logic [1:0] { MODE_SLOW, MODE_FAST, MODE_OFF } mode_e;
    typedef struct packed { logic [3:0] burst; logic wrap; } cfg_t;
endpackage
`endif
