// FW-W-DOM-STYLE: a pin requiring a synchronous reset on an asynchronous
// reset domain. Pins requiring any style, or the domain's own, are fine.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    class ext #(int STYLE = 2) extends fw_component implements fw_extern_if;
        `fw_extern_utils(ext #(STYLE), "ext_mod")
        virtual function void extern_map(fw_extern_map m);
            fw_reset_domain::pin(m, "rst", null,
                fw_reset_kind::active_high(fw_reset_kind::style_e'(STYLE)));
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_input #(bit) rst_i;
        fw_reset_domain rst;
        ext #(1)        e;
        ext #(2)        f;
        ext #(0)        g;
        virtual function void build();
            rst_i = fw_input #(bit)::create("rst_i", this);
            rst   = fw_reset_domain::create("rst", this);
            fw_reset_domain::set(this, rst);
            e = ext #(1)::create("e", this);
            f = ext #(2)::create("f", this);
            g = ext #(0)::create("g", this);
        endfunction
        virtual function void connect();
            rst.drive(rst_i);
        endfunction
    endclass

endpackage
