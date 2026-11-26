// A parameterized initiator transactor, used at two widths: one converter
// per protocol specialization.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;
    `include "test_rv_proto.svh"

    class rv_init_xtor #(int W = 8) extends fw_xtor_initiator #(test_rv_bundle #(W))
            implements test_put_if #(logic [W-1:0]);
        typedef rv_init_xtor #(W) this_t;
        `fw_xtor_param_utils(rv_init_xtor)
        virtual task put(logic [W-1:0] t);
        endtask
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_bundle #(test_rv_bundle #(8))  o8;
        fw_bundle #(test_rv_bundle #(16)) o16;
        rv_init_xtor #(8)  x8;
        rv_init_xtor #(16) x16;
        virtual function void build();
            o8  = fw_bundle #(test_rv_bundle #(8))::create("o8", this);
            o16 = fw_bundle #(test_rv_bundle #(16))::create("o16", this);
            x8  = rv_init_xtor #(8)::create("x8", this);
            x16 = rv_init_xtor #(16)::create("x16", this);
        endfunction
        virtual function void connect();
            x8.pins.connect_up(o8);
            x16.pins.connect_up(o16);
        endfunction
    endclass

endpackage
