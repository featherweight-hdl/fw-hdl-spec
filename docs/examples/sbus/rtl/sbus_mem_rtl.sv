// An existing RTL sbus target: a 240-word memory with sbus pins s_*. One
// access in flight: s_reqready is low from a request's handshake until its
// response's. An access at 0xF0 and above answers err. Reset is active low.
module sbus_mem_rtl (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        s_reqvalid,
    output logic        s_reqready,
    input  logic [7:0]  s_reqaddr,
    input  logic [31:0] s_reqwdata,
    input  logic        s_reqwe,
    output logic        s_rspvalid,
    input  logic        s_rspready,
    output logic [31:0] s_rsprdata,
    output logic        s_rsperr
);
    logic [31:0] mem [0:239];

    assign s_reqready = !s_rspvalid;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            s_rspvalid <= 1'b0;
            s_rsprdata <= '0;
            s_rsperr   <= 1'b0;
        end else if (s_reqvalid && s_reqready) begin
            s_rspvalid <= 1'b1;
            s_rsperr   <= (s_reqaddr >= 8'hF0);
            if (s_reqaddr >= 8'hF0)
                s_rsprdata <= '0;
            else if (s_reqwe) begin
                mem[s_reqaddr] <= s_reqwdata;
                s_rsprdata     <= s_reqwdata;
            end else
                s_rsprdata <= mem[s_reqaddr];
        end else if (s_rspvalid && s_rspready) begin
            s_rspvalid <= 1'b0;
        end
    end
endmodule
