// An override registered after its target was created: FW-E-PARAM-LATE on
// the target.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    class cfg_c extends fw_component;
        typedef struct { int a; int b; int c; } params_t;
        static function params_t mk_params(int a = 1, int b = 2, int c = 3);
            params_t p;
            p.a = a; p.b = b; p.c = c;
            return p;
        endfunction
        `fw_component_params
        `fw_component_utils(cfg_c)
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        cfg_c x;
        virtual function void build();
            x = cfg_c::create("x", this);
            fw_param_override #(cfg_c::params_t)::set(this, "x", cfg_c::mk_params(.a(9)));
        endfunction
    endclass

endpackage
