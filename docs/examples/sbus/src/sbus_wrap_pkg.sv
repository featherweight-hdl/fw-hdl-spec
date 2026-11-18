// The RTL sbus target wrapped as a component, and a system around it that
// owns the clock and reset. fe-sv elaborates sbus_sys and emits Verilog in
// which sbus_mem is replaced by the module sbus_mem_rtl.
`include "fw_hdl_macros.svh"

package sbus_wrap_pkg;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;
    import sbus_pkg::*;
    import sbus_pkg_gen_pkg::*;

    // sbus_mem_rtl as a component: its port s is the target side of an
    // sbus link; the generated pin map gives s_reqvalid, s_reqaddr, ...
    class sbus_mem_w extends fw_component implements fw_extern_if;
        `fw_extern_utils(sbus_mem_w, "sbus_mem_rtl")
        fw_mirror #(sbus_bundle) s;

        virtual function void build();
            s = fw_mirror #(sbus_bundle)::create("s", this);
        endfunction

        virtual function void extern_map(fw_extern_map m);
            fw_clock_domain::pin(m, "clk");
            fw_reset_domain::pin(m, "rst_n", null, fw_reset_kind::active_low());
            void'(sbus_pins::flat(m, s, "s_"));
        endfunction
    endclass

    // The design: the memory, its sbus port passed up, and the clock and
    // reset domains driven from two inputs.
    class sbus_sys extends fw_component;
        `fw_component_utils(sbus_sys)
        fw_input  #(bit)          clk_i, rst_i;
        fw_mirror #(sbus_bundle)  s;
        fw_clock_domain           clk;
        fw_reset_domain           rst;
        sbus_mem_w                mem;

        virtual function void build();
            clk_i = fw_input #(bit)::create("clk_i", this);
            rst_i = fw_input #(bit)::create("rst_i", this);
            clk   = fw_clock_domain::create("clk", this);
            rst   = fw_reset_domain::create("rst", this, fw_reset_kind::root(.clock(clk)));
            fw_clock_domain::set(this, clk);
            fw_reset_domain::set(this, rst);
            s     = fw_mirror #(sbus_bundle)::create("s", this);
            mem   = sbus_mem_w::create("mem", this);
        endfunction

        virtual function void connect();
            mem.s.connect_up(s);
            clk.drive(clk_i);
            rst.drive(rst_i);
        endfunction
    endclass
endpackage
