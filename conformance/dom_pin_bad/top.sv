// FW-E-DOM-PIN without a module header: a domain driven by a 2-bit signal;
// a domain of a marker kind (declared here) driven at all.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    // A marker kind: physical() is 0.
    class tag_kind extends fw_domain_kind;
        `fw_domain_kind_utils(tag_kind)
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_input #(bit [1:0])     bus;
        fw_input #(bit)           m_i;
        fw_clock_domain           clk;
        fw_domain #(tag_kind)     tag;
        virtual function void build();
            bus = fw_input #(bit [1:0])::create("bus", this);
            m_i = fw_input #(bit)::create("m_i", this);
            clk = fw_clock_domain::create("clk", this);
            tag = fw_domain #(tag_kind)::create("tag", this);
        endfunction
        virtual function void connect();
            clk.drive(bus);
            tag.drive(m_i);
        endfunction
    endclass

endpackage
