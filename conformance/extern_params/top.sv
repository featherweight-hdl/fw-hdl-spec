// Module parameters of every kind through fw_value/fw_type: int (one
// negative), a wide vector, a string, an enum, a packed struct, and two
// type parameters, one of which sets a port's width.
`include "fw_hdl_macros.svh"
`include "prm_types.svh"

package scenario;
    import fw_hdl_pkg::*;
    import prm_pkg::*;

    class ext extends fw_component implements fw_extern_if;
        `fw_extern_utils(ext, "prm_mod")

        fw_input #(bit [11:0]) d;

        virtual function void build();
            d = fw_input #(bit [11:0])::create("d", this);
        endfunction

        virtual function void extern_map(fw_extern_map m);
            m.param("OFS",    fw_value #(int)::of(-5));
            m.param("K",      fw_value #(logic [39:0])::of(40'h12_3456_789a));
            m.param("NAME",   fw_value #(string)::of("u0"));
            m.param("MODE",   fw_value #(mode_e)::of(MODE_FAST));
            m.param("CFG",    fw_value #(cfg_t)::of('{burst: 4, wrap: 1}));
            m.param("data_t", fw_type #(bit [11:0])::get());
            m.param("cfg_tt", fw_type #(cfg_t)::get());
            m.param("OFS",    fw_value #(int)::of(-6));    // set twice: the later wins
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_input #(bit [11:0]) d;
        ext                    e;
        virtual function void build();
            d = fw_input #(bit [11:0])::create("d", this);
            e = ext::create("e", this);
        endfunction
        virtual function void connect();
            e.d.connect(d);
        endfunction
    endclass

endpackage
