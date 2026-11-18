// Runs the back-to-back test in rt-sv: elaborate, run +fw_edges=N edges of
// the root clock, then print what the monitor saw (M), the recorded
// transactions (T), any diagnostics (D) and the verdict.
module sbus_b2b;
    import fw_hdl_pkg::*;
    import sbus_pkg_gen_pkg::*;
    import sbus_b2b_pkg::*;

    initial begin
        top_c t = top_c::create("top", null);
        if (__fw_rt::elaborate(t) == 0)
            __fw_rt_kern::run();
        foreach (__fw_rt::diags[i])
            $display("D %s %s", __fw_rt::diags[i].id, __fw_rt::diags[i].path);
        foreach (t.log.got[i]) $display("M %s", t.log.got[i]);
        foreach (t.test.rec.q[i]) $display("T %s", t.test.rec.q[i].sprint());
        if (t.test.rec.q.size() != 3) t.test.n_err++;
        $display("%s", (t.test.n_err == 0 && __fw_rt::diags.size() == 0) ? "PASS" : "FAIL");
        $finish;
    end
endmodule
