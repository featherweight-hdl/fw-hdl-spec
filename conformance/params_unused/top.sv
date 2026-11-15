// An override that matches nothing: its glob names a component, but of
// another params type. FW-W-PARAM-UNUSED on the registering component;
// elaboration succeeds.
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

    class other_c extends fw_component;
        typedef struct { int q; } params_t;
        static function params_t mk_params(int q = 0);
            params_t p;
            p.q = q;
            return p;
        endfunction
        `fw_component_params
        `fw_component_utils(other_c)
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        cfg_c x;
        virtual function void build();
            fw_param_override #(other_c::params_t)::set(this, "x", other_c::mk_params(.q(1)));
            x = cfg_c::create("x", this);
        endfunction
    endclass

endpackage
