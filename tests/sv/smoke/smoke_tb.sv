// Compiles and elaborates the worked example against fw_hdl_pkg with
// generated default bodies. It checks the API, not behavior: behavior is
// tested in each tool against the conformance scenarios. The creation and
// phase calls are compiled but never run (the default bodies return null).
module smoke_tb;
    import fw_hdl_pkg::*;
    import smoke_pkg::*;

    initial begin : main
        soc top;
        if ($test$plusargs("fw_never")) begin
            top = soc::create("top", null);
            top.build();
            top.connect();
        end
        $display("PASS");
        $finish;
    end
endmodule
