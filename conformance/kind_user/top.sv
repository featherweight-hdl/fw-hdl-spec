// A kind declared only in user code (the toy macro kind: a marker, with
// information on every crossing). It is associated, looked up, checked at
// connections and listed in the netlist like a library kind.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    // A leaf with one output.
    class src extends fw_component;
        `fw_component_utils(src)
        fw_output #(bit) o;
        virtual function void build();
            o = fw_output #(bit)::create("o", this);
        endfunction
    endclass

    // A leaf with one input.
    class snk extends fw_component;
        `fw_component_utils(snk)
        fw_input #(bit) i;
        virtual function void build();
            i = fw_input #(bit)::create("i", this);
        endfunction
    endclass

    // A marker kind: crossings between macros are information.
    class macro_kind extends fw_domain_kind;
        `fw_domain_kind_utils(macro_kind)
        static function fw_severity_e severity(fw_domain_rel_e r);
            return (r == FW_DOMAIN_SAME) ? FW_SEV_NONE : FW_SEV_INFO;
        endfunction
    endclass

    typedef fw_domain #(macro_kind) macro_domain;

    class top extends fw_component;
        `fw_component_utils(top)
        macro_domain m0, m1;
        src          a;
        snk          b, c;
        virtual function void build();
            m0 = macro_domain::create("m0", this);
            m1 = macro_domain::create("m1", this);
            macro_domain::set(this, m0);
            a = src::create("a", this);
            b = snk::create("b", this);
            c = snk::create("c", this);
            macro_domain::set(b, m1);
        endfunction
        virtual function void connect();
            b.i.connect(a.o);
            c.i.connect(a.o);
        endfunction
    endclass

endpackage
