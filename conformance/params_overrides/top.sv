// Override precedence: creator, then the nearest ancestor's overrides, then
// farther ancestors', then global overrides; within one registering
// component a later registration wins. Set and edit forms; * and ** globs.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    class cfg_c extends fw_component;
        typedef struct { int a; int b; int c; int d; } params_t;
        static function params_t mk_params(int a = 1, int b = 2, int c = 3, int d = 4);
            params_t p;
            p.a = a; p.b = b; p.c = c; p.d = d;
            return p;
        endfunction
        `fw_component_params
        `fw_component_utils(cfg_c)
    endclass

    class inc_c extends fw_param_edit #(cfg_c::params_t);
        virtual function params_t apply(params_t p);
            p.c = p.c + 1;
            return p;
        endfunction
    endclass

    class dbl_b extends fw_param_edit #(cfg_c::params_t);
        virtual function params_t apply(params_t p);
            p.b = 2 * p.b;
            return p;
        endfunction
    endclass

    class set_d7 extends fw_param_edit #(cfg_c::params_t);
        virtual function params_t apply(params_t p);
            p.d = 7;
            return p;
        endfunction
    endclass

    class mid extends fw_component;
        `fw_component_utils(mid)
        cfg_c x, y, z;
        virtual function void build();
            dbl_b e = new();
            fw_param_override #(cfg_c::params_t)::set(this, "x", cfg_c::mk_params(.a(10), .b(10)));
            fw_param_override #(cfg_c::params_t)::edit(this, "*", e);
            x = cfg_c::create("x", this, cfg_c::mk_params(.a(5)));
            y = cfg_c::create("y", this);
            z = cfg_c::create("z", this);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        mid m;
        virtual function void build();
            inc_c  ic = new();
            set_d7 g  = new();
            fw_param_override #(cfg_c::params_t)::set(this, "mid.x", cfg_c::mk_params(.a(20), .b(20), .c(20), .d(20)));
            fw_param_override #(cfg_c::params_t)::set(this, "mid.z", cfg_c::mk_params(.a(30)));
            fw_param_override #(cfg_c::params_t)::set(this, "mid.z", cfg_c::mk_params(.a(31)));
            fw_param_override #(cfg_c::params_t)::edit(this, "mid.*", ic);
            fw_param_override #(cfg_c::params_t)::edit(null, "top.**", g);    // global
            m = mid::create("mid", this);
        endfunction
    endclass

endpackage
