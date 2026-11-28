// sbus against RTL: the emitted sbus_sys (sbus_mem_rtl inside) driven by
// the generated initiator and watched by the generated monitor. The
// testbench class sbus_sys_tb_c, its module sbus_sys_tb and the bind module
// sbus_sys_fw_mon are generated (gen_tb, gen_bind; check.py). This file is
// the test: the same host adapter and accesses as the back-to-back test,
// in a subclass of the generated class, and a one-line top.
`include "fw_hdl_macros.svh"

package sbus_rtl_tb_pkg;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;
    import sbus_pkg::*;
    import sbus_pkg_gen_pkg::*;
    import sbus_behav_pkg::*;
    import sbus_sys_tb_pkg::*;

    class beat_count implements sbus_req_if_listener, sbus_rsp_if_listener;
        int n_req, n_rsp;
        virtual function void req_pre(input sbus_req_t t);
        endfunction
        virtual function void req_post(input sbus_req_t t);
            n_req++;
        endfunction
        virtual function void rsp_pre(input sbus_rsp_t t);
        endfunction
        virtual function void rsp_post(input sbus_rsp_t t);
            n_rsp++;
        endfunction
    endclass

    // The generated class has the port's bundle s, the initiator dut_s and
    // the monitor mon_s (fed from the DUT's nets by the bind module).
    class tb_c extends sbus_sys_tb_c implements fw_run_if;
        `fw_component_utils(tb_c)
        sbus_host                host;
        beat_count               cnt = new();
        int n_err;

        virtual function void build();
            super.build();
            host = sbus_host::create("host", this);
        endfunction

        virtual function void connect();
            super.connect();
            host.s.connect(dut_s.s);
            mon_s.add_req_listener(cnt);
            mon_s.add_rsp_listener(cnt);
        endfunction

        task check(sbus_rsp_t got, sbus_rsp_t want);
            string diff;
            if (!sbus_payloads::sbus_rsp_compare(got, want, diff)) begin
                $display("E mismatch:%s", diff);
                n_err++;
            end
        endtask

        virtual task run();
            sbus_rsp_t rsp;
            host.access(rsp, '{addr: 8'h10, wdata: 32'hdeadbeef, we: 1});
            check(rsp, '{rdata: 32'hdeadbeef, err: 0});
            host.access(rsp, '{addr: 8'h10, wdata: 0, we: 0});
            check(rsp, '{rdata: 32'hdeadbeef, err: 0});
            host.access(rsp, '{addr: 8'hF4, wdata: 0, we: 0});
            check(rsp, '{rdata: 0, err: 1});
            $display("M req %0d rsp %0d", cnt.n_req, cnt.n_rsp);
            $display("%s", (n_err == 0 && cnt.n_req == 3 && cnt.n_rsp == 3) ? "PASS" : "FAIL");
        endtask
    endclass
endpackage

// The generated module runs the DUT against tb_c: clock, reset, and one
// fw_pin_bridge per pin of s.
module sbus_rtl_tb;
    sbus_sys_tb #(.TB(sbus_rtl_tb_pkg::tb_c)) tb();
endmodule
