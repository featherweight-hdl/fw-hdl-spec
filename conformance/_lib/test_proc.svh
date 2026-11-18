`ifndef TEST_PROC_SVH
`define TEST_PROC_SVH
// Shared by the process scenarios (layer 2; conformance/README.md).

// Reset generator: rst_n is a step() register that reads 0 at edges 1 and
// 2 and 1 from edge 3 on. It has no reset of its own.
class test_rst_gen extends fw_component implements fw_step_if;
    `fw_component_utils(test_rst_gen)
    fw_output #(bit) rst_n;
    bit [1:0] n;
    virtual function void build();
        rst_n = fw_output #(bit)::create("rst_n", this);
    endfunction
    virtual function void step();
        if (n != 2'd2)
            n = n + 2'd1;
        rst_n.write(n == 2'd2);
    endfunction
endclass

// Base of a process scenario's top: root clock clk, period 10 and no
// driver (edges at 10, 20, ...); synchronous reset rst, active low, driven
// by test_rst_gen rg: asserted at edges 1 and 2.
virtual class test_proc_top extends fw_component;
    fw_clock_domain clk;
    fw_reset_domain rst;
    test_rst_gen    rg;
    virtual function void build();
        clk = fw_clock_domain::create("clk", this, fw_clock_kind::root(10ns));
        rst = fw_reset_domain::create("rst", this,
                                      fw_reset_kind::root(fw_reset_kind::SYNC, clk));
        fw_clock_domain::set(this, clk);
        fw_reset_domain::set(this, rst);
        rg = test_rst_gen::create("rg", this);
    endfunction
    virtual function void connect();
        rst.drive(rg.rst_n, fw_reset_kind::active_low());
    endfunction
endclass

`endif // TEST_PROC_SVH
