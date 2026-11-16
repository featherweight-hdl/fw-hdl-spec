// FW-E-DOM-UNUSED: a named association the component never reads. A name
// read only in the connect phase is read.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    class dual extends fw_component;
        `fw_component_utils(dual)
        fw_clock_domain wr, late;
        virtual function void build();
            wr = fw_clock_domain::get(this, "wr");
        endfunction
        virtual function void connect();
            late = fw_clock_domain::get(this, "late");
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_clock_domain c0, c1;
        dual            d;
        virtual function void build();
            c0 = fw_clock_domain::create("c0", this);
            c1 = fw_clock_domain::create("c1", this);
            d  = dual::create("d", this);
            fw_clock_domain::set(d, c0, "wr");
            fw_clock_domain::set(d, c1, "rd");
            fw_clock_domain::set(d, c1, "late");
        endfunction
    endclass

endpackage
