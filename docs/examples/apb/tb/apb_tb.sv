// apb_initiator and apb_target back to back over one apb_bundle, with a
// memory model behind the target. The driver makes N transfers through the
// initiator's export (a write, then a read back; every 5th to ERR_ADDR,
// which the memory answers with slverr), each after a gap of 0-2 edges. The
// memory adds 0-2 wait states. A step-only checker logs the bus at each
// edge, and check() tests each call against the log:
//   - one setup edge (psel, !penable) after the call, then access edges
//     (psel, penable) with the request held, up to the edge it returns at,
//     which is the only one with pready
//   - the response is the memory's, and the memory saw each transfer once
// +mut swaps in an initiator whose comb() skips the setup phase: the checks
// must fail.
`include "fw_hdl_macros.svh"

package apb_tb_pkg;
    import fw_hdl_pkg::*;
    import apb_pkg::*;

    localparam int N = 24;
    localparam bit [15:0] ERR_ADDR = 16'hF000;

    // A call: the edges it was made and returned at, and what went each way.
    typedef struct { int c; int r; apb_req_t q; apb_rsp_t s; } call_t;

    // The bus at one edge.
    typedef struct packed {
        bit psel, penable, pwrite, pready, pslverr;
        bit [15:0] paddr;
        bit [31:0] pwdata, prdata;
    } bus_t;

    // Logs the bus at each edge.
    class chk_c extends fw_component implements fw_step_if;
        `fw_component_utils(chk_c)
        fw_monitor #(apb_bundle) p;
        bus_t log[$];
        virtual function void build();
            p = fw_monitor #(apb_bundle)::create("p", this);
        endfunction
        virtual function void step();
            log.push_back('{psel: p.psel.read(), penable: p.penable.read(),
                            pwrite: p.pwrite.read(), pready: p.pready.read(),
                            pslverr: p.pslverr.read(), paddr: p.paddr.read(),
                            pwdata: p.pwdata.read(), prdata: p.prdata.read()});
        endfunction
        // The edges so far: task code at edge k reads k.
        function int n();
            return log.size();
        endfunction
    endclass

    // The memory: 16 words; ERR_ADDR is an error. Each access takes 0-2
    // wait states: a delay of that many clock periods (10ns), into the
    // middle of a cycle.
    class mem_c extends fw_component implements apb_if;
        `fw_component_utils(mem_c)
        fw_export #(apb_if) t;
        bit [31:0] mem[16];
        int n_acc;
        virtual function void build();
            t = fw_export #(apb_if)::create("t", this);
        endfunction
        virtual task access(output apb_rsp_t rsp, input apb_req_t req);
            int ws = n_acc++ % 3;
            if (ws != 0) fw_time::delay(ws * 10ns + 5ns);
            rsp.slverr = (req.addr == ERR_ADDR);
            if (!rsp.slverr && req.write) mem[req.addr[5:2]] = req.wdata;
            rsp.rdata = rsp.slverr ? '0 : mem[req.addr[5:2]];
        endtask
    endclass

    // The reset: rst_n reads 0 at edges 1 and 2, then 1.
    class rst_gen_c extends fw_component implements fw_step_if;
        `fw_component_utils(rst_gen_c)
        fw_output #(bit) rst_n;
        bit [1:0] n;
        virtual function void build();
            rst_n = fw_output #(bit)::create("rst_n", this);
        endfunction
        virtual function void step();
            if (n != 2) n++;
            rst_n.write(n == 2);
        endfunction
    endclass

    // Makes the N transfers through port p, after the reset.
    class drv_c extends fw_component implements fw_run_if;
        `fw_component_utils(drv_c)
        fw_port #(apb_if) p;
        chk_c  k;
        call_t calls[$];
        virtual function void build();
            p = fw_port #(apb_if)::create("p", this);
        endfunction
        virtual task run();
            apb_if i = p.get_if();
            for (int a = 0; a < N; a++) begin
                call_t c;
                repeat (a % 3) fw_clock_domain::tick(this);
                c.q.addr  = (a % 5 == 4) ? ERR_ADDR : 16'((a / 2) % 16 * 4);
                c.q.write = !(a % 2);
                c.q.wdata = c.q.write ? 32'hA000_0000 + a : '0;
                c.c = k.n();
                i.access(c.s, c.q);
                c.r = k.n();
                calls.push_back(c);
            end
        endtask
    endclass

    // The mutant: no setup phase.
    class mut_init_c extends apb_initiator;
        `fw_component_utils(mut_init_c)
        virtual function void comb();
            super.comb();
            pins.penable.write(reqs.valid() && rsps.ready());
        endfunction
    endclass

    class top_c extends fw_component;
        `fw_component_utils(top_c)
        fw_clock_domain clk;
        fw_reset_domain rst;
        rst_gen_c       rg;
        drv_c           d;
        apb_initiator   xi;
        apb_target      xt;
        mem_c           m;
        chk_c           k;
        virtual function void build();
            clk = fw_clock_domain::create("clk", this, fw_clock_kind::root(10ns));
            rst = fw_reset_domain::create("rst", this,
                                          fw_reset_kind::root(fw_reset_kind::SYNC, clk));
            fw_clock_domain::set(this, clk);
            fw_reset_domain::set(this, rst);
            rg = rst_gen_c::create("rg", this);
            d  = drv_c::create("d", this);
            xi = $test$plusargs("mut") ? mut_init_c::create("xi", this)
                                       : apb_initiator::create("xi", this);
            xt = apb_target::create("xt", this);
            m  = mem_c::create("m", this);
            k  = chk_c::create("k", this);
            d.k = k;
        endfunction
        virtual function void connect();
            rst.drive(rg.rst_n, fw_reset_kind::active_low());
            d.p.connect(xi.t);
            xi.pins.connect(xt.pins);
            xt.p.connect(m.t);
            k.p.connect(xi.pins);
        endfunction
    endclass

    // Checks the calls against the log and a shadow of the memory. Returns
    // the first failure, or "".
    function automatic string check(top_c t);
        bus_t l[$] = t.k.log;
        bit [31:0] shadow[16];
        foreach (t.d.calls[a]) begin
            call_t c = t.d.calls[a];
            bit eerr = (c.q.addr == ERR_ADDR);
            if (c.r < c.c + 2 || c.r > l.size())
                return $sformatf("transfer %0d: called at %0d, returned at %0d", a, c.c, c.r);
            for (int e = c.c + 1; e <= c.r; e++) begin
                bus_t b = l[e - 1];
                if (!b.psel || b.penable != (e > c.c + 1))
                    return $sformatf("transfer %0d: psel %0d penable %0d at edge %0d",
                                     a, b.psel, b.penable, e);
                if (b.paddr != c.q.addr || b.pwrite != c.q.write
                        || (c.q.write && b.pwdata != c.q.wdata))
                    return $sformatf("transfer %0d: request not held at edge %0d", a, e);
                if (b.pready != (e == c.r))
                    return $sformatf("transfer %0d: pready %0d at edge %0d", a, b.pready, e);
            end
            if (c.s.slverr != eerr)
                return $sformatf("transfer %0d: slverr %0d", a, c.s.slverr);
            if (!eerr && c.q.write) shadow[c.q.addr[5:2]] = c.q.wdata;
            if (!eerr && c.s.rdata != shadow[c.q.addr[5:2]])
                return $sformatf("transfer %0d: read %h, expected %h",
                                 a, c.s.rdata, shadow[c.q.addr[5:2]]);
        end
        if (t.d.calls.size() != N) return $sformatf("%0d transfers returned", t.d.calls.size());
        if (t.m.n_acc != N) return $sformatf("the memory saw %0d transfers", t.m.n_acc);
        return "";
    endfunction
endpackage
