// A ready/valid source and a sink whose ready is a comb() of valid and a
// register that toggles (R2.3): ready answers valid in the same cycle.
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;
    `include "test_proc.svh"

    // Offers data 0, 1, 2, ... from the first edge out of reset.
    class rv_src extends fw_component implements fw_step_if;
        `fw_component_utils(rv_src)
        fw_bundle #(fw_rv_if #(bit [7:0])) out;
        virtual function void build();
            out = fw_bundle #(fw_rv_if #(bit [7:0]))::create("out", this);
        endfunction
        virtual function void step();
            if (fw_reset_domain::in_reset(this)) begin
                out.valid.write(0);
                out.data.write(0);
            end else begin
                out.valid.write(1);
                if (out.valid.read() && out.ready.read())
                    out.data.write(out.data.read() + 8'd1);
            end
        endfunction
    endclass

    class rv_snk extends fw_component implements fw_step_if;
        `fw_component_utils(rv_snk)
        fw_mirror #(fw_rv_if #(bit [7:0])) in;
        fw_output #(bit)       en;
        fw_output #(bit [7:0]) got;
        virtual function void build();
            in  = fw_mirror #(fw_rv_if #(bit [7:0]))::create("in", this);
            en  = fw_output #(bit)::create("en", this);
            got = fw_output #(bit [7:0])::create("got", this);
        endfunction
        `fw_comb(rdy)
        function void rdy();
            in.ready.write(in.valid.read() && en.read());
        endfunction
        virtual function void step();
            if (fw_reset_domain::in_reset(this)) begin
                en.write(0);
                got.write(0);
            end else begin
                en.write(!en.read());
                if (in.valid.read() && in.ready.read())
                    got.write(in.data.read());
            end
        endfunction
    endclass

    class top extends test_proc_top;
        `fw_component_utils(top)
        rv_src s;
        rv_snk k;
        virtual function void build();
            super.build();
            s = rv_src::create("s", this);
            k = rv_snk::create("k", this);
        endfunction
        virtual function void connect();
            super.connect();
            s.out.connect(k.in);
        endfunction
    endclass

endpackage
