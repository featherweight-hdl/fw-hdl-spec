// The modules that scenario dom_pin_hdr wraps.
module m_dir (
    output logic clk
);
endmodule

module m_width (
    input  logic [1:0] clk
);
endmodule

module m_missing (
    input  logic clk
);
endmodule

module m_out (
    input  logic clk,
    input  logic clk_o
);
endmodule
