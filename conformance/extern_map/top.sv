// An extern pin map: module parameters (one from params), a prefix rule with
// a rename, an explicit pin that replaces a rule's choice, an explicit pin,
// ties, opens, and the default rule for the rest.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    class ext extends fw_component implements fw_extern_if;
        typedef struct { int depth; } params_t;
        static function params_t mk_params(int depth = 2);
            params_t p;
            p.depth = depth;
            return p;
        endfunction
        `fw_component_params
        `fw_extern_utils(ext, "ext_mod")

        fw_input  #(bit)                   clk, rst_n;
        fw_mirror #(fw_rv_if #(bit [7:0])) in;
        fw_bundle #(fw_rv_if #(bit [7:0])) out;
        fw_input  #(bit [3:0])             cfg;
        fw_output #(bit)                   stat;

        virtual function void build();
            clk   = fw_input  #(bit)::create("clk", this);
            rst_n = fw_input  #(bit)::create("rst_n", this);
            in    = fw_mirror #(fw_rv_if #(bit [7:0]))::create("in", this);
            out   = fw_bundle #(fw_rv_if #(bit [7:0]))::create("out", this);
            cfg   = fw_input  #(bit [3:0])::create("cfg", this);
            stat  = fw_output #(bit)::create("stat", this);
        endfunction

        virtual function void extern_map(fw_extern_map m);
            m.param("W", fw_value #(int)::of(8));
            m.param("D", fw_value #(int)::of(params.depth));
            void'(m.prefix(in, "i_").rename("valid", "vld"));
            m.pin("i_dat", in.data);        // replaces the rule's i_data
            void'(m.prefix(out, "o_").rename("valid", "vld").rename("ready", "rdy"));
            m.pin("RST_N", rst_n);
            m.tie("TEST", 0);
            m.tie("MODE", 'h2a);
            m.open("DBG");
            m.open("ERR");
            // clk, cfg, stat: default rule
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_input  #(bit)                   clk, rst_n;
        fw_mirror #(fw_rv_if #(bit [7:0])) in;
        fw_bundle #(fw_rv_if #(bit [7:0])) out;
        ext                                e;
        virtual function void build();
            clk   = fw_input  #(bit)::create("clk", this);
            rst_n = fw_input  #(bit)::create("rst_n", this);
            in    = fw_mirror #(fw_rv_if #(bit [7:0]))::create("in", this);
            out   = fw_bundle #(fw_rv_if #(bit [7:0]))::create("out", this);
            e     = ext::create("e", this, ext::mk_params(.depth(4)));
        endfunction
        virtual function void connect();
            e.clk.connect(clk);
            e.rst_n.connect(rst_n);
            e.in.connect_up(in);
            e.out.connect_up(out);
            e.cfg.tie(3);
        endfunction
    endclass

endpackage
