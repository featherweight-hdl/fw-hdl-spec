// A struct-valued shape class parameter drives port widths. The created type
// spells the struct value positionally.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;

    typedef struct packed { int dw; int aw; } shape_t;
    localparam shape_t DFLT = '{dw: 8, aw: 4};
    localparam shape_t WIDE = '{dw: 16, aw: 2};

    class port_c #(shape_t S = DFLT) extends fw_component;
        `fw_component_utils(port_c #(S))
        fw_input  #(bit [S.dw-1:0]) d;
        fw_output #(bit [S.aw-1:0]) a;
        virtual function void build();
            d = fw_input  #(bit [S.dw-1:0])::create("d", this);
            a = fw_output #(bit [S.aw-1:0])::create("a", this);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_input #(bit [7:0])               d8;
        fw_input #(bit [15:0])              d16;
        port_c                              v;
        port_c #(WIDE)                      w;
        virtual function void build();
            d8  = fw_input #(bit [7:0])::create("d8", this);
            d16 = fw_input #(bit [15:0])::create("d16", this);
            v   = port_c #()::create("v", this);
            w   = port_c #(WIDE)::create("w", this);
        endfunction
        virtual function void connect();
            d8.connect(v.d);
            d16.connect(w.d);
        endfunction
    endclass

endpackage
