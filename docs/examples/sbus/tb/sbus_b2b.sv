// sbus back to back, no RTL: test -> proxy -> host adapter -> generated
// initiator -> pins -> generated target -> device adapter -> memory model,
// and each response back the same way. The generated monitor taps the pins.
// The root clock's period drives the run (+fw_edges=N).
`include "fw_hdl_macros.svh"

package sbus_b2b_pkg;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;
    import sbus_pkg::*;
    import sbus_pkg_gen_pkg::*;
    import sbus_behav_pkg::*;

    function automatic int cyc();
        return int'($time / 10ns);
    endfunction

    // Keeps every recorded transaction.
    class recorder implements sbus_if_txn_sink;
        sbus_if_txn q[$];
        virtual function void put(input sbus_if_txn t);
            q.push_back(t);
        endfunction
    endclass

    // Logs each beat the monitor sees, at its handshake.
    class beat_log implements sbus_req_if_listener, sbus_rsp_if_listener;
        string got[$];
        virtual function void req_pre(input sbus_req_t t);
        endfunction
        virtual function void req_post(input sbus_req_t t);
            got.push_back($sformatf("req %s @%0d", sbus_payloads::sbus_req_sprint(t), cyc()));
        endfunction
        virtual function void rsp_pre(input sbus_rsp_t t);
        endfunction
        virtual function void rsp_post(input sbus_rsp_t t);
            got.push_back($sformatf("rsp %s @%0d", sbus_payloads::sbus_rsp_sprint(t), cyc()));
        endfunction
    endclass

    // The test: accesses through a proxy that records each call.
    class test_c extends fw_component implements fw_run_if;
        `fw_component_utils(test_c)
        fw_port #(sbus_if) p;
        recorder rec = new();
        int n_err;

        virtual function void build();
            p = fw_port #(sbus_if)::create("p", this);
        endfunction

        task check(sbus_rsp_t got, sbus_rsp_t want);
            string diff;
            if (!sbus_payloads::sbus_rsp_compare(got, want, diff)) begin
                $display("E mismatch:%s", diff);
                n_err++;
            end
        endtask

        virtual task run();
            sbus_if_proxy px = new(p.get_if());
            sbus_if_txn_listener tl = new(rec);
            sbus_rsp_t rsp;
            px.add_listener(tl);
            px.access(rsp, '{addr: 8'h10, wdata: 32'hdeadbeef, we: 1});
            check(rsp, '{rdata: 32'hdeadbeef, err: 0});
            px.access(rsp, '{addr: 8'h10, wdata: 0, we: 0});
            check(rsp, '{rdata: 32'hdeadbeef, err: 0});
            px.access(rsp, '{addr: 8'hF4, wdata: 0, we: 0});
            check(rsp, '{rdata: 0, err: 1});
            replay();
        endtask

        // A transaction, made by hand here (or randomized, or recorded),
        // becomes a call through a driver; the outputs land in it.
        task replay();
            sbus_if_txn_driver drv = new(p.get_if());
            sbus_if_access_txn t = new();
            t.req = '{addr: 8'h10, wdata: 0, we: 0};
            drv.drive(t);
            check(t.rsp, '{rdata: 32'hdeadbeef, err: 0});
        endtask
    endclass

    class top_c extends fw_component;
        `fw_component_utils(top_c)
        fw_clock_domain clk;
        test_c          test;
        sbus_host       host;
        sbus_initiator  xi;
        sbus_target     xt;
        sbus_monitor    mon;
        sbus_dev        dev;
        sbus_mem        mem;
        beat_log        log = new();

        virtual function void build();
            clk = fw_clock_domain::create("clk", this, fw_clock_kind::root(10ns));
            fw_clock_domain::set(this, clk);
            test = test_c::create("test", this);
            host = sbus_host::create("host", this);
            xi   = sbus_initiator::create("xi", this);
            xt   = sbus_target::create("xt", this);
            mon  = sbus_monitor::create("mon", this);
            dev  = sbus_dev::create("dev", this);
            mem  = sbus_mem::create("mem", this);
        endfunction

        virtual function void connect();
            test.p.connect(host.t);
            host.s.connect(xi.s);
            xi.pins.connect(xt.pins);
            mon.pins.connect(xi.pins);
            xt.s.connect(dev.s);
            dev.m.connect(mem.t);
            mon.add_req_listener(log);
            mon.add_rsp_listener(log);
        endfunction
    endclass
endpackage
