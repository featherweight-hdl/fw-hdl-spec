// FW-E-WRITE-MULTI: o written by two step blocks; p written by a step and a
// comb block.
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_proc.svh"

    class two extends fw_component implements fw_step_if;
        `fw_component_utils(two)
        fw_output #(bit) o, p;
        virtual function void build();
            o = fw_output #(bit)::create("o", this);
            p = fw_output #(bit)::create("p", this);
        endfunction
        `fw_step(sa)
        `fw_step(sb)
        `fw_comb(cc)
        function void sa();
            o.write(1);
        endfunction
        function void sb();
            o.write(0);
        endfunction
        function void cc();
            p.write(1);
        endfunction
        virtual function void step();
            p.write(0);
        endfunction
    endclass

    class top extends test_proc_top;
        `fw_component_utils(top)
        two x;
        virtual function void build();
            super.build();
            x = two::create("x", this);
        endfunction
    endclass

endpackage
