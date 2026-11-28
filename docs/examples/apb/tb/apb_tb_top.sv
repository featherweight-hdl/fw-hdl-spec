// Runs the bench in rt-sv: elaborate, run +fw_edges=N edges, check. Uses
// rt-sv's internal entry points, as its own tests do.
module apb_tb;
    import fw_hdl_pkg::*;
    import apb_tb_pkg::*;

    initial begin
        top_c t = top_c::create("top", null);
        string e;
        int nerr = __fw_rt::elaborate(t), nws;
        if (nerr == 0) __fw_rt_kern::run();
        foreach (__fw_rt::diags[i]) $display("D %s %s", __fw_rt::diags[i].id, __fw_rt::diags[i].path);
        e = (nerr != 0) ? $sformatf("%0d elaboration errors", nerr) : check(t);
        foreach (t.d.calls[i]) if (t.d.calls[i].r > t.d.calls[i].c + 2) nws++;
        if (e == "") $display("%0d transfers in %0d edges, %0d with wait states", N, t.k.n(), nws);
        else         $display("E %s", e);
        $display("%s", (e == "" && __fw_rt::diags.size() == 0) ? "PASS" : "FAIL");
        $finish;
    end
endmodule
