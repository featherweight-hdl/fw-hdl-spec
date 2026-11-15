// Header check: a module pin that nothing maps (FW-E-EXT-PIN, on the
// extern), and a port whose default pin the module lacks (FW-E-EXT-PORT, on
// the port). Needs the module header.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    class ext extends fw_component implements fw_extern_if;
        `fw_extern_utils(ext, "hdr_mod")
        fw_input  #(bit)       clk, extra;
        fw_input  #(bit [7:0]) d;
        fw_output #(bit)       q;
        virtual function void build();
            clk   = fw_input  #(bit)::create("clk", this);
            d     = fw_input  #(bit [7:0])::create("d", this);
            q     = fw_output #(bit)::create("q", this);
            extra = fw_input  #(bit)::create("extra", this);
        endfunction
        virtual function void extern_map(fw_extern_map m);
            // all default rule; pin en is never mapped
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
            e.extra.tie(0);
        endfunction
    endclass

endpackage
