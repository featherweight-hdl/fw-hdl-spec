// Params from defaults and from the creator, including a value the creator
// computes from its own params. A field's source is the last stage that
// changed it, so a creator value equal to the default has none.
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
        typedef struct { int k; } params_t;
        static function params_t mk_params(int k = 7);
            params_t p;
            p.k = k;
            return p;
        endfunction
        `fw_component_params
        `fw_component_utils(top)
        cfg_c d0, d1, d2, d3;
        virtual function void build();
            d0 = cfg_c::create("d0", this);
            d1 = cfg_c::create("d1", this, cfg_c::mk_params(.b(5)));
            d2 = cfg_c::create("d2", this, cfg_c::mk_params(.a(1), .c(9)));
            d3 = cfg_c::create("d3", this, cfg_c::mk_params(.c(2 * params.k)));
        endfunction
    endclass

endpackage
