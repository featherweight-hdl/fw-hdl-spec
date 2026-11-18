// A socket bound to its mirror (fw_socket#(OUT,IN) to fw_socket#(IN,OUT)):
// two api_endpoint objects and one api binding, from the calling side to
// the providing side.
`include "fw_hdl_macros.svh"

package scenario;
    import fw_hdl_pkg::*;
    `include "test_apis.svh"

    // Calls the API through its socket.
    class src extends fw_component;
        `fw_component_utils(src)
        fw_socket #(test_put_if #(byte), test_get_if #(byte)) s;
        virtual function void build();
            s = fw_socket #(test_put_if #(byte), test_get_if #(byte))::create("s", this);
        endfunction
    endclass

    // Implements the API for its mirror socket.
    class sink extends fw_component implements test_put_if #(byte);
        `fw_component_utils(sink)
        fw_socket #(test_get_if #(byte), test_put_if #(byte)) t;
        virtual function void build();
            t = fw_socket #(test_get_if #(byte), test_put_if #(byte))::create("t", this);
        endfunction
        virtual task put(byte t);
        endtask
    endclass

    class top extends fw_component;
        `fw_component_utils(top)
        src  a;
        sink k;
        virtual function void build();
            a = src::create("a", this);
            k = sink::create("k", this);
        endfunction
        virtual function void connect();
            a.s.connect(k.t);
        endfunction
    endclass

endpackage
