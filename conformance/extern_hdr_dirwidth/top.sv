// Header check: a port narrower than its pin (FW-E-EXT-WIDTH) and a port
// whose direction disagrees with its pin (FW-E-EXT-DIR), each on the port.
// Needs the module header.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    class ext extends fw_component implements fw_extern_if;
        `fw_extern_utils(ext, "hw_mod")
        fw_input #(bit)       clk;
        fw_input #(bit [3:0]) d;
        fw_input #(bit)       q;
        virtual function void build();
            clk = fw_input #(bit)::create("clk", this);
            d   = fw_input #(bit [3:0])::create("d", this);
            q   = fw_input #(bit)::create("q", this);
        endfunction
        virtual function void extern_map(fw_extern_map m);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        ext e;
        virtual function void build();
            e = ext::create("e", this);
        endfunction
        virtual function void connect();
            e.clk.tie(0);
            e.d.tie(0);
            e.q.tie(0);
        endfunction
    endclass

endpackage
