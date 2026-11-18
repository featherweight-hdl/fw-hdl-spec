// Field-wise pins: renames into the packed-struct payload of aw give one pin
// per field (awaddr, awlen, awsize). ar has a rename into its payload too,
// but pin() then maps ar.data whole, so ar has no field pins.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;

    typedef struct packed {
        bit [31:0] addr;
        bit [7:0]  len;
        bit [2:0]  size;
    } aw_t;

    class ext extends fw_component implements fw_extern_if;
        `fw_extern_utils(ext, "axi_sink")

        fw_input  #(bit)                clk;
        fw_mirror #(fw_rv_if #(aw_t))   aw, ar;

        virtual function void build();
            clk = fw_input  #(bit)::create("clk", this);
            aw  = fw_mirror #(fw_rv_if #(aw_t))::create("aw", this);
            ar  = fw_mirror #(fw_rv_if #(aw_t))::create("ar", this);
        endfunction

        virtual function void extern_map(fw_extern_map m);
            void'(m.prefix(aw, "aw")
                .rename("data.addr", "addr")
                .rename("data.len", "len")
                .rename("data.size", "size"));
            void'(m.prefix(ar, "ar").rename("data.addr", "addr"));
            m.pin("ardata", ar.data);       // whole: replaces the field-wise choice
            // clk: default rule
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_input  #(bit)                clk;
        fw_mirror #(fw_rv_if #(aw_t))   aw, ar;
        ext                             e;
        virtual function void build();
            clk = fw_input  #(bit)::create("clk", this);
            aw  = fw_mirror #(fw_rv_if #(aw_t))::create("aw", this);
            ar  = fw_mirror #(fw_rv_if #(aw_t))::create("ar", this);
            e   = ext::create("e", this);
        endfunction
        virtual function void connect();
            e.clk.connect(clk);
            e.aw.connect_up(aw);
            e.ar.connect_up(ar);
        endfunction
    endclass

endpackage
