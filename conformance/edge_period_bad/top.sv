// FW-E-CLOCK-PERIOD: clk3 is clk (period 10 ns) multiplied by 3. Its edges
// would be 10/3 ns apart, which is not a whole number of the 1 ps
// precision. clk4, a phase of 45 degrees (1.25 ns), is fine.
`timescale 1ns/1ps
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_proc.svh"

    class top extends test_proc_top;
        `fw_component_utils(top)
        fw_clock_domain clk3, clk4;
        virtual function void build();
            super.build();
            clk3 = fw_clock_domain::create("clk3", this,
                                           fw_clock_kind::derived(clk, .mul(3)));
            clk4 = fw_clock_domain::create("clk4", this,
                                           fw_clock_kind::phase(clk, 45));
        endfunction
    endclass

endpackage
