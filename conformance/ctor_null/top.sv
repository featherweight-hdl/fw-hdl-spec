// A constructor factory that is still null when used: FW-E-PARAM-NULL on the
// component that used it. Static only: in a simulator the call is a null
// dereference.
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
        typedef struct { fw_ctor #(api) h; } params_t;
        static function params_t mk_params(fw_ctor #(api) h = null);
            params_t p;
            p.h = h;
            return p;
        endfunction
        `fw_component_params
        `fw_component_utils(holder)
        api u;
        virtual function void build();
            u = params.h.create("u", this, api::mk_params());
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        holder h0;
        virtual function void build();
            h0 = holder::create("h0", this);
        endfunction
    endclass

endpackage
