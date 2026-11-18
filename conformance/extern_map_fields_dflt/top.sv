// Field-wise pins with default field names: a rename into r's payload makes
// it field-wise; addr is renamed, len is not (r_data_len). tag is a nested
// packed struct with a rename into it (r_tid), so it is field-wise too
// (r_data_tag_user). The reference runtime cannot list unrenamed fields.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;

    typedef struct packed {
        bit [3:0] id;
        bit [1:0] user;
    } tag_t;

    typedef struct packed {
        bit [31:0] addr;
        tag_t      tag;
        bit [7:0]  len;
    } req_t;

    class ext extends fw_component implements fw_extern_if;
        `fw_extern_utils(ext, "req_sink")

        fw_mirror #(fw_rv_if #(req_t)) r;

        virtual function void build();
            r = fw_mirror #(fw_rv_if #(req_t))::create("r", this);
        endfunction

        virtual function void extern_map(fw_extern_map m);
            void'(m.prefix(r, "r_")
                .rename("data.addr", "addr")
                .rename("data.tag.id", "tid"));
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_mirror #(fw_rv_if #(req_t)) r;
        ext                            e;
        virtual function void build();
            r = fw_mirror #(fw_rv_if #(req_t))::create("r", this);
            e = ext::create("e", this);
        endfunction
        virtual function void connect();
            e.r.connect_up(r);
        endfunction
    endclass

endpackage
