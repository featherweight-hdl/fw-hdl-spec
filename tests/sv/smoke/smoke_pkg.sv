// The worked example of core-layer1.md 4.7, written against fw_hdl_pkg.
`include "fw_hdl_macros.svh"

package smoke_pkg;
    import fw_hdl_pkg::*;

    // The abstract FIFO: ports and params only. Realizations extend it.
    virtual class fifo_api #(type T = bit[7:0]) extends fw_component;
        typedef struct { int depth; } params_t;
        static function params_t mk_params(int depth = 2);
            params_t p;
            p.depth = depth;
            return p;
        endfunction
        `fw_component_params

        fw_input  #(bit)            clk, rst;
        fw_mirror #(fw_rv_if #(T))  in;
        fw_bundle #(fw_rv_if #(T))  out;

        virtual function void build();
            clk = fw_input #(bit)::create("clk", this);
            rst = fw_input #(bit)::create("rst", this);
            in  = fw_mirror #(fw_rv_if #(T))::create("in",  this);
            out = fw_bundle #(fw_rv_if #(T))::create("out", this);
        endfunction
    endclass

    // The RTL realization: wraps fw_rv_fifo. It inherits ports and params.
    class rv_fifo #(type T = bit[7:0]) extends fifo_api #(T) implements fw_extern_if;
        `fw_extern_utils(rv_fifo #(T), "fw_rv_fifo")

        virtual function void extern_map(fw_extern_map m);
            m.param("WIDTH", fw_value #(int)::of($bits(T)));
            m.param("DEPTH", fw_value #(int)::of(params.depth));
            void'(m.prefix(in,  "in_").rename("valid", "vld").rename("ready", "rdy"));
            void'(m.prefix(out, "out_").rename("valid", "vld").rename("ready", "rdy"));
        endfunction
    endclass

    // Wraps fw_valid_check (pins clk, rst, vld, rdy): checks a link's valid
    // and ready. It taps the link with a monitor of the link's own bundle
    // type; the module has no data pin, so p.data is unused. No params of its
    // own; NAME keeps its default.
    class valid_mon #(type T = bit[7:0]) extends fw_component implements fw_extern_if;
        `fw_extern_utils(valid_mon #(T), "fw_valid_check")

        fw_input   #(bit)            clk, rst;
        fw_monitor #(fw_rv_if #(T))  p;

        virtual function void build();
            clk = fw_input   #(bit)::create("clk", this);
            rst = fw_input   #(bit)::create("rst", this);
            p   = fw_monitor #(fw_rv_if #(T))::create("p", this);
        endfunction

        virtual function void extern_map(fw_extern_map m);
            void'(m.prefix(p, "").rename("valid", "vld").rename("ready", "rdy"));
            m.unused(p.data);
            // clk, rst: default rule
        endfunction
    endclass

    class fifo_chain #(type T = bit[7:0]) extends fw_component;
        typedef struct {
            int                      n;
            int                      depth;
            bit                      deep_tail;
            fw_ctor #(fifo_api #(T)) fifo_h;               // null: init_params picks rv_fifo
        } params_t;
        static function params_t mk_params(int n = 2, int depth = 2, bit deep_tail = 0,
                                           fw_ctor #(fifo_api #(T)) fifo_h = null);
            params_t p;
            p.n = n; p.depth = depth; p.deep_tail = deep_tail; p.fifo_h = fifo_h;
            return p;
        endfunction
        `fw_component_params_init(init_params)
        `fw_component_utils(fifo_chain #(T))

        static function void init_params(ref params_t p);
            if (p.fifo_h == null) p.fifo_h = fw_ctor_of #(fifo_api #(T), rv_fifo #(T))::get();
        endfunction

        fw_input  #(bit)            clk, rst;
        fw_mirror #(fw_rv_if #(T))  in;
        fw_bundle #(fw_rv_if #(T))  out;
        fifo_api  #(T)              u[];
        valid_mon #(T)              mon;

        virtual function void build();
            clk = fw_input #(bit)::create("clk", this);
            rst = fw_input #(bit)::create("rst", this);
            in  = fw_mirror #(fw_rv_if #(T))::create("in",  this);
            out = fw_bundle #(fw_rv_if #(T))::create("out", this);
            u = new[params.n];
            foreach (u[i])
                u[i] = params.fifo_h.create($sformatf("u[%0d]", i), this,
                    fifo_api #(T)::mk_params(.depth(
                        (params.deep_tail && i == params.n - 1) ? 2 * params.depth
                                                                : params.depth)));
            mon = valid_mon #(T)::create("mon", this);
        endfunction

        virtual function void connect();
            u[0].in.connect_up(in);
            for (int i = 0; i + 1 < params.n; i++) u[i].out.connect(u[i+1].in);
            u[params.n-1].out.connect_up(out);
            mon.p.connect(u[0].out);
            foreach (u[i]) connect_all('{ '{u[i].clk, clk}, '{u[i].rst, rst} });
            connect_all('{ '{mon.clk, clk}, '{mon.rst, rst} });
        endfunction
    endclass

    class deepen #(type T = bit[7:0]) extends fw_param_edit #(fifo_api #(T)::params_t);
        virtual function params_t apply(params_t p);
            p.depth = 2 * p.depth;
            return p;
        endfunction
    endclass

    // An integrator: overrides one FIFO deep inside the chain, and every
    // FIFO's depth with an edit.
    class soc extends fw_component;
        `fw_component_utils(soc)
        fw_input  #(bit)                   clk, rst;
        fw_bundle #(fw_rv_if #(bit[31:0])) out;
        fifo_chain #(bit[31:0])            chain;

        virtual function void build();
            deepen #(bit[31:0]) d = new();
            clk = fw_input #(bit)::create("clk", this);
            rst = fw_input #(bit)::create("rst", this);
            out = fw_bundle #(fw_rv_if #(bit[31:0]))::create("out", this);
            fw_param_override #(fifo_api #(bit[31:0])::params_t)::set(
                this, "chain.u[0]", fifo_api #(bit[31:0])::mk_params(.depth(16)));
            fw_param_override #(fifo_api #(bit[31:0])::params_t)::edit(this, "**", d);
            chain = fifo_chain #(bit[31:0])::create(
                "chain", this, fifo_chain #(bit[31:0])::mk_params(.n(3), .deep_tail(1)));
        endfunction

        virtual function void connect();
            chain.in.valid.tie(0);
            chain.in.data.tie('hdead_beef);
            chain.clk.connect(clk);
            chain.rst.connect(rst);
            chain.out.connect_up(out);
        endfunction
    endclass

endpackage
