// A checker that observes a ready/valid link but has no data pin: the
// monitor's data member is unused, and a second monitor is unused whole.
// Unused ports have no pin, but they are inputs like any other and must
// still be connected (FW-E-IN-OPEN).
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;

    class chk extends fw_component implements fw_extern_if;
        `fw_extern_utils(chk, "chk_mod")

        fw_input   #(bit)                   clk;
        fw_monitor #(fw_rv_if #(bit [7:0])) p;
        fw_monitor #(fw_rv_if #(bit [7:0])) aux;

        virtual function void build();
            clk = fw_input   #(bit)::create("clk", this);
            p   = fw_monitor #(fw_rv_if #(bit [7:0]))::create("p", this);
            aux = fw_monitor #(fw_rv_if #(bit [7:0]))::create("aux", this);
        endfunction

        virtual function void extern_map(fw_extern_map m);
            m.unused(aux);                  // before the rule: order does not matter
            void'(m.prefix(p, "").rename("valid", "vld").rename("ready", "rdy"));
            m.unused(p.data);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_input  #(bit)                   clk;
        fw_mirror #(fw_rv_if #(bit [7:0])) in;
        fw_bundle #(fw_rv_if #(bit [7:0])) out;
        chk                                c;
        virtual function void build();
            clk = fw_input  #(bit)::create("clk", this);
            in  = fw_mirror #(fw_rv_if #(bit [7:0]))::create("in", this);
            out = fw_bundle #(fw_rv_if #(bit [7:0]))::create("out", this);
            c   = chk::create("c", this);
        endfunction
        virtual function void connect();
            connect_all('{ '{in, out} });   // own in to own out, member-wise
            c.clk.connect(clk);
            c.p.connect(in);
            c.aux.connect(in);
        endfunction
    endclass

endpackage
