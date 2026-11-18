// The module that scenario extern_map_fields_dflt wraps.
module req_sink (
    input  logic        r_valid,
    output logic        r_ready,
    input  logic [31:0] r_addr,
    input  logic [3:0]  r_tid,
    input  logic [1:0]  r_data_tag_user,
    input  logic [7:0]  r_data_len
);
endmodule
