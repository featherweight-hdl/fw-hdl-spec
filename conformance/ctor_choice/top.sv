// Constructor factories: the init_params default, a creator's choice, and an
// override's choice. A handle is written as the type it creates.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    // The abstract component: params only. Realizations extend it.
    virtual class api extends fw_component;
        typedef struct { int depth; } params_t;
        static function params_t mk_params(int depth = 2);
            params_t p;
            p.depth = depth;
            return p;
        endfunction
        `fw_component_params
    endclass

    class impl_a extends api;
        `fw_component_utils(impl_a)
    endclass

    class impl_b extends api;
        `fw_component_utils(impl_b)
    endclass

    class holder extends fw_component;
        typedef struct { fw_ctor #(api) h; int depth; } params_t;
        static function params_t mk_params(fw_ctor #(api) h = null, int depth = 2);
            params_t p;
            p.h = h; p.depth = depth;
            return p;
        endfunction
        `fw_component_params_init(init_params)
        `fw_component_utils(holder)

        static function void init_params(ref params_t p);
            if (p.h == null) p.h = fw_ctor_of #(api, impl_a)::get();
        endfunction

        api u;
        virtual function void build();
            u = params.h.create("u", this, api::mk_params(.depth(params.depth)));
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        holder h0, h1, h2;
        virtual function void build();
            fw_param_override #(holder::params_t)::set(this, "h2",
                holder::mk_params(.h(fw_ctor_of #(api, impl_b)::get())));
            h0 = holder::create("h0", this);
            h1 = holder::create("h1", this,
                holder::mk_params(.h(fw_ctor_of #(api, impl_b)::get()), .depth(3)));
            h2 = holder::create("h2", this);
        endfunction
    endclass

endpackage
