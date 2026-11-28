// FW-E-WRITE-MULTI between sync blocks of one component: o is written by
// two comb blocks. p is written twice in one call of the step block, once
// through a helper: one writer, no error, and the last write of the call
// wins (p toggles). Two step blocks, and a step and a comb block, are in
// proc_write_multi.
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_proc.svh"

    class both extends fw_component implements fw_comb_if, fw_step_if;
        `fw_component_utils(both)
        fw_output #(bit) o, p;
        virtual function void build();
            o = fw_output #(bit)::create("o", this);
            p = fw_output #(bit)::create("p", this);
        endfunction
        `fw_comb(cb)
        function void cb();
            o.write(!p.read());
        endfunction
        virtual function void comb();
            o.write(p.read());
        endfunction
        function void set_p(bit v);
            p.write(v);
        endfunction
        virtual function void step();
            set_p(0);
            p.write(!p.read());
        endfunction
    endclass

    class top extends test_proc_top;
        `fw_component_utils(top)
        both b;
        virtual function void build();
            super.build();
            b = both::create("b", this);
        endfunction
    endclass

endpackage
