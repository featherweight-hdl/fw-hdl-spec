// A component writes its params value: FW-E-PARAM-WRITE on the component.
// Static only.
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
        virtual function void build();
            params.depth = 3;     // read-only
        endfunction
    endclass

    class impl_b extends api;
        `fw_component_utils(impl_b)
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        impl_a c;
        virtual function void build();
            c = impl_a::create("c", this);
        endfunction
    endclass

endpackage
