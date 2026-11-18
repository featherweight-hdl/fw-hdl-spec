// The module that scenario extern_map_fields wraps.
module axi_sink (
    input  logic        clk,
    input  logic        awvalid,
    output logic        awready,
    input  logic [31:0] awaddr,
    input  logic [7:0]  awlen,
    input  logic [2:0]  awsize,
    input  logic        arvalid,
    output logic        arready,
    input  logic [42:0] ardata
);
endmodule
