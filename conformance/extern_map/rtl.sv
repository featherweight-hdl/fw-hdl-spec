// The module that scenario extern_map wraps.
module ext_mod #(
    parameter int W = 8,
    parameter int D = 2
) (
    input  logic         clk,
    input  logic         RST_N,
    input  logic [W-1:0] i_dat,
    input  logic         i_vld,
    output logic         i_ready,
    output logic [W-1:0] o_data,
    output logic         o_vld,
    input  logic         o_rdy,
    input  logic [3:0]   cfg,
    output logic         stat,
    input  logic         TEST,
    input  logic [7:0]   MODE,
    output logic         DBG,
    output logic         ERR
);
endmodule
