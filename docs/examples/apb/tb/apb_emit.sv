// What check.py lowers to RTL: the target and the initiator, each with its
// pins connected up to a bundle of the top (the module's APB pins: s in, m
// out) and its task-sync crossings lowered to ready/valid ports of the
// module (xi_reqs_*, xt_rsps_*, ...). The target's port is bound to the
// initiator's export, as a repeater would be; the target's run() only hands
// off, so it is left out of the RTL with the initiator's API task.
`include "fw_hdl_macros.svh"

package apb_emit_pkg;
    import fw_hdl_pkg::*;
    import apb_pkg::*;

    class top extends fw_component;
        `fw_component_utils(top)
        fw_clock_domain          clk;
        fw_reset_domain          rst;
        fw_mirror #(apb_bundle)  s;
        fw_bundle #(apb_bundle)  m;
        apb_target               xt;
        apb_initiator            xi;
        virtual function void build();
            clk = fw_clock_domain::create("clk", this, fw_clock_kind::root(10ns));
            rst = fw_reset_domain::create("rst", this,
                                          fw_reset_kind::root(fw_reset_kind::SYNC, clk));
            fw_clock_domain::set(this, clk);
            fw_reset_domain::set(this, rst);
            s  = fw_mirror #(apb_bundle)::create("s", this);
            m  = fw_bundle #(apb_bundle)::create("m", this);
            xt = apb_target::create("xt", this);
            xi = apb_initiator::create("xi", this);
        endfunction
        virtual function void connect();
            xt.pins.connect_up(s);
            xi.pins.connect_up(m);
            xt.p.connect(xi.t);
        endfunction
    endclass
endpackage
