// connect_all with non-equivalent value types (bit[7:0] and logic[7:0]),
// bundles of different types, and a signal with a bundle: FW-E-CONN-TYPE on
// the first endpoint of each pair.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    import fw_hdl_std_pkg::*;

    class sink8 extends fw_component;
        `fw_component_utils(sink8)
        fw_input  #(logic [7:0])            i;
        fw_mirror #(fw_rv_if #(bit [3:0]))  r;
        virtual function void build();
            i = fw_input  #(logic [7:0])::create("i", this);
            r = fw_mirror #(fw_rv_if #(bit [3:0]))::create("r", this);
        endfunction
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        fw_input  #(bit [7:0])             a;
        fw_input  #(bit)                   x;
        fw_bundle #(fw_rv_if #(bit [7:0])) ob;
        sink8                              c;
        virtual function void build();
            a  = fw_input  #(bit [7:0])::create("a", this);
            x  = fw_input  #(bit)::create("x", this);
            ob = fw_bundle #(fw_rv_if #(bit [7:0]))::create("ob", this);
            c  = sink8::create("c", this);
        endfunction
        virtual function void connect();
            connect_all('{ '{a, c.i}, '{ob, c.r}, '{x, c.r} });
            c.i.tie(0);
            c.r.valid.tie(0);
            c.r.data.tie(0);
        endfunction
    endclass

endpackage
