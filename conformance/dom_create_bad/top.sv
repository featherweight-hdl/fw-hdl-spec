// A domain named like a port (FW-E-NAME-DUP) and a domain created in the
// connect phase (FW-E-ELAB-LATE).
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    class top extends fw_component;
        `fw_component_utils(top)
        fw_input #(bit) a;
        fw_clock_domain clk, dup, late;

        virtual function void build();
            a   = fw_input #(bit)::create("a", this);
            clk = fw_clock_domain::create("clk", this);
            dup = fw_clock_domain::create("a", this);
        endfunction

        virtual function void connect();
            late = fw_clock_domain::create("late", this);
        endfunction
    endclass

endpackage
