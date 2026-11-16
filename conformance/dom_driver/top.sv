// FW-E-DOM-DRIVER: a domain driven by two signals; a domain driven by a
// signal and by an extern's output pin.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    class div extends fw_component implements fw_extern_if;
        `fw_extern_utils(div, "div_mod")
        virtual function void extern_map(fw_extern_map m);
            fw_clock_domain::pin(m, "clk_i");
            fw_clock_domain::pin_out(m, "clk_o", fw_clock_domain::get(this, "out"));
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_input #(bit) a, b, c;
        fw_clock_domain clk, c2;
        div             u;
        virtual function void build();
            a   = fw_input #(bit)::create("a", this);
            b   = fw_input #(bit)::create("b", this);
            c   = fw_input #(bit)::create("c", this);
            clk = fw_clock_domain::create("clk", this);
            c2  = fw_clock_domain::create("c2", this, fw_clock_kind::derived(clk, .div(2)));
            fw_clock_domain::set(this, clk);
            u   = div::create("u", this);
            fw_clock_domain::set(u, c2, "out");
        endfunction
        virtual function void connect();
            clk.drive(a);
            clk.drive(b);
            c2.drive(c);
        endfunction
    endclass

endpackage
